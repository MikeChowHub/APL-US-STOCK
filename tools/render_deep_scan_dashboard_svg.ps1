param(
  [string]$InputPath = '',
  [string]$Root = '',
  [string]$RankingCsv = '',
  [string]$ScanDate = '',
  [string]$OutputPath = '',
  [string]$OutputDir = '',
  [string]$LogoPath = '',
  [string]$SectorMapPath = '',
  [string]$WeekLabel = '',
  [int]$ScanUniverseCount = 0,
  [int]$ScanQualifiedCount = 0,
  [int]$LeaderCapacity = 30,
  [switch]$RegressionTest
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')
$resolved = Resolve-AplRendererInput -ExpectedRendererType Dashboard -BoundParameters $PSBoundParameters -InputPath $InputPath -RankingCsv $RankingCsv -ScanDate $ScanDate -SectorMapPath $SectorMapPath -OutputPath $OutputPath -OutputDir $OutputDir -Root $Root -LogoPath $LogoPath -WeekLabel $WeekLabel -ScanUniverseCount $ScanUniverseCount -ScanQualifiedCount $ScanQualifiedCount -LeaderCapacity $LeaderCapacity -RegressionTest:$RegressionTest
$Root=$resolved.ProjectRoot; $RankingCsv=$resolved.RankingCsv; $ScanDate=$resolved.ScanDate; $SectorMapPath=$resolved.SectorMapPath; $OutputDir=$resolved.OutputPath; $LogoPath=$resolved.LogoPath; $WeekLabel=$resolved.WeekLabel; $ScanUniverseCount=$resolved.ScanUniverseCount; $ScanQualifiedCount=$resolved.ScanQualifiedCount; $LeaderCapacity=$resolved.LeaderCapacity
$raw = Import-AplRankingCsv $RankingCsv
$sectorPresentation = Import-AplSectorPresentation $SectorMapPath
if ([string]::IsNullOrWhiteSpace($WeekLabel)) {
  $calendar = [System.Globalization.CultureInfo]::InvariantCulture.Calendar
  $dateValue = [datetime]::ParseExact($ScanDate, 'yyyy-MM-dd', $null)
  $weekNumber = $calendar.GetWeekOfYear($dateValue, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
  $WeekLabel = "Week $weekNumber"
}
if (!(Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
$outSvg = Join-Path $OutputDir "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_1920x1080.svg"
$logPath = Join-Path $OutputDir "APL_DeepScan_Radar_Dashboard_Top30_${ScanDate}_Render_Log.txt"

function U([int[]]$codes) {
  $s = ''
  foreach ($c in $codes) { $s += [char]$c }
  return $s
}
function X([string]$s) { return [System.Security.SecurityElement]::Escape($s) }
function Add([string]$s) { $script:svg.Add($s) }
function LogoData($path) {
  if (!(Test-Path -LiteralPath $path)) { return '' }
  return 'data:image/png;base64,' + [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($path))
}
$T_TITLE = U @(0x8CC7,0x91D1,0x6D41,0x5411,0x96F7,0x9054,0x5716)
$T_LEADER = U @(0x9818,0x5C0E,0x80A1)
$T_BUY_DIST = U @(0x8CB7,0x5165,0x8A55,0x7D1A,0x5206,0x4F48)
$T_SECTOR_DIST = U @(0x7522,0x696D,0x5206,0x4F48)
$T_SUMMARY = U @(0x5E02,0x5834,0x6383,0x63CF,0x7E3D,0x7D50)
$T_LEGEND = U @(0x96F7,0x9054,0x5716,0x4F8B)
$T_INSIGHT = U @(0x6DF1,0x6D77,0x96F7,0x9054,0x89C0,0x9EDE)
$T_WATCH = U @(0x89C0,0x5BDF,0x5340)
$T_OBS = U @(0x6F5B,0x529B,0x8FFD,0x8E64,0x5340)
$T_MISSION = 'DEEP-SCAN ' + (U @(0x4EFB,0x52D9))
$T_AVG_MOM = U @(0x5E73,0x5747,0x52D5,0x80FD,0x5206,0x6578)
$T_AVG_BUY = U @(0x5E73,0x5747,0x8CB7,0x5165,0x8A55,0x7D1A)
$T_AVG_VOL = U @(0x5E73,0x5747,0x76F8,0x5C0D,0x6210,0x4EA4,0x91CF)
$T_TOP5 = 'Top 5 ' + (U @(0x6838,0x5FC3,0x9396,0x5B9A))
$T_LOCK = U @(0x6838,0x5FC3,0x9396,0x5B9A,0x5340)
$T_TODAY_LOGIC = "TODAY'S SCAN LOGIC"
$T_TODAY_SCAN = "SCAN SUMMARY"
$T_WEEKLY_SCAN_RESULT = U @(0x6383,0x63CF,0x6458,0x8981)
$T_STOCK_UNIVERSE = U @(0x80A1,0x7968,0x6C60)
$T_QUALIFIED = U @(0x7B26,0x5408,0x689D,0x4EF6)
$T_LEADERS_ZH = U @(0x9818,0x5C0E,0x80A1)
$T_LEADER_LOCK_ZH = U @(0x6838,0x5FC3,0x9396,0x5B9A)
$T_SOURCE = 'Source'
$T_MARKET_THEME = 'Market Theme'

$sectorMapInput = $sectorPresentation
$sectorMap = $sectorPresentation.Symbols
$defaultSector = $sectorPresentation.DefaultSector
$sectorColors = @{}; foreach ($key in $sectorPresentation.Entries.Keys) { $sectorColors[$key] = [string]$sectorPresentation.Entries[$key].Color }
function NormalizeSector([string]$sector) {
  return Get-AplNormalizedSector $sectorPresentation $sector
}
function SectorChinese([string]$sector) {
  return [string](Get-AplSectorVisual $sectorPresentation $sector).ChineseLabel
}
function BuyColor([int]$b) {
  if ($b -ge 8) { return '#00D8FF' }
  if ($b -ge 6) { return '#00D97B' }
  if ($b -ge 4) { return '#008BFF' }
  if ($b -ge 2) { return '#FF9D00' }
  return '#FF4E5E'
}
function BuyGlow([int]$b) {
  if ($b -ge 8) { return 18 }
  if ($b -ge 6) { return 13 }
  if ($b -ge 4) { return 7 }
  if ($b -ge 2) { return 4 }
  return 0
}
function BuyGlowOpacity([int]$b) {
  if ($b -ge 8) { return '0.20' }
  if ($b -ge 6) { return '0.14' }
  if ($b -ge 4) { return '0.07' }
  if ($b -ge 2) { return '0.04' }
  return '0'
}
function BuyGlowFilter([int]$b) {
  if ($b -ge 8) { return 'url(#glowStrong)' }
  if ($b -ge 6) { return 'url(#glowMedium)' }
  if ($b -ge 4) { return 'url(#glowSoft)' }
  if ($b -ge 2) { return 'url(#glowSoft)' }
  return ''
}
function BuyStars([int]$b) {
  if ($b -ge 8) { return '5-star' }
  if ($b -ge 6) { return '4-star' }
  if ($b -ge 4) { return '3-star' }
  if ($b -ge 2) { return '2-star' }
  return '1-star'
}
function BaseSize([int]$rank) {
  if ($rank -le 5) { return 78 }
  if ($rank -le 15) { return 62 }
  return 48
}
function MaxSize([int]$rank) {
  if ($rank -le 5) { return 92 }
  if ($rank -le 15) { return 78 }
  return 60
}
function Diameter([int]$rank, [double]$mom) {
  $base = BaseSize $rank
  $max = MaxSize $rank
  $d = $base + (($mom - 56) / 34) * ($max - $base)
  if ($d -lt $base) { $d = $base }
  if ($d -gt $max) { $d = $max }
  return [math]::Round($d, 1)
}
$rankMap = @{
  1=@(0,155); 2=@(205,172); 3=@(155,172); 4=@(270,190); 5=@(90,190);
  6=@(15,300); 7=@(50,285); 8=@(90,315); 9=@(130,285); 10=@(168,292);
  11=@(205,285); 12=@(240,305); 13=@(275,310); 14=@(315,292); 15=@(345,300);
  16=@(10,420); 17=@(35,430); 18=@(60,405); 19=@(85,428); 20=@(112,410);
  21=@(138,430); 22=@(162,402); 23=@(184,392); 24=@(212,410); 25=@(238,430);
  26=@(262,410); 27=@(288,430); 28=@(312,405); 29=@(336,430); 30=@(358,415)
}
function Pos([int]$rank) {
  $cx = 920; $cy = 540
  $p = $rankMap[$rank]
  $rad = ([double]$p[0] - 90) * [math]::PI / 180
  $r = [double]$p[1]
  return @([math]::Round($cx + [math]::Cos($rad) * $r, 2), [math]::Round($cy + [math]::Sin($rad) * $r, 2))
}

$leaderCapacity = [math]::Min($LeaderCapacity, 30)
$rankedRaw = @(
  $raw |
    Where-Object { $_.Rank -match '^\d+$' -and [int]$_.Rank -ge 1 -and [int]$_.Rank -le $leaderCapacity } |
    Sort-Object @{Expression={ [int]$_.Rank }; Ascending=$true}, @{Expression='Symbol'; Ascending=$true} |
    Select-Object -First $leaderCapacity
)

$rows = @()
foreach ($r in $rankedRaw) {
  $rank = [int]$r.Rank
  $sym = [string]$r.Symbol
  $mom = [double]$r.'Momentum Score'
  $buy = [int]$r.'Buyability Score'
  $relVol = [double]$r.'Rel Vol'
  $composite = if ($r.PSObject.Properties.Name -contains 'Composite Score' -and [string]$r.'Composite Score' -ne '') {
    [double]$r.'Composite Score'
  } else {
    0
  }
  $sector = if ($sectorMap.ContainsKey($sym)) { $sectorMap[$sym] } else { $defaultSector }
  $p = Pos $rank
  $rows += [pscustomobject]@{
    Rank=$rank; OriginalRank=$rank; Symbol=$sym; Momentum=$mom; Buy=$buy; Composite=[math]::Round($composite, 2); Sector=$sector;
    RelVol=$relVol; Perf6=[double]$r.'Perf 6M %'; Perf3=[double]$r.'Perf 3M %';
    X=$p[0]; Y=$p[1]; D=(Diameter $rank $mom)
  }
}
$leaderCount = @($rows).Count
if ($leaderCount -eq 0) {
  throw "No Momentum Leaders found in prepared ranking CSV. Renderer expects Rank 1-$leaderCapacity rows."
}

$avgMomentum = [math]::Round((($rows | Measure-Object Momentum -Average).Average), 2)
$avgBuy = [math]::Round((($rows | Measure-Object Buy -Average).Average), 2)
$avg6M = [math]::Round((($rows | Measure-Object Perf6 -Average).Average), 2)
$avg3M = [math]::Round((($rows | Measure-Object Perf3 -Average).Average), 2)
$avgRel = [math]::Round((($rows | Measure-Object RelVol -Average).Average), 2)
$highBuy = @($rows | Where-Object { $_.Buy -ge 8 }).Count
$denseLeaderLock = $highBuy -gt 15
$highestRel = ($rows | Sort-Object RelVol -Descending | Select-Object -First 1).Symbol
$normalizedSectorRows = $rows | ForEach-Object { [pscustomobject]@{ Sector=(NormalizeSector $_.Sector) } }
$allSectorCounts = $normalizedSectorRows | Group-Object Sector | Sort-Object @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false}
$topFiveRaw = @($allSectorCounts | Select-Object -First 5)
$sectorCounts = @($topFiveRaw)
$topSectorNames = @($sectorCounts | ForEach-Object { $_.Name })
$topSector = $sectorCounts[0].Name
$topSectorVisual = Get-AplSectorVisual $sectorPresentation $topSector
$marketTheme = [string]$topSectorVisual.MarketTheme
$insightTheme = [string]$topSectorVisual.InsightTheme
$buyBuckets = [ordered]@{
  '8-10' = @($rows | Where-Object { $_.Buy -ge 8 }).Count
  '6-7' = @($rows | Where-Object { $_.Buy -ge 6 -and $_.Buy -le 7 }).Count
  '4-5' = @($rows | Where-Object { $_.Buy -ge 4 -and $_.Buy -le 5 }).Count
  '2-3' = @($rows | Where-Object { $_.Buy -ge 2 -and $_.Buy -le 3 }).Count
  '0-1' = @($rows | Where-Object { $_.Buy -le 1 }).Count
}

$svg = New-Object System.Collections.Generic.List[string]
$logoData = LogoData $logoPath

Add '<?xml version="1.0" encoding="UTF-8"?>'
Add '<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">'
Add '<defs>'
Add '<style><![CDATA['
Add '.font-cn{font-family:"Noto Sans TC","Microsoft JhengHei UI","Microsoft JhengHei",sans-serif}.font-en{font-family:"Montserrat","Segoe UI",sans-serif}.mono{font-family:"JetBrains Mono","Consolas",monospace}.white{fill:#fff}.cyan{fill:#00D8FF}.gray{fill:#8B93A6}.ticker{fill:#fff;font-weight:800;text-anchor:middle}.score{fill:#fff;text-anchor:middle;opacity:.86}.rank{fill:#00D8FF;text-anchor:middle;font-weight:800}.panel-title{fill:#00D8FF;font-weight:800}'
Add ']]></style>'
Add '<filter id="glow"><feGaussianBlur stdDeviation="8" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
Add '<filter id="glowStrong" x="-120%" y="-120%" width="340%" height="340%"><feGaussianBlur stdDeviation="16" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
Add '<filter id="glowMedium" x="-90%" y="-90%" width="280%" height="280%"><feGaussianBlur stdDeviation="11" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
Add '<filter id="glowSoft" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="6" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
Add '<filter id="deepNoise" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.82" numOctaves="2" seed="28" result="noise"/><feColorMatrix in="noise" type="matrix" values="0 0 0 0 0  0 0 0 0 0.82  0 0 0 0 1  0 0 0 .18 0"/></filter>'
Add '<filter id="fogBlur" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="78"/></filter>'
Add '<radialGradient id="deepLighting" cx="48%" cy="46%" r="78%"><stop offset="0%" stop-color="#123B55"/><stop offset="34%" stop-color="#0A2233"/><stop offset="68%" stop-color="#06131D"/><stop offset="100%" stop-color="#03080D"/></radialGradient>'
Add '<radialGradient id="cinematicVignette" cx="50%" cy="47%" r="74%"><stop offset="0%" stop-color="#000000" stop-opacity="0"/><stop offset="58%" stop-color="#000000" stop-opacity=".10"/><stop offset="82%" stop-color="#000000" stop-opacity=".38"/><stop offset="100%" stop-color="#000000" stop-opacity=".72"/></radialGradient>'
Add '<linearGradient id="aplGlass" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#A8B3C2"/><stop offset="18%" stop-color="#FFFFFF"/><stop offset="48%" stop-color="#DDE7F2"/><stop offset="72%" stop-color="#FFFFFF"/><stop offset="100%" stop-color="#8EEBFF"/></linearGradient>'
Add '<linearGradient id="aplGlassReflection" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="45%" stop-color="#FFFFFF" stop-opacity=".32"/><stop offset="62%" stop-color="#00D8FF" stop-opacity=".26"/><stop offset="100%" stop-color="#FFFFFF" stop-opacity="0"/></linearGradient>'
Add '</defs>'
Add '<rect width="1920" height="1080" fill="url(#deepLighting)"/>'
Add '<g id="blue-fog-layer" filter="url(#fogBlur)">'
Add '<ellipse cx="920" cy="540" rx="520" ry="320" fill="#00D8FF" opacity=".045"/>'
Add '<ellipse cx="905" cy="540" rx="760" ry="460" fill="#008BFF" opacity=".026"/>'
Add '<ellipse cx="1145" cy="355" rx="280" ry="190" fill="#8EEBFF" opacity=".022"/>'
Add '<ellipse cx="650" cy="770" rx="330" ry="210" fill="#00D8FF" opacity=".018"/>'
Add '</g>'
Add '<rect width="1920" height="1080" fill="#00D8FF" filter="url(#deepNoise)" opacity=".018"/>'
for ($x=0; $x -le 1920; $x += 48) { Add "<line x1='$x' y1='0' x2='$x' y2='1080' stroke='#0E3146' stroke-opacity='.16'/>" }
for ($y=0; $y -le 1080; $y += 48) { Add "<line x1='0' y1='$y' x2='1920' y2='$y' stroke='#0E3146' stroke-opacity='.16'/>" }
Add '<g id="depth-radar-geometry" fill="none" stroke="#00D8FF" stroke-linecap="round">'
Add '<circle cx="920" cy="540" r="520" stroke-opacity=".035" stroke-width="1"/>'
Add '<circle cx="920" cy="540" r="650" stroke-opacity=".026" stroke-width="1"/>'
Add '<circle cx="920" cy="540" r="810" stroke-opacity=".018" stroke-width="1"/>'
Add '<ellipse cx="920" cy="540" rx="1040" ry="520" stroke-opacity=".018" stroke-width="1"/>'
Add '<ellipse cx="920" cy="540" rx="1280" ry="690" stroke-opacity=".014" stroke-width="1"/>'
Add '<path d="M230 166 A900 900 0 0 1 1610 162" stroke-opacity=".028" stroke-width="1.2"/>'
Add '<path d="M160 912 A980 980 0 0 0 1680 910" stroke-opacity=".024" stroke-width="1.2"/>'
Add '</g>'
Add '<g id="sonar-echo-rings" fill="none" stroke="#8EEBFF" stroke-linecap="round">'
Add '<circle cx="920" cy="540" r="575" stroke-opacity=".035" stroke-width="1.2" stroke-dasharray="70 46 16 64"/>'
Add '<circle cx="920" cy="540" r="705" stroke-opacity=".026" stroke-width="1" stroke-dasharray="90 70 22 92"/>'
Add '<circle cx="920" cy="540" r="875" stroke-opacity=".018" stroke-width="1" stroke-dasharray="110 96 26 120"/>'
Add '</g>'
Add '<g id="ocean-current-layer" fill="none" stroke="#8EEBFF" stroke-width="1" stroke-linecap="round">'
Add '<path d="M370 188 C530 150 700 196 860 158 S1160 130 1320 168" stroke-opacity=".028"/>'
Add '<path d="M420 302 C590 270 755 318 930 286 S1190 248 1380 292" stroke-opacity=".024"/>'
Add '<path d="M350 816 C535 780 705 828 895 790 S1190 746 1385 798" stroke-opacity=".026"/>'
Add '<path d="M470 930 C650 895 820 940 1015 904 S1260 872 1390 910" stroke-opacity=".02"/>'
Add '</g>'
for ($i=0; $i -lt 150; $i++) {
  $px = 24 + (($i * 137) % 1870)
  $py = 34 + (($i * 89) % 1010)
  $dx = [math]::Abs($px - 920)
  $dy = [math]::Abs($py - 540)
  $dist = [math]::Sqrt(($dx*$dx)+($dy*$dy))
  if ($dist -lt 250) { continue }
  $r = 0.45 + (($i % 3) * 0.28)
  $op = 0.018 + ([math]::Min($dist,900) / 900 * 0.026)
  Add "<circle cx='$px' cy='$py' r='$r' fill='#8EEBFF' opacity='$('{0:0.000}' -f $op)'/>"
}
Add '<path d="M 920 540 L 1195 205 L 1265 255 L 960 575 Z" fill="#00D8FF" opacity=".028" filter="url(#fogBlur)"/>'
Add '<rect x="1440" y="0" width="480" height="1080" fill="#08131F" opacity=".82"/>'
Add '<rect width="1920" height="1080" fill="url(#cinematicVignette)"/>'
if ($logoData) { Add "<image href='$logoData' x='24' y='22' width='500' height='190' preserveAspectRatio='xMinYMin meet'/>" }

function Panel([int]$x,[int]$y,[int]$w,[int]$h,[string]$title) {
  Add "<rect x='$x' y='$y' width='$w' height='$h' rx='8' fill='#08131F' fill-opacity='.78' stroke='#00D8FF' stroke-opacity='.55'/>"
  Add "<text x='$($x+18)' y='$($y+34)' class='font-cn panel-title' font-size='18'>$(X $title)</text>"
}
function SectorIcon([string]$sector, [int]$x, [int]$y, [string]$color) {
  $c = $color
  if ($sector -eq 'Semiconductor') {
    Add "<g transform='translate($x $y)' stroke='$c' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='5' y='5' width='12' height='12' rx='2'/><path d='M8 2v3M14 2v3M8 17v3M14 17v3M2 8h3M2 14h3M17 8h3M17 14h3'/></g>"
  } elseif ($sector -eq 'AI' -or $sector -eq 'Software' -or $sector -eq 'AI / Software') {
    Add "<g transform='translate($x $y)' stroke='$c' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M8 5a4 4 0 0 0-4 4c0 2 1.5 3.2 3 4.2V18'/><path d='M14 5a4 4 0 0 1 4 4c0 2-1.5 3.2-3 4.2V18'/><path d='M8 9h6M8 13h6M11 3v17'/></g>"
  } elseif ($sector -eq 'Healthcare' -or $sector -eq 'Bio' -or $sector -eq 'Healthcare / Bio') {
    Add "<g transform='translate($x $y)' stroke='$c' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M11 19s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 18 9c0 5.5-7 10-7 10z'/><path d='M11 8v6M8 11h6'/></g>"
  } elseif ($sector -eq 'Networking' -or $sector -eq 'Networking / Infrastructure') {
    Add "<g transform='translate($x $y)' stroke='$c' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M4 10a10 10 0 0 1 14 0'/><path d='M7 13a6 6 0 0 1 8 0'/><path d='M10 16a2 2 0 0 1 2 0'/><circle cx='11' cy='18' r='1'/></g>"
  } elseif ($sector -eq 'Industrial') {
    Add "<g transform='translate($x $y)' stroke='$c' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M3 18h16'/><path d='M4 18V9l5 3V9l5 3V6h4v12'/><path d='M7 15h2M12 15h2'/></g>"
  } elseif ($sector -eq 'Consumer') {
    Add "<g transform='translate($x $y)' stroke='$c' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M6 8h10l1 11H5L6 8z'/><path d='M8 8a3 3 0 0 1 6 0'/></g>"
  } else {
    Add "<g transform='translate($x $y)' fill='$c'><circle cx='6' cy='6' r='2.5'/><circle cx='15' cy='6' r='2.5'/><circle cx='6' cy='15' r='2.5'/><circle cx='15' cy='15' r='2.5'/></g>"
  }
}

Panel 24 232 312 200 $T_TODAY_SCAN
Add "<text x='42' y='284' class='font-cn white' font-size='15' opacity='.88'>$(X $T_WEEKLY_SCAN_RESULT)</text>"
$scanRows = @(
  @('Universe', $T_STOCK_UNIVERSE, ('{0:N0}' -f $scanUniverseCount)),
  @('Qualified Stocks', $T_QUALIFIED, ('{0:N0}' -f $scanQualifiedCount)),
  @('Momentum Leaders', $T_LEADERS_ZH, ('{0:N0}' -f $leaderCount)),
  @('Leader Lock', $T_LEADER_LOCK_ZH, ('{0:N0}' -f $highBuy))
)
$scanY = 306
foreach ($sr in $scanRows) {
  Add "<text x='42' y='$scanY' class='font-en gray' font-size='13' font-weight='700'>$(X $sr[0])</text>"
  Add "<text x='42' y='$($scanY+14)' class='font-cn gray' font-size='12' font-weight='600' opacity='.82'>$(X $sr[1])</text>"
  Add "<text x='312' y='$($scanY+8)' class='mono white' font-size='18' text-anchor='end' font-weight='900'>$(X $sr[2])</text>"
  Add "<line x1='42' y1='$($scanY+21)' x2='312' y2='$($scanY+21)' stroke='#8B93A6' stroke-opacity='.10'/>"
  $scanY += 31
}
Panel 24 444 312 340 'RADAR LEGEND'
Add "<g transform='translate(34 496)' fill='none' stroke-linecap='round' stroke-linejoin='round'>"
Add "<circle cx='66' cy='66' r='24' stroke='#00D8FF' stroke-width='4' filter='url(#glowStrong)'/>"
Add "<circle cx='66' cy='66' r='44' stroke='#008BFF' stroke-opacity='.9' stroke-width='2.5'/>"
Add "<circle cx='66' cy='66' r='64' stroke='#8B93A6' stroke-opacity='.78' stroke-width='2'/>"
Add "<line x1='66' y1='2' x2='66' y2='130' stroke='#00D8FF' stroke-opacity='.22'/>"
Add "<line x1='2' y1='66' x2='130' y2='66' stroke='#00D8FF' stroke-opacity='.22'/>"
Add "<circle cx='66' cy='66' r='6' fill='#00D8FF' stroke='none' filter='url(#glow)'/>"
Add "</g>"
Add "<text x='180' y='513' class='font-en cyan' font-size='15' font-weight='900'>◎ Core Zone</text>"
Add "<text x='180' y='535' class='font-cn cyan' font-size='13' opacity='.88'>核心區</text>"
Add "<text x='180' y='557' class='mono gray' font-size='12'>Rank 1-5</text>"
Add "<text x='180' y='600' fill='#008BFF' class='font-en' font-size='15' font-weight='900'>◉ Watch Zone</text>"
Add "<text x='180' y='622' fill='#008BFF' class='font-cn' font-size='13' opacity='.88'>觀察區</text>"
Add "<text x='180' y='644' class='mono gray' font-size='12'>Rank 6-15</text>"
Add "<text x='180' y='687' fill='#8B93A6' class='font-en' font-size='15' font-weight='900'>○ Observation</text>"
Add "<text x='180' y='709' fill='#8B93A6' class='font-cn' font-size='13' opacity='.88'>追蹤區</text>"
Add "<text x='180' y='731' class='mono gray' font-size='12'>Rank 16-30</text>"
Add "<line x1='42' y1='748' x2='300' y2='748' stroke='#00D8FF' stroke-opacity='.18'/>"
Add "<text x='42' y='766' class='mono cyan' font-size='10' font-weight='800'>Size→Momentum</text>"
Add "<text x='176' y='766' class='mono cyan' font-size='10' font-weight='800'>Glow→Buyability</text>"
Add "<text x='42' y='776' class='mono cyan' font-size='10' font-weight='800'>Border→Sector</text>"

Panel 24 796 312 210 'BUYABILITY SCORE'
$buyLegend = @(
  @('★★★★★','8-10','Strong Buy','#00D8FF','glowStrong'),
  @('★★★★☆','6-7','Good','#00D97B','glowMedium'),
  @('★★★☆☆','4-5','Neutral','#008BFF','glowSoft'),
  @('★★☆☆☆','2-3','Watch','#FF9D00','glowSoft'),
  @('★☆☆☆☆','0-1','Extended','#FF4E5E','')
)
$buyLegendY = 856
foreach ($bl in $buyLegend) {
  $filterAttr = if ($bl[4]) { " filter='url(#$($bl[4]))'" } else { '' }
  Add "<circle cx='46' cy='$($buyLegendY-5)' r='8' fill='$($bl[3])' opacity='.9'$filterAttr/>"
  Add "<circle cx='46' cy='$($buyLegendY-5)' r='12' fill='none' stroke='$($bl[3])' stroke-opacity='.36'/>"
  Add "<text x='64' y='$buyLegendY' fill='$($bl[3])' class='font-en' font-size='14' font-weight='900'>$($bl[0])</text>"
  Add "<text x='176' y='$buyLegendY' fill='$($bl[3])' class='mono' font-size='12' text-anchor='end' font-weight='800'>$($bl[1])</text>"
  Add "<text x='204' y='$buyLegendY' class='font-en gray' font-size='12'>$(X $bl[2])</text>"
  $buyLegendY += 29
}

Add "<rect x='24' y='1018' width='312' height='52' rx='7' fill='#08131F' fill-opacity='.78' stroke='#00D8FF' stroke-opacity='.55'/>"
Add "<g transform='translate(42 1030) scale(.85)' stroke='#00D8FF' fill='none' stroke-width='1.8' opacity='.65'><rect x='2' y='8' width='12' height='10' rx='2'/><path d='M5 8 V5 a3.5 3.5 0 0 1 7 0 v3'/></g>"
Add "<text x='72' y='1038' class='mono cyan' font-size='13' font-weight='900'>Leader Lock</text>"
Add "<text x='72' y='1056' class='mono gray' font-size='12'>Buyability ≥ 8</text>"

$cx=920; $cy=540
foreach ($r in @(90,120,220,320,380,430)) { Add "<circle cx='$cx' cy='$cy' r='$r' fill='none' stroke='#00D8FF' stroke-opacity='.15'/>" }
for ($deg=0; $deg -lt 360; $deg += 30) {
  $rad = ($deg - 90) * [math]::PI / 180
  $x2=[math]::Round($cx+[math]::Cos($rad)*430,2); $y2=[math]::Round($cy+[math]::Sin($rad)*430,2)
  Add "<line x1='$cx' y1='$cy' x2='$x2' y2='$y2' stroke='#00D8FF' stroke-opacity='.12'/>"
}
Add "<path d='M 920 540 L 1140 220 L 1295 315 Z' fill='#00D8FF' opacity='.035' filter='url(#glow)'/>"
Add "<path d='M 920 540 L 1165 215 L 1270 290 Z' fill='#00D8FF' opacity='.055' filter='url(#glowSoft)'/>"
Add "<path d='M 920 540 L 1192 205 L 1245 255 Z' fill='#00D8FF' opacity='.08'/>"
Add "<path d='M 920 540 L 1198 225 L 1225 252 Z' fill='#00D8FF' opacity='.11'/>"
Add "<line x1='920' y1='540' x2='1260' y2='220' stroke='#00D8FF' stroke-width='2.2' opacity='.38' filter='url(#glowSoft)'/>"

Add "<circle cx='920' cy='540' r='92' fill='#00D8FF' opacity='.065' filter='url(#glow)'/>"
Add "<circle cx='920' cy='540' r='68' fill='#00D8FF' opacity='.09'/>"
Add "<text x='920' y='478' class='mono cyan' font-size='16' text-anchor='middle' font-weight='800'>LEADER LOCK</text>"
Add "<text x='920' y='548' class='font-en' fill='url(#aplGlass)' font-size='60' text-anchor='middle' font-weight='900' stroke='#FFFFFF' stroke-opacity='.22' stroke-width='.7'>APL</text>"
Add "<text x='920' y='548' class='font-en' fill='url(#aplGlassReflection)' font-size='60' text-anchor='middle' font-weight='900' opacity='.55'>APL</text>"
Add "<path d='M865 526 C895 516 945 516 975 526' stroke='#00D8FF' stroke-opacity='.22' stroke-width='2' fill='none'/>"
Add "<text x='920' y='586' class='font-en cyan' font-size='26' text-anchor='middle' font-weight='800'>Deep-Scan</text>"
Add "<text x='920' y='612' class='mono cyan' font-size='12' text-anchor='middle' font-weight='800'>LIVE SCAN</text>"

foreach ($row in $rows) {
  $rank=[int]$row.Rank; $sym=X $row.Symbol; $buy=[int]$row.Buy; $d=[double]$row.D; $rr=$d/2; $x=[double]$row.X; $y=[double]$row.Y
  $normalizedNodeSector = NormalizeSector $row.Sector
  $sectorColor = if ($topSectorNames -contains $normalizedNodeSector) { $sectorColors[$normalizedNodeSector] } else { $sectorColors['Others'] }
  $bc=BuyColor $buy; $glow=BuyGlow $buy; $gOpacity=BuyGlowOpacity $buy; $gFilter=BuyGlowFilter $buy
  if ($denseLeaderLock -and $buy -ge 8) { $glow=12; $gOpacity='0.14' }
  $rankFs = if ($rank -le 5) { 18 } elseif ($rank -le 15) { 15 } else { 13 }
  $ts = if ($rank -le 5) { 26 } elseif ($rank -le 15) { 22 } else { 18 }
  $ss = if ($rank -le 5) { 16 } elseif ($rank -le 15) { 14 } else { 12 }
  $scoreDy = if ($rank -le 5) { 28 } elseif ($rank -le 15) { 26 } else { 23 }
  if ($glow -gt 0) {
    Add "<circle cx='$x' cy='$y' r='$($rr+$glow)' fill='$bc' opacity='$gOpacity' filter='$gFilter'/>"
    if ($buy -ge 8) {
      $outerRing = if ($rank -le 5) { 15 } elseif ($rank -le 15) { 10 } else { 7 }
      $pulseRing = if ($rank -le 5) { 24 } elseif ($rank -le 15) { 15 } else { 10 }
      $ringOpacity = if ($rank -le 5) { '.78' } elseif ($rank -le 15) { '.58' } else { '.42' }
      $pulseOpacity = if ($rank -le 5) { '.18' } elseif ($rank -le 15) { '.10' } else { '.06' }
      Add "<circle cx='$x' cy='$y' r='$($rr+4)' fill='none' stroke='$bc' stroke-opacity='$ringOpacity' stroke-width='2.4'/>"
      Add "<circle cx='$x' cy='$y' r='$($rr+$outerRing)' fill='none' stroke='$bc' stroke-opacity='.34' stroke-width='1.6' filter='url(#glowSoft)'/>"
      Add "<circle cx='$x' cy='$y' r='$($rr+$pulseRing)' fill='none' stroke='$bc' stroke-opacity='$pulseOpacity' stroke-width='1.2' stroke-dasharray='4 9'/>"
    } elseif ($buy -ge 6) {
      Add "<circle cx='$x' cy='$y' r='$($rr+8)' fill='none' stroke='$bc' stroke-opacity='.42' stroke-width='2' filter='url(#glowSoft)'/>"
      Add "<circle cx='$x' cy='$y' r='$($rr+3)' fill='none' stroke='$bc' stroke-opacity='.28' stroke-width='1.3'/>"
    } elseif ($buy -ge 4) {
      Add "<circle cx='$x' cy='$y' r='$($rr+5)' fill='none' stroke='$bc' stroke-opacity='.30' stroke-width='1.5' filter='url(#glowSoft)'/>"
    } else {
      Add "<circle cx='$x' cy='$y' r='$($rr+3)' fill='none' stroke='$bc' stroke-opacity='.18' stroke-width='1.5'/>"
    }
  }
  if ($rank -le 5) {
    Add "<circle cx='$x' cy='$y' r='$($rr+12)' fill='none' stroke='#FFFFFF' stroke-opacity='.16' stroke-width='1.2' stroke-dasharray='2 7'/>"
  }
  Add "<circle cx='$x' cy='$y' r='$rr' fill='#07121C' fill-opacity='.78' stroke='$sectorColor' stroke-width='2'/>"
  if ($rank -le 15) {
    Add "<text x='$x' y='$($y-$rr+$rankFs+1)' class='mono rank' font-size='$rankFs'>$rank</text>"
    Add "<text x='$x' y='$($y+6)' class='font-en ticker' font-size='$ts'>$sym</text>"
    Add "<text x='$x' y='$($y+$scoreDy)' class='mono score' font-size='$ss'>$('{0:0.00}' -f $row.Momentum)</text>"
  } else {
    Add "<text x='$x' y='$($y+6)' class='font-en ticker' font-size='$ts'>$sym</text>"
  }
  if ($buy -ge 8) {
    $lx=[math]::Round($x+$rr+4,2); $ly=[math]::Round($y+$rr-10,2)
    Add "<g transform='translate($lx $ly) scale(1.05)' stroke='#00D8FF' fill='none' stroke-width='1.8' opacity='.65'><rect x='2' y='6' width='10' height='8' rx='2'/><path d='M4 6 V4 a3 3 0 0 1 6 0 v2'/></g>"
  }
}

function SummaryIcon([string]$kind, [int]$x, [int]$y, [string]$color) {
  Add "<rect x='$x' y='$y' width='32' height='32' rx='6' fill='#07121C' fill-opacity='.92' stroke='$color' stroke-opacity='.62'/>"
  $tx = $x + 6
  $ty = $y + 6
  if ($kind -eq 'momentum') {
    Add "<g transform='translate($tx $ty)' stroke='$color' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M2 11h4l3-7 5 16 3-9h3'/></g>"
  } elseif ($kind -eq 'buy') {
    Add "<g transform='translate($tx $ty)' stroke='$color' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='10' cy='10' r='8'/><circle cx='10' cy='10' r='3'/><path d='M10 2v3M10 15v3M2 10h3M15 10h3'/></g>"
  } elseif ($kind -eq 'theme') {
    Add "<g transform='translate($tx $ty)' stroke='$color' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='10' width='3' height='7'/><rect x='9' y='6' width='3' height='11'/><rect x='15' y='2' width='3' height='15'/><path d='M2 18h18M4 8l5-4 4 3 5-6'/></g>"
  } elseif ($kind -eq 'perf') {
    Add "<g transform='translate($tx $ty)' stroke='$color' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M3 15l5-5 4 3 6-8'/><path d='M14 5h4v4'/></g>"
  } elseif ($kind -eq 'relvol') {
    Add "<g transform='translate($tx $ty)' stroke='$color' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='11' width='3' height='7'/><rect x='8' y='7' width='3' height='11'/><rect x='13' y='3' width='3' height='15'/><rect x='18' y='9' width='3' height='9'/></g>"
  } else {
    Add "<g transform='translate($tx $ty)' stroke='$color' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='10' cy='10' r='7'/><path d='M10 3v14M3 10h14'/></g>"
  }
}

Panel 1450 30 415 1010 'DEEP-SCAN DASHBOARD'
Add "<text x='1484' y='110' class='font-cn cyan' font-size='23' font-weight='800'>Momentum Leaders $(X $T_LEADER)</text>"
Add "<text x='1484' y='145' class='font-en gray' font-size='20' font-weight='800'>Dynamic Leaders Overview</text>"
Add "<line x1='1484' y1='172' x2='1848' y2='172' stroke='#00D8FF' stroke-opacity='.18'/>"
Add "<text x='1484' y='205' class='font-cn panel-title' font-size='19'>$(X $T_BUY_DIST) %</text>"
Add "<circle cx='1556' cy='310' r='82' fill='#07121C' stroke='#00D8FF' stroke-opacity='.25'/>"
$donutCircumference = 515.22
$donutOffset = 0.0
$buyRows=@(@('強烈買入','8-10',$buyBuckets['8-10'],'#00D8FF'),@('良好機會','6-7',$buyBuckets['6-7'],'#00D97B'),@('機會觀察','4-5',$buyBuckets['4-5'],'#008BFF'),@('等待觀察','2-3',$buyBuckets['2-3'],'#FF9D00'),@('過度延伸','0-1',$buyBuckets['0-1'],'#FF4E5E'))
foreach ($b in $buyRows) {
  $count = [int]$b[2]
  if ($count -gt 0) {
    $dash = [math]::Round($donutCircumference * ([double]$count / $leaderCount), 2)
    $gap = [math]::Round($donutCircumference - $dash, 2)
    $offset = [math]::Round($donutOffset, 2)
    Add "<circle cx='1556' cy='310' r='82' fill='none' stroke='$($b[3])' stroke-width='28' stroke-dasharray='$dash $gap' stroke-dashoffset='-$offset' transform='rotate(-90 1556 310)'/>"
    $donutOffset += $dash
  }
}
Add "<circle cx='1556' cy='310' r='52' fill='#06131D'/>"
Add "<text x='1556' y='311' class='mono white' font-size='38' text-anchor='middle' font-weight='800'>$leaderCount</text>"
Add "<text x='1556' y='338' class='mono gray' font-size='12' text-anchor='middle'>TOTAL</text>"
$scoreY=242
foreach ($b in $buyRows) {
  $count = [int]$b[2]
  $pct = [math]::Round(([double]$count / $leaderCount) * 100, 0)
  $barW = [math]::Round(186 * $pct / 100, 0)
  Add "<text x='1662' y='$($scoreY+10)' fill='$($b[3])' class='font-cn' font-size='13' font-weight='800'>$(X $b[0]) <tspan class='mono'>($($b[1]))</tspan></text>"
  Add "<text x='1848' y='$($scoreY+10)' class='mono white' font-size='14' text-anchor='end' font-weight='900'>$count 個  $pct%</text>"
  Add "<rect x='1662' y='$($scoreY+20)' width='186' height='8' rx='2' fill='#132637'/>"
  Add "<rect x='1662' y='$($scoreY+20)' width='$barW' height='8' rx='2' fill='$($b[3])'/>"
  $scoreY += 34
}
Add "<line x1='1484' y1='398' x2='1848' y2='398' stroke='#00D8FF' stroke-opacity='.18'/>"
Add "<g transform='translate(1484 414)' stroke='#00D8FF' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='10' cy='10' r='8'/><path d='M10 10V2A8 8 0 0 1 18 10Z'/><path d='M10 10l-6 6'/></g>"
Add "<text x='1518' y='426' class='mono cyan' font-size='18' font-weight='900'>SECTOR DISTRIBUTION</text>"
Add "<text x='1518' y='446' class='font-cn gray' font-size='12'>$(X $T_SECTOR_DIST)</text>"
$barY=474
$maxSectorCount = ($sectorCounts | Measure-Object Count -Maximum).Maximum
foreach ($sc in $sectorCounts) {
  $name=$sc.Name; $count=[int]$sc.Count; $color=$sectorColors[$name]; $w=[math]::Round(126*$count/$maxSectorCount,0); $zh=SectorChinese $name; $pct=[math]::Round(([double]$count/$leaderCount)*100,0)
  Add "<rect x='1484' y='$($barY-16)' width='28' height='28' rx='5' fill='#07121C' fill-opacity='.9' stroke='$color' stroke-opacity='.55'/>"
  SectorIcon $name 1488 ($barY-12) $color
  Add "<text x='1524' y='$($barY-2)' fill='$color' class='font-en' font-size='14' font-weight='900'>$(X $name)</text>"
  Add "<text x='1524' y='$($barY+16)' class='font-cn gray' font-size='12' font-weight='700'>$(X $zh)</text>"
  Add "<rect x='1648' y='$($barY+1)' width='126' height='11' rx='1.5' fill='#132637'/>"
  Add "<rect x='1648' y='$($barY+1)' width='$w' height='11' rx='1.5' fill='$color'/>"
  Add "<text x='1810' y='$($barY+12)' class='mono white' font-size='14' text-anchor='end' font-weight='900'>$count</text>"
  Add "<text x='1848' y='$($barY+12)' class='mono white' font-size='13' text-anchor='end' font-weight='800'>$pct%</text>"
  $barY += 50
}
Add "<line x1='1484' y1='706' x2='1848' y2='706' stroke='#00D8FF' stroke-opacity='.18'/>"
Add "<g transform='translate(1484 714)' stroke='#00D8FF' fill='none' stroke-width='2.4' stroke-linecap='round' stroke-linejoin='round'><path d='M0 20l7-7 5 4 10-13'/><path d='M16 4h6v6'/><path d='M1 24h24M4 24V15M12 24V11M20 24V7'/></g>"
Add "<text x='1522' y='730' class='mono cyan' font-size='18' font-weight='900'>MARKET SCAN SUMMARY</text>"
Add "<text x='1522' y='750' class='font-cn gray' font-size='13' font-weight='700'>市場掃描總結</text>"
$summaryRows=@(
  @('momentum','平均動能分數','Average Momentum Score',('{0:0.00}' -f $avgMomentum),'#00D8FF'),
  @('buy','平均買入評級','Average Buyability Score',('{0:0.00}' -f $avgBuy),'#00D97B'),
  @('theme','市場主題','Market Theme',$marketTheme,'#00D8FF'),
  @('perf','6M 平均表現','6M Performance (Avg)',('+' + ('{0:0.00}' -f $avg6M) + '%'),'#00D97B'),
  @('perf','3M 平均表現','3M Performance (Avg)',('+' + ('{0:0.00}' -f $avg3M) + '%'),'#00D97B'),
  @('relvol','最高相對成交量','Highest Relative Volume',$highestRel,'#FF9D00')
)
$summaryTop=768
$summaryRowH=44
for ($summaryIndex=0; $summaryIndex -lt $summaryRows.Count; $summaryIndex++) {
  $s = $summaryRows[$summaryIndex]
  SummaryIcon $s[0] 1484 ($summaryTop+7) $s[4]
  Add "<text x='1532' y='$($summaryTop+20)' class='font-cn white' font-size='14' font-weight='900'>$(X $s[1])</text>"
  Add "<text x='1532' y='$($summaryTop+36)' class='font-en gray' font-size='12' font-weight='600'>$(X $s[2])</text>"
  $valueSize = if (([string]$s[3]).Length -gt 15) { 14 } else { 17 }
  Add "<text x='1848' y='$($summaryTop+30)' class='mono white' font-size='$valueSize' text-anchor='end' font-weight='900'>$(X $s[3])</text>"
  if ($summaryIndex -lt ($summaryRows.Count - 1)) {
    Add "<line x1='1484' y1='$($summaryTop+$summaryRowH)' x2='1848' y2='$($summaryTop+$summaryRowH)' stroke='#8B93A6' stroke-opacity='.16'/>"
  }
  $summaryTop += $summaryRowH
}
Add "<g id='terminal-footer'>"
Add "<rect x='390' y='1044' width='990' height='30' rx='3' fill='#07111B' fill-opacity='.86' stroke='#00D8FF' stroke-opacity='.28'/>"
Add "<line x1='390' y1='1044' x2='1380' y2='1044' stroke='#00D8FF' stroke-opacity='.42'/>"
Add "<circle cx='410' cy='1059' r='4' fill='#00D8FF' opacity='.9' filter='url(#glow)'/>"
Add "<text x='424' y='1064' class='mono cyan' font-size='12' font-weight='800'>LIVE</text>"
Add "<line x1='470' y1='1051' x2='470' y2='1068' stroke='#00D8FF' stroke-opacity='.25'/>"
Add "<text x='486' y='1064' class='mono gray' font-size='12'>MODE</text>"
Add "<text x='532' y='1064' class='mono white' font-size='12'>RADAR_RENDER</text>"
Add "<line x1='650' y1='1051' x2='650' y2='1068' stroke='#00D8FF' stroke-opacity='.25'/>"
Add "<text x='666' y='1064' class='mono gray' font-size='12'>DATA</text>"
Add "<text x='710' y='1064' class='mono white' font-size='12'>APL MOMENTUM DATABASE</text>"
Add "<line x1='910' y1='1051' x2='910' y2='1068' stroke='#00D8FF' stroke-opacity='.25'/>"
Add "<text x='926' y='1064' class='mono gray' font-size='12'>RANK</text>"
Add "<text x='974' y='1064' class='mono cyan' font-size='12' font-weight='800'>MOM+BUY+RV</text>"
Add "<line x1='1130' y1='1051' x2='1130' y2='1068' stroke='#00D8FF' stroke-opacity='.25'/>"
Add "<text x='1146' y='1064' class='mono gray' font-size='12'>DATE</text>"
Add "<text x='1194' y='1064' class='mono white' font-size='11'>$($weekLabel.ToUpperInvariant()) / $scanDate</text>"
Add "</g>"
Add '</svg>'

[System.IO.File]::WriteAllText($outSvg, ($svg -join [Environment]::NewLine), [System.Text.Encoding]::UTF8)
$log = @(
  'APL Deep-Scan Dashboard Render Log',
  "Date: $scanDate",
  "Input Ranking CSV: $RankingCsv",
  "Input Sector Map: $SectorMapPath",
  "Sector Map Schema: $($sectorMapInput.SchemaVersion)",
  "Output SVG: $outSvg",
  "Ranking CSV rows read: $(@($raw).Count)",
  "Renderer ranking source: prepared Full Ranking CSV",
  "Rendered Momentum Leaders: $(@($rows).Count)",
  "Dashboard capacity: $leaderCapacity",
  "Rows rendered: $leaderCount",
  'Ranking source: prepared Full Ranking CSV generated by Deep-Scan Research Mode',
  'Renderer rule: render Rank 1-30 only; no scoring or eligibility calculation',
  'Ordering: CSV Rank ascending',
  "Composite Top 5: $((($rows | Sort-Object Rank | Select-Object -First 5 | ForEach-Object { $_.Symbol + '=' + ('{0:0.00}' -f $_.Composite) }) -join ', '))",
  'Required fields checked: Rank, Symbol, Momentum Score, Buyability Score, Composite Score, Rel Vol, Perf 6M %, Perf 3M %',
  'Sector mapping: external sector map JSON',
  "Avg Momentum Score: $avgMomentum",
  "Avg Buyability Score: $avgBuy",
  "High Buyability: $highBuy",
  "Top Sector: $topSector",
  "Market Theme: $marketTheme",
  "Highest Rel Vol: $highestRel"
)
[System.IO.File]::WriteAllText($logPath, ($log -join [Environment]::NewLine), [System.Text.Encoding]::UTF8)
Write-Output $outSvg
Write-Output $logPath





