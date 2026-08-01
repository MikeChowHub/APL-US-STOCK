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
. (Join-Path $PSScriptRoot 'dashboard_svg_geometry.ps1')
$resolved = Resolve-AplRendererInput -ExpectedRendererType Social -BoundParameters $PSBoundParameters -InputPath $InputPath -RankingCsv $RankingCsv -ScanDate $ScanDate -SectorMapPath $SectorMapPath -OutputPath $OutputPath -OutputDir $OutputDir -Root $Root -LogoPath $LogoPath -WeekLabel $WeekLabel -ScanUniverseCount $ScanUniverseCount -ScanQualifiedCount $ScanQualifiedCount -LeaderCapacity $LeaderCapacity -RegressionTest:$RegressionTest
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
$outSvg = Join-Path $OutputDir "APL_DeepScan_Social_Radar_Top30_${ScanDate}_1080x1350.svg"
$logPath = Join-Path $OutputDir "APL_DeepScan_Social_Radar_Top30_${ScanDate}_Render_Log.txt"
function X([string]$s) { return [System.Security.SecurityElement]::Escape($s) }
function Add([string]$s) { $script:svg.Add($s) }
function LogoData($path) {
  if (!(Test-Path -LiteralPath $path)) { return '' }
  return 'data:image/png;base64,' + [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($path))
}
function U([int[]]$codes) {
  $s = ''
  foreach ($c in $codes) { $s += [char]$c }
  return $s
}
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
  if ($b -ge 8) { return 16 }
  if ($b -ge 6) { return 11 }
  if ($b -ge 4) { return 7 }
  if ($b -ge 2) { return 4 }
  return 0
}
function Diameter([int]$rank, [double]$mom) {
  if ($rank -le 5) { $base=76; $max=98 }
  elseif ($rank -le 15) { $base=56; $max=72 }
  else { $base=40; $max=52 }
  $d = $base + (($mom - 56) / 34) * ($max - $base)
  if ($d -lt $base) { $d = $base }
  if ($d -gt $max) { $d = $max }
  return [math]::Round($d,1)
}
$rankMap = @{
  1=@(0,122); 2=@(215,178); 3=@(145,178); 4=@(285,178); 5=@(75,178);
  6=@(18,262); 7=@(54,270); 8=@(90,262); 9=@(126,270); 10=@(162,262);
  11=@(198,270); 12=@(234,262); 13=@(270,270); 14=@(306,262); 15=@(342,270);
  16=@(12,352); 17=@(36,365); 18=@(60,352); 19=@(84,365); 20=@(108,352);
  21=@(132,365); 22=@(156,352); 23=@(180,365); 24=@(204,352); 25=@(228,365);
  26=@(252,352); 27=@(276,365); 28=@(300,352); 29=@(324,365); 30=@(348,352)
}
function Pos([int]$rank) {
  $cx=540; $cy=560
  $p=$rankMap[$rank]
  $rad=([double]$p[0]-90)*[math]::PI/180
  $r=[double]$p[1]
  return @([math]::Round($cx+[math]::Cos($rad)*$r,2), [math]::Round($cy+[math]::Sin($rad)*$r,2))
}

$leaderCapacity = [math]::Min($LeaderCapacity, 30)
$rankedRaw = @(
  $raw |
    Where-Object { $_.Rank -match '^\d+$' -and [int]$_.Rank -ge 1 -and [int]$_.Rank -le $leaderCapacity } |
    Sort-Object @{Expression={ [int]$_.Rank }; Ascending=$true}, @{Expression='Symbol'; Ascending=$true} |
    Select-Object -First $leaderCapacity
)

