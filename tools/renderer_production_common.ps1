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

function Assert-AplTableCardContract($Json, [string]$ExpectedCardType = '') {
  $label = 'Table card input'
  $allowed = @('SchemaVersion','CardType','Title','Subtitle','Columns','Rows','SourceNote','FooterNote','Meta')
  Assert-AplObjectProperties $Json $allowed @('SchemaVersion','Title','Rows') $label
  Assert-AplStringProperty $Json 'SchemaVersion' $label -Required -NonEmpty
  if ([string]$Json.SchemaVersion -ne 'APL Table Card Input v1.0') { throw "$label SchemaVersion must be 'APL Table Card Input v1.0'." }
  Assert-AplStringProperty $Json 'Title' $label -Required -NonEmpty
  foreach ($name in @('Subtitle','SourceNote','FooterNote')) { Assert-AplStringProperty $Json $name $label }
  $cardTypes = @('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure','MarketObservation','Comparison')
  if ($null -ne $Json.PSObject.Properties['CardType']) {
    Assert-AplStringProperty $Json 'CardType' $label -NonEmpty
    if ($cardTypes -notcontains [string]$Json.CardType) { throw "$label CardType '$($Json.CardType)' is invalid." }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedCardType) -and [string]$Json.CardType -ne $ExpectedCardType) { throw "$label CardType '$($Json.CardType)' does not match expected '$ExpectedCardType'." }
  }
  $effectiveCardType = if (-not [string]::IsNullOrWhiteSpace($ExpectedCardType)) { $ExpectedCardType } elseif ($null -ne $Json.PSObject.Properties['CardType']) { [string]$Json.CardType } else { '' }
  $canonicalTopGainersTitle = ((-join (@(0x6700,0x8FD1,0x0037,0x65E5) | ForEach-Object { [char]$_ })) + ' Top Gainers')
  if ($effectiveCardType -eq 'TopGainers' -and [string]$Json.Title -cne $canonicalTopGainersTitle) { throw "$label Title for TopGainers must match the canonical title exactly." }
  if ($Json.Rows -isnot [array]) { throw "$label Rows must be a JSON array." }
  $rows = @($Json.Rows)
  if ($rows.Count -lt 1 -or $rows.Count -gt 8) { throw "$label Rows must contain 1-8 rows." }
  foreach ($row in $rows) {
    if ($row -isnot [array]) { throw "$label row must be a JSON array." }
    $cells = @($row)
    if ($cells.Count -lt 1 -or $cells.Count -gt 5) { throw "$label row must contain 1-5 cells." }
    foreach ($cell in $cells) {
      if ($null -ne $cell -and $cell -isnot [string] -and $cell -isnot [bool] -and -not (Test-AplJsonNumber $cell)) { throw "$label row cells must be string, number, boolean, or null." }
    }
  }
  if ($null -ne $Json.PSObject.Properties['Columns']) {
    if ($Json.Columns -isnot [array]) { throw "$label Columns must be a JSON array." }
    $columns = @($Json.Columns)
    if ($columns.Count -lt 1 -or $columns.Count -gt 5) { throw "$label Columns must contain 1-5 items." }
    foreach ($column in $columns) {
      Assert-AplObjectProperties $column @('Label','Width','Align','Bold') @('Label','Width') "$label column"
      Assert-AplStringProperty $column 'Label' "$label column" -Required -NonEmpty
      if (-not (Test-AplJsonNumber $column.Width) -or [double]$column.Width -le 0) { throw "$label column Width must be a number greater than zero." }
      if ($null -ne $column.PSObject.Properties['Align']) {
        Assert-AplStringProperty $column 'Align' "$label column"
        if (@('Near','Center','Far') -notcontains [string]$column.Align) { throw "$label column Align is invalid." }
      }
      if ($null -ne $column.PSObject.Properties['Bold'] -and $column.Bold -isnot [bool]) { throw "$label column Bold must be boolean." }
    }
  }
  if ($null -ne $Json.PSObject.Properties['Meta']) {
    Assert-AplObjectProperties $Json.Meta @('Date','Source','MarketTheme','ProductionNote') @() "$label Meta"
    foreach ($name in @('Date','Source','MarketTheme','ProductionNote')) { Assert-AplStringProperty $Json.Meta $name "$label Meta" }
    if ($null -ne $Json.Meta.PSObject.Properties['Date'] -and [string]$Json.Meta.Date -notmatch '^\d{4}-\d{2}-\d{2}$') { throw "$label Meta.Date must use YYYY-MM-DD." }
  }
  return [pscustomobject]@{ SchemaVersion=[string]$Json.SchemaVersion; CardType=if ($null -ne $Json.CardType) { [string]$Json.CardType } else { 'not provided' }; Rows=$rows.Count }
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
      Assert-AplObjectProperties $contract.Meta @('ProductionMode','ProductionNote') @() 'Runtime contract Meta'
      Assert-AplStringProperty $contract.Meta 'ProductionMode' 'Runtime contract Meta'
      Assert-AplStringProperty $contract.Meta 'ProductionNote' 'Runtime contract Meta'
      if ($null -ne $contract.Meta.ProductionMode -and @('Deep-Scan Research Mode','Blog Production Mode') -notcontains [string]$contract.Meta.ProductionMode) { throw 'Runtime contract Meta.ProductionMode is invalid; Regression/Test authority is CLI-only.' }
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
  if ([string]::IsNullOrWhiteSpace($LogoPath)) { $LogoPath = Join-Path $projectRoot 'outputs\APL_Deep_Scan_Brand_Logo_Renderer_Clean_2026-06-28.png' }
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
