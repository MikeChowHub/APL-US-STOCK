$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $root 'tools\renderer_production_common.ps1')
$passed = 0
$failed = 0

function Invoke-Case([string]$Name, [bool]$ShouldPass, [scriptblock]$Action) {
  try {
    & $Action
    if (-not $ShouldPass) { throw 'Expected failure but action passed.' }
    $script:passed++
    Write-Host "PASS $Name"
  } catch {
    if ($ShouldPass) { $script:failed++; Write-Host "FAIL $Name :: $($_.Exception.Message)" }
    else { $script:passed++; Write-Host "PASS $Name (rejected: $($_.Exception.Message))" }
  }
}

function Convert-Fixture([string]$Json) { return (($Json -replace '\\\\u','\u') | ConvertFrom-Json) }

$executive = Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"ExecutiveSummary","Title":"Executive","Rows":[{"observation":"\\u5e02\\u5834\\u5ee3\\u5ea6\\u4ecd\\u7136\\u96c6\\u4e2d\\uff0c\\u5408\\u8cc7\\u683c\\u80a1\\u7968\\u53ea\\u6709\\u5c11\\u6578\\u9032\\u5165\\u9818\\u5c0e\\u5c64\\u3002","meaning":"\\u9019\\u8868\\u793a\\u8cc7\\u91d1\\u914d\\u7f6e\\u4ecd\\u7136\\u9078\\u64c7\\u6027\\u8f03\\u9ad8\\uff0c\\u4e0d\\u80fd\\u628a\\u6307\\u6578\\u53cd\\u5f48\\u8996\\u70ba\\u5168\\u9762\\u64f4\\u6563\\u3002"},{"observation":"\\u9818\\u5c0e\\u80a1\\u52d5\\u80fd\\u8f03\\u5f37\\uff0c\\u4f46\\u8cb7\\u9ede\\u689d\\u4ef6\\u4ecd\\u7136\\u56b7\\u683c\\u3002","meaning":"Leader Lock \\u4ee3\\u8868\\u88ab\\u9396\\u5b9a\\u7684\\u9818\\u5c0e\\u80a1\\u96c6\\u5408\\uff1bBuyability \\u53cd\\u6620\\u73fe\\u968e\\u6bb5\\u53ef\\u8ffd\\u8e64\\u7684\\u9032\\u5834\\u689d\\u4ef6\\uff0c\\u5169\\u8005\\u9700\\u8981\\u5206\\u958b\\u7406\\u89e3\\u3002"},{"observation":"\\u6210\\u4ea4\\u53c3\\u8207\\u53ea\\u5728\\u90e8\\u5206\\u9818\\u5c0e\\u80a1\\u51fa\\u73fe\\u64f4\\u5f35\\u3002","meaning":"\\u82e5\\u6210\\u4ea4\\u53c3\\u8207\\u672a\\u80fd\\u64f4\\u6563\\u81f3\\u66f4\\u591a\\u7522\\u696d\\u7fa4\\u7d44\\uff0c\\u73fe\\u6709\\u9818\\u5c0e\\u7d50\\u69cb\\u4ecd\\u9808\\u63a5\\u53d7\\u53cd\\u8b49\\u3002"}]}'
$leaders = Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[{"rank":"#1","symbol":"PENG","companyName":"Penguin Solutions, Inc.","coreBusiness":"AI infrastructure","mainDriver":"Relative strength","compositeScore":104.82}]}'
$topGainersTitle=Get-AplCanonicalTopGainersTitle
$gainers = [pscustomobject]@{SchemaVersion='APL Table Card Input v1.1';CardType='TopGainers';Title=$topGainersTitle;Rows=@([pscustomobject]@{symbol='PYPL';companyName='PayPal Holdings, Inc.';sectorTheme='Commercial services';changePct='+17.20%'})}
$sectors = Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"SectorStructure","Title":"Structure","Rows":[{"theme":"Bio","count":11,"direction":"\u91ab\u7642\u751f\u6280\u8cc7\u91d1\u7dad\u6301\u9078\u64c7\u6027\u9818\u5c0e","representativeSymbols":"CORT, LQDA, ABSI"}]}'