$rows=@()
foreach ($r in $rankedRaw) {
  $rank=[int]$r.Rank
  $sym=[string]$r.Symbol
  $mom=[double]$r.'Momentum Score'
  $buy=[int]$r.'Buyability Score'
  $relVol=[double]$r.'Rel Vol'
  $composite = if ($r.PSObject.Properties.Name -contains 'Composite Score' -and [string]$r.'Composite Score' -ne '') {
    [double]$r.'Composite Score'
  } else {
    0
  }
  $sector=if ($sectorMap.ContainsKey($sym)) { $sectorMap[$sym] } else { $defaultSector }
  $p=Pos $rank
  $rows += [pscustomobject]@{
    Rank=$rank; Symbol=$sym; Momentum=$mom; Buy=$buy; Composite=[math]::Round($composite,2); RelVol=$relVol;
    Sector=$sector; Perf6=[double]$r.'Perf 6M %'; Perf3=[double]$r.'Perf 3M %'; X=$p[0]; Y=$p[1]; D=(Diameter $rank $mom)
  }
}$leaderCount=@($rows).Count
$highBuy=@($rows | Where-Object { $_.Buy -ge 8 }).Count
$avgMomentum=[math]::Round((($rows | Measure-Object Momentum -Average).Average),2)
$avgBuy=[math]::Round((($rows | Measure-Object Buy -Average).Average),2)
$highestRel=($rows | Sort-Object RelVol -Descending | Select-Object -First 1).Symbol
$sectorCounts=@($rows | ForEach-Object { [pscustomobject]@{ Sector=(NormalizeSector $_.Sector) } } | Group-Object Sector | Sort-Object @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false} | Select-Object -First 5)
$topSectorNames=@($sectorCounts | ForEach-Object { $_.Name })
$topSector=$sectorCounts[0].Name
$marketTheme=[string](Get-AplSectorVisual $sectorPresentation $topSector).MarketTheme
$buyBuckets=[ordered]@{
  '8-10'=@($rows | Where-Object { $_.Buy -ge 8 }).Count
  '6-7'=@($rows | Where-Object { $_.Buy -ge 6 -and $_.Buy -le 7 }).Count
  '4-5'=@($rows | Where-Object { $_.Buy -ge 4 -and $_.Buy -le 5 }).Count
  '2-3'=@($rows | Where-Object { $_.Buy -ge 2 -and $_.Buy -le 3 }).Count
  '0-1'=@($rows | Where-Object { $_.Buy -le 1 }).Count
}

$svg=New-Object System.Collections.Generic.List[string]
$logoData=LogoData $logoPath

Add '<?xml version="1.0" encoding="UTF-8"?>'
Add '<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1350" viewBox="0 0 1080 1350">'
Add '<defs>'
Add '<style><![CDATA[.font-cn{font-family:"Alibaba Sans HK";font-weight:400}.font-cn-semibold{font-family:"Alibaba Sans HK";font-weight:600}.font-en{font-family:"Montserrat";font-weight:400}.font-en-medium{font-family:"Montserrat";font-weight:500}.font-en-semibold{font-family:"Montserrat";font-weight:600}.font-en-bold{font-family:"Montserrat";font-weight:700}.mono{font-family:"Montserrat";font-weight:500}.mono-semibold{font-family:"Montserrat";font-weight:600}.font-cn[font-weight="800"],.font-en[font-weight="800"],.mono[font-weight="800"]{font-weight:600}.font-cn[font-weight="900"],.font-en[font-weight="900"],.mono[font-weight="900"]{font-weight:700}.white{fill:#fff}.cyan{fill:#00D8FF}.gray{fill:#8B93A6}.ticker{fill:#fff;font-weight:700;text-anchor:middle}.score{fill:#fff;text-anchor:middle;opacity:.86}.rank{fill:#00D8FF;text-anchor:middle;font-weight:700}.panel-title{fill:#00D8FF;font-weight:600}]]></style>'
Add '<filter id="glow"><feGaussianBlur stdDeviation="8" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
Add '<filter id="glowStrong" x="-120%" y="-120%" width="340%" height="340%"><feGaussianBlur stdDeviation="14" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
Add '<filter id="fogBlur" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="70"/></filter>'
Add '<radialGradient id="deepLighting" cx="50%" cy="43%" r="82%"><stop offset="0%" stop-color="#123B55"/><stop offset="38%" stop-color="#0A2233"/><stop offset="72%" stop-color="#06131D"/><stop offset="100%" stop-color="#03080D"/></radialGradient>'
Add '<radialGradient id="vignette" cx="50%" cy="45%" r="75%"><stop offset="0%" stop-color="#000" stop-opacity="0"/><stop offset="76%" stop-color="#000" stop-opacity=".32"/><stop offset="100%" stop-color="#000" stop-opacity=".78"/></radialGradient>'
Add '</defs>'
Add '<rect width="1080" height="1350" fill="url(#deepLighting)"/>'
Add '<ellipse cx="540" cy="560" rx="430" ry="370" fill="#00D8FF" opacity=".04" filter="url(#fogBlur)"/>'
Add '<ellipse cx="540" cy="560" rx="620" ry="520" fill="#008BFF" opacity=".022" filter="url(#fogBlur)"/>'
for ($x=0; $x -le 1080; $x += 45) { Add "<line x1='$x' y1='0' x2='$x' y2='1350' stroke='#0E3146' stroke-opacity='.13'/>" }
for ($y=0; $y -le 1350; $y += 45) { Add "<line x1='0' y1='$y' x2='1080' y2='$y' stroke='#0E3146' stroke-opacity='.13'/>" }
Add '<g fill="none" stroke="#8EEBFF" stroke-linecap="round">'
Add '<circle cx="540" cy="560" r="430" stroke-opacity=".026" stroke-dasharray="78 46 20 64"/>'
Add '<circle cx="540" cy="560" r="510" stroke-opacity=".018" stroke-dasharray="110 76 26 98"/>'
Add '<path d="M120 272 C280 234 425 282 590 248 S835 220 970 270" stroke-opacity=".025" stroke-width="1"/>'
Add '<path d="M105 880 C300 842 470 900 655 854 S905 824 1010 870" stroke-opacity=".023" stroke-width="1"/>'
Add '</g>'
for ($i=0; $i -lt 90; $i++) {
  $px=40+(($i*97)%1000); $py=90+(($i*131)%1120)
  $dist=[math]::Sqrt((($px-540)*($px-540))+(($py-560)*($py-560)))
  if ($dist -lt 230) { continue }
  $op=0.018+([math]::Min($dist,680)/680*.025)
  Add "<circle cx='$px' cy='$py' r='.7' fill='#8EEBFF' opacity='$('{0:0.000}' -f $op)'/>"
}
Add '<rect width="1080" height="1350" fill="url(#vignette)"/>'

