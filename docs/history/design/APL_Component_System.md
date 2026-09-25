# APL Component System

> Version: v1.1  
> Purpose: 固定所有 Dashboard 元件尺寸、樣式、字體、邊框、Glow，避免每次重新設計。

## 1. Stock Node Component

Each stock node is a fixed UI component.

### Node Content

```text
Rank
Ticker
Momentum Score
Buyability Indicator
Leader Lock if eligible
```

### Node Size by Rank

| Rank Group | Base Diameter | Visual Role |
|---|---:|---|
| Rank 1–5 | 96px | Core Leaders |
| Rank 6–15 | 72px | Watch Zone |
| Rank 16–30 | 56px | Observation |

Momentum size formula:

```text
finalDiameter = baseDiameter + ((MomentumScore - 56) / 34) × 18
```

Clamp:

```text
min = baseDiameter - 8
max = baseDiameter + 28
```

### Node Styling

| Layer | Style |
|---|---|
| Fill | `#07121C`, opacity 78% |
| Outer Border | Sector Color, 2px |
| Glow | Buyability Glow |
| Hover / Tooltip | Optional, not shown in static SVG |

### Node Typography

| Text | Font | Size Large | Size Medium | Size Small |
|---|---|---:|---:|---:|
| Rank | JetBrains Mono Bold | 14px | 13px | 11px |
| Ticker | Montserrat Bold | 26px | 20px | 16px |
| Momentum Score | JetBrains Mono | 15px | 12px | 10px |
| Buyability | JetBrains Mono / Symbol | 10px | 9px | 8px |
| LOCK | JetBrains Mono Bold | 10px | 9px | 8px |

Rules:

- Ticker never wraps;
- Rank always appears above ticker;
- Momentum Score always appears below ticker;
- Buyability indicator appears at node bottom;
- LOCK appears only if Buyability >= 8.

## 2. Buyability Visual Mapping

| Buyability | Range | Visual | Glow | State |
|---|---:|---|---:|---|
| 5-star | 8–10 | Cyan | 24px | Strong Buyability / Leader Lock |
| 4-star | 6–7 | Green | 18px | Good Opportunity |
| 3-star | 4–5 | Blue | 10px | Neutral |
| 2-star | 2–3 | Gray Blue | 5px | Wait / Observe |
| 1-star | 0–1 | Red | 0px | Too Extended / Weak |

In SVG render, star symbol may be replaced by text label:

```text
5-star
4-star
3-star
2-star
1-star
```

This avoids font / encoding instability while preserving meaning.

## 3. APL Core Component

The center core is not decorative. It is the system origin.

| Element | Text | Font | Size |
|---|---|---|---:|
| Lock Label | `LEADER LOCK` | JetBrains Mono Bold | 16px |
| Main | `APL` | Montserrat ExtraBold | 64–90px |
| Sub | `Deep-Scan` | Montserrat Bold | 26–32px |
| Status | `LIVE SCAN` | JetBrains Mono Bold | 13px |

Core visual:

- cyan pulse rings;
- no external logo image;
- text centered exactly on radar origin.

APL Wordmark Material v2.1:

- Main `APL` text must use a glass-metal gradient.
- Gradient direction: upper-left silver to lower-right light cyan reflection.
- Base colors: Silver, Glass White, Light Cyan Reflection.
- Use subtle white stroke only; avoid heavy glow.
- Add one faint cyan reflection line above the wordmark.
- The wordmark should feel premium, cold, precise, and terminal-grade.

## 4. Radar Component

| Property | Value |
|---|---:|
| Rings | 6 |
| Ring Stroke | 1px |
| Ring Color | APL Cyan |
| Ring Opacity | 15% |
| Radial Lines | every 30° |
| Degree Labels | every 30° |
| Sweep Angle | 35° |
| Sweep Width | 14° |
| Sweep Tail Layers | 2 |

Sweep:

- main beam opacity 65%;
- focused beam wedge opacity 18%;
- tail 1 opacity 13%;
- tail 2 opacity 9%;
- tail 3 opacity 5.5%;
- blur 18px;
- originates from APL core.
- beam must feel like radar sweep, not a spotlight.
- beam must not visually cover stock nodes.

## 5. Dashboard Frame Component

| Property | Value |
|---|---|
| Fill | `#08131F`, opacity 78% |
| Stroke | APL Cyan, opacity 55% |
| Radius | 8px |
| Padding | 18px |
| Header | APL Cyan |

Dashboard sections:

1. Header
2. Momentum Leaders Top 30 Overview
3. Buyability Distribution
4. Sector Distribution
5. Market Scan Summary

## 6. Buyability Donut Component

| Property | Value |
|---|---:|
| Diameter | 164px |
| Stroke Width | 28px |
| Inner Hole | 52px radius |
| Center Number | Actual rendered Momentum Leaders count |
| Center Label | `TOTAL` |

Segments:

- 8–10;
- 6–7;
- 4–5;
- 2–3;
- 0–1.

## 7. Buyability Distribution Rows

| Row | Label | Color |
|---|---|---|
| 1 | `5-star (8–10)` | APL Cyan |
| 2 | `4-star (6–7)` | Bullish Green |
| 3 | `3-star (4–5)` | Electric Blue |
| 4 | `2-star (2–3)` | Gray Blue |
| 5 | `1-star (0–1)` | Bearish Red |

Each row:

```text
width: 210px
height: 34px
radius: 5px
border: APL Cyan 22% opacity
value: right aligned
```

## Buyability Distribution Percentage Mode v1.6

Right Dashboard must not duplicate the full Buyability legend.

The left panel explains:

- 5-star
- 4-star
- 3-star
- 2-star
- 1-star

The right dashboard shows both count and percentage.

Format:

```text
強烈買入 (8-10)     13 個 43%
良好機會 (6-7)       2 個 7%
機會觀察 (4-5)      11 個 37%
等待觀察 (2-3)       3 個 10%
過度延伸 (0-1)       1 個 3%
```

Rules:

- Do not repeat "5-star", "4-star", "Strong Buyability", etc. on the right panel.
- Use Chinese rating labels.
- Each row must show both Count and Percentage.
- Use color-coded bars under each row.
- Percent values must be right-aligned.
- Count and percentage values must use JetBrains Mono.
- Counts may be used internally but should not dominate the visual.
- Percent value font size must be 16px.
- Percent value weight must be 900.
- Do not use percentage labels below 14px.
- Donut segment length and bar length must be generated from the same percentage data.
- The donut must never be manually approximated.

## 8. Sector Distribution Bar

| Property | Value |
|---|---:|
| Label X | 1484 |
| Bar X | 1630 |
| Bar Width | 150 |
| Bar Height | 14 |
| Value X | 1845 |

Background:

```text
#132637
```

Fill:

Sector color.

## 8.1 Sector Icon System

### Purpose

Every sector displayed in the dashboard must include a corresponding icon before the sector name.

The icon improves readability and allows users to identify industries at a glance.

### Layout

```text
[Sector Icon]  Sector Name  ████████  Value
```

Example:

```text
Semiconductor        ██████████   13
AI / Software        ████████     11
Healthcare / Bio     █████        5
Networking / Infra   █████        5
Industrial           ███          3
Others               ██           2
```

### Icon Specifications

| Sector | Icon | Meaning |
|---|---|---|
| Semiconductor | CPU / Chip | Chip manufacturing, semiconductor devices, equipment |
| AI / Software | Brain / AI Chip | Artificial Intelligence, Software, Cloud Computing |
| Healthcare / Bio | Heart / Medical Cross | Biotechnology, Medical Devices, Healthcare |
| Networking / Infrastructure | Wireless Signal / Network | Networking, Communications, Infrastructure |
| Industrial | Factory | Industrial Manufacturing, Construction, Engineering |
| Consumer | Shopping Bag | Consumer Products, Retail |
| Automotive | Car | EV, Automotive Supply Chain |
| Energy | Lightning Bolt | Energy, Power Management |
| Materials | Cube | Chemicals, Materials, Mining |
| Aerospace / Defense | Aircraft | Aerospace, Defense, Military |
| Financial | Bank | Banking, Insurance, Financial Services |
| Others | Four Dots | Uncategorized Companies |

