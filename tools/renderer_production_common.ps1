$script:AplProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Read-AplUtf8Json([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { throw 'JSON path is required.' }
  if (!(Test-Path -LiteralPath $Path -PathType Leaf)) { throw "JSON file not found: $Path" }
  try { return ([System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) | ConvertFrom-Json) }
  catch { throw "Invalid JSON '$Path': $($_.Exception.Message)" }
}

function Get-AplFullPath([string]$Path, [string]$BasePath = '') {
  if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
  if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path) }
  if ([string]::IsNullOrWhiteSpace($BasePath)) { $BasePath = $script:AplProjectRoot }
  return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Assert-AplProductionPath([string]$Path, [string]$Label, [switch]$RegressionTest) {
  if ([string]::IsNullOrWhiteSpace($Path)) { throw "$Label is required." }
  $full = Get-AplFullPath $Path
  $normalized = $full.Replace('/', '\').TrimEnd('\')
  $legacyPrefix = 'C:\Users\user\Documents\Codex\'
  if ($normalized.StartsWith($legacyPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "$Label uses forbidden legacy Codex path: $full"
  }
  if ($normalized -match '(?i)(^|\\)(prototype|pre-migration backup)(\\|$)') {
    throw "$Label uses forbidden production path: $full"
  }
  if (-not $RegressionTest -and $normalized -match '(?i)(^|\\)tmp(\\|$)') {
    throw "$Label cannot use tmp in production mode: $full"
  }
  return $full
}

function Test-AplValueEqual($Left, $Right) {
  if ($null -eq $Left -and $null -eq $Right) { return $true }
  return ([string]$Left).Trim() -ceq ([string]$Right).Trim()
}

function Test-AplJsonInteger($Value) {
  return ($Value -is [byte] -or $Value -is [sbyte] -or $Value -is [int16] -or $Value -is [uint16] -or $Value -is [int32] -or $Value -is [uint32] -or $Value -is [int64] -or $Value -is [uint64])
}

function Test-AplJsonNumber($Value) {
  return ((Test-AplJsonInteger $Value) -or $Value -is [single] -or $Value -is [double] -or $Value -is [decimal])
}

function Enter-AplNamedMutex([string]$Scope, [string]$Label) {
  if ([string]::IsNullOrWhiteSpace($Scope)) { throw "$Label mutex scope is required." }
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { $hash = ([System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Scope)))).Replace('-', '') }
  finally { $sha.Dispose() }
  $name = "Global\APL_US_STOCK_$hash"
  $mutex = New-Object System.Threading.Mutex($false, $name)
  $acquired = $false
  try {
    try { $acquired = $mutex.WaitOne(0, $false) }
    catch [System.Threading.AbandonedMutexException] { $acquired = $true }
    if (-not $acquired) { throw "$Label is already active for scope: $Scope" }
    return $mutex
  } catch {
    $mutex.Dispose()
    throw
  }
}

function Exit-AplNamedMutex($Mutex) {
  if ($null -eq $Mutex) { return }
  try { $Mutex.ReleaseMutex() } finally { $Mutex.Dispose() }
}

function Assert-AplObjectProperties($Object, [string[]]$Allowed, [string[]]$Required, [string]$Label) {
  if ($null -eq $Object -or $Object -isnot [pscustomobject]) { throw "$Label must be a JSON object." }
  $names = @($Object.PSObject.Properties.Name)
  foreach ($name in $Required) { if ($names -notcontains $name) { throw "$Label missing required property '$name'." } }
  foreach ($name in $names) { if ($Allowed -notcontains $name) { throw "$Label contains unsupported property '$name'." } }
}

function Assert-AplStringProperty($Object, [string]$Name, [string]$Label, [switch]$Required, [switch]$NonEmpty) {
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { if ($Required) { throw "$Label missing required property '$Name'." }; return }
  if ($property.Value -isnot [string]) { throw "$Label property '$Name' must be a string." }
  if ($NonEmpty -and [string]::IsNullOrWhiteSpace([string]$property.Value)) { throw "$Label property '$Name' cannot be empty." }
}

