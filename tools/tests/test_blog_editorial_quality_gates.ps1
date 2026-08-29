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

function Expect-Pass([string]$Name,[scriptblock]$Action){
  try{& $Action|Out-Null;Add-Result $Name $true}
  catch{Add-Result $Name $false $_.Exception.Message}
}

function Expect-Fail([string]$Name,[scriptblock]$Action,[string]$Pattern){
  try{& $Action|Out-Null;Add-Result $Name $false 'Expected fail-closed rejection.'}
  catch{Add-Result $Name ($_.Exception.Message-match$Pattern) $_.Exception.Message}
}

$map=Get-AplBlogHeadingMap -ScanDate '2026-08-10'
Add-Result 'exact-conclusion-heading' ([string]$map.DeepScanConclusion -ceq 'Deep-Scan Conclusion｜深度掃描結論') ([string]$map.DeepScanConclusion)
Add-Result 'cta-heading' ([string]$map.CallToAction -ceq 'Call to Action｜延伸閱讀') ([string]$map.CallToAction)
Add-Result 'disclaimer-heading' ([string]$map.Disclaimer -ceq 'Disclaimer｜免責聲明') ([string]$map.Disclaimer)
$futureMap=Get-AplBlogHeadingMap -ScanDate '2026-08-30'
Add-Result 'exact-investment-implication-heading' ([string]$futureMap.InvestmentImplication -ceq 'Investment Implication｜投資啟示') ([string]$futureMap.InvestmentImplication)

Expect-Pass 'natural-reader-language-pass' {Assert-AplClientFacingEditorialLanguage -Text '本期掃描679檔公司，361檔符合條件；強勢群組有22檔，平均動能82.77。' -Label 'Overview'}
Expect-Fail 'raw-universe-label-fail' {Assert-AplClientFacingEditorialLanguage -Text 'universe 679、qualified 361。' -Label 'Overview'} 'internal Production terminology'
Expect-Fail 'trigger-b-label-fail' {Assert-AplClientFacingEditorialLanguage -Text '受管 Trigger B 顯示領導仍在。' -Label 'Overview'} 'internal Production terminology'

Expect-Pass 'balanced-top-gainers-pass' {Assert-AplEditorialBalancedPunctuation -Text 'ABNB（Airbnb）及PLTR（Palantir）反映短線風險偏好。' -Label 'Top Gainers'}
Expect-Fail 'unbalanced-top-gainers-fail' {Assert-AplEditorialBalancedPunctuation -Text 'ABNB（Airbnb；PLTR（Palantir。' -Label 'Top Gainers'} 'unbalanced parentheses'

$naturalMarket="能源成本重新上升，因此市場開始提高對盈利與現金流的要求。這代表估值門檻已經改變。`r`n`r`n指數仍然上升，但個股表現分化，反映資金正在選擇具實際需求的公司。"
Expect-Pass 'market-two-paragraph-causal-pass' {Assert-AplEditorialParagraphQuality -Section $naturalMarket -Label 'Market Context' -MinimumParagraphs 2 -MaximumSemicolonsPerParagraph 3;Assert-AplEditorialCausalLanguage -Text $naturalMarket -Label 'Market Context' -MinimumSignals 2}
Expect-Fail 'market-one-paragraph-fail' {Assert-AplEditorialParagraphQuality -Section '能源、利率、科技與就業消息全部集中在同一長段落，因此難以閱讀。' -Label 'Market Context' -MinimumParagraphs 2 -MaximumSemicolonsPerParagraph 3} 'at least 2 natural prose paragraphs'
$weeklyExecutive="本期最大變化是企業重新提高盈利門檻，因此市場結論由追逐敘事轉向驗證商業回報，這項改變對估值非常重要。`r`n`r`n資金流向盈利能見度較高的領導公司，並由高估值概念輪動至具現金流證據的企業，這代表配置標準正在收緊。`r`n`r`n下一步應觀察成交與盈利指引能否確認這種領導結構；若資金重新集中於少數公司，便要下修判斷。"
Expect-Pass 'weekly-executive-three-layer-pass' {Assert-AplEditorialParagraphQuality -Section $weeklyExecutive -Label 'Executive Summary' -MinimumParagraphs 3;Assert-AplEditorialCausalLanguage -Text $weeklyExecutive -Label 'Executive Summary' -MinimumSignals 2;Assert-AplWeeklyOpeningLayers -Text $weeklyExecutive -Label 'Executive Summary'}
Expect-Fail 'weekly-executive-missing-watchpoint-fail' {Assert-AplWeeklyOpeningLayers -Text '這項改變非常重要，因為資金流向盈利較清晰的領導公司。' -Label 'Executive Summary'} 'next-watchpoint'

$weeklyMarket="能源與利率訊號改變市場折現假設，因此企業盈利的質量變得更重要，單看指數已不足以描述風險。`r`n`r`n估值門檻提高令資金配置轉向現金流與需求較清晰的公司，這代表領導結構會比大市升跌更早反映市場選擇。`r`n`r`n後續要觀察盈利指引、成交廣度與債息能否確認這條資金流向，所以需要再以APL領導股證據檢驗。"
Expect-Pass 'weekly-market-three-layer-pass' {Assert-AplEditorialParagraphQuality -Section $weeklyMarket -Label 'Market Context' -MinimumParagraphs 3;Assert-AplEditorialCausalLanguage -Text $weeklyMarket -Label 'Market Context' -MinimumSignals 3;Assert-AplWeeklyOpeningLayers -Text $weeklyMarket -Label 'Market Context'}
Expect-Fail 'weekly-market-two-paragraph-fail' {Assert-AplEditorialParagraphQuality -Section "事件改變估值，因此市場重新定價。`r`n`r`n資金轉向盈利公司，下一步觀察指引。" -Label 'Market Context' -MinimumParagraphs 3} 'at least 3 natural prose paragraphs'

