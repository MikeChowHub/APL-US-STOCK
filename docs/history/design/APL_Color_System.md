# APL Deep-Scan Color System

> Version: v1.0  
> Purpose: 固定 Deep-Scan 所有 Dashboard、Radar、Card、Header 的品牌色、產業色、Buyability 色、Glow 強度。

## 1. Brand Colors

| Token | HEX | 用途 |
|---|---|---|
| `APL_CYAN` | `#00D8FF` | 主色、雷達光、Logo 文字、Leader Lock |
| `ELECTRIC_BLUE` | `#00B8FF` | 掃描光束、次級高亮 |
| `DEEP_OCEAN` | `#06131D` | 主背景 |
| `DARK_NAVY` | `#08131F` | 面板底色 |
| `PANEL_NAVY` | `#0E2233` | Dashboard 卡片 / HUD Panel |
| `GRID_BLUE` | `#0E3146` | 背景網格、雷達細線 |
| `WHITE` | `#FFFFFF` | 主標題、Ticker、重要文字 |
| `GLASS_SILVER` | `#A8B3C2` | APL 中心字金屬玻璃底色 |
| `GLASS_WHITE` | `#FFFFFF` | APL 中心字高光 |
| `GLASS_CYAN_REFLECTION` | `#8EEBFF` | APL 中心字冷光反射 |
| `TEXT_GRAY` | `#8B93A6` | 次要文字、註腳 |
| `ALERT_ORANGE` | `#FF9D00` | 注意訊號、Rank 強調、Industrial |
| `BULLISH_GREEN` | `#00D97B` | 正向、Healthcare、★★★★ |
| `BEARISH_RED` | `#FF4E5E` | 風險、Bio、★ |

## 2. Background System

| Layer | Color | Opacity | 說明 |
|---|---|---:|---|
| Base | `DEEP_OCEAN` | 100% | 主背景 |
| Grid | `GRID_BLUE` | 25% | 40px 或 48px 網格 |
| Radar Ring | `APL_CYAN` | 15% | 雷達圓環 |
| Minor Ring | `APL_CYAN` | 8% | 補助圓環 |
| Panel Fill | `DARK_NAVY` | 78% | HUD 面板 |
| Panel Stroke | `APL_CYAN` | 55% | 面板邊框 |

## 3. Sector Colors

| Sector | Color Token | HEX |
|---|---|---|
| AI | `APL_CYAN` | `#00D8FF` |
| Semiconductor | `ELECTRIC_BLUE` | `#008BFF` |
| Healthcare | `BULLISH_GREEN` | `#00D97B` |
| Bio | `BEARISH_RED` | `#FF4E5E` |
| Networking | `NETWORK_PURPLE` | `#9A62FF` |
| Industrial | `ALERT_ORANGE` | `#FF9D00` |
| Consumer | `CONSUMER_YELLOW` | `#FFD147` |
| Software | `SOFTWARE_BLUE` | `#00B8FF` |
| Others | `TEXT_GRAY` | `#8B93A6` |

Sector color controls:

- Stock node outer border;
- Sector bar chart;
- Sector icon;
- optional supply-chain link color.

Stock node border palette rule:

- The rendered dashboard may use only the current Top 5 sector colors for stock node borders.
- Stocks from sectors outside the current Top 5 sector list must use `Others / TEXT_GRAY #8B93A6`.
- This prevents the radar from becoming visually noisy with too many border colors.
- The right-side Sector Distribution and node border colors must share the same Top 5 sector set.

## 4. Buyability Colors

| Buyability | Range | Color | Glow |
|---|---:|---|---:|
| ★★★★★ | 8–10 | `APL_CYAN` | 24px |
| ★★★★☆ | 6–7 | `BULLISH_GREEN` | 18px |
| ★★★☆☆ | 4–5 | `ELECTRIC_BLUE` | 10px |
| ★★☆☆☆ | 2–3 | `TEXT_GRAY_BLUE` `#789BB4` | 5px |
| ★☆☆☆☆ | 0–1 | `BEARISH_RED` | 0px |

Rules:

- Buyability controls glow intensity and halo color only;
- Sector controls node border color only;
- Momentum controls node size;
- Rank controls radar position.
- Do not use Buyability color as an extra node border.
- Do not use double-colored stock node borders.

## 4.1 Data Text Color Rule

All displayed data values must use white text.

Use `#FFFFFF` for:

- numeric values;
- percentages;
- stock tickers;
- counts;
- symbols shown as values.

Rules:

- Do not color data values by sector, Buyability, or performance direction.
- Semantic colors may be used for icons, bars, borders, halos, and labels.
- Data values remain white for maximum terminal-style readability.

## 5. Radar Sweep

| Property | Value |
|---|---:|
| Angle | 35° |
| Sweep Width | 14° |
| Main Opacity | 80% |
| Tail 1 Opacity | 35% |
| Tail 2 Opacity | 18% |
| Blur | 18px |
| Color | `APL_CYAN` |

Sweep must always appear as a radar scan, not a decorative diagonal line.

## 6. Alert / Lock Colors

| State | Color | Glow |
|---|---|---:|
| `LEADER_LOCK` | `APL_CYAN` | 24px |
| `WATCH` | `ELECTRIC_BLUE` | 10px |
| `CAUTION` | `ALERT_ORANGE` | 8px |
| `RISK` | `BEARISH_RED` | 6px |
