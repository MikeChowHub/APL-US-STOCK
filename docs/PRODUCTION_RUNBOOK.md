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

## 2. Required inputs

| Parameter | Required | Meaning |
|---|---:|---|
| `InputCsv` | Yes | 原始 scoring input CSV |
| `ScanDate` | Yes | `YYYY-MM-DD` |
| `WeekLabel` | Yes | 顯示用週期標籤 |
| `TableCardInputPath` | Yes | 符合 Table Card schema 的 UTF-8 JSON |
| `TableCardType` | Yes | `ExecutiveSummary`、`TopLeaders`、`TopGainers`、`SectorStructure`、`MarketObservation` 或 `Comparison` |
| `CoverBriefPath` | Yes | 符合 cover brief schema 的 UTF-8 JSON |
| `CoverBackgroundPath` | Yes | 已完成的 cinematic background；overlay renderer 不負責生成它 |
| `OutputRoot` | No | Production 必須是 repository `outputs/`；省略即可。Regression 必須明確位於 repository `tmp/` 內 |
| `SectorMapPath` | No | 預設 `tools/sector_map.json` |
| `LogoPath` | No | 預設且唯一隨 v1.0.0 支援的 clean production logo |
| `TableCardOutputName` | No | 只可是單一檔名，不可含目錄或 traversal |
| `RegressionTest` | No | 由 CLI 啟用 regression authority；不是 JSON contract property |

所有 production input 應放在核准、可追溯且非 `tmp/`、`prototype/`、pre-migration backup 或舊 Codex 絕對路徑的位置。JSON／CSV 使用 UTF-8。

## 3. Cinematic background prerequisite

執行前必須先準備能同時裁切為 Cover 1080x1350 與 SEO 1280x720 的 cinematic background。背景圖不得包含由 renderer 再疊加的標題、logo 或資訊圖表。Cover brief 的構圖、crop／focal point 與 overlay 欄位應先驗證；背景不存在或不可讀時 pipeline fail-fast。

## 4. Production command

Execution Policy 可能阻擋直接執行 `.ps1`，因此最外層也必須明確使用 Windows PowerShell 5.1：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -InputCsv "<absolute-input-csv>" `
  -ScanDate "YYYY-MM-DD" `
  -WeekLabel "<week-label>" `
  -TableCardInputPath "<absolute-table-card-json>" `
  -TableCardType "TopLeaders" `
  -CoverBriefPath "<absolute-cover-brief-json>" `
  -CoverBackgroundPath "<absolute-cinematic-background>"
```

`-ExecutionPolicy Bypass` 只作用於該 process，不改寫 machine／user policy。Runner 的 child scripts 亦以 `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass` 執行。

## 5. Step map and fail-fast behavior

Runner 依序執行：ScoringRanking → WatchlistSma200Audit → BuildRendererContracts → ValidateDashboardInput → ValidateSocialInput → RenderDashboard → RenderSocialCard → ValidateTableCardInput → RenderTableCard → RenderCoverOverlay → RenderSeoOverlay → PublishArtifacts。

任何 child exit code 非 0、validation failure、缺失／空 artifact、path guard、no-overwrite 或 audit mismatch 都會立即停止，不會繼續 publish。Scoring／ranking 邏輯只由既有 scoring script執行，runner 不重新實作。

## 6. Output and trace verification

- Working staging：`outputs/.staging/<RunId>/`
- Published artifacts：`outputs/<ScanDate>/`
- Text log：`outputs/logs/daily-production-<RunId>.log`
- JSONL trace：`outputs/logs/daily-production-<RunId>.jsonl`

成功 run 的 JSONL 最後一筆應為 `run-complete`、`status: PASS`，並列出 published artifacts、byte size 與 SHA-256。確認日期目錄、ranking／Top 30、兩份 SMA200 audit、renderer contracts、三種 card/render outputs、Cover／SEO 及各自 logs 完整。

## 7. Regression procedure

Regression authority 只可由 runner CLI 的 `-RegressionTest` 啟用。OutputRoot 必須是 Project Root 下 `tmp/` 的子目錄：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -RegressionTest `
  -OutputRoot ".\tmp\regression-2026-07-12" `
  -InputCsv "<approved-baseline-csv>" `
  -ScanDate "2026-07-12" `
  -WeekLabel "<approved-baseline-week-label>" `
  -TableCardInputPath "<approved-baseline-table-card-json>" `
  -TableCardType "TopLeaders" `
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
