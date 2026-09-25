# APL Deep-Scan Social Card Layout

> Version: v1.0  
> Purpose: Fixed 4:5 social media layout for APL Deep-Scan Momentum Leaders.

## 1. Naming

This layout must be called:

```text
APL Deep-Scan Social Card
```

Do not call this layout Dashboard.

## 2. Canvas

```text
Width: 1080
Height: 1350
Ratio: 4:5
Format: SVG
```

This is not a resized dashboard thumbnail.  
It is a separate fixed social-card layout.

## 3. Vertical Layout Ratio

```text
Logo / Brand Area        15-20%
Radar Hero Area          55-60%
Statistics Area          18-22%
Deep-Scan Insight        disabled unless explicitly requested
Footer                   minimal
```

## 4. Visual Priority

```text
APL Logo                 ★★★★★
Radar                    ★★★★★
Top 5 Leaders            ★★★★☆
Hero Data                ★★★★
Sector Distribution      ★★★
Buyability Distribution  ★★★
Footer                   ★
```

## 5. Required Sections

### Logo Area

- Large APL Deep-Scan logo.
- Logo position: top-left.
- Logo scale: approximately 70% of the first Social Card version.
- Production date appears at top-right in `DD/MM` format.
- Date typography should visually balance the logo area.
- Recommended date style: JetBrains Mono, white, bold, approximately 42px.
- No extra title repetition if the logo already contains APL / 美股深海雷達 / Deep-Scan.

### Radar Hero

- Radar must be the main visual element.
- Radar should occupy the largest single area of the card.
- Top 5 nodes must be visually dominant.
- Rank 16-30 may be simplified to ticker-only.

### Hero Data

Show four large figures:

```text
Universe / 股票池
Qualified / 符合條件
Momentum Leaders / 領導股
Leader Lock / 核心鎖定
```

### Buyability Distribution

- Donut chart retained.
- Use the same expression logic as Dashboard:
  - donut on the left;
  - five rating rows on the right;
  - each row includes Chinese label, range, count / percentage, and a short horizontal bar.
- Mobile readability requirement:
  - section title: approximately 22px;
  - Chinese subtitle: approximately 14px;
  - rating row text: approximately 13-14px;
  - bar height: approximately 9px;
  - donut total number: approximately 32px.
- Data values must be white.
- Color may be used for donut segments and labels.

### Sector Distribution

- Show Top 5 sectors only.
- Horizontal bar layout.
- Separate label, bar, and value columns clearly.
- Long sector names must not overlap bars or values.
- Mobile readability requirement:
  - section title: approximately 21px;
  - Chinese subtitle: approximately 14px;
  - English sector label: approximately 14px;
  - Chinese sector label: approximately 12px;
  - value text: approximately 14px;
  - bar height: approximately 12px.
- Data values and percentages must be white.

### Deep-Scan Insight

- Disabled by default.
- Do not render the bottom Insight bar unless explicitly requested.
- If enabled in a future version, use one sentence only and no paragraph.

### Footer

Only show:

```text
Week XX
YYYY-MM-DD
APL Deep-Scan
```

## 6. Color Rules

- Data values: white `#FFFFFF`.
- Stock tickers: white `#FFFFFF`.
- Percentages: white `#FFFFFF`.
- Sector colors may be used for labels, bars, and node borders.
- Buyability colors may be used for glow and donut segments.

## 7. Relationship With Dashboard

The Social Card shares:

- data mapping;
- ranking formula;
- Buyability rules;
- sector color system;
- Deep-Scan brand system.

The Social Card does not share:

- 1920×1080 canvas;
- left / center / right dashboard layout;
- terminal footer layout;
- dense right-side dashboard panel.
