param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('ExecutiveSummary','TopLeaders','TopGainers','SectorStructure','MarketObservation','Comparison')]
  [string]$CardType,

  [Parameter(Mandatory = $true)]
  [string]$OutDir,

  [string]$Date = '',
  [string]$InputPath = '',
  [string]$InputJson = '',
  [string]$OutputName = '',
  [int]$Width = 1600,
  [int]$Height = 900,
  [switch]$RegressionTest,
  [switch]$AllowUntrackedFontAssetsForSmokeTest
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'renderer_production_common.ps1')
. (Join-Path $PSScriptRoot 'repository_font_loader.ps1')
Initialize-AplRepositoryFontRuntime -AllowUntrackedFontAssetsForSmokeTest:$AllowUntrackedFontAssetsForSmokeTest -PreviewOutputPath (Join-Path $OutDir $OutputName)
$OutDir = Assert-AplProductionPath (Get-AplFullPath $OutDir) 'OutDir' -RegressionTest:$RegressionTest
if (-not [string]::IsNullOrWhiteSpace($InputPath)) { $InputPath = Assert-AplProductionPath (Get-AplFullPath $InputPath) 'InputPath' -RegressionTest:$RegressionTest }

Add-Type -AssemblyName System.Drawing
$script:tableCardFontAudit = New-Object System.Collections.Generic.List[object]
[void](Assert-AplRepositoryFontRuntime)

function New-Font([string]$family, [float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
  $loaded = New-AplRepositoryFont $family $size $style
  [void]$script:tableCardFontAudit.Add($loaded)
  return $loaded.Font
}

function ConvertTo-PlainArray($value) {
  if ($null -eq $value) { return @() }
  if ($value -is [array]) { return @($value) }
  return @($value)
}

function Draw-RoundRect($g, [System.Drawing.Pen]$pen, [System.Drawing.Brush]$brush, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $r * 2
  $path.AddArc($x, $y, $d, $d, 180, 90)
  $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  if ($brush) { $g.FillPath($brush, $path) }
  if ($pen) { $g.DrawPath($pen, $path) }
  $path.Dispose()
}

function Draw-TextBox($g, [string]$text, [System.Drawing.Font]$font, [System.Drawing.Brush]$brush, [float]$x, [float]$y, [float]$w, [float]$h, [string]$align = 'Near', [bool]$topAlign = $false) {
  $fmt = [System.Drawing.StringFormat]::new()
  $fmt.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
  $fmt.FormatFlags = 0
  $fmt.LineAlignment = if ($topAlign) { [System.Drawing.StringAlignment]::Near } else { [System.Drawing.StringAlignment]::Center }
  if ($align -eq 'Center') { $fmt.Alignment = [System.Drawing.StringAlignment]::Center }
  elseif ($align -eq 'Far') { $fmt.Alignment = [System.Drawing.StringAlignment]::Far }
  else { $fmt.Alignment = [System.Drawing.StringAlignment]::Near }
  $g.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $fmt)
  $fmt.Dispose()
}

function Get-DefaultTitle([string]$type) {
  switch ($type) {
    'ExecutiveSummary' { return 'Executive Summary' }
    'TopLeaders' { return 'Top Leaders' }
    'TopGainers' { return (Get-AplCanonicalTopGainersTitle) }
    'SectorStructure' { return 'Sector Structure' }
    'MarketObservation' { return 'Market Observation' }
    'Comparison' { return 'Comparison' }
  }
}

function Read-CardInput([string]$path, [string]$json) {
  if (-not [string]::IsNullOrWhiteSpace($path)) {
    if (!(Test-Path -LiteralPath $path)) { throw "InputPath not found: $path" }
    return ([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) | ConvertFrom-Json)
  }
  if (-not [string]::IsNullOrWhiteSpace($json)) {
    return ($json | ConvertFrom-Json)
  }
  throw 'Either InputPath or InputJson is required.'
}

function Get-SafeFilePart([string]$value) {
  $safe = $value -replace '[^A-Za-z0-9_-]', '_'
  return $safe.Trim('_')
}