$naturalLeaders="短線升幅未完全進入中期排名，因此資金仍然保持選擇性。`r`n`r`n中期領導集中於盈利路徑清晰的公司，反映市場正在驗證商業模式。"
Expect-Pass 'momentum-natural-paragraphs-pass' {Assert-AplEditorialParagraphQuality -Section $naturalLeaders -Label 'Momentum Leaders' -MinimumParagraphs 2 -MaximumSemicolonsPerParagraph 3}
Expect-Fail 'semicolon-pseudo-table-fail' {Assert-AplEditorialParagraphQuality -Section "DFTX；TXG；APGE；PANW；DELL；這是一段資料列。`r`n`r`n第二段只為通過段數。" -Label 'Momentum Leaders' -MinimumParagraphs 2 -MaximumSemicolonsPerParagraph 3} 'semicolon list'

$investmentImplication="對投資者而言，市場已由追逐主題轉向驗證經濟利益，因此選股標準需要檢查商業兌現。`r`n`r`n資本開支仍支持數碼基建，但企業必須把需求轉化為收入、盈利與現金流，才能維持領導地位。`r`n`r`n若資金由少數公司向企業服務及安全支出擴散，市場廣度便會確認新的資金流向。`r`n`r`nAPL Momentum Leaders 透過跨板塊動量觀察相對強度與基本面催化是否同步，這代表分析不預設單一產業必然領先。`r`n`r`n利率與能源成本仍可能壓縮估值，因此後續要觀察現金流、群組廣度與領導結構是否持續。"
Expect-Pass 'investment-implication-five-layer-pass' {Assert-AplEditorialParagraphQuality -Section $investmentImplication -Label 'Investment Implication' -MinimumParagraphs 5;Assert-AplEditorialCausalLanguage -Text $investmentImplication -Label 'Investment Implication' -MinimumSignals 4;Assert-AplInvestmentImplicationLayers -Text $investmentImplication -Label 'Investment Implication'}
Expect-Fail 'investment-implication-missing-apl-link-fail' {Assert-AplInvestmentImplicationLayers -Text '對投資者而言，資金正在擴散，企業需要把需求轉化為盈利與現金流，後續仍要觀察風險訊號。' -Label 'Investment Implication'} 'apl-momentum-leaders-link'
Expect-Fail 'investment-implication-direct-trade-instruction-fail' {Assert-AplInvestmentImplicationLayers -Text '投資者應理解資金領導與擴散。APL Momentum Leaders 顯示企業收入及現金流改善，後續風險訊號確認後買入。' -Label 'Investment Implication'} 'direct trading instruction'
$longRisk="新平台若延誤，需求便不能按預期轉化為供應鏈收入，因此核心命題會受到挑戰。`r`n`r`n成本及利率上升會壓縮盈利與估值，並令高估值領導股先失去承接。`r`n`r`n若硬件升幅消失及群組廣度收縮，就代表需求訊號未形成持久結構。"
Expect-Pass 'long-risk-three-paragraphs-pass' {Assert-AplEditorialParagraphQuality -Section $longRisk -Label 'Blog Risk' -MinimumParagraphs 3 -MaximumSemicolonsPerParagraph 3;Assert-AplEditorialCausalLanguage -Text $longRisk -Label 'Blog Risk' -MinimumSignals 2}
Expect-Fail 'short-risk-two-paragraphs-fail' {Assert-AplEditorialParagraphQuality -Section "平台延誤會影響收入。`r`n`r`n利率上升會壓縮估值。" -Label 'Blog Risk' -MinimumParagraphs 3 -MaximumSemicolonsPerParagraph 3} 'at least 3 natural prose paragraphs'

$longConclusion="本期證據回答了開頭問題：需求仍在，但市場已轉向檢驗商業兌現。`r`n`r`n領導結構同時涵蓋硬件、服務與醫療，然而資金擴散仍然保持選擇性。`r`n`r`n若交付與收入同步改善，核心命題會得到確認；若只剩單一硬件交易，便需要下修判斷。"
Expect-Pass 'long-conclusion-three-paragraphs-pass' {Assert-AplEditorialParagraphQuality -Section $longConclusion -Label 'Blog Deep-Scan Conclusion' -MinimumParagraphs 3 -MaximumSemicolonsPerParagraph 3;Assert-AplEditorialCausalLanguage -Text $longConclusion -Label 'Blog Deep-Scan Conclusion' -MinimumSignals 1}
Expect-Fail 'short-conclusion-one-paragraph-fail' {Assert-AplEditorialParagraphQuality -Section '市場仍然選擇性上升，下一步繼續觀察。' -Label 'Blog Deep-Scan Conclusion' -MinimumParagraphs 3 -MaximumSemicolonsPerParagraph 3} 'at least 3 natural prose paragraphs'

$failures=@($results|Where-Object{$_.Status-ne'PASS'})
Write-Host "Blog editorial quality gates: $($results.Count-$failures.Count) PASS, $($failures.Count) FAIL"
if($failures.Count-gt0){$failures|Format-Table -AutoSize|Out-String|Write-Host;exit 1}
exit 0
