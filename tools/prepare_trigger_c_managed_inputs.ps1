[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][ValidateSet('Initialize','Supersede','Finalize','Status')][string]$Mode,
  [Parameter(Mandatory=$true)][string]$ScanDate,
  [string]$WeekLabel='',
  [string]$InputCsv='',
  [string]$TopGainersCsvPath='',
  [string]$MarketContextPath='',
  [switch]$RegressionTest
)

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')

function Assert-InputFile([string]$Path,[string]$Label){
  if([string]::IsNullOrWhiteSpace($Path)){throw "$Label is required for Initialize or Supersede."}
  $full=Get-AplFullPath $Path
  if(!(Test-Path -LiteralPath $full -PathType Leaf)){throw "$Label not found: $full"}
  $parent=Split-Path $full -Parent
  return Assert-AplNoReparsePath -Path $full -AllowedRoot $parent -RequireFile
}

function Assert-ApprovedMarketContext([string]$Path){
  $text=[IO.File]::ReadAllText($Path,[Text.Encoding]::UTF8)
  $matches=@([regex]::Matches($text,'(?m)^\s*本期核心市場命題(?:是)?\s*[：:]\s*(.+?)\s*$'))
  if($matches.Count-ne1){throw 'Approved Market Context must declare exactly one 本期核心市場命題 editorial-control line.'}
  $thesis=$matches[0].Groups[1].Value.Trim()
  if($thesis.Length-lt40){throw 'Approved Market Context 本期核心市場命題 must be substantive.'}
  return $thesis
}

function Write-Utf8([string]$Path,[string]$Text,[string]$AllowedRoot){
  Write-AplUtf8Atomic $Path $Text $AllowedRoot|Out-Null
}

