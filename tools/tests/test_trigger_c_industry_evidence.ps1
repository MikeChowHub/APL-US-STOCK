$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $root 'tools\prepare_trigger_c_managed_inputs.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'Trigger C preparation has PowerShell syntax errors.'}
$fn=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Export-AplTop30Industries'},$true)
if(!$fn){throw 'Industry evidence function is missing.'}
Invoke-Expression $fn.Extent.Text
function Write-Utf8([string]$Path,[string]$Text,[string]$AllowedRoot){[IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false))}
$dir=Join-Path $root ('tmp\industry-evidence-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dir -Force|Out-Null
$csv=Join-Path $dir 'source.csv';$ranking=Join-Path $dir 'ranking.csv';$output=Join-Path $dir 'industry.json'
$symbols=@('AA','AB','AC','AD','AE','AF','AG','AH','AI','AJ','AK','AL','AM','AN','AO','AP','AQ','AR','AS','AT','AU','AV','AW','AX','AY','AZ','BA','BB','BC','BD')
$header='Symbol,Description,"Relative volume, 1 day","Relative volume, 1 day",Industry'
$rows=@($header)+@($symbols|ForEach-Object{"$_,Company,1,1,`"Software, services`""})
$rankRows=@('Rank,Symbol,Name')+@(for($i=0;$i-lt30;$i++){"$($i+1),$($symbols[$i]),Company"})
[IO.File]::WriteAllLines($ranking,[string[]]$rankRows,[Text.UTF8Encoding]::new($false))
function Write-Fixture([string[]]$Lines){[IO.File]::WriteAllLines($csv,$Lines,[Text.UTF8Encoding]::new($false))}
function Expect-Failure([string]$Label){try{Export-AplTop30Industries $csv $ranking $output $dir;throw "$Label unexpectedly passed"}catch{if($_.Exception.Message -like '*unexpectedly passed*'){throw};Write-Output "PASS $Label rejected"}}
Write-Fixture $rows
Export-AplTop30Industries $csv $ranking $output $dir
$evidence=Get-Content -Raw -Encoding UTF8 $output|ConvertFrom-Json
if(@($evidence.Rows).Count-ne30-or$evidence.Rows[0].SourceIndustry-cne'Software, services'-or$evidence.SourceSHA256-cne(Get-FileHash $csv).Hash){throw 'Industry evidence content mismatch.'}
'PASS duplicate unrelated headers, quoted comma, Top 30 and source hash'
Write-Fixture (@('Symbol,Description,"Relative volume, 1 day","Relative volume, 1 day",Sector')+$rows[1..30]);Expect-Failure 'missing Industry'
Write-Fixture (@($header)+@('AA,Company,1,1,')+$rows[2..30]);Expect-Failure 'blank Top 30 Industry'
Write-Fixture (@($header)+$rows[1..29]+@('AA,Company,1,1,Software'));Expect-Failure 'duplicate Symbol'
