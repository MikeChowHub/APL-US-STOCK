param(
  [Parameter(Mandatory = $true)]
  [string]$BriefPath,

  [Parameter(Mandatory = $true)]
  [string]$BackgroundPath,

  [Parameter(Mandatory = $true)]
  [string]$OutputPath,

  [ValidateSet('Cover','SEO')]
  [string]$Variant = 'Cover',

  [string]$LogoPath = '',
  [int]$Width = 0,
  [int]$Height = 0,
  [switch]$AllowUntrackedFontAssetsForSmokeTest
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing
. (Join-Path $PSScriptRoot 'repository_font_loader.ps1')
Initialize-AplRepositoryFontRuntime -AllowUntrackedFontAssetsForSmokeTest:$AllowUntrackedFontAssetsForSmokeTest -PreviewOutputPath $OutputPath
$script:fontAudit = New-Object System.Collections.Generic.List[object]
$script:chineseFontFamily = 'Alibaba Sans HK'
$script:latinFontFamily = 'Montserrat'

function Read-Utf8Json($path) {
  if (!(Test-Path -LiteralPath $path)) { throw "JSON file not found: $path" }
  return ([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) | ConvertFrom-Json)
}

function New-TrackedFont([string]$role, [string]$requested, [float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
  if ([string]::IsNullOrWhiteSpace($requested)) { throw "Requested font is required for $role." }
  $loaded = New-AplRepositoryFont $requested $size $style
  $font = $loaded.Font
  $resolved = [string]$loaded.ResolvedFamily
  $record = [pscustomobject]@{ Role=$role; Requested=$requested; Resolved=$resolved; Status='PASS'; FontFile=$loaded.RelativePath; Size=$size; Style=[string]$style }
  [void]$script:fontAudit.Add($record)
  return $font
}

function Get-ObjectProperty($obj, [string]$name, $fallback) {
  if ($null -ne $obj -and $obj.PSObject.Properties.Name -contains $name -and $null -ne $obj.$name) {
    return $obj.$name
  }
  return $fallback
}

function Get-NumberProperty($obj, [string]$name, [double]$fallback) {
  $value = Get-ObjectProperty $obj $name $null
  if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) { return $fallback }
  try { return [double]$value } catch { return $fallback }
}

function Get-VariantObject($brief, [string]$section, [string]$variant) {
  if ($null -eq $brief -or -not ($brief.PSObject.Properties.Name -contains $section)) { return $null }
  $container = $brief.$section
  if ($null -eq $container) { return $null }
  $key = $variant.ToLowerInvariant()
  if ($container.PSObject.Properties.Name -contains $key) { return $container.$key }
  return $null
}

function New-OverlayConfig($brief, [string]$variant) {
  $cfg = @{}
  if ($variant -eq 'SEO') {
    $cfg.margin = 58; $cfg.top = 34; $cfg.logoWidth = 180; $cfg.logoHeight = 68; $cfg.logoGap = 22
    $cfg.kickerOffsetY = 8; $cfg.kickerHeight = 52
    $cfg.titleY = 140; $cfg.titleLineHeight = 78
    $cfg.subtitleGap = 16; $cfg.subtitleHeight = 52
    $cfg.metaGap = 62; $cfg.metaHeight = 40
    $cfg.footerY = 0; $cfg.footerHeight = 0
    $cfg.textSafeHeightRatio = 0.46
    $cfg.fontKicker = 34; $cfg.fontTitle = 72; $cfg.fontSubtitle = 34; $cfg.fontMeta = 26; $cfg.fontFooter = 0
  } else {
    $cfg.margin = 54; $cfg.top = 48; $cfg.logoWidth = 190; $cfg.logoHeight = 72; $cfg.logoGap = 22
    $cfg.kickerOffsetY = 8; $cfg.kickerHeight = 52
    $cfg.titleY = 178; $cfg.titleLineHeight = 90
    $cfg.subtitleGap = 16; $cfg.subtitleHeight = 52
    $cfg.metaGap = 62; $cfg.metaHeight = 40
    $cfg.footerY = -88; $cfg.footerHeight = 36
    $cfg.textSafeHeightRatio = 0.42
    $cfg.fontKicker = 34; $cfg.fontTitle = 82; $cfg.fontSubtitle = 38; $cfg.fontMeta = 28; $cfg.fontFooter = 25
  }
  $cfg.trackingKicker = 0; $cfg.trackingTitle = 0; $cfg.trackingSubtitle = 0; $cfg.trackingMeta = 0; $cfg.trackingFooter = 0

  $variantCfg = Get-VariantObject $brief 'overlay' $variant
  foreach ($key in @($cfg.Keys)) {
    $cfg[$key] = Get-NumberProperty $variantCfg $key ([double]$cfg[$key])
  }
  return $cfg
}

function New-CropConfig($brief, [string]$variant) {
  $cfg = @{
    anchor = 'center'
    focalX = 0.5
    focalY = 0.5
  }
  $variantCrop = $null
  if ($null -ne $brief.composition -and $brief.composition.PSObject.Properties.Name -contains 'crop') {
    $crop = $brief.composition.crop
    if ($null -ne $crop) {
      $key = $variant.ToLowerInvariant()
      if ($crop.PSObject.Properties.Name -contains $key) { $variantCrop = $crop.$key }
    }
  }

  $anchor = [string](Get-ObjectProperty $variantCrop 'anchor' $cfg.anchor)
  switch ($anchor) {
    'top' { $cfg.focalX = 0.5; $cfg.focalY = 0.0 }
    'bottom' { $cfg.focalX = 0.5; $cfg.focalY = 1.0 }
    'left' { $cfg.focalX = 0.0; $cfg.focalY = 0.5 }
    'right' { $cfg.focalX = 1.0; $cfg.focalY = 0.5 }
    'top-left' { $cfg.focalX = 0.0; $cfg.focalY = 0.0 }
    'top-right' { $cfg.focalX = 1.0; $cfg.focalY = 0.0 }
    'bottom-left' { $cfg.focalX = 0.0; $cfg.focalY = 1.0 }
    'bottom-right' { $cfg.focalX = 1.0; $cfg.focalY = 1.0 }
    default { $cfg.focalX = 0.5; $cfg.focalY = 0.5 }
  }

  $cfg.anchor = $anchor
  $cfg.focalX = [Math]::Max(0.0, [Math]::Min(1.0, (Get-NumberProperty $variantCrop 'focalX' ([double]$cfg.focalX))))
  $cfg.focalY = [Math]::Max(0.0, [Math]::Min(1.0, (Get-NumberProperty $variantCrop 'focalY' ([double]$cfg.focalY))))
  return $cfg
}

function Draw-TrackedTextBox($g, [string]$text, [System.Drawing.Font]$font, [System.Drawing.Brush]$brush, [float]$x, [float]$y, [float]$w, [float]$h, [string]$align, [float]$tracking) {
  $chars = $text.ToCharArray()
  if ($chars.Count -eq 0) { return }
  $widths = @()
  $total = 0.0
  foreach ($ch in $chars) {
    $size = $g.MeasureString([string]$ch, $font)
    $widths += $size.Width
    $total += $size.Width
  }
  $total += [Math]::Max(0, $chars.Count - 1) * $tracking
  $startX = $x
  if ($align -eq 'Center') { $startX = $x + (($w - $total) / 2) }
  elseif ($align -eq 'Far') { $startX = $x + $w - $total }
  $lineSize = $g.MeasureString($text, $font)
  $baselineY = $y + (($h - $lineSize.Height) / 2)
  for ($i = 0; $i -lt $chars.Count; $i++) {
    $g.DrawString([string]$chars[$i], $font, $brush, [System.Drawing.PointF]::new($startX, $baselineY))
    $startX += $widths[$i] + $tracking
  }
}

function Draw-TextBox($g, [string]$text, [System.Drawing.Font]$font, [System.Drawing.Brush]$brush, [float]$x, [float]$y, [float]$w, [float]$h, [string]$align = 'Near', [float]$tracking = 0) {
  if ([Math]::Abs($tracking) -gt 0.01) {
    Draw-TrackedTextBox $g $text $font $brush $x $y $w $h $align $tracking
    return
  }
  $fmt = [System.Drawing.StringFormat]::new()
  $fmt.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
  $fmt.FormatFlags = 0
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
  if ($align -eq 'Center') { $fmt.Alignment = [System.Drawing.StringAlignment]::Center }
  elseif ($align -eq 'Far') { $fmt.Alignment = [System.Drawing.StringAlignment]::Far }
  else { $fmt.Alignment = [System.Drawing.StringAlignment]::Near }
  $g.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $fmt)
  $fmt.Dispose()
}

