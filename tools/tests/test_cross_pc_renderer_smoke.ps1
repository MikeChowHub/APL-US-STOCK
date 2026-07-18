[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$TestRoot = Join-Path $ProjectRoot ('tmp\cross-pc-renderer-smoke-' + [guid]::NewGuid().ToString('N'))
function Write-Utf8([string]$Path,[string]$Text){$parent=Split-Path -Parent $Path;if(!(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null};[IO.File]::WriteAllText($Path,$Text,[Text.Encoding]::UTF8)}
function Assert-Png([string]$Path,[int]$Width,[int]$Height){Add-Type -AssemblyName System.Drawing;$image=$null;try{$image=[Drawing.Image]::FromFile($Path);if($image.Width-ne $Width-or$image.Height-ne $Height){throw "PNG dimensions mismatch: $Path"}}finally{if($image){$image.Dispose()}}}
New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
try {
  $ranking=Join-Path $TestRoot 'ranking.csv'
  $lines=New-Object System.Collections.Generic.List[string]
  $lines.Add('Rank,Symbol,Momentum Score,Buyability Score,Composite Score,Rel Vol,Perf 6M %,Perf 3M %')
  foreach($i in 1..30){$lines.Add("$i,T$i,$(100-$i),$([math]::Max(1,10-($i%10))),$([math]::Round(110-$i,2)),$([math]::Round(1+($i/100),2)),$([math]::Round(50-$i,2)),$([math]::Round(25-$i/2,2))")}
  Write-Utf8 $ranking ($lines -join [Environment]::NewLine)
  $logo=Join-Path $ProjectRoot 'Assets\Brand\APL_Deep_Scan_Brand_Logo_Renderer_Clean.png'
  $sectorMap=Join-Path $ProjectRoot 'tools\sector_map.json'
  $dashboardScript=Join-Path $ProjectRoot 'tools\render_deep_scan_dashboard_svg.ps1'
  $socialScript=Join-Path $ProjectRoot 'tools\render_deep_scan_social_card_svg.ps1'
  $convertScript=Join-Path $ProjectRoot 'tools\convert_svg_to_png.ps1'
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $dashboardScript -RegressionTest -RankingCsv $ranking -ScanDate '2040-01-02' -SectorMapPath $sectorMap -OutputPath $TestRoot -LogoPath $logo -WeekLabel 'Cross-PC Smoke' -ScanUniverseCount 30 -ScanQualifiedCount 30 | Out-Null
  if($LASTEXITCODE-ne 0){throw 'Dashboard SVG smoke failed.'}
  $dashboardSvg=Join-Path $TestRoot 'APL_DeepScan_Radar_Dashboard_Top30_2040-01-02_1920x1080.svg';$dashboardPng=Join-Path $TestRoot 'dashboard.png'
  $dashboardResult=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $convertScript -RegressionTest -InputSvg $dashboardSvg -OutputPng $dashboardPng -Width 1920 -Height 1080
  if($LASTEXITCODE-ne 0){throw 'Dashboard PNG smoke failed.'};Assert-Png $dashboardPng 1920 1080
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $socialScript -RegressionTest -RankingCsv $ranking -ScanDate '2040-01-02' -SectorMapPath $sectorMap -OutputPath $TestRoot -LogoPath $logo -WeekLabel 'Cross-PC Smoke' -ScanUniverseCount 30 -ScanQualifiedCount 30 | Out-Null
  if($LASTEXITCODE-ne 0){throw 'Social SVG smoke failed.'}
  $socialSvg=Join-Path $TestRoot 'APL_DeepScan_Social_Card_2040-01-02_1080x1350.svg';$socialPng=Join-Path $TestRoot 'social.png'
  $socialResult=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $convertScript -RegressionTest -InputSvg $socialSvg -OutputPng $socialPng -Width 1080 -Height 1350
  if($LASTEXITCODE-ne 0){throw 'Social PNG smoke failed.'};Assert-Png $socialPng 1080 1350
  foreach($result in @($dashboardResult,$socialResult)){if([int]$result.FontFallbackWarningCount-ne 0-or[int]$result.InvalidGeometryWarningCount-ne 0){throw 'resvg smoke reported fallback or invalid geometry.'}}

  Add-Type -AssemblyName System.Drawing
  $coverBackground=Join-Path $TestRoot 'cover-background.png';$bitmap=[Drawing.Bitmap]::new(600,750);$graphics=[Drawing.Graphics]::FromImage($bitmap);try{$graphics.Clear([Drawing.Color]::FromArgb(4,15,24));$bitmap.Save($coverBackground,[Drawing.Imaging.ImageFormat]::Png)}finally{$graphics.Dispose();$bitmap.Dispose()}
  $seoBackground=Join-Path $TestRoot 'seo-background.png';$bitmap=[Drawing.Bitmap]::new(1280,720);$graphics=[Drawing.Graphics]::FromImage($bitmap);try{$graphics.Clear([Drawing.Color]::FromArgb(5,16,25));$bitmap.Save($seoBackground,[Drawing.Imaging.ImageFormat]::Png)}finally{$graphics.Dispose();$bitmap.Dispose()}
  $briefPath=Join-Path $TestRoot 'brief.json';$brief=[ordered]@{version='APL Cover Brief v1.1';scanDate='2040-01-02';marketConclusion='Cross-PC smoke';capitalFlow=[ordered]@{from='Cash';to='Leaders'};riskBackground='Smoke';leadershipDestination=@('Technology');mainVisualMetaphor='Light corridor';sceneConcept=[ordered]@{id='cross-pc-smoke';coreMarketThesis='Smoke';subjectIdentity='Light corridor';primarySceneElements=@('Corridor');colorPalette='Navy cyan gold';lightingDirection='Left to right';cinematicMood='Institutional';brandAtmosphere='Deep-Scan';artStyle='Cinematic realism'};nativeCompositions=[ordered]@{cover=[ordered]@{aspect_ratio='4:5';camera_distance='medium-close';framing_description='portrait';subject_placement='lower center';text_safe_area='upper portrait'};seo=[ordered]@{aspect_ratio='16:9';camera_distance='wide';framing_description='landscape';subject_placement='right third';text_safe_area='left landscape'}};composition=[ordered]@{textSafeArea='Role-specific';storyArea='Role-specific';rules=@('No UI')};imageGenerationBrief=[ordered]@{sharedPrompt='Smoke background';coverPrompt='Portrait close view';seoPrompt='Landscape wide view';negativePrompt='Text'};overlay=[ordered]@{kicker='APL DEEP SCAN';titleLines=@('CROSS-PC','ENVIRONMENT AUDIT');subtitle='Repository managed assets';series='APL US STOCK';date='2040-01-02';footer='Environment smoke'}}
  Write-Utf8 $briefPath ($brief|ConvertTo-Json -Depth 8)
  $overlayScript=Join-Path $ProjectRoot 'tools\render_blog_cover_overlay.ps1';$cover=Join-Path $TestRoot 'cover.png';$seo=Join-Path $TestRoot 'seo.png'
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $overlayScript -BriefPath $briefPath -BackgroundPath $coverBackground -OutputPath $cover -Variant Cover -LogoPath $logo -Width 600 -Height 750 | Out-Null
  if($LASTEXITCODE-ne 0){throw 'Cover smoke failed.'};Assert-Png $cover 600 750
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $overlayScript -BriefPath $briefPath -BackgroundPath $seoBackground -OutputPath $seo -Variant SEO -LogoPath $logo -Width 1280 -Height 720 | Out-Null
  if($LASTEXITCODE-ne 0){throw 'SEO smoke failed.'};Assert-Png $seo 1280 720
  foreach($log in @([IO.Path]::ChangeExtension($cover,'.overlay-log.txt'),[IO.Path]::ChangeExtension($seo,'.overlay-log.txt'))){$text=[IO.File]::ReadAllText($log,[Text.Encoding]::UTF8);if($text -match 'Status:\s*FAIL'){throw "Font fallback/failure in $log"};if(@($text -split "`r?`n"|Where-Object{$_ -match '^Font .*Status: PASS$'}).Count-lt 4){throw "Font audit records missing in $log"}}
  [pscustomobject]@{Status='PASS';Dashboard='1920x1080';Social='1080x1350';Cover='600x750';SEO='1280x720';FontFallbackWarningCount=0;InvalidGeometryWarningCount=0;Renderer='resvg';SystemFonts=$false;BrowserDependency=$false}
} finally {
  if(Test-Path -LiteralPath $TestRoot){Remove-Item -LiteralPath $TestRoot -Recurse -Force}
}