### Icon Style

All icons must follow the APL Deep-Scan design language.

Requirements:

- Outline style only
- Stroke Width: 2px
- Size: 22px x 22px
- Color follows sector color
- No filled icons
- Rounded stroke
- Consistent optical weight
- SVG vector only

### Rendering Rules

- Icons always appear before the sector name.
- The icon and sector text are vertically centered.
- The icon color must match the sector bar color.
- Do not replace icons with emoji.
- Use the official APL SVG icon set.
- If a sector has no predefined icon, use the Others icon.

## Sector Label Style

Each sector label must display both English and Chinese.

Format:

```text
[Sector Icon] English Name
              Chinese Name
```

Examples:

```text
Semiconductor
半導體

AI / Software
AI／軟體

Healthcare / Bio
醫療／生技

Networking / Infrastructure
網路／基礎建設
```

Typography:

English:

- Font: Montserrat SemiBold
- Size: 15px

Chinese:

- Font: Noto Sans TC Medium
- Size: 12px
- Opacity: 75%

Both lines share the same sector color.

The icon is vertically centered with the English label.

## Unified Sector Names

| English | Chinese |
|---|---|
| Semiconductor | 半導體 |
| AI / Software | AI／軟體 |
| Healthcare / Bio | 醫療／生技 |
| Networking / Infrastructure | 網路／基礎建設 |
| Industrial | 工業 |
| Consumer | 消費 |
| Energy | 能源 |
| Materials | 材料 |
| Automotive | 汽車 |
| Aerospace / Defense | 航太／國防 |
| Financial | 金融 |
| Others | 其他 |

## Top 5 Sector Distribution

### Purpose

Display only the five largest sectors represented in the current Top 30 Momentum Leaders.

### Sorting

- Sort by company count descending.
- Display Top 5 sectors only.
- Do not display Others in the right-side dashboard.
- Do not aggregate smaller sectors into Others in this module.

### Layout

```text
[Sector Icon] English Name｜Chinese Name    Horizontal Bar    Count
```

Example:

```text
Semiconductor｜半導體          ██████████ 10
Healthcare / Bio｜醫療／生技   ██████      6
Industrial｜工業              █████       5
AI / Software｜AI／軟體       ███         3
Networking｜網路              ██          2
```

### Rules

- Icons follow the APL Icon System.
- Sort dynamically based on the current CSV.
- Bars are proportional to the largest sector.
- Counts are right-aligned.
- If multiple sectors have the same count, sort alphabetically by English name.

### Spacing

- Each sector row height must be 50-52px.
- Leave clear vertical breathing room between rows.
- Chinese sector label must be at least 10-11px; recommended static SVG size is 12px.
- English sector label must be visually stronger than the Chinese line.

## Sector Distribution Visual Context v1.9

Purpose:

Sector Distribution must read like a dashboard module, not a plain category list.

Header layout:

```text
[ Section Icon ]  SECTOR DISTRIBUTION
                  產業分佈
```

Row layout:

```text
[ Icon Box ]  English Sector
              Chinese Sector        Horizontal Bar      Count    %
```

Rules:

- Display Top 5 sectors only.
- Sort by company count descending.
- Do not display Others.
- Do not aggregate smaller sectors into Others in the right-side dashboard.
- Each sector row must include a 28px × 28px icon box.
- Icon box background: Deep Ocean.
- Icon stroke and icon box stroke must match the sector color.
- English sector label uses the sector color.
- Chinese sector label uses Gray to reduce visual noise.
- Bar width is proportional to the largest visible sector.
- Count and percentage values must be right aligned.
- Percentage is calculated as sector count / visible Momentum Leaders count.
- Use JetBrains Mono for count and percentage.

