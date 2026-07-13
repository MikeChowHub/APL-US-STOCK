# APL Deep-Scan Design System

> Version: v1.1  
> Product: APL 美股深海雷達 Deep-Scan  
> Status: Dashboard UI Specification  
> Principle: This is a product UI render system, not an AI illustration prompt.

## 1. Core Rule

APL Deep-Scan 所有視覺輸出必須被視為一套固定 Dashboard UI，而不是每次重新畫一張圖。

所有圖像均由五個層級組成：

1. Layout（版面）
2. Design System（設計系統）
3. Component（元件）
4. Data（CSV）
5. Render（SVG / HTML）

Render 時只允許更新：

- 股票資料；
- 日期；
- 統計數字；
- 由 CSV 自動計算出的分佈與摘要。

不得重新設計畫面。

## 2. Visual Reference

Deep-Scan Radar Dashboard 的標準視覺參考是一個「軍事雷達 + 金融終端」介面。

視覺必須包含：

- 左側任務欄；
- 中央大型雷達；
- 右側 Dashboard；
- 底部 Deep-Scan Insight；
- 深海藍黑背景；
- 青色雷達掃描光束；
- 產業顏色節點；
- Buyability Glow；
- Leader Lock。

畫面不應像股票排行榜，而應像正在運作中的市場掃描儀表板。

## 3. Brand Positioning

APL Deep-Scan 的核心概念：

> Deep-Scan is not ranking stocks.  
> Deep-Scan renders where capital is being locked.

中文定位：

> APL 美股深海雷達 Deep-Scan 用於掃描市場資金流向、辨認 Momentum Leaders 領導股，並以固定 Dashboard UI 呈現資金正在被鎖定的位置。

## 4. Mandatory Visual Hierarchy

視覺權重必須按以下層級排列：

| Priority | Area | Visual Weight |
|---:|---|---:|
| 1 | Center Radar | 70% |
| 2 | Right Dashboard | 18% |
| 3 | Left Panel | 9% |
| 4 | Footer / Insight | 3% |

第一眼必須看到雷達，而不是表格、文字或 Dashboard。

## 5. Required Dashboard Sections

### Left Panel

固定包括：

- Official Logo；
- `資金流向雷達地圖`；
- `Momentum Leaders Radar`；
- Scan Status；
- Last Update；
- Data Source；
- Deep-Scan Mission；
- Radar Legend；
- Buyability Score；
- Locked Remark。

### Center Radar

固定包括：

- 6 rings；
- degree labels；
- radial grid lines；
- scanning sweep；
- sweep tail；
- 30 stock nodes；
- APL core；
- `LEADER LOCK`；
- `APL Deep-Scan`；
- Leader Lock nodes；
- sector color coding。

### Right Dashboard

固定包括：

- Deep-Scan Dashboard Header；
- Momentum Leaders Top 30 Overview；
- Buyability Distribution；
- Donut Chart；
- Sector Distribution；
- Market Scan Summary。

### Bottom Insight

固定包括：

- Deep-Scan Insight；
- 由 CSV 自動生成的簡短市場觀點；
- APL Deep-Scan System footer。

## 6. Forbidden Changes

Render 時不得：

- 改 Layout；
- 改比例；
- 改配色；
- 改字體；
- 改股票位置；
- 改 Radar ring 數量；
- 把 Radar 改成 Ranking Table；
- 自行增加裝飾元素；
- 自行生成 Logo；
- 更改 Sector color；
- 更改 Buyability glow；
- 移除 Leader Lock；
- 只輸出 PNG 而沒有 SVG source。

## 7. Logo System

Repository product v1.0.0 唯一允許及隨 release 提交的 production Logo：

- `outputs/APL_Deep_Scan_Brand_Logo_Renderer_Clean_2026-06-28.png`

其他 transparent、white-background、HiRes、Inline、legacy brand 或 source logo 均屬 historical／local-only assets，不包含在 v1.0.0 release，亦不可成為 production dependency。

Logo 用法：

| Placement | Usage |
|---|---|
| Left Header | Official inline logo |
| Center Radar | Text-based `APL Deep-Scan` core |
| Footer | `APL Deep-Scan System` |

不得自行重畫或替代 Logo。

## 8. Typography

| Use | Font | Fallback |
|---|---|---|
| English Title | Montserrat Bold | Segoe UI Bold |
| Chinese Title | Noto Sans TC Bold | Microsoft JhengHei UI Bold |
| Body Text | Noto Sans TC Regular | Microsoft JhengHei UI |
| Number / Ticker | JetBrains Mono | Consolas |

Rules:

- Ticker 永遠保持英文；
- Rank / Score / Date 必須用等寬字體；
- 中文使用黑體；
- 文字不可貼邊，所有 Panel 至少保留 16px padding；
- Dashboard 數字右對齊；
- Ticker 不得換行。

## 9. Standard Output Types

| Output | Size | Format | Purpose |
|---|---:|---|---|
| Radar Dashboard | 1920×1080 | SVG | Website / Blog / Report / YouTube |
| Social Radar Card | 1080×1350 | SVG | IG / 小紅書 / Discord |
| Blog Header | 1280×720 | SVG | SEO Header |
| Story / Reels | 1080×1920 | SVG | Short-form content |

All outputs must be derived from the same Design System.

## Render Discipline

This is a fixed dashboard render system, not a redesign task.

Codex must not:

- redesign layout
- change radar center
- change node positions
- change colors
- change typography
- add extra text inside stock nodes
- move dashboard panels
- create new visual styles

Only CSV data may change.

## Logo Resolution Rule v1.5 (v1.0.0 release profile)

Dashboard、Social Card 與 Cover／SEO overlay 必須使用已提交的 clean production logo：

- `outputs/APL_Deep_Scan_Brand_Logo_Renderer_Clean_2026-06-28.png`

Renderer 可以接受明確 `LogoPath` 作受控測試，但正式 v1.0.0 production 不得依賴未提交的 logo variant。過往文件及本機可能存在的 Transparent、White BG、HiRes、Inline、legacy brand 或 source files 僅作 historical／local-only reference，並不隨 release 提供。

## 10. Render Instruction Template

```text
請完全依照 7 份 APL Deep-Scan 規格檔，
根據最新 APL Top30 CSV，
Render 1920×1080 SVG Dashboard。

除股票資料、日期、統計數字外，
所有 Layout、Icon、Glow、位置、字體、比例、顏色不得更改。

這是 Dashboard Render，不是 AI 插畫。
```
