# Cross-PC Production Runbook

## Repository-only environment validation

After cloning, use Windows PowerShell 5.1 from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_cross_pc_environment.ps1 -FullRegression
```

The only successful environment result is `CROSS-PC ENVIRONMENT READY`. This command validates Git root, `main`, origin, required HEAD files, schemas, repository fonts, brand asset, resvg, renderer dimensions, zero font fallback, zero invalid geometry, Table Card semantics, Final Audit and Archive V2 fixtures. It does not start Production.

## Managed inputs

Place the new date's inputs under `work/managed-inputs/<ScanDate>/`; `work/` remains local and must never be committed. The managed bundle contains the source CSV, Table Card manifest and four semantic v1.1 inputs, Cover Brief, cinematic background, and publishing materials root.

Run the preflight before Production:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_managed_inputs.ps1 `
  -InputCsv ".\work\managed-inputs\<ScanDate>\source.csv" `
  -ScanDate "<ScanDate>" `
  -TableCardManifestPath ".\work\managed-inputs\<ScanDate>\table-card-manifest.json" `
  -CoverBriefPath ".\work\managed-inputs\<ScanDate>\cover-brief.json" `
  -CoverBackgroundPath ".\work\managed-inputs\<ScanDate>\cover-background.png" `
  -PublishingArtifactsRoot ".\work\managed-inputs\<ScanDate>\publishing"
```

Only `MANAGED INPUT PREFLIGHT PASS` may proceed.

## Atomic Production

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\run_daily_production.ps1 `
  -InputCsv ".\work\managed-inputs\<ScanDate>\source.csv" `
  -ScanDate "<ScanDate>" `
  -WeekLabel "<week-label>" `
  -TableCardManifestPath ".\work\managed-inputs\<ScanDate>\table-card-manifest.json" `
  -CoverBriefPath ".\work\managed-inputs\<ScanDate>\cover-brief.json" `
  -CoverBackgroundPath ".\work\managed-inputs\<ScanDate>\cover-background.png" `
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
```

No Git operation is performed by the validator or runner.

## Repository boundaries

- Runtime assets come from `Assets/`, never historical `outputs/`.
- Fonts are loaded only from `Assets/Fonts` with manifest SHA validation; system fallback is forbidden.
- PNG conversion uses repository `resvg.exe`; Chrome and Edge are not required.
- `work/`, `outputs/`, `Archive/`, `tmp/`, local logs, preview PNGs and daily managed inputs are never release files.
