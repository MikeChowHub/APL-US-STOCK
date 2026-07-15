# Production Runbook

本 runbook 適用於 APL US Stock repository product v1.0.0，執行環境為 Windows PowerShell 5.1。

## 1. Preflight

在 repository root 執行：

```powershell
$PSVersionTable.PSVersion
git --version
git rev-parse --show-toplevel
git branch --show-current
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
```

要求：PowerShell major version 是 5；Git Root 等於目前 Project Root；production branch／remote 與發布計劃一致。Runner 會直接呼叫 `git.exe`，所以 Git 必須在 `PATH`。GitHub Desktop 已登入並不等於 `git.exe` 可被外部 PowerShell 找到；如 `git --version` 失敗，先把合適 Git installation 加入 `PATH`，不要修改 runner 去綁定某台 PC 的絕對路徑。

`System.Drawing` 與 `Microsoft.VisualBasic` 必須可載入。字型缺失時 renderer 可 fallback，但字寬、換行與像素輸出可能不同；需要 pixel-stable release 時，所有執行 PC 應使用相同核准字型集合。

Cover／SEO overlay 的指定字型為中文 `Alibaba Sans HK`、英文／數字 `Montserrat`。每次 renderer 必須以 `System.Drawing.Font.Name` 記錄 `Requested Font`、`Resolved Font` 及 status，至少涵蓋 `fontTitle`、`fontSubtitle`、`fontMeta`。Production 預設沒有 `APL_ALLOW_FONT_FALLBACK=1`：requested 與 resolved 不一致時不得靜默 fallback 或輸出檔案。受控 comparison render 才可在其獨立 process 設定 `APL_ALLOW_FONT_FALLBACK=1`，並在 overlay log 明確記錄 `WARNING`；中文 fallback 為 `Microsoft JhengHei UI`，英文／數字 fallback 為 `Arial`。

## 2. Required inputs

| Parameter | Required | Meaning |
|---|---:|---|
| `InputCsv` | Yes | 原始 scoring input CSV |
| `ScanDate` | Yes | `YYYY-MM-DD` |
| `WeekLabel` | Yes | 顯示用週期標籤 |
| `TableCardManifestPath` | Trigger C recommended | 符合 `tools/table_card_manifest.schema.json` 的 UTF-8 manifest；正式每日Trigger C必須列出4張required cards |
| `TableCardInputPath` | Single-card compatibility | 單卡 backward-compatible mode的Table Card contract |
| `TableCardType` | Single-card compatibility | 單卡 mode的renderer type |
| `CoverBriefPath` | Yes | Codex 按正式市場文案建立、符合 cover brief schema 的 UTF-8 JSON |
| `CoverBackgroundPath` | Yes | Codex 經 image generation workflow 生成並保存到核准 production-input path 的無字 cinematic background；overlay renderer 只負責本地後製 |
| `OutputRoot` | No | Production 必須是 repository `outputs/`；省略即可。Regression 必須明確位於 repository `tmp/` 內 |
| `SectorMapPath` | No | 預設 `tools/sector_map.json` |
| `LogoPath` | No | 預設且唯一隨 v1.0.0 支援的 clean production logo |
| `TableCardOutputName` | No | 只可是單一檔名，不可含目錄或 traversal |
| `RegressionTest` | No | 由 CLI 啟用 regression authority；不是 JSON contract property |

所有 production input 應放在核准、可追溯且非 `tmp/`、`prototype/`、pre-migration backup 或舊 Codex 絕對路徑的位置。JSON／CSV 使用 UTF-8。

正式Trigger C應使用 `-TableCardManifestPath`。Runner逐項Validate及Render；每張寫入JSONL trace與published `APL_Table_Card_Manifest_<ScanDate>.json`。任何`Required=true` card failure令整體pipeline fail；optional failure會記錄但不得被Blog引用。Single-card parameters只保留作backward compatibility及受控測試。

## 3. Cover pre-production and cinematic background

`CoverBackgroundPath` 是 PowerShell runner 的必要 file input，但預設 production responsibility 不在使用者。Trigger C inputs 齊備後，Codex 必須在啟動 runner 前完成：

```text
正式市場文案／研究結論
↓
建立 Cover Brief JSON
↓
使用 image generation workflow 生成無字 cinematic background
↓
將 final background 保存到 Project Root 內核准且非 tmp/ 的 production-input path
↓
把 CoverBriefPath 與 CoverBackgroundPath 傳給 run_daily_production.ps1
↓
本地 renderer 疊加正式標題、日期、logo及SEO版式
```

Codex 不應要求使用者自行設計或製作背景。只有 image generation capability 不可用、生成失敗，或使用者明確指定外部核准背景時，才可停下並報告具體狀態。

