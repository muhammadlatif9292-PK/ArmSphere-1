# ArmSphere AI Generation Prompt Library
**Atmospheric Asset Specifications & Ethical Generation Guardrails**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Ethical Generation Guardrails

ArmSphere enforces non-negotiable boundaries on generative AI media:

```
┌─────────────────────────────────────────────────────────────────┐
│                    ETHICAL GENERATION RULES                     │
├─────────────────────────────────────────────────────────────────┤
│ 1. NEVER generate fake human faces and present them as athletes.│
│    Real competitors must always be represented by real user     │
│    uploads or neutral geometric initials avatars.               │
│ 2. NEVER generate fake tournament podiums or fake match results.│
│ 3. Generative imagery is restricted to:                         │
│    • Atmospheric arena environments and stadium lighting        │
│    • Dark luxury metallic and carbon textures                   │
│    • Empty official armwrestling competition tables             │
│    • Abstract sports-tech background light cones                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Master Prompt Specifications

### Prompt 01: `arena_dark_atmosphere.jpg`
- **Assigned Placement**: `TournamentDetailsHeroWidget` default backdrop.
- **Aspect Ratio**: 16:9 Landscape (1920×1080px).
- **Prompt**:
  > *"Cinematic high-angle photograph of a prestigious international sports arena illuminated in the dark. A single focused cold blue and amber spotlight beams down onto the center floor. Atmospheric haze and subtle light dust particles float through the air. The grandstand seats in the background are shrouded in deep charcoal shadows (#070A11). Highly detailed, photorealistic 8k, moody architectural sports photography, clean composition with zero people and zero visible text."*
- **Text-Safe Region**: Bottom 60% of image must remain in deep dark shadow (`#0B0F19`) to allow high-contrast title placement.

---

### Prompt 02: `table_sparring_atmosphere.jpg`
- **Assigned Placement**: Welcome screen hero and Informal Meetups directory banner.
- **Aspect Ratio**: 4:3 Landscape (1600×1200px).
- **Prompt**:
  > *"Dramatic side-profile photograph of a professional armwrestling competition table standing alone in an empty dark venue. Heavy-duty black steel frame, official dense red and blue elbow pads, silver hand pegs. Overhead single spotlight creating rim lighting along the steel edges. Dark navy and deep black background with soft rim illumination. Professional sports equipment photography, clean depth of field, zero athletes."*

---

### Prompt 03: `championship_belt_texture.jpg`
- **Assigned Placement**: `ChampionshipDetailScreen` header background.
- **Aspect Ratio**: 21:9 Ultra-wide (1680×720px).
- **Prompt**:
  > *"Extreme macro photograph of handcrafted burnished gold metal relief plates mounted on premium textured dark grain leather. Intricate geometric laurel leaf engravings with polished brass and champagne gold highlights (#D4AF37). Moody studio lighting with soft specular reflections. High-end luxury craftsmanship, dark slate background, zero human figures."*

---

### Prompt 04: `empty_state_table_vector.png`
- **Assigned Placement**: `AppEmptyState` illustration for tournaments and practice sessions.
- **Aspect Ratio**: 1:1 Square (512×512px, Transparent PNG).
- **Prompt**:
  > *"Clean isometric 3D render of an official armwrestling table. Dark matte charcoal steel legs, vibrant emerald green elbow pads, polished aluminum pegs. Soft ambient studio drop shadow on transparent background. Minimalist, premium athletic aesthetic, modern industrial design style."*
