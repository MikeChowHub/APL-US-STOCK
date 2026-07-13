# APL US Stock v1.0.0 Release Notes

Release date: 2026-07-13

v1.0.0 是 repository product 的首次 production release。它封裝現有 scoring／ranking 邏輯，提供 Windows PowerShell 5.1 end-to-end runner、machine-enforced renderer contracts、SMA200 audit、path guard、no-overwrite、failure staging、artifact hashes，以及 UTF-8 logs／JSONL trace。

## Version semantics

`VERSION` 是 repository product version 的唯一簡單來源。文件中的 v1.0、v1.1、v1.5、v1.6 是 workflow specification、input contract、component 或 design-system 的獨立版本；它們不表示多個 repository releases，也不取代 product v1.0.0。

## Included

- Production scripts、schemas、sector maps、rules、templates及design documentation。
- `tools/run_daily_production.ps1` production runner。
- `outputs/APL_Deep_Scan_Brand_Logo_Renderer_Clean_2026-06-28.png`，為本 release 唯一支援及提交的 logo asset。
- README 與 Production Runbook。

## Not included

- Archive、tmp、regression fixtures、failed staging、logs及既有歷史 outputs。
- Historical／local-only logo variants。
- Orchestrator service、自動 Commit／Tag／Push 或 GitHub API integration。

## Compatibility and known limitations

- 只支援 Windows PowerShell 5.1 production path；需要 `git.exe` 在 `PATH`，以及 `System.Drawing`、`Microsoft.VisualBasic`。
- 缺少核准字型時會 fallback，視覺結果可能不是跨 PC pixel-identical。
- Cover／SEO cinematic background 必須在 run 前由使用者提供。
- Regression fixtures 不隨 release 發布；2026-07-12 regression 需使用本機核准 baseline inputs。

