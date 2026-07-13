# APL US Stock Production System

APL US Stock 是一套 Windows PowerShell 5.1 production pipeline，將既有 scoring／ranking、watchlist 與 SMA200 audit、renderer contract validation、Dashboard、Social Card、Table Card、Cover／SEO overlay，以及 UTF-8 log／JSONL trace 串成可追蹤、fail-fast、no-overwrite 的每日流程。

## Product release

Repository product version 是 **v1.0.0**；正式版本來源見 `VERSION`。文件內出現的 v1.0、v1.1、v1.5、v1.6 是個別 workflow、contract、component 或 design-system 版本，不代表 repository product release。

v1.0.0 scope 包括：

- 現有 scoring／ranking 邏輯的 production orchestration；
- watchlist／SMA200 machine audit；
- Dashboard、Social Card、Table Card runtime contract 與 renderer；
- Cover／SEO local overlay；
- production path guard、no-overwrite、failure staging、UTF-8 logs 與 JSONL trace；
- 2026-07-12 regression-compatible workflow。

不包括自動 Commit／Push、GitHub Release API、Orchestrator service、歷史 Archive 或歷史 outputs。

## Prerequisites

- Windows 10／11 與 **Windows PowerShell 5.1**；不依賴 `pwsh`。
- `git.exe` 必須在 `PATH`。只安裝／登入 GitHub Desktop 不保證外部 PowerShell 可找到 Git；先執行 `git --version`。
- .NET Framework 可載入 `System.Drawing` 與 `Microsoft.VisualBasic`。
- 建議安裝設計文件所用字型；缺少時 renderer 會 fallback，但跨 PC 像素結果可能不同。
- Cover／SEO 需要預先準備 cinematic background 圖及符合 schema 的 cover brief JSON；pipeline 不會生成背景圖。
- v1.0.0 唯一隨 repository 提供及支援的 production logo 是 `outputs/APL_Deep_Scan_Brand_Logo_Renderer_Clean_2026-06-28.png`。

完整環境檢查、參數及 recovery 程序見 [Production Runbook](docs/PRODUCTION_RUNBOOK.md)。

## Daily production

由 repository root 啟動最外層 Windows PowerShell：

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

Production output root 固定為 `outputs/`。成功後 artifacts 位於 `outputs/<ScanDate>/`，logs 位於 `outputs/logs/`。同日期正式 artifacts 已存在時，pipeline 會在寫入前拒絕覆蓋。

## Regression

Regression mode 必須同時使用 `-RegressionTest`，並明確把 `-OutputRoot` 指向 repository `tmp/` 之內的獨立目錄；`tmp/` 只供 test／regression，絕不可作正式 production input/output。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -RegressionTest `
  -OutputRoot ".\tmp\regression-2026-07-12" `
  -InputCsv "<2026-07-12-baseline-input>" `
  -ScanDate "2026-07-12" `
  -WeekLabel "<baseline-week-label>" `
  -TableCardInputPath "<baseline-table-card-json>" `
  -TableCardType "TopLeaders" `
  -CoverBriefPath "<baseline-cover-brief-json>" `
  -CoverBackgroundPath "<baseline-cinematic-background>"
```

Regression fixtures 屬本機測試資料，不隨 v1.0.0 repository 發布；執行者須提供已核准 baseline inputs，並比較 Top 30、audit counts、contracts 與 artifacts。

## Inputs and outputs

必需 inputs 是 source CSV、scan date、week label、Table Card contract JSON／type、Cover brief JSON 及 cinematic background。Sector map 與 clean logo 有 repository-relative defaults；可用明確參數覆寫，但仍受 resolved production path guard 約束。

每次成功 run 產生 ranking、Top 30、watchlist、SMA200 audit、metadata、renderer contracts、Dashboard／Social SVG、Table Card PNG、Cover／SEO PNG、renderer logs，以及包含 artifact SHA-256 的 pipeline JSONL trace。

## Failure staging and recovery

Pipeline 先寫入 `<OutputRoot>/.staging/<RunId>/`，所有 steps 成功後才把日期目錄 publish。失敗會保留 staging 供診斷，不會 publish 不完整日期目錄；先查看 `outputs/logs/daily-production-<RunId>.log` 與 `.jsonl`。修正 input 或環境後，以新 run 重試。只可在確認沒有 runner 執行、已保存所需診斷、且目標確為失敗 run 的 staging 目錄後手動清理；不得刪除既有正式日期 output。

## First publish with GitHub Desktop

1. 在 GitHub Desktop 開啟此 repository，確認 current repository、branch `main` 及 remote URL 正確。
2. 檢查 Changes，只選取 Release Readiness Final Audit 核准的 commit scope；不要加入 `Archive/`、`tmp/`、`.staging/`、logs 或歷史 outputs。
3. 建立首次 commit，例如 `Release v1.0.0`，再 Push origin。
4. Push 完成後確認遠端 `main` 已建立且 commit 正確。
5. 只有 Final Audit 為 PASS 後才建立 annotated tag `v1.0.0`。GitHub Desktop 用於首次 commit／push；如其版本沒有 tag UI，另在 repository root 使用 `git tag -a v1.0.0 -m "APL US Stock v1.0.0"` 及 `git push origin v1.0.0`。不使用 GitHub CLI (`gh`)；本 pipeline 不會自動 commit、tag 或 push。