function Get-AplTableCardPresentation([object]$Json, [string]$CardType, [switch]$RequireChineseDirection, [switch]$RequireChineseExecutiveSummary) {
  $columns = New-Object System.Collections.Generic.List[object]
  $displayRows = New-Object System.Collections.Generic.List[object]
  $rowIndex = 0

  switch ($CardType) {
    'ExecutiveSummary' {
      $executiveRows = @($Json.Rows)
      if ($executiveRows.Count -lt 3 -or $executiveRows.Count -gt 5) { throw 'Table card input ExecutiveSummary must contain 3 to 5 priority observations.' }
      foreach ($column in @(
        [pscustomobject]@{ Key='observation'; Label='Observation'; Width=0.42; Align='Near'; Bold=$true },
        [pscustomobject]@{ Key='meaning'; Label='Meaning'; Width=0.58; Align='Near'; Bold=$false }
      )) { [void]$columns.Add($column) }
      foreach ($row in $executiveRows) {
        $rowIndex++
        Assert-AplObjectProperties $row @('observation','meaning') @('observation','meaning') "Table card input ExecutiveSummary row $rowIndex"
        foreach ($key in @('observation','meaning')) { Assert-AplStringProperty $row $key "Table card input ExecutiveSummary row $rowIndex" -Required -NonEmpty }
        if ($RequireChineseExecutiveSummary -and [string]$row.observation -notmatch '[\u3400-\u9FFF]') { throw "Table card input ExecutiveSummary row $rowIndex observation must contain Chinese reader-facing analysis." }
        if ($RequireChineseExecutiveSummary -and [string]$row.meaning -notmatch '[\u3400-\u9FFF]') { throw "Table card input ExecutiveSummary row $rowIndex meaning must contain Chinese explanation." }
        if ($RequireChineseExecutiveSummary -and [string]$row.observation -match '^\s*(?:Universe|qualified|Top\s*30|Leader\s*Lock|average\s+Momentum|average\s+Buyability|final\s+watchlist)\b') { throw "Table card input ExecutiveSummary row $rowIndex observation cannot be a raw machine metric label dump." }
        [void]$displayRows.Add([object[]]@([string]$row.observation,[string]$row.meaning))
      }
    }
    'TopLeaders' {
      foreach ($column in @(
        [pscustomobject]@{ Key='rank'; Label='Rank'; Width=0.07; Align='Center'; Bold=$true },
        [pscustomobject]@{ Key='symbol'; Label='Symbol'; Width=0.09; Align='Center'; Bold=$true },
        [pscustomobject]@{ Key='companyName'; Label='Company'; Width=0.24; Align='Near'; Bold=$false },
        [pscustomobject]@{ Key='coreBusiness'; Label='Core Business'; Width=0.19; Align='Near'; Bold=$false },
        [pscustomobject]@{ Key='mainDriver'; Label='Main Driver'; Width=0.30; Align='Near'; Bold=$false },
        [pscustomobject]@{ Key='compositeScore'; Label='Score'; Width=0.11; Align='Far'; Bold=$true }
      )) { [void]$columns.Add($column) }
      foreach ($row in @($Json.Rows)) {
        $rowIndex++
        $required = @('rank','symbol','companyName','coreBusiness','mainDriver','compositeScore')
        Assert-AplObjectProperties $row $required $required "Table card input TopLeaders row $rowIndex"
        foreach ($key in @('rank','symbol','companyName','coreBusiness','mainDriver')) { Assert-AplStringProperty $row $key "Table card input TopLeaders row $rowIndex" -Required -NonEmpty }
        if ([string]$row.rank -notmatch '^#[1-9][0-9]*$') { throw "Table card input TopLeaders row $rowIndex rank must use '#N' only." }
        if ([string]$row.symbol -notmatch '^[A-Z0-9][A-Z0-9.-]*$') { throw "Table card input TopLeaders row $rowIndex symbol is invalid." }
        if (-not (Test-AplJsonNumber $row.compositeScore)) { throw "Table card input TopLeaders row $rowIndex compositeScore must be a JSON number." }
        $score = [double]$row.compositeScore
        if ([double]::IsNaN($score) -or [double]::IsInfinity($score)) { throw "Table card input TopLeaders row $rowIndex compositeScore must be finite." }
        [void]$displayRows.Add([object[]]@([string]$row.rank,[string]$row.symbol,[string]$row.companyName,[string]$row.coreBusiness,[string]$row.mainDriver,$score.ToString('0.##',[Globalization.CultureInfo]::InvariantCulture)))
      }
    }
    'TopGainers' {
      foreach ($column in @(
        [pscustomobject]@{ Key='symbol'; Label='Symbol'; Width=0.13; Align='Center'; Bold=$true },
        [pscustomobject]@{ Key='companyName'; Label='Company'; Width=0.34; Align='Near'; Bold=$false },
        [pscustomobject]@{ Key='sectorTheme'; Label='Sector / Theme'; Width=0.35; Align='Near'; Bold=$false },
        [pscustomobject]@{ Key='changePct'; Label='Change'; Width=0.18; Align='Far'; Bold=$true }
      )) { [void]$columns.Add($column) }
      foreach ($row in @($Json.Rows)) {
        $rowIndex++
        $required = @('symbol','companyName','sectorTheme','changePct')
        Assert-AplObjectProperties $row $required $required "Table card input TopGainers row $rowIndex"
        foreach ($key in $required) { Assert-AplStringProperty $row $key "Table card input TopGainers row $rowIndex" -Required -NonEmpty }
        if ([string]$row.symbol -notmatch '^[A-Z0-9][A-Z0-9.-]*$') { throw "Table card input TopGainers row $rowIndex symbol is invalid." }
        if ([string]$row.sectorTheme -match '^[+-]?\d+(?:\.\d+)?%$') { throw "Table card input TopGainers row $rowIndex sectorTheme cannot contain the percentage value." }
        if ([string]$row.changePct -notmatch '^[+-]\d+(?:\.\d{1,2})?%$') { throw "Table card input TopGainers row $rowIndex changePct must be a signed percentage." }
        [void]$displayRows.Add([object[]]@([string]$row.symbol,[string]$row.companyName,[string]$row.sectorTheme,[string]$row.changePct))
      }
    }
    'SectorStructure' {
      foreach ($column in @(
        [pscustomobject]@{ Key='theme,count'; Label='Theme'; Width=0.20; Align='Near'; Bold=$true },
        [pscustomobject]@{ Key='direction'; Label='Direction'; Width=0.36; Align='Near'; Bold=$false },
        [pscustomobject]@{ Key='representativeSymbols'; Label='Representative Symbols'; Width=0.44; Align='Near'; Bold=$true }
      )) { [void]$columns.Add($column) }
      foreach ($row in @($Json.Rows)) {
        $rowIndex++
        $required = @('theme','count','direction','representativeSymbols')
        Assert-AplObjectProperties $row $required $required "Table card input SectorStructure row $rowIndex"
        foreach ($key in @('theme','direction','representativeSymbols')) { Assert-AplStringProperty $row $key "Table card input SectorStructure row $rowIndex" -Required -NonEmpty }
        if (-not (Test-AplJsonNumber $row.count) -or [double]$row.count -lt 1 -or [math]::Truncate([double]$row.count) -ne [double]$row.count) { throw "Table card input SectorStructure row $rowIndex count must be a positive integer." }
        $symbolListPattern = '^[A-Z0-9][A-Z0-9.-]*(?:,\s*[A-Z0-9][A-Z0-9.-]*)*$'
        if ([string]$row.representativeSymbols -notmatch $symbolListPattern) { throw "Table card input SectorStructure row $rowIndex representativeSymbols must be a comma-separated symbol list." }
        if ([string]$row.direction -match $symbolListPattern) { throw "Table card input SectorStructure row $rowIndex direction cannot contain only symbols." }
        if ($RequireChineseDirection -and [string]$row.direction -notmatch '[\u3400-\u9FFF]') { throw "Table card input SectorStructure row $rowIndex direction must contain Chinese market-structure text." }
        [void]$displayRows.Add([object[]]@("$($row.theme) | $([int]$row.count)",[string]$row.direction,[string]$row.representativeSymbols))
      }
    }
    'MarketObservation' {
      foreach ($column in @(
        [pscustomobject]@{ Key='observation'; Label='Observation'; Width=0.38; Align='Near'; Bold=$true },
        [pscustomobject]@{ Key='meaning'; Label='Meaning'; Width=0.37; Align='Near'; Bold=$false },
        [pscustomobject]@{ Key='evidence'; Label='Evidence'; Width=0.25; Align='Near'; Bold=$false }
      )) { [void]$columns.Add($column) }
      foreach ($row in @($Json.Rows)) {
        $rowIndex++
        $required = @('observation','meaning','evidence')
        Assert-AplObjectProperties $row $required $required "Table card input MarketObservation row $rowIndex"
        foreach ($key in $required) { Assert-AplStringProperty $row $key "Table card input MarketObservation row $rowIndex" -Required -NonEmpty }
        [void]$displayRows.Add([object[]]@([string]$row.observation,[string]$row.meaning,[string]$row.evidence))
      }
    }
    'Comparison' {
      foreach ($column in @(
        [pscustomobject]@{ Key='signal'; Label='Signal'; Width=0.28; Align='Near'; Bold=$true },
        [pscustomobject]@{ Key='whatItShows'; Label='What It Shows'; Width=0.34; Align='Near'; Bold=$false },
        [pscustomobject]@{ Key='marketMeaning'; Label='Market Meaning'; Width=0.38; Align='Near'; Bold=$false }
      )) { [void]$columns.Add($column) }
      foreach ($row in @($Json.Rows)) {
        $rowIndex++
        $required = @('signal','whatItShows','marketMeaning')
        Assert-AplObjectProperties $row $required $required "Table card input Comparison row $rowIndex"
        foreach ($key in $required) { Assert-AplStringProperty $row $key "Table card input Comparison row $rowIndex" -Required -NonEmpty }
        [void]$displayRows.Add([object[]]@([string]$row.signal,[string]$row.whatItShows,[string]$row.marketMeaning))
      }
    }
    default { throw "Unsupported Table Card type '$CardType'." }
  }

  foreach ($row in $displayRows.ToArray()) {
    if (@($row).Count -ne $columns.Count) { throw "Table card input $CardType header count does not match rendered row field count." }
    foreach ($cell in @($row)) { if ([string]::IsNullOrWhiteSpace([string]$cell)) { throw "Table card input $CardType rendered field cannot be empty." } }
  }
  return [pscustomobject]@{ Columns=[object[]]$columns.ToArray(); Rows=[object[]]$displayRows.ToArray() }
}

