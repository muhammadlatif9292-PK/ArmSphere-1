import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Deterministic, high-contrast QR Matrix renderer used exclusively for the
/// single permanent User Profile QR Identity in Settings & Profile.
class ArmSphereQrMatrixView extends StatelessWidget {
  final String payload;
  final double size;

  const ArmSphereQrMatrixView({
    super.key,
    String? payload,
    String? data,
    this.size = 220,
  }) : payload = payload ?? data ?? '';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.goldPrimary, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _QrMatrixPainter(payload: payload),
        size: Size.square(size - 28),
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final String payload;

  _QrMatrixPainter({required this.payload});

  static bool _isFinderModule(int r, int c, int topR, int leftC) {
    final dr = r - topR;
    final dc = c - leftC;
    if (dr < 0 || dr > 6 || dc < 0 || dc > 6) return false;
    if (dr == 0 || dr == 6 || dc == 0 || dc == 6) return true;
    if (dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4) return true;
    return false;
  }

  static bool _isInFinderZone(int r, int c, int grid) {
    if (r <= 7 && c <= 7) return true;
    if (r <= 7 && c >= grid - 8) return true;
    if (r >= grid - 8 && c <= 7) return true;
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const int grid = 29;
    final double cell = size.width / grid;
    final Paint darkPaint = Paint()
      ..color = const Color(0xFF070A12)
      ..style = PaintingStyle.fill;

    // Expand payload into a deterministic 256-byte bit reservoir using SHA-256 rounds
    final List<int> bytes = <int>[];
    for (int round = 0; round < 8; round++) {
      final digest = sha256.convert(utf8.encode('$payload#$round')).bytes;
      bytes.addAll(digest);
    }

    int bitIdx = 0;
    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        bool dark = false;

        if (_isInFinderZone(r, c, grid)) {
          dark = _isFinderModule(r, c, 0, 0) ||
              _isFinderModule(r, c, 0, grid - 7) ||
              _isFinderModule(r, c, grid - 7, 0);
        } else if (r == 6 || c == 6) {
          // Timing pattern
          dark = (r + c).isEven;
        } else if (r >= grid - 9 &&
            r <= grid - 5 &&
            c >= grid - 9 &&
            c <= grid - 5) {
          // Alignment pattern (5x5)
          final dr = r - (grid - 7);
          final dc = c - (grid - 7);
          dark = dr.abs() == 2 || dc.abs() == 2 || (dr == 0 && dc == 0);
        } else {
          final byteVal = bytes[(bitIdx ~/ 8) % bytes.length];
          final bitOffset = bitIdx % 8;
          dark = ((byteVal >> bitOffset) & 1) == 1;
          bitIdx++;
        }

        if (dark) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell + 0.35, cell + 0.35),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) =>
      oldDelegate.payload != payload;
}
