[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$InputCsv,
  [Parameter(Mandatory=$true)][string]$TopGainersCsvPath,
  [Parameter(Mandatory=$true)][string]$MarketContextPath,
  [Parameter(Mandatory=$true)][string]$TriggerBMetaPath,
  [Parameter(Mandatory=$true)][string]$ScanDate,
  [Parameter(Mandatory=$true)][string]$TableCardManifestPath,
  [Parameter(Mandatory=$true)][string]$CoverBriefPath,
  [Parameter(Mandatory=$true)][string]$CoverBackgroundPath,
  [Parameter(Mandatory=$true)][string]$SeoBackgroundPath,
  [Parameter(Mandatory=$true)][string]$CoverNativeContractPath,
  [Parameter(Mandatory=$true)][string]$SeoNativeContractPath,
  [Parameter(Mandatory=$true)][string]$PublishingArtifactsRoot,
  [string]$ManagedInputsRoot='',
  [switch]$RegressionTest
)
$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')

function Read-AplTradingViewCsv([string]$Path) {
  Add-Type -AssemblyName Microsoft.VisualBasic
  $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser -ArgumentList @($Path, [System.Text.Encoding]::UTF8, $true)
  $rows = New-Object System.Collections.Generic.List[object]
  try {
    $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
    $parser.SetDelimiters(',')
    $parser.HasFieldsEnclosedInQuotes = $true
    $parser.TrimWhiteSpace = $false
    if ($parser.EndOfData) { throw 'InputCsv is empty.' }

    try { $headers = @($parser.ReadFields()) }
    catch [Microsoft.VisualBasic.FileIO.MalformedLineException] {
      throw "InputCsv header is malformed CSV: $($_.Exception.Message)"
    }
    $symbolIndexes = @(
      for ($i = 0; $i -lt $headers.Count; $i++) {
        $header = ([string]$headers[$i]).TrimStart([char]0xFEFF)
        if ($header -ceq 'Symbol') { $i }
      }
    )
    if ($symbolIndexes.Count -ne 1) { throw 'InputCsv must contain exactly one Symbol column.' }

    $rowNumber = 1
    while (-not $parser.EndOfData) {
      $rowNumber++
      try { $fields = @($parser.ReadFields()) }
      catch [Microsoft.VisualBasic.FileIO.MalformedLineException] {
        throw "InputCsv row $rowNumber is malformed CSV: $($_.Exception.Message)"
      }
      if ($fields.Count -ne $headers.Count) {
        throw "InputCsv row $rowNumber has $($fields.Count) fields; expected $($headers.Count)."
      }
      [void]$rows.Add([string[]]$fields)
    }
  } finally {
    $parser.Close()
    $parser.Dispose()
  }
  if ($rows.Count -eq 0) { throw 'InputCsv contains no data rows.' }
  return [pscustomobject]@{
    Headers = [string[]]$headers
    Rows = [object[]]$rows.ToArray()
    SymbolIndex = [int]$symbolIndexes[0]
  }
}

function Get-AplMarkdownSection([string]$Text,[string]$Heading){
  $match=[regex]::Match($Text,"(?ms)^##\s+$([regex]::Escape($Heading))\s*$\s*(.*?)(?=^##\s+|\z)")
  if(-not$match.Success){throw "Blog Markdown missing mandatory section: $Heading"}
  return $match.Groups[1].Value.Trim()
}

function Get-AplHtmlSection([string]$Text,[string]$Heading){
  $match=[regex]::Match($Text,"(?is)<h3>\s*$([regex]::Escape($Heading))\s*</h3>\s*(.*?)(?=<h3>|\z)")
  if(-not$match.Success){throw "Blog HTML missing mandatory section: $Heading"}
  return $match.Groups[1].Value.Trim()
}

function ConvertTo-AplPlainText([string]$Text){
  $plain=$Text-replace'(?m)^#{1,6}\s+',''
  $plain=$plain-replace'<[^>]+>',' '
  $plain=[Net.WebUtility]::HtmlDecode($plain)
  return(($plain-replace'[`*_\[\]()]',' '-replace'\s+',' ').Trim())
}

function Get-AplMarkdownTokens([string]$Section){
  $tokens=New-Object System.Collections.Generic.List[string]
  foreach($block in @($Section-split'(?:\r?\n){2,}')){
    $value=$block.Trim();if([string]::IsNullOrWhiteSpace($value)){continue}
    if($value-match'(?s)^###\s+(.+?)\s*$'){[void]$tokens.Add($Matches[1].Trim())}
    else{[void]$tokens.Add((ConvertTo-AplPlainText $value))}
  }
  return [string[]]$tokens.ToArray()
}

function Get-AplHtmlTokens([string]$Section){
  return [string[]]@([regex]::Matches($Section,'(?is)<(?:h4|p)>\s*(.*?)\s*</(?:h4|p)>')|ForEach-Object{ConvertTo-AplPlainText $_.Groups[1].Value})
}

function Get-AplCoreMarketThesis([string]$Text,[string]$Label){
  $matches=@([regex]::Matches($Text,'(?m)^\s*本期核心市場命題(?:是)?\s*[：:]\s*(.+?)\s*$'))
  if($matches.Count-ne1){throw "$Label must declare exactly one 本期核心市場命題 editorial-control line."}
  $thesis=ConvertTo-AplPlainText $matches[0].Groups[1].Value
  if($thesis.Length-lt40){throw "$Label 本期核心市場命題 must be substantive."}
  return $thesis
}

function Assert-AplCoreMarketThesisAlignment([string]$MarketThesis,[string]$CoverBriefThesis){
  $market=ConvertTo-AplPlainText $MarketThesis
  $cover=ConvertTo-AplPlainText $CoverBriefThesis
  if([string]::IsNullOrWhiteSpace($market)-or[string]::IsNullOrWhiteSpace($cover)){throw 'Cross-platform core market thesis values must be non-empty.'}
  if(-not$market.Equals($cover,[StringComparison]::Ordinal)){throw 'Cover brief sceneConcept.coreMarketThesis must match the approved Market Context core thesis metadata.'}
  return $market
}