## Sector Distribution v2.6 Override

This section overrides earlier rules that displayed Others.

Rules:

- Show Top 5 sectors only.
- Delete Others from the right-side Sector Distribution.
- Each sector row height: 50-52px.
- Icon box: 28px x 28px.
- English label: 14px.
- Chinese label: 12px.
- Bar, count, and percentage must align to the right-side value columns.
- Count and percentage must not collide.

Color hierarchy:

- Dashboard header and main title: APL Cyan.
- Dashboard subheader: Gray.
- English section title: APL Cyan.
- Chinese section subtitle: Gray.

## Right Dashboard Fixed Section Layout v2.3

Purpose:

Prevent the right dashboard from becoming visually crowded.

Fixed section rhythm:

```text
Header                      120px
Buyability Distribution     220px
Sector Distribution         240px
Market Scan Summary         180px
Bottom breathing space      remaining
```

Typography:

| Element | Font | Size | Weight |
|---|---|---:|---:|
| Dashboard header | Montserrat / Noto Sans TC | 22-23px | 800 |
| Section title | Noto Sans TC | 19px | 800 |
| English sector label | Montserrat SemiBold | 14px | 800 |
| Chinese sector label | Noto Sans TC Medium | 12px | 500 |
| Percentage value | JetBrains Mono | 16px | 900 |
| Summary value | JetBrains Mono | 16px | 800-900 |

## 9. Market Scan Summary

Required statistics:

- 平均動能分數;
- 平均買入評級;
- 平均 6 個月績效;
- 平均 3 個月績效;
- 最高相對成交量.

## 9.1 Market Scan Summary Visual Context v1.8

Purpose:

Market Scan Summary must read like a terminal HUD module, not a plain text list.

Layout:

```text
[ Summary Icon ]  MARKET SCAN SUMMARY
                  市場掃描總結

[ Icon Box ]  中文主標籤
              English subtitle                         Value
```

Required rows:

| Row | Chinese Label | English Subtitle | Value Source |
|---|---|---|---|
| 1 | 平均動能分數 | Average Momentum Score | Top list average Momentum Score |
| 2 | 平均買入評級 | Average Buyability Score | Top list average Buyability Score |
| 3 | 市場主題 | Market Theme | Theme mapping from sector concentration |
| 4 | 6M 平均表現 | 6M Performance (Avg) | Top list average 6M performance |
| 5 | 3M 平均表現 | 3M Performance (Avg) | Top list average 3M performance |
| 6 | 最高相對成交量 | Highest Relative Volume | Symbol with highest Rel Vol |

Icon rules:

- Each row must include a 28px × 28px outline icon box.
- Icon box background: Deep Ocean.
- Icon stroke color follows the row value color.
- Icons must be SVG outline only.
- Do not use emoji.

Typography:

- Section title English: JetBrains Mono, 18px, 900, APL Cyan.
- Section subtitle Chinese: Noto Sans TC, 12px, Gray.
- Chinese row label: Noto Sans TC, 13px, 800, White.
- English row subtitle: Montserrat, 11px, Gray.
- Value: JetBrains Mono, 13–16px, 900, right aligned.

Value colors:

- Momentum Score: APL Cyan.
- Buyability Score: Bullish Green.
- Market Theme: APL Cyan.
- 6M / 3M Performance: Bullish Green.
- Highest Relative Volume: Alert Orange.

All values are generated from CSV or fixed sector mapping.

## 9.2 Market Scan Summary Visual Context v2.0 Override

This section overrides earlier Market Scan Summary sizing rules.

Purpose:

Market Scan Summary should read like a high-density terminal information card.

Header:

- Section icon: 26px outline icon.
- English title: JetBrains Mono, 18px, 900, APL Cyan.
- Chinese subtitle: Noto Sans TC, 13px, 700, Gray.
- Header divider: disabled. Do not draw a horizontal line directly under the Market Scan Summary title/subtitle.

Rows:

