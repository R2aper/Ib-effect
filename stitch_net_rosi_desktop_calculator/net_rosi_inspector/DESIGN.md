---
name: Net ROSI Inspector
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#444748'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#747878'
  outline-variant: '#c4c7c7'
  surface-tint: '#5f5e5e'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1c1b1b'
  on-primary-container: '#858383'
  inverse-primary: '#c9c6c5'
  secondary: '#5e5e5e'
  on-secondary: '#ffffff'
  secondary-container: '#e4e2e2'
  on-secondary-container: '#646464'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#1b1c1c'
  on-tertiary-container: '#848484'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c9c6c5'
  on-primary-fixed: '#1c1b1b'
  on-primary-fixed-variant: '#474646'
  secondary-fixed: '#e4e2e2'
  secondary-fixed-dim: '#c8c6c6'
  on-secondary-fixed: '#1b1c1c'
  on-secondary-fixed-variant: '#474747'
  tertiary-fixed: '#e3e2e2'
  tertiary-fixed-dim: '#c7c6c6'
  on-tertiary-fixed: '#1b1c1c'
  on-tertiary-fixed-variant: '#464747'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  headline-lg:
    fontFamily: IBM Plex Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  headline-md:
    fontFamily: IBM Plex Sans
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
  headline-sm:
    fontFamily: IBM Plex Sans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
  body-lg:
    fontFamily: IBM Plex Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  body-md:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  body-sm:
    fontFamily: IBM Plex Sans
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
  label-code-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-code-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
  metric-display:
    fontFamily: JetBrains Mono
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
spacing:
  gutter: 0.5rem
  margin: 0rem
  space-xs: 0.125rem
  space-sm: 0.25rem
  space-md: 0.5rem
  space-lg: 0.75rem
  space-xl: 1rem
---

## Brand & Style

This design system defines an authoritative, high-density native desktop utility for cybersecurity risk quantification, Return on Security Investment (ROSI) analysis, and regulatory auditing in accordance with GOST R ISO/IEC 27005 and FSTEC baseline requirements.

The visual style is **Precision Functionalism / Technical Desktop**:
- A near-monochrome environment focused entirely on numerical clarity, regulatory rigor, and auditability.
- Chromatic restraint: all structural elements remain desaturated to avoid visual fatigue during multi-hour modeling sessions; color is reserved strictly for threat matrices and risk level indicators.
- Desktop-native ergonomics: unified title bars, master-detail panes, keyboard-navigable tabular matrices, split-panel workspaces, and low-latency interaction models.
- Tone: institutional, reliable, dispassionate, precise.

## Colors

The application relies on a clinical light palette designed to maximize contrast for high-density tabular calculation. Color is never decorative; it functions strictly as semantic telemetry for risk prioritization.

### Functional Surfaces & Structural Lines
- **Window Canvas (`#FAFAFA`)**: The base background for the overall application window, inactive viewports, and native split margins.
- **Panel Surface (`#FFFFFF`)**: Master list containers, detail panes, inspector sidebars, and data tables.
- **Surface Hover / Subtle Selection (`#F4F4F5`)**: Row hovers, menu bar item hover states, and inactive tab headers.
- **Active / Accent Selection (`#E4E4E7`)**: Active row focus, splitter bars, and selected master tree nodes.
- **Hairline Border (`#E5E5E5`)**: 1px dividers between splitters, native menu dividers, table grid lines, and docked inspector edges.
- **Deep Typography (`#0A0A0A`)**: Text primary, formula expressions, scalar outputs, and header glyphs.
- **Muted Typography (`#737373`)**: Secondary labels, measurement units (₽, %, дн.), metadata stamps, and regulatory clause citations.

### Risk Criticality Semantics (Badges & Indicators Only)
- **Низкий (Low)**: Text `#16A34A`, background `#F0FDF4`, border `#BBF7D0` (Acceptable risk / Residual baseline).
- **Средний (Medium)**: Text `#CA8A04`, background `#FEFCE8`, border `#FEF08A` (Supervised exposure / Scheduled mitigation).
- **Высокий (High)**: Text `#EA580C`, background `#FFF7ED`, border `#FFEDD5` (Unacceptable / Priority investment required).
- **Критический (Critical)**: Text `#DC2626`, background `#FEF2F2`, border `#FECACA` (Immediate operational hazard / FSTEC non-compliance).

## Typography

Typography prioritizes Cyrillic clarity, tabular alignment, and strict vertical rhythm. 

- **Primary UI & Text**: **IBM Plex Sans**. Delivers authoritative neutral geometry, high rendering fidelity at compact sizes (11–13px), and balanced Cyrillic character sets compliant with technical documentation standards.
- **Data, Formulae, and Metrics**: **JetBrains Mono**. Used across all numerical calculations, financial values (руб.), mathematical models (ALE, SLE, ARO, ROSI), risk matrices, and threat IDs (e.g., `УБИ.025`). All digits are tabular lining (`font-feature-settings: "tnum"`), ensuring flawless column verticality across data grids.

