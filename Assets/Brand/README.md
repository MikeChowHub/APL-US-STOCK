# APL Brand Asset Library

品牌圖片統一收納於此。`asset-catalog.json` 記錄來源、bytes、SHA-256 及使用狀態；相同內容只保存一份，歷史來源位置仍記錄在 catalog。

| 位置 | 用途 |
|---|---|
| 根目錄 Clean PNG | 現行正式 Logo，1677×620 |
| `Sources/` | 原始設計、備份及 Logo Book |
| `Variants/` | 透明、白底、去框及尺寸版本，僅供參考 |
| `Icons/` | Icon 概念設計，尚未核准為正式 icon |
| `Review/2026-09-11/` | 去背及向量比較稿，包含已淘汰嘗試 |

## 常用檔案

- [正式 Logo](APL_Deep_Scan_Brand_Logo_Renderer_Clean.png)
- [1920×819 原始設計](Sources/APL_Deep_Scan_Brand_Logo_Renderer_Source_2026-06-28.png)
- [去框透明比較稿](Review/2026-09-11/APL_Original_NoFrame_Transparent.png)
- [高解像度母稿向量比較稿](Review/2026-09-11/APL_Logo_Clean_1677_Vector.svg)
- [Icon 概念图](Icons/APL_Deep_Scan_Logo_Icon_Concepts_2026-06-28.png)

`brand-manifest.json` 仍是正式 renderer 資產的授權來源；catalog 是搜尋目錄，不代表所有檔案已通過 Production 核准。新增品牌資產應保存至此並更新 catalog。歷史來源檔案未搬動或刪除。

## Production logo

The approved master is `APL_Deep_Scan_Brand_Logo_Renderer_Clean.png` (1677 x 620).
Its SHA-256 is controlled by `brand-manifest.json`. The source is unchanged.

No approved vector master is currently available. Review/ contains vector reconstruction candidates, not approved production replacements.
A PNG embedded in an SVG is not a vector master. Do not auto-trace, redraw,
or use image generation to silently replace the approved brand. A future vector
master requires visual approval and a new manifest entry.

Social Card and full Radar mark the original embedded image `apl-final-logo`.
The shared PNG converter removes that image from a temporary SVG, renders the
chart using resvg, then composites the approved original once in final pixel
space with high-quality bicubic downsampling. Placement remains x=32, y=22,
fit within 490 x 147; native ratio is retained (398 x 147 after pixel rounding).
This controls resampling but cannot recreate detail absent from the source.

The final logo pass happens BEFORE PNG verification, final SHA calculation,
Final Production Audit and Archive. Missing/mismatched logo or failed compositing
fails export; partial output is removed. Existing published images are immutable.
Do not paste logos onto archived/published artifacts. Compare isolated previews
before approving visual changes. SVG retains the embedded original for standalone
viewing; the special final pass applies to PNG only.