- Each row uses a 32px x 32px outline icon box.
- Icon box radius: 6px.
- Icon box background: Deep Ocean at 92% opacity.
- Row icon stroke follows value color.
- Chinese row label: Noto Sans TC, 14px, 900, White.
- English row subtitle: Montserrat, 12px, 600, Gray.
- Value: JetBrains Mono, 14-17px, 900, right aligned.
- Divider line only between rows: Gray at 16% opacity.
- Do not draw a divider after the final Market Scan Summary row.

Spacing:

- Row baseline interval: 36px.
- Header-to-row gap must be visually clear but must not collide with the footer.
- Values must remain vertically centered with the row label pair.

## 9.3 Market Scan Summary Fixed Spacing v2.1 Override

This section overrides earlier Market Scan Summary vertical spacing rules.

Fixed position:

| Element | Y |
|---|---:|
| Section top divider | 668 |
| Section icon | 676 |
| English title baseline | 692 |
| Chinese subtitle baseline | 712 |
| Header divider | 724 |
| First row top | 728 |

Row rules:

- Each summary row uses fixed row height: 52px.
- Every label block is vertically centered within its row.
- Chinese label baseline: row top + 23px.
- English subtitle baseline: row top + 40px.
- Value baseline: row top + 34px.
- Icon box top: row top + 10px.
- Row divider: row top + 52px, only if another summary row follows.
- Divider must sit between rows and must never cross the Chinese label or English subtitle.
- The final summary row must end cleanly without a bottom divider line.
- All row values remain right-aligned.

Relationship with Sector Distribution:

- Market Scan Summary uses a fixed Y position.
- Market Scan Summary must not move upward when Sector Distribution has fewer rows.
- Minimum spacing between Sector Distribution and Market Scan Summary: 24px.
- If Sector Distribution content is short, keep the summary in its fixed position; do not pull it upward.

## 10. Deep-Scan Insight Component v1.9

Purpose:

This component is currently disabled in the 1920x1080 Radar Dashboard.

Reason:

The bottom insight box competes with radar labels and footer HUD information.

Current rule:

- Do not render the Deep-Scan Insight box in the main Radar Dashboard.
- Market theme and scan statistics remain available in the right-side Dashboard.
- Footer HUD remains active.

Legacy layout below is retained only for archived versions and must not be rendered unless explicitly re-enabled.

Layout:

```text
[ Radar Icon ]  DEEP-SCAN INSIGHT        Market Theme  {Market Theme}
                Capital remains concentrated in
                {Insight Theme}. {Leader Lock Count} Leader Lock stocks confirmed.
```

Fixed Position:

| Property | Value |
|---|---|
| X | 390 |
| Y | 920 |
| W | 1028 |
| H | 88 |
| Icon | Radar scan icon |
| Title font size | 18px |
| Body font size | 16px |
| Highlight line | APL Cyan, 16px, 900 |

Content Rules:

- The insight must be generated automatically from the weekly CSV.
- Priority inputs:
  1. Top Sector
  2. Market Theme
  3. Leader Lock Count
  4. Highest Relative Volume
  5. Average Momentum Score
- The insight should describe what the data reveals.
- Do not explain UI elements such as colors, glow effects, or node positions.
- Do not write generic guide text such as "Top 5 in Core Zone" or "Buyability receives glow".
- Highlight the most important theme and the Leader Lock / High Buyability count in APL Cyan.
- One sentence maximum, ideally under 140 characters when possible.

Template:

```text
Capital remains concentrated in {Insight Theme}; {Leader Lock Count} stocks meet APL High Buyability criteria.
```

Insight Theme Mapping:

| Top Sector | Insight Theme |
|---|---|
| Semiconductor | Semiconductor-led AI hardware |
| AI / Software | AI infrastructure and software leadership |
| Healthcare / Bio | Healthcare and biotech rotation |
| Industrial | industrial and infrastructure leadership |
| Networking / Infrastructure | networking infrastructure demand |
| Others | {Top Sector} leadership |

## Footer HUD Status Bar v1.7

