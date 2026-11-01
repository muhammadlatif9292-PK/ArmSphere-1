// lib/core/security/audit_chain_verifier.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Structured verification report produced by client-side cryptographic analysis
/// combined with the server's immutable ledger verification endpoint.
class AuditChainVerificationReport {
  final bool isValid;
  final bool clientChainValid;
  final bool serverChainValid;
  final int totalEventsVerified;
  final List<String> corruptedEventIds;
  final int? tamperedBlockIndex;
  final String? failureReason;
  final DateTime verifiedAt;
  final Map<String, bool> perEventIntegrity;

  const AuditChainVerificationReport({
    required this.isValid,
    required this.clientChainValid,
    required this.serverChainValid,
    required this.totalEventsVerified,
    required this.corruptedEventIds,
    this.tamperedBlockIndex,
    this.failureReason,
    required this.verifiedAt,
    this.perEventIntegrity = const {},
  });

  int get verifiedCount => totalEventsVerified;
  int? get brokenIndex => tamperedBlockIndex;

  factory AuditChainVerificationReport.empty() {
    return AuditChainVerificationReport(
      isValid: true,
      clientChainValid: true,
      serverChainValid: true,
      totalEventsVerified: 0,
      corruptedEventIds: const [],
      verifiedAt: DateTime.now(),
      perEventIntegrity: const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'clientChainValid': clientChainValid,
      'serverChainValid': serverChainValid,
      'totalEventsVerified': totalEventsVerified,
      'corruptedEventIds': corruptedEventIds,
      'tamperedBlockIndex': tamperedBlockIndex,
      'failureReason': failureReason,
      'verifiedAt': verifiedAt.toIso8601String(),
    };
  }
}

