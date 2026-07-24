param(
  [Parameter(Mandatory = $true)]
  [string]$InputCsv,
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
  [string]$ScanDate,
  [Parameter(Mandatory = $true)]
  [string]$WeekLabel,
  [string]$OutputRoot = "",
  [switch]$RegressionTest,
  [string]$RegressionProjectRoot = "",
  [switch]$SkipRootCopies
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')
$InputCsv = Assert-AplProductionPath (Get-AplFullPath $InputCsv) 'InputCsv' -RegressionTest:$RegressionTest
if (!(Test-Path -LiteralPath $InputCsv -PathType Leaf)) { throw "InputCsv not found: $InputCsv" }
$repositoryTmpRoot = Get-AplFullPath (Join-Path $root 'tmp')
if (-not [string]::IsNullOrWhiteSpace($RegressionProjectRoot)) {
  if (-not $RegressionTest) { throw 'RegressionProjectRoot is test-only and requires -RegressionTest.' }
  $RegressionProjectRoot = Get-AplFullPath $RegressionProjectRoot
  if (-not ($RegressionProjectRoot.StartsWith($repositoryTmpRoot.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase))) { throw "RegressionProjectRoot must be inside '$repositoryTmpRoot'." }
}
$effectiveProjectRoot = if ([string]::IsNullOrWhiteSpace($RegressionProjectRoot)) { $root } else { $RegressionProjectRoot }
$isStandaloneTriggerB = [string]::IsNullOrWhiteSpace($OutputRoot)
$outputRootValue = if ($isStandaloneTriggerB) { Join-Path $effectiveProjectRoot "outputs\trigger-b" } else { $OutputRoot }
$outputsRoot = Get-AplFullPath $outputRootValue
$outputsRoot = Assert-AplProductionPath $outputsRoot 'OutputRoot' -RegressionTest:$RegressionTest
$formalRoot = Get-AplFullPath (Join-Path $effectiveProjectRoot 'outputs')
$standaloneRoot = Get-AplFullPath (Join-Path $formalRoot 'trigger-b')
$regressionRoot = $repositoryTmpRoot
if ($RegressionTest) {
  if (-not ($outputsRoot.StartsWith($regressionRoot.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase))) { throw "RegressionTest OutputRoot must be inside '$regressionRoot'." }
} elseif ($isStandaloneTriggerB) {
  if (-not $outputsRoot.Equals($standaloneRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Standalone Trigger B OutputRoot must be '$standaloneRoot'."
  }
} elseif (-not $outputsRoot.StartsWith($formalRoot.TrimEnd('\') + '\.staging\', [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Explicit Production OutputRoot is reserved for an orchestrator staging child."
}
$dateOut = Join-Path $outputsRoot $ScanDate
$dateArtifacts = @(
  "APL_Momentum_Score_Full_Ranking_$ScanDate.csv", "APL_Quant_Top_30_$ScanDate.txt", "APL_Quant_Top_30_$ScanDate.md",
  "APL_Momentum_Leaders_Watchlist_$ScanDate.txt", "removed-below-sma200-$ScanDate.txt", "retained-missing-sma200-$ScanDate.txt",
  "APL_Momentum_Leaders_Overview_$ScanDate.md", "APL_Momentum_Leaders_Meta_$ScanDate.json", "APL_Momentum_Leaders_Source_$ScanDate.csv"
)
$rootArtifacts = if ($SkipRootCopies -or $isStandaloneTriggerB) { @() } else { @($dateArtifacts | Where-Object { $_ -ne "APL_Momentum_Leaders_Source_$ScanDate.csv" }) }
$mutex = Enter-AplNamedMutex ("scoring|$outputsRoot|$ScanDate") 'Scoring/ranking'
try {
foreach ($name in $dateArtifacts) { $path=Join-Path $dateOut $name; if (Test-Path -LiteralPath $path) { throw "Scoring output already exists; refusing overwrite: $path" } }
foreach ($name in $rootArtifacts) { $path=Join-Path $outputsRoot $name; if (Test-Path -LiteralPath $path) { throw "Scoring root output already exists; refusing overwrite: $path" } }
if (!(Test-Path -LiteralPath $outputsRoot)) { New-Item -ItemType Directory -Path $outputsRoot | Out-Null }
if (!(Test-Path -LiteralPath $dateOut)) { New-Item -ItemType Directory -Path $dateOut | Out-Null }

function To-Double($v) {
  if ($null -eq $v) { return 0.0 }
  $s = [string]$v
  $s = $s.Trim().Replace(",", "")
  if ($s -eq "" -or $s -eq "-") { return 0.0 }
  $d = 0.0
  if ([double]::TryParse($s, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d)) {
    return $d
  }
  return 0.0
}

function Test-NumericField($v) {
  if ($null -eq $v) { return $false }
  $s = [string]$v
  $s = $s.Trim().Replace(",", "")
  if ($s -eq "" -or $s -eq "-") { return $false }
  $d = 0.0
  return [double]::TryParse($s, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$d)
}

function Clamp($v, $min, $max) {
  if ($v -lt $min) { return $min }
  if ($v -gt $max) { return $max }
  return $v
}

function Get-Quantile([double[]]$values, [double]$q) {
  if ($values.Count -eq 0) { return 0.0 }
  $sorted = $values | Sort-Object
  if ($sorted.Count -eq 1) { return [double]$sorted[0] }
  $pos = ($sorted.Count - 1) * $q
  $lo = [math]::Floor($pos)
  $hi = [math]::Ceiling($pos)
  if ($lo -eq $hi) { return [double]$sorted[$lo] }
  $w = $pos - $lo
  return ([double]$sorted[$lo] * (1 - $w)) + ([double]$sorted[$hi] * $w)
}

function Scale-Winsor($v, $p5, $p95) {
  if ([math]::Abs($p95 - $p5) -lt 0.000001) { return 50.0 }
  return Clamp ((($v - $p5) / ($p95 - $p5)) * 100.0) 0 100
}

function Get-BuyabilityScore($price, $sma20, $sma50, $price52) {
  if ($sma20 -le 0 -or $sma50 -le 0) { return 0 }
  $dist20 = (($price - $sma20) / $sma20) * 100.0
  $score = 0
  if ($dist20 -ge 0 -and $dist20 -le 3) { $score = 10 }
  elseif ($dist20 -gt 3 -and $dist20 -le 8) { $score = 8 }
  elseif ($dist20 -gt 8 -and $dist20 -le 15) { $score = 5 }
  elseif ($dist20 -gt 15 -and $dist20 -le 25) { $score = 2 }
  elseif ($dist20 -gt 25) { $score = 0 }
  elseif ($dist20 -lt 0 -and $dist20 -ge -3) { $score = 6 }
  elseif ($dist20 -lt -3 -and $dist20 -ge -8) { $score = 3 }
  else { $score = 0 }

  if ($price -lt $sma50) { $score = [math]::Min($score, 1) }
  if ($price52 -lt 75) { $score = [math]::Min($score, 5) }
  return [int]$score
}

function Get-BuyabilityText([int]$score) {
  $full = [string][char]0x2605
  $empty = [string][char]0x2606
  if ($score -ge 8) { $n = 5 }
  elseif ($score -ge 6) { $n = 4 }
  elseif ($score -ge 4) { $n = 3 }
  elseif ($score -ge 2) { $n = 2 }
  else { $n = 1 }
  $suffix = " "
  $suffix += [string][char]0x28
  $suffix += [string]$score
  $suffix += "/10"
  $suffix += [string][char]0x29
  $rating = ($full * $n) + ($empty * (5 - $n))
  return ($rating + $suffix)
}

function Get-RelativeVolumeBonus([double]$relvol) {
  if ($relvol -le 1.1) { return 0 }
  if ($relvol -le 1.5) { return 3 }
  if ($relvol -le 2.0) { return 6 }
  return 10
}

function Read-CsvRobust($path) {
  Add-Type -AssemblyName Microsoft.VisualBasic
  $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($path)
  $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
  $parser.SetDelimiters(",")
  $parser.HasFieldsEnclosedInQuotes = $true

  $rawHeaders = $parser.ReadFields()
  $seen = @{}
  $headers = @()
  foreach ($h in $rawHeaders) {
    $name = ([string]$h).Trim()
    if ($seen.ContainsKey($name)) {
      $seen[$name] += 1
      $headers += "$name`__$($seen[$name])"
    } else {
      $seen[$name] = 1
      $headers += $name
    }
  }

  $rows = New-Object System.Collections.Generic.List[object]
  while (-not $parser.EndOfData) {
    $fields = $parser.ReadFields()
    $obj = [ordered]@{}
    for ($i = 0; $i -lt $headers.Count; $i++) {
      $obj[$headers[$i]] = if ($i -lt $fields.Count) { $fields[$i] } else { "" }
    }
    $rows.Add([pscustomobject]$obj)
  }
  $parser.Close()
  return $rows
}

$rows = Read-CsvRobust $InputCsv

$work = foreach ($r in $rows) {
  $symbol = ([string]$r.Symbol).Trim().ToUpperInvariant()
  if ($symbol -eq "") { continue }
  $price = To-Double $r.Price
  $sma20 = To-Double $r.'Simple moving average, 20, 1 day'
  $sma50 = To-Double $r.'Simple moving average, 50, 1 day'
  $sma200 = To-Double $r.'Simple moving average, 200, 1 day'
  $sma200Valid = ((Test-NumericField $r.'Simple moving average, 200, 1 day') -and $sma200 -gt 0)
  $high52 = To-Double $r.'High, 52 weeks'
  $perf3 = To-Double $r.'Performance %, 3 months'
  $perf6 = To-Double $r.'Performance %, 6 months'
  $relvol = To-Double $r.'Relative volume, 1 day'
  $price52 = if ($high52 -gt 0) { ($price / $high52) * 100.0 } else { 0.0 }
  $dist20 = if ($sma20 -gt 0) { (($price - $sma20) / $sma20) * 100.0 } else { 0.0 }
  $dist50 = if ($sma50 -gt 0) { (($price - $sma50) / $sma50) * 100.0 } else { 0.0 }
  $dist200 = if ($sma200 -gt 0) { (($price - $sma200) / $sma200) * 100.0 } else { 0.0 }
  $belowSma200 = ($sma200Valid -and $sma200 -gt 0 -and $price -lt $sma200)
  $sma200Status = if (-not $sma200Valid) { "Missing SMA200" } elseif ($belowSma200) { "Below SMA200" } else { "Above SMA200" }
  $buy = Get-BuyabilityScore $price $sma20 $sma50 $price52

  [pscustomobject]@{
    Symbol = $symbol
    Name = ([string]$r.Description).Trim()
    Price = $price
    SMA200 = $sma200
    Price52 = $price52
    Dist20 = $dist20
    Dist50 = $dist50
    Dist200 = $dist200
    Sma200Valid = $sma200Valid
    BelowSma200 = $belowSma200
    Sma200Status = $sma200Status
    Perf3 = $perf3
    Perf6 = $perf6
    RelVol = $relvol
    BuyabilityScore = $buy
    Buyability = Get-BuyabilityText $buy
  }
}

$perf6p5 = Get-Quantile ([double[]]($work | ForEach-Object { $_.Perf6 })) 0.05
$perf6p95 = Get-Quantile ([double[]]($work | ForEach-Object { $_.Perf6 })) 0.95
$perf3p5 = Get-Quantile ([double[]]($work | ForEach-Object { $_.Perf3 })) 0.05
$perf3p95 = Get-Quantile ([double[]]($work | ForEach-Object { $_.Perf3 })) 0.95
$dist50p5 = Get-Quantile ([double[]]($work | ForEach-Object { $_.Dist50 })) 0.05
$dist50p95 = Get-Quantile ([double[]]($work | ForEach-Object { $_.Dist50 })) 0.95
$dist200p5 = Get-Quantile ([double[]]($work | ForEach-Object { $_.Dist200 })) 0.05
$dist200p95 = Get-Quantile ([double[]]($work | ForEach-Object { $_.Dist200 })) 0.95
$relp5 = Get-Quantile ([double[]]($work | ForEach-Object { $_.RelVol })) 0.05
$relp95 = Get-Quantile ([double[]]($work | ForEach-Object { $_.RelVol })) 0.95

$scored = foreach ($x in $work) {
  $price52Score = Clamp $x.Price52 0 100
  $perf6Score = Scale-Winsor $x.Perf6 $perf6p5 $perf6p95
  $perf3Score = Scale-Winsor $x.Perf3 $perf3p5 $perf3p95
  $sma50Score = Scale-Winsor $x.Dist50 $dist50p5 $dist50p95
  $sma200Score = Scale-Winsor $x.Dist200 $dist200p5 $dist200p95
  $relScore = Scale-Winsor $x.RelVol $relp5 $relp95
  $buyScore = $x.BuyabilityScore * 10.0
  $rawRvBonus = Get-RelativeVolumeBonus $x.RelVol
  $rvBonus = [math]::Min($rawRvBonus, $x.BuyabilityScore)

  $momentum =
    (0.25 * $price52Score) +
    (0.20 * $perf6Score) +
    (0.15 * $perf3Score) +
    (0.15 * $buyScore) +
    (0.10 * $sma50Score) +
    (0.10 * $sma200Score) +
    (0.05 * $relScore)
  $composite = $momentum + $x.BuyabilityScore + $rvBonus

  $x | Add-Member -NotePropertyName MomentumScore -NotePropertyValue ([math]::Round($momentum, 2)) -PassThru |
       Add-Member -NotePropertyName RawRelativeVolumeBonus -NotePropertyValue $rawRvBonus -PassThru |
       Add-Member -NotePropertyName RelativeVolumeBonus -NotePropertyValue $rvBonus -PassThru |
       Add-Member -NotePropertyName CompositeScore -NotePropertyValue ([math]::Round($composite, 2)) -PassThru
}

$avgComposite = ($scored | Measure-Object -Property CompositeScore -Average).Average
$qualified = @($scored | Where-Object { $_.CompositeScore -gt $avgComposite })
$ranked = @($qualified | Sort-Object @{Expression="CompositeScore";Descending=$true}, @{Expression="MomentumScore";Descending=$true}, @{Expression="RelVol";Descending=$true}, @{Expression="Symbol";Ascending=$true})

$full = for ($i = 0; $i -lt $ranked.Count; $i++) {
  $x = $ranked[$i]
  [pscustomobject]@{
    Rank = $i + 1
    Symbol = $x.Symbol
    Name = $x.Name
    "Composite Score" = $x.CompositeScore
    "Momentum Score" = $x.MomentumScore
    Buyability = $x.Buyability
    "Buyability Score" = $x.BuyabilityScore
    "Relative Volume Bonus" = $x.RelativeVolumeBonus
    Price = [math]::Round($x.Price, 2)
    SMA200 = [math]::Round($x.SMA200, 2)
    "Price / 52W" = [math]::Round($x.Price52, 2)
    "Price vs 20MA %" = [math]::Round($x.Dist20, 2)
    "Perf 6M %" = [math]::Round($x.Perf6, 2)
    "Perf 3M %" = [math]::Round($x.Perf3, 2)
    "Price vs SMA50 %" = [math]::Round($x.Dist50, 2)
    "Price vs SMA200 %" = [math]::Round($x.Dist200, 2)
    "SMA200 Status" = $x.Sma200Status
    "Rel Vol" = [math]::Round($x.RelVol, 2)
  }
}

$top30 = @($full | Select-Object -First 30)

$fullCsv = Join-Path $dateOut "APL_Momentum_Score_Full_Ranking_$ScanDate.csv"
$topTxt = Join-Path $dateOut "APL_Quant_Top_30_$ScanDate.txt"
$topMd = Join-Path $dateOut "APL_Quant_Top_30_$ScanDate.md"
$cumTxt = Join-Path $dateOut "APL_Momentum_Leaders_Watchlist_$ScanDate.txt"
$removedBelowSma200Txt = Join-Path $dateOut "removed-below-sma200-$ScanDate.txt"
$retainedMissingSma200Txt = Join-Path $dateOut "retained-missing-sma200-$ScanDate.txt"
$overviewMd = Join-Path $dateOut "APL_Momentum_Leaders_Overview_$ScanDate.md"
$metaJson = Join-Path $dateOut "APL_Momentum_Leaders_Meta_$ScanDate.json"
$sourceCopy = Join-Path $dateOut "APL_Momentum_Leaders_Source_$ScanDate.csv"

$full | Export-Csv -Path $fullCsv -NoTypeInformation -Encoding UTF8
Copy-Item -LiteralPath $InputCsv -Destination $sourceCopy
($top30.Symbol -join ",") | Set-Content -Path $topTxt -Encoding UTF8

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# APL Momentum Leaders Top 30 | $ScanDate")
$md.Add("")
$md.Add("| Rank | Symbol | Name | Composite Score | Momentum Score | Buyability | Relative Volume Bonus | Price / 52W | Perf 6M % | Perf 3M % | Rel Vol |")
$md.Add("|---:|---|---|---:|---:|---|---:|---:|---:|---:|---:|")
foreach ($r in $top30) {
  $name = ([string]$r.Name).Replace("|", "/")
  $md.Add("| $($r.Rank) | $($r.Symbol) | $name | $($r.'Composite Score') | $($r.'Momentum Score') | $($r.Buyability) | $($r.'Relative Volume Bonus') | $($r.'Price / 52W') | $($r.'Perf 6M %') | $($r.'Perf 3M %') | $($r.'Rel Vol') |")
}
$md | Set-Content -Path $topMd -Encoding UTF8

$watchlistSymbols = @(
  $scored |
    Where-Object { -not $_.BelowSma200 } |
    Sort-Object @{Expression="CompositeScore";Descending=$true}, @{Expression="MomentumScore";Descending=$true}, @{Expression="RelVol";Descending=$true}, @{Expression="Symbol";Ascending=$true} |
    Select-Object -ExpandProperty Symbol
)
($watchlistSymbols -join ",") | Set-Content -Path $cumTxt -Encoding UTF8

$removedBelowSma200 = @($scored | Where-Object { $_.Sma200Status -eq "Below SMA200" } | Sort-Object Symbol)
$retainedMissingSma200 = @($scored | Where-Object { $_.Sma200Status -eq "Missing SMA200" } | Sort-Object Symbol)
$sma200RemovedCount = $removedBelowSma200.Count
$sma200MissingCount = $retainedMissingSma200.Count
$finalWatchlistCount = $watchlistSymbols.Count

$removedBelowSma200Lines = @("Symbol,Name,Price,SMA200,Price vs SMA200 %,SMA200 Status") + @(
  $removedBelowSma200 |
    ForEach-Object { "$($_.Symbol),$($_.Name),$($_.Price),$($_.SMA200),$([math]::Round($_.Dist200, 2)),$($_.Sma200Status)" }
)
$removedBelowSma200Lines | Set-Content -Path $removedBelowSma200Txt -Encoding UTF8
if (-not (Test-Path -LiteralPath $removedBelowSma200Txt)) { New-Item -ItemType File -Path $removedBelowSma200Txt | Out-Null }

$retainedMissingSma200Lines = @("Symbol,Name,Price,SMA200 Status") + @(
  $retainedMissingSma200 |
    ForEach-Object { "$($_.Symbol),$($_.Name),$($_.Price),$($_.Sma200Status)" }
)
$retainedMissingSma200Lines | Set-Content -Path $retainedMissingSma200Txt -Encoding UTF8
if (-not (Test-Path -LiteralPath $retainedMissingSma200Txt)) { New-Item -ItemType File -Path $retainedMissingSma200Txt | Out-Null }

$lockCount = @($top30 | Where-Object { $_.'Buyability Score' -ge 8 }).Count
$avgMomentum = [math]::Round(($top30 | Measure-Object -Property "Momentum Score" -Average).Average, 2)
$avgBuy = [math]::Round(($top30 | Measure-Object -Property "Buyability Score" -Average).Average, 2)

$overview = @(
  "# APL Momentum Leaders Overview | $ScanDate",
  "",
  "- Universe: $($rows.Count)",
  "- Qualified Stocks: $($qualified.Count)",
  "- Momentum Leaders: $($top30.Count)",
  "- Leader Lock: $lockCount",
  "- Average Momentum Score: $avgMomentum",
  "- Average Buyability Score: $avgBuy",
  "- Removed Below SMA200 Count: $sma200RemovedCount",
  "- Retained Missing SMA200 Count: $sma200MissingCount",
  "- Final Watchlist Count: $finalWatchlistCount",
  "",
  "APL Composite Score = Momentum Score + Buyability Score + min(Relative Volume Bonus, Buyability Score)."
)
$overview | Set-Content -Path $overviewMd -Encoding UTF8

$meta = [ordered]@{
  scanDate = $ScanDate
  weekLabel = $WeekLabel
  universe = $rows.Count
  qualified = $qualified.Count
  leaders = $top30.Count
  leaderLock = $lockCount
  averageMomentum = $avgMomentum
  averageBuyability = $avgBuy
  removedBelowSma200Count = $sma200RemovedCount
  retainedMissingSma200Count = $sma200MissingCount
  finalWatchlistCount = $finalWatchlistCount
  source = "APL Momentum Database"
  fullRankingCsv = $fullCsv
  top30Txt = $topTxt
}
$meta | ConvertTo-Json -Depth 4 | Set-Content -Path $metaJson -Encoding UTF8

if (-not $SkipRootCopies -and -not $isStandaloneTriggerB) {
  foreach ($file in @($fullCsv, $topTxt, $topMd, $cumTxt, $removedBelowSma200Txt, $retainedMissingSma200Txt, $overviewMd, $metaJson)) {
    Copy-Item -LiteralPath $file -Destination (Join-Path $outputsRoot (Split-Path $file -Leaf))
  }
}

Write-Host "Processed $ScanDate"
Write-Host "Universe: $($rows.Count)"
Write-Host "Qualified: $($qualified.Count)"
Write-Host "Top 30: $($top30.Count)"
Write-Host "Leader Lock: $lockCount"
Write-Host "Removed Below SMA200: $sma200RemovedCount"
Write-Host "Retained Missing SMA200: $sma200MissingCount"
Write-Host "Final Watchlist Count: $finalWatchlistCount"
Write-Host "Top symbols: $((($top30 | Select-Object -ExpandProperty Symbol) -join ','))"
} finally {
  Exit-AplNamedMutex $mutex
}
