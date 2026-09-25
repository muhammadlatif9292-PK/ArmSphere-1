# ArmSphere Typography System
**Dual-Font Architectural Hierarchy & Accessibility Scaling**
**Document Version**: 1.0.0
**Fonts Verified in Assets**: `assets/fonts/SpaceGrotesk*.ttf` and `assets/fonts/Inter*.ttf`
**Status**: APPROVED & LOCKED

---

## 1. Font Family Architecture

ArmSphere pairs two distinct, complementary typefaces to create an **engineered athletic identity**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    DUAL-FONT SYSTEM ROLES                       │
├─────────────────┬──────────────┬────────────────────────────────┤
│ Font Family     │ Weights Used │ Assigned Interface Domain      │
├─────────────────┼──────────────┼────────────────────────────────┤
│ Space Grotesk   │ Bold (700)   │ Headlines, Display Banners,    │
│ (Display/Engine)│ SemiBold(600)│ Match Scores, ELO Ratings,     │
│                 │ Medium (500) │ Category Pills, Table Numbers  │
├─────────────────┼──────────────┼────────────────────────────────┤
│ Inter           │ SemiBold(600)│ Body Prose, Subtitles, Lists,  │
│ (Body/UI Prose) │ Medium (500) │ Form Input Labels, Captions,   │
│                 │ Regular(400) │ Accordions, Rules, Dialogs     │
└─────────────────┴──────────────┴────────────────────────────────┘
```

---

## 2. Complete Typographic Scale & Styles

All text styles map directly to Material 3 `TextTheme` properties in `AppTheme.darkTheme`:

| Token Name | Family | Weight | Size | Line Height | Letter Spacing | Primary Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | SpaceGrotesk | Bold (700) | **32sp** | 38dp (1.18) | -1.0 | Hero headers, Welcome title |
| `displayMedium`| SpaceGrotesk | Bold (700) | **28sp** | 34dp (1.21) | -0.75 | Event detail title, Belt name |
| `displaySmall` | SpaceGrotesk | Bold (700) | **24sp** | 30dp (1.25) | -0.5 | Section mega-titles |
| `headlineLarge`| SpaceGrotesk | w700 | **20sp** | 26dp (1.30) | -0.5 | Top App Bar title, Card headers |
| `headlineMedium`| SpaceGrotesk| w600 | **18sp** | 24dp (1.33) | -0.25 | Sub-section titles, Modal title |
| `headlineSmall`| SpaceGrotesk | w500 | **16sp** | 22dp (1.37) | 0.0 | High-emphasis list titles |
| `titleLarge` | Inter | w600 | **17sp** | 23dp (1.35) | 0.0 | Dialog titles, Group headers |
| `titleMedium` | Inter | w600 | **15sp** | 21dp (1.40) | 0.1 | Card primary title, Athlete name|
| `titleSmall` | Inter | w500 | **13sp** | 18dp (1.38) | 0.1 | Sub-headers, Club names |
| `bodyLarge` | Inter | Regular (400)| **15sp** | 22dp (1.46) | 0.2 | Longform announcements, rules |
| `bodyMedium` | Inter | Regular (400)| **13sp** | 19dp (1.46) | 0.2 | Standard description, bio |
| `bodySmall` | Inter | Regular (400)| **11sp** | 15dp (1.36) | 0.3 | Timestamps, metadata, hints |
| `labelLarge` | Inter | w600 | **14sp** | 18dp (1.28) | 0.4 | Primary action buttons |
| `labelMedium` | Inter | w700 | **11sp** | 14dp (1.27) | **1.0 (Caps)**| Section headers, Category pills |
| `labelSmall` | Inter | Regular (400)| **10sp** | 13dp (1.30) | 0.2 | Micro tags, weight class badges |
| `scoreDisplay` | SpaceGrotesk | w800 | **36–48sp**| 50dp (1.04) | -1.5 | Referee match scorepad numbers |

---

## 3. Tabular Figure & Number Alignment

In sports interfaces, shifting numbers create visual jitter when values update.
- **ELO Numbers & Scores**: All numerical data uses tabular alignment (`FontFeature.tabularFigures()`).
- When a timer counts down (`04d : 12h : 30m`) or ELO score changes, the layout width remains fixed.

```dart
static const TextStyle monoNumberStyle = TextStyle(
  fontFamily: AppTheme.fontDisplay,
  fontFeatures: [FontFeature.tabularFigures()],
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
);
```

---

## 4. Accessibility & Dynamic Text Scaling

ArmSphere is engineered to withstand Android system font scaling up to **200%**:
1. **No Fixed Container Heights with Text**: Text containers use `minHeight` or padding rather than fixed pixel heights to avoid vertical text clipping.
2. **Flexible Cards**: Cards housing athlete names use `maxLines: 1` with `TextOverflow.ellipsis` on subtitles, while preserving full line wrapping on titles.
3. **Touch Targets Independent of Font Scale**: Buttons maintain minimum 48dp hit targets regardless of user font size.
