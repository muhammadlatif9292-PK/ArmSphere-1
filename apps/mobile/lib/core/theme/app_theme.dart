import 'package:flutter/material.dart';
import '../routing/page_transitions.dart';

/// ArmSphere Design System & Theme Engine
///
/// Authoritative theme token definitions grounded in `docs/design/07_COLOR_AND_THEME_TOKENS.md`
/// and `docs/design/06_DESIGN_SYSTEM.md`.
///
/// Features:
/// - 4-tier surface architecture (void -> background -> cardSurface -> elevatedSurface)
/// - Mathematically verified WCAG AA / AAA contrast ratios
/// - Normalized spatial grid (8dp base) and border radii (8dp, 12dp, 16dp)
/// - Directional 4-stop image text scrims
/// - Centralized Material 3 ThemeData with form, button, and card decorators
class AppTheme {
  // ---------------------------------------------------------------------------
  // 1. Foundational Canvas & Surface Tiers
  // ---------------------------------------------------------------------------
  /// Ultimate dark canvas void background (#070A11) - 18.2:1 contrast against textPrimary.
  static const Color voidBackground = Color(0xFF070A11);

  /// Viewport base background (#0B0F19) - Elevated substrate.
  static const Color background = Color(0xFF0B0F19);

  /// Base solid card container (#121826) - For rankings, feed items, and forms.
  static const Color cardSurface = Color(0xFF121826);

  /// Primary surface token (mapped to cardSurface #121826 for consistency).
  static const Color surface = Color(0xFF121826);

  /// Elevated action cell / secondary interactive container (#1E293B).
  static const Color elevatedSurface = Color(0xFF1E293B);

  /// Backward-compatible alias for elevatedSurface.
  static const Color surfaceElevated = Color(0xFF1E293B);

  /// Structural card and divider border (#334155 at 1.0px).
  static const Color border = Color(0xFF334155);

  /// Muted structural divider for subtle separators (#1E293B).
  static const Color borderMuted = Color(0xFF1E293B);

  /// Elevated bright divider for focused states (#475569).
  static const Color borderLight = Color(0xFF475569);

  // ---------------------------------------------------------------------------
  // 2. Accents & Semantics (WCAG AA/AAA Compliant)
  // ---------------------------------------------------------------------------
  /// Coral Crimson (#EF4444) - Table fouls, match losses, forfeits, and live alerts.
  static const Color primaryAccent = Color(0xFFEF4444);

  /// Amber Gold (#F59E0B) - Warnings, pending sanctions, and in-straps status.
  static const Color secondaryAccent = Color(0xFFF59E0B);

  /// High-contrast Orange (#F97316) - Distinguishable operational warnings.
  static const Color accentOrange = Color(0xFFF97316);

  /// Champagne Gold (#D4AF37) - Medals, championship belts, and high-prestige CTAs.
  static const Color goldPrimary = Color(0xFFD4AF37);

  /// Soft Gold Sheen (#F5E096) - Subtle gold highlight.
  static const Color goldLight = Color(0xFFF5E096);

  /// Burnished Gold (#997A15) - Deep gold shadow tone.
  static const Color goldDark = Color(0xFF997A15);

  /// 20% Gold Halo glow (0x33D4AF37).
  static const Color goldGlow = Color(0x33D4AF37);

  /// Deep Glass Surface (#121622 at 0.85 opacity).
  static const Color glassSurface = Color(0xDD121622);

  /// 15% Gold Border (#D4AF37 at 0.15 opacity).
  static const Color glassBorder = Color(0x26D4AF37);

  /// Emerald Mint (#10B981) - Match wins, cleared weigh-ins, valid certifications.
  static const Color success = Color(0xFF10B981);

  /// High-contrast Coral Red (#FF5252) - Explicit errors, field rejections.
  static const Color error = Color(0xFFFF5252);

  /// High-contrast Warning Orange (#F97316).
  static const Color warning = Color(0xFFF97316);

  /// Luminous Sky Blue / Cyan (#38BDF8) - Live telemetry, active table calls, 8.94:1 contrast.
  static const Color info = Color(0xFF38BDF8);

