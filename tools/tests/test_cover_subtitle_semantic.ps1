[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $ProjectRoot 'tools\renderer_production_common.ps1')
$results=New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Name,[bool]$Passed,[string]$Detail=''){
  [void]$results.Add([pscustomobject]@{Name=$Name;Status=if($Passed){'PASS'}else{'FAIL'};Detail=$Detail})
  if($Passed){Write-Host "PASS $Name"}else{Write-Host "FAIL $Name :: $Detail" -ForegroundColor Red}
}
function Expect-Pass([string]$Name,[scriptblock]$Action){try{&$Action|Out-Null;Add-Result $Name $true}catch{Add-Result $Name $false $_.Exception.Message}}
function Expect-Fail([string]$Name,[scriptblock]$Action,[string]$Pattern){try{&$Action|Out-Null;Add-Result $Name $false 'Expected fail-closed rejection.'}catch{Add-Result $Name ($_.Exception.Message-match$Pattern) $_.Exception.Message}}

$date='2026-08-10'
$title=[string[]]@('中東能源風險重燃','AI 算力需求進入成本驗證期')
Expect-Pass 'descriptive-subtitle-pass' {Assert-AplCoverSubtitleSemantic -Subtitle "航運與能源成本回升，市場重新檢驗`nAI 投資能否轉化為收入與現金流" -ScanDate $date -TitleLines $title}
Expect-Fail 'apl-momentum-leaders-date-fail' {Assert-AplCoverSubtitleSemantic -Subtitle 'APL Momentum Leaders｜2026-08-10' -ScanDate $date -TitleLines $title} 'brand or series identity'
Expect-Fail 'deep-scan-brand-fail' {Assert-AplCoverSubtitleSemantic -Subtitle 'APL DEEP-SCAN 市場觀察' -ScanDate $date -TitleLines $title} 'brand or series identity'
Expect-Fail 'chinese-series-fail' {Assert-AplCoverSubtitleSemantic -Subtitle 'APL 美股深海雷達市場分析' -ScanDate $date -TitleLines $title} 'brand or series identity'
Expect-Fail 'scan-date-fail' {Assert-AplCoverSubtitleSemantic -Subtitle '市場結構觀察 2026-08-10' -ScanDate $date -TitleLines $title} 'must not repeat the scan date'
Expect-Fail 'title-duplication-fail' {Assert-AplCoverSubtitleSemantic -Subtitle '中東能源風險重燃' -ScanDate $date -TitleLines $title} 'must not duplicate the main title'
Expect-Fail 'empty-subtitle-fail' {Assert-AplCoverSubtitleSemantic -Subtitle '   ' -ScanDate $date -TitleLines $title} 'must be non-empty'

$failures=@($results|Where-Object{$_.Status-ne'PASS'})
Write-Host "Cover subtitle semantic gates: $($results.Count-$failures.Count) PASS, $($failures.Count) FAIL"
if($failures.Count-gt0){$failures|Format-Table -AutoSize|Out-String|Write-Host;exit 1}
exit 0
