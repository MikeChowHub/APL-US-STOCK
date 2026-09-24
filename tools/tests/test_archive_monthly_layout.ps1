$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $root 'tools/production_archive_common.ps1')
$fixture=Join-Path $root ('tmp/monthly-layout-'+[guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $fixture)
foreach($date in @('2026-07-04','2026-08-28','2026-09-14')){
  $relative=Get-AplArchiveRelativeDatePath $date
  if($relative -cne ('2026/'+$date.Substring(5,2)+'/'+$date)){throw 'Path mapping failed'}
  [void](New-Item -ItemType Directory -Path (Join-Path $fixture $relative) -Force)
}
if(@(Get-AplMonthlyArchiveDates (Join-Path $fixture '2026') $fixture).Count -ne 3){throw 'Monthly discovery failed'}
'PASS monthly path and enumeration'
foreach($bad in @('2026/2026-09-15','2026/13/2026-12-15','2026/09/2026-08-15','2026/09/2025-09-15')){
  $isolated=Join-Path $fixture ([guid]::NewGuid().ToString('N'))
  [void](New-Item -ItemType Directory -Path (Join-Path $isolated $bad) -Force)
  $rejected=$false
  try {$null=@(Get-AplMonthlyArchiveDates (Join-Path $isolated '2026') $isolated)}catch{$rejected=$true}
  if(!$rejected){throw "Accepted bad layout: $bad"}
  "PASS rejected $bad"
}
foreach($file in @('tools/production_archive_common.ps1','tools/archive_daily_production.ps1','tools/complete_daily_production.ps1','tools/run_daily_production.ps1','tools/migrate_archive_monthly_layout.ps1')){
  $tokens=$null;$errors=$null
  [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $root $file),[ref]$tokens,[ref]$errors)
  if(@($errors).Count){throw "Syntax errors: $file"}
}
'PASS Windows PowerShell 5.1 syntax'