function Get-AplNumericClaims([string]$Text){
  $claims=New-Object System.Collections.Generic.List[string]
  foreach($match in @([regex]::Matches($Text,'(?<![A-Za-z0-9])\d[\d,]*(?:\.\d+)?\s*(?:%|％|億|萬|千|百|年|月|日|厘|個|款|周|週|倍)?'))){
    $value=($match.Value-replace'[,\s]','').Replace('％','%')
    if(-not[string]::IsNullOrWhiteSpace($value)){[void]$claims.Add($value)}
  }
  return [string[]]@($claims.ToArray()|Sort-Object -Unique)
}

function Assert-AplCompanyAnalysisTopSymbols([object[]]$Ranking,[string]$CompanyAnalysis,[int]$RequiredCount=30){
  $rows=@($Ranking)
  if($rows.Count-lt$RequiredCount){throw "Trigger B full ranking has fewer than $RequiredCount rows."}
  foreach($symbolValue in @($rows|Select-Object -First $RequiredCount|ForEach-Object{[string]$_.Symbol})){
    $symbol=$symbolValue.Trim().ToUpperInvariant()
    if([string]::IsNullOrWhiteSpace($symbol)){throw 'Trigger B full ranking contains an empty Symbol.'}
    if($CompanyAnalysis-cnotmatch("(?<![A-Z0-9.])"+[regex]::Escape($symbol)+"(?![A-Z0-9.])")){throw "Company Business Analysis missing Top $RequiredCount leader: $symbol"}
  }
  return $true
}

function Resolve-AplManagedMetaPath([string]$MetaPath,[string]$Value,[string]$AllowedRoot,[string]$Label){
  if([string]::IsNullOrWhiteSpace($Value)){throw "$Label is empty."}
  $candidate=if([IO.Path]::IsPathRooted($Value)){$Value}else{Join-Path (Split-Path $MetaPath -Parent) $Value}
  return Assert-AplNoReparsePath -Path $candidate -AllowedRoot $AllowedRoot -RequireFile
}