## Elevation & Depth

This system intentionally eliminates blurred shadows, volumetric gradients, and skeuomorphic drop elevations.

- **Planar Depth via Borders**: Hierarchy is established strictly through 1px structural hairline borders (`#E5E5E5`) and layered surfaces (`#FAFAFA` window background to `#FFFFFF` floating panels).
- **Z-Index Layering**:
  - `Base`: Application window substrate (`#FAFAFA`).
  - `Surface`: Fixed panels, tabular matrices, sidebars (`#FFFFFF`).
  - `Overlay (Flyouts / Context Menus)`: 1px hairline border (`#E5E5E5`), crisp solid fill (`#FFFFFF`), with a single hard 2px keyline shadow (`0 2px 4px rgba(0, 0, 0, 0.04)`) to separate context menus from underlying tabular cells.
- **Divider Splitters**: Active draggable divider is a 1px border with a 3px invisible grab target, highlighted to `#0A0A0A` only on direct hover or drag.

## Shapes

The design system enforces a sharp geometric aesthetic (`roundedness: 0`), reflecting desktop technical instrumentation and native CAD/IDE conventions:
- Tables, panels, splitters, tabs, and input fields feature 0px border radius.
- Semantic risk badges, contextual filter chips, and segmented controls feature a slight 2px border radius to soften legibility without compromising structural density.

## Components

### Buttons & Toolbars
- **Primary Action (e.g., «Рассчитать ROSI»)**: Background `#0A0A0A`, foreground `#FFFFFF`, height 26px, padding `0 10px`, font size 12px, font weight 500, border radius 0px. Hover: `#262626`. Active: `#404040`.
- **Secondary / Ghost Action**: Background transparent, border 1px solid `#E5E5E5`, foreground `#0A0A0A`, height 26px, padding `0 8px`. Hover: `#F4F4F5`.
- **Icon Buttons (Toolbar)**: 24x24px, 1px padding, hover background `#E4E4E7`.

### Risk Criticality Badges
- Compact inline pills: Height 18px, font JetBrains Mono 11px, weight 500, padding `1px 6px`, border-radius 2px.
- Display values:
  - `КРИТИЧЕСКИЙ` (Red text `#DC2626`, fill `#FEF2F2`, border 1px solid `#FECACA`)
  - `ВЫСОКИЙ` (Orange text `#EA580C`, fill `#FFF7ED`, border 1px solid `#FFEDD5`)
  - `СРЕДНИЙ` (Yellow/Amber text `#CA8A04`, fill `#FEFCE8`, border 1px solid `#FEF08A`)
  - `НИЗКИЙ` (Green text `#16A34A`, fill `#F0FDF4`, border 1px solid `#BBF7D0`)

### Data Grids & Tabular Views
- **Header Cells**: Height 24px, background `#FAFAFA`, border-bottom 1px solid `#E5E5E5`, border-right 1px solid `#E5E5E5`, font IBM Plex Sans 11px, font-weight 600, text `#525252`, uppercase letter-spacing 0.04em.
- **Data Rows**: Height 22px (dense mode) or 26px (standard mode). Alternating rows remain `#FFFFFF`, with 1px hairline horizontal divider `#E5E5E5`.
- **Selected Row**: Background `#E4E4E7` with 2px solid `#0A0A0A` left indicator bar.
- **Monetary & Formula Cells**: Right-aligned, font JetBrains Mono 12px, tabular numerals (`font-variant-numeric: tabular-nums`).

### Numeric Inputs & Parameter Controls
- **Formula Inputs (e.g., Оценка ущерба, SLE)**: Height 24px, border 1px solid `#E5E5E5`, font JetBrains Mono 12px, padding `0 6px`. Focus: border 1px solid `#0A0A0A`, outline none.
- **Inline Steppers**: Integrated spin buttons for frequency values (ARO, 0.01 – 10.0), height matched to cell grid.

### Master-Detail Split Panels
- Master panel displays tree grid of registered information assets and associated FSTEC threat vectors.
- Detail pane organizes parameters into clean bordered group sections:
  1. *Параметры уязвимости и угрозы* (Vulnerability & Threat telemetry).
  2. *Финансовые потери (SLE / ALE)* (Single & Annualized Loss Expectancy).
  3. *Стоимость контрмер (Cost of Tool)* (Capital & operational expenditures).
  4. *Итоговый показатель ROSI* (Formula: `ROSI = ((ALE_до - ALE_после) - Cost) / Cost * 100%`).
- Calculated output uses `metric-display` in JetBrains Mono 22px bold with automatic coloring: positive yield in `#0A0A0A`, negative in `#DC2626`.