function Save-Card([string]$fileName, [string]$title, [string]$subtitle, [array]$columns, [array]$rows, [string]$sourceNote, [string]$footerNote) {
  $padding = 48
  $colGap = 18
  $bmp = [System.Drawing.Bitmap]::new($Width, $Height)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $bg = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.Rectangle]::new(0,0,$Width,$Height),
    [System.Drawing.Color]::FromArgb(8,28,42),
    [System.Drawing.Color]::FromArgb(2,8,14),
    90
  )
  $g.FillRectangle($bg, 0, 0, $Width, $Height)

  $cyan = [System.Drawing.Color]::FromArgb(0,216,255)
  $muted = [System.Drawing.Color]::FromArgb(160,176,194)
  $white = [System.Drawing.Color]::White
  $line = [System.Drawing.Color]::FromArgb(35,0,216,255)
  $panelBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(38, 5, 22, 34))
  $rowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(24, 10, 38, 55))
  $borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(145,0,216,255), 2)
  $linePen = [System.Drawing.Pen]::new($line, 1)
  $cyanBrush = [System.Drawing.SolidBrush]::new($cyan)
  $mutedBrush = [System.Drawing.SolidBrush]::new($muted)
  $whiteBrush = [System.Drawing.SolidBrush]::new($white)

  Draw-RoundRect $g $borderPen $panelBrush 18 18 ($Width-36) ($Height-36) 24

  $fontKicker = New-Font 'Montserrat' 16 ([System.Drawing.FontStyle]::Bold)
  $fontTitle = New-Font 'Alibaba Sans HK' 34 ([System.Drawing.FontStyle]::Bold)
  $fontSub = New-Font 'Alibaba Sans HK' 20 ([System.Drawing.FontStyle]::Regular)
  $fontHeader = New-Font 'Alibaba Sans HK' 18 ([System.Drawing.FontStyle]::Bold)
  $fontCell = New-Font 'Alibaba Sans HK' 22 ([System.Drawing.FontStyle]::Regular)
  $fontCellBold = New-Font 'Alibaba Sans HK' 22 ([System.Drawing.FontStyle]::Bold)
  $fontNote = New-Font 'Alibaba Sans HK' 15 ([System.Drawing.FontStyle]::Regular)

  Draw-TextBox $g ('APL TABLE CARD / ' + $CardType.ToUpperInvariant()) $fontKicker $cyanBrush $padding 28 ($Width - $padding*2) 24
  Draw-TextBox $g $title $fontTitle $whiteBrush $padding 58 ($Width - $padding*2) 50
  if (-not [string]::IsNullOrWhiteSpace($subtitle)) {
    Draw-TextBox $g $subtitle $fontSub $mutedBrush $padding 110 ($Width - $padding*2) 34
  }
  $g.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(135,0,216,255),2), $padding, 154, $Width-$padding, 154)

  $tableX = $padding
  $tableW = $Width - $padding*2
  $headerY = 172
  $x = $tableX
  foreach ($col in $columns) {
    $cw = [float]($tableW * $col.Width)
    Draw-TextBox $g $col.Label $fontHeader $cyanBrush $x $headerY ($cw-$colGap) 34 $col.Align
    $x += $cw
  }

  $reservedBottom = if ([string]::IsNullOrWhiteSpace($sourceNote) -and [string]::IsNullOrWhiteSpace($footerNote)) { 56 } else { 104 }
  $availableRowsH = $Height - ($headerY + 50) - $reservedBottom
  $effectiveRowHeight = [Math]::Max(74, [Math]::Floor($availableRowsH / [Math]::Max(1,$rows.Count)))
  $y = $headerY + 48
  for ($r = 0; $r -lt $rows.Count; $r++) {
    if ($r % 2 -eq 0) { $g.FillRectangle($rowBrush, $tableX, $y, $tableW, $effectiveRowHeight) }
    $g.DrawLine($linePen, $tableX, $y + $effectiveRowHeight, $tableX + $tableW, $y + $effectiveRowHeight)
    $x = $tableX
    for ($i = 0; $i -lt $columns.Count; $i++) {
      $col = $columns[$i]
      $cw = [float]($tableW * $col.Width)
      $value = [string]$rows[$r][$i]
      $font = if ($i -eq 0 -or ($col.Bold -eq $true)) { $fontCellBold } else { $fontCell }
      $brush = if ($i -eq 0) { $cyanBrush } else { $whiteBrush }
      Draw-TextBox $g $value $font $brush ($x+10) ($y+8) ($cw-$colGap-16) ($effectiveRowHeight-16) $col.Align
      $x += $cw
    }
    $y += $effectiveRowHeight
  }

  $noteY = $Height - 76
  if (-not [string]::IsNullOrWhiteSpace($sourceNote)) {
    Draw-TextBox $g $sourceNote $fontNote $mutedBrush $padding $noteY ($Width - $padding*2) 24 'Near'
    $noteY += 26
  }
  if (-not [string]::IsNullOrWhiteSpace($footerNote)) {
    Draw-TextBox $g $footerNote $fontNote $mutedBrush $padding $noteY ($Width - $padding*2) 24 'Near'
  }

  $out = Join-Path $OutDir $fileName
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)

  $g.Dispose(); $bmp.Dispose(); $bg.Dispose()
  $panelBrush.Dispose(); $rowBrush.Dispose(); $borderPen.Dispose(); $linePen.Dispose()
  $cyanBrush.Dispose(); $mutedBrush.Dispose(); $whiteBrush.Dispose()
  $fontKicker.Dispose(); $fontTitle.Dispose(); $fontSub.Dispose(); $fontHeader.Dispose(); $fontCell.Dispose(); $fontCellBold.Dispose(); $fontNote.Dispose()
  return $out
}