function Assert-AplEditorialContent([string]$MarkdownPath,[string]$HtmlPath,[string]$WhatsAppPath,[string]$CompanyPath,[string]$MarketPath,[string]$TopGainersPath,[string]$MetaPath,[string]$AllowedRoot,[string]$ScanDate){
  $markdown=[IO.File]::ReadAllText($MarkdownPath,[Text.Encoding]::UTF8)
  $html=[IO.File]::ReadAllText($HtmlPath,[Text.Encoding]::UTF8)
  $whatsApp=[IO.File]::ReadAllText($WhatsAppPath,[Text.Encoding]::UTF8)
  $company=[IO.File]::ReadAllText($CompanyPath,[Text.Encoding]::UTF8)
  $market=[IO.File]::ReadAllText($MarketPath,[Text.Encoding]::UTF8)
  $allEditorial=$markdown+"`n"+$html+"`n"+$whatsApp+"`n"+$company
  if($allEditorial-match'(?i)\bplaceholder\b|lorem ipsum|\bTODO\b|\bTBD\b|\[insert|\[market|\[section|test sentence|smoke test|dummy content|sample text'){throw 'Editorial artifacts contain placeholder or test content.'}
  if(@([regex]::Matches($markdown,'[\u3400-\u9FFF]')).Count-lt500){throw 'Blog Markdown does not contain substantive Chinese editorial analysis.'}

  $mandatory=[ordered]@{
    'Executive Summary'=80
    'Market Context'=160
    '為什麼要看 APL Momentum Leaders 領導股？'=120
    'Deep-Scan Overview'=120
    '最近7日 Top Gainers'=150
    'Momentum Leaders Analysis'=180
    'Sector Analysis'=120
    'Relative Volume / Market Activity'=120
    'Risk'=120
    'Deep-Scan Conclusion'=120
  }
  $mdHeadings=@([regex]::Matches($markdown,'(?m)^##\s+(.+?)\s*$')|ForEach-Object{$_.Groups[1].Value.Trim()})
  $htmlHeadings=@([regex]::Matches($html,'(?is)<h3>\s*(.*?)\s*</h3>')|ForEach-Object{ConvertTo-AplPlainText $_.Groups[1].Value})
  $previousMd=-1;$previousHtml=-1
  $sections=[ordered]@{}
  foreach($heading in $mandatory.Keys){
    $mdIndex=[Array]::IndexOf([string[]]$mdHeadings,[string]$heading);$htmlIndex=[Array]::IndexOf([string[]]$htmlHeadings,[string]$heading)
    if($mdIndex-lt0){throw "Blog Markdown missing mandatory section: $heading"};if($htmlIndex-lt0){throw "Blog HTML missing mandatory section: $heading"}
    if($mdIndex-le$previousMd-or$htmlIndex-le$previousHtml){throw "Mandatory editorial section order is invalid at: $heading"}
    $previousMd=$mdIndex;$previousHtml=$htmlIndex
    $mdSection=Get-AplMarkdownSection $markdown $heading;$htmlSection=Get-AplHtmlSection $html $heading
    $mdPlain=ConvertTo-AplPlainText $mdSection;$htmlPlain=ConvertTo-AplPlainText $htmlSection
    if($mdPlain.Length-lt[int]$mandatory[$heading]-or$htmlPlain.Length-lt[int]$mandatory[$heading]){throw "Editorial section is empty or too short: $heading"}
    if(@([regex]::Matches($mdPlain,'[\u3400-\u9FFF]')).Count-lt15){throw "Editorial section is an English-only or non-substantive test section: $heading"}
    $mdTokens=@(Get-AplMarkdownTokens $mdSection);$htmlTokens=@(Get-AplHtmlTokens $htmlSection)
    if($mdTokens.Count-ne$htmlTokens.Count){throw "Blog Markdown/HTML token count mismatch in section: $heading"}
    for($i=0;$i-lt$mdTokens.Count;$i++){if([string]$mdTokens[$i]-cne[string]$htmlTokens[$i]){throw "Blog Markdown/HTML content mismatch in section: $heading"}}
    $sections[$heading]=[pscustomobject]@{MarkdownLength=$mdPlain.Length;HtmlLength=$htmlPlain.Length;Tokens=$mdTokens.Count}
  }
  $mdTitle=[regex]::Match($markdown,'(?m)^#\s+(.+?)\s*$').Groups[1].Value.Trim();$htmlTitle=ConvertTo-AplPlainText ([regex]::Match($html,'(?is)<h1>\s*(.*?)\s*</h1>').Groups[1].Value)
  if([string]::IsNullOrWhiteSpace($mdTitle)-or$mdTitle-cne$htmlTitle){throw 'Blog Markdown/HTML title mismatch.'}
  $marketSection=Get-AplMarkdownSection $markdown 'Market Context'
  $coreThesis=Get-AplCoreMarketThesis $market 'Approved Market Context'
  $marketPlain=ConvertTo-AplPlainText $marketSection
  if(@([regex]::Matches($marketPlain,'[\u3400-\u9FFF]')).Count-lt80){throw 'Blog Market Context is only a heading, placeholder, or extremely short summary.'}
  $marketBlocks=@($marketSection-split'(?:\r?\n){2,}'|ForEach-Object{$_.Trim()}|Where-Object{-not[string]::IsNullOrWhiteSpace($_)-and$_-notmatch'^###\s+'})
  if($marketBlocks.Count-lt1-or@($marketBlocks|Where-Object{$_-notmatch'(?m)^\s*(?:[-*+]|\d+[.)])\s+'}).Count-eq0){throw 'Blog Market Context is only a news list without analytical prose.'}
  $executivePlain=ConvertTo-AplPlainText (Get-AplMarkdownSection $markdown 'Executive Summary')
  if($marketPlain-ceq$executivePlain){throw 'Blog Market Context is replaced by the Executive Summary.'}
  $sourceNumbers=@(Get-AplNumericClaims $market)
  $blogNumbers=@(Get-AplNumericClaims $marketSection)
  foreach($number in $blogNumbers){if($sourceNumbers-cnotcontains$number){throw "Blog Market Context contains a numeric claim not found in the approved source: $number"}}
  $sourceMarketHeadings=@([regex]::Matches($market,'(?m)^#{2,3}\s+(.+?)\s*$')|ForEach-Object{$_.Groups[1].Value.Trim()})
  $outsideContext=$html-replace'(?is)<h3>\s*Market Context\s*</h3>.*?(?=<h3>)',''
  if($outsideContext-match'(?is)<h4>'){throw 'HTML h4 is allowed only inside Market Context.'}

  $meta=Read-AplStrictJson $MetaPath $AllowedRoot
  if([string]$meta.scanDate-cne$ScanDate){throw 'Trigger B metadata ScanDate mismatch.'}
  $overview=ConvertTo-AplPlainText (Get-AplMarkdownSection $markdown 'Deep-Scan Overview')
  foreach($field in @('universe','qualified','leaders','leaderLock','removedBelowSma200Count','finalWatchlistCount','averageMomentum','averageBuyability')){
    $value=[string]$meta.$field;$escaped=[regex]::Escape($value)
    if($value-match'\.'){ $pattern='(?<![0-9])'+$escaped+'0*(?![0-9])' }else{ $pattern='(?<![0-9])'+$escaped+'(?![0-9])' }
    if($overview-cnotmatch$pattern){throw "Blog Deep-Scan Overview does not match Trigger B metadata field: $field=$value"}
  }
  $rankingPath=Resolve-AplManagedMetaPath $MetaPath ([string]$meta.fullRankingCsv) $AllowedRoot 'Trigger B metadata fullRankingCsv'
  $ranking=@(Import-Csv -LiteralPath $rankingPath)
  Assert-AplCompanyAnalysisTopSymbols $ranking $company 30|Out-Null
  if((ConvertTo-AplPlainText $company).Length-lt800){throw 'Company Business Analysis is an empty or summary shell.'}

  $topCsv=Read-AplTradingViewCsv $TopGainersPath
  $topSymbols=@($topCsv.Rows|Select-Object -First 3|ForEach-Object{[string]$_[$topCsv.SymbolIndex]})
  $topSection=ConvertTo-AplPlainText (Get-AplMarkdownSection $markdown '最近7日 Top Gainers')
  foreach($symbol in $topSymbols){if($topSection-cnotmatch("(?<![A-Z0-9.])"+[regex]::Escape($symbol)+"(?![A-Z0-9.])")){throw "Blog Top Gainers section missing source leader: $symbol"}}
  if($topSection-cnotmatch'TradingView'){throw 'Blog Top Gainers section missing TradingView source disclosure.'}

  $conclusion=ConvertTo-AplPlainText (Get-AplMarkdownSection $markdown 'Deep-Scan Conclusion')
  $keywords=@($sourceMarketHeadings|ForEach-Object{$_-split'[：，、／/\s]+'}|Where-Object{$_.Length-ge2-and$_-notin@('市場','背景','風險','重新','開始')})
  if($keywords.Count-gt0-and@($keywords|Where-Object{$conclusion.Contains($_)}).Count-lt1){throw 'Deep-Scan Conclusion does not respond to the Market Context proposition.'}
  if((ConvertTo-AplPlainText $whatsApp).Length-lt250){throw 'WhatsApp artifact is an empty or summary shell.'}
  $firstScreen=(ConvertTo-AplPlainText $whatsApp);if($firstScreen.Length-gt400){$firstScreen=$firstScreen.Substring(0,400)}
  if($keywords.Count-gt0-and@($keywords|Where-Object{$firstScreen.Contains($_)}).Count-lt1){throw 'WhatsApp first screen does not state the main market change.'}
  return [pscustomobject]@{MandatorySections=[string[]]$mandatory.Keys;Sections=$sections;TriggerBMeta=$meta;TopGainers=[string[]]$topSymbols;MarkdownTitle=$mdTitle;MarketContextIntegrity=[pscustomobject]@{CoreThesis=$coreThesis;MarkdownCharacters=$marketPlain.Length;ChineseCharacters=@([regex]::Matches($marketPlain,'[\u3400-\u9FFF]')).Count;NumericClaimsValidated=[string[]]$blogNumbers;NotExecutiveSummary=$true;MechanicalIntegrity=$true}}
}

