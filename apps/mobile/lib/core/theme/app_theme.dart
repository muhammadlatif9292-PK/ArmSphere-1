import 'package:flutter/material.dart';
import '../routing/page_transitions.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF1E293B);
  static const Color elevatedSurface = Color(0xFF0F172A);
  static const Color surfaceElevated = Color(0xFF0F172A);
  static const Color border = Color(0xFF334155);
  
  // Accents
  static const Color primaryAccent = Color(0xFFEF4444); // Crimson
  static const Color secondaryAccent = Color(0xFFF59E0B); // Amber
  static const Color accentOrange = Color(0xFFF97316); // Orange accent
  
  // Luxury Gold Accents (Concept 2 - Glass Morphism Luxury)
  static const Color goldPrimary = Color(0xFFD4AF37); // Champagne Gold
  static const Color goldLight = Color(0xFFF5E096); // Soft Gold Sheen
  static const Color goldDark = Color(0xFF997A15); // Burnished Gold
  static const Color goldGlow = Color(0x33D4AF37); // 20% Gold Glow
  static const Color glassSurface = Color(0xDD121622); // Deep Glass Surface
  static const Color glassBorder = Color(0x26D4AF37); // 15% Gold Border
  
  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color error = Color(0xFFFF5252); // High-contrast Coral Red (passes 4.5:1 against surface & bg)
  static const Color warning = Color(0xFFF97316); // Orange (distinguishable from Amber)
  static const Color info = Color(0xFF38BDF8); // Calm Sky Blue (neutral/informational, 8.94:1 vs bg, 6.83:1 vs surface)
  static const Color highlightPurple = Color(0xFFC084FC); // Distinct Purple (public event indicator, 7.25:1 vs bg, 5.54:1 vs surface)
  
  // Neutral Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF8493A5); // High-contrast Muted Slate Blue (passes 4.5:1 against surface & bg)

  // Spacing Scale
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Animation Durations
  static const Duration animationNormal = Duration(milliseconds: 300);

  // Border Radius Scale
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusCircular = 999.0;

  // Font Families
  static const String fontDisplay = 'SpaceGrotesk';
  static const String fontBody = 'Inter';
  static const String fontMono = 'SpaceGrotesk';

  // Active / Live card glow
  static BoxShadow liveGlow() {
    return BoxShadow(
      color: primaryAccent.withOpacity(0.3),
      blurRadius: 8.0,
      spreadRadius: 1.0,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryAccent,
      colorScheme: const ColorScheme.dark(
        background: background,
        surface: surface,
        primary: primaryAccent,
        secondary: secondaryAccent,
        error: error,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      dividerColor: border,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          color: textMuted,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        shadowColor: Colors.black.withOpacity(0.5),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: border, width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: textPrimary,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
        },
      ),
    );
  }
}
