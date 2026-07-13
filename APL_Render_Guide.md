# APL Deep-Scan Render Guide

> Version: v1.0  
> Purpose: 定義每週如何從 CSV Render 出固定 Dashboard。這是 Dashboard Render，不是 AI 插畫。

## 1. Render Instruction

Standard prompt:

```text
請完全依照：

APL_DeepScan_Design_System.md
APL_Color_System.md
APL_Radar_Layout.md
APL_Component_System.md
APL_Icon_System.md
APL_Data_Mapping.md
APL_Render_Guide.md

不要自行更改 Layout。
不要自行更改配色。
不要自行更改字體。
不要自行增加元素。

根據 APL_Top30.csv Render 一張 1920×1080 SVG Dashboard。

除了股票資料、日期、統計數字外，
所有 Layout、Icon、Glow、位置、字體、比例、顏色，
全部不得更改。
```

## 2. Render Pipeline

```text
CSV
 ↓
Normalize Fields
 ↓
Map Rank to Radar Position
 ↓
Map Momentum to Node Size
 ↓
Map Buyability to Glow / Stars / Lock
 ↓
Map Sector to Color
 ↓
Generate Dashboard Stats
 ↓
Render SVG
 ↓
Export PNG if needed
```

## 3. Output Format

Primary output:

```text
SVG
```

Secondary output:

```text
PNG export from SVG
```

Never use raster-only design as the source of truth.

## 4. File Naming

```text
APL_DeepScan_Radar_Dashboard_Top30_[YYYY-MM-DD]_1920x1080.svg
APL_DeepScan_Radar_Dashboard_Top30_[YYYY-MM-DD]_1920x1080.png
APL_DeepScan_Radar_Social_Top30_[YYYY-MM-DD]_1080x1350.svg
APL_DeepScan_Radar_Social_Top30_[YYYY-MM-DD]_1080x1350.png
```

## 5. Weekly Update Workflow

1. User uploads new APL ranking CSV.
2. Validate required fields.
3. Calculate APL Composite Score.
4. Calculate current universe average Composite Score.
5. Keep only stocks with Composite Score above the universe average.
6. Render up to 30 highest-qualifying Momentum Leaders.
7. Normalize Sector labels.
4. Calculate Dashboard summary.
5. Render SVG using fixed layout.
6. Export PNG.
7. Do visual QA.
8. Do not redesign unless user explicitly updates the spec.

## 6. QA Checklist

Before final delivery:

- Logo exists and uses official file;
- Canvas size is correct;
- Left / Center / Right layout ratio unchanged;
- Radar has 6 rings;
- Sweep angle is 35°;
- Rank 1–30 positions follow spec;
- Top 5 are largest;
- Buyability glow follows spec;
- Sector colors follow spec;
- Dashboard summary is generated from CSV;
- Ticker does not wrap;
- Text has at least 10–15px padding;
- SVG opens correctly;
- PNG export matches SVG.

## 7. Prohibited Render Behavior

Do not:

- ask AI image model to reinterpret the design;
- regenerate visual style each week;
- move nodes manually;
- invent extra cards;
- create new color palette;
- change typography;
- produce only PNG without SVG source;
- use screenshots as source of truth.

## 8. Approved Render Outputs

| Output | Required |
|---|---|
| SVG Dashboard | Yes |
| PNG Dashboard | Optional but recommended |
| Render log | Recommended |
| Data validation log | Recommended |

## 9. Versioning

If design changes are approved:

```text
APL Deep-Scan Design System v1.1
```

Do not silently change rules in production renders.