function Get-AplCanonicalTopGainersTitle {
  return ('Top Gainers ' + [char]0x2014 + ' Past 7 Days')
}

function Get-AplBlogHeadingMap {
  param([Parameter(Mandatory = $true)][string]$ScanDate)
  $scanDateValue = [datetime]::ParseExact($ScanDate, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
  $bilingualFrom = [datetime]::ParseExact('2026-08-05', 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
  $bilingual = $scanDateValue -ge $bilingualFrom
  $englishTopGainers = Get-AplCanonicalTopGainersTitle
  if ($bilingual) {
    return [ordered]@{
      ExecutiveSummary = 'Executive Summary' + [char]0xFF5C + [char]0x57F7 + [char]0x884C + [char]0x6458 + [char]0x8981
      MarketContext = 'Market Context' + [char]0xFF5C + [char]0x5E02 + [char]0x5834 + [char]0x80CC + [char]0x666F
      WhyAPL = 'Why APL Momentum Leaders Matter' + [char]0xFF5C + [char]0x70BA + [char]0x4EC0 + [char]0x9EBC + [char]0x8981 + [char]0x770B + [char]0x9818 + [char]0x5C0E + [char]0x80A1 + [char]0xFF1F
      DeepScanOverview = 'Deep-Scan Overview' + [char]0xFF5C + [char]0x6DF1 + [char]0x5EA6 + [char]0x6383 + [char]0x63CF + [char]0x6982 + [char]0x89BD
      TopGainers = $englishTopGainers + [char]0xFF5C + [char]0x6700 + [char]0x8FD1 + [char]0x4E03 + [char]0x65E5 + [char]0x5347 + [char]0x5E45 + [char]0x699C
      MomentumLeaders = 'Momentum Leaders Analysis' + [char]0xFF5C + [char]0x52D5 + [char]0x80FD + [char]0x9818 + [char]0x5C0E + [char]0x80A1 + [char]0x5206 + [char]0x6790
      SectorAnalysis = 'Sector Analysis' + [char]0xFF5C + [char]0x677F + [char]0x584A + [char]0x7D50 + [char]0x69CB + [char]0x5206 + [char]0x6790
      InvestmentImplication = 'Investment Implication' + [char]0xFF5C + [char]0x6295 + [char]0x8CC7 + [char]0x555F + [char]0x793A
      Risk = 'Risk' + [char]0xFF5C + [char]0x98A8 + [char]0x96AA
      DeepScanConclusion = 'Deep-Scan Conclusion' + [char]0xFF5C + [char]0x6DF1 + [char]0x5EA6 + [char]0x6383 + [char]0x63CF + [char]0x7D50 + [char]0x8AD6
      CallToAction = 'Call to Action' + [char]0xFF5C + [char]0x5EF6 + [char]0x4F38 + [char]0x95B1 + [char]0x8B80
      Disclaimer = 'Disclaimer' + [char]0xFF5C + [char]0x514D + [char]0x8CAC + [char]0x8072 + [char]0x660E
    }
  }
  return [ordered]@{
    ExecutiveSummary = 'Executive Summary'
    MarketContext = 'Market Context'
    WhyAPL = '' + [char]0x70BA + [char]0x4EC0 + [char]0x9EBC + [char]0x8981 + [char]0x770B + ' APL Momentum Leaders ' + [char]0x9818 + [char]0x5C0E + [char]0x80A1 + [char]0xFF1F
    DeepScanOverview = 'Deep-Scan Overview'
    TopGainers = $englishTopGainers
    MomentumLeaders = 'Momentum Leaders Analysis'
    SectorAnalysis = 'Sector Analysis'
    InvestmentImplication = 'Investment Implication'
    Risk = 'Risk'
    DeepScanConclusion = 'Deep-Scan Conclusion'
    CallToAction = 'Call to Action'
    Disclaimer = 'Disclaimer'
  }
}

function Get-AplEditorialProseParagraphs {
  param([Parameter(Mandatory = $true)][string]$Section)
  $paragraphs = New-Object System.Collections.Generic.List[string]
  foreach ($block in @($Section -split '(?:\r?\n){2,}')) {
    $value = $block.Trim()
    if ([string]::IsNullOrWhiteSpace($value) -or $value -match '^(?:#{1,6}|[-*+]\s|\d+[.)]\s)') { continue }
    $plain = (($value -replace '<[^>]+>', ' ') -replace '[`*_\[\]]', ' ' -replace '\s+', ' ').Trim()
    if (-not [string]::IsNullOrWhiteSpace($plain)) { [void]$paragraphs.Add($plain) }
  }
  return [string[]]$paragraphs.ToArray()
}

function Assert-AplEditorialBalancedPunctuation {
  param([Parameter(Mandatory = $true)][string]$Text, [Parameter(Mandatory = $true)][string]$Label)
  foreach ($pair in @(@([char]0xFF08, [char]0xFF09), @('(', ')'))) {
    $openCount = @($Text.ToCharArray() | Where-Object { $_ -eq $pair[0] }).Count
    $closeCount = @($Text.ToCharArray() | Where-Object { $_ -eq $pair[1] }).Count
    if ($openCount -ne $closeCount) { throw "$Label contains unbalanced parentheses." }
  }
  return $true
}

function Assert-AplClientFacingEditorialLanguage {
  param([Parameter(Mandatory = $true)][string]$Text, [Parameter(Mandatory = $true)][string]$Label)
  $forbidden = '(?i)\b(?:Trigger\s*B|managed\s+inputs?|universe|qualified|leaderLock|removedBelowSma200Count|finalWatchlistCount|averageMomentum|averageBuyability|fullRankingCsv|runtime\s+contract|renderer|validator|pipeline)\b|受管(?:輸入|來源|排名|\s*Trigger)|正式\s*Production'
  $match = [regex]::Match($Text, $forbidden)
  if ($match.Success) { throw "$Label exposes internal Production terminology: $($match.Value)" }
  return $true
}

function Assert-AplEditorialParagraphQuality {
  param(
    [Parameter(Mandatory = $true)][string]$Section,
    [Parameter(Mandatory = $true)][string]$Label,
    [int]$MinimumParagraphs = 1,
    [int]$MaximumSemicolonsPerParagraph = 3
  )
  $paragraphs = @(Get-AplEditorialProseParagraphs -Section $Section)
  if ($paragraphs.Count -lt $MinimumParagraphs) { throw "$Label must contain at least $MinimumParagraphs natural prose paragraphs." }
  foreach ($paragraph in $paragraphs) {
    $semicolonCount = @($paragraph.ToCharArray() | Where-Object { $_ -eq ';' -or $_ -eq [char]0xFF1B }).Count
    if ($semicolonCount -gt $MaximumSemicolonsPerParagraph) { throw "$Label contains a machine-shaped semicolon list instead of natural prose." }
  }
  Assert-AplEditorialBalancedPunctuation -Text $Section -Label $Label | Out-Null
  return [string[]]$paragraphs
}

function Assert-AplEditorialCausalLanguage {
  param([Parameter(Mandatory = $true)][string]$Text, [Parameter(Mandatory = $true)][string]$Label, [int]$MinimumSignals = 2)
  $signals = @([regex]::Matches($Text, '因此|所以|意味|反映|顯示|說明|導致|令|這代表|換言之|然而|但'))
  if ($signals.Count -lt $MinimumSignals) { throw "$Label does not form a causal analytical chain." }
  return $true
}
function Assert-AplWeeklyOpeningLayers {
  param([Parameter(Mandatory = $true)][string]$Text, [Parameter(Mandatory = $true)][string]$Label)
  $plain = (($Text -replace '(?m)^#{1,6}\s+', '' -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim())
  $layers = [ordered]@{
    'why-it-matters' = '為何|重要|意味|代表|關鍵|影響'
    'capital-flow' = '資金|資本|配置|流向|輪動|承接|領導'
    'next-watchpoint' = '後續|下一步|觀察|確認|留意|檢驗|訊號'
  }
  foreach ($layer in $layers.Keys) {
    if ($plain -notmatch [string]$layers[$layer]) { throw "$Label missing required weekly-opening layer: $layer" }
  }
  return $true
}

function Assert-AplInvestmentImplicationLayers {
  param([Parameter(Mandatory = $true)][string]$Text, [Parameter(Mandatory = $true)][string]$Label)
  $plain = (($Text -replace '(?m)^#{1,6}\s+', '' -replace '<[^>]+>', ' ' -replace '\s+', ' ').Trim())
  $layers = [ordered]@{
    'investor-interpretation' = '投資者|投資啟示|配置|取態|選股標準|選擇性'
    'capital-flow-and-leadership' = '資金|資本|流向|輪動|領導|擴散|市場廣度'
    'apl-momentum-leaders-link' = 'APL\s+Momentum\s+Leaders'
    'fundamental-translation' = '收入|盈利|現金流|經濟利益|商業|需求'
    'forward-risk-signal' = '後續|下一步|觀察|確認|訊號|風險|若|警惕'
  }
  foreach ($layer in $layers.Keys) {
    if ($plain -notmatch [string]$layers[$layer]) { throw "$Label missing required investment-implication layer: $layer" }
  }
  $forbidden = '(?i)\b(?:buy|sell|target\s+price|stop\s+loss)\b|買入|賣出|目標價|止蝕'
  $match = [regex]::Match($plain, $forbidden)
  if ($match.Success) { throw "$Label contains a direct trading instruction: $($match.Value)" }
  return $true
}
function Assert-AplCoverSubtitleSemantic {
  param(
    [Parameter(Mandatory = $true)][string]$Subtitle,
    [Parameter(Mandatory = $true)][string]$ScanDate,
    [Parameter(Mandatory = $true)][string[]]$TitleLines
  )
  $value = (($Subtitle -replace '\s+', ' ').Trim())
  if ([string]::IsNullOrWhiteSpace($value)) { throw 'Cover brief overlay subtitle must be non-empty.' }
  if (($value -replace '\s+', '').Length -lt 8) { throw 'Cover brief overlay subtitle must be a substantive description of the headline.' }

  $identityPattern = '(?i)\bAPL\b|DEEP[\s-]*SCAN|MOMENTUM\s+LEADERS|美股深海雷達'
  $identityMatch = [regex]::Match($value, $identityPattern)
  if ($identityMatch.Success) { throw "Cover brief overlay subtitle must describe the headline and must not repeat brand or series identity: $($identityMatch.Value)" }
  if ($value -match '\b\d{4}[-./]\d{2}[-./]\d{2}\b' -or $value.Contains($ScanDate)) {
    throw 'Cover brief overlay subtitle must not repeat the scan date; the renderer-owned kicker already supplies it.'
  }

  $normalizedSubtitle = ($value -replace '[\s｜|:：,，。.!！?？—–-]', '').ToUpperInvariant()
  $normalizedTitle = ((@($TitleLines) -join ' ') -replace '[\s｜|:：,，。.!！?？—–-]', '').ToUpperInvariant()
  if ($normalizedSubtitle -ceq $normalizedTitle -or @($TitleLines | ForEach-Object { (($_ -replace '[\s｜|:：,，。.!！?？—–-]', '').ToUpperInvariant()) }) -contains $normalizedSubtitle) {
    throw 'Cover brief overlay subtitle must add a description and must not duplicate the main title.'
  }
  return $true
}

function Get-AplCanonicalBlogTopGainersTitle {
  param([Parameter(Mandatory = $true)][string]$ScanDate)
  return [string]((Get-AplBlogHeadingMap -ScanDate $ScanDate).TopGainers)
}

function Assert-AplTableCardContract($Json, [string]$ExpectedCardType = '', [switch]$RequireChineseDirection, [switch]$RequireChineseExecutiveSummary) {
  $label = 'Table card input'
  $allowed = @('SchemaVersion','CardType','Title','Subtitle','Columns','Rows','SourceNote','FooterNote','Meta')
  Assert-AplObjectProperties $Json $allowed @('SchemaVersion','CardType','Title','Rows') $label
  Assert-AplStringProperty $Json 'SchemaVersion' $label -Required -NonEmpty
  if ([string]$Json.SchemaVersion -ne 'APL Table Card Input v1.1') { throw "$label SchemaVersion must be 'APL Table Card Input v1.1'." }
  Assert-AplStringProperty $Json 'Title' $label -Required -NonEmpty
  foreach ($name in @('Subtitle','SourceNote','FooterNote')) { Assert-AplStringProperty $Json $name $label }
  $cardTypes = @('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure','MarketObservation','Comparison')
  Assert-AplStringProperty $Json 'CardType' $label -Required -NonEmpty
  if ($cardTypes -notcontains [string]$Json.CardType) { throw "$label CardType '$($Json.CardType)' is invalid." }
  if (-not [string]::IsNullOrWhiteSpace($ExpectedCardType) -and [string]$Json.CardType -ne $ExpectedCardType) { throw "$label CardType '$($Json.CardType)' does not match expected '$ExpectedCardType'." }
  $effectiveCardType = [string]$Json.CardType
  $canonicalTopGainersTitle = Get-AplCanonicalTopGainersTitle
  if ($effectiveCardType -eq 'TopGainers' -and [string]$Json.Title -cne $canonicalTopGainersTitle) { throw "$label Title for TopGainers must match the canonical title exactly." }
  if ($Json.Rows -isnot [array]) { throw "$label Rows must be a JSON array." }
  $rows = @($Json.Rows)
  if ($rows.Count -lt 1 -or $rows.Count -gt 8) { throw "$label Rows must contain 1-8 rows." }
  foreach ($row in $rows) { if ($row -isnot [pscustomobject]) { throw "$label rows must be JSON objects with named semantic fields." } }
  if ($null -ne $Json.PSObject.Properties['Columns']) {
    throw "$label Columns is renderer-owned for v1.1 semantic cards and must not be supplied."
  }
  if ($null -ne $Json.PSObject.Properties['Meta']) {
    Assert-AplObjectProperties $Json.Meta @('Date','Source','MarketTheme','ProductionNote') @() "$label Meta"
    foreach ($name in @('Date','Source','MarketTheme','ProductionNote')) { Assert-AplStringProperty $Json.Meta $name "$label Meta" }
    if ($null -ne $Json.Meta.PSObject.Properties['Date'] -and [string]$Json.Meta.Date -notmatch '^\d{4}-\d{2}-\d{2}$') { throw "$label Meta.Date must use YYYY-MM-DD." }
  }
  $presentation = Get-AplTableCardPresentation $Json $effectiveCardType -RequireChineseDirection:$RequireChineseDirection -RequireChineseExecutiveSummary:$RequireChineseExecutiveSummary
  return [pscustomobject]@{ SchemaVersion=[string]$Json.SchemaVersion; CardType=$effectiveCardType; Rows=$rows.Count; Columns=@($presentation.Columns).Count; Presentation=$presentation }
}

function Resolve-AplRendererInput {
  param(
    [ValidateSet('Dashboard','Social')][string]$ExpectedRendererType,
    [hashtable]$BoundParameters,
    [string]$InputPath,
    [string]$RankingCsv,
    [string]$ScanDate,
    [string]$SectorMapPath,
    [string]$OutputPath,
    [string]$OutputDir,
    [string]$Root,
    [string]$LogoPath,
    [string]$WeekLabel,
    [int]$ScanUniverseCount,
    [int]$ScanQualifiedCount,
    [int]$LeaderCapacity,
    [switch]$RegressionTest
  )
  $projectRoot = if ([string]::IsNullOrWhiteSpace($Root)) { $script:AplProjectRoot } else { Get-AplFullPath $Root }
  if ((Get-AplFullPath $projectRoot) -ne (Get-AplFullPath $script:AplProjectRoot)) {
    throw "Project Root mismatch. Expected '$script:AplProjectRoot', received '$projectRoot'."
  }
  $contract = $null
  $contractBase = $projectRoot
  if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
    $contractPath = Get-AplFullPath $InputPath $projectRoot
    $contract = Read-AplUtf8Json $contractPath
    $contractBase = Split-Path -Parent $contractPath
    foreach ($name in @('SchemaVersion','RendererType','RankingCsv','ScanDate','SectorMapPath','OutputPath')) {
      if ($null -eq $contract.PSObject.Properties[$name] -or [string]::IsNullOrWhiteSpace([string]$contract.$name)) {
        throw "Runtime contract missing required property '$name': $contractPath"
      }
    }
    $allowed = @('SchemaVersion','RendererType','RankingCsv','ScanDate','SectorMapPath','OutputPath','LogoPath','WeekLabel','ScanUniverseCount','ScanQualifiedCount','LeaderCapacity','Meta')
    foreach ($property in $contract.PSObject.Properties.Name) {
      if ($allowed -notcontains $property) { throw "Runtime contract contains unsupported property '$property': $contractPath" }
    }
    Assert-AplStringProperty $contract 'SchemaVersion' 'Runtime contract' -Required -NonEmpty
    if ([string]$contract.SchemaVersion -ne 'APL Deep-Scan Renderer Input v1.0') { throw "Unsupported runtime contract SchemaVersion: $($contract.SchemaVersion)" }
    if ([string]$contract.RendererType -ne $ExpectedRendererType) { throw "Runtime contract RendererType '$($contract.RendererType)' does not match '$ExpectedRendererType'." }
    if ([string]$contract.ScanDate -notmatch '^\d{4}-\d{2}-\d{2}$') { throw "Runtime contract ScanDate is invalid: $($contract.ScanDate)" }
    foreach ($stringName in @('RendererType','RankingCsv','ScanDate','SectorMapPath','OutputPath')) { Assert-AplStringProperty $contract $stringName 'Runtime contract' -Required -NonEmpty }
    foreach ($stringName in @('LogoPath','WeekLabel')) { Assert-AplStringProperty $contract $stringName 'Runtime contract' }
    foreach ($integerName in @('ScanUniverseCount','ScanQualifiedCount','LeaderCapacity')) {
      if ($null -ne $contract.PSObject.Properties[$integerName]) {
        $value = $contract.$integerName
        if (-not (Test-AplJsonInteger $value)) { throw "Runtime contract property '$integerName' must be an integer." }
        if ([long]$value -lt 0) { throw "Runtime contract property '$integerName' cannot be negative." }
      }
    }
    if ($null -ne $contract.LeaderCapacity -and ([int]$contract.LeaderCapacity -lt 1 -or [int]$contract.LeaderCapacity -gt 30)) { throw 'Runtime contract LeaderCapacity must be 1-30.' }
    if ($null -ne $contract.PSObject.Properties['Meta']) {
      Assert-AplObjectProperties $contract.Meta @('ProductionMode','ProductionNote','SocialHeadlineLines','CoreMarketThesis') @() 'Runtime contract Meta'
      Assert-AplStringProperty $contract.Meta 'ProductionMode' 'Runtime contract Meta'
      Assert-AplStringProperty $contract.Meta 'ProductionNote' 'Runtime contract Meta'
      Assert-AplStringProperty $contract.Meta 'CoreMarketThesis' 'Runtime contract Meta'
      if ($null -ne $contract.Meta.ProductionMode -and @('Deep-Scan Research Mode','Blog Production Mode') -notcontains [string]$contract.Meta.ProductionMode) { throw 'Runtime contract Meta.ProductionMode is invalid; Regression/Test authority is CLI-only.' }
      if ($null -ne $contract.Meta.PSObject.Properties['SocialHeadlineLines']) {
        $headlineLines = @($contract.Meta.SocialHeadlineLines)
        if ($headlineLines.Count -lt 1 -or $headlineLines.Count -gt 2) { throw 'Runtime contract Meta.SocialHeadlineLines must contain one or two lines.' }
        foreach ($line in $headlineLines) {
          if ($line -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$line)) { throw 'Runtime contract Meta.SocialHeadlineLines entries must be non-empty strings.' }
        }
      }
      if ($ExpectedRendererType -eq 'Social') {
        $hasHeadline = $null -ne $contract.Meta.PSObject.Properties['SocialHeadlineLines']
        $hasThesis = $null -ne $contract.Meta.PSObject.Properties['CoreMarketThesis'] -and -not [string]::IsNullOrWhiteSpace([string]$contract.Meta.CoreMarketThesis)
        if ($hasHeadline -xor $hasThesis) { throw 'Social runtime contract must provide Meta.SocialHeadlineLines and Meta.CoreMarketThesis together.' }
      }
    }

    $pairs = @{
      RankingCsv='RankingCsv'; ScanDate='ScanDate'; SectorMapPath='SectorMapPath'; OutputPath='OutputPath';
      LogoPath='LogoPath'; WeekLabel='WeekLabel'; ScanUniverseCount='ScanUniverseCount';
      ScanQualifiedCount='ScanQualifiedCount'; LeaderCapacity='LeaderCapacity'
    }
    foreach ($cliName in $pairs.Keys) {
      $jsonName = $pairs[$cliName]
      if ($BoundParameters.ContainsKey($cliName) -and $null -ne $contract.PSObject.Properties[$jsonName]) {
        $cliValue = Get-Variable -Name $cliName -ValueOnly
        if (-not (Test-AplValueEqual $cliValue $contract.$jsonName)) {
          throw "Runtime contract/CLI mismatch for '$cliName'."
        }
      }
    }
    if ($BoundParameters.ContainsKey('OutputDir')) { throw "Runtime contract/CLI mismatch: use OutputPath, not OutputDir, with -InputPath." }
    $RankingCsv = [string]$contract.RankingCsv
    $ScanDate = [string]$contract.ScanDate
    $SectorMapPath = [string]$contract.SectorMapPath
    $OutputPath = [string]$contract.OutputPath
    if ($null -ne $contract.LogoPath) { $LogoPath = [string]$contract.LogoPath }
    if ($null -ne $contract.WeekLabel) { $WeekLabel = [string]$contract.WeekLabel }
    if ($null -ne $contract.ScanUniverseCount) { $ScanUniverseCount = [int]$contract.ScanUniverseCount }
    if ($null -ne $contract.ScanQualifiedCount) { $ScanQualifiedCount = [int]$contract.ScanQualifiedCount }
    if ($null -ne $contract.LeaderCapacity) { $LeaderCapacity = [int]$contract.LeaderCapacity }
  }
  if ([string]::IsNullOrWhiteSpace($RankingCsv)) { throw 'RankingCsv is required through -InputPath or CLI.' }
  if ([string]::IsNullOrWhiteSpace($ScanDate)) { throw 'ScanDate is required through -InputPath or CLI.' }
  if ($ScanDate -notmatch '^\d{4}-\d{2}-\d{2}$') { throw "ScanDate must use YYYY-MM-DD: $ScanDate" }
  if ([string]::IsNullOrWhiteSpace($SectorMapPath)) { $SectorMapPath = Join-Path $projectRoot 'tools\sector_map.json' }
  if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = $OutputDir }
  if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path $projectRoot "outputs\$ScanDate" }
  if ([string]::IsNullOrWhiteSpace($LogoPath)) { $LogoPath = Join-Path $projectRoot 'Assets\Brand\APL_Deep_Scan_Brand_Logo_Renderer_Clean.png' }
  if ($LeaderCapacity -eq 0) { $LeaderCapacity = 30 }
  if ($LeaderCapacity -ne 30) { throw 'Production renderers require LeaderCapacity 30.' }
  $RankingCsv = Assert-AplProductionPath (Get-AplFullPath $RankingCsv $contractBase) 'RankingCsv' -RegressionTest:$RegressionTest
  $SectorMapPath = Assert-AplProductionPath (Get-AplFullPath $SectorMapPath $contractBase) 'SectorMapPath' -RegressionTest:$RegressionTest
  $OutputPath = Assert-AplProductionPath (Get-AplFullPath $OutputPath $contractBase) 'OutputPath' -RegressionTest:$RegressionTest
  if (-not [string]::IsNullOrWhiteSpace($LogoPath)) { $LogoPath = Assert-AplProductionPath (Get-AplFullPath $LogoPath $contractBase) 'LogoPath' -RegressionTest:$RegressionTest }
  return [pscustomobject]@{
    ProjectRoot=$projectRoot; Contract=$contract; RankingCsv=$RankingCsv; ScanDate=$ScanDate; SectorMapPath=$SectorMapPath;
    OutputPath=$OutputPath; LogoPath=$LogoPath; WeekLabel=$WeekLabel; ScanUniverseCount=$ScanUniverseCount;
    ScanQualifiedCount=$ScanQualifiedCount; LeaderCapacity=$LeaderCapacity; RegressionTest=[bool]$RegressionTest
  }
}