The footer must behave like a terminal/HUD status bar, not a website slogan.

Format:

```text
● LIVE | MODE RADAR_RENDER | DATA APL MOMENTUM DATABASE | RANK MOMENTUM+BUYABILITY | DATE WEEK XX / YYYY-MM-DD | 1920×1080
```

Do not use slogan-style footer copy.

Layout:

| Property | Value |
|---|---|
| X | 390 |
| Y | 1044 |
| W | 990 |
| H | 30 |
| Font | JetBrains Mono |
| Font size | 12px |
| Background | #07111B at 86% opacity |
| Border | APL Cyan at 28% opacity |
| Top rail line | APL Cyan at 42% opacity |

Visual Rules:

- Footer is a functional telemetry rail.
- Use segmented labels and values.
- Labels use Gray.
- Important live/rank values use APL Cyan.
- No marketing slogan.
- No sentence-style copy.
- No "Find Tomorrow's Leaders" inside dashboard footer.

## Stock Node Text Rules v1.2

Static SVG node shows only:

1. Rank
2. Ticker
3. Momentum Score

Do not display:

- Buyability text inside node
- "3-star", "5-star" text inside node
- LOCK text inside node

Leader Lock:

- Use only small lock icon outside node
- position: bottom-right of node
- size: 12px
- color: APL Cyan
- opacity: 65%
- scale: 85% of previous icon size
- no glow filter
- only if Buyability >= 8

## Node Size by Rank v1.2

Rank 1-5:

- Base diameter: 70px
- Max diameter: 84px

Rank 6-15:

- Base diameter: 62px
- Max diameter: 76px

Rank 16-30:

- Base diameter: 44px
- Max diameter: 56px

Compact Core Rule:

- When Core Zone radius is 120px, Rank 1-5 must use compact core sizing.
- Core nodes must remain visually important, but must not cover the APL center wordmark.
- Do not increase Core node size unless Core radius is also increased.

## Radar Node Visual Hierarchy v2.4

Current ranking hierarchy must be expressed by three things at once:

1. Node size
2. Typography
3. Spacing / radar position

Do not rely on circle size alone.

Typography Scaling:

| Rank Group | Ticker | Momentum | Rank |
|---|---:|---:|---:|
| Rank 1-5 | 26px | 16px | 18px |
| Rank 6-15 | 22px | 14px | 15px |
| Rank 16-30 | 18px | 12px | 13px |

Rules:

- Text size must scale together with node size.
- Top 5 should be immediately recognizable from a distance.
- Never use the same font size for every node.
- The radar must emphasize hierarchy, not symmetry.
- APL Deep-Scan is a ranking visualization, not a decorative radar.

## Left Legend Component v1.3

Radar Legend must be visual, not plain text.

Radar Legend panel:

- X: 24
- Y: 700
- W: 312
- H: 170

Rows:

1. Top 5 Leaders (Locked)
   - icon: filled cyan radar dot with glow
2. Watch Zone (Rank 6-15)
   - icon: cyan hollow circle
3. Observation Zone (Rank 16-30)
   - icon: gray hollow circle

## Radar Legend Mini Diagram v1.7

Radar Legend should explain the three-layer structure visually.

Required visual:

- mini radar diagram with three concentric rings
- center dot
- subtle crosshair

Labels:

```text
◎ Core Zone
   Rank 1-5 / priority

◉ Watch Zone
   Rank 6-15 / monitor

○ Observation
   Rank 16-30 / tracking
```

Purpose:

Let first-time viewers understand that the dashboard is a three-layer research priority radar.

Buyability Score panel:

- X: 24
- Y: 850
- W: 312
- H: 185

Rows:

1. 5-star (8-10): cyan stars, label Strong Buyability
2. 4-star (6-7): green stars, label Good Opportunity
3. 3-star (4-5): blue/orange stars, label Neutral
4. 2-star (2-3): orange stars, label Wait & Observe
5. 1-star (0-1): red stars, label Too Extended

Locked Remark bar:

