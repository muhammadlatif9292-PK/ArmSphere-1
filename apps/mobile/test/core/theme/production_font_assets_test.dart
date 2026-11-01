import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

int _findTableOffset(Uint8List bytes, String tableTag) {
  final bd = ByteData.sublistView(bytes);
  final numTables = bd.getUint16(4);
  final tagCode = (tableTag.codeUnitAt(0) << 24) |
      (tableTag.codeUnitAt(1) << 16) |
      (tableTag.codeUnitAt(2) << 8) |
      tableTag.codeUnitAt(3);
  for (int i = 0; i < numTables; i++) {
    final off = 12 + i * 16;
    if (bd.getUint32(off) == tagCode) {
      return bd.getUint32(off + 8);
    }
  }
  return -1;
}

int _getWeightClass(Uint8List bytes) {
  final os2Off = _findTableOffset(bytes, 'OS/2');
  if (os2Off == -1 || os2Off + 6 > bytes.length) return -1;
  return ByteData.sublistView(bytes).getUint16(os2Off + 4);
}

bool _containsFamilyName(Uint8List bytes, String expectedFamily) {
  final nameOff = _findTableOffset(bytes, 'name');
  if (nameOff == -1 || nameOff + 6 > bytes.length) return false;
  final bd = ByteData.sublistView(bytes);
  final count = bd.getUint16(nameOff + 2);
  final stringStorage = nameOff + bd.getUint16(nameOff + 4);

  for (int i = 0; i < count; i++) {
    final rec = nameOff + 6 + i * 12;
    if (rec + 12 > bytes.length) break;
    final pid = bd.getUint16(rec);
    final nameId = bd.getUint16(rec + 6);
    final length = bd.getUint16(rec + 8);
    final nOff = bd.getUint16(rec + 10);

    // NameID 1 is Font Family name
    if (nameId == 1 && stringStorage + nOff + length <= bytes.length) {
      final sub = bytes.sublist(stringStorage + nOff, stringStorage + nOff + length);
      String decoded = '';
      if (pid == 0 || pid == 3) {
        // UTF-16BE
        final chars = <int>[];
        for (int c = 0; c < sub.length - 1; c += 2) {
          chars.add((sub[c] << 8) | sub[c + 1]);
        }
        decoded = String.fromCharCodes(chars);
      } else {
        decoded = String.fromCharCodes(sub);
      }
      if (decoded.contains(expectedFamily)) {
        return true;
      }
    }
  }
  return false;
}

void main() {
  group('Production Font Assets Integrity & Loading Tests', () {
    const requiredFonts = <({String path, String family, int weight})>[
      (path: 'assets/fonts/Inter-Regular.ttf', family: 'Inter', weight: 400),
      (path: 'assets/fonts/Inter-Medium.ttf', family: 'Inter', weight: 500),
      (path: 'assets/fonts/Inter-SemiBold.ttf', family: 'Inter', weight: 600),
      (path: 'assets/fonts/Inter-Bold.ttf', family: 'Inter', weight: 700),
      (path: 'assets/fonts/SpaceGrotesk.ttf', family: 'Space Grotesk', weight: 400),
      (path: 'assets/fonts/SpaceGrotesk-Medium.ttf', family: 'Space Grotesk', weight: 500),
      (path: 'assets/fonts/SpaceGrotesk-SemiBold.ttf', family: 'Space Grotesk', weight: 600),
      (path: 'assets/fonts/SpaceGrotesk-Bold.ttf', family: 'Space Grotesk', weight: 700),
    ];

    test('all 8 bundled font binaries exist, have valid sfnt headers and 0 U+FFFD bytes', () {
      for (final font in requiredFonts) {
        final file = File(font.path);
        expect(file.existsSync(), isTrue, reason: '${font.path} must exist in repository');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(10000), reason: '${font.path} must be substantial binary');
        
        // TrueType sfntVersion must be 0x00010000 (b'\x00\x01\x00\x00')
        expect(bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0, isTrue,
            reason: '${font.path} must have 0x00010000 TrueType magic header');

        // Must not contain any U+FFFD (0xEF 0xBF 0xBD) corruption sequences
        bool hasUfffd = false;
        for (int i = 0; i < bytes.length - 2; i++) {
          if (bytes[i] == 0xEF && bytes[i + 1] == 0xBF && bytes[i + 2] == 0xBD) {
            hasUfffd = true;
            break;
          }
        }
        expect(hasUfffd, isFalse, reason: '${font.path} must not contain U+FFFD replacement bytes');
      }
    });

    test('all 8 font binaries declare intended family names and weights in OpenType tables', () {
      for (final font in requiredFonts) {
        final bytes = File(font.path).readAsBytesSync();
        
        // 1. Verify OS/2 table weight class matches pubspec declaration
        final weight = _getWeightClass(bytes);
        expect(weight, equals(font.weight),
            reason: '${font.path} declared weight ${font.weight} must match OS/2 table usWeightClass');

        // 2. Verify name table NameID 1 contains intended family name
        final hasFamily = _containsFamilyName(bytes, font.family);
        expect(hasFamily, isTrue,
            reason: '${font.path} name table NameID 1 must contain family name "${font.family}"');
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