背景必須能同時裁切為 Cover 1080x1350 與 SEO 1280x720；上方約 35–40% 為低細節 text-safe area，主體集中於中下方。背景不得包含文字、日期、logo、ticker、table、dashboard UI、資訊卡或由 renderer 再疊加的品牌元素。Cover Brief 的構圖、crop／focal point 與 overlay 欄位應先驗證；背景不存在或不可讀時 runner 仍必須 fail-fast。

Image generation 與 PowerShell runner 是兩個明確 stages：runner 不應內嵌外部生成 API，image generation 亦不得自行繪製正式文字或logo。

## 4. Production command

Execution Policy 可能阻擋直接執行 `.ps1`，因此最外層也必須明確使用 Windows PowerShell 5.1：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -InputCsv "<absolute-input-csv>" `
  -ScanDate "YYYY-MM-DD" `
  -WeekLabel "<week-label>" `
  -TableCardManifestPath "<absolute-table-card-manifest-json>" `
  -CoverBriefPath "<absolute-cover-brief-json>" `
  -CoverBackgroundPath "<absolute-cinematic-background>"
```

`-ExecutionPolicy Bypass` 只作用於該 process，不改寫 machine／user policy。Runner 的 child scripts 亦以 `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass` 執行。

## 5. Step map and fail-fast behavior

Runner 依序執行：ScoringRanking → WatchlistSma200Audit → BuildRendererContracts → ValidateDashboardInput → ValidateSocialInput → RenderDashboard SVG → ExportDashboardPng → RenderSocialCard SVG → ExportSocialPng → Validate／Render Table Card manifest → RenderCoverOverlay → RenderSeoOverlay → PublishArtifacts。

Dashboard production completeness要求同時發布1920×1080 SVG及PNG。PNG必須由已完成validation的SVG經`tools/convert_svg_to_png.ps1`及核准的Microsoft Edge／Google Chrome headless export產生；converter維持no-overwrite、resolved path guard、尺寸驗證及fail-fast。

Social production completeness要求同時發布1080×1350 SVG及PNG。Social PNG同樣由已完成validation的SVG經`tools/convert_svg_to_png.ps1`產生，並寫入 `production-package/`。

PublishArtifacts 完成後，runner 必須執行 `LockPublishedMachineArtifacts`：所有由本次 trace追蹤的 machine artifacts設為 Windows read-only，然後才計算及記錄 final bytes／SHA-256。任何 lock failure都令 run失敗。

任何 child exit code 非 0、validation failure、缺失／空 artifact、path guard、no-overwrite 或 audit mismatch 都會立即停止，不會繼續 publish。Scoring／ranking 邏輯只由既有 scoring script執行，runner 不重新實作。

## 6. Output and trace verification

- Working staging：`outputs/.staging/<RunId>/`
- Published artifacts：`outputs/<ScanDate>/`
- Text log：`outputs/logs/daily-production-<RunId>.log`
- JSONL trace：`outputs/logs/daily-production-<RunId>.jsonl`

成功 run 的 JSONL 最後一筆應為 `run-complete`、`status: PASS`，並列出 published artifacts、byte size 與 SHA-256。確認日期目錄、ranking／Top 30、兩份 SMA200 audit、renderer contracts、三種 card/render outputs、Cover／SEO 及各自 logs 完整。

### Date-package file layout

日期 Production Package 的 `production-package/` 子目錄保留：

- 當日 PNG artifacts（Dashboard、Cover、SEO及Table Card PNG）；
- `table-card-log/` 內的 Table Card `.table-card-log.txt`、publication manifest及指定 supporting contracts／CSV／analysis files；
- `APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.md`；
- `APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.html`；
- 已核准的 Dashboard input、source／ranking CSV、cumulative watchlist及 Company Business Analysis。

SVG（Dashboard／Social）、其餘 contracts、SMA200、renderer logs及其他 machine records留在日期根目錄。若整理已發布 package，必須先記錄 path-only migration，再重新核對每個 artifact bytes／SHA-256；不得重新生成或改寫 artifact content。

### Published machine artifact immutability

```text
Publish complete
→ machine artifacts become immutable
→ final bytes／SHA-256 recorded in trace
→ any later write attempt must fail
```

Editorial stage只可 read machine artifacts，不得以 editor、formatter、encoding converter、`Set-Content`、`WriteAllText`或任何 normalization操作重存它們。Blog、company analysis、WhatsApp及其他 editorial outputs必須使用獨立新檔名。需要修復 machine artifact時，必須停止正常 editorial flow、記錄具體 trace mismatch並取得明確 remediation authority。

## 7. Regression procedure

Regression authority 只可由 runner CLI 的 `-RegressionTest` 啟用。OutputRoot 必須是 Project Root 下 `tmp/` 的子目錄：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -RegressionTest `
  -OutputRoot ".\tmp\regression-2026-07-12" `
  -InputCsv "<approved-baseline-csv>" `
  -ScanDate "2026-07-12" `
  -WeekLabel "<approved-baseline-week-label>" `
  -TableCardManifestPath "<approved-baseline-table-card-manifest-json>" `
  -CoverBriefPath "<approved-baseline-cover-brief-json>" `
  -CoverBackgroundPath "<approved-baseline-background>"
```

