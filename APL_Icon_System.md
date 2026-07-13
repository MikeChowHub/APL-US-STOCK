# APL Icon System

> Version: v1.0  
> Purpose: 固定 Deep-Scan Dashboard 所有圖示用途與樣式。

## 1. Icon Style

Icons must follow:

- Line icon;
- Stroke 2px;
- No filled cartoon icons;
- No emoji as primary icon;
- Color from design tokens;
- Must sit inside HUD system.

## 2. Approved Icons

| Icon Name | Meaning | Color |
|---|---|---|
| Scan | 市場掃描 | APL Cyan |
| Capital Flow | 資金流向 | APL Cyan |
| Momentum | 動能 | Electric Blue |
| Radar Lock | 鎖定目標 | APL Cyan |
| Leader | 領導股 | APL Cyan |
| Chart | 圖表 | Electric Blue |
| Signal | 訊號 | Bullish Green |
| Search | 搜尋 | APL Cyan |
| Wave | 波動 | APL Cyan |
| Database | 數據庫 | Text Gray |
| Alert | 警示 | Alert Orange |
| Risk | 風險 | Bearish Red |

## 3. Leader Lock

Leader Lock is a Deep-Scan brand element.

Usage:

```text
If Buyability >= 8:
  show LOCK label or lock icon
  apply cyan glow
```

Lock icon:

| Property | Value |
|---|---:|
| Size | 18px |
| Stroke | 2px |
| Color | APL Cyan |
| Glow | 8px |

## 4. Sector Icons

| Sector | Icon |
|---|---|
| AI | circuit / chip neural node |
| Semiconductor | microchip |
| Healthcare | heart / medical cross |
| Bio | DNA helix |
| Networking | signal / network waves |
| Industrial | factory |
| Consumer | cart / bag |
| Software | cloud / code |
| Others | four-dot grid |

Sector icons are optional in compact layouts but required in full 1920×1080 Dashboard.

## 5. Prohibited Icon Usage

Do not use:

- colorful emoji as main UI element;
- 3D clipart;
- non-brand cartoon elements;
- inconsistent icon stroke weight;
- icons without meaning.

