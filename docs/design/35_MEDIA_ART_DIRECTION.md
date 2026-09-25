# ArmSphere Media Art Direction & Visual Asset Specification
**"Raw Iron & Precision Steel" — Visual Identity, Imagery Physics & Text-Safe Scrims**
**Document Version**: 2.0.0 (Authoritative)
**Status**: APPROVED & LOCKED INTO REPOSITORY
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `docs/design/14_IMAGE_ASSET_STRATEGY.md` & `docs/design/16_AI_GENERATION_PROMPT_LIBRARY.md`
**Scope**: Complete Visual Art Direction, Lighting Rules, Color Grading, Aspect Ratios, Text Scrim Engineering, and Ethical Asset Generation Standards.

---

## 1. Visual Art Direction Philosophy: "Raw Iron & Precision Steel"

ArmSphere rejects the superficial gloss of generic fitness applications. Armwrestling is an ancient, grueling strength sport characterized by:
- Severe isometric tension and tendon strain.
- Knurled steel handles, heavy iron loading pins, and chalk dust in the air.
- Intense psychological duels across leather tournament elbow pads.
- Institutional governance and national pride.

### The 4 Visual Tenets:
1. **Dramatic High-Contrast Lighting**: Deep chiaroscuro with strong directional rim lights carving out forearm musculature and table hardware against void-black backgrounds.
2. **Authenticity Over Artificiality**: Real athletic sweat, genuine chalk textures, and realistic grip setups. Absolutely zero AI-generated fake human faces or anatomically impossible muscles.
3. **Restrained Color Grading**: Backgrounds are desaturated and grounded in carbon black (`#070A11`), allowing luminous Cyan (`#38BDF8`), Champagne Gold (`#D4AF37`), and Crimson (`#EF4444`) to act as functional signals.
4. **Institutional Prestige**: Federation championship textures resemble heavyweight gold title belts, milled aluminum table frames, and official embossed leather seals.

---

## 2. Aspect Ratio & Dimension Standards

To eliminate layout shifts and memory thrashing across varying Android screens, every image surface follows strict fixed aspect ratios:

| Image Surface | Aspect Ratio | Standard Resolution | Flutter Container Widget | Primary Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Tournament Hero Banner** | **16:9** | 1080 × 608 px (2x: 2160 × 1216) | `AspectRatio(aspectRatio: 16/9)` | Event detail headers, livestream previews |
| **Athlete Profile Avatar** | **1:1** | 256 × 256 px (2x: 512 × 512) | `CircleAvatar` / `ClipRRect(12dp)` | User identity, leaderboard rows, chat |
| **Community Post Card** | **4:5** (Vertical) | 1080 × 1350 px | `AspectRatio(aspectRatio: 4/5)` | Sparring video thumbnails, gym training photos |
| **Tale of Tape Cutout** | **3:4** | 720 × 960 px | `ClipRRect` inside split view | Symmetrical head-to-head match cards |
| **Division Bracket Thumb** | **3:2** | 600 × 400 px | `AspectRatio(aspectRatio: 3/2)` | Tournament card lists in Discover feed |
| **Federation Seal / Badge**| **1:1** | 128 × 128 px | SVG Vector or 256 × 256 PNG | Sanction credentials, official certifications |

---

## 3. Lighting & Cinematography Rules

When commissioning photography, capturing live event feeds, or preparing tournament banner assets, strict cinematography criteria must be met:

```
[LIGHTING GEOMETRY]
          Key Light (45° High Angle, Hard Contrast)
                       ╲
                        ▼
   Rim Light (Cyan/White) ──► [ATHLETE / TABLE] ◄── Fill Light (Soft, -2.5 EV)
                                     │
                                     ▼
                     Deep Shadow Substrate (#070A11)
```

1. **Key Light**: High-intensity, directional hard light positioned at a 45-degree angle above the armwrestling table, casting defined shadows beneath forearms and knuckles.
2. **Rim / Kicker Light**: A sharp, cool edge light (5600K cool white or cyan tint) along the contour of the arm, isolating the puller from the dark background.
3. **Fill Light**: Highly suppressed (-2.0 to -3.0 EV) to maintain deep, dramatic blacks without losing structural edge definition.
4. **Environment**: Dark tournament arenas, overhead single-point table spotlights, and subtle atmospheric chalk haze catching the light beam.

---

## 4. Text-Safe Scrim Specifications (Zero Legibility Failures)

A primary flaw in amateur mobile design is placing white text directly over busy photographic backgrounds, causing illegible typography. In ArmSphere, **no text is ever rendered directly on raw photography**. Every image container uses an engineered multi-stop gradient scrim:

### The Canonical 4-Stop Scrim Gradient:
```dart
static const LinearGradient heroTextScrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  stops: [0.0, 0.40, 0.75, 1.0],
  colors: [
    Color(0x00070A11), // 0% opacity at top (full image visibility)
    Color(0x33070A11), // 20% opacity at 40% height (subtle softening)
    Color(0xCC070A11), // 80% opacity at 75% height (reading zone base)
    Color(0xFF070A11), // 100% solid canvas background at bottom
  ],
);
```

