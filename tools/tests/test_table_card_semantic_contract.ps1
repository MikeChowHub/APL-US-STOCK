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

function Convert-Fixture([string]$Json) { return ($Json | ConvertFrom-Json) }

$executive = Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"ExecutiveSummary","Title":"Executive","Rows":[{"observation":"Breadth","meaning":"Leadership is selective"}]}'
$leaders = Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[{"rank":"#1","symbol":"PENG","companyName":"Penguin Solutions, Inc.","coreBusiness":"AI infrastructure","mainDriver":"Relative strength","compositeScore":104.82}]}'
$gainers = Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopGainers","Title":"\u6700\u8fd17\u65e5 Top Gainers","Rows":[{"symbol":"PYPL","companyName":"PayPal Holdings, Inc.","sectorTheme":"Commercial services","changePct":"+17.20%"}]}'
$sectors = Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"SectorStructure","Title":"Structure","Rows":[{"theme":"Bio","count":11,"direction":"Selective biotech leadership","representativeSymbols":"CORT, LQDA, ABSI"}]}'

Invoke-Case 'ExecutiveSummary semantic PASS' $true { $r=Assert-AplTableCardContract $executive 'ExecutiveSummary'; if($r.Columns-ne2){throw 'Column count mismatch'} }
Invoke-Case 'TopLeaders six-field mapping PASS' $true { $r=Assert-AplTableCardContract $leaders 'TopLeaders'; if($r.Columns-ne6){throw 'Column count mismatch'} }
Invoke-Case 'TopGainers four-field mapping PASS' $true { $r=Assert-AplTableCardContract $gainers 'TopGainers'; if($r.Columns-ne4){throw 'Column count mismatch'} }
Invoke-Case 'SectorStructure keyed mapping PASS' $true { $r=Assert-AplTableCardContract $sectors 'SectorStructure'; if($r.Columns-ne3){throw 'Column count mismatch'} }

Invoke-Case 'Legacy positional row FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[["#1","PENG","Company","Driver",104.82]]}') 'TopLeaders' }
Invoke-Case 'Missing mainDriver FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[{"rank":"#1","symbol":"PENG","companyName":"Company","coreBusiness":"AI","compositeScore":104.82}]}') 'TopLeaders' }
Invoke-Case 'Whitespace required field FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[{"rank":"#1","symbol":"PENG","companyName":"Company","coreBusiness":"   ","mainDriver":"Driver","compositeScore":104.82}]}') 'TopLeaders' }
Invoke-Case 'Score in coreBusiness FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopLeaders","Title":"Leaders","Rows":[{"rank":"#1","symbol":"PENG","companyName":"Company","coreBusiness":104.82,"mainDriver":"Driver","compositeScore":104.82}]}') 'TopLeaders' }
Invoke-Case 'Percentage in sectorTheme FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopGainers","Title":"\u6700\u8fd17\u65e5 Top Gainers","Rows":[{"symbol":"PYPL","companyName":"PayPal","sectorTheme":"+17.20%","changePct":"+17.20%"}]}') 'TopGainers' }
Invoke-Case 'Missing changePct FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"TopGainers","Title":"\u6700\u8fd17\u65e5 Top Gainers","Rows":[{"symbol":"PYPL","companyName":"PayPal","sectorTheme":"Finance"}]}') 'TopGainers' }
Invoke-Case 'Symbols in direction FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"SectorStructure","Title":"Structure","Rows":[{"theme":"Bio","count":11,"direction":"CORT, LQDA, ABSI","representativeSymbols":"CORT, LQDA, ABSI"}]}') 'SectorStructure' }
Invoke-Case 'Empty representativeSymbols FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"SectorStructure","Title":"Structure","Rows":[{"theme":"Bio","count":11,"direction":"Selective leadership","representativeSymbols":" "}]}') 'SectorStructure' }
Invoke-Case 'Custom Columns FAIL' $false { Assert-AplTableCardContract (Convert-Fixture '{"SchemaVersion":"APL Table Card Input v1.1","CardType":"ExecutiveSummary","Title":"Executive","Columns":[],"Rows":[{"observation":"Breadth","meaning":"Selective"}]}') 'ExecutiveSummary' }

Write-Host "RESULT Passed=$passed Failed=$failed"
if ($failed -gt 0) { exit 1 }
