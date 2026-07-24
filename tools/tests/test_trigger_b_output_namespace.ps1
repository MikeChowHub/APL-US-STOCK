[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$TestRoot=Join-Path $ProjectRoot ("tmp\trigger-b-output-namespace-"+[guid]::NewGuid().ToString('N'))
$SandboxRoot=Join-Path $TestRoot 'sandbox'
$InputCsv=Join-Path $TestRoot 'input.csv'
$ScanDate='2040-01-06'
$Script=Join-Path $ProjectRoot 'tools\process_apl_momentum_leaders.ps1'
$results=New-Object System.Collections.Generic.List[object]
$formalProtected=@(
  (Join-Path $ProjectRoot "outputs\$ScanDate"),
  (Join-Path $ProjectRoot "outputs\trigger-b\$ScanDate")
)
$formalBefore=@($formalProtected|ForEach-Object{[pscustomobject]@{Path=$_;Exists=(Test-Path -LiteralPath $_)}})

function Add-Result([string]$Name,[bool]$Passed,[string]$Detail=''){
  [void]$results.Add([pscustomobject]@{Name=$Name;Status=if($Passed){'PASS'}else{'FAIL'};Passed=$Passed;Detail=$Detail})
  if($Passed){Write-Host "PASS $Name"}else{Write-Host "FAIL $Name :: $Detail" -ForegroundColor Red}
}

function Write-Utf8([string]$Path,[string]$Text){
  $parent=Split-Path $Path -Parent
  if(!(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
  [IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($false)))
}

try{
  $header=@(
    'Symbol','Description','Price',
    '"Simple moving average, 20, 1 day"','"Simple moving average, 50, 1 day"','"Simple moving average, 200, 1 day"',
    '"High, 52 weeks"','"Performance %, 3 months"','"Performance %, 6 months"','"Relative volume, 1 day"'
  )-join','
  $rows=@(
    'AAA,Alpha Corp,100,95,90,80,110,20,40,2.2',
    'BBB,Beta Corp,80,78,70,60,90,12,30,1.8',
    'CCC,Gamma Corp,60,58,55,50,70,8,18,1.4',
    'DDD,Delta Corp,45,44,42,40,55,4,10,1.1',
    'EEE,Epsilon Corp,30,31,32,25,40,-2,5,0.9'
  )
  Write-Utf8 $InputCsv ((@($header)+@($rows))-join[Environment]::NewLine)

  $arguments=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Script,'-RegressionTest','-RegressionProjectRoot',$SandboxRoot,'-InputCsv',$InputCsv,'-ScanDate',$ScanDate,'-WeekLabel','Regression')
  $output=@(& powershell.exe @arguments 2>&1)
  Add-Result 'standalone-execution-pass' ($LASTEXITCODE-eq0) ($output-join' ')

  $standaloneRoot=Join-Path $SandboxRoot 'outputs\trigger-b'
  $dateRoot=Join-Path $standaloneRoot $ScanDate
  $expected=@(
    "APL_Momentum_Score_Full_Ranking_$ScanDate.csv",
    "APL_Quant_Top_30_$ScanDate.txt",
    "APL_Quant_Top_30_$ScanDate.md",
    "APL_Momentum_Leaders_Watchlist_$ScanDate.txt",
    "removed-below-sma200-$ScanDate.txt",
    "retained-missing-sma200-$ScanDate.txt",
    "APL_Momentum_Leaders_Overview_$ScanDate.md",
    "APL_Momentum_Leaders_Meta_$ScanDate.json",
    "APL_Momentum_Leaders_Source_$ScanDate.csv"
  )
  $actual=@(Get-ChildItem -LiteralPath $dateRoot -File|ForEach-Object{$_.Name}|Sort-Object)
  Add-Result 'dated-namespace-complete' ($actual.Count-eq$expected.Count-and-not(Compare-Object ($expected|Sort-Object) $actual))

  $rootCopies=@(Get-ChildItem -LiteralPath $standaloneRoot -File -ErrorAction SilentlyContinue)
  Add-Result 'standalone-root-copies-absent' ($rootCopies.Count-eq0)
  Add-Result 'final-production-namespace-absent' (-not(Test-Path -LiteralPath (Join-Path $SandboxRoot "outputs\$ScanDate")))

  $previousErrorAction=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  $rerun=@(& powershell.exe @arguments 2>&1)
  $rerunExit=$LASTEXITCODE
  $ErrorActionPreference=$previousErrorAction
  Add-Result 'existing-output-fails-closed' ($rerunExit-ne0) ($rerun-join' ')

  $formalAfter=@($formalProtected|ForEach-Object{[pscustomobject]@{Path=$_;Exists=(Test-Path -LiteralPath $_)}})
  $formalUnchanged=-not(Compare-Object @($formalBefore|ForEach-Object{"$($_.Path)|$($_.Exists)"}) @($formalAfter|ForEach-Object{"$($_.Path)|$($_.Exists)"}))
  Add-Result 'formal-repository-output-unchanged' $formalUnchanged
}catch{
  Add-Result 'test-harness' $false $_.Exception.Message
}finally{
  if(Test-Path -LiteralPath $TestRoot){Remove-Item -LiteralPath $TestRoot -Recurse -Force}
}

$failed=@($results|Where-Object{-not$_.Passed})
[pscustomobject]@{Passed=($failed.Count-eq0);Total=$results.Count;Failed=$failed.Count;Results=[object[]]$results.ToArray()}|ConvertTo-Json -Depth 5
if($failed.Count-gt0){exit 1}
