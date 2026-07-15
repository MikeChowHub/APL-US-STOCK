[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$TestRoot = Join-Path $ProjectRoot 'tmp\archive-workflow-v2-tests'
$ScanDate = '2040-01-02'
$results = New-Object System.Collections.Generic.List[object]
. (Join-Path $ProjectRoot 'tools\production_archive_common.ps1')

function Add-Result([string]$Name, [bool]$Passed, [string]$Detail = '') {
  $results.Add([pscustomobject]@{ Name=$Name; Status=if($Passed){'PASS'}else{'FAIL'}; Passed=$Passed; Skipped=$false; Detail=$Detail })
  if (-not $Passed) { Write-Host "FAIL $Name :: $Detail" -ForegroundColor Red } else { Write-Host "PASS $Name" }
}
function Add-Skip([string]$Name, [string]$Detail) {
  $results.Add([pscustomobject]@{ Name=$Name; Status='SKIP'; Passed=$true; Skipped=$true; Detail=$Detail })
  Write-Host "SKIP $Name :: $Detail" -ForegroundColor Yellow
}
function Write-Text([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if (!(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.Encoding]::UTF8)
}
function Invoke-ExpectExit([string]$Name, [string]$Script, [string[]]$Arguments, [int]$Expected) {
  $previousPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $output = @(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script @Arguments 2>&1)
    $actual = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousPreference
  }
  Add-Result $Name ($actual -eq $Expected) ("expected=$Expected actual=$actual output=" + ($output -join ' '))
}
function New-ProductionFixture([string]$Root) {
  New-Item -ItemType Directory -Path $Root -Force | Out-Null
  Write-Text (Join-Path $Root "APL_Momentum_Score_Full_Ranking_$ScanDate.csv") "Rank,Symbol,Composite Score,Momentum Score,Buyability Score,Relative Volume Bonus`r`n1,TEST,100,90,10,0"
  Write-Text (Join-Path $Root "APL_Quant_Top_30_$ScanDate.md") '# Top 30'
  Write-Text (Join-Path $Root "APL_Momentum_Leaders_Meta_$ScanDate.json") '{"status":"production"}'
  Write-Text (Join-Path $Root "removed-below-sma200-$ScanDate.txt") 'Symbol'
  Write-Text (Join-Path $Root "retained-missing-sma200-$ScanDate.txt") 'Symbol'
  Write-Text (Join-Path $Root "APL_Momentum_Leaders_Overview_$ScanDate.md") '# Publishing notes'
  Write-Text (Join-Path $Root "APL_Momentum_Leaders_WhatsApp_Post_$ScanDate.txt") 'Production social push'
  Write-Text (Join-Path $Root "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_1920x1080.png") 'dashboard'
  Write-Text (Join-Path $Root "APL_Momentum_Leaders_Blog_Cover_${ScanDate}_1080x1350.png") 'cover'
  Write-Text (Join-Path $Root "APL_Momentum_Leaders_Blog_SEO_${ScanDate}_1280x720.png") 'seo'
  Write-Text (Join-Path $Root "production-package\APL_DeepScan_Social_Card_${ScanDate}_1080x1350.png") 'social'
  Write-Text (Join-Path $Root "production-package\APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.md") '# Formal Blog'
  Write-Text (Join-Path $Root "production-package\table-card-log\APL_Momentum_Leaders_Top_30_Company_Business_Analysis_$ScanDate.md") '# Company analysis'
  $cards = New-Object System.Collections.Generic.List[object]
  foreach ($definition in @(
    @('ExecutiveSummary',"APL_Blog_Key_Signals_$ScanDate.png"),
    @('TopLeaders',"APL_Blog_Top5_Leaders_$ScanDate.png"),
    @('TopGainers',"APL_Blog_TopGainers_$ScanDate.png"),
    @('SectorStructure',"APL_Blog_Structure_Map_$ScanDate.png")
  )) {
    $path = Join-Path $Root ("production-package\" + $definition[1])
    Write-Text $path ("card-" + $definition[0])
    $item = Get-Item -LiteralPath $path
    $cards.Add([pscustomobject]@{ CardType=$definition[0]; OutputName=$definition[1]; Required=$true; Status='PASS'; Bytes=$item.Length; Sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash })
  }
  $manifest = [ordered]@{ SchemaVersion='APL Table Card Publication Manifest v1.0'; ScanDate=$ScanDate; Status='PASS'; Cards=[object[]]$cards.ToArray() }
  Write-Text (Join-Path $Root "APL_Table_Card_Manifest_$ScanDate.json") ($manifest | ConvertTo-Json -Depth 8)
  Write-Text (Join-Path $Root 'cache\excluded.tmp') 'excluded'
  Write-Text (Join-Path $Root 'production-package\diagnostics\diagnostic-only.png') 'excluded'
}
function Copy-Fixture([string]$Source, [string]$Destination) {
  if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Recurse -Force }
  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  foreach ($item in @(Get-ChildItem -LiteralPath $Source -Force)) { Copy-Item -LiteralPath $item.FullName -Destination $Destination -Recurse -Force }
}

if (Test-Path -LiteralPath $TestRoot) { Remove-Item -LiteralPath $TestRoot -Recurse -Force }
New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
try {
  $source = Join-Path $TestRoot "source\$ScanDate"
  New-ProductionFixture $source
  $auditScript = Join-Path $ProjectRoot 'tools\test_production_artifact_contract.ps1'
  $archiveScript = Join-Path $ProjectRoot 'tools\archive_daily_production.ps1'
  $completionScript = Join-Path $ProjectRoot 'tools\complete_daily_production.ps1'
  $contract = Join-Path $ProjectRoot 'KnowledgeBase\Rules\APL_US_Stock_Production_Artifact_Contract.json'
  $archivePolicyPath = Join-Path $ProjectRoot 'tools\archive-v2-policy.json'
  $archivePolicy = Read-AplArchiveV2Policy $archivePolicyPath $ProjectRoot
  $audit = Join-Path $source "Final_Production_Audit_$ScanDate.json"
  Invoke-ExpectExit 'complete-production-artifacts-final-audit' $auditScript @('-RegressionTest','-ProductionDatePath',$source,'-ScanDate',$ScanDate,'-ContractPath',$contract,'-AuditOutputPath',$audit) 0
  $auditJson = Get-Content -Raw -Encoding UTF8 $audit | ConvertFrom-Json
  Add-Result 'final-audit-pass' ([string]$auditJson.Status -eq 'PASS')

  $archiveRoot = Join-Path $TestRoot '_archive'
  foreach ($legacyDateValue in @($archivePolicy.LegacyUnverifiedDates)) {
    $legacyDate = [string]$legacyDateValue
    $legacyDirectory = Join-Path $archiveRoot (Join-Path $legacyDate.Substring(0,4) $legacyDate)
    Write-Text (Join-Path $legacyDirectory 'legacy-artifact.txt') ("pre-v2 archive " + $legacyDate)
  }
  Invoke-ExpectExit 'copy-integrity-index-final-manifest' $archiveScript @('-RegressionTest','-SourceDatePath',$source,'-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveRoot',$archiveRoot) 0
  $archiveDate = Join-Path $archiveRoot "2040\$ScanDate"
  $manifestPath = Join-Path $archiveDate 'archive-manifest.json'
  $manifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
  $actual = @(Get-AplArchiveInventory $archiveDate -ExcludeManifest)
  try { Assert-AplArchiveManifest $manifest $ScanDate 'PASS' $actual | Out-Null; Assert-AplArchiveIndexRow (Join-Path $archiveRoot 'index.md') $manifest $archiveRoot | Out-Null; Add-Result 'manifest-and-index-integrity' $true } catch { Add-Result 'manifest-and-index-integrity' $false $_.Exception.Message }
  try {
    foreach ($legacyDateValue in @($archivePolicy.LegacyUnverifiedDates)) {
      $legacyDate = [string]$legacyDateValue
      $legacyDirectory = Join-Path $archiveRoot (Join-Path $legacyDate.Substring(0,4) $legacyDate)
      $legacyInventory = @(Get-AplArchiveInventory $legacyDirectory -ExcludeManifest)
      Assert-AplLegacyArchiveIndexRow (Join-Path $archiveRoot 'index.md') $legacyDate $legacyInventory.Count ([long](($legacyInventory | Measure-Object Size -Sum).Sum)) $archiveRoot | Out-Null
    }
    Add-Result 'five-legacy-plus-one-v2-index' $true
  } catch { Add-Result 'five-legacy-plus-one-v2-index' $false $_.Exception.Message }
  $indexHashBefore = (Get-FileHash -LiteralPath (Join-Path $archiveRoot 'index.md') -Algorithm SHA256).Hash
  Invoke-ExpectExit 'same-date-identical-rerun' $archiveScript @('-RegressionTest','-SourceDatePath',$source,'-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveRoot',$archiveRoot) 0
  $indexHashAfter = (Get-FileHash -LiteralPath (Join-Path $archiveRoot 'index.md') -Algorithm SHA256).Hash
  Add-Result 'index-deterministic-idempotent' ($indexHashBefore -ceq $indexHashAfter) ("before=$indexHashBefore after=$indexHashAfter")

  $postAdoption = Join-Path $archiveRoot '2040\2040-01-03'
  Write-Text (Join-Path $postAdoption 'new-without-manifest.txt') 'must fail'
  Invoke-ExpectExit 'post-adoption-missing-manifest' $archiveScript @('-RegressionTest','-SourceDatePath',$source,'-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveRoot',$archiveRoot) 1
  Remove-Item -LiteralPath $postAdoption -Recurse -Force

  $unknownPreAdoption = Join-Path $archiveRoot '2026\2026-07-13'
  Write-Text (Join-Path $unknownPreAdoption 'unknown-pre-v2.txt') 'must fail'
  Invoke-ExpectExit 'unknown-pre-adoption-missing-manifest' $archiveScript @('-RegressionTest','-SourceDatePath',$source,'-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveRoot',$archiveRoot) 1
  Remove-Item -LiteralPath $unknownPreAdoption -Recurse -Force

  $malformedDate = Join-Path $archiveRoot '2040\2040-01-04'
  Write-Text (Join-Path $malformedDate 'archive-manifest.json') '{malformed'
  Invoke-ExpectExit 'new-date-malformed-manifest' $archiveScript @('-RegressionTest','-SourceDatePath',$source,'-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveRoot',$archiveRoot) 1
  Remove-Item -LiteralPath $malformedDate -Recurse -Force

  $legacyProbeDate = [string]@($archivePolicy.LegacyUnverifiedDates)[0]
  $legacyProbeDirectory = Join-Path $archiveRoot (Join-Path $legacyProbeDate.Substring(0,4) $legacyProbeDate)
  $legacyManifestProbe = Join-Path $legacyProbeDirectory 'archive-manifest.json'
  Write-Text $legacyManifestProbe '{"SchemaVersion":"APL Daily Archive Manifest v2.0","Status":"PASS"}'
  Invoke-ExpectExit 'legacy-date-fake-pass-forbidden' $archiveScript @('-RegressionTest','-SourceDatePath',$source,'-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveRoot',$archiveRoot) 1
  Remove-Item -LiteralPath $legacyManifestProbe -Force
  Write-Text $legacyManifestProbe '{"SchemaVersion":"APL Legacy Inventory v1.0","Status":"INVENTORY_ONLY"}'
  Invoke-ExpectExit 'legacy-inventory-not-v2-manifest' $archiveScript @('-RegressionTest','-SourceDatePath',$source,'-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveRoot',$archiveRoot) 1
  Remove-Item -LiteralPath $legacyManifestProbe -Force

  foreach ($case in @(
    @('missing-blog',"production-package\APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.md"),
    @('missing-company-analysis',"production-package\table-card-log\APL_Momentum_Leaders_Top_30_Company_Business_Analysis_$ScanDate.md"),
    @('missing-whatsapp',"APL_Momentum_Leaders_WhatsApp_Post_$ScanDate.txt")
  )) {
    $variant = Join-Path $TestRoot ("negative\" + $case[0] + "\$ScanDate")
    Copy-Fixture $source $variant
    Remove-Item -LiteralPath (Join-Path $variant $case[1]) -Force
    Invoke-ExpectExit $case[0] $auditScript @('-RegressionTest','-ProductionDatePath',$variant,'-ScanDate',$ScanDate,'-ContractPath',$contract,'-AuditOutputPath',(Join-Path $variant "Final_Production_Audit_$ScanDate.json")) 1
  }

  $baseManifest = Get-Content -Raw -Encoding UTF8 $manifestPath | ConvertFrom-Json
  $baseActual = @(Get-AplArchiveInventory $archiveDate -ExcludeManifest)
  function Expect-ManifestFailure([string]$Name, [object]$Candidate, [object[]]$CandidateActual = $baseActual) {
    try { Assert-AplArchiveManifest $Candidate $ScanDate 'PASS' $CandidateActual | Out-Null; Add-Result $Name $false 'not rejected' } catch { Add-Result $Name $true $_.Exception.Message }
  }
  $x=($baseManifest|ConvertTo-Json -Depth 10|ConvertFrom-Json);$x.SchemaVersion='BAD';Expect-ManifestFailure 'unsupported-schema-version' $x
  $x=($baseManifest|ConvertTo-Json -Depth 10|ConvertFrom-Json);$x.Files=@();Expect-ManifestFailure 'files-empty' $x
  $x=($baseManifest|ConvertTo-Json -Depth 10|ConvertFrom-Json);$x.Files=@($x.Files)+@($x.Files[0]);Expect-ManifestFailure 'duplicate-relative-path' $x
  $x=($baseManifest|ConvertTo-Json -Depth 10|ConvertFrom-Json);$x.Files=@($x.Files|Select-Object -Skip 1);Expect-ManifestFailure 'missing-manifest-record' $x
  $x=($baseManifest|ConvertTo-Json -Depth 10|ConvertFrom-Json);$x.Files[0].SHA256=('0'*64);Expect-ManifestFailure 'wrong-sha' $x
  $x=($baseManifest|ConvertTo-Json -Depth 10|ConvertFrom-Json);$x.Files[0].Size=[long]$x.Files[0].Size+1;Expect-ManifestFailure 'wrong-size' $x
  $extra=@($baseActual)+@([pscustomobject]@{RelativePath='extra.txt';Size=1;SHA256=('A'*64)});Expect-ManifestFailure 'extra-archive-file' $baseManifest $extra
  $missing=@($baseActual|Select-Object -Skip 1);Expect-ManifestFailure 'missing-archive-file' $baseManifest $missing

  try { Assert-AplScanDate '2026-99-99' | Out-Null; Add-Result 'invalid-calendar-date' $false 'not rejected' } catch { Add-Result 'invalid-calendar-date' $true }
  $badIndex = Join-Path $TestRoot 'bad-index.md'
  Write-Text $badIndex "| Date | Status | Files | Bytes | Manifest | Notes |`r`n|---|---|---:|---:|---|---|`r`n"
  try { Assert-AplArchiveIndexRow $badIndex $baseManifest $TestRoot | Out-Null; Add-Result 'index-row-missing' $false 'not rejected' } catch { Add-Result 'index-row-missing' $true }
  Write-Text $badIndex "| Date | Status | Files | Bytes | Manifest | Notes |`r`n|---|---|---:|---:|---|---|`r`n| $ScanDate | FAIL | 999 | 1 | wrong/path.json | wrong |`r`n"
  try { Assert-AplArchiveIndexRow $badIndex $baseManifest $TestRoot | Out-Null; Add-Result 'index-values-mismatch' $false 'not rejected' } catch { Add-Result 'index-values-mismatch' $true }
  Write-Text $badIndex "| Date | Status | Files | Bytes | Manifest | Notes |`r`n|---|---|---:|---:|---|---|`r`n| $ScanDate | PASS | 1 | 1 | x | V2 manifest verified |`r`n| $ScanDate | PASS | 1 | 1 | x | V2 manifest verified |`r`n"
  try { Get-AplArchiveIndexRow $badIndex $ScanDate $TestRoot | Out-Null; Add-Result 'duplicate-date-row' $false 'not rejected' } catch { Add-Result 'duplicate-date-row' $true }
  $legacyIndexDate = [string]@($archivePolicy.LegacyUnverifiedDates)[0]
  Write-Text $badIndex "| Date | Status | Files | Bytes | Manifest | Notes |`r`n|---|---|---:|---:|---|---|`r`n| $legacyIndexDate | PASS | 1 | 1 | N/A | Pre-v2 archive; inventory-only counts; integrity not attested |`r`n"
  try { Assert-AplLegacyArchiveIndexRow $badIndex $legacyIndexDate 1 1 $TestRoot | Out-Null; Add-Result 'legacy-index-mislabeled-pass' $false 'not rejected' } catch { Add-Result 'legacy-index-mislabeled-pass' $true }

  $conflictSource = Join-Path $TestRoot "conflict\$ScanDate"
  Copy-Fixture $source $conflictSource
  Write-Text (Join-Path $conflictSource "APL_Quant_Top_30_$ScanDate.md") '# changed conflict'
  Invoke-ExpectExit 'same-date-content-conflict' $archiveScript @('-RegressionTest','-SourceDatePath',$conflictSource,'-ScanDate',$ScanDate,'-FinalAuditPath',(Join-Path $conflictSource "Final_Production_Audit_$ScanDate.json"),'-ArchiveRoot',$archiveRoot) 1

  $linkTarget = Join-Path $TestRoot 'link-target'
  New-Item -ItemType Directory -Path $linkTarget -Force | Out-Null
  $junction = Join-Path $TestRoot 'junction'
  New-Item -ItemType Junction -Path $junction -Target $linkTarget | Out-Null
  try { Assert-AplNoReparsePath -Path $junction -AllowedRoot $TestRoot -RequireDirectory | Out-Null; Add-Result 'junction-escape' $false 'not rejected' } catch { Add-Result 'junction-escape' $true }
  $symlink = Join-Path $TestRoot 'symlink'
  try {
    New-Item -ItemType SymbolicLink -Path $symlink -Target $linkTarget -ErrorAction Stop | Out-Null
    try { Assert-AplNoReparsePath -Path $symlink -AllowedRoot $TestRoot -RequireDirectory | Out-Null; Add-Result 'symlink-escape' $false 'not rejected' } catch { Add-Result 'symlink-escape' $true }
  } catch { Add-Skip 'symlink-escape' ("fixture creation unavailable; junction reparse-point rejection remains authoritative: " + $_.Exception.Message) }

  $logs = Join-Path $TestRoot 'logs'
  New-Item -ItemType Directory -Path $logs -Force | Out-Null
  $pipelineLog=Join-Path $logs 'pipeline.log';$pipelineTrace=Join-Path $logs 'pipeline.jsonl';Write-Text $pipelineLog 'start';Write-Text $pipelineTrace 'start'
  $state=Join-Path $logs 'state.json'
  Invoke-ExpectExit 'final-log-write-failure' $completionScript @('-RegressionTest','-TestFailFinalLog','-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveManifestPath',$manifestPath,'-ArchiveIndexPath',(Join-Path $archiveRoot 'index.md'),'-PipelineLog',$pipelineLog,'-PipelineTrace',$pipelineTrace,'-StatePath',$state) 1
  Add-Result 'failed-finalization-no-pass-state' (-not (Test-Path -LiteralPath $state))
  Invoke-ExpectExit 'finalization-rerun' $completionScript @('-RegressionTest','-ScanDate',$ScanDate,'-FinalAuditPath',$audit,'-ArchiveManifestPath',$manifestPath,'-ArchiveIndexPath',(Join-Path $archiveRoot 'index.md'),'-PipelineLog',$pipelineLog,'-PipelineTrace',$pipelineTrace,'-StatePath',$state) 0
  $stateJson=Get-Content -Raw -Encoding UTF8 $state|ConvertFrom-Json;Add-Result 'authoritative-final-state' ([string]$stateJson.Status -eq 'PASS' -and $stateJson.DailyProductionComplete -eq $true)

  foreach ($file in @('tools\production_archive_common.ps1','tools\test_production_artifact_contract.ps1','tools\archive_daily_production.ps1','tools\complete_daily_production.ps1','tools\run_daily_production.ps1')) {
    $tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $ProjectRoot $file),[ref]$tokens,[ref]$errors);Add-Result ("ps51-ast-"+$file.Replace('\','-')) ($errors.Count -eq 0) (($errors|ForEach-Object{$_.Message}) -join '; ')
  }
} finally {
  $failed=@($results.ToArray()|Where-Object{-not $_.Passed})
  $skipped=@($results.ToArray()|Where-Object{$_.Skipped})
  $summary=[ordered]@{ Passed=($failed.Count -eq 0); Total=$results.Count; Failed=$failed.Count; Skipped=$skipped.Count; Results=[object[]]$results.ToArray() }
  $summary | ConvertTo-Json -Depth 6
}
if (@($results.ToArray()|Where-Object{-not $_.Passed}).Count -gt 0) { exit 1 }