  /// Cool Cyan Accent (#38BDF8) - Table telemetry and structural lines.
  static const Color cyanAccent = Color(0xFF38BDF8);

  /// Soft Ice Blue (#7DD3FC) - Highlights and active chip fills.
  static const Color cyanLight = Color(0xFF7DD3FC);

  /// Distinct Purple (#C084FC) - Public event and grassroots indicator.
  static const Color highlightPurple = Color(0xFFC084FC);

  // ---------------------------------------------------------------------------
  // 3. Neutral Typography & Readability (WCAG AAA >= 7.0:1 / AA >= 4.5:1)
  // ---------------------------------------------------------------------------
  /// High-emphasis primary text (#F8FAFC) - 18.2:1 contrast against canvas.
  static const Color textPrimary = Color(0xFFF8FAFC);

  /// Medium-emphasis secondary text (#94A3B8) - 7.8:1 contrast.
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Muted metadata & caption text (#8493A5) - 4.8:1 contrast (passes WCAG AA 4.5:1).
  static const Color textMuted = Color(0xFF8493A5);

  // ---------------------------------------------------------------------------
  // 4. Shimmer & Atmospheric Background Constants
  // ---------------------------------------------------------------------------
  /// Base placeholder skeleton color (#121826).
  static const Color shimmerBase = Color(0xFF121826);

  /// Shimmer highlight wave color (#1E293B).
  static const Color shimmerHighlight = Color(0xFF1E293B);

  /// Ambient background particle glow (shell-level decoration, 0x0F1B2A4A).
  static const Color ambientGlow = Color(0x0F1B2A4A);

  // ---------------------------------------------------------------------------
  // 5. Spacing Scale (8dp Normalized Grid)
  // ---------------------------------------------------------------------------
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ---------------------------------------------------------------------------
  // 6. Border Radius Scale
  // ---------------------------------------------------------------------------
  /// 8dp - Compact tags, badges, scorepad chips, and inner selectors.
  static const double radiusSmall = 8.0;

  /// 12dp - Standard cards, text form fields, dialog boxes, and action buttons.
  static const double radiusMedium = 12.0;

  /// 16dp - Modal bottom sheets, hero cards, and tournament banners.
  static const double radiusLarge = 16.0;

  /// 24dp - Specialized floating dialogs and prominent action sheets.
  static const double radiusXLarge = 24.0;

  /// 999dp - Circular avatars and small indicator pills ONLY.
  /// BANNED: Never use radiusCircular on primary form action buttons.
  static const double radiusCircular = 999.0;

  // ---------------------------------------------------------------------------
  // 7. Motion & Duration Tiers (docs/design/11_MOTION_SYSTEM.md)
  // ---------------------------------------------------------------------------
  /// Level 0: Micro Feedback (120ms) - Tap down, scale depression, score increment.
  static const Duration durationMicro = Duration(milliseconds: 120);

  /// Level 1: Local Transitions (220ms) - Sheet opens, accordion expand, chip filter.
  static const Duration durationLocal = Duration(milliseconds: 220);

  /// Level 2: Navigation Routes (280ms) - Push/pop page transitions.
  static const Duration durationRoute = Duration(milliseconds: 280);

  /// Level 3: Feature Moments (500ms) - Match win, ELO count-up, bracket pan snap.
  static const Duration durationFeature = Duration(milliseconds: 500);

  /// Level 4: Cinematic Moments (900ms) - Splash boot, championship crowning.
  static const Duration durationCinematic = Duration(milliseconds: 900);

  /// Standard backward-compatible animation duration (300ms).
  static const Duration animationNormal = Duration(milliseconds: 300);

  // ---------------------------------------------------------------------------
  // 8. Typography Fonts (Verified in assets/fonts/)
  // ---------------------------------------------------------------------------
  /// SpaceGrotesk: Display headings, numbers, scores, ELO ratings, and monospace counters.
  static const String fontDisplay = 'SpaceGrotesk';

  /// Inter: High-legibility UI prose, form labels, body text, and captions.
  static const String fontBody = 'Inter';

  /// Monospace / Numeric font family.
  static const String fontMono = 'SpaceGrotesk';

  // ---------------------------------------------------------------------------
  // 9. Shadows & Directional Halos
  // ---------------------------------------------------------------------------
  /// Active / Live card glow.
  static BoxShadow liveGlow() {
    return BoxShadow(
      color: primaryAccent.withValues(alpha: 0.3),
      blurRadius: 8.0,
      spreadRadius: 1.0,
    );
  }

  /// Restrained Champagne Gold halo for championship cards.
  static BoxShadow goldHalo() {
    return BoxShadow(
      color: goldPrimary.withValues(alpha: 0.25),
      blurRadius: 16.0,
      spreadRadius: 1.0,
    );
  }

  /// Restrained Luminous Cyan halo for active table telemetry.
  static BoxShadow cyanHalo() {
    return BoxShadow(
      color: cyanAccent.withValues(alpha: 0.25),
      blurRadius: 12.0,
      spreadRadius: 1.0,
    );
  }

  /// Standard card elevation shadow.
  static BoxShadow cardShadow() {
    return BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 10.0,
      offset: const Offset(0, 4),
    );
  }

