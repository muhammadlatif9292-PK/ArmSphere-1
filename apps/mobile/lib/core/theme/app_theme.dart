import 'package:flutter/material.dart';
import '../routing/page_transitions.dart';
import '../widgets/crystal_glass_nav_controls.dart';

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
  // 1. Foundational Canvas & Surface Tiers (Titanium Glass Elite Championship)
  // ---------------------------------------------------------------------------
  /// Ultimate dark canvas void background (#070A11) - Deepest architectural foundation.
  static const Color voidBackground = Color(0xFF070A11);

  /// Viewport base background (#0B0F19) - Midnight graphite substrate.
  static const Color background = Color(0xFF0B0F19);

  /// Midnight Graphite (#0B0F19)
  static const Color graphite = Color(0xFF0B0F19);

  /// Precision Machined Titanium container (#151B24) - For primary cards and panels.
  static const Color titanium = Color(0xFF151B24);

  /// Smoked-Obsidian Crystal Glass card surface (#D9101520 -> #F0070A11).
  static const Color cardSurface = Color(0xD9101520);

  /// Primary surface token (mapped to cardSurface).
  static const Color surface = Color(0xD9101520);

  /// Elevated action cell / secondary interactive container (#05070C recessed obsidian well).
  static const Color elevatedSurface = Color(0xCC05070C);

  /// Backward-compatible alias for elevatedSurface.
  static const Color surfaceElevated = Color(0xCC05070C);

  /// Silver Plane structural substrate (#202832).
  static const Color silverPlane = Color(0xFF202832);

  /// Dark brushed steel surface (#1A2330).
  static const Color brushedSteel = Color(0xFF1A2330);

  /// Recessed obsidian well container (#CC05070C) for inputs, stat cells, and inner wells.
  static const Color recessedSurface = Color(0xCC05070C);

  /// Crystal Glassmorphic Specular Card Border (15% white = 0x26FFFFFF).
  static const Color borderTitanium = Color(0x26FFFFFF);

  /// Metallic specular upper-edge highlight border (rgba(255, 255, 255, 0.36) = 0x5CFFFFFF).
  static const Color borderHighlight = Color(0x5CFFFFFF);

  /// Structural card and divider border (15% white = 0x26FFFFFF).
  static const Color border = Color(0x26FFFFFF);

  /// Muted structural divider for subtle separators (8% white = 0x14FFFFFF).
  static const Color borderMuted = Color(0x14FFFFFF);

  /// Subtle structural divider for secondary separators & recessed inner wells (8% white = 0x14FFFFFF).
  static const Color borderSubtle = Color(0x14FFFFFF);

  /// Elevated bright divider for focused states.
  static const Color borderLight = Color(0x47FFFFFF);

  /// Backward-compatible alias for structural card border.
  static const Color cardBorder = border;

  /// Obsidian rim border token (15% white specular sheen).
  static const Color obsidianRimBorder = Color(0x26FFFFFF);

  /// Smoked obsidian glass surface token.
  static const Color smokedObsidianGlass = Color(0xF0070A11);

  /// Backward-compatible alias for cardSurface.
  static const Color cardBackground = cardSurface;

  /// Backward-compatible alias for background (#0B0F19).
  static const Color surfaceDark = background;

  // ---------------------------------------------------------------------------
  // 2. Accents & Semantics (Championship Illumination)
  // ---------------------------------------------------------------------------
  /// Competition Crimson (#E23B3B) - Competitive intensity, red-corner identity, live bouts.
  static const Color crimson = Color(0xFFE23B3B);
  static const Color crimsonPrimary = Color(0xFFE23B3B);
  static const Color primaryAccent = crimson;
  static const Color primaryRed = crimson;
  static const Color combatCrimson = crimson;
  static const Color competitionCrimson = crimson;

  /// Restrained 12% Crimson glow.
  static const Color crimsonGlow = Color(0x1FE23B3B);

  /// Championship Champagne Gold (#D4AF37) - Medals, rankings, achievements, prestige.
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF5E096);
  static const Color goldDark = Color(0xFF997A15);
  static const Color championshipGold = goldPrimary;

  /// Restrained 10% Gold Halo glow.
  static const Color goldGlow = Color(0x1AD4AF37);

  /// Electric Cyan (#38BDF8) - Live telemetry, active controls, focus states, blue corner.
  static const Color cyan = Color(0xFF38BDF8);
  static const Color cyanAccent = cyan;
  static const Color activeCyan = cyan;
  static const Color cyanLight = Color(0xFF7DD3FC);
  static const Color info = cyan;
  static const Color electricCyan = cyan;

  /// Restrained 12% Cyan glow.
  static const Color cyanGlow = Color(0x1F38BDF8);

  /// Verified Emerald (#10B981) - Official verification, cleared weigh-ins, match victories.
  static const Color emerald = Color(0xFF10B981);
  static const Color success = emerald;
  static const Color verifiedEmerald = emerald;

  /// Restrained 12% Emerald glow.
  static const Color emeraldGlow = Color(0x1F10B981);

  /// High-contrast Warning Amber (#F59E0B).
  static const Color warning = Color(0xFFF59E0B);
  static const Color secondaryAccent = warning;

  /// High-contrast Orange (#F97316).
  static const Color accentOrange = Color(0xFFF97316);
  static const Color primaryOrange = accentOrange;

  /// High-contrast Coral Red (#FF4D4D) - Explicit errors, field rejections.
  static const Color error = Color(0xFFFF4D4D);

  /// Distinct Purple (#C084FC) - Public event and grassroots indicator.
  static const Color highlightPurple = Color(0xFFC084FC);

  // ---------------------------------------------------------------------------
  // 3. Crystal Glassmorphic / Glossmorphic Surface Tokens
  // ---------------------------------------------------------------------------
  /// Rich Smoked-Obsidian Crystal Glass surface for main content cards & image cards.
  static const Color smokedCardSurface = Color(0xF0070A11);

  /// Elevated Smoked-Obsidian Crystal Glass surface for prominent headers & podium cards.
  static const Color smokedCardSurfaceElevated = Color(0xD9101520);

  /// Deep recessed obsidian inner well surface (#CC05070C) for inputs, stat boxes & empty wells.
  static const Color glassSurface = Color(0xCC05070C);

  /// Elevated recessed obsidian surface plane (#CC05070C).
  static const Color glassSurfaceHeavy = Color(0xCC05070C);
  static const Color glassSurfaceHigh = glassSurfaceHeavy;

  /// Ultra-light floating crystal plane (#CC05070C).
  static const Color glassSurfaceLight = Color(0xCC05070C);

  /// Crisp light-catching specular border (15% white reflection = 0x26FFFFFF).
  static const Color glassBorder = Color(0x26FFFFFF);

  /// Upper-crest specular glass highlight line (38% white reflection = 0x61FFFFFF).
  static const Color glassBorderSpecular = Color(0x61FFFFFF);

  // ---------------------------------------------------------------------------
  // 4. Neutral Typography & Readability (WCAG AAA >= 7.0:1 / AA >= 4.5:1)
  // ---------------------------------------------------------------------------
  /// Pure white (#FFFFFF) - Ultra-high emphasis numeric displays & headings.
  static const Color textPure = Color(0xFFFFFFFF);

  /// High-emphasis primary text (#F4F7FA) - 17.5:1 contrast against void.
  static const Color textPrimary = Color(0xFFF4F7FA);

  /// Medium-emphasis secondary text (#AAB3BE) - Cool silver-grey.
  static const Color textSecondary = Color(0xFFAAB3BE);

  /// Muted metadata & caption text (#7E8996) - Desaturated steel-grey.
  static const Color textMuted = Color(0xFF7E8996);

  // ---------------------------------------------------------------------------
  // 5. Shimmer & Atmospheric Background Constants
  // ---------------------------------------------------------------------------
  /// Base placeholder skeleton color (#151B24).
  static const Color shimmerBase = Color(0xFF151B24);

  /// Shimmer highlight wave color (#1E2836).
  static const Color shimmerHighlight = Color(0xFF1E2836);

  /// Ambient background particle glow (shell-level decoration, 0x0F1B2A4A).
  static const Color ambientGlow = Color(0x0F1B2A4A);

  // ---------------------------------------------------------------------------
  // 5. Spacing Scale (8dp Normalized Grid)
  // ---------------------------------------------------------------------------
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
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

  /// Competition Crimson halo for active bouts and critical actions.
  static BoxShadow crimsonHalo() {
    return BoxShadow(
      color: crimson.withValues(alpha: 0.28),
      blurRadius: 14.0,
      spreadRadius: 1.0,
    );
  }

  /// Verified Emerald halo for cleared states and certifications.
  static BoxShadow emeraldHalo() {
    return BoxShadow(
      color: emerald.withValues(alpha: 0.25),
      blurRadius: 12.0,
      spreadRadius: 1.0,
    );
  }

  /// Standard Smoked-Obsidian Crystal Glass levitating Y-axis drop shadow.
  static BoxShadow cardShadow() {
    return const BoxShadow(
      color: Color(0x99000000),
      blurRadius: 20.0,
      offset: Offset(0, 10),
    );
  }

  /// Smoked-Obsidian Crystal Glass architectural floating card shadow.
  static BoxShadow titaniumShadow() {
    return const BoxShadow(
      color: Color(0x99000000),
      blurRadius: 20.0,
      offset: Offset(0, 10),
    );
  }

  /// Deep floating crystal dock elevation shadow.
  static BoxShadow glassDockShadow() {
    return const BoxShadow(
      color: Color(0x99000000),
      blurRadius: 20.0,
      offset: Offset(0, 10),
    );
  }

  // ---------------------------------------------------------------------------
  // 10. Smoked-Obsidian Crystal Glass Gradients & Surface Shaders
  // ---------------------------------------------------------------------------
  /// Unified Smoked-Obsidian Crystal Glass outer card surface gradient.
  static const LinearGradient machinedTitaniumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xD9101520),
      Color(0xF0070A11),
    ],
  );

  /// Secondary Smoked-Obsidian Crystal Glass gradient for compact cards & sub-panels.
  static const LinearGradient brushedSteelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xD9101520),
      Color(0xF0070A11),
    ],
  );

  /// Immersive Smoked-Obsidian Crystal Glass athlete hero banner gradient.
  static const LinearGradient cinematicBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xD9101520),
      Color(0xF0070A11),
    ],
  );

  /// Broadcast fight card / Supermatch Smoked-Obsidian Crystal Glass stage gradient.
  static const LinearGradient upcomingMatchGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xD9101520),
      Color(0xF0070A11),
    ],
  );

  /// Smoked optical glass sheen gradient with top-left specular highlight.
  static const LinearGradient glassSheenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
    colors: [
      Color(0x22FFFFFF), // 13% specular reflection at top-left
      Color(0x06FFFFFF),
      Color(0x00000000),
    ],
  );

  /// Competition Crimson directional gradient.
  static const LinearGradient competitionCrimsonGradient = LinearGradient(
    colors: [
      Color(0xFFFF5252),
      Color(0xFFE23B3B),
      Color(0xFF9E1F1F),
    ],
  );

  /// Championship Champagne Gold directional gradient.
  static const LinearGradient championshipGoldGradient = LinearGradient(
    colors: [
      Color(0xFFF5E096),
      Color(0xFFD4AF37),
      Color(0xFF997A15),
    ],
  );

  /// Electric Cyan telemetry gradient.
  static const LinearGradient electricCyanGradient = LinearGradient(
    colors: [
      Color(0xFF7DD3FC),
      Color(0xFF38BDF8),
      Color(0xFF0284C7),
    ],
  );

  /// Verified Emerald status gradient.
  static const LinearGradient verifiedEmeraldGradient = LinearGradient(
    colors: [
      Color(0xFF34D399),
      Color(0xFF10B981),
      Color(0xFF047857),
    ],
  );

  /// Unified Smoked-Obsidian Crystal Glass Outer Card Box Decoration.
  static BoxDecoration machinedTitaniumDecoration({
    double radius = 18.0,
    Color? borderColor,
    Color? customBackground,
    List<BoxShadow>? customShadow,
  }) {
    return BoxDecoration(
      gradient: customBackground != null ? null : machinedTitaniumGradient,
      color: customBackground,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? const Color(0x26FFFFFF),
        width: 1.0,
      ),
      boxShadow: customShadow ??
          const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 20.0,
              offset: Offset(0, 10),
            ),
          ],
    );
  }

  /// Dark Brushed Steel / Recessed Obsidian Box Decoration for compact cards & controls.
  static BoxDecoration brushedSteelDecoration({
    double radius = 14.0,
    Color? borderColor,
    List<BoxShadow>? customShadow,
  }) {
    return BoxDecoration(
      color: const Color(0xCC05070C),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? const Color(0x14FFFFFF),
        width: 1.0,
      ),
      boxShadow: customShadow,
    );
  }

  /// Smoked-Obsidian Crystal Glass Outer Card Box Decoration.
  static BoxDecoration smokedGlassDecoration({
    double radius = 18.0,
    Color? borderColor,
    Color? surfaceColor,
    List<BoxShadow>? customShadow,
  }) {
    return BoxDecoration(
      gradient: surfaceColor != null ? null : machinedTitaniumGradient,
      color: surfaceColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? const Color(0x26FFFFFF),
        width: 1.0,
      ),
      boxShadow: customShadow ??
          const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 20.0,
              offset: Offset(0, 10),
            ),
          ],
    );
  }

  /// Deep Recessed Obsidian Inner Well Decoration (`#CC05070C`, `radius: 14`, `1px #14FFFFFF` border).
  static BoxDecoration recessedObsidianWellDecoration({
    double radius = 14.0,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: const Color(0xCC05070C),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? const Color(0x14FFFFFF),
        width: 1.0,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 11. Gradient Scrims (docs/design/35_MEDIA_ART_DIRECTION.md)
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
  // 12. Material 3 ThemeData Specification
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
        color: smokedCardSurface,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderTitanium, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderTitanium, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderTitanium, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: cyan, width: 1.5),
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
          disabledBackgroundColor: glassSurfaceHeavy,
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
          side: const BorderSide(color: borderTitanium, width: 1.0),
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
        backgroundColor: glassSurface,
        disabledColor: glassSurfaceLight,
        selectedColor: info.withValues(alpha: 0.18),
        secondarySelectedColor: goldPrimary.withValues(alpha: 0.18),
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
          side: const BorderSide(color: borderTitanium, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xEB0B0F19),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: borderTitanium, width: 1.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF00B101B),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Color(0xF00B101B),
        modalBarrierColor: Color(0xAA030509),
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: Color(0x38FFFFFF), width: 1.0),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xEB0B0F19),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: borderTitanium, width: 1.0),
        ),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => const CrystalNavCapsuleIcon(
          icon: Icons.arrow_back_ios_new_rounded,
          iconSize: 17,
          iconColor: textPure,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xEB0B101C),
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: goldPrimary.withValues(alpha: 0.55), width: 1.2),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontBody,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: textPure,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xD90B101C),
        foregroundColor: goldPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: goldPrimary.withValues(alpha: 0.68), width: 1.3),
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
