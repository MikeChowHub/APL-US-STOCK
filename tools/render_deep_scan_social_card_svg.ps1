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
$managedHeadlineLines=@()
$coreMarketThesis=''
if($null-ne$resolved.Contract-and$null-ne$resolved.Contract.Meta){
  $managedHeadlineLines=@($resolved.Contract.Meta.SocialHeadlineLines|ForEach-Object{([string]$_).Trim()}|Where-Object{-not[string]::IsNullOrWhiteSpace($_)})
  $coreMarketThesis=([string]$resolved.Contract.Meta.CoreMarketThesis).Trim()
}
$raw = Import-AplRankingCsv $RankingCsv
$sectorPresentation = Import-AplSectorPresentation $SectorMapPath
if ([string]::IsNullOrWhiteSpace($WeekLabel)) {
  $calendar = [System.Globalization.CultureInfo]::InvariantCulture.Calendar
  $dateValue = [datetime]::ParseExact($ScanDate, 'yyyy-MM-dd', $null)
  $weekNumber = $calendar.GetWeekOfYear($dateValue, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
  $WeekLabel = "Week $weekNumber"
}
if (!(Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }
$outSvg = Join-Path $OutputDir "APL_DeepScan_Social_Card_${ScanDate}_1080x1350.svg"
$logPath = Join-Path $OutputDir "APL_DeepScan_Social_Card_${ScanDate}_Render_Log.txt"
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
  $rows += [pscustomobject]@{
    Rank=$rank; Symbol=$sym; Momentum=$mom; Buy=$buy; Composite=[math]::Round($composite,2); RelVol=$relVol;
    Sector=$sector; Perf6=[double]$r.'Perf 6M %'; Perf3=[double]$r.'Perf 3M %'
  }
}
$leaderCount=@($rows).Count
if($leaderCount-lt1){throw 'Social Card requires at least one ranked leader.'}
$topLeaders=@($rows|Sort-Object Rank|Select-Object -First 3)
$focusSectorCounts=@($topLeaders | ForEach-Object { [pscustomobject]@{ Sector=(NormalizeSector $_.Sector) } } | Group-Object Sector | Sort-Object @{Expression='Count';Descending=$true}, @{Expression='Name';Descending=$false})
$namedFocusSector=@($focusSectorCounts | Where-Object { $_.Name-ne'Others'-and[int]$_.Count-ge2 } | Select-Object -First 1)
$hasNamedCluster=$namedFocusSector.Count-gt0
if($hasNamedCluster){
  $focusSectorGroup=$namedFocusSector[0]
  $topSector=$focusSectorGroup.Name
  $topSectorVisual=Get-AplSectorVisual $sectorPresentation $topSector
  $marketTheme=[string]$topSectorVisual.MarketTheme
  $insightTheme=[string]$topSectorVisual.InsightTheme
  $topSectorChinese=[string]$topSectorVisual.ChineseLabel
  $topSectorCount=[int]$focusSectorGroup.Count
  $topSectorPct=[math]::Round(([double]$topSectorCount/$topLeaders.Count)*100,0)
  $evidenceTitle=$topSector
  $evidenceChinese=$topSectorChinese
  $evidenceMetric="$topSectorPct%"
  $evidenceCaption="$topSectorCount OF $($topLeaders.Count) SELECTED LEADERS"
}else{
  $marketTheme='Selective Leadership'
  $insightTheme='No dominant named group in the selected leaders'
  $topSectorChinese=U @(0x9818,0x5C0E,0x5206,0x6563)
  $evidenceTitle='Selective Leadership'
  $evidenceChinese=$topSectorChinese
  $evidenceMetric=[string]$topLeaders.Count
  $evidenceCaption='TOP-RANKED LEADERS'
}
$headlineLines=if($managedHeadlineLines.Count-gt0){[string[]]$managedHeadlineLines}else{[string[]]@($marketTheme)}

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

# One mobile-first message
$ZH_LEADERSHIP_FOCUS=U @(0x9818,0x5C0E,0x7126,0x9EDE)
$ZH_CURRENT_LEADERS=U @(0x7576,0x671F,0x9818,0x5C0E,0x80A1)
$ZH_SUPPORTING_EVIDENCE=U @(0x652F,0x6301,0x8B49,0x64DA)
Add "<text x='54' y='238' class='font-en cyan' font-size='22' font-weight='900'>LEADERSHIP FOCUS</text>"
Add "<text x='54' y='272' class='font-cn gray' font-size='18' font-weight='700'>$(X $ZH_LEADERSHIP_FOCUS)</text>"
if($headlineLines.Count-eq1){
  $headlineClass=if($headlineLines[0]-match'[\u3400-\u9FFF]'){'font-cn'}else{'font-en'}
  Add "<text x='54' y='348' class='$headlineClass white' font-size='58' font-weight='900'>$(X $headlineLines[0])</text>"
  Add "<text x='54' y='402' class='font-cn gray' font-size='28' font-weight='700'>$(X $topSectorChinese) / $(X $insightTheme)</text>"
  Add "<line x1='54' y1='438' x2='1026' y2='438' stroke='#00D8FF' stroke-opacity='.45' stroke-width='2'/>"
}else{
  for($i=0;$i-lt$headlineLines.Count;$i++){
    $headlineClass=if($headlineLines[$i]-match'[\u3400-\u9FFF]'){'font-cn'}else{'font-en'}
    Add "<text x='54' y='$((330+($i*58)))' class='$headlineClass white' font-size='50' font-weight='900'>$(X $headlineLines[$i])</text>"
  }
  Add "<text x='54' y='430' class='font-cn gray' font-size='24' font-weight='700'>$(X $topSectorChinese) / $(X $insightTheme)</text>"
  Add "<line x1='54' y1='458' x2='1026' y2='458' stroke='#00D8FF' stroke-opacity='.45' stroke-width='2'/>"
}

# Selected leaders: three evidence points, not a full radar
Card 54 486 972 390
Add "<text x='88' y='538' class='font-en cyan' font-size='22' font-weight='900'>CURRENT LEADERS</text>"
Add "<text x='88' y='570' class='font-cn gray' font-size='17' font-weight='700'>$(X $ZH_CURRENT_LEADERS)</text>"
$leaderX=@(236,540,844)
for($i=0;$i-lt$topLeaders.Count;$i++){
  $row=$topLeaders[$i];$x=$leaderX[$i];$sector=NormalizeSector $row.Sector
  $color=if($sectorColors.ContainsKey($sector)){$sectorColors[$sector]}else{$sectorColors['Others']}
  Add "<circle cx='$x' cy='704' r='112' fill='#07121C' fill-opacity='.88' stroke='$color' stroke-width='4'/>"
  Add "<circle cx='$x' cy='704' r='126' fill='none' stroke='$color' stroke-opacity='.18' stroke-width='2'/>"
  Add "<text x='$x' y='650' class='mono cyan' font-size='20' text-anchor='middle' font-weight='900'>#$([int]$row.Rank)</text>"
  Add "<text x='$x' y='715' class='font-en white' font-size='42' text-anchor='middle' font-weight='900'>$(X $row.Symbol)</text>"
  Add "<text x='$x' y='758' class='font-en gray' font-size='17' text-anchor='middle' font-weight='700'>$(X $sector)</text>"
}

# Minimum supporting evidence: one group-level measure
Card 54 916 972 300
Add "<text x='88' y='970' class='font-en cyan' font-size='22' font-weight='900'>SUPPORTING EVIDENCE</text>"
Add "<text x='88' y='1002' class='font-cn gray' font-size='17' font-weight='700'>$(X $ZH_SUPPORTING_EVIDENCE)</text>"
Add "<text x='88' y='1092' class='font-en white' font-size='38' font-weight='900'>$(X $evidenceTitle)</text>"
Add "<text x='88' y='1144' class='font-cn gray' font-size='25' font-weight='700'>$(X $evidenceChinese)</text>"
Add "<text x='984' y='1094' class='mono white' font-size='62' text-anchor='end' font-weight='900'>$(X $evidenceMetric)</text>"
Add "<text x='984' y='1142' class='font-en gray' font-size='18' text-anchor='end' font-weight='700'>$(X $evidenceCaption)</text>"

Add "<text x='54' y='1332' class='font-cn gray' font-size='11'>$weekLabel  /  $scanDate  /  APL Deep-Scan</text>"

Add '</svg>'
[System.IO.File]::WriteAllText($outSvg, ($svg -join [Environment]::NewLine), [System.Text.Encoding]::UTF8)
$log=@(
  'APL Deep-Scan Social Card Render Log',
  "Date: $scanDate",
  "Input Ranking CSV: $RankingCsv",
  "Input Sector Map: $SectorMapPath",
  "Sector Map Schema: $($sectorMapInput.SchemaVersion)",
  "Output SVG: $outSvg",
  'Canvas: 1080x1350',
  "Ranking rows evaluated: $leaderCount",
  "Leaders displayed: $($topLeaders.Count)",
  "Primary message: $($headlineLines-join' | ')",
  "Core market thesis: $coreMarketThesis",
  "Supporting evidence: $evidenceTitle; $evidenceMetric; $evidenceCaption",
  'Layout: APL Deep-Scan Social Card mobile-first single-message',
  'Renderer rule: evaluate Rank 1-30; display only selected evidence; no scoring or eligibility calculation',
  'Ordering: CSV Rank ascending',
  'Ranking source: prepared Full Ranking CSV generated by Deep-Scan Research Mode'
)
[System.IO.File]::WriteAllText($logPath, ($log -join [Environment]::NewLine), [System.Text.Encoding]::UTF8)
Write-Output $outSvg
Write-Output $logPath



