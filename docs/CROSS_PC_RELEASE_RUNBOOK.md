# Cross-PC Production Runbook

## Repository-only environment validation

After cloning, use Windows PowerShell 5.1 from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_cross_pc_environment.ps1 -FullRegression
```

The only successful environment result is `CROSS-PC ENVIRONMENT READY`. This command validates Git root, `main`, origin, required HEAD files, schemas, repository fonts, brand asset, resvg, renderer dimensions, zero font fallback, zero invalid geometry, Table Card semantics, Final Audit and Archive V2 fixtures. It does not start Production.

## Managed inputs

Place the new date's inputs under `work/managed-inputs/<ScanDate>/`; `work/` remains local and must never be committed. The managed bundle contains the source CSV, Top Gainers CSV, detailed Market Context source, Trigger B metadata, Table Card manifest and four semantic v1.1 inputs, Cover Brief, two native cinematic backgrounds, and the complete publishing materials root. Placeholder publishing files are forbidden.

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