if ($logoData) { Add "<image href='$logoData' x='32' y='22' width='490' height='147' preserveAspectRatio='xMinYMin meet'/>" }
$displayDate = [datetime]::ParseExact($scanDate, 'yyyy-MM-dd', $null).ToString('dd/MM')
Add "<text x='1002' y='96' class='mono white' font-size='42' text-anchor='end' font-weight='900'>$displayDate</text>"
Add "<line x1='878' y1='112' x2='1002' y2='112' stroke='#00D8FF' stroke-opacity='.72' stroke-width='3'/>"

function Card([int]$x,[int]$y,[int]$w,[int]$h) {
  Add "<rect x='$x' y='$y' width='$w' height='$h' rx='18' fill='#08131F' fill-opacity='.72' stroke='#00D8FF' stroke-opacity='.45'/>"
}

# Radar Hero
$cx=540; $cy=560
foreach ($r in @(92,150,260,360,430)) { Add "<circle cx='$cx' cy='$cy' r='$r' fill='none' stroke='#00D8FF' stroke-opacity='.16'/>" }
for ($deg=0; $deg -lt 360; $deg += 30) {
  $rad=($deg-90)*[math]::PI/180
  $x2=[math]::Round($cx+[math]::Cos($rad)*430,2); $y2=[math]::Round($cy+[math]::Sin($rad)*430,2)
  Add "<line x1='$cx' y1='$cy' x2='$x2' y2='$y2' stroke='#00D8FF' stroke-opacity='.10'/>"
}
Add '<path d="M540 560 L760 230 L835 300 Z" fill="#00D8FF" opacity=".065" filter="url(#glow)"/>'
Add "<circle cx='$cx' cy='$cy' r='96' fill='#00D8FF' opacity='.07' filter='url(#glow)'/>"
Add "<text x='$cx' y='$($cy-5)' class='font-en white' font-size='56' text-anchor='middle' font-weight='900'>APL</text>"
Add "<text x='$cx' y='$($cy+38)' class='font-en cyan' font-size='25' text-anchor='middle' font-weight='800'>Deep-Scan</text>"

