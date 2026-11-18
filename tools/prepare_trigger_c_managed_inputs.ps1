[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][ValidateSet('Initialize','Supersede','Review','Finalize','Produce','Status')][string]$Mode,
  [Parameter(Mandatory=$true)][string]$ScanDate,
  [string]$WeekLabel='',
  [string]$InputCsv='',
  [string]$TopGainersCsvPath='',
  [string]$MarketContextPath='',
  [switch]$GenerateHtmlFromMarkdown,
  [switch]$RegressionTest,
  [string]$OutputRoot=''
)

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')
. (Join-Path $PSScriptRoot 'article_reader_quality.ps1')

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

function Export-AplTop30Industries([string]$SourcePath,[string]$RankingPath,[string]$OutputPath,[string]$Root){
  Add-Type -AssemblyName Microsoft.VisualBasic
  $parser=New-Object Microsoft.VisualBasic.FileIO.TextFieldParser -ArgumentList @($SourcePath,[Text.Encoding]::UTF8,$true)
  $bySymbol=@{}
  try {
    $parser.TextFieldType=[Microsoft.VisualBasic.FileIO.FieldType]::Delimited
    $parser.SetDelimiters(',');$parser.HasFieldsEnclosedInQuotes=$true;$parser.TrimWhiteSpace=$false
    if($parser.EndOfData){throw 'Cumulative CSV is empty.'}
    $headers=@($parser.ReadFields())
    $symbolIndexes=@(for($i=0;$i-lt$headers.Count;$i++){if(([string]$headers[$i]).TrimStart([char]0xFEFF)-ceq'Symbol'){$i}})
    $industryIndexes=@(for($i=0;$i-lt$headers.Count;$i++){if(([string]$headers[$i]).TrimStart([char]0xFEFF)-ceq'Industry'){$i}})
    if($symbolIndexes.Count-ne1-or$industryIndexes.Count-ne1){throw 'Cumulative CSV requires exactly one Symbol and one Industry column.'}
    $line=1
    while(-not$parser.EndOfData){
      $line++;$fields=@($parser.ReadFields())
      if($fields.Count-ne$headers.Count){throw "Cumulative CSV row $line has an invalid field count."}
      $symbol=([string]$fields[$symbolIndexes[0]]).Trim().ToUpperInvariant()
      if([string]::IsNullOrWhiteSpace($symbol)-or$bySymbol.ContainsKey($symbol)){throw "Cumulative CSV has an empty or duplicate symbol at row $line."}
      $bySymbol[$symbol]=([string]$fields[$industryIndexes[0]]).Trim()
    }
  }finally{$parser.Close();$parser.Dispose()}
  $ranking=@(Import-Csv -LiteralPath $RankingPath|Select-Object -First 30)
  if($ranking.Count-ne30){throw 'Top 30 ranking is incomplete for Industry evidence.'}
  $rows=@(foreach($row in $ranking){
    $symbol=([string]$row.Symbol).Trim().ToUpperInvariant()
    if(-not$bySymbol.ContainsKey($symbol)-or[string]::IsNullOrWhiteSpace([string]$bySymbol[$symbol])){throw "Industry missing for Top 30 symbol '$symbol'."}
    [ordered]@{Rank=[int]$row.Rank;Symbol=$symbol;Name=[string]$row.Name;SourceIndustry=[string]$bySymbol[$symbol]}
  })
  $evidence=[ordered]@{SchemaVersion='APL Top 30 Industry Evidence v1.0';SourceSHA256=(Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash;RankingSHA256=(Get-FileHash -LiteralPath $RankingPath -Algorithm SHA256).Hash;Note='Industry is the source label; verify business and use editorial judgment for sector classification.';Rows=$rows}
  Write-Utf8 $OutputPath ($evidence|ConvertTo-Json -Depth 8) $Root
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

function Get-ManagedInputArguments([string]$Root,[string]$Date){
  return @(
    '-InputCsv',(Join-Path $Root 'source.csv'),
    '-TopGainersCsvPath',(Join-Path $Root 'top-gainers.csv'),
    '-MarketContextPath',(Join-Path $Root 'market-context.md'),
    '-TriggerBMetaPath',(Join-Path $Root "trigger-b\$Date\APL_Momentum_Leaders_Meta_$Date.json"),
    '-ScanDate',$Date,
    '-TableCardManifestPath',(Join-Path $Root 'table-card-manifest.json'),
    '-CoverBriefPath',(Join-Path $Root 'cover-brief.json'),
    '-CoverBackgroundPath',(Join-Path $Root 'cover-background.png'),
    '-SeoBackgroundPath',(Join-Path $Root 'seo-background.png'),
    '-CoverNativeContractPath',(Join-Path $Root 'cover-native-contract.json'),
    '-SeoNativeContractPath',(Join-Path $Root 'seo-native-contract.json'),
    '-PublishingArtifactsRoot',(Join-Path $Root 'publishing')
  )
}

Assert-AplScanDate $ScanDate|Out-Null
$currentArticle=(Get-AplReaderQualityPolicy -ScanDate $ScanDate).Enabled
if($GenerateHtmlFromMarkdown-and($Mode-cne'Finalize'-or-not$currentArticle)){throw 'GenerateHtmlFromMarkdown requires Finalize for an issue dated 2026-11-12 or later.'}
if($OutputRoot-and(-not$RegressionTest-or$Mode-cne'Produce')){throw 'OutputRoot is available only for Produce in RegressionTest mode.'}
$gitRoot=(& git -C $ProjectRoot rev-parse --show-toplevel 2>$null)
if($LASTEXITCODE-ne0-or[string]::IsNullOrWhiteSpace([string]$gitRoot)-or(Get-AplFullPath ([string]$gitRoot))-ne(Get-AplFullPath $ProjectRoot)){throw 'Project Root/Git Root mismatch.'}

$regressionRoot=Get-AplFullPath (Join-Path $ProjectRoot 'tmp\tc-inputs')
$formalWorkRoot=Get-AplFullPath (Join-Path $ProjectRoot 'work')
$stagingParent=if($RegressionTest){Join-Path $regressionRoot 'staging'}else{Join-Path $formalWorkRoot '.staging\trigger-c'}
$managedParent=if($RegressionTest){Join-Path $regressionRoot 'managed-inputs'}else{Join-Path $formalWorkRoot 'managed-inputs'}
$allowedContainer=if($RegressionTest){$regressionRoot}else{$formalWorkRoot}
# Check both complete parent chains before the first filesystem mutation.
$stagingParent=Assert-AplNoReparsePath -Path $stagingParent -AllowedRoot $allowedContainer
$managedParent=Assert-AplNoReparsePath -Path $managedParent -AllowedRoot $allowedContainer
if($Mode-cnotin@('Status','Review','Produce')){
  foreach($root in @($stagingParent,$managedParent)){
    if(!(Test-Path -LiteralPath $root)){New-Item -ItemType Directory -Path $root -Force|Out-Null}
    Assert-AplNoReparsePath -Path $root -AllowedRoot $allowedContainer -RequireDirectory|Out-Null
  }
}
$stagingDate=Join-Path $stagingParent $ScanDate
$managedDate=Join-Path $managedParent $ScanDate
$statePath=Join-Path $stagingDate 'trigger-c-preparation.json'
$produceCommand="powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\tools\prepare_trigger_c_managed_inputs.ps1 -Mode Produce -ScanDate $ScanDate"

if($Mode-ceq'Produce'){
  $finalStatePath=Join-Path $managedDate 'trigger-c-preparation.json'
  if(-not(Test-Path -LiteralPath $finalStatePath -PathType Leaf)){throw "No finalized Trigger C bundle for $ScanDate. Run Finalize before Produce."}
  $finalState=Read-AplStrictJson $finalStatePath $managedDate
  if([string]$finalState.SchemaVersion-cne'APL Trigger C Preparation v1.0'-or[string]$finalState.ScanDate-cne$ScanDate-or[string]$finalState.Status-cne'PREFLIGHT_PASS'-or[string]::IsNullOrWhiteSpace([string]$finalState.WeekLabel)){
    throw "Trigger C bundle for $ScanDate has no matching finalized preflight state and WeekLabel."
  }
  $requiredRoles=@('cumulative-screener','top-gainers','market-context','trigger-b-ranking','trigger-b-meta')
  foreach($role in $requiredRoles){
    if(@($finalState.SourceEvidence|Where-Object{$_.Role-ceq$role}).Count-ne1){throw "Finalized Trigger C bundle requires one source record: $role"}
  }
  foreach($record in @($finalState.SourceEvidence)){Assert-Record $record $managedDate|Out-Null}
  $runnerArgs=(Get-ManagedInputArguments $managedDate $ScanDate)+@('-WeekLabel',([string]$finalState.WeekLabel))
  if($RegressionTest){$runnerArgs+='-RegressionTest'}
  if($OutputRoot){$runnerArgs+=@('-OutputRoot',$OutputRoot)}
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run_daily_production.ps1') @runnerArgs
  exit $LASTEXITCODE
}

if($Mode-ceq'Status'){
  if(Test-Path -LiteralPath $managedDate -PathType Container){[pscustomobject]@{Status='FINALIZED';ScanDate=$ScanDate;ManagedInputsRoot=$managedDate;ProduceCommand=$produceCommand};exit 0}
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
  $scoringRoot=if($RegressionTest){Join-Path $regressionRoot ('s-'+[guid]::NewGuid().ToString('N').Substring(0,16))}else{Join-Path $ProjectRoot ('outputs\.staging\tc-prep-'+[guid]::NewGuid().ToString('N').Substring(0,16))}
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

    $industryPath=$null
    if([datetime]::ParseExact($ScanDate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)-ge[datetime]'2026-11-11'){
      $industryPath=Join-Path $buildDate 'top30-industry-evidence.json'
      Export-AplTop30Industries $sourcePath $rankingPath $industryPath $buildDate
    }

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
      ProduceCommand=$produceCommand
    }
    if($null-ne$industryPath){$workOrder['IndustryEvidence']='top30-industry-evidence.json'}
    if($currentArticle){
      $workOrder['FinalizeCommand']+=' -GenerateHtmlFromMarkdown'
      $workOrder['EditorialOrder']=@(
        'Read KnowledgeBase/Rules/APL_US_Stock_Blog_Rules.md and KnowledgeBase/Templates/Blog_Template.md.',
        'Research each Top 30 company using Industry and company evidence; choose the primary recommendations with reasons.',
        'Draft Markdown and company analysis; compare available recent issues and complete factual then reader review in existing editorial evidence.',
        'Run Review before rendering. It rejects known textual defects; it does not approve facts or replace editorial judgment.',
        'Derive WhatsApp and visual content from the reviewed manuscript. Finalize generates the HTML from that manuscript and runs preflight; Produce runs production and Archive verification.'
      )
      $workOrder['ReviewCommand']="powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\tools\prepare_trigger_c_managed_inputs.ps1 -Mode Review -ScanDate $ScanDate"
    }
    $records=@(
      (Get-Record $sourcePath 'cumulative-screener' $buildDate),
      (Get-Record $gainersPath 'top-gainers' $buildDate),
      (Get-Record $marketPath 'market-context' $buildDate),
      (Get-Record $rankingPath 'trigger-b-ranking' $buildDate),
      (Get-Record $metaPath 'trigger-b-meta' $buildDate)
    )
    if($null-ne$industryPath){$records+=Get-Record $industryPath 'top30-industry-evidence' $buildDate}
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
if($Mode-ceq'Review'){
  if(-not$currentArticle){throw 'Draft reader checks apply from 2026-11-12; use the historical preflight for earlier dates.'}
  $draftPath=Assert-AplNoReparsePath -Path (Join-Path $stagingDate ([string]$state.WorkOrder.PublishingArtifacts.BlogMarkdown)) -AllowedRoot $stagingDate -RequireFile
  $companyPath=Assert-AplNoReparsePath -Path (Join-Path $stagingDate ([string]$state.WorkOrder.PublishingArtifacts.CompanyBusinessAnalysis)) -AllowedRoot $stagingDate -RequireFile
  $rankingPath=Assert-AplNoReparsePath -Path (Join-Path $stagingDate "trigger-b/$ScanDate/APL_Momentum_Score_Full_Ranking_$ScanDate.csv") -AllowedRoot $stagingDate -RequireFile
  $review=Assert-AplArticleReaderQuality -Markdown ([IO.File]::ReadAllText($draftPath,[Text.Encoding]::UTF8)) -Company ([IO.File]::ReadAllText($companyPath,[Text.Encoding]::UTF8)) -Top30Symbols @((Import-Csv -LiteralPath $rankingPath)|Select-Object -First 30|ForEach-Object{[string]$_.Symbol})
  [pscustomobject]@{Status='DRAFT_READER_CHECKS_PASS';ScanDate=$ScanDate;MechanicalOnly=$true;FullPreflightStillRequired=$true;ReaderQuality=$review}
  exit 0
}
if(Test-AplStyledArticleDate $ScanDate){
  $htmlPath=Join-Path $stagingDate ([string]$state.WorkOrder.PublishingArtifacts.BlogHtmlSource)
  $htmlPath=Assert-AplNoReparsePath -Path $htmlPath -AllowedRoot $stagingDate
  $symbols=@(Get-AplArticleSymbols (Join-Path $stagingDate "trigger-b/$ScanDate/APL_Momentum_Score_Full_Ranking_$ScanDate.csv") (Join-Path $stagingDate 'top-gainers.csv'))
  if($currentArticle-and($GenerateHtmlFromMarkdown-or-not(Test-Path -LiteralPath $htmlPath -PathType Leaf))){
    $markdownPath=Assert-AplNoReparsePath -Path (Join-Path $stagingDate ([string]$state.WorkOrder.PublishingArtifacts.BlogMarkdown)) -AllowedRoot $stagingDate -RequireFile
    $markdown=[IO.File]::ReadAllText($markdownPath,[Text.Encoding]::UTF8)
    $raw=ConvertTo-AplArticleHtmlFromMarkdown $markdown (Get-AplBlogHeadingMap -ScanDate $ScanDate).ExecutiveSummary
  }else{
    $htmlPath=Assert-AplNoReparsePath -Path $htmlPath -AllowedRoot $stagingDate -RequireFile
    $raw=[IO.File]::ReadAllText($htmlPath,[Text.Encoding]::UTF8)
  }
  $styled=ConvertTo-AplStyledArticle -Html $raw -Symbols $symbols
  Assert-AplStyledArticle -Html $styled -Symbols $symbols|Out-Null
  Write-Utf8 $htmlPath $styled $stagingDate
}
$validatorArgs=(Get-ManagedInputArguments $stagingDate $ScanDate)+@('-ManagedInputsRoot',$stagingParent)
if($RegressionTest){$validatorArgs+='-RegressionTest'}
$validation=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'validate_managed_inputs.ps1') @validatorArgs 2>&1)
if($LASTEXITCODE-ne0){throw "Trigger C managed-input finalization failed preflight: $($validation-join' ')"}
$state.Status='PREFLIGHT_PASS'
$state|Add-Member -NotePropertyName FinalizedUtc -NotePropertyValue ([datetime]::UtcNow.ToString('o')) -Force
$state|Add-Member -NotePropertyName FinalManagedRoot -NotePropertyValue $managedDate -Force
Write-Utf8 $statePath ($state|ConvertTo-Json -Depth 10) $stagingDate
Move-Item -LiteralPath $stagingDate -Destination $managedDate
[pscustomobject]@{Status='MANAGED_INPUT_BUNDLE_PASS';ScanDate=$ScanDate;ManagedInputsRoot=$managedDate;ProduceCommand=$produceCommand;Preflight=($validation-join[Environment]::NewLine)}
