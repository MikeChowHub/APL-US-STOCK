[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $ProjectRoot 'tools\renderer_production_common.ps1')
$Script=Join-Path $ProjectRoot 'tools\prepare_trigger_c_managed_inputs.ps1'
$Runner=Join-Path $ProjectRoot 'tools\run_daily_production.ps1'
$ScanDate='2040-02-07'
$SupersedeDate='2040-02-08'
$FixtureRoot=Join-Path $ProjectRoot ("tmp\tc-"+[guid]::NewGuid().ToString('N').Substring(0,8))
$BuilderRoot=Join-Path $ProjectRoot 'tmp\tc-inputs'
$StagingDate=Join-Path $BuilderRoot "staging\$ScanDate"
$ManagedDate=Join-Path $BuilderRoot "managed-inputs\$ScanDate"
$SupersedeStagingDate=Join-Path $BuilderRoot "staging\$SupersedeDate"
$SupersedeManagedDate=Join-Path $BuilderRoot "managed-inputs\$SupersedeDate"
$RejectedStagingRoot=Join-Path $BuilderRoot 'staging\rejected'
$results=New-Object System.Collections.Generic.List[object]
Add-Type -AssemblyName System.Drawing

function Add-Result([string]$Name,[bool]$Passed,[string]$Detail=''){
  [void]$results.Add([pscustomobject]@{Name=$Name;Status=if($Passed){'PASS'}else{'FAIL'};Passed=$Passed;Detail=$Detail})
  if($Passed){Write-Host "PASS $Name"}else{Write-Host "FAIL $Name :: $Detail" -ForegroundColor Red}
}

