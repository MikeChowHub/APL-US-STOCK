# APL Radar Layout Specification

> Version: v1.1  
> Canvas: 1920×1080  
> Output: SVG  
> Rule: Layout is fixed. Data changes only through CSV.

## 1. Master Canvas

```text
Width: 1920
Height: 1080
Format: SVG
Coordinate: 0,0 at top-left
```

## 2. Main Layout Ratio

| Region | Width | X Range | Role |
|---|---:|---|---|
| Left Panel | 20% | 0–384 | Brand / Mission / Legend |
| Center Radar | 55% | 384–1440 | Main visual focus |
| Right Dashboard | 25% | 1440–1920 | Metrics / Distribution |

Visual target:

```text
┌────────────────────┬────────────────────────────────────┬────────────────────────┐
│ Left Panel          │ Center Radar                       │ Right Dashboard        │
│ 20%                 │ 55%                                │ 25%                    │
│                     │                                    │                        │
│ Logo                │ 6-ring radar                       │ Dashboard Header       │
│ Title               │ sweep beam                         │ Buyability Donut       │
│ Status              │ Top 30 stock nodes                 │ Sector Bars            │
│ Mission             │ APL core                           │ Market Summary         │
│ Legend              │ Leader Lock                        │                        │
│ Buyability          │ Deep-Scan Insight                  │                        │
└────────────────────┴────────────────────────────────────┴────────────────────────┘
```

## 3. Left Panel Layout

| Component | X | Y | W | H | Fixed |
|---|---:|---:|---:|---:|---|
| Brand Logo | 10 | 10 | 520 | 205 | Yes |
| Main Title | Removed | Removed | Removed | Removed | Yes |
| Subtitle | Removed | Removed | Removed | Removed | Yes |
| Divider | Removed | Removed | Removed | Removed | Yes |
| Scan Status | 24 | 220 | auto | 20 | Yes |
| Last Update Week | 24 | 320 | auto | 18 | Data |
| Last Update Date | 24 | 344 | auto | 18 | Data |
| Data Source | 24 | 368 | auto | 18 | Data |
| Deep-Scan Mission | 24 | 315 | 312 | 180 | Yes |
| Radar Legend | 24 | 690 | 312 | 150 | Yes |
| Buyability Score | 24 | 840 | 312 | 190 | Yes |
| Locked Remark | 24 | 1035 | 312 | 34 | Optional |

Left Panel text:

```text
SCAN STATUS • ACTIVE
Last Update: Week XX
[YYYY-MM-DD]
Data Source: APL Deep-Scan System
```

## Left Brand Entry v2.2

The enlarged APL Deep-Scan logo is the only brand/title entry in the left panel.

Logo:

- X: 10
- Y: 10
- W: 520
- H: 205
- Asset: clean no-frame transparent PNG

Do not display separate repeated title text under the logo.

Do not use a framed logo card in the renderer.

The top-left logo must be extracted as a no-frame brand mark so it behaves like a product logo, not a banner pasted into the dashboard.

Do not display status/date/source text directly under the logo.

The logo itself is the only brand description in the top-left area.

Remove:

```text
資金流向雷達圖
Momentum Leaders Radar
```

Reason:

The official logo already contains:

- APL
- 美股深海雷達
- Deep-Scan

Duplicating the same meaning below the logo weakens the product UI hierarchy.

## 4. Center Radar Layout

| Property | Value |
|---|---:|
| Center X | 910 |
| Center Y | 540 |
| Outer Radius | 430 |
| Rings | 6 |
| Ring Stroke | 1px |
| Radial Lines | every 30° |
| Degree Labels | every 30° |
| Sweep Angle | 35° |
| Sweep Width | 14° |

## 5. Radar Ring Meaning

| Ring | Radius | Meaning |
|---|---:|---|
| R1 | 90 | APL Core |
| R2 | 120 | Core Zone |
| R3 | 220 | Watch Zone |
| R4 | 320 | Observation Zone |
| R5 | 380 | Outer Observation Buffer |
| R6 | 430 | Outer Scan Boundary |

## 6. Center Core

Fixed center text:

```text
LEADER LOCK
APL
Deep-Scan
LIVE SCAN
```

Core position:

