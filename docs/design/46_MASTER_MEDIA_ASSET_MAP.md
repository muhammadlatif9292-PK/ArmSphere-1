# ArmSphere Stage 3 — Master Media Asset Map & Systemic Registry
**Document Version**: 1.0.0 (Authoritative Master Asset Registry)
**Date**: September 26, 2026
**Status**: APPROVED & AUDITED
**Authority**: `docs/design/00_DESIGN_AUTHORITY.md`, `14_IMAGE_ASSET_STRATEGY.md`, `15_VIDEO_ASSET_STRATEGY.md`, & `17_MEDIA_PERFORMANCE_BUDGET.md`
**Scope**: Exhaustive 66-Screen Media Asset Registry, M0–M7 Classification Taxonomy, Multi-Density Resolutions, WebP Budgets, Fallback Ladders, and Preload Hierarchy.

---

## 1. Media Classification Taxonomy (M0 to M7)

Every visual, motion, and auditory asset within ArmSphere is categorized into one of eight immutable media classes:

| Class | Classification Name | Source / Nature | Lifecycle / Storage | Strict Budget Limit |
| :--- | :--- | :--- | :--- | :--- |
| **M0** | **System & Brand Core** | Bundled static vector/raster | Shipped in APK (`assets/images/brand/`) | Max 250 KB total |
| **M1** | **Bundled Hero & Textures** | Bundled static high-res textures | Shipped in APK (`assets/images/textures/`) | Max 1.2 MB total |
| **M2** | **User & Community Dynamic** | User-generated uploads | Network fetched, cached via disk/memory | Max 300 KB / image (WebP) |
| **M3** | **Tournament & Event Dynamic**| Federation/Operator uploads | Network fetched, CDN cached | Max 500 KB / poster (WebP) |
| **M4** | **Institutional Seals & Badges** | Federation official emblems | Shipped in APK (`assets/images/badges/`) | Max 600 KB total |
| **M5** | **Video Media (Authorized Only)**| Live streams, user clips, disputes| Network streamed (H.264/AV1, HLS) | Max 2.5 MB (Hero Loop) / 1080p stream |
| **M6** | **Audio Effects (Sensory Pack)**| High-impact combat audio | Shipped in APK (`assets/sounds/`) | Max 300 KB total |
| **M7** | **Procedural & Vector Fallbacks**| Pure code (Gradients, CustomPainters)| 0 bytes disk, GPU computed at runtime | 0 KB (0ms instant render) |

---

## 2. Multi-Density Resolution & WebP Compression Standards

All bundled and cached raster images adhere to strict multi-density pixel standards targeting Android `xxhdpi` (baseline @3x) and iOS `@3x`:

| Aspect Ratio | Display Size (@1x dp) | Target @1x (px) | Target @2x (px) | Target @3x (px) | Format & Quality | Max Disk Size (@3x) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1:1 (Avatar/Badge)** | 64 x 64 dp | 64 x 64 px | 128 x 128 px | 192 x 192 px | WebP Lossless (Alpha) | 35 KB |
| **1:1 (Trophy/Seal)** | 160 x 160 dp | 160 x 160 px | 320 x 320 px | 480 x 480 px | WebP Lossless (Alpha) | 75 KB |
| **16:9 (Card Poster)** | 360 x 202 dp | 360 x 202 px | 720 x 405 px | 1080 x 608 px | WebP Lossy (Q=85) | 120 KB |
| **16:9 (Hero Banner)** | 412 x 232 dp | 412 x 232 px | 824 x 464 px | 1236 x 695 px | WebP Lossy (Q=82) | 180 KB |
| **9:16 (Fullscreen BG)** | 412 x 915 dp | 412 x 915 px | 824 x 1830 px | 1236 x 2745 px | WebP Lossy (Q=80) | 280 KB |
| **Seamless Texture** | 512 x 512 dp | 512 x 512 px | 512 x 512 px | 512 x 512 px | WebP Lossy (Q=75, Tile)| 65 KB |

---

## 3. The 3-Level Fallback Ladder