function Draw-ShadowText($g, [string]$text, [System.Drawing.Font]$font, [System.Drawing.Brush]$brush, [float]$x, [float]$y, [float]$w, [float]$h, [string]$align = 'Near', [float]$tracking = 0) {
  $shadowBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
  Draw-TextBox $g $text $font $shadowBrush ($x+4) ($y+5) $w $h $align $tracking
  Draw-TextBox $g $text $font $brush $x $y $w $h $align $tracking
  $shadowBrush.Dispose()
}

function Draw-CroppedImage($g, [System.Drawing.Image]$img, [int]$targetW, [int]$targetH, [double]$focalX = 0.5, [double]$focalY = 0.5) {
  $srcRatio = [double]$img.Width / [double]$img.Height
  $dstRatio = [double]$targetW / [double]$targetH
  if ($srcRatio -gt $dstRatio) {
    $srcH = $img.Height
    $srcW = [int]($img.Height * $dstRatio)
    $srcX = [int](($img.Width - $srcW) * $focalX)
    $srcX = [Math]::Max(0, [Math]::Min(($img.Width - $srcW), $srcX))
    $srcY = 0
  } else {
    $srcW = $img.Width
    $srcH = [int]($img.Width / $dstRatio)
    $srcX = 0
    $srcY = [int](($img.Height - $srcH) * $focalY)
    $srcY = [Math]::Max(0, [Math]::Min(($img.Height - $srcH), $srcY))
  }
  $dest = [System.Drawing.Rectangle]::new(0, 0, $targetW, $targetH)
  $src = [System.Drawing.Rectangle]::new($srcX, $srcY, $srcW, $srcH)
  $g.DrawImage($img, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
}

function Add-TextSafeGradient($g, [int]$w, [int]$h, [double]$safeRatio) {
  $coverHeight = [int]($h * [Math]::Max(0.1, [Math]::Min(0.8, $safeRatio)))
  $rect = [System.Drawing.Rectangle]::new(0, 0, $w, $coverHeight)
  $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    $rect,
    [System.Drawing.Color]::FromArgb(225, 2, 8, 14),
    [System.Drawing.Color]::FromArgb(30, 2, 8, 14),
    90
  )
  $g.FillRectangle($brush, $rect)
  $brush.Dispose()

  $vignette = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(40, 0, 0, 0))
  $g.FillRectangle($vignette, 0, 0, $w, $h)
  $vignette.Dispose()
}

