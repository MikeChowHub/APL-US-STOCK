$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $root 'tools/client_article_html.ps1')
$testRoot=Join-Path $root ('tmp/html-style-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot|Out-Null
$count=0
function Check([bool]$Condition,[string]$Name){if(-not$Condition){throw "FAIL $Name"};$script:count++;Write-Output "PASS $Name"}
function Reject([string]$Html,[string]$Name){$failed=$false;try{Assert-AplStyledArticle $Html @('NTSK','AVTR')|Out-Null}catch{$failed=$true};Check $failed $Name}
try{
 $raw='<h3>Executive Summary｜執行摘要</h3><p>本期主要關注NTSK與AVTR。</p><p>NTSK及AVTR服務不同需求。</p><h3>Market Context｜市場背景</h3><p>市場第一段保留。</p><p>第二段包含S&amp;P指數。會員專屬其後內容。</p><h3>Risk｜風險</h3><p>風險與判斷。</p>'
 $styled=ConvertTo-AplStyledArticle $raw @('NTSK','AVTR')
 Check (Assert-AplStyledArticle $styled @('NTSK','AVTR')) 'style-roundtrip'
 Check ((ConvertTo-AplArticleBody $styled)-ceq$raw) 'text-and-headings-preserved'
 Check (@([regex]::Matches($styled,'<strong ')).Count-eq2) 'first-symbol-only'
 Check (@([regex]::Matches($styled,'color:#e3c37b;')).Count-eq1) 'one-gold-judgement'
 Reject ($styled.Replace('max-width:800px','max-width:900px')) 'reject-wrong-width'
 Reject ($styled.Replace('margin:0 0 23px','margin:0 0 22px')) 'reject-spacing-drift'
 Reject ($styled.Replace('margin:34px 0 23px','margin:36px 0 23px')) 'reject-section-drift'
 Reject ($styled.Replace('<strong style="font-weight:700;color:#f3f1e8;">NTSK</strong>','NTSK')) 'reject-missing-first-bold'
 Reject ($styled.Replace('NTSK及AVTR服務','<strong style="font-weight:700;color:#f3f1e8;">NTSK</strong>及AVTR服務')) 'reject-repeat-bold'
 $source=Join-Path $testRoot 'source.txt';$preview=Join-Path $testRoot 'preview.txt';$sql=Join-Path $testRoot 'member.sql'
 [IO.File]::WriteAllText($source,$styled,[Text.UTF8Encoding]::new($true))
 $result=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $root 'tools/create_blog_delivery_supplements.ps1') -HtmlSourcePath $source -ScanDate '2026-10-20' -PublicPreviewPath $preview -MemberSqlPath $sql 2>&1
 Check ($LASTEXITCODE-eq0) ('styled-preview-generation '+($result-join' '))
 $p=[IO.File]::ReadAllText($preview)
 Check (Assert-AplStyledArticle $p @('NTSK','AVTR')) 'preview-same-style'
 Check ($p.EndsWith('<div id="apl-member-content"></div>')) 'member-boundary-outside-wrapper'
 Check ($p-match'第二段包含S&amp;P指數\.\.\.'-and$p-notmatch'會員專屬其後內容') 'truncation-and-no-leak'
 Check ($p-match'</div>\s*<div id="apl-member-content"></div>$') 'balanced-wrapper-before-boundary'
 Check ((Test-AplStyledArticleDate '2026-10-20')-and-not(Test-AplStyledArticleDate '2026-10-19')) 'effective-date-and-legacy'
 [IO.File]::WriteAllText($source,$raw,[Text.UTF8Encoding]::new($true))
 $ErrorActionPreference='Continue'
 $negative=& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $root 'tools/create_blog_delivery_supplements.ps1') -HtmlSourcePath $source -ScanDate '2026-10-20' -PublicPreviewPath (Join-Path $testRoot 'invalid-preview') -MemberSqlPath (Join-Path $testRoot 'invalid-sql') 2>&1
 $exit=$LASTEXITCODE;$ErrorActionPreference='Stop'
 Check ($exit-ne0) 'future-plain-html-rejected'
 "PASS $count / FAIL 0"
} finally {
 $full=[IO.Path]::GetFullPath($testRoot);$allowed=[IO.Path]::GetFullPath((Join-Path $root 'tmp'))+'\'
 if(-not$full.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)){throw 'Test cleanup scope violation'}
 Remove-Item -LiteralPath $full -Recurse -Force
}
