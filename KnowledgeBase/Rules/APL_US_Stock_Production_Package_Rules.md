## HTML 共用視覺合約 — 2026-10-19 修訂

自下一期 ScanDate 2026-10-20 起，完整 HTML 與公開預覽必須使用 `tools/client_article_html.ps1` 的同一製作方法。今期另交更正版，已發布與 Archive 原件保留。

- 透明背景容器：width 100%、max-width 800px、置中；Arial / Microsoft JhengHei / sans-serif。
- 正文 18px、行距 1.95、段落下距固定 23px；H3 25px、行距 1.5、章節前距 34px、下距 23px，附底部分隔線。
- 首段摘要使用深色重點框；金色文字只標示該段一個核心研究判斷。其餘正文保持淺色。
- 以當期 Top 30 及單日榜前五公司代碼為依據，文章中每家公司首次出現的代碼加粗一次，後續不重複加粗；股票代碼用淺色，不全部染金。
- 不加入 H1；容器內第一個內容標題仍為 Executive Summary H3。此條取代過往要求檔案第一個標籤必須為裸 H3 的格式限制，八節正文及無來源連結合約不變。
- 公開預覽沿用同一樣式，僅保留完整摘要、市場背景首段及第二段首句／分句加 ...。關閉樣式容器後，以唯一 `<div id="apl-member-content"></div>` 結束；不得洩漏其後會員內容。
- Finalize 在來源驗證後、內容 Preflight 前套用樣式；Preflight、補充檔產生與 Final Audit 必須檢查樣式。Notification 只以正規化內容檢查標題，來源雜湊仍使用實際交付檔。
- 不從歷史 work、更正版或對話記憶讀取製作邏輯。規則、共用工具及測試均在 Repository 內，跨電腦使用相同製作方法。

# APL US Stock Production Package Rules

## 客戶文章不展示來源連結 — 2026-10-12 修訂

今日更正版及往後客戶文章，不附新聞、公司公告或產品資料的來源超連結、URL、來源註腳或 Sources 清單。適用完整 Markdown 正文、完整 HTML、公開預覽及 WhatsApp 分析正文；HTML 不輸出 `<a href=...>` 來源標籤，也不留下「AP機場報道」「公司公告」等孤立引用文字。文章必要的事實、日期、期間及研究判斷保留，來源查核與來源路徑、URL、時間、SHA-256 留在內部新聞快照及編輯證據。Markdown 置頂 SEO and Sharing 的 Canonical URL、SEO 圖，以及 WhatsApp 固定文章／體驗 CTA 是交付用途，照常保留。此規則優先於下方保留正文來源連結的舊說明。已發布與 Archive 原件保留，修訂稿另存並交付。


## 完整 HTML 無 H1 — 2026-10-12 修訂

自下一期 ScanDate 2026-10-13 起，完整 `.html.txt` 與公開預覽均直接以 `<h3>Executive Summary｜執行摘要</h3>` 開頭，不得包含 `<h1>`，也不得在摘要之前加入標題、日期或導言。完整文章標題只留在 Markdown `#` 及 SEO Page title，兩者保持一致。完整 HTML 保留八節正文，來源記錄留於內部，以 Risk 結束；公開預覽及會員 SQL 其餘合約維持。此規則取代下方完整 HTML 必須含 H1／與 Markdown 標題相同的歷史說明。10 月 12 日已完成原稿及 Archive 保留，當期另交付無 H1 更正版。


## Authority

For every new full Trigger C run, the publishing package is created natively in staging and atomically published as:

```text
outputs/<ScanDate>/production-package/
```

Post-publish relocation, manual copying, and duplicate root-level publishing artifacts are forbidden.

## Required package structure

```text
production-package/
|-- Table Cards/
|   |-- four required Table Card PNG files
|   |-- their renderer logs
|   `-- APL_Table_Card_Manifest_<ScanDate>.json
|-- APL_DeepScan_Radar_Dashboard_Top30_<ScanDate>_1920x1080.png
|-- APL_DeepScan_Social_Card_<ScanDate>_1080x1350.png
|-- APL_DeepScan_Social_Radar_Top30_<ScanDate>_1080x1350.png
|-- APL_Momentum_Leaders_Blog_Cover_<ScanDate>_1080x1350.png
|-- APL_Momentum_Leaders_Blog_SEO_<ScanDate>_1280x720.png
|-- WhatsApp_<ScanDate>.md
|-- APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.md
|-- APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.html.txt
|-- APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.public-preview.html.txt
|-- APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.article.sql
|-- table-card-log/APL_Momentum_Leaders_Top_30_Company_Business_Analysis_<ScanDate>.md
`-- APL_Production_Package_Manifest_<ScanDate>.json
```

