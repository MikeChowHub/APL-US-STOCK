param(
  [Parameter(Mandatory = $true)]
  [string]$InputCsv,

  [Parameter(Mandatory = $true)]
  [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
  [string]$ScanDate,

  [Parameter(Mandatory = $true)]
  [string]$WeekLabel,

  [string]$OutputRoot = '',
  [string]$SectorMapPath = '',
  [string]$LogoPath = '',

  [Parameter(Mandatory = $true)]
  [string]$TableCardInputPath,

  [Parameter(Mandatory = $true)]
  [ValidateSet('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure','MarketObservation','Comparison')]
  [string]$TableCardType,

  [string]$TableCardOutputName = '',

  [Parameter(Mandatory = $true)]
  [string]$CoverBriefPath,

  [Parameter(Mandatory = $true)]
  [string]$CoverBackgroundPath,

  [switch]$RegressionTest
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')

if ((Get-AplFullPath $ProjectRoot) -ne (Get-AplFullPath $script:AplProjectRoot)) { throw 'Project Root resolution failed.' }
$gitRoot = (& git -C $ProjectRoot rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$gitRoot)) { throw "Git Root not found for Project Root: $ProjectRoot" }
if ((Get-AplFullPath ([string]$gitRoot)) -ne (Get-AplFullPath $ProjectRoot)) { throw "Project Root/Git Root mismatch. Project='$ProjectRoot'; Git='$gitRoot'." }

function Test-PathInside([string]$Path, [string]$Parent) {
  $fullPath = (Get-AplFullPath $Path).TrimEnd('\')
  $fullParent = (Get-AplFullPath $Parent).TrimEnd('\')
  return ($fullPath.Equals($fullParent, [System.StringComparison]::OrdinalIgnoreCase) -or $fullPath.StartsWith($fullParent + '\', [System.StringComparison]::OrdinalIgnoreCase))
}

function Assert-InputFile([string]$Path, [string]$Label) {
  $full = Assert-AplProductionPath (Get-AplFullPath $Path) $Label -RegressionTest:$RegressionTest
  if (!(Test-Path -LiteralPath $full -PathType Leaf)) { throw "$Label not found: $full" }
  return $full
}

function Assert-NewArtifact([string]$Path, [string]$Label) {
  $full = Assert-AplProductionPath (Get-AplFullPath $Path) $Label -RegressionTest:$RegressionTest
  if (Test-Path -LiteralPath $full) { throw "$Label already exists; production pipeline will not overwrite it: $full" }
  return $full
}

function Write-Utf8Text([string]$Path, [string]$Text) {
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.Encoding]::UTF8)
}

$InputCsv = Assert-InputFile $InputCsv 'InputCsv'
$TableCardInputPath = Assert-InputFile $TableCardInputPath 'TableCardInputPath'
$CoverBriefPath = Assert-InputFile $CoverBriefPath 'CoverBriefPath'
$CoverBackgroundPath = Assert-InputFile $CoverBackgroundPath 'CoverBackgroundPath'
if ([string]::IsNullOrWhiteSpace($SectorMapPath)) { $SectorMapPath = Join-Path $ProjectRoot 'tools\sector_map.json' }
$SectorMapPath = Assert-InputFile $SectorMapPath 'SectorMapPath'
if ([string]::IsNullOrWhiteSpace($LogoPath)) { $LogoPath = Join-Path $ProjectRoot 'outputs\APL_Deep_Scan_Brand_Logo_Renderer_Clean_2026-06-28.png' }
$LogoPath = Assert-InputFile $LogoPath 'LogoPath'

if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Join-Path $ProjectRoot 'outputs' }
$OutputRoot = Assert-AplProductionPath (Get-AplFullPath $OutputRoot) 'OutputRoot' -RegressionTest:$RegressionTest
$formalOutputRoot = Get-AplFullPath (Join-Path $ProjectRoot 'outputs')
$regressionRoot = Get-AplFullPath (Join-Path $ProjectRoot 'tmp')
if ($RegressionTest) {
  if (-not (Test-PathInside $OutputRoot $regressionRoot)) { throw "RegressionTest OutputRoot must be inside '$regressionRoot'." }
} elseif (-not $OutputRoot.Equals($formalOutputRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Production OutputRoot must be '$formalOutputRoot'."
}

$publishRoot = $OutputRoot
$finalDateOut = Join-Path $publishRoot $ScanDate
$runId = '{0}-{1}' -f $ScanDate, ([datetime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
$runMutex = Enter-AplNamedMutex ("orchestrator|$publishRoot|$ScanDate") 'Daily production pipeline'
try { $publishScoringMutex = Enter-AplNamedMutex ("scoring|$publishRoot|$ScanDate") 'Published scoring namespace' }
catch { Exit-AplNamedMutex $runMutex; throw }
$OutputRoot = Join-Path $publishRoot ".staging\$runId"
$dateOut = Join-Path $OutputRoot $ScanDate
$logsRoot = Join-Path $publishRoot 'logs'
$safeTableType = $TableCardType -replace '[^A-Za-z0-9_-]', '_'
if ([string]::IsNullOrWhiteSpace($TableCardOutputName)) { $TableCardOutputName = "APL_Blog_${safeTableType}_${ScanDate}.png" }
if ([System.IO.Path]::IsPathRooted($TableCardOutputName) -or [System.IO.Path]::GetFileName($TableCardOutputName) -cne $TableCardOutputName) { throw 'TableCardOutputName must be a file name without directory or traversal segments.' }

$rankingCsv = Join-Path $dateOut "APL_Momentum_Score_Full_Ranking_$ScanDate.csv"
$topTxt = Join-Path $dateOut "APL_Quant_Top_30_$ScanDate.txt"
$topMd = Join-Path $dateOut "APL_Quant_Top_30_$ScanDate.md"
$watchlistTxt = Join-Path $dateOut "APL_Quant_Cumulative_Watchlist_$ScanDate.txt"
$removedAudit = Join-Path $dateOut "removed-below-sma200-$ScanDate.txt"
$retainedAudit = Join-Path $dateOut "retained-missing-sma200-$ScanDate.txt"
$overviewMd = Join-Path $dateOut "APL_Momentum_Leaders_Overview_$ScanDate.md"
$metaJson = Join-Path $dateOut "APL_Momentum_Leaders_Meta_$ScanDate.json"
$sourceCopy = Join-Path $dateOut "APL_Momentum_Leaders_Source_$ScanDate.csv"
$dashboardContract = Join-Path $dateOut "APL_DeepScan_Dashboard_Input_$ScanDate.json"
$socialContract = Join-Path $dateOut "APL_DeepScan_Social_Input_$ScanDate.json"
$dashboardSvg = Join-Path $dateOut "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_1920x1080.svg"
$dashboardLog = Join-Path $dateOut "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_Render_Log.txt"
$socialSvg = Join-Path $dateOut "APL_DeepScan_Social_Card_${ScanDate}_1080x1350.svg"
$socialLog = Join-Path $dateOut "APL_DeepScan_Social_Card_${ScanDate}_Render_Log.txt"
$tableCardOutput = Join-Path $dateOut $TableCardOutputName
$tableCardLog = [System.IO.Path]::ChangeExtension($tableCardOutput, '.table-card-log.txt')
$coverOutput = Join-Path $dateOut "APL_Momentum_Leaders_Blog_Cover_${ScanDate}_1080x1350.png"
$coverLog = [System.IO.Path]::ChangeExtension($coverOutput, '.overlay-log.txt')
$seoOutput = Join-Path $dateOut "APL_Momentum_Leaders_Blog_SEO_${ScanDate}_1280x720.png"
$seoLog = [System.IO.Path]::ChangeExtension($seoOutput, '.overlay-log.txt')

$rootCopies = @()
$expectedArtifacts = @($rankingCsv,$topTxt,$topMd,$watchlistTxt,$removedAudit,$retainedAudit,$overviewMd,$metaJson,$sourceCopy,$dashboardContract,$socialContract,$dashboardSvg,$dashboardLog,$socialSvg,$socialLog,$tableCardOutput,$tableCardLog,$coverOutput,$coverLog,$seoOutput,$seoLog) + $rootCopies
function Get-PublishedPath([string]$StagePath) {
  $full = Get-AplFullPath $StagePath
  if ($full.StartsWith($dateOut.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return Join-Path $finalDateOut $full.Substring($dateOut.TrimEnd('\').Length + 1) }
  if ($full.StartsWith($OutputRoot.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return Join-Path $publishRoot $full.Substring($OutputRoot.TrimEnd('\').Length + 1) }
  throw "Cannot map staging artifact to publish path: $full"
}
foreach ($artifact in $expectedArtifacts) { Assert-NewArtifact (Get-PublishedPath $artifact) 'Expected published artifact' | Out-Null }

if (!(Test-Path -LiteralPath $OutputRoot)) { New-Item -ItemType Directory -Path $OutputRoot | Out-Null }
if (!(Test-Path -LiteralPath $logsRoot)) { New-Item -ItemType Directory -Path $logsRoot | Out-Null }
$pipelineLog = Assert-NewArtifact (Join-Path $logsRoot "daily-production-$runId.log") 'PipelineLog'
$tracePath = Assert-NewArtifact (Join-Path $logsRoot "daily-production-$runId.jsonl") 'PipelineTrace'
$script:stepNumber = 0
$script:completedArtifacts = New-Object System.Collections.Generic.List[string]

function Add-Trace([hashtable]$Record) {
  $line = ([pscustomobject]$Record | ConvertTo-Json -Compress -Depth 6)
  [System.IO.File]::AppendAllText($tracePath, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
}

function Add-Log([string]$Message) {
  $line = '[{0}] {1}' -f ([datetime]::UtcNow.ToString('o')), $Message
  [System.IO.File]::AppendAllText($pipelineLog, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
}

function Invoke-PipelineStep {
  param([string]$Name, [string]$ScriptPath, [string[]]$Arguments, [string[]]$Artifacts = @())
  $script:stepNumber++
  $started = [datetime]::UtcNow
  Add-Log "STEP $script:stepNumber START $Name"
  Add-Trace @{ step=$script:stepNumber; name=$Name; event='start'; utc=$started.ToString('o'); script=$ScriptPath; arguments=$Arguments }
  try {
    $output = @(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    foreach ($line in $output) { Add-Log "[$Name] $line" }
    if ($exitCode -ne 0) { throw "Step '$Name' failed with exit code $exitCode." }
    foreach ($artifact in $Artifacts) {
      if (!(Test-Path -LiteralPath $artifact -PathType Leaf)) { throw "Step '$Name' did not create required artifact: $artifact" }
      if ((Get-Item -LiteralPath $artifact).Length -le 0) { throw "Step '$Name' created empty artifact: $artifact" }
      $script:completedArtifacts.Add($artifact)
    }
    $ended = [datetime]::UtcNow
    Add-Trace @{ step=$script:stepNumber; name=$Name; event='complete'; utc=$ended.ToString('o'); durationMs=[math]::Round(($ended-$started).TotalMilliseconds); artifacts=$Artifacts }
    Add-Log "STEP $script:stepNumber PASS $Name"
  } catch {
    $ended = [datetime]::UtcNow
    Add-Trace @{ step=$script:stepNumber; name=$Name; event='failed'; utc=$ended.ToString('o'); durationMs=[math]::Round(($ended-$started).TotalMilliseconds); error=$_.Exception.Message }
    Add-Log "STEP $script:stepNumber FAIL $Name :: $($_.Exception.Message)"
    throw
  }
}

function Complete-InternalStep([string]$Name, [scriptblock]$Action, [string[]]$Artifacts = @()) {
  $script:stepNumber++
  $started = [datetime]::UtcNow
  Add-Log "STEP $script:stepNumber START $Name"
  Add-Trace @{ step=$script:stepNumber; name=$Name; event='start'; utc=$started.ToString('o'); internal=$true }
  try {
    & $Action
    foreach ($artifact in $Artifacts) {
      if (!(Test-Path -LiteralPath $artifact -PathType Leaf) -or (Get-Item -LiteralPath $artifact).Length -le 0) { throw "Internal step '$Name' missing required artifact: $artifact" }
      $script:completedArtifacts.Add($artifact)
    }
    $ended = [datetime]::UtcNow
    Add-Trace @{ step=$script:stepNumber; name=$Name; event='complete'; utc=$ended.ToString('o'); durationMs=[math]::Round(($ended-$started).TotalMilliseconds); artifacts=$Artifacts }
    Add-Log "STEP $script:stepNumber PASS $Name"
  } catch {
    $ended = [datetime]::UtcNow
    Add-Trace @{ step=$script:stepNumber; name=$Name; event='failed'; utc=$ended.ToString('o'); error=$_.Exception.Message }
    Add-Log "STEP $script:stepNumber FAIL $Name :: $($_.Exception.Message)"
    throw
  }
}

$processScript = Join-Path $PSScriptRoot 'process_apl_momentum_leaders.ps1'
$validatorScript = Join-Path $PSScriptRoot 'validate_renderer_inputs.ps1'
$dashboardScript = Join-Path $PSScriptRoot 'render_deep_scan_dashboard_svg.ps1'
$socialScript = Join-Path $PSScriptRoot 'render_deep_scan_social_card_svg.ps1'
$tableScript = Join-Path $PSScriptRoot 'render_blog_table_cards.ps1'
$overlayScript = Join-Path $PSScriptRoot 'render_blog_cover_overlay.ps1'

$status = 'FAILED'
try {
  Add-Log "RUN START $runId ProjectRoot=$ProjectRoot GitRoot=$gitRoot PublishRoot=$publishRoot StagingRoot=$OutputRoot RegressionTest=$([bool]$RegressionTest)"
  $scoringRegressionArg = if ($RegressionTest) { @('-RegressionTest') } else { @() }
  Invoke-PipelineStep 'ScoringRanking' $processScript (@('-InputCsv',$InputCsv,'-ScanDate',$ScanDate,'-WeekLabel',$WeekLabel,'-OutputRoot',$OutputRoot,'-SkipRootCopies') + $scoringRegressionArg) @($rankingCsv,$topTxt,$topMd,$overviewMd,$metaJson,$sourceCopy)
  Complete-InternalStep 'WatchlistSma200Audit' {
    foreach ($path in @($watchlistTxt,$removedAudit,$retainedAudit)) { if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Audit artifact missing: $path" } }
    $meta = Read-AplUtf8Json $metaJson
    foreach ($name in @('removedBelowSma200Count','retainedMissingSma200Count','finalWatchlistCount')) { if ($null -eq $meta.PSObject.Properties[$name]) { throw "Scoring metadata missing '$name'." } }
    $watchlistRaw = [System.IO.File]::ReadAllText($watchlistTxt, [System.Text.Encoding]::UTF8).Trim()
    $watchlistSymbols = if ([string]::IsNullOrWhiteSpace($watchlistRaw)) { @() } else { @($watchlistRaw.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) }
    $removedLines = @([System.IO.File]::ReadAllLines($removedAudit, [System.Text.Encoding]::UTF8))
    $retainedLines = @([System.IO.File]::ReadAllLines($retainedAudit, [System.Text.Encoding]::UTF8))
    $removedCount = [math]::Max(0, $removedLines.Count - 1)
    $retainedCount = [math]::Max(0, $retainedLines.Count - 1)
    if ($watchlistSymbols.Count -ne [int]$meta.finalWatchlistCount) { throw "Watchlist count mismatch. File=$($watchlistSymbols.Count); Meta=$($meta.finalWatchlistCount)." }
    if ($removedCount -ne [int]$meta.removedBelowSma200Count) { throw "Removed SMA200 audit count mismatch. File=$removedCount; Meta=$($meta.removedBelowSma200Count)." }
    if ($retainedCount -ne [int]$meta.retainedMissingSma200Count) { throw "Retained missing SMA200 audit count mismatch. File=$retainedCount; Meta=$($meta.retainedMissingSma200Count)." }
    $removedSymbols = @($removedLines | Select-Object -Skip 1 | ForEach-Object { ($_ -split ',', 2)[0].Trim() })
    $unexpected = @($removedSymbols | Where-Object { $watchlistSymbols -contains $_ })
    if ($unexpected.Count -gt 0) { throw "Below-SMA200 symbols remain in watchlist: $($unexpected -join ',')." }
    $retainedSymbols = @($retainedLines | Select-Object -Skip 1 | ForEach-Object { ($_ -split ',', 2)[0].Trim() })
    $missingRetained = @($retainedSymbols | Where-Object { $watchlistSymbols -notcontains $_ })
    if ($missingRetained.Count -gt 0) { throw "Missing-SMA200 symbols were not retained in watchlist: $($missingRetained -join ',')." }
  } @($watchlistTxt,$removedAudit,$retainedAudit)

  Complete-InternalStep 'BuildRendererContracts' {
    $meta = Read-AplUtf8Json $metaJson
    $common = [ordered]@{ SchemaVersion='APL Deep-Scan Renderer Input v1.0'; RankingCsv=$rankingCsv; ScanDate=$ScanDate; SectorMapPath=$SectorMapPath; OutputPath=$dateOut; LogoPath=$LogoPath; WeekLabel=$WeekLabel; ScanUniverseCount=[int]$meta.universe; ScanQualifiedCount=[int]$meta.qualified; LeaderCapacity=30; Meta=[ordered]@{ ProductionMode='Deep-Scan Research Mode'; ProductionNote="run_daily_production $runId" } }
    $dashboard = [ordered]@{}; foreach ($key in $common.Keys) { $dashboard[$key]=$common[$key] }; $dashboard.RendererType='Dashboard'
    $social = [ordered]@{}; foreach ($key in $common.Keys) { $social[$key]=$common[$key] }; $social.RendererType='Social'
    Write-Utf8Text $dashboardContract (($dashboard | ConvertTo-Json -Depth 6))
    Write-Utf8Text $socialContract (($social | ConvertTo-Json -Depth 6))
  } @($dashboardContract,$socialContract)

  $regressionArg = if ($RegressionTest) { @('-RegressionTest') } else { @() }
  Invoke-PipelineStep 'ValidateDashboardInput' $validatorScript (@('-RendererType','Dashboard','-InputPath',$dashboardContract) + $regressionArg)
  Invoke-PipelineStep 'ValidateSocialInput' $validatorScript (@('-RendererType','Social','-InputPath',$socialContract) + $regressionArg)
  Invoke-PipelineStep 'RenderDashboard' $dashboardScript (@('-InputPath',$dashboardContract) + $regressionArg) @($dashboardSvg,$dashboardLog)
  Invoke-PipelineStep 'RenderSocialCard' $socialScript (@('-InputPath',$socialContract) + $regressionArg) @($socialSvg,$socialLog)
  Invoke-PipelineStep 'ValidateTableCardInput' $validatorScript (@('-RendererType','TableCard','-TableCardInputPath',$TableCardInputPath,'-CardType',$TableCardType) + $regressionArg)
  Invoke-PipelineStep 'RenderTableCard' $tableScript (@('-CardType',$TableCardType,'-OutDir',$dateOut,'-Date',$ScanDate,'-InputPath',$TableCardInputPath,'-OutputName',$TableCardOutputName) + $regressionArg) @($tableCardOutput,$tableCardLog)
  Invoke-PipelineStep 'RenderCoverOverlay' $overlayScript @('-BriefPath',$CoverBriefPath,'-BackgroundPath',$CoverBackgroundPath,'-OutputPath',$coverOutput,'-Variant','Cover','-LogoPath',$LogoPath) @($coverOutput,$coverLog)
  Invoke-PipelineStep 'RenderSeoOverlay' $overlayScript @('-BriefPath',$CoverBriefPath,'-BackgroundPath',$CoverBackgroundPath,'-OutputPath',$seoOutput,'-Variant','SEO','-LogoPath',$LogoPath) @($seoOutput,$seoLog)
  Complete-InternalStep 'PublishArtifacts' {
    foreach ($contractPath in @($dashboardContract,$socialContract)) {
      $contract = Read-AplUtf8Json $contractPath
      $contract.RankingCsv = Join-Path $finalDateOut (Split-Path $rankingCsv -Leaf)
      $contract.OutputPath = $finalDateOut
      Write-Utf8Text $contractPath ($contract | ConvertTo-Json -Depth 6)
    }
    $publishedMeta = Read-AplUtf8Json $metaJson
    $publishedMeta.fullRankingCsv = Join-Path $finalDateOut (Split-Path $rankingCsv -Leaf)
    $publishedMeta.top30Txt = Join-Path $finalDateOut (Split-Path $topTxt -Leaf)
    Write-Utf8Text $metaJson ($publishedMeta | ConvertTo-Json -Depth 6)
    foreach ($path in @($dashboardLog,$socialLog,$tableCardLog,$coverLog,$seoLog)) {
      $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
      $text = $text.Replace($dateOut, $finalDateOut).Replace($OutputRoot, $publishRoot)
      Write-Utf8Text $path $text
    }
    if (Test-Path -LiteralPath $finalDateOut) { throw "Final date output appeared during staging: $finalDateOut" }
    Move-Item -LiteralPath $dateOut -Destination $finalDateOut
  } @()
  $status = 'PASS'
  $publishedPaths = @($script:completedArtifacts | Where-Object { Test-PathInside $_ $OutputRoot } | ForEach-Object { Get-PublishedPath $_ } | Sort-Object -Unique)
  $publishedArtifacts = @($publishedPaths | ForEach-Object { $item=Get-Item -LiteralPath $_; [ordered]@{ path=$item.FullName; bytes=$item.Length; sha256=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash } })
  Add-Trace @{ event='run-complete'; runId=$runId; utc=[datetime]::UtcNow.ToString('o'); status=$status; artifacts=$publishedArtifacts; pipelineLog=$pipelineLog; pipelineTrace=$tracePath }
  Add-Log "RUN PASS $runId"
  Exit-AplNamedMutex $publishScoringMutex
  Exit-AplNamedMutex $runMutex
} catch {
  Add-Trace @{ event='run-complete'; runId=$runId; utc=[datetime]::UtcNow.ToString('o'); status=$status; error=$_.Exception.Message; artifacts=@($script:completedArtifacts) }
  Add-Log "RUN FAILED $runId :: $($_.Exception.Message)"
  Exit-AplNamedMutex $publishScoringMutex
  Exit-AplNamedMutex $runMutex
  Write-Error $_
  exit 1
}

[pscustomobject]@{ RunId=$runId; Status=$status; ProjectRoot=$ProjectRoot; OutputRoot=$publishRoot; DateOutput=$finalDateOut; PipelineLog=$pipelineLog; PipelineTrace=$tracePath; ArtifactCount=$publishedArtifacts.Count }