以核准 baseline 比較完整 Top 30 的 Rank、Symbol 及所需數值欄位、watchlist／SMA200 counts、contracts、artifacts 與 trace PASS。Fixtures 不納入 v1.0.0 commit；不要把 `tmp/` regression output 當 production artifact。

## 8. Failure recovery

1. 記錄 console error 與 RunId。
2. 查看同 RunId 的 UTF-8 `.log` 和 `.jsonl`，定位第一個 failed step。
3. 檢查 input contract、source CSV、Git PATH、assemblies、fonts、background、path guard 與既有同日期 output。
4. 不要搬移或改名失敗 staging 來冒充正式 output；修正根因後啟動新 run。
5. Runner 不會覆寫已存在的正式 artifacts。若日期 output 已存在，先判斷它是否是核准正式 run；不得為了重跑而刪除歷史正式 output。
6. 失敗 staging 預設保留。只有在沒有 active runner、已保存診斷、路徑已確認為 `<OutputRoot>/.staging/<failed-RunId>` 時才可手動清理。

## 9. Release operation

Runner 不會執行 Git stage、commit、tag 或 push。首次發布使用 GitHub Desktop：確認 repository／`main`／origin，核對 Final Audit 的精確 scope，commit 並 push `main`。Final Audit PASS 後，如 GitHub Desktop 沒有 tag UI，可在 repository root 使用 `git tag -a v1.0.0 -m "APL US Stock v1.0.0"` 及 `git push origin v1.0.0`；不需要亦不得使用 GitHub CLI (`gh`)。Archive、tmp、logs、staging 與歷史 outputs不得加入 commit。

## 10. Automatic Archive and daily completion

正式 daily runner 的末段固定如下，不需要等待使用者再下 Archive 指令：

1. `LockPublishedMachineArtifacts`
2. `FinalProductionAudit`
3. `ArchiveDailyProduction`
4. `VerifyArchivePass`
5. `Daily Production Complete`

Final audit 會建立：

```text
outputs/YYYY-MM-DD/Final_Production_Audit_YYYY-MM-DD.json
```

只有該檔案的 schema、日期及 `Status=PASS` 符合時，`tools/archive_daily_production.ps1` 才接受 Archive。正式路徑固定為：

```text
outputs/YYYY-MM-DD/
→ Archive/YYYY/YYYY-MM-DD/
```

Archive executor 會：

- 選取正式 Blog/HTML、Top 30 analysis、publishing materials、Dashboard、Social、Table Cards、Cover、SEO、manifest 與必要 audit/logs；
- 排除 `.staging`、staging、temporary、tmp、cache、typography comparisons、diagnostics 與暫存副檔名；
- Copy 並保留 source relative paths，不 Move／Delete source；
- 逐檔核對 relative path、file count、bytes 與 SHA-256；
- 寫入 `archive-manifest.json`；
- 更新 `Archive/index.md`；
- 只有 manifest 與 index 都通過 runner 的 `VerifyArchivePass`，才輸出 `DailyProductionComplete=True`。

若 Archive 失敗，runner 保持非完成狀態，即使前段 Production 已 PASS。查看 pipeline log/trace、Final Audit 與 Archive staging 狀態後修正原因；不得以 Git Commit／Push 代替 Archive。既有 Archive 日期只在 PASS manifest 且與來源逐檔一致時可重用，不會覆蓋不同內容。

Regression 使用同一 Archive executor，但 destination 被隔離在 regression `OutputRoot/_archive/`（位於 `tmp/`），不會更新正式 `Archive/`。

### Legacy Archive compatibility

Archive v2 marker位於 `tools/archive-v2-policy.json`，初始 `AdoptionDate` 為 `2026-07-15`。正式 index建立時：

- 有受支援且逐檔驗證的 v2 manifest：`Status=PASS`；
- adoption前且精確列於 `LegacyUnverifiedDates`、沒有 v2 manifest：`Status=LEGACY_UNVERIFIED`；
- adoption後缺 manifest、未知舊日期缺 manifest、malformed manifest或 legacy日期冒充 v2：立即 FAIL。

Index固定為 `Date | Status | Files | Bytes | Manifest | Notes`。Legacy Files／Bytes只反映當次唯讀 inventory；Manifest為 `N/A`，Notes明示 integrity not attested。不要為舊日期補造 PASS manifest，亦不要修改歷史 Archive。完整 index policy見 `docs/ARCHIVE_INDEX_POLICY.md`。

驗收 checklist：`docs/FINAL_PRODUCTION_AUDIT_CHECKLIST.md`。永久規則：`KnowledgeBase/Rules/APL_US_Stock_Archive_Rules.md`。

Git stage、commit、tag、push 仍是 Production workflow 以外的明確操作，runner 不會自動執行。
