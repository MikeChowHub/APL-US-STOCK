# APL US Stock Production System

Cross-PC setup and second-computer commands are documented in [Cross-PC Production Runbook](docs/CROSS_PC_RELEASE_RUNBOOK.md). Run `tools/validate_cross_pc_environment.ps1 -FullRegression` before supplying daily managed inputs; environment validation never starts Production.

APL US Stock 是一套 Windows PowerShell 5.1 production pipeline，將既有 scoring／ranking、watchlist 與 SMA200 audit、renderer contract validation、Dashboard、Social Card、完整 Social Radar、Table Card、Cover／SEO overlay，以及 UTF-8 log／JSONL trace 串成可追蹤、fail-fast、no-overwrite 的每日流程。

## Product release

Repository product version 是 **v1.0.0**；正式版本來源見 `VERSION`。文件內出現的 v1.0、v1.1、v1.5、v1.6 是個別 workflow、contract、component 或 design-system 版本，不代表 repository product release。

v1.0.0 scope 包括：

- 現有 scoring／ranking 邏輯的 production orchestration；
- watchlist／SMA200 machine audit；
- Dashboard、Social Card、Social Radar、Table Card runtime contract 與 renderer；
- Cover／SEO local overlay；
- production path guard、no-overwrite、failure staging、UTF-8 logs 與 JSONL trace；
- 2026-07-12 regression-compatible workflow。

不包括自動 Commit／Push、GitHub Release API、Orchestrator service、歷史 Archive 或歷史 outputs。

## Prerequisites

- Windows 10／11 與 **Windows PowerShell 5.1**；不依賴 `pwsh`。
- `git.exe` 必須在 `PATH`。只安裝／登入 GitHub Desktop 不保證外部 PowerShell 可找到 Git；先執行 `git --version`。
- .NET Framework 可載入 `System.Drawing` 與 `Microsoft.VisualBasic`。
- 建議安裝設計文件所用字型；缺少時 renderer 會 fallback，但跨 PC 像素結果可能不同。
- Trigger C由Codex先按正式市場文案建立符合schema的Cover Brief，再以同一scene concept分別生成原生4:5 Cover及原生16:9 SEO無字背景。`run_daily_production.ps1`以`CoverBriefPath`／`CoverBackgroundPath`／`SeoBackgroundPath`接收inputs，本地renderer只疊加準確標題、日期、logo及各自版式。PowerShell pipeline本身不呼叫image generation。
- 正式 production logo 與 manifest 位於 `Assets/Brand/`；runtime 不依賴 `outputs/` 歷史檔案。

完整環境檢查、參數及 recovery 程序見 [Production Runbook](docs/PRODUCTION_RUNBOOK.md)。

## Daily production

由 repository root 啟動最外層 Windows PowerShell：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -InputCsv "<absolute-input-csv>" `
  -TopGainersCsvPath "<absolute-top-gainers-csv>" `
  -MarketContextPath "<absolute-market-context-md>" `
  -TriggerBMetaPath "<absolute-managed-trigger-b-meta>" `
  -ScanDate "YYYY-MM-DD" `
  -WeekLabel "<week-label>" `
  -TableCardManifestPath "<absolute-table-card-manifest-json>" `
  -CoverBriefPath "<absolute-cover-brief-json>" `
  -CoverBackgroundPath "<absolute-native-cover-background>" `
  -SeoBackgroundPath "<absolute-native-seo-background>" `
  -CoverNativeContractPath "<absolute-cover-native-contract>" `
  -SeoNativeContractPath "<absolute-seo-native-contract>" `
  -PublishingArtifactsRoot "<absolute-managed-publishing-root>"
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
  -TableCardManifestPath "<baseline-table-card-manifest-json>" `
  -CoverBriefPath "<baseline-cover-brief-json>" `
  -CoverBackgroundPath "<baseline-native-cover-background>" `
  -SeoBackgroundPath "<baseline-native-seo-background>"
```

Regression fixtures 屬本機測試資料，不隨 v1.0.0 repository 發布；執行者須提供已核准 baseline inputs，並比較 Top 30、audit counts、contracts 與 artifacts。

## Inputs and outputs

正式Daily Production必需 inputs 是 cumulative source CSV、Top Gainers CSV、Market Context、Trigger B metadata／ranking evidence、四張Table Card manifest／semantic inputs、完整publishing root、Cover Brief、兩張不同native backgrounds及兩份native composition records。Runner會先自行執行managed-input preflight，再重算Trigger B並核對ranking SHA；獨立preflight不能繞過這個gate。Sector map與clean logo有repository-relative defaults，仍受resolved production path guard約束。

