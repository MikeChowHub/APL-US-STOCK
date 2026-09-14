# Windows PowerShell 5.1. Marked Social and Dashboard logos are composited after resvg.
function Get-AplSocialLogoPlan {
  param([string]$InputSvg,[string]$Root,[int]$Width,[int]$Height)
  $doc=New-Object System.Xml.XmlDocument
  $doc.XmlResolver=$null
  $doc.Load($InputSvg)
  $nodes=@($doc.SelectNodes("//*[local-name()='image' and @id='apl-final-logo']"))
  if($nodes.Count -eq 0){
    if([IO.Path]::GetFileName($InputSvg) -match '^APL_DeepScan_(Social_|Radar_Dashboard_)'){throw 'Chart logo: required final-overlay marker missing.'}
    return $null
  }
  if($nodes.Count -ne 1){ throw 'Social logo: exactly one marked logo is required.' }
  $node=$nodes[0]
  if($Width -eq 1080 -and $Height -eq 1350){$x=32;$y=22;$boxWidth=490;$boxHeight=147}
  elseif($Width -eq 1920 -and $Height -eq 1080){$x=24;$y=22;$boxWidth=500;$boxHeight=190}
  else {throw 'Chart logo: unsupported canvas.'}
  if($doc.DocumentElement.GetAttribute('viewBox') -cne "0 0 $Width $Height"){throw 'Chart logo: unsupported viewBox.'}
  foreach($pair in @(@('x',"$x"),@('y',"$y"),@('width',"$boxWidth"),@('height',"$boxHeight"),@('preserveAspectRatio','xMinYMin meet'))){
    if($node.GetAttribute($pair[0]) -cne $pair[1]){ throw 'Social logo: unapproved placement.' }
  }
  $manifest=Get-Content -LiteralPath (Join-Path $Root 'Assets/Brand/brand-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $assets=@($manifest.Assets | Where-Object {$_.Id -eq 'production-logo-clean'})
  if($assets.Count -ne 1){ throw 'Social logo: missing or duplicate brand manifest entry.' }
  $asset=$assets[0]
  if($asset.File -cne 'Assets/Brand/APL_Deep_Scan_Brand_Logo_Renderer_Clean.png'){ throw 'Social logo: unapproved asset path.' }
  $path=Join-Path $Root $asset.File
  if(!(Test-Path -LiteralPath $path -PathType Leaf)){ throw 'Social logo: source missing.' }
  $sha=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if($sha -ine $asset.SHA256){ throw 'Social logo: source SHA mismatch.' }
  $expected='data:image/png;base64,'+[Convert]::ToBase64String([IO.File]::ReadAllBytes($path))
  if($node.GetAttribute('href') -cne $expected){ throw 'Social logo: embedded source differs from approved asset.' }
  [void]$node.ParentNode.RemoveChild($node)
  return [pscustomobject]@{Document=$doc;Source=$path;SHA256=$sha;CanvasWidth=$Width;CanvasHeight=$Height;X=$x;Y=$y;BoxWidth=$boxWidth;BoxHeight=$boxHeight;Policy='Final pixel-space overlay; single high-quality downsample; no logo redraw'}
}

function Add-AplSocialLogo {
  param([string]$Png,$Plan)
  Add-Type -AssemblyName System.Drawing
  $canvas=$null; $logo=$null; $graphics=$null; $attributes=$null
  $partial=Join-Path (Split-Path $Png -Parent) ('.logo-'+[guid]::NewGuid().ToString('N')+'.png')
  try {
    $canvas=[Drawing.Bitmap]::FromFile($Png)
    $logo=[Drawing.Image]::FromFile($Plan.Source)
    if($canvas.Width -ne $Plan.CanvasWidth -or $canvas.Height -ne $Plan.CanvasHeight){ throw 'Chart logo: canvas dimensions mismatch.' }
    if($logo.Width -ne 1677 -or $logo.Height -ne 620){ throw 'Social logo: source dimensions mismatch.' }
    $graphics=[Drawing.Graphics]::FromImage($canvas)
    $graphics.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $attributes=New-Object Drawing.Imaging.ImageAttributes
    $attributes.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $scale=[Math]::Min($Plan.BoxWidth/[double]$logo.Width,$Plan.BoxHeight/[double]$logo.Height)
    $w=[int][Math]::Round($logo.Width*$scale)
    $h=[int][Math]::Round($logo.Height*$scale)
    $rect=New-Object Drawing.Rectangle($Plan.X,$Plan.Y,$w,$h)
    $graphics.DrawImage($logo,$rect,0,0,$logo.Width,$logo.Height,[Drawing.GraphicsUnit]::Pixel,$attributes)
    $canvas.Save($partial,[Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $graphics=$null
    $canvas.Dispose(); $canvas=$null
    [IO.File]::Copy($partial,$Png,$true)
  } finally {
    if($attributes){$attributes.Dispose()}; if($graphics){$graphics.Dispose()}
    if($logo){$logo.Dispose()}; if($canvas){$canvas.Dispose()}
    if(Test-Path -LiteralPath $partial){Remove-Item -LiteralPath $partial -Force}
  }
}
