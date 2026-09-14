[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $projectRoot 'tools\production_archive_common.ps1')
$fixture=Join-Path $projectRoot ('tmp\builder-parent-guard-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture|Out-Null
$source=[IO.File]::ReadAllText((Join-Path $projectRoot 'tools\prepare_trigger_c_managed_inputs.ps1'))
$start=$source.IndexOf('$allowedContainer=')
$end=$source.IndexOf('$stagingDate=',$start)
$block=[scriptblock]::Create($source.Substring($start,$end-$start))
try {
  $RegressionTest=$true
  $regressionRoot=Join-Path $fixture 'status'
  $formalWorkRoot=$regressionRoot
  $stagingParent=Join-Path $regressionRoot 'staging'
  $managedParent=Join-Path $regressionRoot 'managed-inputs'
  $Mode='Status'
  . $block
  if(Test-Path $regressionRoot){throw 'Status created directories.'}
  $Mode='Initialize'
  . $block
  if(!(Test-Path $stagingParent)-or!(Test-Path $managedParent)){throw 'Normal directory initialization failed.'}
  $target=Join-Path $fixture 'outside'
  New-Item -ItemType Directory -Path $target|Out-Null
  $link=Join-Path $fixture 'linked'
  New-Item -ItemType Junction -Path $link -Target $target|Out-Null
  $regressionRoot=$link
  $stagingParent=Join-Path $link 'staging'
  $managedParent=Join-Path $link 'managed-inputs'
  $rejected=$false
  try{. $block}catch{if($_.Exception.Message -notmatch 'Reparse point'){throw};$rejected=$true}
  if(!$rejected-or@(Get-ChildItem $target -Force).Count){throw 'Junction was not rejected before writes.'}
  Write-Output 'PASS Status read-only; normal initialization; junction rejected before writes'
} finally {
  if($link-and(Test-Path -LiteralPath $link)){[IO.Directory]::Delete($link)}
  $safe=Assert-AplNoReparsePath -Path $fixture -AllowedRoot (Join-Path $projectRoot 'tmp') -RequireDirectory
  Remove-Item -LiteralPath $safe -Recurse -Force
}
