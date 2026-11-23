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

  /// Smoked-Obsidian Crystal Glass card surface -> 100% Pure Crystal Transparent.
  static const Color cardSurface = Colors.transparent;

  /// Primary surface token (mapped to cardSurface).
  static const Color surface = Colors.transparent;

  /// Elevated action cell / secondary interactive container -> 100% Pure Crystal Transparent.
  static const Color elevatedSurface = Colors.transparent;

  /// Backward-compatible alias for elevatedSurface.
  static const Color surfaceElevated = Colors.transparent;

  /// Silver Plane structural substrate (#202832).
  static const Color silverPlane = Color(0xFF202832);

  /// Dark brushed steel surface (#1A2330).
  static const Color brushedSteel = Color(0xFF1A2330);

  /// Recessed inner well container -> 100% Pure Crystal Transparent.
  static const Color recessedSurface = Colors.transparent;

  /// Crystal Wireframe Card Boundary (22% white = 0x38FFFFFF).
  static const Color borderTitanium = Color(0x38FFFFFF);

  /// Metallic specular upper-edge highlight border (rgba(255, 255, 255, 0.36) = 0x5CFFFFFF).
  static const Color borderHighlight = Color(0x5CFFFFFF);

  /// Structural card and container border (22% white = 0x38FFFFFF).
  static const Color border = Color(0x38FFFFFF);

  /// Muted structural divider for internal row separators (13% white = 0x22FFFFFF).
  static const Color borderMuted = Color(0x22FFFFFF);

  /// Subtle structural divider for secondary separators & recessed inner wells (15% white = 0x26FFFFFF).
  static const Color borderSubtle = Color(0x26FFFFFF);

  /// Elevated bright divider for focused states.
  static const Color borderLight = Color(0x59FFFFFF);

  /// Backward-compatible alias for structural card border.
  static const Color cardBorder = border;

  /// Obsidian rim border token (22% white specular sheen).
  static const Color obsidianRimBorder = Color(0x38FFFFFF);

  /// Obsidian background color token.
  static const Color obsidian = Color(0xFF070A11);

  /// Smoked obsidian glass surface token -> 100% Pure Crystal Transparent.
  static const Color smokedObsidianGlass = Colors.transparent;

  /// Backward-compatible alias for cardSurface.
  static const Color cardBackground = cardSurface;

  /// Backward-compatible alias for background (#0B0F19).
  static const Color surfaceDark = background;

  /// Canonical G6 opaque overlay surface (#0E1118 at 96% opacity) for dialogs,
  /// bottom sheets, dropdown menus, popup menus, and date/time pickers.
  static const Color overlayG6Surface = Color(0xF50E1118);

  /// Canonical G6 overlay border (rgba(255, 255, 255, 0.16) = 0x29FFFFFF).
  static const Color overlayG6Border = Color(0x29FFFFFF);

  /// Canonical G6 backdrop scrim (70% black = 0xB3000000).
  static const Color overlayG6Barrier = Color(0xB3000000);

  /// Canonical G1/G2 scrimmed dark charcoal card fill (~83% opaque) for legible
  /// data cards & form containers over detailed 3D backdrops.
  static const Color scrimmedCardSurface = Color(0xD40B0F18);

  /// Canonical frosted dark obsidian AppBar surface (~82% #070A11).
  static const Color frostedAppBarSurface = Color(0xD1070A11);

  /// Crisp white/platinum-silver accent for Referee White Corner controls.
  static const Color cornerWhiteAccent = Color(0xFFE2E8F0);

  /// Standardized Gold Standard primary button style (24k Championship Gold).
  static ButtonStyle get primaryGoldButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: goldPrimary,
        foregroundColor: voidBackground,
        disabledBackgroundColor: const Color(0x40D4AF37),
        disabledForegroundColor: textMuted,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
      );

  /// Standardized Gold Standard destructive button style (Competition Crimson).
  static ButtonStyle get destructiveCrimsonButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: crimson,
        foregroundColor: textPure,
        disabledBackgroundColor: const Color(0x40E23B3B),
        disabledForegroundColor: textMuted,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
      );

  /// Standardized Gold Standard neutral dark glass button style.
  static ButtonStyle get neutralDarkGlassButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: scrimmedCardSurface,
        foregroundColor: textPure,
        disabledBackgroundColor: const Color(0x800B0F18),
        disabledForegroundColor: textMuted,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: overlayG6Border, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      );

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
  // 3. Crystal Glassmorphic / Glossmorphic Surface Tokens (100% Transparent)
  // ---------------------------------------------------------------------------
  /// Pure Crystal Transparent card surface.
  static const Color smokedCardSurface = Colors.transparent;

  /// Pure Crystal Transparent elevated card surface.
  static const Color smokedCardSurfaceElevated = Colors.transparent;

  /// Pure Crystal Transparent inner well surface for inputs, stat boxes & empty wells.
  static const Color glassSurface = Colors.transparent;

  /// Pure Crystal Transparent surface plane.
  static const Color glassSurfaceHeavy = Colors.transparent;
  static const Color glassSurfaceHigh = glassSurfaceHeavy;

  /// Pure Crystal Transparent floating plane.
  static const Color glassSurfaceLight = Colors.transparent;

  /// Crisp light-catching wireframe border (22% white reflection = 0x38FFFFFF).
  static const Color glassBorder = Color(0x38FFFFFF);

  /// Upper-crest specular glass highlight line (38% white reflection = 0x61FFFFFF).
  static const Color glassBorderSpecular = Color(0x61FFFFFF);

  /// Universal crisp text shadow for 100% readability over transparent wireframe cards.
  static const List<Shadow> crystalTextShadows = [
    Shadow(
      color: Color(0xE6000000),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

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
  // 9. Shadows & Directional Halos (BlurStyle.outer for transparent cards)
  // ---------------------------------------------------------------------------
  /// Active / Live card outer rim glow.
  static BoxShadow liveGlow() {
    return BoxShadow(
      color: primaryAccent.withValues(alpha: 0.3),
      blurRadius: 8.0,
      spreadRadius: 1.0,
      blurStyle: BlurStyle.outer,
    );
  }

  /// Restrained Champagne Gold outer halo for championship cards.
  static BoxShadow goldHalo() {
    return BoxShadow(
      color: goldPrimary.withValues(alpha: 0.25),
      blurRadius: 16.0,
      spreadRadius: 1.0,
      blurStyle: BlurStyle.outer,
    );
  }

  /// Restrained Luminous Cyan outer halo for active table telemetry.
  static BoxShadow cyanHalo() {
    return BoxShadow(
      color: cyanAccent.withValues(alpha: 0.25),
      blurRadius: 12.0,
      spreadRadius: 1.0,
      blurStyle: BlurStyle.outer,
    );
  }

  /// Competition Crimson outer halo for active bouts and critical actions.
  static BoxShadow crimsonHalo() {
    return BoxShadow(
      color: crimson.withValues(alpha: 0.28),
      blurRadius: 14.0,
      spreadRadius: 1.0,
      blurStyle: BlurStyle.outer,
    );
  }

  /// Verified Emerald outer halo for cleared states and certifications.
  static BoxShadow emeraldHalo() {
    return BoxShadow(
      color: emerald.withValues(alpha: 0.25),
      blurRadius: 12.0,
      spreadRadius: 1.0,
      blurStyle: BlurStyle.outer,
    );
  }

  /// Zero-fill outer shadow for transparent cards (prevents BoxShadow grey-fill bug).
  static BoxShadow cardShadow() {
    return const BoxShadow(
      color: Colors.transparent,
      blurRadius: 0.0,
      blurStyle: BlurStyle.outer,
    );
  }

  /// Zero-fill outer shadow for transparent cards.
  static BoxShadow titaniumShadow() {
    return const BoxShadow(
      color: Colors.transparent,
      blurRadius: 0.0,
      blurStyle: BlurStyle.outer,
    );
  }

  /// Zero-fill outer shadow for floating crystal dock.
  static BoxShadow glassDockShadow() {
    return const BoxShadow(
      color: Colors.transparent,
      blurRadius: 0.0,
      blurStyle: BlurStyle.outer,
    );
  }

  // ---------------------------------------------------------------------------
  // 10. Pure Crystal Transparent Gradients & Surface Shaders
  // ---------------------------------------------------------------------------
  /// 100% Transparent gradient token (backward-compatible constant).
  static const LinearGradient machinedTitaniumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.transparent,
      Colors.transparent,
    ],
  );

  /// 100% Transparent secondary gradient token.
  static const LinearGradient brushedSteelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.transparent,
      Colors.transparent,
    ],
  );

  /// 100% Transparent hero banner gradient token.
  static const LinearGradient cinematicBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.transparent,
      Colors.transparent,
    ],
  );

  /// 100% Transparent upcoming match gradient token.
  static const LinearGradient upcomingMatchGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.transparent,
      Colors.transparent,
    ],
  );

  /// 100% Transparent glass sheen gradient token.
  static const LinearGradient glassSheenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.transparent,
      Colors.transparent,
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

  /// Whisper-Dark Optical Crystal Lens Card Box Decoration (`Color(0x4704060B)`).
  static BoxDecoration machinedTitaniumDecoration({
    double radius = 18.0,
    Color? borderColor,
    Color? customBackground,
    List<BoxShadow>? customShadow,
    Color? accentGlow,
  }) {
    return BoxDecoration(
      color: customBackground ?? const Color(0x4704060B),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (accentGlow != null
                ? accentGlow.withValues(alpha: 0.5)
                : const Color(0x38FFFFFF)),
        width: 1.0,
      ),
      boxShadow: customShadow ??
          (accentGlow != null
              ? [
                  BoxShadow(
                    color: accentGlow.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: -2,
                  )
                ]
              : const []),
    );
  }

  /// Whisper-Dark Optical Crystal Lens Box Decoration for compact cards & controls.
  static BoxDecoration brushedSteelDecoration({
    double radius = 14.0,
    Color? borderColor,
    List<BoxShadow>? customShadow,
  }) {
    return BoxDecoration(
      color: const Color(0x4704060B),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? const Color(0x26FFFFFF),
        width: 1.0,
      ),
      boxShadow: const [],
    );
  }

  /// Whisper-Dark Optical Crystal Lens Outer Card Box Decoration.
  static BoxDecoration smokedGlassDecoration({
    double radius = 18.0,
    double? borderRadius,
    Color? borderColor,
    Color? surfaceColor,
    List<BoxShadow>? customShadow,
  }) {
    final effectiveRadius = borderRadius ?? radius;
    return BoxDecoration(
      color: const Color(0x4704060B),
      borderRadius: BorderRadius.circular(effectiveRadius),
      border: Border.all(
        color: borderColor ?? const Color(0x38FFFFFF),
        width: 1.0,
      ),
      boxShadow: const [],
    );
  }

  /// Whisper-Dark Optical Crystal Inner Well Decoration (`Color(0x4704060B)`, `radius: 14`, `1px #26FFFFFF` border).
  static BoxDecoration recessedObsidianWellDecoration({
    double radius = 14.0,
    double? borderRadius,
    Color? borderColor,
  }) {
    final effectiveRadius = borderRadius ?? radius;
    return BoxDecoration(
      color: const Color(0x4704060B),
      borderRadius: BorderRadius.circular(effectiveRadius),
      border: Border.all(
        color: borderColor ?? const Color(0x26FFFFFF),
        width: 1.0,
      ),
      boxShadow: const [],
    );
  }

  // ---------------------------------------------------------------------------
  // 11. Gradient Scrims (docs/design/35_MEDIA_ART_DIRECTION.md)
  // ---------------------------------------------------------------------------
  /// Directional 4-stop hero gradient scrim so 9:16 stage artwork shines through transparent cards.
  static BoxDecoration heroScrim() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.0, 0.45, 0.78, 1.0],
        colors: [
          Color(0x00000000),
          Color(0x00000000),
          Color(0x40000000),
          Color(0x73000000),
        ],
      ),
    );
  }

  /// Radial vignette scrim for athlete profile cutouts and Tale of the Tape.
  static BoxDecoration cutoutRadialScrim() {
    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0.0, -0.2),
        radius: 0.85,
        stops: [0.30, 0.70, 1.0],
        colors: [
          Color(0x00000000),
          Color(0x40000000),
          Color(0x73000000),
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
      canvasColor: overlayG6Surface,
      primaryColor: goldPrimary,
      colorScheme: const ColorScheme.dark(
        surface: overlayG6Surface,
        surfaceContainerLowest: voidBackground,
        surfaceContainerLow: background,
        surfaceContainer: overlayG6Surface,
        surfaceContainerHigh: Color(0xFF141926),
        surfaceContainerHighest: Color(0xFF1A2030),
        primary: goldPrimary,
        secondary: secondaryAccent,
        error: error,
        onSurface: textPure,
        onSurfaceVariant: textSecondary,
        onPrimary: voidBackground,
        onSecondary: voidBackground,
        onError: textPure,
        outline: border,
        outlineVariant: overlayG6Border,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: goldPrimary,
        circularTrackColor: Color(0x26D4AF37),
        linearTrackColor: Color(0x26D4AF37),
      ),
      dividerColor: const Color(0x22FFFFFF),
      dividerTheme: const DividerThemeData(
        color: Color(0x22FFFFFF),
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
          shadows: crystalTextShadows,
        ),
        displayMedium: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          fontSize: 28.0,
          color: textPrimary,
          letterSpacing: -0.5,
          shadows: crystalTextShadows,
        ),
        displaySmall: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.bold,
          fontSize: 24.0,
          color: textPrimary,
          shadows: crystalTextShadows,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w700,
          fontSize: 22.0,
          color: textPrimary,
          shadows: crystalTextShadows,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w600,
          fontSize: 20.0,
          color: textPrimary,
          shadows: crystalTextShadows,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w600,
          fontSize: 18.0,
          color: textPrimary,
          shadows: crystalTextShadows,
        ),
        titleLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          fontSize: 16.0,
          color: textPrimary,
          shadows: crystalTextShadows,
        ),
        titleMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          fontSize: 15.0,
          color: textPrimary,
          shadows: crystalTextShadows,
        ),
        titleSmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          fontSize: 13.0,
          color: textSecondary,
          shadows: crystalTextShadows,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 16.0,
          color: textPrimary,
          height: 1.5,
          shadows: crystalTextShadows,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 14.0,
          color: textSecondary,
          height: 1.4,
          shadows: crystalTextShadows,
        ),
        bodySmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 12.0,
          color: textMuted,
          height: 1.3,
          shadows: crystalTextShadows,
        ),
        labelLarge: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          fontSize: 14.0,
          color: textPrimary,
          letterSpacing: 0.1,
          shadows: crystalTextShadows,
        ),
        labelMedium: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w500,
          fontSize: 12.0,
          color: textSecondary,
          shadows: crystalTextShadows,
        ),
        labelSmall: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 11.0,
          color: textMuted,
          shadows: crystalTextShadows,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x38FFFFFF), width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x38FFFFFF), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x38FFFFFF), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: goldPrimary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.2),
        ),
        labelStyle: const TextStyle(
          fontFamily: fontBody,
          color: textSecondary,
          fontSize: 14.0,
          shadows: crystalTextShadows,
        ),
        hintStyle: const TextStyle(
          fontFamily: fontBody,
          color: textMuted,
          fontSize: 14.0,
          shadows: crystalTextShadows,
        ),
        errorStyle: const TextStyle(
          fontFamily: fontBody,
          color: error,
          fontSize: 12.0,
          shadows: crystalTextShadows,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: goldPrimary,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: textMuted,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          side: const BorderSide(color: Color(0x73D4AF37), width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w600,
            fontSize: 15.0,
            letterSpacing: 0.2,
            shadows: crystalTextShadows,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textPrimary,
          disabledForegroundColor: textMuted,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          side: const BorderSide(color: Color(0x38FFFFFF), width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
            shadows: crystalTextShadows,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: goldPrimary,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontFamily: fontBody,
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
            shadows: crystalTextShadows,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        disabledColor: Colors.transparent,
        selectedColor: Colors.transparent,
        secondarySelectedColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: fontBody,
          color: textPrimary,
          fontSize: 12.0,
          shadows: crystalTextShadows,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontBody,
          color: goldPrimary,
          fontSize: 12.0,
          shadows: crystalTextShadows,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: const BorderSide(color: Color(0x2EFFFFFF), width: 1.0),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.all(Colors.transparent),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x73D4AF37);
          }
          return const Color(0x59FFFFFF);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return goldPrimary;
          }
          return textSecondary;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: overlayG6Surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        barrierColor: overlayG6Barrier,
        elevation: 8,
        titleTextStyle: const TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: textPure,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontBody,
          fontSize: 14,
          color: textPrimary,
          height: 1.45,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: overlayG6Border, width: 1.0),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: overlayG6Surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: overlayG6Surface,
        modalBarrierColor: overlayG6Barrier,
        elevation: 8,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: overlayG6Border, width: 1.0),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: overlayG6Surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        elevation: 8,
        textStyle: const TextStyle(
          fontFamily: fontBody,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPure,
        ),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: fontBody,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPure,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: overlayG6Border, width: 1.0),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(overlayG6Surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.black),
          elevation: const WidgetStatePropertyAll(8),
          side: const WidgetStatePropertyAll(
            BorderSide(color: overlayG6Border, width: 1.0),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(
          fontFamily: fontBody,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPure,
        ),
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(overlayG6Surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.black),
          elevation: const WidgetStatePropertyAll(8),
          side: const WidgetStatePropertyAll(
            BorderSide(color: overlayG6Border, width: 1.0),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: overlayG6Surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        elevation: 10,
        headerBackgroundColor: const Color(0xFF141926),
        headerForegroundColor: textPure,
        weekdayStyle: const TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: textSecondary,
        ),
        dayStyle: const TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          color: textPure,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return voidBackground;
          if (states.contains(WidgetState.disabled)) return textMuted;
          return textPure;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return goldPrimary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return voidBackground;
          return goldPrimary;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return goldPrimary;
          return Colors.transparent;
        }),
        todayBorder: const BorderSide(color: goldPrimary, width: 1.2),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return voidBackground;
          return textPure;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return goldPrimary;
          return Colors.transparent;
        }),
        dividerColor: overlayG6Border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: overlayG6Border, width: 1.0),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: goldPrimary,
          textStyle: const TextStyle(
            fontFamily: fontDisplay,
            fontWeight: FontWeight.w800,
          ),
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: const TextStyle(
            fontFamily: fontDisplay,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: overlayG6Surface,
        elevation: 10,
        dialBackgroundColor: const Color(0xFF141926),
        dialHandColor: goldPrimary,
        dialTextColor: textPure,
        hourMinuteColor: const Color(0xFF1A2030),
        hourMinuteTextColor: textPure,
        dayPeriodColor: const Color(0xFF1A2030),
        dayPeriodTextColor: textPure,
        dayPeriodBorderSide: const BorderSide(color: overlayG6Border),
        entryModeIconColor: goldPrimary,
        helpTextStyle: const TextStyle(
          fontFamily: fontDisplay,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: overlayG6Border, width: 1.0),
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
          shadows: crystalTextShadows,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xEB0B101C),
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x73D4AF37), width: 1.0),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontBody,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: textPure,
          shadows: crystalTextShadows,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.transparent,
        foregroundColor: goldPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x73D4AF37), width: 1.2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: goldPrimary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.w600,
          fontSize: 11.0,
          shadows: crystalTextShadows,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontBody,
          fontWeight: FontWeight.normal,
          fontSize: 11.0,
          shadows: crystalTextShadows,
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