function Get-Record([string]$Path,[string]$Role,[string]$Root){
  $item=Get-Item -LiteralPath $Path
  return [pscustomobject][ordered]@{
    Role=$Role
    RelativePath=$item.FullName.Substring($Root.TrimEnd('\').Length+1).Replace('\','/')
    Bytes=[long]$item.Length
    SHA256=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
  }
}

function Assert-Record([object]$Record,[string]$Root){
  $path=Assert-AplNoReparsePath -Path (Join-Path $Root ([string]$Record.RelativePath).Replace('/','\')) -AllowedRoot $Root -RequireFile
  $item=Get-Item -LiteralPath $path
  if([long]$item.Length-ne[long]$Record.Bytes-or(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash-cne[string]$Record.SHA256){throw "Trigger C preparation source integrity mismatch: $($Record.Role)"}
  return $path
}

Assert-AplScanDate $ScanDate|Out-Null
$gitRoot=(& git -C $ProjectRoot rev-parse --show-toplevel 2>$null)
if($LASTEXITCODE-ne0-or[string]::IsNullOrWhiteSpace([string]$gitRoot)-or(Get-AplFullPath ([string]$gitRoot))-ne(Get-AplFullPath $ProjectRoot)){throw 'Project Root/Git Root mismatch.'}

$regressionRoot=Get-AplFullPath (Join-Path $ProjectRoot 'tmp\trigger-c-managed-input-builder')
$formalWorkRoot=Get-AplFullPath (Join-Path $ProjectRoot 'work')
$stagingParent=if($RegressionTest){Join-Path $regressionRoot 'staging'}else{Join-Path $formalWorkRoot '.staging\trigger-c'}
$managedParent=if($RegressionTest){Join-Path $regressionRoot 'managed-inputs'}else{Join-Path $formalWorkRoot 'managed-inputs'}
foreach($root in @($stagingParent,$managedParent)){if(!(Test-Path -LiteralPath $root)){New-Item -ItemType Directory -Path $root -Force|Out-Null}}
$allowedContainer=if($RegressionTest){$regressionRoot}else{$formalWorkRoot}
$stagingParent=Assert-AplNoReparsePath -Path $stagingParent -AllowedRoot $allowedContainer -RequireDirectory
$managedParent=Assert-AplNoReparsePath -Path $managedParent -AllowedRoot $allowedContainer -RequireDirectory
$stagingDate=Join-Path $stagingParent $ScanDate
$managedDate=Join-Path $managedParent $ScanDate
$statePath=Join-Path $stagingDate 'trigger-c-preparation.json'

if($Mode-ceq'Status'){
  if(Test-Path -LiteralPath $managedDate -PathType Container){[pscustomobject]@{Status='FINALIZED';ScanDate=$ScanDate;ManagedInputsRoot=$managedDate};exit 0}
  if(!(Test-Path -LiteralPath $statePath -PathType Leaf)){throw "Trigger C preparation state not found: $statePath"}
  $state=Read-AplStrictJson $statePath $stagingDate
  [pscustomobject]@{Status=[string]$state.Status;ScanDate=$ScanDate;StagingRoot=$stagingDate;ManagedInputsRoot=$managedDate;WorkOrder=$state.WorkOrder}
  exit 0
}

if($Mode-ceq'Initialize'-or$Mode-ceq'Supersede'){
  if([string]::IsNullOrWhiteSpace($WeekLabel)){throw 'WeekLabel is required for Initialize or Supersede.'}
  if(Test-Path -LiteralPath $managedDate){throw "Managed input bundle already exists; refusing overwrite: $managedDate"}
  $InputCsv=Assert-InputFile $InputCsv 'InputCsv'
  $TopGainersCsvPath=Assert-InputFile $TopGainersCsvPath 'TopGainersCsvPath'
  $MarketContextPath=Assert-InputFile $MarketContextPath 'MarketContextPath'
  $coreMarketThesis=Assert-ApprovedMarketContext $MarketContextPath
  $supersededStaging=''
  if($Mode-ceq'Initialize'){
    if(Test-Path -LiteralPath $stagingDate){throw "Trigger C preparation staging already exists; refusing overwrite: $stagingDate"}
  }else{
    $existingStaging=Assert-AplNoReparsePath -Path $stagingDate -AllowedRoot $stagingParent -RequireDirectory
    $existingStatePath=Join-Path $existingStaging 'trigger-c-preparation.json'
    if(!(Test-Path -LiteralPath $existingStatePath -PathType Leaf)){throw "Supersede requires a builder-owned staging state: $existingStatePath"}
    $existingState=Read-AplStrictJson $existingStatePath $existingStaging
    if([string]$existingState.SchemaVersion-cne'APL Trigger C Preparation v1.0'-or[string]$existingState.ScanDate-cne$ScanDate){throw 'Supersede requires a matching Trigger C preparation state.'}
    $rejectedParent=Join-Path $stagingParent 'rejected'
    if(!(Test-Path -LiteralPath $rejectedParent)){New-Item -ItemType Directory -Path $rejectedParent -Force|Out-Null}
    $rejectedParent=Assert-AplNoReparsePath -Path $rejectedParent -AllowedRoot $stagingParent -RequireDirectory
    $supersededStaging=Join-Path $rejectedParent ("$ScanDate-"+[datetime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8))
    Move-Item -LiteralPath $existingStaging -Destination $supersededStaging
  }

  $buildRoot=Join-Path $stagingParent ('.build-'+[guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $buildRoot|Out-Null
  $buildDate=Join-Path $buildRoot $ScanDate
  New-Item -ItemType Directory -Path $buildDate|Out-Null
  $scoringRoot=if($RegressionTest){Join-Path $regressionRoot ('scoring-'+[guid]::NewGuid().ToString('N'))}else{Join-Path $ProjectRoot ('outputs\.staging\trigger-c-prep-'+[guid]::NewGuid().ToString('N'))}
  try{
    $sourcePath=Join-Path $buildDate 'source.csv'
    $gainersPath=Join-Path $buildDate 'top-gainers.csv'
    $marketPath=Join-Path $buildDate 'market-context.md'
    Copy-Item -LiteralPath $InputCsv -Destination $sourcePath
    Copy-Item -LiteralPath $TopGainersCsvPath -Destination $gainersPath
    Copy-Item -LiteralPath $MarketContextPath -Destination $marketPath
    foreach($pair in @(@($InputCsv,$sourcePath),@($TopGainersCsvPath,$gainersPath),@($MarketContextPath,$marketPath))){if((Get-FileHash -LiteralPath $pair[0] -Algorithm SHA256).Hash-cne(Get-FileHash -LiteralPath $pair[1] -Algorithm SHA256).Hash){throw "Trigger C intake copy integrity mismatch: $($pair[1])"}}

    $scoreArgs=@('-InputCsv',$sourcePath,'-ScanDate',$ScanDate,'-WeekLabel',$WeekLabel,'-OutputRoot',$scoringRoot,'-SkipRootCopies')
    if($RegressionTest){$scoreArgs+='-RegressionTest'}
    $scoreOutput=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'process_apl_momentum_leaders.ps1') @scoreArgs 2>&1)
    if($LASTEXITCODE-ne0){throw "Trigger B preparation failed: $($scoreOutput-join' ')"}
    $scoreDate=Assert-AplNoReparsePath -Path (Join-Path $scoringRoot $ScanDate) -AllowedRoot $scoringRoot -RequireDirectory
    $triggerDestination=Join-Path $buildDate "trigger-b\$ScanDate"
    New-Item -ItemType Directory -Path (Split-Path $triggerDestination -Parent) -Force|Out-Null
    Copy-Item -LiteralPath $scoreDate -Destination $triggerDestination -Recurse
    $rankingPath=Join-Path $triggerDestination "APL_Momentum_Score_Full_Ranking_$ScanDate.csv"
    $metaPath=Join-Path $triggerDestination "APL_Momentum_Leaders_Meta_$ScanDate.json"
    $top30Path=Join-Path $triggerDestination "APL_Quant_Top_30_$ScanDate.txt"
    foreach($path in @($rankingPath,$metaPath,$top30Path)){if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Trigger B preparation artifact missing: $path"}}
    $meta=Read-AplStrictJson $metaPath $triggerDestination
    $meta.fullRankingCsv=(Split-Path $rankingPath -Leaf)
    $meta.top30Txt=(Split-Path $top30Path -Leaf)
    Write-Utf8 $metaPath ($meta|ConvertTo-Json -Depth 6) $buildDate

    foreach($directory in @('table-cards','publishing\production-package\table-card-log')){New-Item -ItemType Directory -Path (Join-Path $buildDate $directory) -Force|Out-Null}
    $workOrder=[ordered]@{
      Rule='Complete issue-specific content; do not create placeholders or copy template instructions.'
      TableCardManifest='table-card-manifest.json'
      TableCardInputs=[ordered]@{
        ExecutiveSummary='table-cards/ExecutiveSummary.json'
        TopLeaders='table-cards/TopLeaders.json'
        TopGainers='table-cards/TopGainers.json'
        SectorStructure='table-cards/SectorStructure.json'
      }
      PublishingArtifacts=[ordered]@{
        BlogMarkdown="publishing/production-package/APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.md"
        BlogHtmlSource="publishing/production-package/APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.html.txt"
        WhatsApp="publishing/production-package/WhatsApp_$ScanDate.md"
        CompanyBusinessAnalysis="publishing/production-package/table-card-log/APL_Momentum_Leaders_Top_30_Company_Business_Analysis_$ScanDate.md"
      }
      NativeAssets=[ordered]@{
        CoverBrief='cover-brief.json'
        CoverBriefSchema='tools/cover_image_brief.schema.json'
        RequiredCoverBriefVersion='APL Cover Brief v1.1'
        RequiredCoverBriefScanDate=$ScanDate
        RequiredCoreMarketThesis=$coreMarketThesis
        CoverBackground='cover-background.png'
        SeoBackground='seo-background.png'
        CoverNativeContract='cover-native-contract.json'
        SeoNativeContract='seo-native-contract.json'
      }
      FinalizeCommand="powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\tools\prepare_trigger_c_managed_inputs.ps1 -Mode Finalize -ScanDate $ScanDate"
    }
    $records=@(
      (Get-Record $sourcePath 'cumulative-screener' $buildDate),
      (Get-Record $gainersPath 'top-gainers' $buildDate),
      (Get-Record $marketPath 'market-context' $buildDate),
      (Get-Record $rankingPath 'trigger-b-ranking' $buildDate),
      (Get-Record $metaPath 'trigger-b-meta' $buildDate)
    )
    $state=[ordered]@{
      SchemaVersion='APL Trigger C Preparation v1.0'
      ScanDate=$ScanDate
      WeekLabel=$WeekLabel
      Status='AWAITING_EDITORIAL_AND_NATIVE'
      CreatedUtc=[datetime]::UtcNow.ToString('o')
      SourceEvidence=[object[]]$records
      WorkOrder=$workOrder
    }
    Write-Utf8 (Join-Path $buildDate 'trigger-c-preparation.json') ($state|ConvertTo-Json -Depth 10) $buildDate
    Move-Item -LiteralPath $buildDate -Destination $stagingDate
  }finally{
    if(Test-Path -LiteralPath $buildRoot){Remove-Item -LiteralPath $buildRoot -Recurse -Force}
    if(Test-Path -LiteralPath $scoringRoot){
      $scoringFull=Get-AplFullPath $scoringRoot
      $scoringAllowed=if($RegressionTest){$regressionRoot}else{Get-AplFullPath (Join-Path $ProjectRoot 'outputs\.staging')}
      if(-not$scoringFull.StartsWith($scoringAllowed.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){throw "Unsafe Trigger B staging cleanup path: $scoringFull"}
      Remove-Item -LiteralPath $scoringFull -Recurse -Force
    }
  }
  $created=Read-AplStrictJson $statePath $stagingDate
  [pscustomobject]@{Status=[string]$created.Status;ScanDate=$ScanDate;StagingRoot=$stagingDate;SupersededStaging=$supersededStaging;TriggerBMeta=(Join-Path $stagingDate "trigger-b\$ScanDate\APL_Momentum_Leaders_Meta_$ScanDate.json");WorkOrder=$created.WorkOrder}
  exit 0
}

if(!(Test-Path -LiteralPath $statePath -PathType Leaf)){throw "Trigger C preparation state not found: $statePath"}
if(Test-Path -LiteralPath $managedDate){throw "Managed input bundle already exists; refusing overwrite: $managedDate"}
$state=Read-AplStrictJson $statePath $stagingDate
if([string]$state.SchemaVersion-cne'APL Trigger C Preparation v1.0'-or[string]$state.ScanDate-cne$ScanDate-or[string]$state.Status-cne'AWAITING_EDITORIAL_AND_NATIVE'){throw 'Trigger C preparation state is not finalizable.'}
foreach($record in @($state.SourceEvidence)){Assert-Record $record $stagingDate|Out-Null}
$validatorArgs=@(
  '-InputCsv',(Join-Path $stagingDate 'source.csv'),
  '-TopGainersCsvPath',(Join-Path $stagingDate 'top-gainers.csv'),
  '-MarketContextPath',(Join-Path $stagingDate 'market-context.md'),
  '-TriggerBMetaPath',(Join-Path $stagingDate "trigger-b\$ScanDate\APL_Momentum_Leaders_Meta_$ScanDate.json"),
  '-ScanDate',$ScanDate,
  '-TableCardManifestPath',(Join-Path $stagingDate 'table-card-manifest.json'),
  '-CoverBriefPath',(Join-Path $stagingDate 'cover-brief.json'),
  '-CoverBackgroundPath',(Join-Path $stagingDate 'cover-background.png'),
  '-SeoBackgroundPath',(Join-Path $stagingDate 'seo-background.png'),
  '-CoverNativeContractPath',(Join-Path $stagingDate 'cover-native-contract.json'),
  '-SeoNativeContractPath',(Join-Path $stagingDate 'seo-native-contract.json'),
  '-PublishingArtifactsRoot',(Join-Path $stagingDate 'publishing'),
  '-ManagedInputsRoot',$stagingParent
)
if($RegressionTest){$validatorArgs+='-RegressionTest'}
$validation=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate_managed_inputs.ps1') @validatorArgs 2>&1)
if($LASTEXITCODE-ne0){throw "Trigger C managed-input finalization failed preflight: $($validation-join' ')"}
$state.Status='PREFLIGHT_PASS'
$state|Add-Member -NotePropertyName FinalizedUtc -NotePropertyValue ([datetime]::UtcNow.ToString('o')) -Force
$state|Add-Member -NotePropertyName FinalManagedRoot -NotePropertyValue $managedDate -Force
Write-Utf8 $statePath ($state|ConvertTo-Json -Depth 10) $stagingDate
Move-Item -LiteralPath $stagingDate -Destination $managedDate
[pscustomobject]@{Status='MANAGED_INPUT_BUNDLE_PASS';ScanDate=$ScanDate;ManagedInputsRoot=$managedDate;Preflight=($validation-join[Environment]::NewLine)}