$card = Read-CardInput $InputPath $InputJson
$cardContract = Assert-AplTableCardContract $card $CardType
$title = if ($null -ne $card.Title -and -not [string]::IsNullOrWhiteSpace([string]$card.Title)) { [string]$card.Title } else { Get-DefaultTitle $CardType }
$subtitle = if ($null -ne $card.Subtitle) { [string]$card.Subtitle } else { '' }
$sourceNote = if ($null -ne $card.SourceNote) { [string]$card.SourceNote } else { '' }
$footerNote = if ($null -ne $card.FooterNote) { [string]$card.FooterNote } else { '' }
$columns = [object[]]$cardContract.Presentation.Columns
$rows = [object[]]$cardContract.Presentation.Rows
if ($rows.Count -gt 8) { throw 'Table card input Rows exceeds schema maximum 8.' }
function Get-TopGainersScopeNote {
  return 'Scope: SPX / NDX / DJI constituents'
}

if ($CardType -eq 'TopGainers' -and [string]::IsNullOrWhiteSpace($sourceNote)) {
  $sourceNote = Get-TopGainersScopeNote
}
if ([string]::IsNullOrWhiteSpace($OutputName)) {
  $datePart = if ([string]::IsNullOrWhiteSpace($Date)) { (Get-Date -Format 'yyyy-MM-dd') } else { $Date }
  $OutputName = 'APL_Blog_{0}_{1}.png' -f (Get-SafeFilePart $CardType), $datePart
}
if ([System.IO.Path]::IsPathRooted($OutputName) -or [System.IO.Path]::GetFileName($OutputName) -cne $OutputName) { throw 'OutputName must be a file name without directory or traversal segments.' }
$finalOutputPath = Assert-AplProductionPath ([System.IO.Path]::GetFullPath((Join-Path $OutDir $OutputName))) 'TableCardOutputPath' -RegressionTest:$RegressionTest
if (-not ([string](Split-Path -Parent $finalOutputPath)).Equals([string]$OutDir, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Resolved Table Card output must remain directly inside OutDir.' }
if (!(Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

$outPath = Save-Card $OutputName $title $subtitle $columns $rows $sourceNote $footerNote
$logPath = [System.IO.Path]::ChangeExtension($outPath, '.table-card-log.txt')
$schemaVersion = if ($null -ne $card.SchemaVersion) { [string]$card.SchemaVersion } else { 'not provided' }
$metaDate = if ($null -ne $card.Meta -and $null -ne $card.Meta.Date) { [string]$card.Meta.Date } else { $Date }
$log = @(
  'APL Blog Table Card Render Log',
  "CardType: $CardType",
  "SchemaVersion: $schemaVersion",
  "InputPath: $InputPath",
  "Output: $outPath",
  "Canvas: ${Width}x${Height}",
  "Rows: $($rows.Count)",
  "Columns: $($columns.Count)",
  "Date: $metaDate",
  "Font Asset Validation Stage: $script:AplFontStage",
  'Font Resolution Policy: PrivateFontCollection exact internal family; Stage B additionally requires Git tracking and HEAD presence',
  ($script:tableCardFontAudit | ForEach-Object { "Font | Requested Font: $($_.RequestedFamily) | Resolved Font: $($_.ResolvedFamily) | Font File: $($_.RelativePath) | Style: $($_.Style) | Status: PASS" }),
  'Contract: tools/table_card_input.schema.json',
  'Template: KnowledgeBase/Templates/Table_Card_Input_Contract.md',
  'Renderer role: render one structured research information card',
  'Deprecated as production input: raw CSV screenshot, full ranking dump, dashboard/radar table background'
)
$flatLog = New-Object System.Collections.Generic.List[string]
foreach ($entry in $log) { foreach ($line in $entry) { [void]$flatLog.Add([string]$line) } }
$log = @($flatLog)
[System.IO.File]::WriteAllText($logPath, ($log -join [Environment]::NewLine), [System.Text.Encoding]::UTF8)
[pscustomobject]@{
  CardType = $CardType
  Output = $outPath
  Log = $logPath
  Rows = $rows.Count
  Columns = $columns.Count
  Width = $Width
  Height = $Height
}

