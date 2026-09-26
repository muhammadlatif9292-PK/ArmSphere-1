# ArmSphere Stage 3 — Master Flow Image Generation Prompt Pack
**Document Version**: 1.0.0 (Authoritative Google Flow / Imagen 3 Production Pack)
**Date**: September 26, 2026
**Status**: APPROVED & AUDITED
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `14_IMAGE_ASSET_STRATEGY.md`, `16_AI_GENERATION_PROMPT_LIBRARY.md`, & `35_MEDIA_ART_DIRECTION.md`
**Scope**: Copy-Paste Ready Master Prompt Pack Engineered for Google Flow / Imagen 3, Enforcing the "Raw Iron & Precision Steel" Brand Language, Negative Constraint Anchors, and Text-Safe Composition Scrims.

---

## 1. Master Style Anchor & Negative Constraint Directives

To achieve world-class, authentic sports federation fidelity and eradicate generic "AI art" tropes, **every single image generation session in Google Flow MUST include the following Core Style Anchor and Negative Constraints**:

### 1.1 The ArmSphere Master Positive Style Anchor
```text
Photorealistic medium-format sports photography captured on Hasselblad H6D-100c, 85mm f/1.4 lens. Gritty, authentic international armwrestling federation aesthetics. Dramatic chiaroscuro stadium lighting, high-contrast directional rim lights in luminous cyan (#38BDF8) and warm champagne gold (#D4AF37). Backgrounds in deep charcoal obsidian (#070A11). Visible chalk dust suspended in volumetric light shafts, natural skin pores, realistic forearm vascularity, heavy knurled steel hardware, authentic leather competition table with regulation elbow and pin pads. Zero fantasy armor, zero cartoon exaggeration. High-end, premium, raw athletic intensity.
```

### 1.2 The Master Negative Prompt Anchor (Mandatory Rejection Block)
```text
NEGATIVE PROMPT:
cartoon, anime, 3d render, low poly, CGI plastic skin, doll face, airbrushed, oversaturated neon, glowing magic runes, fantasy armor, fake muscles, anatomical inaccuracies, six fingers, deformed hands, broken wrists, incorrect grip, floating table, sci-fi HUD elements, fake gibberish text, watermarks, signatures, blurry, low resolution, flat lighting, stock photo smiles, colorful confetti.
```

### 1.3 Text-Safe Zone Architectural Rule
For all 16:9 and 9:16 banner/hero backgrounds:
- **Rule**: The bottom 45% of the frame must fade progressively into deep obsidian darkness (`#070A11` at 95%-100% opacity) or maintain low-contrast negative space.
- **Purpose**: Guarantees that Flutter `Text` and `StickyBottomActionBar` widgets achieve WCAG AAA contrast (minimum 18:1 against `#F8FAFC`) without requiring artificial heavy CSS drop-shadows.

---

## 2. Category 1: System Brand Core & App Icon (M0)

### Asset: `M0-ICON-GOLD` (Master App Icon Emblem)
- **Aspect Ratio**: 1:1 (Square)
- **Target Dimensions**: 1024 x 1024 px
- **Usage**: Android Adaptive Icon Foreground, Splash Screen Hero, Store Listing
```text
PROMPT:
An authoritative, iconic emblem for an international armwrestling federation. A heavy, forged solid champagne gold (#D4AF37) armwrestling grip monogram fused with an industrial steel anvil. Beveled, micro-knurled metallic edges with precision chamfers reflecting subtle studio rim light. Perfectly centered on a matte dark brushed titanium obsidian disc (#070A11). Micro-scratches and raw metallic grain on the gold surface indicating heavy competition use. Symmetrical, prestigious, modern athletic luxury. Clean solid dark background, zero glow slop, isolated studio product shot, 8k resolution.
```

### Asset: `M0-SEAL-FED` (Official Federation Holographic Seal)
- **Aspect Ratio**: 1:1 (Square)
- **Target Dimensions**: 512 x 512 px
- **Usage**: Athlete Verification, Sanction Certificates, Policy Seals
```text
PROMPT:
A prestigious circular metallic federation seal of verification. Embossed deep-relief champagne gold and cold platinum steel. Outer ring engraved with precise Roman numerals and micro-stars. Inner core displays two clasped competition wrists locked over a regulation center line. Precision engraved guilloche patterns, subtle iridescent holographic rainbow sheen on the steel facets under cold spotlight. Isolated on pure transparent black (#000000), macro lens, razor-sharp edge definition.
```

---

## 3. Category 2: Bundled Textures & Atmospheric Backgrounds (M1)

### Asset: `M1-TEX-KNURL` (Seamless Knurled Steel Pattern)
- **Aspect Ratio**: 1:1 (Square Tile)
- **Target Dimensions**: 1024 x 1024 px (Seamless Tile)
- **Usage**: Global Scaffold Texture, Card Surface Substrate
```text
PROMPT:
Macro top-down seamless texture of dark diamond-pattern knurled steel from a championship Olympic barbell. Deep matte charcoal-black finish (#0B0F19) with subtle metallic sheen on the raised pyramid peaks. Micro-dustings of white gymnastic chalk trapped in the recesses. Flat, even lighting, orthographic camera angle, perfectly repeating seamless tileable texture, industrial precision manufacturing, 8k resolution.
```