foreach ($row in $rows) {
  $rank=[int]$row.Rank; $sym=X $row.Symbol; $buy=[int]$row.Buy; $d=[double]$row.D; $rr=$d/2; $x=[double]$row.X; $y=[double]$row.Y
  $norm=NormalizeSector $row.Sector
  $sectorColor=if ($topSectorNames -contains $norm) { $sectorColors[$norm] } else { $sectorColors['Others'] }
  $bc=BuyColor $buy; $glow=BuyGlow $buy
  if ($glow -gt 0) { Add "<circle cx='$x' cy='$y' r='$($rr+$glow)' fill='$bc' opacity='.13' filter='url(#glowStrong)'/>" }
  Add "<circle cx='$x' cy='$y' r='$rr' fill='#07121C' fill-opacity='.82' stroke='$sectorColor' stroke-width='2.2'/>"
  if ($rank -le 15) {
    $rankFs=if ($rank -le 5) { 17 } else { 13 }
    $tickerFs=if ($rank -le 5) { 25 } else { 18 }
    $scoreFs=if ($rank -le 5) { 14 } else { 11 }
    Add "<text x='$x' y='$($y-$rr+$rankFs+1)' class='mono rank' font-size='$rankFs'>$rank</text>"
    Add "<text x='$x' y='$($y+5)' class='font-en ticker' font-size='$tickerFs'>$sym</text>"
    Add "<text x='$x' y='$($y+25)' class='mono score' font-size='$scoreFs'>$('{0:0.00}' -f $row.Momentum)</text>"
  } else {
    Add "<text x='$x' y='$($y+5)' class='font-en ticker' font-size='15'>$sym</text>"
  }
}

# Hero data cards
$heroY=920
$ZH_UNIVERSE = U @(0x80A1,0x7968,0x6C60)
$ZH_QUALIFIED = U @(0x7B26,0x5408,0x689D,0x4EF6)
$ZH_LEADERS = U @(0x9818,0x5C0E,0x80A1)
$ZH_LOCK = U @(0x6838,0x5FC3,0x9396,0x5B9A)
$hero=@(
  @('Universe',$ZH_UNIVERSE,('{0:N0}' -f $scanUniverseCount)),
  @('Qualified',$ZH_QUALIFIED,('{0:N0}' -f $scanQualifiedCount)),
  @('Leaders',$ZH_LEADERS,('{0:N0}' -f $leaderCount)),
  @('Leader Lock',$ZH_LOCK,('{0:N0}' -f $highBuy))
)
for ($i=0; $i -lt 4; $i++) {
  $x=54+($i*243)
  Card $x $heroY 220 100
  Add "<text x='$($x+20)' y='$($heroY+34)' class='font-en gray' font-size='16' font-weight='800'>$(X $hero[$i][0])</text>"
  Add "<text x='$($x+20)' y='$($heroY+56)' class='font-cn gray' font-size='13' font-weight='700'>$(X $hero[$i][1])</text>"
  Add "<text x='$($x+200)' y='$($heroY+84)' class='mono white' font-size='32' text-anchor='end' font-weight='900'>$(X $hero[$i][2])</text>"
}

# Buyability and sector cards
Card 54 1038 440 270
$ZH_BUY_DIST = U @(0x8CB7,0x5165,0x8A55,0x7D1A,0x5206,0x4F48)
$ZH_SECTOR_DIST = U @(0x7522,0x696D,0x5206,0x4F48)
Add "<text x='84' y='1078' class='font-en cyan' font-size='22' font-weight='900'>BUYABILITY</text>"
Add "<text x='84' y='1100' class='font-cn gray' font-size='14' font-weight='700'>$(X $ZH_BUY_DIST)</text>"
Add "<circle cx='152' cy='1185' r='62' fill='#07121C' stroke='#00D8FF' stroke-opacity='.25'/>"
$circ=389.56; $offset=0
$BUY_STRONG = U @(0x5F37,0x70C8,0x8CB7,0x5165)
$BUY_GOOD = U @(0x826F,0x597D,0x6A5F,0x6703)
$BUY_NEUTRAL = U @(0x6A5F,0x6703,0x89C0,0x5BDF)
$BUY_WATCH = U @(0x7B49,0x5F85,0x89C0,0x5BDF)
$BUY_EXTENDED = U @(0x904E,0x5EA6,0x5EF6,0x4F38)
$buyRows=@(
  @($BUY_STRONG,'8-10',$buyBuckets['8-10'],'#00D8FF'),
  @($BUY_GOOD,'6-7',$buyBuckets['6-7'],'#00D97B'),
  @($BUY_NEUTRAL,'4-5',$buyBuckets['4-5'],'#008BFF'),
  @($BUY_WATCH,'2-3',$buyBuckets['2-3'],'#FF9D00'),
  @($BUY_EXTENDED,'0-1',$buyBuckets['0-1'],'#FF4E5E')
)
foreach ($b in $buyRows) {
  $count=[int]$b[2]
  if ($count -gt 0) {
    $dash=[math]::Round($circ*([double]$count/$leaderCount),2); $gap=[math]::Round($circ-$dash,2)
    Add "<circle cx='152' cy='1185' r='62' fill='none' stroke='$($b[3])' stroke-width='20' stroke-dasharray='$dash $gap' stroke-dashoffset='-$offset' transform='rotate(-90 152 1185)'/>"
    $offset += $dash
  }
}
Add "<circle cx='152' cy='1185' r='38' fill='#06131D'/>"
Add "<text x='152' y='1196' class='mono white' font-size='32' text-anchor='middle' font-weight='900'>$leaderCount</text>"
Add "<text x='152' y='1219' class='mono gray' font-size='11' text-anchor='middle'>TOTAL</text>"
$by=1120
foreach ($b in $buyRows) {
  $count=[int]$b[2]; $barW=Get-AplValidatedDistributionWidth $count $leaderCount 200 'Social buyability distribution'; $pct=[math]::Round(([double]$count/$leaderCount)*100,0)
  if ($pct -lt 0 -or $pct -gt 100) { throw "Social buyability distribution percentage $pct is outside 0..100." }
  Add "<text x='236' y='$by' fill='$($b[3])' class='font-cn' font-size='13.5' font-weight='600'>$(X $b[0]) ($($b[1]))</text>"
  Add "<text x='466' y='$by' class='mono white' font-size='13' text-anchor='end' font-weight='900'>$count / $pct%</text>"
  Add "<rect x='236' y='$($by+12)' width='200' height='9' rx='2.5' fill='#132637'/>"
  if ($barW -gt 0) { Add "<rect x='236' y='$($by+12)' width='$barW' height='9' rx='2.5' fill='$($b[3])'/>" }
  $by += 38
}