- X: 24
- Y: 1040
- W: 312
- H: 34
- icon: cyan lock
- text: `LOCKED: 符合 APL 研究標準 (Buyability >= 8)`

## Stock Node Halo Rules v1.3

Every stock node uses Buyability to control halo color and glow intensity.

- 5-star: cyan strong halo, visible from distance
- 4-star: green medium-strong halo
- 3-star: blue medium halo
- 2-star: orange weak halo
- 1-star: red border only, no halo

Halo must sit outside the sector border. Sector color still controls the main node border, while Buyability controls the glow.

## Stock Node Halo Rules v1.4

Buyability must be readable directly from the node halo without checking the legend.

5-star:

- double glow
- outer halo radius: 30px
- inner halo radius: 16px
- strongest cyan glow

4-star:

- single glow
- halo radius: 22px
- green glow

3-star:

- normal glow
- halo radius: 12px
- blue glow

2-star:

- weak glow
- halo radius: 6px
- orange glow

1-star:

- no halo
- red ring only

Leader Lock v1.4:

- icon size: 12px
- color: APL Cyan
- opacity: 65%
- glow: disabled
- placed outside node bottom-right

## Stock Node Glow Intensity Rules v1.5

Glow intensity must be visually different by Buyability category.

The difference must be obvious even without reading the legend.

5-star:

- strongest glow
- double halo
- strong blur filter
- high opacity
- should be visible immediately at thumbnail size

4-star:

- bright glow
- single halo
- medium blur filter
- medium opacity

3-star:

- normal glow
- thin halo only
- low opacity

2-star:

- weak glow
- minimal halo
- very low opacity

1-star:

- no glow
- red ring only

Renderer must not make all star categories visually similar.

## Dense Leader Lock Protection v1.6

When more than 15 stocks meet 5-star / Leader Lock conditions, the renderer must reduce outer halo radius and opacity.

Purpose:

- preserve readability;
- avoid cyan overexposure;
- keep 5-star nodes clearly stronger than other categories without covering nearby nodes.

This is a density-control rule, not a redesign.

## Leader Lock Glow Discipline v1.9

Purpose:

Prevent Leader Lock nodes from becoming overexposed and visually dominating the radar.

Leader Lock must use three layers only:

1. Main Buyability ring
2. Small outer glow
3. Subtle pulse ring

Do not use:

- stacked multi-glow halos;
- large filled cyan halos;
- white inner rings;
- more than three glow/ring layers for the same node.

Glow Area Rule:

- Leader Lock glow should extend approximately 1.4x to 1.6x the node radius.
- It must not extend beyond 1.6x the node radius.
- In dense Leader Lock conditions, reduce glow opacity and radius.

Core Zone Focus:

- Rank 1-5 may receive an additional subtle Core Focus ring.
- Core Focus ring must be low opacity and must not replace sector border.
- Outer zones must use reduced glow so the Core Zone remains the visual focus.

## Leader Lock Icon Discipline v2.0

Purpose:

Leader Lock icon is a secondary status marker, not the primary visual signal.

Rules:

- Icon opacity: 65%.
- Icon size must be 15% smaller than v1.9.
- Icon must not use glow filter.
- Icon must remain APL Cyan but visually quieter than stock ticker text.
- Icon must never compete with node ticker, sector border, or Buyability halo.

## Stock Node Semantic Color Separation v1.8

Purpose:

Prevent stock nodes from mixing multiple visual meanings.

Rules:

- Sector controls the main stock node border only.
- Buyability controls glow, halo, and soft outer light only.
- Do not use Buyability color as a second node border.
- Do not add a white inner ring around stock nodes.
- Do not use double-colored borders.
- Leader Lock icon remains APL Cyan and appears outside the node only when Buyability >= 8.

Visual Meaning:

| Visual Layer | Meaning |
|---|---|
| Main node border | Sector / industry |
| Outer glow / halo | Buyability |
| Node size | Momentum Score |
| Radar position | Composite Rank |
| Lock icon | High Buyability / Leader Lock |