Dashboard SVG, Social Card SVG, Social Radar SVG, scoring/ranking, watchlist, SMA200 audits, renderer input contracts and other machine records remain at the date root. Dashboard, Social Card, Social Radar, Table Card, Cover, SEO and WhatsApp publishing artifacts must not be duplicated at the date root.

## Manifest and integrity

`APL_Production_Package_Manifest_<ScanDate>.json` uses `APL Production Package Manifest v1.0` and records:

- exact required id-to-relative-path mappings;
- every package file except the package manifest itself;
- file count and total bytes;
- per-file size and SHA-256.

The package manifest is generated only after renderers and publishing import finish, but before atomic publish. Missing files, duplicate ids or paths, unsafe paths, zero-byte files, size/SHA mismatch or root duplicates make Production fail.

## Table Card semantic gate

All four required cards use `APL Table Card Input v1.1`. Rows are keyed objects rather than positional arrays. The shared validator/renderer mapping is authoritative and Final Production Audit revalidates each input path and SHA before Archive.

For `TopLeaders`, `rank` and `compositeScore` already state position and quantitative strength. `mainDriver` must instead give a concise, company-specific business demand or operating variable that a reader can investigate (for example customer usage and renewals, test utilisation and reimbursement, orders and delivery, or product adoption and licensing). It is an evidence/verification lens, not an invented confirmed catalyst or return forecast. Repeating rank, score, relative-strength status, or the same generic phrase for several companies fails the semantic gate. `coreBusiness` says what the company does; `mainDriver` says what demand or commercial conversion matters now. The card may not publish if any required driver lacks that distinction.

## Production completion response

Every successful Daily Production completion response must list the four Table Card PNG artifacts individually under a visible `Table Cards` label. A directory-only link is not an acceptable substitute.

The fixed display labels and file mappings are:

- `Executive Summary` → `production-package/Table Cards/APL_Blog_ExecutiveSummary_<ScanDate>.png`
- `Deep-Scan Dashboard` → `production-package/APL_DeepScan_Radar_Dashboard_Top30_<ScanDate>_1920x1080.png`
- `Top Gainers` → `production-package/Table Cards/APL_Blog_TopGainers_<ScanDate>.png`
- `Top Leaders` → `production-package/Table Cards/APL_Blog_TopLeaders_<ScanDate>.png`
- `Sector Structure` → `production-package/Table Cards/APL_Blog_SectorStructure_<ScanDate>.png`

Each item must be a directly clickable link to its published PNG for the completed ScanDate. The reader-facing `Table Cards` group includes the standalone Dashboard between Executive Summary and Top Gainers, so its fixed five-link order is `Executive Summary → Deep-Scan Dashboard → Top Gainers → Top Leaders → Sector Structure`. This presentation order does not move the Dashboard into the physical `Table Cards/` directory.

After `Table Cards`, the response must list `正式圖像` in this order: `Social Card → Social 完整 Radar → Cover → SEO`. It must then list `文章及發布文件` in this order: `今日文章 Markdown → HTML 原始碼 TXT → WhatsApp → Top 30 公司分析 → 公開預覽 HTML 原始碼 → 會員文章 SQL`. Before every completed delivery, inspect `Assets/Delivery/deep-scan-delivery-reference.png` and compare the response groups, labels, item order and direct artifact links with that image. All links are individual absolute paths. Missing, duplicated, mis-grouped or folder-only entries are an incomplete delivery response.

The three HTML/member publishing artifacts are not interchangeable. The full `.html.txt` retains the entire source, `.public-preview.html.txt` ends at the single empty `<div id="apl-member-content"></div>` boundary after the controlled Market Context excerpt, and `.article.sql` contains the exact same-date `apl-deep-scan-<ScanDate>` manual `'<p>PASTE'` template. Final Audit validates all three before Archive.

## Migration policy

Completed runs before this integration retain their original paths and Archive manifests unchanged. They are not silently relabelled, moved, copied, or backfilled. The new package structure applies only to the next complete rerun that starts from Step 1 or to a later ScanDate. A historical date may adopt the new structure only through an explicitly authorized full replacement production cycle with new Final Audit and Archive evidence; it must never reuse the old `DailyProductionComplete=true` state.

## Archive

Archive V2 copies `outputs/<ScanDate>/` without reclassification. Therefore `production-package/` is preserved byte-for-byte at `Archive/YYYY/MM/<ScanDate>/production-package/`. Archive is permitted only when Final Audit reports both `ProductionPackage.Status=PASS` and four PASS Table Card semantic records.