function Draw-Logo($g, [string]$path, [float]$x, [float]$y, [float]$maxW, [float]$maxH) {
  if ([string]::IsNullOrWhiteSpace($path) -or !(Test-Path -LiteralPath $path)) { return }
  $logo = [System.Drawing.Image]::FromFile($path)
  try {
    $ratio = [double]$logo.Width / [double]$logo.Height
    $w = $maxW
    $h = $w / $ratio
    if ($h -gt $maxH) { $h = $maxH; $w = $h * $ratio }
    $g.DrawImage($logo, [System.Drawing.RectangleF]::new($x, $y, $w, $h))
  } finally {
    $logo.Dispose()
  }
}

$brief = Read-Utf8Json $BriefPath
if (!(Test-Path -LiteralPath $BackgroundPath)) { throw "Background image not found: $BackgroundPath" }
if (Test-Path -LiteralPath $OutputPath) { throw "OutputPath already exists; renderer will not overwrite it: $OutputPath" }

if ($Width -le 0 -or $Height -le 0) {
  if ($Variant -eq 'SEO') {
    $Width = 1280; $Height = 720
  } else {
    $Width = 1080; $Height = 1350
  }
}

$outDir = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outDir) -and !(Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir | Out-Null
}

$bg = [System.Drawing.Image]::FromFile($BackgroundPath)
$bmp = [System.Drawing.Bitmap]::new($Width, $Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

try {
  $layout = New-OverlayConfig $brief $Variant
  $crop = New-CropConfig $brief $Variant

  Draw-CroppedImage $g $bg $Width $Height ([double]$crop.focalX) ([double]$crop.focalY)
  Add-TextSafeGradient $g $Width $Height ([double]$layout.textSafeHeightRatio)

  $cyan = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0,216,255))
  $gold = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255,209,71))
  $white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
  $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(200,220,230,240))

  $margin = [float]$layout.margin
  $top = [float]$layout.top
  $logoW = [float]$layout.logoWidth
  $logoH = [float]$layout.logoHeight
  $logoGap = [float]$layout.logoGap
  $fontKicker = New-TrackedFont 'fontKicker' $script:latinFontFamily ([float]$layout.fontKicker) ([System.Drawing.FontStyle]::Bold)
  $fontTitle = New-TrackedFont 'fontTitle' $script:chineseFontFamily ([float]$layout.fontTitle) ([System.Drawing.FontStyle]::Bold)
  $fontSub = New-TrackedFont 'fontSubtitle' $script:chineseFontFamily ([float]$layout.fontSubtitle) ([System.Drawing.FontStyle]::Bold)
  $fontMeta = New-TrackedFont 'fontMeta' $script:latinFontFamily ([float]$layout.fontMeta) ([System.Drawing.FontStyle]::Bold)
  $lineHeight = [float]$layout.titleLineHeight

  Draw-Logo $g $LogoPath $margin $top $logoW $logoH
  $kickerX = if ([string]::IsNullOrWhiteSpace($LogoPath)) { $margin } else { $margin + $logoW + $logoGap }
  Draw-ShadowText $g ([string]$brief.overlay.kicker) $fontKicker $cyan $kickerX ($top + [float]$layout.kickerOffsetY) ($Width - $kickerX - $margin) ([float]$layout.kickerHeight) 'Near' ([float]$layout.trackingKicker)

  $titleY = [float]$layout.titleY
  $titleLines = @($brief.overlay.titleLines)
  for ($i = 0; $i -lt $titleLines.Count; $i++) {
    $brush = if ($i -eq 1) { $gold } else { $white }
    Draw-ShadowText $g ([string]$titleLines[$i]) $fontTitle $brush $margin ($titleY + $i * $lineHeight) ($Width - $margin*2) $lineHeight 'Near' ([float]$layout.trackingTitle)
  }

  $subY = $titleY + ($titleLines.Count * $lineHeight) + [float]$layout.subtitleGap
  if (-not [string]::IsNullOrWhiteSpace([string]$brief.overlay.subtitle)) {
    Draw-ShadowText $g ([string]$brief.overlay.subtitle) $fontSub $muted $margin $subY ($Width - $margin*2) ([float]$layout.subtitleHeight) 'Near' ([float]$layout.trackingSubtitle)
  }

  $meta = ([string]$brief.overlay.series) + ' | ' + ([string]$brief.overlay.date)
  Draw-ShadowText $g $meta $fontMeta $cyan $margin ($subY + [float]$layout.metaGap) ($Width - $margin*2) ([float]$layout.metaHeight) 'Near' ([float]$layout.trackingMeta)

  if ($Variant -eq 'Cover' -and -not [string]::IsNullOrWhiteSpace([string]$brief.overlay.footer)) {
    $fontFooter = New-TrackedFont 'fontFooter' $script:chineseFontFamily ([float]$layout.fontFooter) ([System.Drawing.FontStyle]::Regular)
    $footerY = [float]$layout.footerY
    if ($footerY -lt 0) { $footerY = $Height + $footerY }
    Draw-ShadowText $g ([string]$brief.overlay.footer) $fontFooter $muted $margin $footerY ($Width - $margin*2) ([float]$layout.footerHeight) 'Center' ([float]$layout.trackingFooter)
    $fontFooter.Dispose()
  }

  $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
  if ($fontKicker) { $fontKicker.Dispose() }
  if ($fontTitle) { $fontTitle.Dispose() }
  if ($fontSub) { $fontSub.Dispose() }
  if ($fontMeta) { $fontMeta.Dispose() }
  if ($cyan) { $cyan.Dispose() }
  if ($gold) { $gold.Dispose() }
  if ($white) { $white.Dispose() }
  if ($muted) { $muted.Dispose() }
  $g.Dispose()
  $bmp.Dispose()
  $bg.Dispose()
}