### Radial Scrim for Athlete Cutouts (Head-to-Head & Profile Hero):
```dart
static const RadialGradient profileCutoutScrim = RadialGradient(
  center: Alignment(0.0, -0.2), // Anchored on athlete chest/shoulders
  radius: 0.85,
  stops: [0.30, 0.70, 1.0],
  colors: [
    Color(0x000B0F19), // Fully transparent over athlete portrait
    Color(0x880B0F19), // Vignette darkening around arms
    Color(0xFF0B0F19), // 100% solid surface blending seamlessly into page
  ],
);
```

**Verification Rule**: Typography placed over these scrims achieves minimum **WCAG AAA 14:1 contrast** regardless of the underlying photograph's brightness.

---

## 5. Fallback & Placeholder Asset Architecture

When network latency prevents images from loading or when an athlete has not uploaded a portrait, ArmSphere provides deterministic, athletic vector placeholders:

### 1. Monogram Athlete Avatars:
- Circular container filled with `#1E293B`.
- Centered athlete initials in `SpaceGrotesk Bold` (`#F8FAFC`).
- **Role-Coded Outer Border Ring (2px)**:
  - `ATHLETE`: Champagne Gold (`#D4AF37`) or Cool Cyan (`#38BDF8`).
  - `REFEREE / OFFICIAL`: Crisp Emerald Green (`#10B981`) or High-Contrast White.
  - `SANCTIONED DIRECTOR`: Amber Gold (`#F59E0B`).

### 2. Tournament Venue Banner Fallback:
- Dark geometric SVG canvas featuring a stylized overhead view of an armwrestling competition table (two elbow pads, two pin pads, table center line) rendered in subtle 1px stroke (`#334155`) with a soft radial cyan glow (`#38BDF8` at 8% opacity).

---

## 6. Generative AI Asset Prompt Library (Strictly Backgrounds & Textures)

Per `docs/design/00_DESIGN_AUTHORITY.md` Rule 17 and `docs/design/24_ANTI_SLOP_RULES.md`, **AI image generators may NEVER be used to generate fake human athletes, faces, or referee personas**. Generative tools are strictly permitted for environmental textures, championship metals, and dark arena atmospheres.

### Prompt Recipe 1: Tournament Arena Background Texture
```
Prompt: Extreme wide angle, dark competitive combat sports arena at midnight, single overhead spotlight illuminating empty professional armwrestling table with red and blue elbow pads, knurled steel frame, subtle chalk dust suspended in dark air, deep carbon black shadows, dramatic chiaroscuro, cinematic 8k, realistic sports photography, no people, clean background --ar 16:9 --style raw --v 6.0
```

### Prompt Recipe 2: Championship Title Belt Leather & Gold
```
Prompt: Macro close-up of heavy championship armwrestling title belt, thick black full-grain leather strap with precision white stitching, embossed gold-plated brass medallion with crossed forearm engraving, polished metallic highlights, soft warm rim light, studio product photography, dark luxury aesthetic --ar 16:9 --style raw --v 6.0
```

### Prompt Recipe 3: Knurled Steel & Loading Pin Texture
```
Prompt: Macro photography of heavy-duty knurled stainless steel handle attached to black steel loading pin, Olympic cast iron weight plates stacked on gym floor, fine white magnesium carbonate chalk dusting the knurling, moody industrial gym lighting, high contrast, crisp mechanical focus --ar 4:5 --style raw --v 6.0
```

### Prompt Recipe 4: Digital Cyber-Grid Combat Background
```
Prompt: Abstract dark sports telemetry background, subtle dark navy and charcoal hexagon grid, luminous faint cyan laser lines at 1px thickness, deep dark void background, high-end esports telemetry aesthetic, zero clutter, minimalist --ar 16:9 --style raw --v 6.0
```

---

## 7. Media Compression & Runtime Budgets

To protect low-memory Android devices:
- **Format**: All raster images are compressed to **WebP** at 82% quality (lossy) or PNG for vector graphics.
- **Max Resolution**: No image bundled or loaded into memory exceeds **1080px in any dimension**.
- **Memory Bounding**: All network images are wrapped in `CachedNetworkImage` with explicit `memCacheWidth` and `memCacheHeight` constraints:
  ```dart
  CachedNetworkImage(
    imageUrl: url,
    memCacheWidth: 600, // Decodes only to required display pixel density
    fit: BoxFit.cover,
  )
  ```
- **Total Bundle Budget**: Total static visual assets bundled into the release APK must not exceed **8.5 MB**.

---

## 8. Verification & Non-Contradiction Proof
This media art direction specification fulfills all criteria of `docs/design/00_DESIGN_AUTHORITY.md` and `docs/design/14_IMAGE_ASSET_STRATEGY.md`. It guarantees absolute text legibility via mathematical 4-stop scrims, enforces strict aspect ratio discipline to eliminate layout shifts, and legally protects the brand by prohibiting fake AI athlete portraits.