Invoke-Case 'ExecutiveSummary semantic PASS' $true { $r=Assert-AplTableCardContract $executive 'ExecutiveSummary'; if($r.Columns-ne2){throw 'Column count mismatch'} }
Invoke-Case 'ExecutiveSummary Chinese reader-facing PASS' $true { $r=Assert-AplTableCardContract $executive 'ExecutiveSummary' -RequireChineseExecutiveSummary; if($r.Columns-ne2){throw 'Column count mismatch'} }
Invoke-Case 'English-only ExecutiveSummary FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"ExecutiveSummary","Title":"Executive","Rows":[{"observation":"Universe 604; qualified 314","meaning":"Selective leadership"},{"observation":"Leader Lock 21","meaning":"Participation requires confirmation"},{"observation":"Buyability 7.57","meaning":"Entry remains difficult"}]}') 'ExecutiveSummary' -RequireChineseExecutiveSummary }
Invoke-Case 'Raw metric label dump FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"ExecutiveSummary","Title":"Executive","Rows":[{"observation":"Universe 604; qualified 314; Top 30 30 市場集中","meaning":"資金配置仍然選擇性較高"},{"observation":"領導股結構","meaning":"需要成交確認"},{"observation":"風險變數","meaning":"需要持續檢驗"}]}') 'ExecutiveSummary' -RequireChineseExecutiveSummary }
Invoke-Case 'ExecutiveSummary two rows FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"ExecutiveSummary","Title":"Executive","Rows":[{"observation":"One","meaning":"First"},{"observation":"Two","meaning":"Second"}]}') 'ExecutiveSummary' }
Invoke-Case 'ExecutiveSummary six rows FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"ExecutiveSummary","Title":"Executive","Rows":[{"observation":"One","meaning":"First"},{"observation":"Two","meaning":"Second"},{"observation":"Three","meaning":"Third"},{"observation":"Four","meaning":"Fourth"},{"observation":"Five","meaning":"Fifth"},{"observation":"Six","meaning":"Sixth"}]}') 'ExecutiveSummary' }
Invoke-Case 'TopLeaders six-field mapping PASS' $true { $r=Assert-AplTableCardContract $leaders 'TopLeaders'; if($r.Columns-ne6){throw 'Column count mismatch'} }
Invoke-Case 'TopGainers four-field mapping PASS' $true { $r=Assert-AplTableCardContract $gainers 'TopGainers'; if($r.Columns-ne4){throw 'Column count mismatch'} }
Invoke-Case 'SectorStructure keyed mapping PASS' $true { $r=Assert-AplTableCardContract $sectors 'SectorStructure'; if($r.Columns-ne3){throw 'Column count mismatch'} }

Invoke-Case 'Legacy positional row FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[["#1","PENG","Company","Driver",104.82]]}') 'TopLeaders' }
Invoke-Case 'Missing mainDriver FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[{"rank":"#1","symbol":"PENG","companyName":"Company","coreBusiness":"AI","compositeScore":104.82}]}') 'TopLeaders' }
Invoke-Case 'Whitespace required field FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[{"rank":"#1","symbol":"PENG","companyName":"Company","coreBusiness":"   ","mainDriver":"Driver","compositeScore":104.82}]}') 'TopLeaders' }
Invoke-Case 'Score in coreBusiness FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[{"rank":"#1","symbol":"PENG","companyName":"Company","coreBusiness":104.82,"mainDriver":"Driver","compositeScore":104.82}]}') 'TopLeaders' }
Invoke-Case 'Percentage in sectorTheme FAIL' $false { Assert-AplTableCardContract ([pscustomobject]@{SchemaVersion='APL Table Card Input v1.1';CardType='TopGainers';Title=$topGainersTitle;Rows=@([pscustomobject]@{symbol='PYPL';companyName='PayPal';sectorTheme='+17.20%';changePct='+17.20%'})}) 'TopGainers' }
Invoke-Case 'Missing changePct FAIL' $false { Assert-AplTableCardContract ([pscustomobject]@{SchemaVersion='APL Table Card Input v1.1';CardType='TopGainers';Title=$topGainersTitle;Rows=@([pscustomobject]@{symbol='PYPL';companyName='PayPal';sectorTheme='Finance'})}) 'TopGainers' }
Invoke-Case 'Symbols in direction FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"SectorStructure","Title":"Structure","Rows":[{"theme":"Bio","count":11,"direction":"CORT, LQDA, ABSI","representativeSymbols":"CORT, LQDA, ABSI"}]}') 'SectorStructure' }
Invoke-Case 'English-only direction FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"SectorStructure","Title":"Structure","Rows":[{"theme":"Bio","count":11,"direction":"Selective biotech leadership","representativeSymbols":"CORT, LQDA, ABSI"}]}') 'SectorStructure' -RequireChineseDirection }
Invoke-Case 'Empty representativeSymbols FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"SectorStructure","Title":"Structure","Rows":[{"theme":"Bio","count":11,"direction":"Selective leadership","representativeSymbols":" "}]}') 'SectorStructure' }
Invoke-Case 'Custom Columns FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"ExecutiveSummary","Title":"Executive","Columns":[],"Rows":[{"observation":"Breadth","meaning":"Selective"},{"observation":"Rotation","meaning":"Narrow"},{"observation":"Risk","meaning":"Present"}]}') 'ExecutiveSummary' }

Write-Host "RESULT Passed=$passed Failed=$failed"
if ($failed -gt 0) { exit 1 }
