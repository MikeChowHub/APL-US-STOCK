param([string]$ScanDate='2026-09-10')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $root 'tools/social_logo_compositor.ps1')
$fixture=Join-Path $root ('tmp/social-logo-'+[guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $fixture)
$utf8=New-Object Text.UTF8Encoding($false)
$results=New-Object 'System.Collections.Generic.List[object]'
foreach($name in @('Card','Radar_Top30')){
  $file="APL_DeepScan_Social_${name}_${ScanDate}_1080x1350.svg"
  $logo=Join-Path $root 'Assets/Brand/APL_Deep_Scan_Brand_Logo_Renderer_Clean.png'
  $data=[Convert]::ToBase64String([IO.File]::ReadAllBytes($logo))
  $text="<svg xmlns='http://www.w3.org/2000/svg' width='1080' height='1350' viewBox='0 0 1080 1350'><rect width='1080' height='1350' fill='#08131F'/><image id='apl-final-logo' href='data:image/png;base64,$data' x='32' y='22' width='490' height='147' preserveAspectRatio='xMinYMin meet'/></svg>"
  $svg=Join-Path $fixture $file
  [IO.File]::WriteAllText($svg,$text,$utf8)
  $png=[IO.Path]::ChangeExtension($svg,'.png')
  $audit=& (Join-Path $root 'tools/convert_svg_to_png.ps1') -InputSvg $svg -OutputPng $png -Width 1080 -Height 1350 -RegressionTest
  if($audit.Status -ne 'PASS' -or $audit.LogoOverlay.Status -ne 'PASS' -or $audit.FontFallbackWarningCount -ne 0 -or $audit.InvalidGeometryWarningCount -ne 0){throw 'Positive smoke failed.'}
  $results.Add([pscustomobject]@{Test=$name;Result='PASS';Output=$png;SHA256=$audit.Sha256})
  try { & (Join-Path $root 'tools/convert_svg_to_png.ps1') -InputSvg $svg -OutputPng $png -Width 1080 -Height 1350 -RegressionTest; throw 'STALE_ACCEPTED' }
  catch {if($_.Exception.Message -eq 'STALE_ACCEPTED'){throw}}
}
$lastText=$text
$longDirectory=Join-Path $fixture ('p'*(165-$fixture.Length-1))
[void][IO.Directory]::CreateDirectory($longDirectory)
$longSvg=Join-Path $longDirectory ('APL_DeepScan_Social_'+('x'*44)+'.svg')
[IO.File]::WriteAllText($longSvg,$lastText,$utf8)
$longPng=[IO.Path]::ChangeExtension($longSvg,'.png')
if(($longPng.Length+42)-lt260){throw 'Long-path fixture does not reproduce the old temporary-name limit.'}
$longAudit=& (Join-Path $root 'tools/convert_svg_to_png.ps1') -InputSvg $longSvg -OutputPng $longPng -Width 1080 -Height 1350 -RegressionTest
if($longAudit.Status-ne'PASS'){throw 'Long-path overlay failed.'}
$results.Add([pscustomobject]@{Test='LongTemporaryPath';Result='PASS'})
$assetRoot=Join-Path $fixture 'asset-negative'
$brand=Join-Path $assetRoot 'Assets/Brand'
[void](New-Item -ItemType Directory -Path $brand -Force)
$manifestSource=Join-Path $root 'Assets/Brand/brand-manifest.json'
[IO.File]::Copy($manifestSource,(Join-Path $brand 'brand-manifest.json'))
foreach($case in @('MissingAsset','WrongAssetSHA')){
  if($case -eq 'WrongAssetSHA'){
    [IO.File]::WriteAllBytes((Join-Path $brand 'APL_Deep_Scan_Brand_Logo_Renderer_Clean.png'),[byte[]]@(1,2,3))
  }
  $failed=$false
  try {$null=Get-AplSocialLogoPlan -InputSvg $svg -Root $assetRoot -Width 1080 -Height 1350} catch {$failed=$true}
  if(!$failed){throw "Negative case accepted: $case"}
  $results.Add([pscustomobject]@{Test=$case;Result='PASS (rejected)'})
}
foreach($case in @('MissingMarker','WrongSource','WrongPlacement','WrongCanvas')){
  $bad=$lastText
  switch($case){
    'MissingMarker' {$bad=$bad.Replace("id='apl-final-logo'",'')}
    'WrongSource' {$bad=$bad.Replace('data:image/png;base64,','data:image/png;base64,AAAA')}
    'WrongPlacement' {$bad=$bad.Replace("width='490' height='147'","width='491' height='147'")}
    'WrongCanvas' {$bad=$bad.Replace('0 0 1080 1350','0 0 1080 1351')}
  }
  $path=Join-Path $fixture ('APL_DeepScan_Social_'+$case+'.svg')
  [IO.File]::WriteAllText($path,$bad,$utf8)
  $failed=$false
  try { $null=Get-AplSocialLogoPlan -InputSvg $path -Root $root -Width 1080 -Height 1350 } catch {$failed=$true}
  if(!$failed){throw "Negative case accepted: $case"}
  $results.Add([pscustomobject]@{Test=$case;Result='PASS (rejected)'})
}
if(@(Get-ChildItem -LiteralPath $fixture -Filter '.logo-pass-*').Count -gt 0 -or @(Get-ChildItem -LiteralPath $fixture -Filter '*.logo-*.png').Count -gt 0){throw 'Partial files remain.'}
$results.ToArray()