$logPath = [System.IO.Path]::ChangeExtension($OutputPath, '.overlay-log.txt')
$log = @(
  'APL Blog Cover Overlay Render Log',
  "Variant: $Variant",
  "Brief: $BriefPath",
  "Background: $BackgroundPath",
  "Output: $OutputPath",
  "Canvas: ${Width}x${Height}",
  "Crop Anchor: $($crop.anchor)",
  "Crop Focal Point: $($crop.focalX), $($crop.focalY)",
  "Text Safe Height Ratio: $($layout.textSafeHeightRatio)",
  "Logo Box: $($layout.logoWidth)x$($layout.logoHeight)",
  "Title Font / Line Height / Y: $($layout.fontTitle) / $($layout.titleLineHeight) / $($layout.titleY)",
  "Font Asset Validation Stage: $script:AplFontStage",
  'Font Resolution Policy: PrivateFontCollection exact internal family; Stage B additionally requires Git tracking and HEAD presence',
  ($script:fontAudit | ForEach-Object { "Font $($_.Role) | Requested Font: $($_.Requested) | Resolved Font: $($_.Resolved) | Font File: $($_.FontFile) | Status: $($_.Status)" }),
  'Background source rule: ImageGen cinematic background only',
  'Local renderer role: precise text/logo overlay only',
  'Deprecated as production cover source: local SVG, shape-based cinematic simulation, abstract radar cover, flow-line infographic cover'
)
$flatLog = New-Object System.Collections.Generic.List[string]
foreach ($entry in $log) { foreach ($line in $entry) { [void]$flatLog.Add([string]$line) } }
$log = @($flatLog)
[System.IO.File]::WriteAllText($logPath, ($log -join [Environment]::NewLine), [System.Text.Encoding]::UTF8)

[pscustomobject]@{
  Variant = $Variant
  Output = $OutputPath
  Log = $logPath
  Width = $Width
  Height = $Height
}
