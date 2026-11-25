/// Shared display formatters for clean, zero-raw-enum, typo-free UI labels.
class ArmSphereFormatters {
  ArmSphereFormatters._();

  static const Set<String> _invalidLocationTokens = {
    'unknown',
    'null',
    'n/a',
    'na',
    'none',
    'undefined',
    '-',
    '--',
  };

  /// Deduplicates address/city/province fragments and strips placeholder tokens
  /// such as `UNKNOWN`, `null`, or `N/A`.
  ///
  /// Example:
  /// `formatCleanAddress(['Charsadda KPK', 'Charsadda KPK', 'UNKNOWN'])`
  /// -> `'Charsadda, KPK'`
  static String formatCleanAddress(Iterable<String?> rawParts) {
    final List<String> cleaned = [];
    final Set<String> seenNormalized = {};

    for (final raw in rawParts) {
      if (raw == null) continue;
      // Split comma-separated segments so embedded duplicates are also removed.
      for (final segment in raw.split(',')) {
        final trimmed = segment.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (trimmed.isEmpty) continue;
        final lower = trimmed.toLowerCase();
        if (_invalidLocationTokens.contains(lower)) continue;

        // Normalize common combined "City KPK" / "City Punjab" pattern when
        // followed by or duplicating a known province code.
        final expanded = _splitTrailingProvinceSuffix(trimmed);
        for (final piece in expanded) {
          final p = piece.trim();
          if (p.isEmpty) continue;
          final pLower = p.toLowerCase();
          if (_invalidLocationTokens.contains(pLower)) continue;
          if (seenNormalized.add(pLower)) {
            cleaned.add(p);
          }
        }
      }
    }

    return cleaned.join(', ');
  }

  static List<String> _splitTrailingProvinceSuffix(String segment) {
    final match = RegExp(
      r'^(.+?)\s+(KPK|Khyber Pakhtunkhwa|Punjab|Sindh|Balochistan|Islamabad|Gilgit-Baltistan|AJK)$',
      caseSensitive: false,
    ).firstMatch(segment);
    if (match == null) return [segment];
    final prefix = match.group(1)!.trim();
    final prov = match.group(2)!.trim();
    if (prefix.isEmpty || prefix.toLowerCase() == prov.toLowerCase()) {
      return [segment];
    }
    return [prefix, prov];
  }

  /// Normalizes known organization spelling typos (e.g. `ARMWRESLING`).
  static String formatOrganizationName(String? raw, {String fallback = 'Organization'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    var text = raw.trim();
    text = text.replaceAll(
      RegExp(r'ARMWRESLING', caseSensitive: false),
      text == text.toUpperCase() ? 'ARMWRESTLING' : 'Armwrestling',
    );
    return text;
  }

  /// Formats arm preference / division labels cleanly (`BOTH ARM` -> `Both Arms`).
  static String formatArmLabel(String? raw, {bool uppercase = false}) {
    final cleaned = (raw ?? '').trim().toUpperCase().replaceAll('_', ' ');
    String label;
    switch (cleaned) {
      case 'BOTH':
      case 'BOTH ARM':
      case 'BOTH ARMS':
        label = 'Both Arms';
        break;
      case 'AMBIDEXTROUS':
        label = 'Ambidextrous';
        break;
      case 'RIGHT':
      case 'RIGHT ARM':
        label = 'Right Arm';
        break;
      case 'LEFT':
      case 'LEFT ARM':
        label = 'Left Arm';
        break;
      default:
        label = cleaned.isEmpty ? 'Right Arm' : _titleCase(cleaned);
    }
    return uppercase ? label.toUpperCase() : label;
  }

  /// Dynamic singular/plural table counter (`1 Pro Table` vs `2 Pro Tables`).
  static String formatProTables(int count) {
    final safeCount = count < 0 ? 0 : count;
    return safeCount == 1 ? '1 Pro Table' : '$safeCount Pro Tables';
  }

  /// Human-readable role badge label (`SYSTEM_ADMIN` -> `System Admin`).
  static String formatRoleLabel(String? raw) {
    final upper = (raw ?? '').trim().toUpperCase();
    switch (upper) {
      case 'SYSTEM_ADMIN':
        return 'System Admin';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'ORG_ADMIN':
      case 'ORGANIZATION_ADMIN':
        return 'Organization Admin';
      case 'FEDERATION_ADMIN':
        return 'Federation Admin';
      case 'TOURNAMENT_OPERATOR':
      case 'ORGANIZER':
        return 'Tournament Operator';
      case 'REFEREE':
      case 'OFFICIAL':
        return 'Certified Referee';
      case 'ATHLETE':
        return 'Athlete';
      default:
        return upper.isEmpty ? 'Athlete' : _titleCase(upper.replaceAll('_', ' '));
    }
  }

  /// Human-readable tournament status (`REGISTRATION_OPEN` -> `Registration Open`).
  static String formatTournamentStatus(String? raw) {
    final upper = (raw ?? '').trim().toUpperCase();
    switch (upper) {
      case 'REGISTRATION_OPEN':
      case 'OPEN':
        return 'Registration Open';
      case 'REGISTRATION_CLOSED':
        return 'Registration Closed';
      case 'DRAFT':
        return 'Draft';
      case 'SCHEDULED':
      case 'PUBLISHED':
        return 'Scheduled';
      case 'WEIGH_IN':
      case 'WEIGH_IN_OPEN':
        return 'Weigh-In Open';
      case 'LIVE':
      case 'IN_PROGRESS':
      case 'ONGOING':
        return 'Live Now';
      case 'COMPLETED':
      case 'FINISHED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return upper.isEmpty ? 'Scheduled' : _titleCase(upper.replaceAll('_', ' '));
    }
  }

  /// Human-readable competition division (`SENIOR` -> `Senior`).
  static String formatDivisionLabel(String? raw) {
    final upper = (raw ?? '').trim().toUpperCase();
    switch (upper) {
      case 'SENIOR':
        return 'Senior';
      case 'JUNIOR':
        return 'Junior';
      case 'MASTERS':
        return 'Masters';
      case 'FEMALE':
      case 'WOMEN':
        return 'Women';
      default:
        return upper.isEmpty ? 'Senior' : _titleCase(upper.replaceAll('_', ' '));
    }
  }

  static String _titleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.length == 1
            ? w.toUpperCase()
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}
