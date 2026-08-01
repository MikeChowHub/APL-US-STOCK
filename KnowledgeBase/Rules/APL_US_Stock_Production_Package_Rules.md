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
|-- APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.html
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

## Migration policy

Completed runs before this integration retain their original paths and Archive manifests unchanged. They are not silently relabelled, moved, copied, or backfilled. The new package structure applies only to the next complete rerun that starts from Step 1 or to a later ScanDate. A historical date may adopt the new structure only through an explicitly authorized full replacement production cycle with new Final Audit and Archive evidence; it must never reuse the old `DailyProductionComplete=true` state.

## Archive

Archive V2 copies `outputs/<ScanDate>/` without reclassification. Therefore `production-package/` is preserved byte-for-byte at `Archive/YYYY/<ScanDate>/production-package/`. Archive is permitted only when Final Audit reports both `ProductionPackage.Status=PASS` and four PASS Table Card semantic records.