To guarantee that ArmSphere **never displays a broken image icon, a white flash, or a blank unstyled container**, every network and bundled image must implement the strict 3-Level Fallback Ladder:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ LEVEL 1: HIGH-RES RENDER                                                    │
│ Target network image or bundled high-res WebP asset loaded into memory.     │
│ Verified against cacheWidth / cacheHeight to prevent GPU texture bloat.    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ (If network fail, 404, or decoding error)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ LEVEL 2: BUNDLED LOW-RES / CATEGORY DEFAULT ASSET                           │
│ Instant synchronous load from bundled assets:                              │
│ - Athlete: `assets/images/defaults/avatar_neutral_dark.webp`                │
│ - Tournament: `assets/images/defaults/tournament_poster_fallback.webp`      │
│ - Club: `assets/images/defaults/club_banner_fallback.webp`                  │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ (If asset missing or bundle corrupted)
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ LEVEL 3: PROCEDURAL GPU SHADER & VECTOR GLYPH                               │
│ Zero-asset fallback rendered via Flutter CustomPainter / LinearGradient:     │
│ - Obsidian gradient (#070A11 -> #121826) with subtle 45deg precision grid.  │
│ - Centered high-contrast vector icon (#38BDF8 / #D4AF37) with initial glyph.│
│ - 100% offline guaranteed, 0ms latency, zero memory allocation overhead.    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Comprehensive 66-Screen Master Media Asset Registry

### 4.1 System & Brand Core (M0)
| Asset ID | Target Screens | Description | Ratio | Max Dim (@3x) | Format | Budget | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `M0-LOGO-FULL` | 01, 09, 42, 61 | ArmSphere Master Monogram + Logotype in Champagne Gold | 4:1 | 960 x 240 px | SVG / WebP | 45 KB | P0 (Boot) |
| `M0-ICON-GOLD` | Splash, App Bar | Embossed Gold Grip & Anvil Icon | 1:1 | 512 x 512 px | WebP Lossless | 65 KB | P0 (Boot) |
| `M0-SEAL-FED` | 08, 20, 42, 47 | Official International Federation Holographic Watermark | 1:1 | 384 x 384 px | WebP Lossless | 50 KB | P1 (Preload) |

### 4.2 Bundled Textures & Hero Backgrounds (M1)
| Asset ID | Target Screens | Description | Ratio | Max Dim (@3x) | Format | Budget | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `M1-TEX-KNURL` | Global App Bg | Seamless Dark Knurled Steel Grid Pattern | 1:1 | 512 x 512 px | WebP Tile | 45 KB | P0 (Boot) |
| `M1-TEX-CHALK` | 07, 10, 11, 26 | Subtle Arena Chalk Dust & Atmospheric Vignette | 9:16 | 1236 x 2745 px | WebP Lossy | 180 KB | P1 (Preload) |
| `M1-HERO-ARENA` | 01, 06, 16, 17 | High-Tension Championship Stage Lighting & Dual Podiums | 16:9 | 1236 x 695 px | WebP Lossy | 160 KB | P1 (Preload) |
| `M1-HERO-GRIP` | 07, 19, 33, 40 | Macro Shot of Clashed Arms, Knuckles & Chalk Smoke | 16:9 | 1236 x 695 px | WebP Lossy | 175 KB | P1 (Preload) |

### 4.3 Division & Weight Class Badges (M4)
| Asset ID | Target Screens | Description | Ratio | Max Dim (@3x) | Format | Budget | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `M4-BDG-HEAVY` | 08, 17, 20, 54 | Super Heavyweight (110kg+) - Titanium Anvil Emblem | 1:1 | 256 x 256 px | WebP Lossless | 28 KB | P2 (On-Demand) |
| `M4-BDG-MIDDLE` | 08, 17, 20, 54 | Middleweight (86-105kg) - Forged Steel Shield Emblem | 1:1 | 256 x 256 px | WebP Lossless | 28 KB | P2 (On-Demand) |
| `M4-BDG-LIGHT` | 08, 17, 20, 54 | Lightweight (-85kg) - Tempered Blade Emblem | 1:1 | 256 x 256 px | WebP Lossless | 28 KB | P2 (On-Demand) |
| `M4-BDG-JUNIOR` | 08, 17, 20, 54 | Junior / Youth Division - Bronze Wing Emblem | 1:1 | 256 x 256 px | WebP Lossless | 28 KB | P2 (On-Demand) |
| `M4-BDG-MASTERS`| 08, 17, 20, 54 | Masters Division (40+) - Gold Laurel Emblem | 1:1 | 256 x 256 px | WebP Lossless | 28 KB | P2 (On-Demand) |

### 4.4 Referee Certification Insignia (M4)
| Asset ID | Target Screens | Description | Ratio | Max Dim (@3x) | Format | Budget | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `M4-REF-MASTER` | 25, 26, 28, 55 | Master International Referee - Gold Compass & Whistle | 1:1 | 256 x 256 px | WebP Lossless | 32 KB | P2 (On-Demand) |
| `M4-REF-NAT` | 25, 26, 28, 55 | Senior National Referee - Polished Silver Compass | 1:1 | 256 x 256 px | WebP Lossless | 30 KB | P2 (On-Demand) |
| `M4-REF-REG` | 25, 26, 28, 55 | Certified Regional Referee - Gunmetal Steel Shield | 1:1 | 256 x 256 px | WebP Lossless | 28 KB | P2 (On-Demand) |

### 4.5 Empty State Atmospheric Illustrations (M1/M7)
| Asset ID | Target Screens | Description | Ratio | Max Dim (@3x) | Format | Budget | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `M1-EMP-NOTOURN`| 16, 48, 52 | Solitary Armwrestling Table under Spotlight in Empty Arena | 16:9 | 720 x 405 px | WebP Lossy | 75 KB | P3 (Lazy) |
| `M1-EMP-NOTRAIN`| 10, 13 | Unracked Loading Pin and Straps on Steel Floor | 16:9 | 720 x 405 px | WebP Lossy | 70 KB | P3 (Lazy) |
| `M1-EMP-NOFEED` | 30, 35 | Silent Chalk Stand with Dust Suspended in Beam | 16:9 | 720 x 405 px | WebP Lossy | 68 KB | P3 (Lazy) |
| `M1-EMP-NOCHAT` | 32, 64 | Steel Radio Mic and Headphones on Oak Bench | 16:9 | 720 x 405 px | WebP Lossy | 65 KB | P3 (Lazy) |
| `M1-EMP-OFFLINE`| Global Offline | Heavy Severed Steel Cable with Sparks Frozen | 16:9 | 720 x 405 px | WebP Lossy | 72 KB | P1 (Preload) |

### 4.6 Video Media Assets (M5) — Authorized Use Cases Only
| Asset ID | Target Screens | Context & Behavior | Ratio | Resolution & Encoding | Max File Size | Audio Policy |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `M5-VID-HEROLOOP`| 17 (Championship) | Seamless 4-6s atmospheric loop of chalk rise and table tension | 16:9 | 1080p, H.264/AV1, 24fps | 2.2 MB | Muted Always (No audio track) |
| `M5-VID-STREAM` | 24 (Live Stream) | Low-latency HLS stream from table broadcast feed | 16:9 | 1080p/720p Adaptive HLS | Dynamic Stream | User unmute with ducking |
| `M5-VID-DISPUTE`| 27 (Dispute Rev) | 10-30s referee slow-mo clip upload with frame scrubbing | 16:9 | 1080p 60fps MP4 | Max 15 MB | Audio scrub enabled |
| `M5-VID-COMMFEED`| 30, 32 (Feed) | User technique / highlight video on-demand modal | 9:16 / 16:9 | 720p/1080p MP4 | Max 25 MB | User click to play |

### 4.7 Audio Sensory Assets (M6)
| Asset ID | File Name | Context & Trigger | Format | Sample Rate | Max Size |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `M6-SND-CHALL` | `challenge_accepted.wav`| Competitor accepts an official challenge | WAV 16-bit | 44.1 kHz | 40 KB |
| `M6-SND-WIN` | `match_won.mp3` | Official pin recorded, match won | MP3 320kbps | 44.1 kHz | 41 KB |
| `M6-SND-PR` | `pr_achieved.wav` | New personal record locked into database | WAV 16-bit | 44.1 kHz | 91 KB |
| `M6-SND-CLICK` | `pro_tick.wav` | Ultra-short metallic tactile feedback on scorepad / stepper | WAV 16-bit | 48 kHz | 8 KB |

---

## 5. Total Disk Budget & Performance Constraints

- **Total Bundled Assets in APK**:
  - M0 (Brand Core): 210 KB
  - M1 (Textures, Heroes, Empty States): 1,020 KB
  - M4 (Division & Ref Badges): 380 KB
  - M6 (Audio Sensory Pack): 180 KB
  - **Total Bundled Asset Footprint**: **~1.79 MB** (Well below the 5.0 MB global APK asset ceiling).
- **RAM Footprint Ceiling**:
  - Flutter ImageCache max capacity: 100 MB.
  - Image Cache entry cap: 100 images.
  - Strict enforcement of `cacheWidth` and `cacheHeight` on all network and asset images:
    - Avatars: `cacheWidth: 192, cacheHeight: 192` (Prevents loading a 2048x2048 user upload into a full 16MB uncompressed RGBA framebuffer).
    - Hero Banners: `cacheWidth: 1080, cacheHeight: 608`.

---

## 6. Implementation Verification Gate

- **Asset ID Determinism**: Every asset referenced in Flutter UI code must use the exact string constants defined in `ArmSphereMediaRegistry`.
- **Zero Raw Strings**: All asset paths must resolve through `core/constants/asset_paths.dart`.
- **Approved Sign-Off**: Ready for Stage 3 Image & Video Prompt Packs (`47_` and `48_`).
