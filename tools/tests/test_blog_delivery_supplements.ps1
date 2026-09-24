[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$ScriptPath=Join-Path $ProjectRoot 'tools\create_blog_delivery_supplements.ps1'
$Root=Join-Path $ProjectRoot 'tmp\blog-delivery-supplements'
$ScanDate='2099-09-22'
$results=New-Object System.Collections.Generic.List[object]

function Write-Utf8([string]$Path,[string]$Text){$parent=Split-Path -Parent $Path;if(!(Test-Path $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null};[IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($true)))}
function Add-Result([string]$Name,[bool]$Pass,[string]$Detail=''){$results.Add([pscustomobject]@{Test=$Name;Status=if($Pass){'PASS'}else{'FAIL'};Detail=$Detail})}
function Invoke-Case([string]$Name,[string]$Html,[int]$ExpectedExit){
  $case=Join-Path $Root $Name;$source=Join-Path $case 'article.html.txt';$preview=Join-Path $case 'article.public-preview.html.txt';$sql=Join-Path $case 'article.article.sql'
  Write-Utf8 $source $Html
  $oldPreference=$ErrorActionPreference;$ErrorActionPreference='Continue'
  $log=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $ScriptPath -HtmlSourcePath $source -ScanDate $ScanDate -PublicPreviewPath $preview -MemberSqlPath $sql 2>&1)
  $exit=$LASTEXITCODE;$ErrorActionPreference=$oldPreference
  Write-Utf8 (Join-Path $case 'run.log') ($log -join [Environment]::NewLine)
  Add-Result $Name ($exit -eq $ExpectedExit) "expected=$ExpectedExit actual=$exit"
  return [pscustomobject]@{Root=$case;Preview=$preview;Sql=$sql;Exit=$exit}
}

if(Test-Path $Root){Remove-Item -LiteralPath $Root -Recurse -Force};New-Item -ItemType Directory -Path $Root -Force|Out-Null
try{
  $valid='<h1>APL Deep-Scan｜美股深海雷達: 測試 | 2099-09-22</h1><h3>Executive Summary｜執行摘要</h3><p>完整摘要第一段。</p><p>完整摘要第二段。</p><h3>Market Context｜市場背景</h3><p>市場背景第一段完整保留。</p><p>第二段第一句保留。第二句只限會員。</p><h3>Risk｜風險</h3><p>風險。</p>'
  $positive=Invoke-Case 'valid-delivery' $valid 0
  if($positive.Exit -eq 0){
    $preview=[IO.File]::ReadAllText($positive.Preview,[Text.Encoding]::UTF8)
    $sql=[IO.File]::ReadAllText($positive.Sql,[Text.Encoding]::UTF8)
    $previewPass = ($preview -match '<div id="apl-member-content"></div>') -and ($preview -match '第二段第一句保留\.\.\.') -and ($preview -notmatch '第二句只限會員')
    Add-Result 'preview-boundary' $previewPass
    $sqlPass = ($sql -match "SELECT 'apl-deep-scan-2099-09-22', 'deepscan', '<p>PASTE'") -and (@([regex]::Matches($sql,'apl-deep-scan-2099-09-22')).Count -eq 2)
    Add-Result 'sql-exact-slug' $sqlPass
  }
  Invoke-Case 'missing-executive' ($valid-replace'(?s)<h3>Executive Summary.*?(?=<h3>Market Context)','') 1|Out-Null
  Invoke-Case 'missing-market' ($valid-replace'(?s)<h3>Market Context.*?(?=<h3>Risk)','') 1|Out-Null
  Invoke-Case 'one-market-paragraph' ($valid-replace'<p>第二段第一句保留。第二句只限會員。</p>','') 1|Out-Null
  Invoke-Case 'missing-truncation-punctuation' ($valid-replace'第二段第一句保留。第二句只限會員。','第二段沒有任何句號') 1|Out-Null
  $stale=Join-Path $Root 'stale-output';New-Item -ItemType Directory -Path $stale -Force|Out-Null;Write-Utf8 (Join-Path $stale 'article.html.txt') $valid;Write-Utf8 (Join-Path $stale 'article.public-preview.html.txt') 'stale'
  $oldPreference=$ErrorActionPreference;$ErrorActionPreference='Continue'
  $staleLog=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $ScriptPath -HtmlSourcePath (Join-Path $stale 'article.html.txt') -ScanDate $ScanDate -PublicPreviewPath (Join-Path $stale 'article.public-preview.html.txt') -MemberSqlPath (Join-Path $stale 'article.article.sql') 2>&1)
  $staleExit=$LASTEXITCODE;$ErrorActionPreference=$oldPreference
  Write-Utf8 (Join-Path $stale 'run.log') ($staleLog -join [Environment]::NewLine)
  Add-Result 'stale-output-fails' ($staleExit -eq 1)
  $failed=@($results | Where-Object Status -eq 'FAIL');$results|Format-Table -AutoSize;if($failed.Count){throw "$($failed.Count) blog delivery supplement regression test(s) failed."};"PASS $($results.Count) / FAIL 0"
}finally{if(Test-Path $Root){Remove-Item -LiteralPath $Root -Recurse -Force}}
