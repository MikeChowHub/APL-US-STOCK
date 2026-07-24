[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$results=New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Name,[bool]$Passed,[string]$Detail=''){
  [void]$results.Add([pscustomobject]@{Name=$Name;Status=if($Passed){'PASS'}else{'FAIL'};Passed=$Passed;Detail=$Detail})
  if($Passed){Write-Host "PASS $Name"}else{Write-Host "FAIL $Name :: $Detail" -ForegroundColor Red}
}

function Read-RepoText([string]$RelativePath){
  return [IO.File]::ReadAllText((Join-Path $ProjectRoot $RelativePath),[Text.Encoding]::UTF8)
}

function Get-FunctionDefinition([string]$RelativePath,[string]$Name){
  $tokens=$null;$errors=$null
  $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $ProjectRoot $RelativePath),[ref]$tokens,[ref]$errors)
  if($errors.Count){throw "Cannot parse $RelativePath"}
  $definition=@($ast.FindAll({param($node)$node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq$Name},$true))
  if($definition.Count-ne1){throw "Expected one function '$Name' in $RelativePath."}
  return $definition[0].Extent.Text
}

try{
  $readme=Read-RepoText 'KnowledgeBase\README.md'
  Add-Result 'native-contract-production-authority' ($readme-cnotmatch'DESIGN_ONLY_NOT_PRODUCTION')

  $blogRules=Read-RepoText 'KnowledgeBase\Rules\APL_US_Stock_Blog_Rules.md'
  $thesisLabel=-join(@(0x672C,0x671F,0x6838,0x5FC3,0x5E02,0x5834,0x547D,0x984C,0x662F,0xFF1A)|ForEach-Object{[char]$_})
  Add-Result 'core-thesis-source-contract-documented' ($blogRules.Contains($thesisLabel)-and$blogRules.Contains('managed source metadata'))

  $runbook=Read-RepoText 'docs\PRODUCTION_RUNBOOK.md'
  Add-Result 'published-lock-runbook-aligned' ($runbook.Contains('LockPublishedArtifacts')-and$runbook-cnotmatch'LockPublishedMachineArtifacts')

  $archivePolicy=Read-RepoText 'docs\ARCHIVE_INDEX_POLICY.md'
  Add-Result 'unrelated-pending-policy-documented' ($archivePolicy.Contains('PENDING_INDEX')-and$archivePolicy.Contains('different date'))

  $triggerB=Read-RepoText 'tools\process_apl_momentum_leaders.ps1'
  Add-Result 'standalone-trigger-b-namespace' ($triggerB.Contains('outputs\trigger-b')-and$triggerB.Contains('orchestrator staging child'))

  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'ConvertTo-AplPlainText')
  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'Get-AplCoreMarketThesis')
  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'Assert-AplCoreMarketThesisAlignment')
  $thesis='Energy risk raises the inflation threshold while AI capital spending must convert into earnings and cash flow.'
  try{$actual=Get-AplCoreMarketThesis "$thesisLabel$thesis`r`n`r`n## Evidence" 'fixture';Add-Result 'single-core-thesis-pass' ($actual-ceq$thesis)}catch{Add-Result 'single-core-thesis-pass' $false $_.Exception.Message}
  try{Get-AplCoreMarketThesis '## Evidence only' 'fixture'|Out-Null;Add-Result 'missing-core-thesis-fail' $false 'not rejected'}catch{Add-Result 'missing-core-thesis-fail' $true}
  try{Get-AplCoreMarketThesis "$thesisLabel$thesis`r`n$thesisLabel$thesis" 'fixture'|Out-Null;Add-Result 'duplicate-core-thesis-fail' $false 'not rejected'}catch{Add-Result 'duplicate-core-thesis-fail' $true}
  try{$aligned=Assert-AplCoreMarketThesisAlignment $thesis "  $thesis  ";Add-Result 'cross-platform-thesis-match-pass' ($aligned-ceq$thesis)}catch{Add-Result 'cross-platform-thesis-match-pass' $false $_.Exception.Message}
  try{Assert-AplCoreMarketThesisAlignment $thesis 'A different Cover Brief proposition that does not match the managed source.'|Out-Null;Add-Result 'cross-platform-thesis-mismatch-fail' $false 'not rejected'}catch{Add-Result 'cross-platform-thesis-mismatch-fail' $true}

  $runner=Read-RepoText 'tools\run_daily_production.ps1'
  Add-Result 'runner-package-lock-integration' ($runner.Contains('Set-AplPublishedPackageReadOnly $finalDateOut')-and$runner.Contains('Set-AplPublishedFilesReadOnly @($finalAuditPath) $finalDateOut'))

  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'Assert-AplCompanyAnalysisTopSymbols')
  $ranking=@(1..30|ForEach-Object{[pscustomobject]@{Symbol=("T{0:D2}"-f$_)}})
  $company=(@($ranking|ForEach-Object{"## $($_.Symbol)`r`nBusiness model analysis."})-join"`r`n")
  try{Assert-AplCompanyAnalysisTopSymbols $ranking $company 30|Out-Null;Add-Result 'company-top30-pass' $true}catch{Add-Result 'company-top30-pass' $false $_.Exception.Message}
  try{Assert-AplCompanyAnalysisTopSymbols $ranking ($company-replace'(?m)^## T30\r?\nBusiness model analysis\.\r?\n?','') 30|Out-Null;Add-Result 'company-missing-rank30-fail' $false 'not rejected'}catch{Add-Result 'company-missing-rank30-fail' $true}
  try{Assert-AplCompanyAnalysisTopSymbols @($ranking|Select-Object -First 29) $company 30|Out-Null;Add-Result 'ranking-below30-fail' $false 'not rejected'}catch{Add-Result 'ranking-below30-fail' $true}
}finally{
  $failed=@($results|Where-Object{-not$_.Passed})
  [pscustomobject]@{Passed=($failed.Count-eq0);Total=$results.Count;Failed=$failed.Count;Results=[object[]]$results.ToArray()}|ConvertTo-Json -Depth 5
}
if(@($results|Where-Object{-not$_.Passed}).Count-gt0){exit 1}
