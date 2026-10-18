import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Production Font Assets Integrity & Loading Tests', () {
    const requiredFonts = <String>[
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Bold.ttf',
      'assets/fonts/SpaceGrotesk.ttf',
      'assets/fonts/SpaceGrotesk-Medium.ttf',
      'assets/fonts/SpaceGrotesk-SemiBold.ttf',
      'assets/fonts/SpaceGrotesk-Bold.ttf',
    ];

    test('all 8 bundled font binaries exist and contain valid TrueType signatures', () {
      for (final fontPath in requiredFonts) {
        final file = File(fontPath);
        expect(file.existsSync(), isTrue, reason: '$fontPath must exist in repository');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(10000), reason: '$fontPath must be substantial binary');
        
        // TrueType sfntVersion must be 0x00010000 (b'\x00\x01\x00\x00')
        expect(bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0, isTrue,
            reason: '$fontPath must have 0x00010000 TrueType magic header');

        // Must not contain any U+FFFD (0xEF 0xBF 0xBD) corruption sequences
        bool hasUfffd = false;
        for (int i = 0; i < bytes.length - 2; i++) {
          if (bytes[i] == 0xEF && bytes[i + 1] == 0xBF && bytes[i + 2] == 0xBD) {
            hasUfffd = true;
            break;
          }
        }
        expect(hasUfffd, isFalse, reason: '$fontPath must not contain U+FFFD replacement bytes');
      }
    });

    testWidgets('production Space Grotesk and Inter load and render proportional letterforms', (tester) async {
      await tester.runAsync(() async {
        // Load production Space Grotesk
        final sgBytes = File('assets/fonts/SpaceGrotesk.ttf').readAsBytesSync();
        await ui.loadFontFromList(sgBytes, fontFamily: 'SpaceGrotesk');
        await ui.loadFontFromList(sgBytes, fontFamily: 'Space Grotesk');

        // Load production Inter
        final interBytes = File('assets/fonts/Inter-Regular.ttf').readAsBytesSync();
        await ui.loadFontFromList(interBytes, fontFamily: 'Inter');
      });

      // Verification via ParagraphBuilder metrics:
      // Proportional font: 'M' is significantly wider than 'i'.
      // Mock Ahem font: all glyphs are square (width == height, so 'M' width == 'i' width).
      double measureWidth(String text, String fontFamily) {
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          fontFamily: fontFamily,
          fontSize: 32.0,
        ))
          ..addText(text);
        final paragraph = builder.build()
          ..layout(const ui.ParagraphConstraints(width: double.infinity));
        return paragraph.maxIntrinsicWidth;
      }

      final sgWidthI = measureWidth('i', 'SpaceGrotesk');
      final sgWidthM = measureWidth('M', 'SpaceGrotesk');
      expect(sgWidthM, greaterThan(sgWidthI * 1.5),
          reason: 'Space Grotesk must have proportional glyph advance widths (M > 1.5 * i)');

      final interWidthI = measureWidth('i', 'Inter');
      final interWidthM = measureWidth('M', 'Inter');
      expect(interWidthM, greaterThan(interWidthI * 1.5),
          reason: 'Inter must have proportional glyph advance widths (M > 1.5 * i)');
    });
  });
}