| Element | X | Y |
|---|---:|---:|
| LEADER LOCK | 910 | 482 |
| APL | 910 | 548 |
| Deep-Scan | 910 | 584 |
| LIVE SCAN | 910 | 610 |

## 7. Radar Zone Labels

| Label | X | Y | Text |
|---|---:|---:|---|
| Watch Zone | 612 | 174 | `WATCH ZONE` / `觀察區` |
| Watch Rank | 612 | 193 | `RANK 6–15` |
| Observation Zone | 1237 | 174 | `OBSERVATION ZONE` / `潛力追蹤區` |
| Observation Rank | 1237 | 193 | `RANK 16–30` |

Zone Label Safe Area:

- Watch label box: x 535-689, y 150-198.
- Observation label box: x 1150-1324, y 150-198.
- Zone labels must never be placed on radar node rings.
- Zone labels must not overlap Core, Watch, or Observation stock nodes.
- Use low-opacity pill background to preserve readability.

## 8. Fixed Rank Position Map

No AI layout allowed. Rank maps to fixed polar coordinate.

Angle definition:

```text
0° = top
90° = right
180° = bottom
270° = left
```

### Core Zone: Rank 1–5

| Rank | Angle | Radius | Node Size |
|---:|---:|---:|---:|
| 1 | 0° | 135 | Large |
| 2 | 210° | 190 | Large |
| 3 | 150° | 190 | Large |
| 4 | 270° | 180 | Large |
| 5 | 90° | 180 | Large |

Visual structure:

```text
          Rank 1

Rank 4              Rank 5

     Rank 2    Rank 3

          APL
```

### Watch Zone: Rank 6–15

| Rank | Angle | Radius |
|---:|---:|---:|
| 6 | 300° | 305 |
| 7 | 320° | 305 |
| 8 | 0° | 305 |
| 9 | 40° | 305 |
| 10 | 70° | 305 |
| 11 | 105° | 305 |
| 12 | 125° | 305 |
| 13 | 255° | 305 |
| 14 | 180° | 305 |
| 15 | 230° | 305 |

### Observation Zone: Rank 16–30

| Rank | Angle | Radius |
|---:|---:|---:|
| 16 | 290° | 405 |
| 17 | 310° | 405 |
| 18 | 330° | 405 |
| 19 | 0° | 405 |
| 20 | 25° | 405 |
| 21 | 50° | 405 |
| 22 | 75° | 405 |
| 23 | 100° | 405 |
| 24 | 125° | 405 |
| 25 | 145° | 405 |
| 26 | 165° | 405 |
| 27 | 185° | 405 |
| 28 | 205° | 405 |
| 29 | 225° | 405 |
| 30 | 250° | 405 |

## 9. Right Dashboard Layout

| Component | X | Y | W | H |
|---|---:|---:|---:|---:|
| Dashboard Frame | 1460 | 30 | 420 | 1010 |
| Header | 1460 | 30 | 420 | 70 |
| Momentum Overview | 1460 | 100 | 420 | 100 |
| Buyability Distribution | 1460 | 200 | 420 | 230 |
| Sector Distribution | 1460 | 430 | 420 | 260 |
| Market Scan Summary | 1460 | 690 | 420 | 350 |

## 10. Bottom Insight

| Component | X | Y | W | H |
|---|---:|---:|---:|---:|
| Deep-Scan Insight | 390 | 980 | 990 | 70 |
| Footer Text | 650 | 1060 | 600 | 20 |

## 11. Social Layout

Social Radar Card:

```text
Canvas: 1080×1350
Center: 540, 610
Radius: 430
Header: y 30–190
Radar: y 210–1000
Bottom Panels: y 1030–1260
Footer: y 1300
```

Social version must preserve:

- same rank order;
- same color system;
- same Buyability glow;
- same core / watch / observation zones.

## Radar Layout Rules v1.2

Canvas: 1920 x 1080 only.

Main radar center:

- cx: 920
- cy: 540
- radius: 430

Reserved safe zones:

- Left panel: x 24-330
- Radar zone: x 390-1380
- Right dashboard: x 1450-1865

No stock node may enter:

- x < 380
- x > 1370
- y < 110
- y > 920

## APL Deep-Scan Radar Layers

