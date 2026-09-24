[CmdletBinding()]
param([switch]$Apply)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ((& git -C $root rev-parse --show-toplevel).Trim().Replace('/','\') -ine $root.TrimEnd('\')) {throw 'Git root mismatch'}
. (Join-Path $PSScriptRoot 'production_archive_common.ps1')
$archive=Join-Path $root 'Archive'
$year=Join-Path $archive '2026'
$policy=Read-AplArchiveV2Policy (Join-Path $root 'tools/archive-v2-policy.json') $root
function Inventory([string]$Path) {
  @(Get-AplSafeFileList $Path | ForEach-Object {
    [pscustomobject]@{RelativePath=$_.FullName.Substring($Path.Length+1).Replace('\','/');Size=[long]$_.Length;SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
  } | Sort-Object RelativePath)
}
$plans=New-Object 'System.Collections.Generic.List[object]'
foreach($dir in @(Get-ChildItem -LiteralPath $year -Directory | Where-Object {$_.Name -match '^2026-\d{2}-\d{2}$'} | Sort-Object Name)) {
  $src=Assert-AplNoReparsePath $dir.FullName $archive -RequireDirectory
  $dst=Assert-AplNoReparsePath (Join-Path $archive (Get-AplArchiveRelativeDatePath $dir.Name)) $archive
  $files=@(Inventory $src)
  if(!$files.Count){throw "Empty archive: $src"}
  $mp=Join-Path $src 'archive-manifest.json'
  if(Test-Path -LiteralPath $mp){
    $manifest=Read-AplStrictJson $mp $src
    Assert-AplArchiveManifest $manifest $dir.Name 'PASS' @(Get-AplArchiveInventory $src -ExcludeManifest) | Out-Null
  } elseif(!(Test-AplLegacyUnverifiedDate $policy $dir.Name)){throw "Unknown legacy: $src"}
  if(Test-Path -LiteralPath $dst){Assert-AplInventoryMatch $files @(Inventory $dst) 'Existing destination'}
  $plans.Add([pscustomobject]@{Date=$dir.Name;Source=$src;Destination=$dst;Files=[object[]]$files})
}
if(!$plans.Count){throw 'No unmigrated dates; no changes made.'}
$index=Join-Path $archive 'index.md'
$indexText=[IO.File]::ReadAllText($index)
$newIndex=$indexText
foreach($p in $plans){$newIndex=$newIndex.Replace(('2026/'+$p.Date+'/archive-manifest.json'),((Get-AplArchiveRelativeDatePath $p.Date)+'/archive-manifest.json'))}
$states=New-Object 'System.Collections.Generic.List[object]'
foreach($s in @(Get-ChildItem -LiteralPath (Join-Path $root 'outputs/logs') -Filter 'daily-production-state-*.json')) {
  $raw=[IO.File]::ReadAllText($s.FullName)
  $obj=$raw | ConvertFrom-Json
  $plan=@($plans | Where-Object {$_.Date -ceq [string]$obj.ScanDate})
  if($plan.Count -eq 0){continue}
  $oldPath=Join-Path $plan[0].Source 'archive-manifest.json'
  $newPath=Join-Path $plan[0].Destination 'archive-manifest.json'
  if([string]$obj.ArchiveManifest -ine $oldPath){throw "Unexpected state archive path: $($s.FullName)"}
  $oldJson=ConvertTo-Json -InputObject ([string]$obj.ArchiveManifest) -Compress
  $newJson=ConvertTo-Json -InputObject $newPath -Compress
  $updated=$raw.Replace($oldJson,$newJson)
  if(($updated|ConvertFrom-Json).ArchiveManifest -cne $newPath){throw 'State replacement failed'}
  $states.Add([pscustomobject]@{Path=$s.FullName;Text=$updated;BeforeSHA256=(Get-FileHash -LiteralPath $s.FullName -Algorithm SHA256).Hash;BeforeBase64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($s.FullName))})
}
[pscustomobject]@{Stage='PREFLIGHT PASS';Dates=$plans.Count;Files=($plans | ForEach-Object {$_.Files.Count}|Measure-Object -Sum).Sum;StateRecords=$states.Count;Apply=[bool]$Apply}
if(!$Apply){exit 0}
$auditDir=Join-Path $root ('work/archive-monthly-migration/'+[datetime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
[void](New-Item -ItemType Directory -Path $auditDir)
$utf8=New-Object Text.UTF8Encoding($true)
[IO.File]::WriteAllText((Join-Path $auditDir 'before.json'),(@{Dates=$plans.ToArray();States=$states.ToArray();IndexBase64=[Convert]::ToBase64String([IO.File]::ReadAllBytes($index))}|ConvertTo-Json -Depth 12),$utf8)
# Copy all dates, including excluded files and empty directories. Never modify payload bytes.
foreach($p in $plans){
  [void](New-Item -ItemType Directory -Path $p.Destination -Force)
  foreach($d in @(Get-ChildItem -LiteralPath $p.Source -Directory -Recurse)){
    Assert-AplNoReparsePath $d.FullName $archive -RequireDirectory | Out-Null
    [void](New-Item -ItemType Directory -Path (Join-Path $p.Destination $d.FullName.Substring($p.Source.Length+1)) -Force)
  }
  foreach($f in $p.Files){
    $target=Assert-AplNoReparsePath (Join-Path $p.Destination $f.RelativePath) $archive
    if(!(Test-Path -LiteralPath $target)){[IO.File]::Copy((Join-Path $p.Source $f.RelativePath),$target,$false)}
  }
  Assert-AplInventoryMatch $p.Files @(Inventory $p.Destination) 'Copied payload'
}
# Verify every source again before removing any source. Save durable copy evidence first.
foreach($p in $plans){Assert-AplInventoryMatch $p.Files @(Inventory $p.Source) 'Source unchanged';Assert-AplInventoryMatch $p.Files @(Inventory $p.Destination) 'Destination verified'}
[IO.File]::WriteAllText((Join-Path $auditDir 'copy-pass.json'),(@{Status='COPY_VERIFIED';Dates=$plans.ToArray()}|ConvertTo-Json -Depth 10),$utf8)
foreach($p in $plans){
  $src=Assert-AplNoReparsePath $p.Source $year -RequireDirectory
  if((Split-Path $src -Parent) -ine $year -or (Split-Path $src -Leaf) -cne $p.Date){throw 'Removal boundary failed'}
  foreach($f in $p.Files){
    $path=Assert-AplNoReparsePath (Join-Path $src $f.RelativePath) $src -RequireFile
    $target=Join-Path $p.Destination $f.RelativePath
    if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $f.SHA256 -or (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -cne $f.SHA256){throw 'Pre-delete hash mismatch'}
    Remove-Item -LiteralPath $path -Force
  }
  foreach($d in @(Get-ChildItem -LiteralPath $src -Directory -Recurse | Sort-Object {$_.FullName.Length} -Descending)){
    if(@(Get-ChildItem -LiteralPath $d.FullName -Force).Count){throw 'Nonempty source directory'}
    Remove-Item -LiteralPath $d.FullName -Force
  }
  if(@(Get-ChildItem -LiteralPath $src -Force).Count){throw 'Source is not empty'}
  Remove-Item -LiteralPath $src -Force
}
Write-AplUtf8Atomic $index $newIndex $archive | Out-Null
foreach($s in $states){Write-AplUtf8Atomic $s.Path $s.Text $root | Out-Null}
foreach($p in $plans){
  Assert-AplInventoryMatch $p.Files @(Inventory $p.Destination) 'Final payload'
  $mp=Join-Path $p.Destination 'archive-manifest.json'
  if(Test-Path -LiteralPath $mp){
    $m=Read-AplStrictJson $mp $p.Destination
    Assert-AplArchiveManifest $m $p.Date 'PASS' @(Get-AplArchiveInventory $p.Destination -ExcludeManifest) | Out-Null
    Assert-AplArchiveIndexRow $index $m $archive | Out-Null
  } else {
    $inv=@(Get-AplArchiveInventory $p.Destination -ExcludeManifest)
    Assert-AplLegacyArchiveIndexRow $index $p.Date $inv.Count ([long](($inv|Measure-Object Size -Sum).Sum)) $archive | Out-Null
  }
}
foreach($s in $states){$state=Read-AplStrictJson $s.Path $root;if(!(Test-Path -LiteralPath $state.ArchiveManifest)){throw 'Completion reference missing'}}
$record=[ordered]@{SchemaVersion='APL Archive Layout Migration v1';Status='PASS';Utc=[datetime]::UtcNow.ToString('o');Layout='YYYY/MM/YYYY-MM-DD';PayloadPolicy='All date-directory bytes unchanged, including historical manifest Destination and logs; paths there are original-run evidence.';Evidence=$auditDir;Dates=$plans.ToArray();UpdatedCompletionRecords=@($states|ForEach-Object {$_.Path})}
Write-AplUtf8Atomic (Join-Path $archive 'monthly-layout-migration-2026.json') ($record|ConvertTo-Json -Depth 10) $archive | Out-Null
[pscustomobject]$record | Select-Object Status,Layout,Evidence,@{n='Dates';e={$_.Dates.Count}},@{n='UpdatedCompletionRecords';e={$_.UpdatedCompletionRecords.Count}}