Card 524 1038 502 270
Add "<text x='554' y='1078' class='font-en cyan' font-size='21' font-weight='900'>SECTOR DISTRIBUTION</text>"
Add "<text x='554' y='1100' class='font-cn gray' font-size='14' font-weight='700'>$(X $ZH_SECTOR_DIST)</text>"
$barY=1124
$maxSector=($sectorCounts | Measure-Object Count -Maximum).Maximum
$null=ConvertTo-AplRequiredFiniteDouble $maxSector 'Social sector distribution maxSectorCount'
if ([double]$maxSector -le 0) { throw 'Social sector distribution maxSectorCount must be greater than zero.' }
foreach ($sc in $sectorCounts) {
  $name=$sc.Name; $count=[int]$sc.Count; $color=$sectorColors[$name]; $zh=SectorChinese $name
  $w=Get-AplValidatedDistributionWidth $count $maxSector 138 'Social sector distribution'; $pct=[math]::Round(([double]$count/$leaderCount)*100,0)
  Add "<text x='554' y='$barY' fill='$color' class='font-en' font-size='14' font-weight='900'>$(X $name)</text>"
  Add "<text x='554' y='$($barY+18)' class='font-cn gray' font-size='12' font-weight='700'>$(X $zh)</text>"
  Add "<rect x='806' y='$($barY+3)' width='138' height='12' rx='2.5' fill='#132637'/>"
  if ($w -gt 0) { Add "<rect x='806' y='$($barY+3)' width='$w' height='12' rx='2.5' fill='$color'/>" }
  Add "<text x='1004' y='$($barY+15)' class='mono white' font-size='14' text-anchor='end' font-weight='900'>$count  $pct%</text>"
  $barY += 40
}

Add "<text x='54' y='1332' class='font-cn gray' font-size='11'>$weekLabel  /  $scanDate  /  APL Deep-Scan</text>"

Add '</svg>'
[System.IO.File]::WriteAllText($outSvg, ($svg -join [Environment]::NewLine), [System.Text.Encoding]::UTF8)
$log=@(
  'APL Deep-Scan Social Radar Render Log',
  "Date: $scanDate",
  "Input Ranking CSV: $RankingCsv",
  "Input Sector Map: $SectorMapPath",
  "Sector Map Schema: $($sectorMapInput.SchemaVersion)",
  "Output SVG: $outSvg",
  'Canvas: 1080x1350',
  "Rows rendered: $leaderCount",
  'Layout: APL Deep-Scan Social Radar 4:5',
  'Renderer rule: render Rank 1-30 only; no scoring, ranking or eligibility calculation',
  'Ordering: CSV Rank ascending',
  'Ranking source: prepared Full Ranking CSV generated by Deep-Scan Research Mode'
)
[System.IO.File]::WriteAllText($logPath, ($log -join [Environment]::NewLine), [System.Text.Encoding]::UTF8)
Write-Output $outSvg
Write-Output $logPath