function Import-AplRankingCsv([string]$Path) {
  if (!(Test-Path -LiteralPath $Path -PathType Leaf)) { throw "RankingCsv not found: $Path" }
  $rows = @(Import-Csv -LiteralPath $Path -Encoding UTF8)
  if ($rows.Count -eq 0) { throw "RankingCsv has no rows: $Path" }
  $required = @('Rank','Symbol','Momentum Score','Buyability Score','Composite Score','Rel Vol','Perf 6M %','Perf 3M %')
  $headers = @($rows[0].PSObject.Properties.Name)
  foreach ($name in $required) { if ($headers -notcontains $name) { throw "RankingCsv missing required column '$name': $Path" } }
  $seenRanks = @{}; $seenSymbols = @{}; $expectedRank = 1
  foreach ($row in $rows) {
    $rank = 0
    if (-not [int]::TryParse(([string]$row.Rank).Trim(), [ref]$rank)) { throw "Rank is not a valid integer: '$($row.Rank)'" }
    if ($rank -lt 1) { throw "Rank must be a positive integer: $rank" }
    if ($seenRanks.ContainsKey($rank)) { throw "Duplicate Rank: $rank" }
    if ($rank -ne $expectedRank) { throw "RankingCsv row order does not match Rank. Expected $expectedRank, found $rank." }
    $seenRanks[$rank] = $true; $expectedRank++
    $symbol = ([string]$row.Symbol).Trim().ToUpperInvariant()
    if ([string]::IsNullOrWhiteSpace($symbol)) { throw "Symbol is empty at Rank $rank." }
    if ($seenSymbols.ContainsKey($symbol)) { throw "Duplicate Symbol: $symbol" }
    $seenSymbols[$symbol] = $true
    foreach ($name in @('Momentum Score','Buyability Score','Composite Score','Rel Vol','Perf 6M %','Perf 3M %')) {
      $number = 0.0
      if (-not [double]::TryParse(([string]$row.$name).Trim(), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
        throw "Required numeric value '$name' is invalid at Rank ${rank}: '$($row.$name)'"
      }
    }
  }
  foreach ($requiredRank in 1..30) { if (-not $seenRanks.ContainsKey($requiredRank)) { throw "RankingCsv is missing required Rank $requiredRank." } }
  return $rows
}

function Import-AplSectorPresentation([string]$SectorMapPath, [string]$VisualMapPath = '') {
  $sectorJson = Read-AplUtf8Json $SectorMapPath
  if ($null -eq $sectorJson.Symbols -or @($sectorJson.Symbols.PSObject.Properties).Count -eq 0) { throw "Sector map Symbols is missing or empty: $SectorMapPath" }
  if ([string]::IsNullOrWhiteSpace($VisualMapPath)) { $VisualMapPath = Join-Path $PSScriptRoot 'sector_visual_map.json' }
  $visual = Read-AplUtf8Json $VisualMapPath
  Assert-AplObjectProperties $visual @('SchemaVersion','Sectors') @('SchemaVersion','Sectors') 'Sector visual map'
  Assert-AplStringProperty $visual 'SchemaVersion' 'Sector visual map' -Required -NonEmpty
  if ([string]$visual.SchemaVersion -ne 'APL Sector Visual Map v1.0') { throw "Unsupported sector visual map: $VisualMapPath" }
  if ($visual.Sectors -isnot [pscustomobject] -or @($visual.Sectors.PSObject.Properties).Count -eq 0) { throw 'Sector visual map Sectors must be a non-empty JSON object.' }
  $requiredVisualFields = @('Normalized','EnglishLabel','ChineseLabel','Color','MarketTheme','InsightTheme')
  foreach ($sectorProperty in $visual.Sectors.PSObject.Properties) {
    $entryLabel = "Sector visual map entry '$($sectorProperty.Name)'"
    $entry = $sectorProperty.Value
    Assert-AplObjectProperties $entry $requiredVisualFields $requiredVisualFields $entryLabel
    foreach ($field in $requiredVisualFields) { Assert-AplStringProperty $entry $field $entryLabel -Required -NonEmpty }
    if ([string]$entry.Color -notmatch '^#[0-9A-Fa-f]{6}$') { throw "$entryLabel Color must use #RRGGBB." }
  }
  $symbols = @{}; foreach ($p in $sectorJson.Symbols.PSObject.Properties) { $symbols[([string]$p.Name).Trim().ToUpperInvariant()] = [string]$p.Value }
  $entries = @{}; foreach ($p in $visual.Sectors.PSObject.Properties) { $entries[[string]$p.Name] = $p.Value }
  foreach ($entryName in $entries.Keys) { $normalized = [string]$entries[$entryName].Normalized; if (-not $entries.ContainsKey($normalized)) { throw "Sector visual map entry '$entryName' references missing normalized sector '$normalized'." } }
  if (-not $entries.ContainsKey([string]$sectorJson.DefaultSector)) { throw "Sector visual map is missing DefaultSector '$($sectorJson.DefaultSector)'." }
  return [pscustomobject]@{ Symbols=$symbols; DefaultSector=[string]$sectorJson.DefaultSector; Entries=$entries; SchemaVersion=[string]$sectorJson.SchemaVersion; VisualSchemaVersion=[string]$visual.SchemaVersion }
}

function Get-AplNormalizedSector($Presentation, [string]$Sector) {
  if ($Presentation.Entries.ContainsKey($Sector)) { return [string]$Presentation.Entries[$Sector].Normalized }
  if ($Presentation.Entries.ContainsKey($Presentation.DefaultSector)) { return [string]$Presentation.Entries[$Presentation.DefaultSector].Normalized }
  return 'Others'
}
function Get-AplSectorVisual($Presentation, [string]$Sector) {
  $normalized = Get-AplNormalizedSector $Presentation $Sector
  if (-not $Presentation.Entries.ContainsKey($normalized)) { $normalized = 'Others' }
  return $Presentation.Entries[$normalized]
}
