# APL US Stock Production Package Rules

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
