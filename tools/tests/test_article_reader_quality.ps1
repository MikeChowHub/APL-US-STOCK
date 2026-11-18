[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $root 'tools\article_reader_quality.ps1')
$script:passed=0;$script:failed=0
function Expect-Pass([string]$Name,[scriptblock]$Action){
  try{& $Action|Out-Null;$script:passed++;Write-Host "PASS $Name"}
  catch{$script:failed++;Write-Host "FAIL $Name : $($_.Exception.Message)"}
}
function Expect-Fail([string]$Name,[scriptblock]$Action,[string]$Pattern){
  try{& $Action|Out-Null;$script:failed++;Write-Host "FAIL $Name : expected rejection"}
  catch{if($_.Exception.Message-match$Pattern){$script:passed++;Write-Host "PASS $Name"}else{$script:failed++;Write-Host "FAIL $Name : $($_.Exception.Message)"}}
}
$symbols=@(1..30|ForEach-Object{'T'+$_.ToString('00')})
$companyCases=@(
  '雲端內容管理|企業協作席位和文件治理合約|客戶縮減軟件席位及免費工具競爭',
  '非阿片類鎮痛藥物|外科醫生採用與醫院藥品採購|支付覆蓋收緊和替代療法競爭',
  '數碼產品分析平台|應用事件分析量與訂閱續約|企業產品開發預算削減',
  '食品折扣零售|門店客流與同店交易數量|採購成本上升及庫存報廢',
  '航空發動機維修|在役機隊使用時數和維修合約|零件供應不足及工場產能限制',
  '銀行企業信貸|企業貸款餘額及存貸息差|信貸損失上升和存款成本增加',
  '光學通訊元件|數據中心高速模組交付|客戶集中及產品良率不穩',
  '半導體封裝測試|先進封裝產能使用與測試訂單|產能投資過剩及客戶技術轉移',
  '汽車零件供應|車廠排產和單車電子零件配置|整車需求減少與召回成本',
  '工業氣體供應|長約供氣量和新工場投產|電力價格波動及客戶停工',
  '抗體藥物研發|合作研究里程碑和技術授權|臨床試驗失敗及資金消耗',
  '醫療影像設備|醫院設備更新與維護服務|資本預算延後和認證進度',
  '信用卡支付網絡|跨境交易金額和支付處理量|支付監管調整及替代網絡競爭',
  '專業顧問服務|企業稅務專案與顧問計費時數|專業人員成本增加及合規責任',
  '寬頻通訊服務|住宅用戶接駁和企業線路合約|用戶流失及網絡升級支出',
  '電子商務物流|包裹處理量和倉儲服務合約|燃油成本上升及旺季人力短缺',
  '腫瘤藥物開發|已上市藥品處方及新適應症拓展|專利到期和臨床安全性問題',
  '美容個人護理產品|零售渠道鋪貨及消費者回購|促銷費用增加和品牌替代',
  '建築材料製造|工程開工與承建商補庫存|房地產活動下降和能源成本',
  '供應鏈管理軟件|零售商倉庫部署與平台續約|實施延期和專案毛利下降',
  '人力資源及薪酬軟件|企業僱員覆蓋數與客戶留存|就業收縮和資料外洩責任',
  '火箭及衛星系統|發射任務排期與航天零件訂單|發射失敗及客戶取消任務',
  '電力公用事業|監管資產投資和電網使用量|回報率核准延遲及極端天氣',
  '可再生能源設備|電站工程交付與設備維護|項目融資成本和政策變化',
  '銅礦採掘|礦石品位與金屬銷售價格|營運中斷及開採許可限制',
  '生物科研儀器|實驗室設備採購和耗材使用|研究資金縮減及客戶去庫存',
  '保險經紀|客戶保費規模和續保服務|佣金壓力及專業疏失索償',
  '酒店營運管理|入住率和每間可售客房收入|旅遊需求下降及工資成本',
  '企業身份安全|身份授權數和安全平台續約|競爭產品整合及信任受損',
  '遊戲內容開發|新遊戲發售及玩家持續消費|作品延期和開發成本超支'
)
function New-CompanyFixture([string]$ExtraSentence=''){
  $sections=for($i=0;$i-lt$symbols.Count;$i++){
    $symbol=$symbols[$i];$details=$companyCases[$i]-split'\|'
    $extra=$ExtraSentence.Replace('{symbol}',$symbol)
    "### $symbol｜公司`r`n`r`n$symbol 提供$($details[0])，主要收入與$($details[1])相關；產品交付、使用深度及合約安排影響服務收入。$symbol 面對$($details[2])，經營分析需結合客戶使用情況和產品競爭位置。$extra"
  }
  return "# 公司分析`r`n`r`n"+($sections-join"`r`n`r`n")
}
$company=New-CompanyFixture
$article="## SEO and Sharing`r`n`r`nPage title：測試標題 | 2026-11-12`r`n`r`n# 測試標題 | 2026-11-12`r`n`r`n## Investment Implication｜投資啟示`r`n`r`nPCRX 的藥物銷售與 ZETA 的營銷平台提供兩種業務方向，前者取決於臨床採用，後者則連結企業客戶的營銷預算。`r`n`r`n本期選擇以既有藥品組合及平台客戶需求為研究重點。醫院採購和企業營銷開支的驅動不同，配置判斷亦應分別解讀。"
Expect-Pass 'historical-policy-disabled' {if((Get-AplReaderQualityPolicy '2026-11-11').Enabled){throw 'Historical policy unexpectedly enabled.'}}
Expect-Pass 'new-policy-concise-paragraphs' {$p=Get-AplReaderQualityPolicy '2026-11-12';if(-not$p.Enabled-or$p.InvestmentMinChars-ne180-or$p.InvestmentMinParagraphs-ne2){throw 'Wrong policy.'}}
Expect-Pass 'concise-two-paragraph-article-and-normal-company-sections' {$r=Assert-AplArticleReaderQuality $article $company $symbols;if($r.CompanySections-ne30-or$r.ArticleParagraphs-ne2){throw 'Wrong paragraph or company count.'};$r|ConvertTo-Json -Depth 6|ConvertFrom-Json|Out-Null}
Expect-Pass 'actual-numbered-h2-company-heading-supported' {$numbered=$company-replace'### T01｜','## 01. T01｜';Assert-AplArticleReaderQuality $article $numbered $symbols}
Expect-Pass 'bold-ticker-company-heading-supported' {$bold=$company-replace'### T01｜','## 01. **T01**｜';Assert-AplArticleReaderQuality $article $bold $symbols}
$long='企業營銷平台透過數據分析幫助客戶調整廣告投放，收入來源包括平台使用和服務合約，客戶續約及預算分配會影響收入增長。產品的使用深度、服務成本和交付安排共同決定盈利，因此研究必須結合具體業務理解公司差異。'
Expect-Fail 'duplicate-long-paragraph' {Assert-AplArticleReaderQuality ($article+"`r`n`r`n$long`r`n`r`n$long") $company $symbols} 'repeated long paragraph.*paragraph'
Expect-Fail 'duplicate-paragraph-different-punctuation' {Assert-AplArticleReaderQuality ($article+"`r`n`r`n$long`r`n`r`n"+($long-replace'，','；')) $company $symbols} 'repeated long paragraph'
$sentence='企業營銷平台透過數據分析幫助客戶調整廣告投放，收入來源包括平台使用和服務合約，客戶續約及預算分配會影響收入增長。'
Expect-Fail 'same-long-sentence-three-times-in-one-paragraph' {Assert-AplArticleReaderQuality ($article+"`r`n`r`n"+($sentence*3)) $company $symbols} 'same long sentence three times'
Expect-Fail 'same-long-sentence-three-sections' {Assert-AplArticleReaderQuality ($article+"`r`n`r`n## A`r`n`r`n$sentence`r`n`r`n## B`r`n`r`n$sentence`r`n`r`n## C`r`n`r`n$sentence") $company $symbols} 'same long sentence three times'
Expect-Pass 'short-fact-summary-detail-repetition-allowed' {Assert-AplArticleReaderQuality ($article+"`r`n`r`n## 摘要`r`n`r`n收入按年增長30%。`r`n`r`n## 公司分析`r`n`r`n收入按年增長30%。`r`n`r`n## 啟示`r`n`r`n收入按年增長30%。") $company $symbols}
Expect-Pass 'seo-is-excluded-from-prose-duplication' {Assert-AplArticleReaderQuality ("## SEO and Sharing`r`n`r`n$long`r`n`r`n$long`r`n`r`n"+($article.Substring($article.IndexOf('# 測試')))) $company $symbols}
Expect-Fail 'copied-company-risk-filler' {Assert-AplArticleReaderQuality $article (New-CompanyFixture '其業務受到客戶需求、競爭和成本安排影響。') $symbols} 'copied company-analysis sentence'
Expect-Fail 'copied-company-filler-with-different-tickers' {Assert-AplArticleReaderQuality $article (New-CompanyFixture '{symbol} 的業務受到客戶需求、競爭和成本安排影響。') $symbols} 'copied company-analysis sentence'
Expect-Pass 'ticker-substring-in-product-code-is-preserved' {Assert-AplArticleReaderQuality $article (New-CompanyFixture '{symbol}X 型號設備採用不同規格，專用零件供應和維護安排影響交付周期。') $symbols}
Expect-Pass 'short-company-label-repetition-allowed' {Assert-AplArticleReaderQuality $article (New-CompanyFixture '主要風險。') $symbols}
Expect-Fail 'thin-independent-company-section' {Assert-AplArticleReaderQuality $article ($company-replace'(?s)(### T01｜公司\s+).*?(?=### T02)',('$1業務分析。'+"`r`n`r`n")) $symbols} 'thin company section.*T01'
Expect-Fail 'missing-company-section' {Assert-AplArticleReaderQuality $article ($company-replace'(?s)### T30｜公司.*$','') $symbols} 'independent company section for T30'
Expect-Fail 'duplicate-company-section' {Assert-AplArticleReaderQuality $article ($company+"`r`n`r`n### T01｜重複公司`r`n`r`n重複內容。") $symbols} 'duplicate company sections for T01'
Expect-Fail 'internal-others-excuse' {Assert-AplArticleReaderQuality ($article+"`r`n`r`n由於現有標準分類沒有相應類別而列入 Others。") $company $symbols} 'internal classification limitation'
Expect-Pass 'ordinary-industry-description' {Assert-AplArticleReaderQuality ($article+"`r`n`r`n公司按主要業務分類為醫療服務，產品供應與軟件服務具有不同收入模式。") $company $symbols}
Expect-Pass 'long-paragraph-warning-not-hard-failure' {$longUnique=('需求分析甲'*25)+('企業服務乙'*25);$r=Assert-AplArticleReaderQuality ($article+"`r`n`r`n$longUnique") $company $symbols;if(@($r.Warnings).Count-ne1){throw 'Expected one reading warning.'}}
Write-Host "Article reader quality: $script:passed PASS, $script:failed FAIL"
if($script:failed-gt0){exit 1}