function Write-Utf8([string]$Path,[string]$Text){
  $parent=Split-Path $Path -Parent
  if(!(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
  [IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($false)))
}

function Write-Json([string]$Path,$Value){
  Write-Utf8 $Path ($Value|ConvertTo-Json -Depth 10)
}

function New-Png([string]$Path,[int]$Width,[int]$Height,[Drawing.Color]$Color){
  $bitmap=New-Object Drawing.Bitmap($Width,$Height)
  $graphics=[Drawing.Graphics]::FromImage($bitmap)
  try{$graphics.Clear($Color);$bitmap.Save($Path,[Drawing.Imaging.ImageFormat]::Png)}
  finally{$graphics.Dispose();$bitmap.Dispose()}
}

try{
  if((Test-Path -LiteralPath $StagingDate)-or(Test-Path -LiteralPath $ManagedDate)){throw "Reserved regression date already exists: $ScanDate"}
  $input=Join-Path $FixtureRoot 'source.csv'
  $gainers=Join-Path $FixtureRoot 'top-gainers.csv'
  $market=Join-Path $FixtureRoot 'market-context.md'
  $header=@(
    'Symbol','Description','Price',
    '"Simple moving average, 20, 1 day"','"Simple moving average, 50, 1 day"','"Simple moving average, 200, 1 day"',
    '"High, 52 weeks"','"Performance %, 3 months"','"Performance %, 6 months"','"Relative volume, 1 day"'
  )-join','
  $rows=@(1..70|ForEach-Object{
    $symbol='T{0:D3}'-f$_
    $price=171-$_
    $sma20=$price-2;$sma50=$price-5;$sma200=$price-10;$high52=$price+8
    $perf3=71-$_;$perf6=101-$_;$relvol=[Math]::Round(3.5-($_/100),2)
    "$symbol,Alpha Research $_,$price,$sma20,$sma50,$sma200,$high52,$perf3,$perf6,$relvol"
  })
  Write-Utf8 $input ((@($header)+$rows)-join[Environment]::NewLine)
  Write-Utf8 $gainers "Symbol,Description,`"Price change %, 1 day`"`r`nT001,Alpha Research 1,12.5`r`nT002,Alpha Research 2,10.25`r`nT003,Alpha Research 3,8"
  $coreThesis='能源成本與利率門檻同步上升，市場領導力因此轉向盈利能見度、自由現金流及資本效率較清晰的公司，而非延續廣泛追價。'
  Write-Utf8 $market "本期核心市場命題是：$coreThesis`r`n`r`n## 能源利率重估`r`n能源成本提高企業資金門檻，市場因此重新檢視估值、現金流與資本配置效率，並尋找盈利路徑較清晰的領導公司。"
  $sourceHashes=@(@($input,$gainers,$market)|ForEach-Object{(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash})

  $initialize=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Initialize -ScanDate $ScanDate -WeekLabel 'Regression' -InputCsv $input -TopGainersCsvPath $gainers -MarketContextPath $market 2>&1)
  Add-Result 'initialize-pass' ($LASTEXITCODE-eq0) ($initialize-join' ')
  Add-Result 'staging-created' (Test-Path -LiteralPath $StagingDate -PathType Container)
  Add-Result 'final-managed-root-absent-before-preflight' (-not(Test-Path -LiteralPath $ManagedDate))

  $state=Get-Content -LiteralPath (Join-Path $StagingDate 'trigger-c-preparation.json') -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'state-awaits-real-editorial-native' ([string]$state.Status-ceq'AWAITING_EDITORIAL_AND_NATIVE')
  Add-Result 'source-evidence-complete' (@($state.SourceEvidence).Count-eq5)
  $triggerRoot=Join-Path $StagingDate "trigger-b\$ScanDate"
  $triggerFiles=@(Get-ChildItem -LiteralPath $triggerRoot -File)
  Add-Result 'trigger-b-dated-artifacts-complete' ($triggerFiles.Count-eq9)
  $meta=Get-Content -LiteralPath (Join-Path $triggerRoot "APL_Momentum_Leaders_Meta_$ScanDate.json") -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'trigger-b-meta-portable-relative-ranking' (-not[IO.Path]::IsPathRooted([string]$meta.fullRankingCsv)-and(Test-Path -LiteralPath (Join-Path $triggerRoot ([string]$meta.fullRankingCsv))))
  $validatorSource=[IO.File]::ReadAllText((Join-Path $ProjectRoot 'tools\validate_managed_inputs.ps1'),[Text.Encoding]::UTF8)
  Add-Result 'formal-builder-staging-root-policy' ($validatorSource.Contains('(Test-AplPathInside $allowedRoot $formalStagingRoot)')) 'Formal Finalize must accept the exact work\.staging\trigger-c root passed by the builder.'

  $forbiddenCreated=@(
    'table-card-manifest.json','cover-brief.json','cover-background.png','seo-background.png','cover-native-contract.json','seo-native-contract.json',
    "publishing\production-package\APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.md",
    "publishing\production-package\APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.html.txt",
    "publishing\production-package\WhatsApp_$ScanDate.md"
  )
  Add-Result 'no-placeholder-artifacts-created' (@($forbiddenCreated|Where-Object{Test-Path -LiteralPath (Join-Path $StagingDate $_)}).Count-eq0)

  $previous=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  $finalize=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Finalize -ScanDate $ScanDate 2>&1)
  $finalizeExit=$LASTEXITCODE
  $ErrorActionPreference=$previous
  $finalizeText=$finalize-join' '
  Add-Result 'incomplete-work-order-finalize-fails-closed' ($finalizeExit-ne0-and$finalizeText.Contains('Required file does not exist')) $finalizeText
  Add-Result 'failed-finalize-does-not-publish-managed-root' (-not(Test-Path -LiteralPath $ManagedDate))

  $rankingPath=Join-Path $triggerRoot "APL_Momentum_Score_Full_Ranking_$ScanDate.csv"
  $ranking=@(Import-Csv -LiteralPath $rankingPath)
  if($ranking.Count-lt30){throw "Positive fixture requires 30 ranking rows; actual=$($ranking.Count)"}
  $tableRoot=Join-Path $StagingDate 'table-cards'
  $executive=[ordered]@{SchemaVersion='APL Table Card Input v1.1';CardType='ExecutiveSummary';Title='核心觀察';Rows=@(
    [ordered]@{observation='能源成本提高';meaning='估值與資金成本重新定價'},
    [ordered]@{observation='領導力仍然存在';meaning='資金集中於盈利路徑清晰公司'},
    [ordered]@{observation='成交確認重要';meaning='需要持續參與才能鞏固趨勢'}
  )}
  $driverFixtures=@('企業設備訂單與交付需求','醫療檢測使用與支付覆蓋','企業軟件客戶續約與收入')
  $leaderRows=@(for($i=0;$i-lt3;$i++){$row=$ranking[$i];[ordered]@{rank="#$($i+1)";symbol=[string]$row.Symbol;companyName=[string]$row.Name;coreBusiness='企業營運與市場服務';mainDriver=$driverFixtures[$i];compositeScore=[double]$row.'Composite Score'}})
  $leaders=[ordered]@{SchemaVersion='APL Table Card Input v1.1';CardType='TopLeaders';Title='領導公司';Rows=$leaderRows}
  $headingMap=Get-AplBlogHeadingMap -ScanDate $ScanDate
  $topGainersHeading=Get-AplCanonicalTopGainersTitle
  $blogTopGainersHeading=[string]$headingMap.TopGainers
  $gainersCard=[ordered]@{SchemaVersion='APL Table Card Input v1.1';CardType='TopGainers';Title=$topGainersHeading;Rows=@(
    [ordered]@{symbol='T001';companyName='Alpha Research 1';sectorTheme='市場服務';changePct='+12.5%'},
    [ordered]@{symbol='T002';companyName='Alpha Research 2';sectorTheme='市場服務';changePct='+10.25%'},
    [ordered]@{symbol='T003';companyName='Alpha Research 3';sectorTheme='市場服務';changePct='+8%'}
  )}
  $sectorCard=[ordered]@{SchemaVersion='APL Table Card Input v1.1';CardType='SectorStructure';Title='產業結構';Rows=@(
    [ordered]@{theme='Others';count=30;direction='盈利能見度支持群組形成';representativeSymbols=(@($ranking|Select-Object -First 3|ForEach-Object{$_.Symbol})-join', ')}
  )}
  $cardFiles=[ordered]@{ExecutiveSummary='ExecutiveSummary.json';TopLeaders='TopLeaders.json';TopGainers='TopGainers.json';SectorStructure='SectorStructure.json'}
  Write-Json (Join-Path $tableRoot $cardFiles.ExecutiveSummary) $executive
  Write-Json (Join-Path $tableRoot $cardFiles.TopLeaders) $leaders
  Write-Json (Join-Path $tableRoot $cardFiles.TopGainers) $gainersCard
  Write-Json (Join-Path $tableRoot $cardFiles.SectorStructure) $sectorCard
  $cards=@()
  foreach($type in $cardFiles.Keys){$cards+=[ordered]@{CardType=$type;InputSchemaVersion='APL Table Card Input v1.1';InputPath=("table-cards/"+$cardFiles[$type]);OutputName=("APL_${type}_$ScanDate.png");Required=$true}}
  Write-Json (Join-Path $StagingDate 'table-card-manifest.json') ([ordered]@{SchemaVersion='APL Table Card Manifest v1.1';ScanDate=$ScanDate;Cards=$cards})

  $meta=Get-Content -LiteralPath (Join-Path $triggerRoot "APL_Momentum_Leaders_Meta_$ScanDate.json") -Raw -Encoding UTF8|ConvertFrom-Json
  $sections=[ordered]@{
    ([string]$headingMap.ExecutiveSummary)="能源與利率門檻上升，市場資金集中於具清晰盈利路徑、現金流及資本效率的企業。本期主要關注T001與T002，分別代表企業設備交付和醫療檢測需求。兩家公司維持相對強勢，而所屬業務直接連接客戶營運支出，因此是這次選擇性領導的研究重點。`r`n`r`n企業設備需求支持T001的交付方向，醫療檢測使用支持T002的服務收入，兩條主線具有不同的成本結構。這代表市場並未只圍繞單一熱門題材配置，資金同時選擇營運效率與必要性服務，並以可辨認的客戶需求支持公司地位。`r`n`r`n本期研究判斷是保留對領導公司的明確關注，並把能源、利率與個別企業風險納入同一框架。價格強勢提供資金選擇的證據，業務結構說明公司如何承接市場需求；兩者結合後，便能把本期的主要方向集中於T001與T002，而不是把所有上升公司視為同等機會。"
    ([string]$headingMap.MarketContext)="能源與利率重新定價令企業成本與估值折現率同步受壓，因此市場資金由廣泛追價轉向具盈利能見度的公司。能源成本提高運輸、設備及日常營運開支，利率則改變資金成本與遠期盈利的估值，兩股力量共同提高投資門檻。這條傳導鏈直接影響企業的成本轉嫁能力、資產負債表和資本配置，也令不同商業模式之間的回報差異更加清晰。`r`n`r`n指數表現不能完整反映個股差異，因為受壓與受惠企業可以同時存在。設備更新及營運效率支出支持部分企業服務，醫療檢測則由使用需求與支付覆蓋推動，兩者均具有清晰的業務連接。這說明資金輪動具體反映客戶支出方向，而非只依賴宏觀升跌標籤；本期T001與T002的相對強勢，因此具備獨立研究價值。`r`n`r`n高資本成本環境偏向支持資產負債表穩健、交付能力完整和收入來源清晰的公司，同時壓縮依賴持續外部融資的企業估值。市場因而形成選擇性領導，而不是所有板塊一起擴張。這項變化連接宏觀成本、企業需求及股票相對強弱，亦解釋本期把企業設備和醫療服務放在前列的理由。設備交付和服務使用對應不同客戶支出，收入組成與毛利結構亦不同，這些差異讓資金配置具備清晰的研究依據。"
    ([string]$headingMap.WhyAPL)='當主要指數同時包含受壓與受惠公司，只看平均升跌會掩蓋資金真正選擇。APL Momentum Leaders把相對強度、趨勢及市場參與放在同一框架，讓領導股研究集中於資金正在承接的企業。這個比較方式把短期價格變化與持續領導地位接起來，同時保留不同商業模式的差異，為本期選股提供一致的研究尺度。'
    $blogTopGainersHeading="SPX、NDX及DJI成分股的單日資料顯示，T001、T002及T003位於升幅前列，反映資金集中於具具體需求支持的公司。T001的設備服務、T002的醫療檢測和T003的企業軟件分別連接不同客戶支出，單日價格變化呈現市場當期的配置方向，而持續領導地位則由下節的中期排名提供比較。`r`n`r`nScope: SPX／NDX／DJI constituents."
    ([string]$headingMap.MomentumLeaders)="中期排名顯示T001與T002同時保持相對強勢與完整趨勢，資金集中於設備交付和檢測服務，因此本期主要關注兩家公司的需求定位。T003提供軟件收入的延伸比較，三家公司分別承接企業效率和必要性服務支出，形成具體的領導結構。`r`n`r`n這個結果說明領導力跨越不同商業模式，設備收入取決於交付節奏，檢測服務取決於使用與支付，軟件則連接續約與客戶擴張。比較這些差異後，T001與T002仍是本期清晰的主要方向，T003則補充企業服務的研究範圍。"
    ([string]$headingMap.SectorAnalysis)="由個股推進至群組後，可見選擇性領導涵蓋設備、醫療及軟件服務。代表公司在相近市場條件下維持強勢，說明資金以具體需求和業務定位組成新的配置結構。`r`n`r`n群組之間的收入來源及成本轉嫁能力不同，因此板塊比較應保留商業模式差異。設備交付、檢測使用及軟件續約共同呈現必要性支出的多條路徑，支持本期對市場領導結構的判斷。"
    ([string]$headingMap.InvestmentImplication)="對投資者而言，當前環境提高了選股標準，也令本期T001與T002的研究方向更清晰。設備交付和醫療檢測均連到具體客戶需求，因此資金配置具有可辨認的商業基礎。兩家公司所屬業務不同，能夠呈現效率提升與必要性服務的獨立需求，這是本期選擇性參與的主要理由。`r`n`r`n企業資本開支在高成本環境下更重視營運效率，所以具交付能力和服務支援的設備企業具有明確位置。T001的研究價值在於承接這類需求，而價格與中期排名共同反映市場對其定位。設備支出有交付節奏與客戶集中風險，這些因素決定公司承受宏觀壓力的方式，也提供同業比較的實際尺度。`r`n`r`n醫療檢測的需求結構則由臨床使用、檢測服務及支付條件構成，與設備資本開支不同。T002提供必要性服務的研究方向，因此本期同時關注醫療服務和企業效率。檢測使用帶來業務機會，而支付覆蓋與成本管理構成主要風險；這種收入與風險配對能更具體地說明公司地位。`r`n`r`nAPL Momentum Leaders顯示的相對強勢，把企業需求與市場資金連接起來。這代表排名具備選股上的比較價值，能夠協助辨認資金集中方向，同時讓商業模式差異維持清晰。T003的企業軟件服務則補充續約與客戶擴張的路徑，讓本期研究覆蓋設備、醫療及應用支出。`r`n`r`n能源、利率及融資成本仍會影響企業估值，但影響程度取決於公司現金流、負債和成本轉嫁能力。因此本期配置判斷集中於收入來源清晰且維持相對強勢的公司，並把外部成本與個別業務風險放在同一比較框架。這個方式保留成長機會，也讓風險來源具體可辨。`r`n`r`n整體投資啟示是重點關注T001與T002，並以T003延伸企業服務方向。若能源與利率壓力加大，估值敏感度和資金需要便是主要風險訊號；設備、檢測及軟件的需求連接則繼續構成本期研究依據。市場領導力存在於具體公司，這項判斷將資金流向、商業定位與風險結合，提供清晰的投資研究方向。"
    ([string]$headingMap.Risk)='能源利率重估提高企業成本與估值壓力，設備交付、醫療支付及軟件續約則構成個別業務風險。本期主要關注T001與T002，並以T003作企業服務延伸；市場環境推動資金選擇，但不同公司的受惠程度仍取決於業務定位及基本面差異。'
  }
  $title="APL Deep-Scan｜美股深海雷達: 市場領導分析 | $ScanDate"
  $markdown=New-Object Collections.Generic.List[string]
  $html=New-Object Collections.Generic.List[string]
  $issueUrl="https://www.goinvestingnow.com/blog/apl-deep-scan-$ScanDate";$trialUrl='https://www.goinvestingnow.com/ExploreCourses'
  $seoImagePath=(Join-Path $ProjectRoot "outputs/$ScanDate/production-package/APL_Momentum_Leaders_Blog_SEO_${ScanDate}_1280x720.png").Replace('\','/')
  $markdown.Add('## SEO and Sharing');$markdown.Add('');$markdown.Add("Page title：$title");$markdown.Add('');$markdown.Add('Page description：能源與利率提高選股門檻，T001與T002領航設備交付及醫療檢測需求。');$markdown.Add('');$markdown.Add('Sharing summary：本期主要關注T001與T002，並以T003延伸企業服務方向。');$markdown.Add('');$markdown.Add("Canonical URL：$issueUrl");$markdown.Add('');$markdown.Add("SEO 圖：[SEO 圖](<$seoImagePath>)");$markdown.Add('')
  $markdown.Add("# $title");$markdown.Add('')
  if([datetime]$ScanDate-lt[datetime]'2026-10-13'){$html.Add("<h1>$title</h1>")}
  foreach($heading in $sections.Keys){
    $markdown.Add("## $heading");$markdown.Add('')
    $paragraphs=@(([string]$sections[$heading])-split'(?:\r?\n){2,}')
    foreach($paragraph in $paragraphs){$markdown.Add($paragraph);$markdown.Add('');$html.Add("<h3>$heading</h3>")|Out-Null;break}
    for($paragraphIndex=0;$paragraphIndex-lt$paragraphs.Count;$paragraphIndex++){
      if($paragraphIndex-gt0){$markdown.Add($paragraphs[$paragraphIndex]);$markdown.Add('')}
      $html.Add("<p>$($paragraphs[$paragraphIndex])</p>")
    }
  }
  $package=Join-Path $StagingDate 'publishing\production-package'
  Write-Utf8 (Join-Path $package "APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.md") ($markdown-join[Environment]::NewLine)
  Write-Utf8 (Join-Path $package "APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.html.txt") ($html-join[Environment]::NewLine)
  $issueUrl="https://www.goinvestingnow.com/blog/apl-deep-scan-$ScanDate";$trialUrl='https://www.goinvestingnow.com/ExploreCourses'
  Write-Utf8 (Join-Path $package "WhatsApp_$ScanDate.md") ("🌊APL Deep-Scan 美股深海雷達`n`n能源利率重估提高估值與企業成本門檻，市場資金集中於具體需求及盈利定位較清晰的公司。本期APL Deep-Scan主要關注T001與T002，分別代表企業設備交付與醫療檢測服務。`n`nT001承接企業營運效率需求，T002連接檢測使用及支付覆蓋，兩家公司維持相對強勢，也呈現不同的收入來源。T003提供企業軟件服務的延伸比較，讓本期研究兼顧設備、醫療與應用支出。投資者可由這三條方向理解資金配置與商業定位。`n`n主要風險包括能源與利率壓力、設備交付節奏、醫療支付條件及客戶續約。這些風險對不同公司的影響各異，因此本期保留對T001與T002的主要關注，同時比較各自基本面。完整文章載有公司理據與板塊分析。`n`n研究摘要，不構成投資建議。`n`n📖 今日完整研究：`n$issueUrl`n`n🐧 APL 三日免費體驗｜工具・分析・課程`n$trialUrl")
  $companyLines=New-Object Collections.Generic.List[string]
  $companyLines.Add('# Top 30 Company Business Analysis')
  foreach($row in @($ranking|Select-Object -First 30)){$companyLines.Add("## $($row.Symbol) $($row.Name)");$companyLines.Add('公司核心業務涵蓋企業營運、市場服務及客戶解決方案，收入增長需要由產品需求、執行能力、成本控制與現金流共同支持。本期排名只代表相對市場領導，仍需持續檢查商業模式、盈利能見度與主要風險。')}
  Write-Utf8 (Join-Path $package "table-card-log\APL_Momentum_Leaders_Top_30_Company_Business_Analysis_$ScanDate.md") ($companyLines-join[Environment]::NewLine)

  $coverPath=Join-Path $StagingDate 'cover-background.png';$seoPath=Join-Path $StagingDate 'seo-background.png'
  New-Png $coverPath 600 750 ([Drawing.Color]::FromArgb(12,35,58))
  New-Png $seoPath 1280 720 ([Drawing.Color]::FromArgb(18,48,72))
  $brief=[ordered]@{
    version='APL Cover Brief v1.1';scanDate=$ScanDate;marketConclusion='選擇性領導';capitalFlow=[ordered]@{from='廣泛追價';to='盈利能見度'};riskBackground='能源與利率門檻';leadershipDestination=@('選擇性領導');mainVisualMetaphor='資金穿越提高的市場門檻'
    sceneConcept=[ordered]@{id='regression-energy-gate';coreMarketThesis=$coreThesis;subjectIdentity='穿越市場門檻的資金光流';primarySceneElements=@('能源光帶','市場門檻','領導方向');colorPalette='深藍、青色與金色';lightingDirection='由左向右';cinematicMood='克制而具張力';brandAtmosphere='機構研究';artStyle='電影感寫實'}
    nativeCompositions=[ordered]@{cover=[ordered]@{aspect_ratio='4:5';camera_distance='medium-close';framing_description='直向集中視角';subject_placement='中央偏下';text_safe_area='上方標題區'};seo=[ordered]@{aspect_ratio='16:9';camera_distance='wide';framing_description='橫向延展視角';subject_placement='右側三分位';text_safe_area='左側標題區'}}
    composition=[ordered]@{textSafeArea='role-specific';storyArea='role-specific';rules=@('no text in background')}
    imageGenerationBrief=[ordered]@{sharedPrompt='同一能源與市場門檻場景';coverPrompt='直向中近距離視角';seoPrompt='橫向廣角環境視角';negativePrompt='文字、標誌、水印'}
    overlay=[ordered]@{titleLines=@('能源門檻提高','選擇性領導');subtitle='市場重新檢驗盈利能見度';footer='Deep Scan'}
  }
  Write-Json (Join-Path $StagingDate 'cover-brief.json') $brief
  $generatedUtc=[datetime]::UtcNow.ToString('o')
  $coverContract=[ordered]@{artifact_type='cover';scene_concept_id='regression-energy-gate';native_size=[ordered]@{width=600;height=750};aspect_ratio='4:5';camera_distance='medium-close';framing_description='直向集中視角';subject_placement='中央偏下';text_safe_area='上方標題區';source_path='cover-background.png';tolerance=0.001;source_sha256=(Get-FileHash $coverPath -Algorithm SHA256).Hash;provider='Regression fixture';workflow='Independent native generation';generation_time=$generatedUtc;capture_stage='ImmediateGenerationOutput';transformation='none'}
  $seoContract=[ordered]@{artifact_type='seo';scene_concept_id='regression-energy-gate';native_size=[ordered]@{width=1280;height=720};aspect_ratio='16:9';camera_distance='wide';framing_description='橫向延展視角';subject_placement='右側三分位';text_safe_area='左側標題區';source_path='seo-background.png';tolerance=0.001;source_sha256=(Get-FileHash $seoPath -Algorithm SHA256).Hash;provider='Regression fixture';workflow='Independent native generation';generation_time=$generatedUtc;capture_stage='ImmediateGenerationOutput';transformation='none'}
  Write-Json (Join-Path $StagingDate 'cover-native-contract.json') $coverContract
  Write-Json (Join-Path $StagingDate 'seo-native-contract.json') $seoContract

  $finalizePass=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Finalize -ScanDate $ScanDate 2>&1)
  Add-Result 'complete-work-order-finalize-pass' ($LASTEXITCODE-eq0) ($finalizePass-join' ')
  Add-Result 'managed-root-atomically-published' ((Test-Path -LiteralPath $ManagedDate -PathType Container)-and-not(Test-Path -LiteralPath $StagingDate))
  $finalState=Get-Content -LiteralPath (Join-Path $ManagedDate 'trigger-c-preparation.json') -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'final-state-preflight-pass' ([string]$finalState.Status-ceq'PREFLIGHT_PASS')
  Add-Result 'editorial-audit-created' (Test-Path -LiteralPath (Join-Path $ManagedDate "publishing\production-package\APL_Editorial_Completion_Audit_$ScanDate.json") -PathType Leaf)
  $productionRoot=Join-Path $FixtureRoot 'production'
  $runnerErrorAction=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  $runnerOutput=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Runner -RegressionTest `
    -InputCsv (Join-Path $ManagedDate 'source.csv') -TopGainersCsvPath (Join-Path $ManagedDate 'top-gainers.csv') `
    -MarketContextPath (Join-Path $ManagedDate 'market-context.md') -TriggerBMetaPath (Join-Path $ManagedDate "trigger-b\$ScanDate\APL_Momentum_Leaders_Meta_$ScanDate.json") `
    -TableCardManifestPath (Join-Path $ManagedDate 'table-card-manifest.json') -CoverBriefPath (Join-Path $ManagedDate 'cover-brief.json') `
    -CoverBackgroundPath (Join-Path $ManagedDate 'cover-background.png') -SeoBackgroundPath (Join-Path $ManagedDate 'seo-background.png') `
    -CoverNativeContractPath (Join-Path $ManagedDate 'cover-native-contract.json') -SeoNativeContractPath (Join-Path $ManagedDate 'seo-native-contract.json') `
    -PublishingArtifactsRoot (Join-Path $ManagedDate 'publishing') -ScanDate $ScanDate -WeekLabel 'Regression' -OutputRoot $productionRoot 2>&1)
  $runnerExit=$LASTEXITCODE
  $ErrorActionPreference=$runnerErrorAction
  Add-Result 'daily-production-consumes-finalized-bundle' ($runnerExit-eq0) ($runnerOutput-join' ')
  $dailyStatePath=Join-Path $productionRoot "logs\daily-production-state-$ScanDate.json"
  if(Test-Path -LiteralPath $dailyStatePath){$dailyState=Get-Content -LiteralPath $dailyStatePath -Raw -Encoding UTF8|ConvertFrom-Json;Add-Result 'daily-production-complete' ($dailyState.DailyProductionComplete-eq$true-and[string]$dailyState.Status-ceq'PASS')}
  else{Add-Result 'daily-production-complete' $false 'Authoritative state was not created.'}
  $invalidMarket=Join-Path $FixtureRoot 'market-context-missing-thesis.md'
  Write-Utf8 $invalidMarket '## 市場背景`r`n這是一段沒有受管核心命題的市場說明。'
  $previous=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  $invalidInitialize=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Initialize -ScanDate $SupersedeDate -WeekLabel 'Regression' -InputCsv $input -TopGainersCsvPath $gainers -MarketContextPath $invalidMarket 2>&1)
  $invalidInitializeExit=$LASTEXITCODE
  $ErrorActionPreference=$previous
  Add-Result 'missing-core-thesis-rejected-before-staging' ($invalidInitializeExit-ne0-and($invalidInitialize-join' ').Contains('exactly one 本期核心市場命題')-and-not(Test-Path -LiteralPath $SupersedeStagingDate))
  $supersedeInitialize=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Initialize -ScanDate $SupersedeDate -WeekLabel 'Regression' -InputCsv $input -TopGainersCsvPath $gainers -MarketContextPath $market 2>&1)
  Add-Result 'initial-staging-created-for-supersede' ($LASTEXITCODE-eq0-and(Test-Path -LiteralPath $SupersedeStagingDate)) ($supersedeInitialize-join' ')
  $revisedMarket=Join-Path $FixtureRoot 'market-context-revised.md'
  $revisedThesis='能源與利率風險重新提高估值門檻，資金正轉向盈利能見度、現金流品質與資本效率更明確的中期領導公司。'
  Write-Utf8 $revisedMarket "本期核心市場命題：$revisedThesis`r`n`r`n## 修訂市場背景`r`n修訂來源把當期市場因果關係集中於能源成本、利率預期與企業盈利品質。"
  $supersede=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Supersede -ScanDate $SupersedeDate -WeekLabel 'Regression' -InputCsv $input -TopGainersCsvPath $gainers -MarketContextPath $revisedMarket 2>&1)
  Add-Result 'supersede-pass' ($LASTEXITCODE-eq0-and(Test-Path -LiteralPath $SupersedeStagingDate)) ($supersede-join' ')
  $rejected=@(Get-ChildItem -LiteralPath $RejectedStagingRoot -Directory -ErrorAction SilentlyContinue|Where-Object{$_.Name.StartsWith($SupersedeDate+'-')})
  Add-Result 'supersede-preserves-prior-staging-in-quarantine' ($rejected.Count-eq1)
  Add-Result 'supersede-new-market-source-is-bound' ((Get-FileHash -LiteralPath (Join-Path $SupersedeStagingDate 'market-context.md') -Algorithm SHA256).Hash-ceq(Get-FileHash -LiteralPath $revisedMarket -Algorithm SHA256).Hash)
  $supersedeState=Get-Content -LiteralPath (Join-Path $SupersedeStagingDate 'trigger-c-preparation.json') -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'supersede-work-order-carries-cover-contract' ([string]$supersedeState.WorkOrder.NativeAssets.RequiredCoverBriefVersion-ceq'APL Cover Brief v1.1'-and[string]$supersedeState.WorkOrder.NativeAssets.RequiredCoverBriefScanDate-ceq$SupersedeDate-and[string]$supersedeState.WorkOrder.NativeAssets.RequiredCoreMarketThesis-ceq$revisedThesis)
  $afterHashes=@(@($input,$gainers,$market)|ForEach-Object{(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash})
  Add-Result 'intake-sources-unchanged' (-not(Compare-Object $sourceHashes $afterHashes))
}catch{
  Add-Result 'test-harness' $false $_.Exception.Message
}finally{
  foreach($path in @($StagingDate,$ManagedDate,$SupersedeStagingDate,$SupersedeManagedDate,$RejectedStagingRoot,$FixtureRoot)){
    try {
      $full=[IO.Path]::GetFullPath($path)
      $allowed=[IO.Path]::GetFullPath((Join-Path $ProjectRoot 'tmp')).TrimEnd('\')+'\'
      if(-not $full.StartsWith($allowed,[StringComparison]::OrdinalIgnoreCase)){throw 'Cleanup path escaped repository tmp.'}
      if(Test-Path -LiteralPath $full){Remove-Item -LiteralPath $full -Recurse -Force}
    } catch { Add-Result 'fixture-cleanup' $false $_.Exception.Message }
  }
}

$failed=@($results|Where-Object{-not$_.Passed})
[pscustomobject]@{Passed=($failed.Count-eq0);Total=$results.Count;Failed=$failed.Count;Results=[object[]]$results.ToArray()}|ConvertTo-Json -Depth 5
if($failed.Count-gt0){exit 1}