/// Cryptographically validates the federation SHA-256 audit event ledger.
///
/// Implements dual client + server chain verification:
/// 1. Verifies parent-to-child cryptographic hash continuity in Dart (`package:crypto`).
/// 2. Recomputes event hashes against the backend's canonical serialization:
///    - 8-field canonical format (`AuditLedgerService.logEvent`):
///      `parentHash|eventId|actorId|entityType|entityId|action|payloadJson|createdAtIso`
///    - 7-field fallback format (`AdministrationService.verifyImmutableAuditLedger`):
///      `parentHash|eventId|actorId|entityType|entityId|action|payloadJson`
/// 3. Cross-references the server verification response from `GET /admin/audit/verify`.
class AuditChainVerifier {
  static const String genesisHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  /// Computes a standard SHA-256 hex digest for an input string.
  static String sha256Hex(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  /// Evaluates an array of audit events (in any sort order) and returns a complete
  /// cryptographic verification report.
  static AuditChainVerificationReport verifyChain({
    required List<Map<String, dynamic>> rawEvents,
    Map<String, dynamic>? serverVerificationResponse,
  }) {
    if (rawEvents.isEmpty) {
      final bool serverValid =
          serverVerificationResponse?['isValid'] as bool? ??
          serverVerificationResponse?['valid'] as bool? ??
          true;
      return AuditChainVerificationReport(
        isValid: serverValid,
        clientChainValid: true,
        serverChainValid: serverValid,
        totalEventsVerified: 0,
        corruptedEventIds: const [],
        verifiedAt: DateTime.now(),
        perEventIntegrity: const {},
      );
    }

    // 1. Sort events chronologically (oldest to newest)
    final chain = List<Map<String, dynamic>>.from(rawEvents);
    chain.sort((a, b) {
      final aDate = _parseDate(a['createdAt']);
      final bDate = _parseDate(b['createdAt']);
      if (aDate != null && bDate != null) {
        final cmp = aDate.compareTo(bDate);
        if (cmp != 0) return cmp;
      }
      return (a['eventId']?.toString() ?? a['id']?.toString() ?? '')
          .compareTo(b['eventId']?.toString() ?? b['id']?.toString() ?? '');
    });

    final List<String> corruptedEventIds = [];
    final Map<String, bool> perEventIntegrity = {};
    int? firstTamperedIndex;
    String? failureReason;

    // Determine if the chronological list starts with genesis or a window slice
    final firstParentHash = chain[0]['parentHash']?.toString() ?? '';
    final bool isGenesisStart = firstParentHash == genesisHash;
    String expectedParentHash = isGenesisStart ? genesisHash : firstParentHash;

    for (int i = 0; i < chain.length; i++) {
      final event = chain[i];
      final eventId =
          event['eventId']?.toString() ??
          event['id']?.toString() ??
          'unknown_event_$i';
      final parentHash = event['parentHash']?.toString() ?? '';
      final eventHash =
          event['eventHash']?.toString() ??
          event['currentHash']?.toString() ??
          event['hash']?.toString() ??
          '';

      bool isBlockValid = true;

      // Check 1: Parent Hash Continuity
      if (i == 0) {
        if (isGenesisStart && parentHash != genesisHash) {
          isBlockValid = false;
          corruptedEventIds.add(eventId);
          firstTamperedIndex ??= i;
          failureReason ??=
              'Parent hash link broken at genesis block #0 ($eventId): expected $genesisHash but found $parentHash';
        }
      } else {
        if (parentHash != expectedParentHash) {
          isBlockValid = false;
          corruptedEventIds.add(eventId);
          firstTamperedIndex ??= i;
          failureReason ??=
              'Parent hash link broken at block #$i ($eventId): parentHash ($parentHash) does not match predecessor hash ($expectedParentHash)';
        }
      }

      // Check 2: Recompute Hash Signature
      final actorStr =
          event['actorId']?.toString() ??
          event['userId']?.toString() ??
          'SYSTEM';
      final action =
          event['action']?.toString() ??
          event['actionType']?.toString() ??
          '';
      final entityType =
          event['entityType']?.toString() ??
          (action.isNotEmpty ? action.split('_').first : 'AUDIT');
      final entityId =
          event['entityId']?.toString() ??
          event['id']?.toString() ??
          eventId;

      final payloadObj = event['payload'] ?? event['details'];
      final payloadJson = payloadObj != null
          ? (payloadObj is String ? payloadObj : jsonEncode(payloadObj))
          : '{}';

      final createdAtRaw = event['createdAt'];
      final createdAtDate = _parseDate(createdAtRaw);
      final createdAtIso = createdAtDate != null
          ? createdAtDate.toUtc().toIso8601String()
          : (createdAtRaw?.toString() ?? '');

      // Formula A: 8-field format (AuditLedgerService)
      final input8 = [
        parentHash,
        eventId,
        actorStr,
        entityType,
        entityId,
        action,
        payloadJson,
        createdAtIso,
      ].join('|');
      final hash8 = sha256Hex(input8);

      // Formula B: 7-field format (AdministrationService legacy / verify)
      final input7 = [
        parentHash,
        eventId,
        actorStr,
        entityType,
        entityId,
        action,
        payloadObj != null ? (payloadObj is String ? payloadObj : jsonEncode(payloadObj)) : '',
      ].join('|');
      final hash7 = sha256Hex(input7);

      final bool signatureMatches =
          eventHash.isNotEmpty &&
          (eventHash.toLowerCase() == hash8.toLowerCase() ||
              eventHash.toLowerCase() == hash7.toLowerCase());

      // If neither formula matches, verify if eventHash was pre-verified by server
      if (!signatureMatches && eventHash.isNotEmpty) {
        // Also check with alternate actor fallback (e.g. empty string vs 'SYSTEM')
        final input8Alt = [
          parentHash,
          eventId,
          event['actorId']?.toString() ?? '',
          entityType,
          entityId,
          action,
          payloadJson,
          createdAtIso,
        ].join('|');
        if (eventHash.toLowerCase() != sha256Hex(input8Alt).toLowerCase()) {
          // If the signature check failed on recomputed values, mark corrupted
          isBlockValid = false;
          if (!corruptedEventIds.contains(eventId)) {
            corruptedEventIds.add(eventId);
          }
          firstTamperedIndex ??= i;
          failureReason ??=
              'Hash mismatch at block #$i ($eventId). Record payload or metadata was tampered.';
        }
      }

      perEventIntegrity[eventId] = isBlockValid;
      expectedParentHash = eventHash;
    }

    final bool clientValid = corruptedEventIds.isEmpty;

    // Check 3: Cross-check against server verification endpoint
    final bool serverValid = serverVerificationResponse != null
        ? (serverVerificationResponse['isValid'] as bool? ??
            serverVerificationResponse['valid'] as bool? ??
            (serverVerificationResponse['tamperedEventId'] == null))
        : true;

    final String? serverTamperedId =
        serverVerificationResponse?['tamperedEventId']?.toString();
    if (serverTamperedId != null && serverTamperedId.isNotEmpty) {
      if (!corruptedEventIds.contains(serverTamperedId)) {
        corruptedEventIds.add(serverTamperedId);
      }
    }

    final bool overallValid = clientValid && serverValid;

    return AuditChainVerificationReport(
      isValid: overallValid,
      clientChainValid: clientValid,
      serverChainValid: serverValid,
      totalEventsVerified: chain.length,
      corruptedEventIds: corruptedEventIds,
      tamperedBlockIndex: firstTamperedIndex,
      failureReason: failureReason ??
          (serverVerificationResponse?['reason']?.toString()),
      verifiedAt: DateTime.now(),
      perEventIntegrity: perEventIntegrity,
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    try {
      return DateTime.parse(val.toString());
    } catch (_) {
      return null;
    }
  }
}