### Asset: `M1-HERO-ARENA` (Championship Stage Hero Backdrop)
- **Aspect Ratio**: 16:9
- **Target Dimensions**: 1920 x 1080 px
- **Usage**: Login Screen Header, Tournament List Hero, Event Detail Header
```text
PROMPT:
Wide cinematic shot of an international armwrestling world championship arena stage before the final match. A solitary heavy competition table sits on an elevated steel riser under intense downward spotlights. Suspended white chalk dust particles catch sharp golden beams (#D4AF37) cutting through heavy arena haze. The background audience stadium seating is plunged into deep atmospheric shadow (#070A11). Cold blue edge lights illuminate the arena perimeter. Bottom 45% composed of clean dark gradient negative space. Dramatic, hushed tension, high production value, Hasselblad cinema still.
```

### Asset: `M1-HERO-GRIP` (The Clash — Macro Combat Tension)
- **Aspect Ratio**: 16:9
- **Target Dimensions**: 1920 x 1080 px
- **Usage**: Athlete Home War-Room, Challenge Screen Hero, Match Detail Header
```text
PROMPT:
Extreme close-up macro action photograph of two massive, muscular armwrestling forearms locked in an intense combat grip at the center line of a competition table. White chalk explodes outward in micro-clouds from the clenched knuckles. Tense vascularity, flexed tendons, beads of sweat on weathered skin. Heavy referee competition strap buckled tightly across the wrists with cold steel buckle. Dramatic cross-directional rim lighting with luminous cyan highlights on one arm and warm golden rim light on the opposing arm. Dark background with smooth chiaroscuro bokeh. Raw power, intense grip pressure, high-speed shutter freezing chalk particles.
```

---

## 4. Category 3: Weight Class Division Badges (M4)

### Asset: `M4-BDG-HEAVY` (Super Heavyweight Division 110kg+)
- **Aspect Ratio**: 1:1
- **Target Dimensions**: 512 x 512 px
- **Usage**: Roster Cards, Tournament Bracket Division Tags, Profile Badges
```text
PROMPT:
A 3D metallic division shield representing the Super Heavyweight Armwrestling division. Heavy forged raw cast iron and dark titanium. The central motif is a massive industrial blacksmith anvil with two clasped iron gauntlets embossed on the face. Cold brushed steel chamfers with champagne gold (#D4AF37) accent rivets. Subtle chalk residue in the steel crevices. Centered, isolated on solid obsidian (#070A11), rim lighting, tactile weight and impenetrable strength.
```

### Asset: `M4-BDG-MIDDLE` (Middleweight Division 86–105kg)
- **Aspect Ratio**: 1:1
- **Target Dimensions**: 512 x 512 px
- **Usage**: Division Selectors, Bracket Tags
```text
PROMPT:
A 3D metallic division shield representing the Middleweight Armwrestling division. Balanced forged Damascus steel with visible flowing wave patterns. The central motif is an aerodynamic steel crest flanked by dual competition grip silhouettes. Polished razor-sharp chrome beveled edges, deep navy-gray plate core, luminous cyan (#38BDF8) edge lighting. Centered, isolated on solid obsidian (#070A11), high precision, agility and explosive power.
```

### Asset: `M4-BDG-LIGHT` (Lightweight Division -85kg)
- **Aspect Ratio**: 1:1
- **Target Dimensions**: 512 x 512 px
- **Usage**: Division Selectors, Bracket Tags
```text
PROMPT:
A 3D metallic division emblem representing the Lightweight Armwrestling division. Sleek tempered carbon fiber and tungsten steel. The central motif is a sharp, stylized raptor claw gripping a precision steel bar. Razor-thin beveled edges, high-gloss weave reflections, electric cyan micro-accents. Centered, isolated on solid obsidian (#070A11), hyper-fast torque and technical precision aesthetic.
```

---

## 5. Category 4: Referee Certification Insignia (M4)

### Asset: `M4-REF-MASTER` (Master International Referee Badge)
- **Aspect Ratio**: 1:1
- **Target Dimensions**: 512 x 512 px
- **Usage**: Referee Dashboard, Official Scorepad Screen, Dispute Review
```text
PROMPT:
An official Master International Referee badge of authority. Solid polished champagne gold (#D4AF37) shield with inset cold enamel dark sapphire core. Deeply engraved dual crossed referee whistles above a precision balance scale. Beveled multi-tiered gold frame with micro-milled knurled border. Subdued specular highlights, museum artifact quality, isolated on pure black (#000000), macro jewelry photography.
```