  // ---------------------------------------------------------------------------
  // 10. Gradient Scrims (docs/design/35_MEDIA_ART_DIRECTION.md)
  // ---------------------------------------------------------------------------
  /// Directional 4-stop hero gradient scrim for guaranteed text legibility over photography.
  static BoxDecoration heroScrim() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.40, 0.75, 1.0],
        colors: [
          Color(0x00070A11), // 0% opacity at top
          Color(0x33070A11), // 20% opacity at 40% height
          Color(0xCC070A11), // 80% opacity at 75% height
          Color(0xFF070A11), // 100% solid background at bottom
        ],
      ),
    );
  }

  /// Radial vignette scrim for athlete profile cutouts and Tale of the Tape.
  static BoxDecoration cutoutRadialScrim() {
    return BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 0.85,
        stops: const [0.30, 0.70, 1.0],
        colors: [
          Color(0x000B0F19),
          Color(0x880B0F19),
          Color(0xFF0B0F19),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 11. Material 3 ThemeData Specification
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: goldPrimary,
      colorScheme: const ColorScheme.dark(
        surface: cardSurface,
        surfaceContainer: elevatedSurface,
        primary: goldPrimary,
        secondary: secondaryAccent,
        error: error,
        onSurface: textPrimary,
        onPrimary: voidBackground,
        onSecondary: voidBackground,
        outline: border,
      ),
      dividerColor: border,
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1.0,
        space: 1.0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          fontSize: 32.0,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          fontSize: 28.0,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          fontSize: 24.0,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w700,
          fontSize: 22.0,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w600,
          fontSize: 18.0,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          fontSize: 16.0,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          fontSize: 15.0,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          fontSize: 13.0,
          color: textSecondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 16.0,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 14.0,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 12.0,
          color: textMuted,
          height: 1.3,
        ),
        labelLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          fontSize: 14.0,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          fontSize: 12.0,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 11.0,
          color: textMuted,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        elevation: 2.0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: border, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: info, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontBody,
          color: textSecondary,
          fontSize: 14.0,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontBody,
          color: textMuted,
          fontSize: 14.0,
        ),
        errorStyle: const TextStyle(
          fontFamily: fontBody,
          color: error,
          fontSize: 12.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldPrimary,
          foregroundColor: voidBackground,
          disabledBackgroundColor: elevatedSurface,
          disabledForegroundColor: textMuted,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w600,
            fontSize: 15.0,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          disabledForegroundColor: textMuted,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          side: const BorderSide(color: border, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: info,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: elevatedSurface,
        disabledColor: elevatedSurface.withValues(alpha: 0.5),
        selectedColor: info.withValues(alpha: 0.2),
        secondarySelectedColor: goldPrimary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(
          fontFamily: fontBody,
          color: textPrimary,
          fontSize: 12.0,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontBody,
          color: goldLight,
          fontSize: 12.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: border, width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: textPrimary, size: 24),
        titleTextStyle: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardSurface,
        elevation: 0,
        selectedItemColor: goldPrimary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          fontSize: 11.0,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 11.0,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Official Design Authority Canonical Alias
typedef ArmSphereTheme = AppTheme;