每次成功 run 產生 ranking、Top 30、watchlist、SMA200 audit、metadata、renderer contracts、Dashboard／Social SVG、正式 `production-package/`、renderer logs，以及包含 artifact SHA-256 的 pipeline JSONL trace。

日期 Production Package 由 runner 在 staging 原生建立。`production-package/Table Cards/` 保存四張 required Table Card PNG、logs及publication manifest；package根目錄保存Dashboard／Social PNG、Cover、SEO、WhatsApp、Blog Markdown／HTML及`APL_Production_Package_Manifest_<ScanDate>.json`。SVG、renderer contracts、ranking、SMA200及其他machine records留在日期根目錄。上述publishing artifacts不得在日期根目錄重複出現，亦不得在publish後手動搬移。

完整package規則及舊路徑migration policy見 [Production Package Rules](KnowledgeBase/Rules/APL_US_Stock_Production_Package_Rules.md)。

## Failure staging and recovery

Pipeline 先寫入 `<OutputRoot>/.staging/<RunId>/`，所有 steps 成功後才把日期目錄 publish。失敗會保留 staging 供診斷，不會 publish 不完整日期目錄；先查看 `outputs/logs/daily-production-<RunId>.log` 與 `.jsonl`。修正 input 或環境後，以新 run 重試。只可在確認沒有 runner 執行、已保存所需診斷、且目標確為失敗 run 的 staging 目錄後手動清理；不得刪除既有正式日期 output。

## First publish with GitHub Desktop

1. 在 GitHub Desktop 開啟此 repository，確認 current repository、branch `main` 及 remote URL 正確。
2. 檢查 Changes，只選取 Release Readiness Final Audit 核准的 commit scope；不要加入 `Archive/`、`tmp/`、`.staging/`、logs 或歷史 outputs。
3. 建立首次 commit，例如 `Release v1.0.0`，再 Push origin。
4. Push 完成後確認遠端 `main` 已建立且 commit 正確。
5. 只有 Final Audit 為 PASS 後才建立 annotated tag `v1.0.0`。GitHub Desktop 用於首次 commit／push；如其版本沒有 tag UI，另在 repository root 使用 `git tag -a v1.0.0 -m "APL US Stock v1.0.0"` 及 `git push origin v1.0.0`。不使用 GitHub CLI (`gh`)；本 pipeline 不會自動 commit、tag 或 push。

## Automatic Archive completion gate

當日 Production 的完成狀態包含 Archive，不需要額外指示：

```text
Production PASS
→ Final Production Audit PASS
→ Archive Copy
→ file count / bytes / SHA-256 audit
→ Archive index update
→ Archive PASS
→ Daily Production Complete
→ Daily Production Publishable
```

- Source：`outputs/YYYY-MM-DD/`
- Destination：`Archive/YYYY/YYYY-MM-DD/`
- Runner：`tools/run_daily_production.ps1`
- Archive executor：`tools/archive_daily_production.ps1`
- Evidence：`outputs/YYYY-MM-DD/Final_Production_Audit_YYYY-MM-DD.json` 與 `Archive/YYYY/YYYY-MM-DD/archive-manifest.json`
- Index：`Archive/index.md`

Archive 採 Copy 並保留來源；不以 Move／Delete 取代。正式 Blog、HTML、Top 30 analysis、publishing materials、Dashboard、Social、Table Cards、Cover、SEO、manifest、必要 audits/logs 會保留；staging、temporary、cache、diagnostic 與指定重複中間檔會排除。

Archive 是 Production workflow 的責任。Git Commit／Push 不觸發 Archive，runner 也不自動 Commit／Push。完整規則見 [Archive Rules](KnowledgeBase/Rules/APL_US_Stock_Archive_Rules.md)，操作與驗收見 [Production Runbook](docs/PRODUCTION_RUNBOOK.md) 及 [Final Production Audit Checklist](docs/FINAL_PRODUCTION_AUDIT_CHECKLIST.md)。

Archive v2 adoption由 `tools/archive-v2-policy.json` 控制。既有 pre-v2日期不會被偽造為 PASS：只有 policy精確 allowlisted的歷史目錄可在 `Archive/index.md` 標示 `LEGACY_UNVERIFIED`，其 Files／Bytes只是當前唯讀 inventory，並非歷史完整性證明。新的 v2日期仍必須有有效 manifest；未知或 adoption後缺 manifest日期會 fail-fast。Index格式與維護規則見 [Archive Index Policy](docs/ARCHIVE_INDEX_POLICY.md)。