### Asset: `M4-REF-NAT` (Senior National Referee Badge)
- **Aspect Ratio**: 1:1
- **Target Dimensions**: 512 x 512 px
- **Usage**: Referee Profile, Table Assignment Matrix
```text
PROMPT:
An official Senior National Referee insignia. Polished sterling silver and gunmetal titanium shield. Embossed central referee whistle resting on a circular target reticle representing strict table arbitration. Crisp engraved lettering, brushed silver texture, icy blue rim reflection. Centered, isolated on dark background.
```

---

## 6. Category 5: Role Intent Selection Cards (M1)

### Asset: `M1-ROLE-ATHLETE` (Competitor Role Card Hero)
- **Aspect Ratio**: 3:2
- **Target Dimensions**: 900 x 600 px
- **Usage**: `RoleIntentScreen` Athlete Card Header
```text
PROMPT:
Athletic portrait of a professional armwrestler wrapping heavy competition wrist straps around their chalked hand. Focused intense gaze, hooded athletic sweatshirt, side-lit with dramatic golden light catching the muscular forearm and knuckles. Dark background with subtle gym iron plates out of focus. Serious, gritty determination, authentic combat sports documentary style.
```

### Asset: `M1-ROLE-REFEREE` (Arbitrator Role Card Hero)
- **Aspect Ratio**: 3:2
- **Target Dimensions**: 900 x 600 px
- **Usage**: `RoleIntentScreen` Referee Card Header
```text
PROMPT:
Close-up shot of an official armwrestling referee in the signature black-and-white vertical striped technical federation polo shirt. Two hands with chalk dust poised with millimeter precision adjusting two competitors' locked thumbs at the center line ("Referee's Grip"). Razor-sharp focus on the referee's stern authoritative hands ensuring fair alignment. High-contrast arena lighting.
```

### Asset: `M1-ROLE-OPERATOR` (Tournament Operator Role Card Hero)
- **Aspect Ratio**: 3:2
- **Target Dimensions**: 900 x 600 px
- **Usage**: `RoleIntentScreen` Operator Card Header
```text
PROMPT:
Tournament Director command station overlooking a multi-table championship arena. In the foreground, hands adjusting official double-elimination bracket brackets on an industrial rugged tablet. In the background bokeh, multiple lighted armwrestling tables with active crowds and referee spotlights. Atmosphere of total logistical mastery and electric championship energy.
```

---

## 7. Category 6: Empty State Atmospheric Illustrations (M1)

### Asset: `M1-EMP-NOTOURN` (Empty Tournament Radar)
- **Aspect Ratio**: 16:9
- **Target Dimensions**: 960 x 540 px
- **Usage**: Tournament List Empty State, Provincial Events Empty State
```text
PROMPT:
Atmospheric, cinematic still of an empty armwrestling arena at midnight. A single championship table with dark leather pads stands isolated under one faint overhead work light. The stadium stands are dark and empty. Fine dust particles float quietly through the light shaft. Clean, poignant, expectant silence before battle. Deep shadows (#070A11), rich tonal gradient, perfectly framed for UI card overlay.
```

### Asset: `M1-EMP-NOTRAIN` (Empty Training Log)
- **Aspect Ratio**: 16:9
- **Target Dimensions**: 960 x 540 px
- **Usage**: Training Log Empty State, PRs Empty State
```text
PROMPT:
Still life of raw armwrestling training tools resting on a dark rubber gym floor. A heavy steel loading pin with cast iron plates, a wide wrist wrench handle, and heavy nylon webbing straps coated in white chalk dust. High-contrast side-lighting creating bold metallic textures and deep shadows. Evocative of hard work yet to be logged.
```

### Asset: `M1-EMP-NOCHALL` (Empty Challenge Queue)
- **Aspect Ratio**: 16:9
- **Target Dimensions**: 960 x 540 px
- **Usage**: Challenge Screen Empty State
```text
PROMPT:
A pair of empty armwrestling elbow pads on a heavy steel competition table with a single white chalk mark drawn down the exact center line. A pristine leather competition strap lies unbuckled across the line. Dramatic low-angle perspective, inviting the challenger to step up to the table. Mood of intense anticipation.
```

---

## 8. Quality Assurance & Generation Validation Checklist

Before accepting any image output from Google Flow for inclusion into the ArmSphere asset tree:
1. **Hand / Finger Verification**: Inspect all human hands at 200% zoom. Confirm exactly 5 fingers per hand, natural knuckle spacing, realistic thumb articulation in the armwrestling lock, and zero distorted digital melting.
2. **Table Regulation Verification**: Ensure table contains proper regulation pads (two elbow pads, two pin pads, center line, two hand pegs). Reject any images showing generic wooden picnic tables or bar tables.
3. **Contrast Gradient Verification**: Verify the bottom 45% text-safe scrim against `#F8FAFC` text using a color picker tool. Contrast ratio must exceed 18:1.
4. **Format & Metadata Stripping**: Convert generated images to `.webp` with 85% quality, strip EXIF metadata, and enforce maximum file size per `46_MASTER_MEDIA_ASSET_MAP.md`.
