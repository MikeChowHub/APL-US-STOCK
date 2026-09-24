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
  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'Assert-AplBlogOverviewPolicy')
  Add-Result 'overview-legacy-required' (Assert-AplBlogOverviewPolicy '2026-09-07' '' '')
  Add-Result 'overview-new-date-omitted-pass' (-not(Assert-AplBlogOverviewPolicy '2026-09-08' '' ''))
  try{Assert-AplBlogOverviewPolicy '2026-09-08' '## Deep-Scan Overview' ''|Out-Null;Add-Result 'overview-new-markdown-fail' $false}catch{Add-Result 'overview-new-markdown-fail' $true}
  try{Assert-AplBlogOverviewPolicy '2026-09-08' '' '<h3>Deep-Scan Overview</h3>'|Out-Null;Add-Result 'overview-new-html-fail' $false}catch{Add-Result 'overview-new-html-fail' $true}
  Add-Result 'internal-research-queue-documented' ($blogRules.Contains('不自動生成')-and$blogRules.Contains('4個不同 ScanDate'))
  $thesisLabel=-join(@(0x672C,0x671F,0x6838,0x5FC3,0x5E02,0x5834,0x547D,0x984C,0x662F,0xFF1A)|ForEach-Object{[char]$_})
  Add-Result 'core-thesis-source-contract-documented' ($blogRules.Contains($thesisLabel)-and$blogRules.Contains('managed source metadata'))

  $runbook=Read-RepoText 'docs\PRODUCTION_RUNBOOK.md'
  Add-Result 'published-lock-runbook-aligned' ($runbook.Contains('LockPublishedArtifacts')-and$runbook-cnotmatch'LockPublishedMachineArtifacts')
  $packageRules=Read-RepoText 'KnowledgeBase\Rules\APL_US_Stock_Production_Package_Rules.md'
  $deliveryOrder='Executive Summary → Deep-Scan Dashboard → Top Gainers → Top Leaders → Sector Structure'
  $publishingOrder='今日文章 Markdown → HTML 原始碼 TXT → 公開預覽 HTML 原始碼 → 會員文章 SQL → WhatsApp → Top 30 公司分析'
  Add-Result 'delivery-table-card-order-documented' ($packageRules.Contains($deliveryOrder)-and$runbook.Contains($deliveryOrder))
  Add-Result 'delivery-publishing-order-documented' ($packageRules.Contains($publishingOrder)-and$runbook.Contains($publishingOrder))

  $archivePolicy=Read-RepoText 'docs\ARCHIVE_INDEX_POLICY.md'
  Add-Result 'unrelated-pending-policy-documented' ($archivePolicy.Contains('PENDING_INDEX')-and$archivePolicy.Contains('different date'))

  $triggerB=Read-RepoText 'tools\process_apl_momentum_leaders.ps1'
  Add-Result 'standalone-trigger-b-namespace' ($triggerB.Contains('outputs\trigger-b')-and$triggerB.Contains('orchestrator staging child'))

  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'ConvertTo-AplPlainText')
  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'Get-AplCoreMarketThesis')
  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'Assert-AplCoreMarketThesisAlignment')
  Invoke-Expression (Get-FunctionDefinition 'tools\validate_managed_inputs.ps1' 'Assert-AplWhatsAppSequence')
  $thesis='Energy risk raises the inflation threshold while AI capital spending must convert into earnings and cash flow.'
  try{$actual=Get-AplCoreMarketThesis "$thesisLabel$thesis`r`n`r`n## Evidence" 'fixture';Add-Result 'single-core-thesis-pass' ($actual-ceq$thesis)}catch{Add-Result 'single-core-thesis-pass' $false $_.Exception.Message}
  try{Get-AplCoreMarketThesis '## Evidence only' 'fixture'|Out-Null;Add-Result 'missing-core-thesis-fail' $false 'not rejected'}catch{Add-Result 'missing-core-thesis-fail' $true}
  try{Get-AplCoreMarketThesis "$thesisLabel$thesis`r`n$thesisLabel$thesis" 'fixture'|Out-Null;Add-Result 'duplicate-core-thesis-fail' $false 'not rejected'}catch{Add-Result 'duplicate-core-thesis-fail' $true}
  try{$aligned=Assert-AplCoreMarketThesisAlignment $thesis "  $thesis  ";Add-Result 'cross-platform-thesis-match-pass' ($aligned-ceq$thesis)}catch{Add-Result 'cross-platform-thesis-match-pass' $false $_.Exception.Message}
  try{Assert-AplCoreMarketThesisAlignment $thesis 'A different Cover Brief proposition that does not match the managed source.'|Out-Null;Add-Result 'cross-platform-thesis-mismatch-fail' $false 'not rejected'}catch{Add-Result 'cross-platform-thesis-mismatch-fail' $true}
  $whatsappPass='**APL Deep-Scan 美股深海雷達**`n**能源風險緩和但 AI 回報進入驗證期 | 2040-01-02**`nhttps://www.goinvestingnow.com/blog/apl-deep-scan-2040-01-02`n`n能源風險緩和，指數反彈，但市場仍然選擇性配置。`n`n📊 **APL Deep-Scan 觀察近期美股領導結構**，領導股仍需盈利與成交確認。`n`n• 投資者應關注能源成本、AI 現金流及領導廣度。`n• 下一步觀察成交參與能否擴散。`n`n🐧 APL Deep-Scan 持續追蹤市場變化。`n`n研究摘要，不構成投資建議。'
  $issueUrl='https://www.goinvestingnow.com/blog/apl-deep-scan-2040-01-02'
  $trialUrl='https://www.goinvestingnow.com/ExploreCourses'
  $whatsappPass += "`n`n今日文章會分析哪些領導股的需求值得繼續驗證。`n`n📖 今日完整研究：`n[$issueUrl]($issueUrl)`n🐧 APL 三日免費體驗｜工具・分析・課程`n[$trialUrl]($trialUrl)"
  try{Assert-AplWhatsAppSequence $whatsappPass '2040-01-02'|Out-Null;Add-Result 'whatsapp-sequence-pass' $true}catch{Add-Result 'whatsapp-sequence-pass' $false $_.Exception.Message}
  try{Assert-AplWhatsAppSequence ($whatsappPass -replace '(?s)📖 今日完整研究：.*$','') '2040-01-02'|Out-Null;Add-Result 'whatsapp-footer-missing-fail' $false 'not rejected'}catch{Add-Result 'whatsapp-footer-missing-fail' $true}
  try{Assert-AplWhatsAppSequence ($whatsappPass.Replace('ExploreCourses','ExploreCourse')) '2040-01-02'|Out-Null;Add-Result 'whatsapp-trial-link-mismatch-fail' $false 'not rejected'}catch{Add-Result 'whatsapp-trial-link-mismatch-fail' $true}
  try{Assert-AplWhatsAppSequence ($whatsappPass + "`nextra") '2040-01-02'|Out-Null;Add-Result 'whatsapp-footer-not-last-fail' $false 'not rejected'}catch{Add-Result 'whatsapp-footer-not-last-fail' $true}
  try{Assert-AplWhatsAppSequence ($whatsappPass-replace'apl-deep-scan-','apl-momentum-leaders-') '2040-01-02'|Out-Null;Add-Result 'future-retired-slug-fail' $false 'not rejected'}catch{Add-Result 'future-retired-slug-fail' $true}
  $historicalWhatsApp=$whatsappPass.Replace('2040-01-02','2026-09-03').Replace('apl-deep-scan-','apl-momentum-leaders-')
  try{Assert-AplWhatsAppSequence $historicalWhatsApp '2026-09-03'|Out-Null;Add-Result 'historical-slug-pass' $true}catch{Add-Result 'historical-slug-pass' $false $_.Exception.Message}
  try{Assert-AplWhatsAppSequence ($whatsappPass-replace'APL Deep-Scan','') '2040-01-02'|Out-Null;Add-Result 'whatsapp-viewpoint-missing-fail' $false 'not rejected'}catch{Add-Result 'whatsapp-viewpoint-missing-fail' $true}
  try{Assert-AplWhatsAppSequence ($whatsappPass-replace'2040-01-02','2040-01-03') '2040-01-02'|Out-Null;Add-Result 'whatsapp-sequence-date-fail' $false 'not rejected'}catch{Add-Result 'whatsapp-sequence-date-fail' $true}

  $runner=Read-RepoText 'tools\run_daily_production.ps1'
  Add-Result 'runner-package-lock-integration' ($runner.Contains('Set-AplPublishedPackageReadOnly $finalDateOut')-and$runner.Contains('Set-AplPublishedFilesReadOnly @($finalAuditPath) $finalDateOut'))
  Add-Result 'runner-delivery-supplement-integration' ($runner.Contains('create_blog_delivery_supplements.ps1')-and$runner.Contains('public-preview-html-source')-and$runner.Contains('member-article-sql'))

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