The radar is divided into three fixed analysis zones.

These zones represent the current observation priority, not future return prediction.

Stocks are positioned by Rank only.

### 1. Core Zone

Layer:

Core Zone

Rank:

1-5

Radius:

120px

Purpose:

Highest priority research targets.

Meaning:

These are the strongest Momentum Leaders currently satisfying most APL quantitative conditions.

Characteristics:

- Highest Momentum Score
- Highest observation priority
- Reviewed first
- Largest node size

Visual:

- Largest nodes
- Strongest glow
- Leader Lock available
- Closest to APL Core

中文：

核心區（Core Zone）

放置 Rank 1-5。

代表目前最值得優先研究的 Momentum Leaders，是整個雷達的核心觀察區。

### 2. Watch Zone

Layer:

Watch Zone

Rank:

6-15

Radius:

220px

Purpose:

Potential leaders under observation.

Meaning:

Strong companies that are approaching Core Zone quality.

Characteristics:

- Good Momentum
- Need further confirmation
- May enter Core Zone
- Medium node size

Visual:

- Medium glow
- Medium node

中文：

監察區（Watch Zone）

放置 Rank 6-15。

已具備不錯的動能，但仍需等待更多確認。

### 3. Observation Zone

Layer:

Observation Zone

Rank:

16-30

Radius:

320px

Purpose:

Early-stage opportunities.

Meaning:

Stocks that passed the quantitative filter but currently rank below Watch Zone.

Characteristics:

- Worth monitoring
- Lower priority
- Smaller node size

Visual:

- Small nodes
- Reduced glow

## Dynamic Momentum Leaders Count v2.0

TOP30 is a dashboard capacity limit, not fixed membership.

Momentum Leaders are selected by the current APL Composite Score rule:

```text
APL Composite Score = Momentum Score + (Buyability Score x 2)
```

Eligibility:

- Calculate the current universe average Composite Score.
- Only stocks with Composite Score above the current universe average qualify as Momentum Leaders.
- Render up to 30 highest-qualifying leaders.
- If fewer than 30 qualify, the radar must display fewer than 30 nodes.

Radar Layer Assignment:

- Rank 1-5: Core Zone.
- Rank 6-15: Watch Zone.
- Rank 16-30: Observation Zone.
- If fewer stocks qualify, do not fill empty positions.
- Stock position is based on dynamic Composite Rank, not original CSV Rank.

中文：

觀察區（Observation Zone）

放置 Rank 16-30。

已通過 APL 篩選，但目前優先級較低，作為後續追蹤名單。

Top 5 placement:

- Rank 1: center upper, angle 0, radius 120
- Rank 2: angle 216, radius 120
- Rank 3: angle 144, radius 120
- Rank 4: angle 288, radius 120
- Rank 5: angle 72, radius 120

Rank 6-15:

- radius: 220
- evenly distributed
- avoid angle 0 because it conflicts with top label

Rank 16-30:

- radius: 320
- evenly distributed
- minimum node distance: 88px

## Radar Layout Distribution v2.4

The radar must emphasize hierarchy, not symmetry.

APL Deep-Scan is a ranking visualization, not a decorative radar.

Node size, typography, spacing and position must all reinforce ranking importance.

The layout should maximize radar coverage and minimize visual clustering around the center.

Rules:

- Use the full radar radius.
- Increase spacing between nodes.
- Push outer-ring nodes closer to the outer radar rings.
- Maximize usage of all four quadrants.
- Avoid clustering around the APL core.
- Keep at least one node diameter spacing between adjacent nodes.

Ring Distribution:

```text
Core Zone          Radius 80-150
Watch Zone         Radius 170-280
Observation Zone   Radius 300-430
```

Renderer may use 20-30px radial variation within each layer.

Do not place all nodes on a perfectly identical circle if it causes visual clustering.

Collision Rules:

- No node overlap.
- Minimum spacing: 1.15 x larger node diameter.
- If collision occurs:
  1. Rotate node around ring.
  2. Move radially +/-20px.
  3. Retry until no overlap.

Visual Priority:

```text
Top 5
↓
Rank 6-15
↓
Rank 16-30
```

First-time viewers must immediately recognize Top 5 as the highest-priority group.