## Stock Node Sector Border Palette v2.1

Purpose:

Keep the radar visually clean by limiting sector border colors to the five most important sectors in the current rendered Momentum Leaders list.

Rules:

- Calculate the Top 5 sectors from the rendered Momentum Leaders.
- Only these Top 5 sectors may use their official sector colors as stock node borders.
- Any stock outside the Top 5 sectors must use the Others gray border.
- Do not create extra border colors for smaller sectors.
- Sector Distribution on the right panel remains Top 5 only.
- The node border palette and right-side Sector Distribution must always refer to the same Top 5 sectors.

Visual Meaning:

```text
Top 5 Sector  -> official sector color border
Other Sector  -> Others gray border
Glow          -> Buyability
Node size     -> Momentum Score
```

## Dynamic Momentum Leaders Count v2.0

Purpose:

Prevent the dashboard from hard-filling a fixed TOP30 list when fewer stocks qualify as Momentum Leaders.

Rules:

- Momentum Leaders count is dynamic.
- Dashboard maximum capacity remains 30 nodes.
- Right-side dashboard total must display the actual rendered leader count.
- Buyability distribution percentages must use the actual rendered leader count as denominator.
- Sector distribution must be calculated only from the rendered Momentum Leaders.
- Do not hardcode `30 TOTAL` unless exactly 30 stocks qualify and are rendered.
- Avoid wording such as `TOP 30 Overview` when the rendered count is dynamic.

Recommended dashboard label:

```text
Momentum Leaders 領導股
Dynamic Leaders Overview
```

## Today's Scan Component v2.1

Purpose:

Show the current weekly scan result as a data card, not a process explanation.

Do not display step-by-step workflow text such as:

```text
01 Scan Universe
02 Filter Momentum
03 Rank Leaders
04 Leader Lock
```

Required Layout:

```text
TODAY'S SCAN
本週掃描結果

股票池                 {Universe Count}
符合條件               {Qualified Count}
Momentum Leaders       {Rendered Leader Count}
Leader Lock            {Leader Lock Count}
```

Rules:

- `股票池` is the full scanned market universe.
- `符合條件` is the number of stocks that pass the APL screener before final Momentum Leaders ranking.
- `Momentum Leaders` uses the actual rendered leader count.
- `Leader Lock` uses the actual count of rendered leaders with Buyability >= 8.
- Numbers must be right-aligned.
- Labels must be left-aligned.
- Use APL Cyan for values.
- Use neutral gray or white for labels.
- This component must remain a compact dashboard data card.

## Left Legend Component v2.2

Purpose:

Make the radar legend function like a dashboard control key, not a text note.

Radar Legend:

- The mini radar diagram must be visually larger than plain text bullets.
- Mini radar size should be 25-35% larger than v1.7.
- Use three clearly separated rings:
  - Core Zone: APL Cyan.
  - Watch Zone: Blue.
  - Observation Zone: Gray.
- Each zone label must be bilingual:

```text
◎ Core Zone
  核心區
  Rank 1-5

◉ Watch Zone
  觀察區
  Rank 6-15

○ Observation
  追蹤區
  Rank 16-30
```

Do not use secondary descriptions such as `priority`, `monitor`, or `tracking`.

Visual Language Note:

The bottom of the Radar Legend must explain the three visual encodings:

```text
Node Size   Momentum Score
Glow        Buyability
Border      Sector
```

Buyability Score Legend:

- Use glow circles, not plain solid dots.
- Use short labels only:

```text
★★★★★   8-10   Strong Buy
★★★★☆   6-7    Good
★★★☆☆   4-5    Neutral
★★☆☆☆   2-3    Watch
★☆☆☆☆   0-1    Extended
```

Typography:

- Star column left-aligned.
- Range column right-aligned.
- Description column short and low contrast.

Leader Lock Badge:

- Display as a compact status badge.
- Text:

```text
Leader Lock
Buyability >= 8
```

- Do not display long sentence descriptions in the badge.
