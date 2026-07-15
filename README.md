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
- Trigger C 由 Codex 先按正式市場文案建立符合 schema 的 Cover Brief，再使用 image generation workflow 生成無字 cinematic background。背景生成完成後，`run_daily_production.ps1` 以 `CoverBriefPath`／`CoverBackgroundPath` 接收兩項 production inputs，並由本地 renderer 疊加準確標題、日期、logo及SEO版式。PowerShell pipeline 本身不呼叫 image generation。
- v1.0.0 唯一隨 repository 提供及支援的 production logo 是 `outputs/APL_Deep_Scan_Brand_Logo_Renderer_Clean_2026-06-28.png`。

完整環境檢查、參數及 recovery 程序見 [Production Runbook](docs/PRODUCTION_RUNBOOK.md)。

## Daily production

由 repository root 啟動最外層 Windows PowerShell：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -InputCsv "<absolute-input-csv>" `
  -ScanDate "YYYY-MM-DD" `
  -WeekLabel "<week-label>" `
  -TableCardManifestPath "<absolute-table-card-manifest-json>" `
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
  -TableCardManifestPath "<baseline-table-card-manifest-json>" `
  -CoverBriefPath "<baseline-cover-brief-json>" `
  -CoverBackgroundPath "<baseline-cinematic-background>"
```

Regression fixtures 屬本機測試資料，不隨 v1.0.0 repository 發布；執行者須提供已核准 baseline inputs，並比較 Top 30、audit counts、contracts 與 artifacts。

## Inputs and outputs

必需 inputs 是 source CSV、scan date、week label、Table Card contract JSON／type，以及由 Trigger C pre-production stage 產生的 Cover Brief JSON 與無字 cinematic background。預設由 Codex 根據正式市場文案建立後兩者，不應要求使用者自行設計背景；使用者亦可明確指定已核准的外部背景。Sector map 與 clean logo 有 repository-relative defaults；可用明確參數覆寫，但仍受 resolved production path guard 約束。

每次成功 run 產生 ranking、Top 30、watchlist、SMA200 audit、metadata、renderer contracts、Dashboard SVG＋1920×1080 PNG、Social SVG、Table Card PNG、Cover／SEO PNG、renderer logs，以及包含 artifact SHA-256 的 pipeline JSONL trace。

日期 Production Package 的 `production-package/` 子目錄集中當日 PNG、Table Card 圖片、Blog `.md`／`.html`；其 `table-card-log/` 子目錄集中 Table Card logs、manifest及指定 supporting contracts／CSV／analysis files。SVG、其餘 contracts、SMA200、renderer logs及其他 machine records留在日期根目錄。Package relocation 必須同步 trace path migration，並保持每個 artifact bytes／SHA-256不變。

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