### Fixed Rank Angle Map v1.2

Use this exact angle map for Dashboard Render. Do not auto-recalculate positions unless the layout spec is updated.

| Rank | Angle | Radius |
|---:|---:|---:|
| 1 | 0 | 120 |
| 2 | 215 | 180 |
| 3 | 145 | 180 |
| 4 | 285 | 180 |
| 5 | 75 | 180 |
| 6 | 210 | 270 |
| 7 | 240 | 270 |
| 8 | 270 | 270 |
| 9 | 300 | 270 |
| 10 | 330 | 270 |
| 11 | 30 | 270 |
| 12 | 60 | 270 |
| 13 | 90 | 270 |
| 14 | 120 | 270 |
| 15 | 150 | 270 |
| 16 | 300 | 390 |
| 17 | 320 | 390 |
| 18 | 340 | 390 |
| 19 | 20 | 390 |
| 20 | 40 | 390 |
| 21 | 60 | 390 |
| 22 | 80 | 390 |
| 23 | 100 | 390 |
| 24 | 120 | 390 |
| 25 | 140 | 390 |
| 26 | 153 | 390 |
| 27 | 207 | 390 |
| 28 | 220 | 390 |
| 29 | 240 | 390 |
| 30 | 260 | 390 |

Bottom insight v1.2:

- X: 390
- Y: 930
- W: 990
- H: 70
- Footer remains at y 1060.

## Radar Background Rules v1.4

The radar background must stay clean and analytical.

Allowed background elements:

- radar rings
- radial grid lines
- degree labels
- sweep beam
- subtle HUD particles
- subtle circular scan texture
- subtle data points
- faint world-coordinate lines
- weak noise texture

Not allowed:

- arbitrary diagonal lines
- stock-to-stock connector lines
- decorative lines not tied to radar geometry
- sector network lines unless explicitly required by the data mapping spec

Background depth rules:

- Data points opacity: 3%–5%.
- World-coordinate lines opacity: 2.5%–3.5%.
- Noise texture opacity: 3%–5%.
- Background effects must never compete with stock nodes, text, panels, radar rings, or sweep beam.
- Background effects must remain deterministic and generated by renderer code.
- Do not use random image backgrounds.

Reason:

Unrelated lines reduce readability and make the dashboard feel less like a professional radar interface.

## Radar Geometry Rules v1.4

The radar must clearly show three circular priority layers.

All stock nodes must use a fixed polar coordinate system.

Each node position is generated from:

```text
radar center + angle + radius
```

No stock node may be manually positioned with arbitrary x/y values.

This keeps all three radar layers evenly distributed and visually stable across weekly renders.

Top 5 Core Zone:

- Rank 1-5 must form a compact pentagon around the APL core.
- The visual center must remain balanced around APL, not shifted upward.
- Rank 1-5 radius: 120px
- Rank 1 angle: 0
- Rank 2 angle: 216
- Rank 3 angle: 144
- Rank 4 angle: 288
- Rank 5 angle: 72

Watch Zone:

- Rank 6-15 must form one complete circular ring.
- Radius: 220px
- 10 stocks must be evenly distributed.
- Fixed step: 36 degrees.
- Starting angle: 18 degrees.

Observation Zone:

- Rank 16-30 must form one complete outer circular ring.
- Radius: 320px
- 15 stocks must be evenly distributed.
- Fixed step: 24 degrees.
- Starting angle: 12 degrees.

Leader Lock:

- Lock icon size: 16-18px
- Lock icon must have cyan glow
- Lock icon must sit outside the node, bottom-right

Radar Beam:

- Beam width should be approximately 20 degrees.
- Beam must not cover too many stock nodes.
- Main beam opacity: 65%.
- Focused beam wedge opacity: 18%.
- Tail opacity should step down from 13% to 9% to 5.5%.
- Tail should be wider and softer than the main beam.
- Beam should read as radar sweep, not a spotlight.

APL Core:

- APL core typography should be visually dominant.
- APL wordmark may be approximately 10% larger than v1.3.

### Layer Separation Rules v1.5

Fixed radar layer radius:

| Layer | Rank | Radius |
|---|---:|---:|
| Core Zone | 1-5 | 120px |
| Watch Zone | 6-15 | 220px |
| Observation Zone | 16-30 | 320px |

