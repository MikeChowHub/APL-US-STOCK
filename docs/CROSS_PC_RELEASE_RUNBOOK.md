# Cross-PC Production Runbook

## Repository-only environment validation

After cloning, use Windows PowerShell 5.1 from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_cross_pc_environment.ps1 -FullRegression
```

The only successful environment result is `CROSS-PC ENVIRONMENT READY`. This command validates Git root, `main`, origin, required HEAD files, schemas, repository fonts, brand asset, resvg, renderer dimensions, zero font fallback, zero invalid geometry, Table Card semantics, Final Audit and Archive V2 fixtures. It does not start Production.

## Managed inputs

Do not manually construct `work/managed-inputs/<ScanDate>/`. Start the tracked Trigger C preparation workflow from the three approved intake files:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\prepare_trigger_c_managed_inputs.ps1 `
  -Mode Initialize `
  -ScanDate "<ScanDate>" `
  -WeekLabel "<week-label>" `
  -InputCsv "<cumulative-screener.csv>" `
  -TopGainersCsvPath "<top-gainers.csv>" `
  -MarketContextPath "<market-context.md>"
```

Initialize copies and hashes the three sources, runs the repository Trigger B implementation in isolated staging, preserves the dated ranking／metadata inside the preparation bundle, and writes `trigger-c-preparation.json`. It creates directories and an exact work order only; it never creates placeholder publishing or native files.

Codex then completes the work order inside the reported staging root using the current Rules and Templates. This is the explicit editorial／image-generation boundary: issue-specific Blog／HTML／WhatsApp／Company Analysis and semantic cards require editorial judgment, while Cover／SEO require two image-generation calls. PowerShell must not invent this content.

After every work-order artifact is complete, finalize the bundle:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\prepare_trigger_c_managed_inputs.ps1 `
  -Mode Finalize `
  -ScanDate "<ScanDate>"
```

Finalize verifies the original source hashes, executes the full managed-input preflight against staging, and only after PASS atomically publishes `work/managed-inputs/<ScanDate>/`. On failure it leaves staging intact, does not create the final managed-input directory and does not start Production. `work/` remains local and must never be committed.

If an approved intake source is corrected after Initialize, do not edit the hash-bound staging copy. Use `-Mode Supersede` with all three replacement inputs and the same ScanDate／WeekLabel. It first validates the new Market Context has exactly one substantive `本期核心市場命題：...` line, moves the matching old builder staging directory intact to `work/.staging/trigger-c/rejected/`, then creates a new source-bound staging bundle. It refuses to supersede a managed bundle or a directory without matching builder state.

Run the preflight before Production:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_managed_inputs.ps1 `
  -InputCsv ".\work\managed-inputs\<ScanDate>\source.csv" `
  -TopGainersCsvPath ".\work\managed-inputs\<ScanDate>\top-gainers.csv" `
  -MarketContextPath ".\work\managed-inputs\<ScanDate>\market-context.md" `
  -TriggerBMetaPath ".\work\managed-inputs\<ScanDate>\trigger-b\<ScanDate>\APL_Momentum_Leaders_Meta_<ScanDate>.json" `
  -ScanDate "<ScanDate>" `
  -TableCardManifestPath ".\work\managed-inputs\<ScanDate>\table-card-manifest.json" `
  -CoverBriefPath ".\work\managed-inputs\<ScanDate>\cover-brief.json" `
  -CoverBackgroundPath ".\work\managed-inputs\<ScanDate>\cover-background.png" `
  -SeoBackgroundPath ".\work\managed-inputs\<ScanDate>\seo-background.png" `
  -CoverNativeContractPath ".\work\managed-inputs\<ScanDate>\cover-native-contract.json" `
  -SeoNativeContractPath ".\work\managed-inputs\<ScanDate>\seo-native-contract.json" `
  -PublishingArtifactsRoot ".\work\managed-inputs\<ScanDate>\publishing"
```

Only `MANAGED INPUT PREFLIGHT PASS` with `EditorialCompletion=PASS`, `ProductionReadiness=PASS` and `DailyProductionPublishableCandidate=true` may proceed. The preflight writes deterministic v1.1 readiness evidence into the publishing package. The Production runner repeats this same fail-closed gate before scoring and verifies that its generated Trigger B ranking matches the managed editorial evidence; the standalone command is not a bypass token.

## Atomic Production

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -InputCsv ".\work\managed-inputs\<ScanDate>\source.csv" `
  -TopGainersCsvPath ".\work\managed-inputs\<ScanDate>\top-gainers.csv" `
  -MarketContextPath ".\work\managed-inputs\<ScanDate>\market-context.md" `
  -TriggerBMetaPath ".\work\managed-inputs\<ScanDate>\trigger-b\<ScanDate>\APL_Momentum_Leaders_Meta_<ScanDate>.json" `
  -ScanDate "<ScanDate>" `
  -WeekLabel "<week-label>" `
  -TableCardManifestPath ".\work\managed-inputs\<ScanDate>\table-card-manifest.json" `
  -CoverBriefPath ".\work\managed-inputs\<ScanDate>\cover-brief.json" `
  -CoverBackgroundPath ".\work\managed-inputs\<ScanDate>\cover-background.png" `
  -SeoBackgroundPath ".\work\managed-inputs\<ScanDate>\seo-background.png" `
  -CoverNativeContractPath ".\work\managed-inputs\<ScanDate>\cover-native-contract.json" `
  -SeoNativeContractPath ".\work\managed-inputs\<ScanDate>\seo-native-contract.json" `
  -PublishingArtifactsRoot ".\work\managed-inputs\<ScanDate>\publishing"
```

The runner owns the complete sequence:

```text
atomic staging
→ production-package manifest
→ Final Production Audit
→ Archive V2 copy and integrity
→ Archive index verification
→ final Archive manifest PASS
→ authoritative DailyProductionComplete=true
→ authoritative DailyProductionPublishable=true
```

No Git operation is performed by the validator or runner.

## Repository boundaries

- Runtime assets come from `Assets/`, never historical `outputs/`.
- Fonts are loaded only from `Assets/Fonts` with manifest SHA validation; system fallback is forbidden.
- PNG conversion uses repository `resvg.exe`; Chrome and Edge are not required.
- `work/`, `outputs/`, `Archive/`, `tmp/`, local logs, preview PNGs and daily managed inputs are never release files.
