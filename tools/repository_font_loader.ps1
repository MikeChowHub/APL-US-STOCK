# PS 5.1 repository font runtime. Stage A may use untracked assets only for work/tmp previews.
if (-not ('System.Drawing.Text.PrivateFontCollection' -as [type])) { Add-Type -AssemblyName System.Drawing }
$script:AplFontRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$script:AplFontManifestPath=Join-Path $PSScriptRoot 'font-manifest.json'
$script:AplFontStage='B';$script:AplFontCache=@{};$script:AplFontCollections=New-Object 'System.Collections.Generic.List[object]'
function Initialize-AplRepositoryFontRuntime {
 param([switch]$AllowUntrackedFontAssetsForSmokeTest,[string]$PreviewOutputPath='')
 if($AllowUntrackedFontAssetsForSmokeTest){
   $p=[IO.Path]::GetFullPath($PreviewOutputPath);$work=[IO.Path]::GetFullPath((Join-Path $script:AplFontRoot 'work')).TrimEnd('\');$tmp=[IO.Path]::GetFullPath((Join-Path $script:AplFontRoot 'tmp')).TrimEnd('\')
   if([string]::IsNullOrWhiteSpace($PreviewOutputPath) -or (-not $p.StartsWith($work+'\',[StringComparison]::OrdinalIgnoreCase) -and -not $p.StartsWith($tmp+'\',[StringComparison]::OrdinalIgnoreCase))){throw 'AllowUntrackedFontAssetsForSmokeTest is restricted to a work/ or tmp/ preview output.'}
   $script:AplFontStage='A'
 } else {$script:AplFontStage='B'}
}
function Get-AplFontManifest {
 if(!(Test-Path -LiteralPath $script:AplFontManifestPath)){throw "Font manifest is required: $script:AplFontManifestPath"}
 $m=[IO.File]::ReadAllText($script:AplFontManifestPath,[Text.Encoding]::UTF8)|ConvertFrom-Json
 if([string]$m.SchemaVersion -cne 'APL Repository Font Manifest v1.0' -or $null -eq $m.Fonts){throw 'Font manifest is invalid.'}
 if($script:AplFontStage -eq 'B'){
  $rel='tools/font-manifest.json';$tracked=@(& git -C $script:AplFontRoot ls-files --error-unmatch -- $rel 2>$null)
  if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1){throw 'Font manifest is not Git tracked.'}; & git -C $script:AplFontRoot cat-file -e ('HEAD:'+$rel) 2>$null;if($LASTEXITCODE -ne 0){throw 'Font manifest is not present in HEAD.'}
 };return $m
}
function Get-AplFontStyleKey([Drawing.FontStyle]$Style){if(($Style -band [Drawing.FontStyle]::Bold)-ne 0){'Bold'}else{'Regular'}}
function Get-AplRepositoryFont([string]$RequestedFamily,[Drawing.FontStyle]$Style=[Drawing.FontStyle]::Regular){
 $style=Get-AplFontStyleKey $Style;$key=$RequestedFamily+'|'+$style;if($script:AplFontCache.ContainsKey($key)){return $script:AplFontCache[$key]}
 $entry=@((Get-AplFontManifest).Fonts|Where-Object {[string]$_.logicalName -ceq $RequestedFamily -and [string]$_.style -ceq $style})
 if($entry.Count-ne 1){throw "Font manifest requires exactly one $RequestedFamily/$style entry."};$e=$entry[0];$rel=[string]$e.file;$path=[IO.Path]::GetFullPath((Join-Path $script:AplFontRoot $rel.Replace('/','\')));$assets=[IO.Path]::GetFullPath((Join-Path $script:AplFontRoot 'Assets\Fonts')).TrimEnd('\')
 if($rel -notmatch '^Assets/Fonts/.+\.(ttf|otf)$' -or !$path.StartsWith($assets+'\',[StringComparison]::OrdinalIgnoreCase) -or !(Test-Path -LiteralPath $path -PathType Leaf)){throw "Repository font file is required: $rel"}
 $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;if($hash -cne [string]$e.sha256){throw "Font SHA-256 mismatch for $rel"}
 if($script:AplFontStage -eq 'B'){$tracked=@(& git -C $script:AplFontRoot ls-files --error-unmatch -- $rel 2>$null);if($LASTEXITCODE-ne 0 -or $tracked.Count-ne 1){throw "Repository font file is not Git tracked: $rel"};& git -C $script:AplFontRoot cat-file -e ('HEAD:'+$rel) 2>$null;if($LASTEXITCODE-ne 0){throw "Repository font file is not present in HEAD: $rel"}}
 $pfc=New-Object Drawing.Text.PrivateFontCollection;try{$pfc.AddFontFile($path);$fam=@($pfc.Families|Where-Object {[string]$_.Name -ceq [string]$e.internalFamily})[0];if($null-eq $fam){$actual=@($pfc.Families|ForEach-Object {$_.Name})-join ', ';throw "Font family mismatch. Requested: $RequestedFamily; Expected internal: $($e.internalFamily); Resolved: $actual; Status: FAIL"};[void]$script:AplFontCollections.Add($pfc);$pfc=$null;$d=[pscustomobject]@{RequestedFamily=$RequestedFamily;ResolvedFamily=$fam.Name;RelativePath=$rel;FontFile=$path;Family=$fam;Style=$style;Weight=$e.weight;Stage=$script:AplFontStage};$script:AplFontCache[$key]=$d;return $d}finally{if($null-ne $pfc){$pfc.Dispose()}}
}
function New-AplRepositoryFont([string]$RequestedFamily,[float]$Size,[Drawing.FontStyle]$Style=[Drawing.FontStyle]::Regular){$d=Get-AplRepositoryFont $RequestedFamily $Style;$f=New-Object Drawing.Font($d.Family,$Size,$Style,[Drawing.GraphicsUnit]::Pixel);if([string]$f.Name-cne [string]$d.ResolvedFamily){$x=$f.Name;$f.Dispose();throw "Font runtime fallback detected. Requested: $RequestedFamily; Resolved: $x; Status: FAIL"};$d|Add-Member NoteProperty Font $f -Force;$d|Add-Member NoteProperty Size $Size -Force;return $d}
function Assert-AplRepositoryFontRuntime {param([string[]]$RequiredFamilies=@('Montserrat','Alibaba Sans HK'));foreach($n in $RequiredFamilies){[void](Get-AplRepositoryFont $n);[void](Get-AplRepositoryFont $n ([Drawing.FontStyle]::Bold))};$true}