Rules:

- Core, Watch, and Observation zones must be separated by at least 80px.
- Default separation is 100px between Core and Watch, and 100px between Watch and Observation.
- Do not place Watch Zone stocks on the Core radius.
- Do not place Observation Zone stocks on the Watch radius.
- All stocks must be positioned by fixed polar coordinates based on rank.

## Radar Zone Labels v2.5 Override

This section overrides all earlier zone-label box rules.

Zone labels are structural navigation, not buttons.

Rules:

- Remove rounded rectangle containers.
- Float labels directly above radar rings.
- Center-align labels with the radar axis.
- English title: 18px Montserrat SemiBold, APL Cyan.
- Chinese subtitle: 16px Noto Sans TC Medium, White.
- Rank: 12px JetBrains Mono, Gray, 70% opacity.
- Add one thin cyan divider below the English title.
- Zone labels must follow radar geometry instead of floating inside boxes.

Fixed labels:

| Label | X | Y | Text |
|---|---:|---:|---|
| Observation English | 920 | 144 | `OBSERVATION ZONE` |
| Observation Divider | 830-1010 | 154 | Cyan line |
| Observation Chinese | 920 | 176 | `潛力追蹤區` |
| Observation Rank | 920 | 198 | `Rank 16-30` |
| Watch English | 920 | 250 | `WATCH ZONE` |
| Watch Divider | 850-990 | 260 | Cyan line |
| Watch Chinese | 920 | 282 | `觀察區` |
| Watch Rank | 920 | 304 | `Rank 6-15` |

## Radar Spatial Usage v2.5 Override

The radar must occupy the full available canvas.

Rules:

- Nodes should expand to 90-95% of usable radar radius.
- Avoid excessive clustering around the APL core.
- Increase radial spacing between Core, Watch and Observation zones.
- Observation nodes should use the outer radar area, not remain visually centered.
- Typography scales together with node size.
- Zone labels must follow the radar geometry instead of using floating button-like boxes.

Current fixed radial usage:

```text
Core Zone          radius 155-190
Watch Zone         radius 285-315
Observation Zone   radius 392-430
```

Center core typography:

- APL wordmark: 52-60px.
- Deep-Scan: 24-26px.
- LIVE SCAN: 12px.
- Center text must not overpower Leader Lock or stock nodes.

Radar sweep:

- Sweep must read as radar movement, not a spotlight.
- Beam opacity should be reduced by approximately 20-40% versus earlier versions.
- Tail should be soft and transparent.

Node text spacing:

- Rank should sit 4px higher than earlier versions.
- Ticker should sit 2px lower than earlier versions.
- Rank and ticker must never visually touch.

## Left Panel Spacing v2.6 Override

This section overrides earlier left-panel vertical layout rules.

Purpose:

The left-side information boxes must use the same breathable text rhythm as the Sector Distribution rows.

Fixed boxes:

| Component | X | Y | W | H |
|---|---:|---:|---:|---:|
| Today's Scan | 24 | 285 | 312 | 210 |
| Radar Legend | 24 | 515 | 312 | 330 |
| Buyability Score | 24 | 860 | 312 | 150 |
| Leader Lock Badge | 24 | 1022 | 312 | 46 |

Spacing rules:

- Today's Scan row interval: 36px.
- Radar Legend mini radar diagram must be 25-35% larger than v2.5.
- Radar Legend text must sit to the right of the mini radar and must not touch it.
- Radar Legend zone label line interval: 22px.
- Radar Legend group interval: approximately 40px.
- Buyability Score panel height: 220px.
- Buyability row interval: at least 26px.
- Star / Range / Label columns must not overlap.
- Mini explanatory labels stay inside Radar Legend and must not touch the Buyability box.
- Leader Lock badge may be compact, but must remain visually separated from Buyability Score.

## Left Panel Vertical Rhythm v2.7 Override

This section overrides earlier left-panel height rules.

Purpose:

The left column uses fixed dashboard proportions. Panel height must never depend on content height.

Fixed layout:

| Panel | X | Y | W | H | Role |
|---|---:|---:|---:|---:|---|
| SCAN SUMMARY | 24 | 232 | 312 | 200 | compact scan result |
| RADAR LEGEND | 24 | 444 | 312 | 340 | primary interpretation legend |
| BUYABILITY SCORE | 24 | 796 | 312 | 210 | rating scale |
| LEADER LOCK | 24 | 1018 | 312 | 52 | status badge |

Visual ratio target:

```text
SCAN SUMMARY      approximately 18%
RADAR LEGEND      approximately 36%
BUYABILITY SCORE  approximately 34%
LEADER LOCK       approximately 12%
```

Rules:

- Every panel uses fixed height.
- Panel height never depends on content.
- Fixed inter-panel gap: 12px.
- Internal rows use fixed spacing.
- Vertical rhythm has higher priority than equal margins.
- Panels should visually fill the left column from top to bottom with consistent breathing space.
- SCAN SUMMARY should remain compact; it only shows four values.
- SCAN SUMMARY title must be:
  - English: `SCAN SUMMARY`
  - Chinese subtitle: `掃描摘要`
- SCAN SUMMARY row labels:
  - `Universe` / `股票池`
  - `Qualified Stocks` / `符合條件`
  - `Momentum Leaders` / `領導股`
  - `Leader Lock` / `核心鎖定`
- RADAR LEGEND should have enough space for a larger mini radar and three grouped labels.
- RADAR LEGEND text column begins at x=180; mini radar right edge must stay at least 12px away from the text column.
- BUYABILITY SCORE row spacing should be slightly expanded; current row interval is 29px.
- BUYABILITY SCORE should not compress stars, ranges, or labels.
- LEADER LOCK should read as a status badge, not a website footer.

## APL Deep-Scan Dashboard v2.6 Layout Refinement

This is a layout refinement task, not a redesign task.

Allowed changes:

- spacing;
- fixed positions;
- typography hierarchy;
- panel height;
- node distribution;
- safe areas.

Not allowed:

- change Logo;
- change color system;
- change APL Composite Score formula;
- change CSV fields;
- change 1920x1080 layout;
- change overall visual style.

Buyability Score:

- Panel height: 220px.
- Row height: at least 26px.
- Star / Range / Label columns must be separated.
- Leader Lock badge must not press into Buyability Score.

Radar Legend:

- Mini radar diagram must be enlarged by 25-35%.
- Core / Watch / Observation text groups align to the right of the mini radar.
- Text must not touch the mini radar.
- Keep bottom encoding note:
  - Size -> Momentum
  - Glow -> Buyability
  - Border -> Sector

Zone Labels:

- Zone labels must use safe areas.
- Zone labels may move if they conflict with node, glow, lock icon, or beam.
- Do not move stock rank mapping to solve label overlap.
- Remove button-like rounded rectangles.
- Use floating HUD labels.

## Radar Node Typography v2.7 Override

This is a layout refinement rule, not a redesign rule.

Purpose:

Node typography must scale with node hierarchy. The dashboard must never render all stock nodes with the same font sizes.

Fixed typography:

| Rank Group | Ticker | Momentum Score | Rank |
|---|---:|---:|---:|
| Rank 1-5 | 26px | 16px | 18px |
| Rank 6-15 | 22px | 14px | 15px |
| Rank 16-30 | 18px | 12px | 13px |

Rules:

- Text size must scale together with node size.
- Top 5 must be recognizable from a distance.
- Rank, ticker, and momentum score must not visually touch.
- Rank sits higher than ticker to create clear vertical separation.
- Ticker remains the strongest text inside each node.
- Momentum score remains secondary.

## Zone Label Safe Area v2.7 Override

This is a layout refinement rule, not a redesign rule.

Purpose:

Zone labels must behave like HUD navigation labels and must not be covered by stock nodes.

Rules:

- Zone labels must not sit inside node paths.
- Zone labels must not use rounded rectangle containers.
- Zone labels must not look like buttons.
- Use floating text plus thin cyan divider.
- If a node overlaps a zone label, move the node radially or rotate it; do not move the label into a box.

Fixed safe areas:

| Zone Label | Safe Area |
|---|---|
| Observation Zone | x 800-1040, y 128-205 |
| Watch Zone | x 820-1020, y 232-310 |

Allowed changes:

- Adjust spacing.
- Adjust typography hierarchy.
- Adjust fixed node positions.
- Adjust node distribution.

Not allowed:

- Redesign the dashboard.
- Change the brand colors.
- Change the left / center / right panel architecture.
- Add decorative elements unrelated to radar readability.

## Observation Zone Node Simplification v2.8

Purpose:

Observation Zone represents stocks that passed the APL filter but remain lower-priority monitoring names. It is not intended for precise rank comparison.

For Rank 16-30, render only:

- Ticker;
- Sector border;
- Buyability glow;
- Leader Lock icon if Buyability >= 8.

Do not render for Rank 16-30:

- Rank number;
- Momentum Score.

Rules:

- Rank still controls radar position internally.
- Momentum Score still controls node size internally.
- The simplified visual output only reduces text density.
- Do not change ranking, scoring, CSV fields, or node placement.
- This is a readability refinement, not a redesign.

## Radar Label Cleanup v2.9

Purpose:

Reduce visual obstruction around the outer radar rings and avoid text being covered by nodes, glow, lock icons, or the sweep beam.

Rules:

- Do not render outer degree numbers around the radar perimeter.
- Keep radial grid lines.
- Do not render floating Watch Zone / Observation Zone descriptions inside the main radar.
- The left-side Radar Legend remains the only explanation for Core / Watch / Observation zones.
- If a zone explanation is needed, use the left legend or supporting text outside the radar, not text over the radar rings.

## Deep Lighting Background v3.0

Purpose:

The dashboard should feel as if the radar is operating at depth, without drawing literal deep-sea objects.

Core principle:

- Do not draw the sea.
- Do not add decorative background objects.
- Create depth through lighting, contrast, and radar geometry only.

Required layers:

1. Radial Lighting
   - Center color: #123B55
   - Mid color: #0A2233
   - Base color: #06131D
   - Corner color: #03080D

2. Cinematic Vignette
   - Corners must fall close to black.
   - Vignette focuses attention toward the radar core.

3. Multi-layer Radar Geometry
   - Use only very faint large radar circles, ellipses, and arcs.
   - Geometry opacity should remain approximately 1%-4%.

4. Depth Contrast
   - Background must visually recede.
   - Radar, panels, and stock nodes must remain visually forward.

Not allowed:

- bubbles;
- sea-current lines;
- random star/data particles;
- decorative world-coordinate lines;
- noise texture as a visible design element;
- photographic or illustrative deep-sea backgrounds.

## Deep Ocean Environment Background v3.1 Override

Purpose:

The dashboard background should feel like a radar operating inside deep water, not a flat black UI canvas.

This is an environment system, not an illustration system.

Required background layer order:

1. Deep Ocean Gradient
   - Large radial gradient.
   - Radar center is slightly brighter.
   - Corners fall toward near-black.

2. Blue Fog
   - Soft cyan / blue fog behind the radar.
   - Blur approximately 70-120px.
   - Opacity approximately 2%-5%.
   - This should feel like light passing through water, not glow around a shape.

3. Water Particles
   - Very small cyan particles only.
   - Size: 0.5px-1.5px.
   - Opacity: 2%-5%.
   - Density should be lower near the radar center and higher toward the outer field.
   - Must not look like stars.

4. Ocean Current Curves
   - Very faint curved lines.
   - Stroke width: approximately 1px.
   - Opacity: 2%-3%.
   - Curves must feel like water flow, not network lines.

5. Sonar Echo Rings
   - Broken circular rings only.
   - Use dashed / interrupted arcs.
   - Opacity: 1%-4%.
   - Rings stay behind all radar nodes and panels.

6. Noise Texture
   - Very low opacity deterministic SVG noise.
   - Opacity: approximately 1%-2%.
   - Noise adds depth but must not be visibly dominant.

7. Cinematic Vignette
   - Final background layer before foreground UI.
   - Darkens corners and focuses attention toward the radar.

Rules:

- Do not use external image backgrounds.
- Do not draw fish, seabed, waves, or literal ocean objects.
- Do not add bright star-like dots.
- Do not let any background layer compete with stock nodes, panel text, sector bars, or radar sweep.
- All environment layers must be deterministic and generated by the renderer.