function Get-AplUniqueCsvColumnIndex($Csv,[string]$Name){
  $indexes=@(for($i=0;$i-lt$Csv.Headers.Count;$i++){if(([string]$Csv.Headers[$i]).TrimStart([char]0xFEFF)-ceq$Name){$i}})
  if($indexes.Count-ne1){throw "CSV must contain exactly one '$Name' column."}
  return [int]$indexes[0]
}

function ConvertTo-AplInvariantDouble($Value,[string]$Label){
  $number=0.0
  if(-not[double]::TryParse(([string]$Value).Trim(),[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$number)){throw "$Label must be a valid invariant number."}
  return [double]$number
}

function ConvertTo-AplCompanyIdentity([string]$Value){
  $ignored=@('INC','INCORPORATED','CORP','CORPORATION','CO','COMPANY','COMPANIES','LTD','LIMITED','PLC','HOLDING','HOLDINGS','GROUP','THE')
  $tokens=@(($Value.ToUpperInvariant()-replace'[^A-Z0-9]+',' ').Trim()-split'\s+'|Where-Object{$_-and$ignored-cnotcontains$_})
  return ($tokens-join'')
}

function Assert-AplCompanyIdentity([string]$Actual,[string]$Expected,[string]$Label){
  $actualKey=ConvertTo-AplCompanyIdentity $Actual;$expectedKey=ConvertTo-AplCompanyIdentity $Expected
  if($actualKey.Length-lt2-or$expectedKey.Length-lt2-or(-not$actualKey.StartsWith($expectedKey,[StringComparison]::Ordinal)-and-not$expectedKey.StartsWith($actualKey,[StringComparison]::Ordinal))){throw "$Label company identity does not match its source."}
}

function Assert-AplTableCardSourceIntegrity($Cards,$Meta,[string]$MetaPath,[string]$TopGainersPath,[string]$AllowedRoot){
  $rankingPath=Resolve-AplManagedMetaPath $MetaPath ([string]$Meta.fullRankingCsv) $AllowedRoot 'Trigger B metadata fullRankingCsv'
  $ranking=@(Import-Csv -LiteralPath $rankingPath)
  if($ranking.Count-lt30){throw 'Trigger B full ranking has fewer than 30 rows for Table Card source validation.'}

  $executiveRows=@($Cards['ExecutiveSummary'].Json.Rows)
  if($executiveRows.Count-lt3-or$executiveRows.Count-gt5){throw 'ExecutiveSummary must contain 3 to 5 priority observations.'}

  $leaderRows=@($Cards['TopLeaders'].Json.Rows)
  if($leaderRows.Count-lt1-or$leaderRows.Count-gt$ranking.Count){throw 'TopLeaders card row count is invalid.'}
  for($i=0;$i-lt$leaderRows.Count;$i++){
    $expected=$ranking[$i];$actual=$leaderRows[$i];$expectedRank=$i+1
    if(([string]$actual.rank).TrimStart('#')-cne[string]$expectedRank){throw "TopLeaders row $($i+1) rank does not match Trigger B ranking."}
    if(([string]$actual.symbol).Trim().ToUpperInvariant()-cne([string]$expected.Symbol).Trim().ToUpperInvariant()){throw "TopLeaders row $($i+1) symbol does not match Trigger B ranking."}
    Assert-AplCompanyIdentity ([string]$actual.companyName) ([string]$expected.Name) "TopLeaders row $($i+1)"
    $actualScore=ConvertTo-AplInvariantDouble $actual.compositeScore "TopLeaders row $($i+1) compositeScore"
    $expectedScore=ConvertTo-AplInvariantDouble $expected.'Composite Score' "Trigger B ranking row $($i+1) Composite Score"
    if([Math]::Abs($actualScore-$expectedScore)-gt0.005){throw "TopLeaders row $($i+1) compositeScore does not match Trigger B ranking."}
  }

  $topCsv=Read-AplTradingViewCsv $TopGainersPath
  $descriptionIndex=Get-AplUniqueCsvColumnIndex $topCsv 'Description'
  $changeIndex=Get-AplUniqueCsvColumnIndex $topCsv 'Price change %, 1 day'
  $gainerRows=@($Cards['TopGainers'].Json.Rows)
  if($gainerRows.Count-lt1-or$gainerRows.Count-gt$topCsv.Rows.Count){throw 'TopGainers card row count is invalid.'}
  for($i=0;$i-lt$gainerRows.Count;$i++){
    $source=$topCsv.Rows[$i];$actual=$gainerRows[$i]
    if(([string]$actual.symbol).Trim().ToUpperInvariant()-cne([string]$source[$topCsv.SymbolIndex]).Trim().ToUpperInvariant()){throw "TopGainers row $($i+1) symbol does not match source CSV."}
    Assert-AplCompanyIdentity ([string]$actual.companyName) ([string]$source[$descriptionIndex]) "TopGainers row $($i+1)"
    $actualChange=ConvertTo-AplInvariantDouble (([string]$actual.changePct).Trim().TrimEnd('%')) "TopGainers row $($i+1) changePct"
    $sourceChange=ConvertTo-AplInvariantDouble $source[$changeIndex] "Top Gainers source row $($i+1) change"
    if([Math]::Abs($actualChange-$sourceChange)-gt0.005){throw "TopGainers row $($i+1) changePct does not match source CSV."}
  }

  $top30=@($ranking|Select-Object -First 30|ForEach-Object{([string]$_.Symbol).Trim().ToUpperInvariant()})
  $seenRepresentatives=@{}
  foreach($row in @($Cards['SectorStructure'].Json.Rows)){
    $symbols=@(([string]$row.representativeSymbols)-split'[,;\s]+'|ForEach-Object{$_.Trim().ToUpperInvariant()}|Where-Object{$_})
    if($symbols.Count-lt1){throw 'SectorStructure row has no representative symbols.'}
    if([int]$row.count-lt$symbols.Count-or[int]$row.count-gt30){throw "SectorStructure count is inconsistent for theme '$($row.theme)'."}
    foreach($symbol in $symbols){
      if($top30-cnotcontains$symbol){throw "SectorStructure representative '$symbol' is not in the Trigger B Top 30."}
      if($seenRepresentatives.ContainsKey($symbol)){throw "SectorStructure representative '$symbol' is duplicated across groups."}
      $seenRepresentatives[$symbol]=$true
    }
  }
  return [pscustomobject]@{RankingRows=$ranking.Count;ExecutiveRows=$executiveRows.Count;TopLeaderRows=$leaderRows.Count;TopGainerRows=$gainerRows.Count;SectorRepresentatives=$seenRepresentatives.Count}
}

function Assert-AplNativeCompositionRecord($Record, [string]$ContractPath, [string]$Role, [string]$ImagePath, $BriefComposition, [string]$SceneConceptId, [string]$AllowedRoot) {
  $contractFields=@('artifact_type','scene_concept_id','native_size','aspect_ratio','camera_distance','framing_description','subject_placement','text_safe_area','source_path','tolerance','source_sha256','provider','workflow','generation_time','capture_stage','transformation')
  foreach($name in $contractFields) {
    if($null-eq$Record.PSObject.Properties[$name]) { throw "Native $Role contract missing $name." }
  }
  $unsupported=@($Record.PSObject.Properties.Name|Where-Object{$_-notin$contractFields})
  if($unsupported.Count-gt0){throw "Native $Role contract contains unsupported fields: $($unsupported-join', ')."}
  if([string]$Record.artifact_type-cne$Role) { throw "Native contract artifact_type must be $Role." }
  if([string]$Record.scene_concept_id-cne$SceneConceptId) { throw "Native $Role contract scene_concept_id does not match Cover Brief." }
  $expectedRatio=if($Role-eq'cover'){'4:5'}else{'16:9'}
  if([string]$Record.aspect_ratio-cne$expectedRatio) { throw "Native $Role contract aspect_ratio must be $expectedRatio." }
  if([string]$Record.transformation-cne'none') { throw "Native $Role contract transformation must be none." }
  if([string]$Record.capture_stage-cne'ImmediateGenerationOutput') { throw "Native $Role contract capture_stage mismatch." }
  if([double]$Record.tolerance-ne0.001){throw "Native $Role contract tolerance must be 0.001."}
  foreach($name in @('camera_distance','framing_description','subject_placement','text_safe_area','source_path','source_sha256','provider','workflow','generation_time')) {
    if([string]::IsNullOrWhiteSpace([string]$Record.$name)) { throw "Native $Role contract $name must be non-empty." }
  }
  if([string]$Record.source_sha256-cnotmatch'^[0-9A-F]{64}$'){throw "Native $Role source_sha256 format is invalid."}
  $generationTime=[DateTimeOffset]::MinValue
  if(-not[DateTimeOffset]::TryParse([string]$Record.generation_time,[ref]$generationTime)-or[string]$Record.generation_time-cnotmatch'(Z|[+-]\d{2}:\d{2})$'){throw "Native $Role generation_time must include a UTC offset."}
  if($null-eq$Record.native_size-or$null-eq$Record.native_size.width-or$null-eq$Record.native_size.height){throw "Native $Role native_size is invalid."}
  if([IO.Path]::IsPathRooted([string]$Record.source_path)) { throw "Native $Role source_path must be repository-portable and relative to its contract." }
  $declaredSource=Assert-AplNoReparsePath -Path (Join-Path (Split-Path $ContractPath -Parent) ([string]$Record.source_path)) -AllowedRoot $AllowedRoot -RequireFile
  if(-not$declaredSource.Equals($ImagePath,[StringComparison]::OrdinalIgnoreCase)) { throw "Native $Role source_path does not resolve to its managed background." }
  foreach($name in @('camera_distance','framing_description','subject_placement','text_safe_area')) {
    if([string]$Record.$name-cne[string]$BriefComposition.$name) { throw "Native $Role contract $name does not match Cover Brief composition." }
  }
  $image=$null
  try {
    $image=[Drawing.Image]::FromFile($ImagePath)
    $width=[int]$image.Width;$height=[int]$image.Height
    if([int]$Record.native_size.width-ne$width-or[int]$Record.native_size.height-ne$height) { throw "Native $Role contract dimension mismatch." }
    if($Role-eq'cover'-and($width-lt600-or$height-lt750)){throw 'Native cover background is too small.'}
    if($Role-eq'seo'-and($width-lt1280-or$height-lt720)){throw 'Native seo background is too small.'}
    $target=if($Role-eq'cover'){4.0/5.0}else{16.0/9.0}
    if([Math]::Abs(([double]$width/[double]$height)-$target)-gt 0.001) { throw "Native $Role background aspect ratio mismatch." }
  } finally { if($image){$image.Dispose()} }
  $sha=(Get-FileHash -LiteralPath $ImagePath -Algorithm SHA256).Hash
  if($sha-cne[string]$Record.source_sha256) { throw "Native $Role source_sha256 mismatch." }
  return $sha
}

Assert-AplScanDate $ScanDate|Out-Null
$defaultManagedRoot=Get-AplFullPath (Join-Path $ProjectRoot 'work\managed-inputs')
$workRoot=Get-AplFullPath (Join-Path $ProjectRoot 'work')
$formalStagingRoot=Get-AplFullPath (Join-Path $workRoot '.staging\trigger-c')
$regressionRoot=Get-AplFullPath (Join-Path $ProjectRoot 'tmp')
if([string]::IsNullOrWhiteSpace($ManagedInputsRoot)){
  $allowedRoot=if($RegressionTest){$regressionRoot}else{$defaultManagedRoot}
}else{
  $allowedRoot=Get-AplFullPath $ManagedInputsRoot
  if($RegressionTest){
    if(-not(Test-AplPathInside $allowedRoot $regressionRoot)){throw "Regression ManagedInputsRoot must be inside '$regressionRoot'."}
  }elseif(-not($allowedRoot.Equals($defaultManagedRoot,[StringComparison]::OrdinalIgnoreCase)-or(Test-AplPathInside $allowedRoot $formalStagingRoot))){
    throw "Formal ManagedInputsRoot must be '$defaultManagedRoot' or the Trigger C preparation staging root."
  }
}
$allowedRootParent=if($RegressionTest){$regressionRoot}else{$workRoot}
$allowedRoot=Assert-AplNoReparsePath -Path $allowedRoot -AllowedRoot $allowedRootParent -RequireDirectory
$artifactContract=Read-AplStrictJson (Join-Path $ProjectRoot 'KnowledgeBase\Rules\APL_US_Stock_Production_Artifact_Contract.json') $ProjectRoot
$readinessContract=$artifactContract.EditorialReadiness
if($null-eq$readinessContract-or[string]::IsNullOrWhiteSpace([string]$readinessContract.SchemaVersion)-or@($readinessContract.RequiredSourceRoles).Count-lt1-or@($readinessContract.RequiredChecks).Count-lt1){throw 'Production Artifact Contract EditorialReadiness definition is invalid.'}
$InputCsv=Assert-AplNoReparsePath -Path $InputCsv -AllowedRoot $allowedRoot -RequireFile
$TopGainersCsvPath=Assert-AplNoReparsePath -Path $TopGainersCsvPath -AllowedRoot $allowedRoot -RequireFile
$MarketContextPath=Assert-AplNoReparsePath -Path $MarketContextPath -AllowedRoot $allowedRoot -RequireFile
$TriggerBMetaPath=Assert-AplNoReparsePath -Path $TriggerBMetaPath -AllowedRoot $allowedRoot -RequireFile
$TableCardManifestPath=Assert-AplNoReparsePath -Path $TableCardManifestPath -AllowedRoot $allowedRoot -RequireFile
$CoverBriefPath=Assert-AplNoReparsePath -Path $CoverBriefPath -AllowedRoot $allowedRoot -RequireFile
$CoverBackgroundPath=Assert-AplNoReparsePath -Path $CoverBackgroundPath -AllowedRoot $allowedRoot -RequireFile
$SeoBackgroundPath=Assert-AplNoReparsePath -Path $SeoBackgroundPath -AllowedRoot $allowedRoot -RequireFile
$CoverNativeContractPath=Assert-AplNoReparsePath -Path $CoverNativeContractPath -AllowedRoot $allowedRoot -RequireFile
$SeoNativeContractPath=Assert-AplNoReparsePath -Path $SeoNativeContractPath -AllowedRoot $allowedRoot -RequireFile
$PublishingArtifactsRoot=Assert-AplNoReparsePath -Path $PublishingArtifactsRoot -AllowedRoot $allowedRoot -RequireDirectory
foreach($path in @($InputCsv,$TopGainersCsvPath,$MarketContextPath,$TriggerBMetaPath,$TableCardManifestPath,$CoverBriefPath,$CoverBackgroundPath,$SeoBackgroundPath,$CoverNativeContractPath,$SeoNativeContractPath,$PublishingArtifactsRoot)){if(-not(Test-AplPathInside $path (Join-Path $allowedRoot $ScanDate))){throw "Managed input must be inside the ScanDate directory: $path"}}
$csv=Read-AplTradingViewCsv $InputCsv
$manifest=Read-AplStrictJson $TableCardManifestPath $allowedRoot
if([string]$manifest.SchemaVersion-cne'APL Table Card Manifest v1.1'-or[string]$manifest.ScanDate-cne$ScanDate){throw 'Table Card manifest schema/date mismatch.'}
$requiredTypes=@('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure')
$tableCardSources=@{}
foreach($type in $requiredTypes){$records=@($manifest.Cards|Where-Object{[string]$_.CardType-eq$type-and$_.Required-eq$true});if($records.Count-ne 1){throw "Managed inputs require exactly one $type card."};$input=[string]$records[0].InputPath;$base=Split-Path $TableCardManifestPath -Parent;$path=if([IO.Path]::IsPathRooted($input)){$input}else{Join-Path $base $input};$path=Assert-AplNoReparsePath -Path $path -AllowedRoot $allowedRoot -RequireFile;$json=Read-AplStrictJson $path $allowedRoot;[void](Assert-AplTableCardContract $json $type);$tableCardSources[$type]=[pscustomobject]@{Path=$path;Json=$json}}
$triggerBMeta=Read-AplStrictJson $TriggerBMetaPath $allowedRoot
if([string]$triggerBMeta.scanDate-cne$ScanDate){throw 'Trigger B metadata ScanDate mismatch.'}
if($csv.Rows.Count-ne[int]$triggerBMeta.universe){throw "Cumulative screener row count does not match Trigger B metadata universe. Csv=$($csv.Rows.Count); Meta=$($triggerBMeta.universe)."}
$tableCardIntegrity=Assert-AplTableCardSourceIntegrity $tableCardSources $triggerBMeta $TriggerBMetaPath $TopGainersCsvPath $allowedRoot
$brief=Read-AplStrictJson $CoverBriefPath $allowedRoot
foreach($name in @('version','scanDate','composition','imageGenerationBrief','overlay')){if($null-eq$brief.PSObject.Properties[$name]){throw "Cover brief missing $name."}}
if([string]$brief.version-cne'APL Cover Brief v1.1'-or[string]$brief.scanDate-cne$ScanDate){throw 'Cover brief schema/date mismatch.'}
foreach($name in @('sceneConcept','nativeCompositions')){if($null-eq$brief.PSObject.Properties[$name]){throw "Cover brief missing $name."}}
$sceneId=[string]$brief.sceneConcept.id
if([string]::IsNullOrWhiteSpace($sceneId)){throw 'Cover brief sceneConcept.id must be non-empty.'}
$coverComposition=$brief.nativeCompositions.cover
$seoComposition=$brief.nativeCompositions.seo
if($null-eq$coverComposition-or$null-eq$seoComposition){throw 'Cover brief requires cover and seo native compositions.'}
if([string]$coverComposition.aspect_ratio-cne'4:5'-or[string]$seoComposition.aspect_ratio-cne'16:9'){throw 'Cover/SEO native composition aspect ratios must be 4:5 and 16:9.'}
foreach($composition in @($coverComposition,$seoComposition)){foreach($name in @('camera_distance','framing_description','subject_placement','text_safe_area')){if([string]::IsNullOrWhiteSpace([string]$composition.$name)){throw "Cover brief native composition $name must be non-empty."}}}
foreach($name in @('coreMarketThesis','subjectIdentity','colorPalette','lightingDirection','cinematicMood','brandAtmosphere','artStyle')){if([string]::IsNullOrWhiteSpace([string]$brief.sceneConcept.$name)){throw "Cover brief sceneConcept.$name must be non-empty."}}
if(@($brief.sceneConcept.primarySceneElements).Count-lt1-or@($brief.sceneConcept.primarySceneElements|Where-Object{[string]::IsNullOrWhiteSpace([string]$_)}).Count-gt0){throw 'Cover brief sceneConcept.primarySceneElements must contain non-empty values.'}
foreach($name in @('sharedPrompt','coverPrompt','seoPrompt','negativePrompt')){if([string]::IsNullOrWhiteSpace([string]$brief.imageGenerationBrief.$name)){throw "Cover brief imageGenerationBrief.$name must be non-empty."}}
if([string]$brief.imageGenerationBrief.coverPrompt-ceq[string]$brief.imageGenerationBrief.seoPrompt){throw 'Cover and SEO generation prompts must express different role-specific viewpoints.'}
if(([string]$coverComposition.camera_distance-ceq[string]$seoComposition.camera_distance)-and([string]$coverComposition.framing_description-ceq[string]$seoComposition.framing_description)){throw 'Cover and SEO camera distance or framing must differ.'}
if($CoverBackgroundPath.Equals($SeoBackgroundPath,[StringComparison]::OrdinalIgnoreCase)){throw 'Cover and SEO background paths must differ.'}
Add-Type -AssemblyName System.Drawing
$coverContract=Read-AplStrictJson $CoverNativeContractPath $allowedRoot
$seoContract=Read-AplStrictJson $SeoNativeContractPath $allowedRoot
$coverSha=Assert-AplNativeCompositionRecord $coverContract $CoverNativeContractPath 'cover' $CoverBackgroundPath $coverComposition $sceneId $allowedRoot
$seoSha=Assert-AplNativeCompositionRecord $seoContract $SeoNativeContractPath 'seo' $SeoBackgroundPath $seoComposition $sceneId $allowedRoot
if($coverSha-ceq$seoSha){throw 'Cover and SEO source SHA-256 must differ; the same native image cannot serve both roles.'}
$requiredPublishing=@(
  "production-package\WhatsApp_${ScanDate}.md",
  "production-package\APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.md",
  "production-package\APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.html",
  "production-package\table-card-log\APL_Momentum_Leaders_Top_30_Company_Business_Analysis_${ScanDate}.md"
)
foreach($relative in $requiredPublishing){$path=Assert-AplNoReparsePath -Path (Join-Path $PublishingArtifactsRoot $relative) -AllowedRoot $PublishingArtifactsRoot -RequireFile;if((Get-Item $path).Length-le 0){throw "Managed publishing artifact is empty: $relative"}}
$packageRoot=Assert-AplNoReparsePath -Path (Join-Path $PublishingArtifactsRoot 'production-package') -AllowedRoot $PublishingArtifactsRoot -RequireDirectory
$whatsAppPath=Join-Path $packageRoot "WhatsApp_${ScanDate}.md"
$blogMarkdownPath=Join-Path $packageRoot "APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.md"
$blogHtmlPath=Join-Path $packageRoot "APL_Momentum_Leaders_Market_Analysis_Blog_${ScanDate}.html"
$companyPath=Join-Path $packageRoot "table-card-log\APL_Momentum_Leaders_Top_30_Company_Business_Analysis_${ScanDate}.md"
$editorial=Assert-AplEditorialContent $blogMarkdownPath $blogHtmlPath $whatsAppPath $companyPath $MarketContextPath $TopGainersCsvPath $TriggerBMetaPath $allowedRoot $ScanDate
$alignedCoreThesis=Assert-AplCoreMarketThesisAlignment ([string]$editorial.MarketContextIntegrity.CoreThesis) ([string]$brief.sceneConcept.coreMarketThesis)
$editorial.MarketContextIntegrity|Add-Member -NotePropertyName CoverBriefCoreThesis -NotePropertyValue $alignedCoreThesis
$editorial.MarketContextIntegrity|Add-Member -NotePropertyName CrossPlatformThesisAligned -NotePropertyValue $true
$editorialAuditPath=Join-Path $packageRoot "APL_Editorial_Completion_Audit_${ScanDate}.json"
$scanDateRoot=Join-Path $allowedRoot $ScanDate
function New-AplEditorialEvidence([string]$Path,[string]$Role){$item=Get-Item -LiteralPath $Path;return [pscustomobject]@{Role=$Role;RelativePath=$item.FullName.Substring($scanDateRoot.TrimEnd('\').Length+1).Replace('\','/');Size=[long]$item.Length;SHA256=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash}}
$audit=[ordered]@{
  SchemaVersion=[string]$readinessContract.SchemaVersion
  ScanDate=$ScanDate
  Status='PASS'
  EditorialCompletion=$true
  ProductionReadiness=$true
  DailyProductionPublishableCandidate=$true
  MandatorySections=[string[]]$editorial.MandatorySections
  CoreTitle=[string]$editorial.MarkdownTitle
  Sources=[object[]]@(
    (New-AplEditorialEvidence $InputCsv 'cumulative-screener'),
    (New-AplEditorialEvidence $MarketContextPath 'market-context'),
    (New-AplEditorialEvidence $TopGainersCsvPath 'top-gainers'),
    (New-AplEditorialEvidence $TriggerBMetaPath 'trigger-b-meta'),
    (New-AplEditorialEvidence $TableCardManifestPath 'table-card-manifest'),
    (New-AplEditorialEvidence $tableCardSources['ExecutiveSummary'].Path 'table-card-executive-summary'),
    (New-AplEditorialEvidence $tableCardSources['TopLeaders'].Path 'table-card-top-leaders'),
    (New-AplEditorialEvidence $tableCardSources['TopGainers'].Path 'table-card-top-gainers'),
    (New-AplEditorialEvidence $tableCardSources['SectorStructure'].Path 'table-card-sector-structure'),
    (New-AplEditorialEvidence $CoverBriefPath 'cover-brief'),
    (New-AplEditorialEvidence $CoverBackgroundPath 'cover-native-background'),
    (New-AplEditorialEvidence $SeoBackgroundPath 'seo-native-background'),
    (New-AplEditorialEvidence $CoverNativeContractPath 'cover-native-contract'),
    (New-AplEditorialEvidence $SeoNativeContractPath 'seo-native-contract')
  )
  Artifacts=[object[]]@(
    (New-AplEditorialEvidence $blogMarkdownPath 'blog-markdown'),
    (New-AplEditorialEvidence $blogHtmlPath 'blog-html'),
    (New-AplEditorialEvidence $whatsAppPath 'whatsapp'),
    (New-AplEditorialEvidence $companyPath 'company-business-analysis')
  )
  MarketContextIntegrity=$editorial.MarketContextIntegrity
  TableCardSourceIntegrity=$tableCardIntegrity
  NativeCompositionIntegrity=[ordered]@{SceneConceptId=$sceneId;CoverSourceSHA256=$coverSha;SeoSourceSHA256=$seoSha;DistinctSourcePaths=$true;DistinctSourceSHA256=$true;NativeAspectRatios=$true;DistinctViewpoints=$true}
  Checks=[ordered]@{NoPlaceholder=$true;MandatorySections=$true;SectionOrder=$true;SubstantiveContent=$true;DetailedMarketContext=$true;MarkdownHtmlEquivalent=$true;TriggerBDataMatch=$true;TopGainersEvidence=$true;ConclusionResponds=$true;WhatsAppFirstScreen=$true;CompanyAnalysis=$true;IntakeSourceIntegrity=$true;TableCardSourceIntegrity=$true;NativeCompositionIntegrity=$true}
}
$actualSourceRoles=@($audit.Sources|ForEach-Object{[string]$_.Role})
if(Compare-Object @($readinessContract.RequiredSourceRoles) $actualSourceRoles){throw 'Editorial readiness source roles do not match the Production Artifact Contract.'}
$actualChecks=@($audit.Checks.Keys|ForEach-Object{[string]$_})
if(Compare-Object @($readinessContract.RequiredChecks) $actualChecks){throw 'Editorial readiness checks do not match the Production Artifact Contract.'}
if(Test-Path -LiteralPath $editorialAuditPath -PathType Leaf){
  $existingAudit=Read-AplStrictJson $editorialAuditPath $packageRoot
  if([string]$existingAudit.SchemaVersion-cne[string]$audit.SchemaVersion-or[string]$existingAudit.ScanDate-cne$ScanDate-or[string]$existingAudit.Status-cne'PASS'-or$existingAudit.EditorialCompletion-ne$true-or$existingAudit.ProductionReadiness-ne$true-or$existingAudit.DailyProductionPublishableCandidate-ne$true){throw 'Existing Editorial Completion Audit is invalid.'}
  foreach($collectionName in @('Sources','Artifacts')){foreach($record in @($audit[$collectionName])){$existing=@($existingAudit.$collectionName|Where-Object{[string]$_.Role-ceq[string]$record.Role});if($existing.Count-ne1-or[string]$existing[0].RelativePath-cne[string]$record.RelativePath-or[string]$existing[0].SHA256-cne[string]$record.SHA256-or[long]$existing[0].Size-ne[long]$record.Size){throw "Existing Editorial Completion Audit $collectionName mismatch: $($record.Role)"}}}
  foreach($check in $audit.Checks.Keys){if($null-eq$existingAudit.Checks.PSObject.Properties[$check]-or$existingAudit.Checks.$check-ne$true){throw "Existing Editorial Completion Audit check is not PASS: $check"}}
  if($null-eq$existingAudit.MarketContextIntegrity-or[string]$existingAudit.MarketContextIntegrity.CoreThesis-cne[string]$audit.MarketContextIntegrity.CoreThesis-or[string]$existingAudit.MarketContextIntegrity.CoverBriefCoreThesis-cne[string]$audit.MarketContextIntegrity.CoverBriefCoreThesis-or$existingAudit.MarketContextIntegrity.MechanicalIntegrity-ne$true-or$existingAudit.MarketContextIntegrity.CrossPlatformThesisAligned-ne$true){throw 'Existing Editorial Completion Audit MarketContextIntegrity mismatch.'}
  if($null-eq$existingAudit.TableCardSourceIntegrity-or[int]$existingAudit.TableCardSourceIntegrity.ExecutiveRows-ne[int]$audit.TableCardSourceIntegrity.ExecutiveRows){throw 'Existing Editorial Completion Audit ExecutiveSummary row evidence mismatch.'}
}else{
  Write-AplUtf8Atomic $editorialAuditPath ($audit|ConvertTo-Json -Depth 10) $packageRoot|Out-Null
}
[pscustomobject]@{Status='MANAGED INPUT PREFLIGHT PASS';ScanDate=$ScanDate;InputRows=$csv.Rows.Count;RequiredTableCards=4;TableCardSourceIntegrity='PASS';PublishingArtifacts=($requiredPublishing.Count+1);NativeSceneConceptId=$sceneId;NativeCompositions=2;EditorialCompletion='PASS';ProductionReadiness='PASS';EditorialAudit=$editorialAuditPath;DailyProductionPublishableCandidate=$true;ProductionStarted=$false}
