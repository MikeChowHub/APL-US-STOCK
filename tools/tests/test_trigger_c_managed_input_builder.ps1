[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
. (Join-Path $ProjectRoot 'tools\renderer_production_common.ps1')
$Script=Join-Path $ProjectRoot 'tools\prepare_trigger_c_managed_inputs.ps1'
$ScanDate='2040-02-07'
$SupersedeDate='2040-02-08'
$FixtureRoot=Join-Path $ProjectRoot ("tmp\tc-"+[guid]::NewGuid().ToString('N').Substring(0,8))
$BuilderRoot=Join-Path $ProjectRoot 'tmp\tc-inputs'
$StagingDate=Join-Path $BuilderRoot "staging\$ScanDate"
$ManagedDate=Join-Path $BuilderRoot "managed-inputs\$ScanDate"
$SupersedeStagingDate=Join-Path $BuilderRoot "staging\$SupersedeDate"
$SupersedeManagedDate=Join-Path $BuilderRoot "managed-inputs\$SupersedeDate"
$RejectedStagingRoot=Join-Path $BuilderRoot 'staging\rejected'
$ownsReservedDates=$false
$initialRejectedPaths=@(Get-ChildItem -LiteralPath $RejectedStagingRoot -Directory -ErrorAction SilentlyContinue|ForEach-Object{$_.FullName})
$fixtureSectorMap=Get-Content -LiteralPath (Join-Path $ProjectRoot 'tools\sector_map.json') -Raw -Encoding UTF8|ConvertFrom-Json
$fixtureSymbols=@('ALNT','NEO','APPN')+@($fixtureSectorMap.Symbols.PSObject.Properties|Where-Object{$_.Name-notin@('ALNT','NEO','APPN')-and$_.Value-in@('Industrial','Healthcare','Software','Consumer','Financial','Energy','Networking','Bio')}|ForEach-Object{$_.Name}|Sort-Object|Select-Object -First 67)
$fixtureIndustries=@('Industrial machinery','Medical services','Packaged software','Air freight/Couriers','Industrial machinery','Pharmaceuticals: major','Packaged software','Food retail','Electrical products','Data processing services','Aerospace and defense','Finance/Rental/Leasing','Home furnishings','Semiconductors','Major telecommunications','Trucks/Construction/Farm machinery','Industrial machinery','Apparel/Footwear','Miscellaneous commercial services','Aerospace and defense','Medical specialties','Miscellaneous commercial services','Household/Personal care','Electronic equipment/Instruments','Biotechnology','Construction materials','Packaged software','Restaurants','Environmental services','Other consumer services')
$results=New-Object System.Collections.Generic.List[object]
Add-Type -AssemblyName System.Drawing

function Add-Result([string]$Name,[bool]$Passed,[string]$Detail=''){
  [void]$results.Add([pscustomobject]@{Name=$Name;Status=if($Passed){'PASS'}else{'FAIL'};Passed=$Passed;Detail=$Detail})
  if($Passed){Write-Host "PASS $Name"}else{Write-Host "FAIL $Name :: $Detail" -ForegroundColor Red}
}

function Write-Utf8([string]$Path,[string]$Text){
  $parent=Split-Path $Path -Parent
  if(!(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
  for($i=0;$i-lt$fixtureSymbols.Count;$i++){$Text=$Text.Replace(('T{0:D3}'-f($i+1)),[string]$fixtureSymbols[$i])}
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
  foreach($reserved in @($StagingDate,$ManagedDate,$SupersedeStagingDate,$SupersedeManagedDate)){if(Test-Path -LiteralPath $reserved){throw "Reserved regression path already exists: $reserved"}}
  $ownsReservedDates=$true
  $input=Join-Path $FixtureRoot 'source.csv'
  $gainers=Join-Path $FixtureRoot 'top-gainers.csv'
  $market=Join-Path $FixtureRoot 'market-context.md'
  $header=@(
    'Symbol','Description','Price',
    '"Simple moving average, 20, 1 day"','"Simple moving average, 50, 1 day"','"Simple moving average, 200, 1 day"',
    '"High, 52 weeks"','"Performance %, 3 months"','"Performance %, 6 months"','"Relative volume, 1 day"','Industry'
  )-join','
  $rows=@(1..70|ForEach-Object{
    $symbol=[string]$fixtureSymbols[$_-1]
    $price=171-$_
    $sma20=$price-2;$sma50=$price-5;$sma200=$price-10;$high52=$price+8
    $perf3=71-$_;$perf6=101-$_;$relvol=[Math]::Round(3.5-($_/100),2)
    $industry=if($_-le$fixtureIndustries.Count){$fixtureIndustries[$_-1]}else{'Industrial machinery'}
    "$symbol,Alpha Research $_,$price,$sma20,$sma50,$sma200,$high52,$perf3,$perf6,$relvol,$industry"
  })
  Write-Utf8 $input ((@($header)+$rows)-join[Environment]::NewLine)
  Write-Utf8 $gainers "Symbol,Description,`"Price change %, 1 day`"`r`nT001,Alpha Research 1,12.5`r`nT002,Alpha Research 2,10.25`r`nT003,Alpha Research 3,8"
  $coreThesis='能源成本與利率門檻同步上升，市場領導力因此轉向盈利能見度、自由現金流及資本效率較清晰的公司，而非延續廣泛追價。'
  Write-Utf8 $market "本期核心市場命題是：$coreThesis`r`n`r`n## 能源利率重估`r`n能源成本提高企業資金門檻，市場因此重新檢視估值、現金流與資本配置效率，並尋找盈利路徑較清晰的領導公司。"
  $sourceHashes=@(@($input,$gainers,$market)|ForEach-Object{(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash})

  $missingIndustry=Join-Path $FixtureRoot 'source-without-industry.csv'
  Write-Utf8 $missingIndustry ((@($header-replace',Industry$','')+@($rows|ForEach-Object{$_-replace',[^,]+$',''}))-join[Environment]::NewLine)
  $previous=$ErrorActionPreference;$ErrorActionPreference='Continue'
  $missingIndustryOutput=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Initialize -ScanDate $SupersedeDate -WeekLabel 'Regression' -InputCsv $missingIndustry -TopGainersCsvPath $gainers -MarketContextPath $market 2>&1)
  $missingIndustryExit=$LASTEXITCODE;$ErrorActionPreference=$previous
  Add-Result 'missing-industry-rejected-before-staging' ($missingIndustryExit-ne0-and($missingIndustryOutput-join' ').Contains('Cumulative CSV requires exactly one Symbol and one Industry column.')-and-not(Test-Path -LiteralPath $SupersedeStagingDate)) ($missingIndustryOutput-join' ')

  $initialize=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Initialize -ScanDate $ScanDate -WeekLabel 'Regression' -InputCsv $input -TopGainersCsvPath $gainers -MarketContextPath $market 2>&1)
  Add-Result 'initialize-pass' ($LASTEXITCODE-eq0) ($initialize-join' ')
  Add-Result 'staging-created' (Test-Path -LiteralPath $StagingDate -PathType Container)
  Add-Result 'final-managed-root-absent-before-preflight' (-not(Test-Path -LiteralPath $ManagedDate))

  $state=Get-Content -LiteralPath (Join-Path $StagingDate 'trigger-c-preparation.json') -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'state-awaits-real-editorial-native' ([string]$state.Status-ceq'AWAITING_EDITORIAL_AND_NATIVE')
  Add-Result 'source-evidence-complete' (@($state.SourceEvidence).Count-eq6)
  $industryEvidencePath=Join-Path $StagingDate 'top30-industry-evidence.json'
  $industryEvidence=Get-Content -LiteralPath $industryEvidencePath -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'top30-industry-evidence-bound' (@($industryEvidence.Rows).Count-eq30-and[string]$industryEvidence.SourceSHA256-ceq$sourceHashes[0]-and@($industryEvidence.Rows|Where-Object{[string]::IsNullOrWhiteSpace([string]$_.SourceIndustry)}).Count-eq0)
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
  $previous=$ErrorActionPreference;$ErrorActionPreference='Continue'
  $prematureProduce=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Produce -ScanDate $ScanDate 2>&1)
  $prematureProduceExit=$LASTEXITCODE;$ErrorActionPreference=$previous
  Add-Result 'produce-requires-finalized-bundle' ($prematureProduceExit-ne0-and($prematureProduce-join' ').Contains('Run Finalize before Produce.')) ($prematureProduce-join' ')

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
  $sectorGroups=@($ranking|Select-Object -First 30|Group-Object -Property {[string]$fixtureSectorMap.Symbols.PSObject.Properties[[string]$_.Symbol].Value})
  $sectorRows=@($sectorGroups|ForEach-Object{[ordered]@{theme=[string]$_.Name;count=[int]$_.Count;direction='盈利能見度支持群組形成';representativeSymbols=(@($_.Group|Select-Object -First 3|ForEach-Object{$_.Symbol})-join', ')}})
  $sectorCard=[ordered]@{SchemaVersion='APL Table Card Input v1.1';CardType='SectorStructure';Title='產業結構';Rows=$sectorRows}
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
    ([string]$headingMap.InvestmentImplication)="本期選股優先次序以T001設備交付與T002醫療檢測為主，T003企業軟件居延伸觀察位置。前兩者服務的客戶與付款方不同，能提供企業更新設備及醫療使用兩種研究方向；優先次序來自各自需求定位與相對強勢的結合，並非把同日上升公司視為同等機會。`r`n`r`n設備公司承接企業效率投資，收入時點受驗收與安裝影響；檢測公司按實際樣本服務收費，業務則與診療使用相關。APL Momentum Leaders把兩者放入同一比較框架，投資者可先理解客戶支出類型，再區分訂單交付與持續服務的營運特性，這也是本期保留兩條主要方向的理由。`r`n`r`nT003提供訂閱服務的補充視角，較適合用客戶使用與續約來比較，而不是沿用設備交付標準。能源成本與利率壓力下，本期研究集中於需求來源清楚的公司；客戶付款、供應零件與醫療支付的風險則各自處理，讓關注理由與具體經營風險相對應。"
    ([string]$headingMap.Risk)='能源利率重估提高企業成本與估值壓力，設備交付、醫療支付及軟件續約則構成個別業務風險。本期主要關注T001與T002，並以T003作企業服務延伸；市場環境推動資金選擇，但不同公司的受惠程度仍取決於業務定位及基本面差異。'
  }
  $title="APL Deep-Scan｜美股深海雷達: 市場領導分析 | $ScanDate"
  $markdown=New-Object Collections.Generic.List[string]
  $issueUrl="https://www.goinvestingnow.com/blog/apl-deep-scan-$ScanDate";$trialUrl='https://www.goinvestingnow.com/ExploreCourses'
  $seoImagePath=(Join-Path $ProjectRoot "outputs/$ScanDate/production-package/APL_Momentum_Leaders_Blog_SEO_${ScanDate}_1280x720.png").Replace('\','/')
  $markdown.Add('## SEO and Sharing');$markdown.Add('');$markdown.Add("Page title：$title");$markdown.Add('');$markdown.Add('Page description：能源與利率提高選股門檻，T001與T002領航設備交付及醫療檢測需求。');$markdown.Add('');$markdown.Add('Sharing summary：本期主要關注T001與T002，並以T003延伸企業服務方向。');$markdown.Add('');$markdown.Add("Canonical URL：$issueUrl");$markdown.Add('');$markdown.Add("SEO 圖：[SEO 圖](<$seoImagePath>)");$markdown.Add('')
  $markdown.Add("# $title");$markdown.Add('')
  foreach($heading in $sections.Keys){
    $markdown.Add("## $heading");$markdown.Add('')
    $markdown.Add([string]$sections[$heading]);$markdown.Add('')
  }
  $package=Join-Path $StagingDate 'publishing\production-package'
  $markdownPath=Join-Path $package "APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.md"
  $htmlPath=Join-Path $package "APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.html.txt"
  $markdownText=($markdown-join[Environment]::NewLine).Replace('主要關注T001與T002，','主要關注**T001**與**T002**，')
  Write-Utf8 $markdownPath $markdownText
  $issueUrl="https://www.goinvestingnow.com/blog/apl-deep-scan-$ScanDate";$trialUrl='https://www.goinvestingnow.com/ExploreCourses'
  Write-Utf8 (Join-Path $package "WhatsApp_$ScanDate.md") ("🌊APL Deep-Scan 美股深海雷達`n`n能源利率重估提高估值與企業成本門檻，市場資金集中於具體需求及盈利定位較清晰的公司。本期APL Deep-Scan主要關注T001與T002，分別代表企業設備交付與醫療檢測服務。`n`nT001承接企業營運效率需求，T002連接檢測使用及支付覆蓋，兩家公司維持相對強勢，也呈現不同的收入來源。T003提供企業軟件服務的延伸比較，讓本期研究兼顧設備、醫療與應用支出。投資者可由這三條方向理解資金配置與商業定位。`n`n主要風險包括能源與利率壓力、設備交付節奏、醫療支付條件及客戶續約。這些風險對不同公司的影響各異，因此本期保留對T001與T002的主要關注，同時比較各自基本面。完整文章載有公司理據與板塊分析。`n`n研究摘要，不構成投資建議。`n`n📖 今日完整研究：`n$issueUrl`n`n🐧 APL 三日免費體驗｜工具・分析・課程`n$trialUrl")
  $companyLines=New-Object Collections.Generic.List[string]
  $companyLines.Add('# Top 30 Company Business Analysis')
  # Synthetic companies have distinct operating models so this fixture exercises company-level review.
  $companyResearch=@(
    '設備製造商銷售工廠自動化機台，並在安裝後提供維護服務。客戶為更新產線的製造業企業，訂單交付及驗收決定收入入帳節奏；零件短缺可能延長安裝時間，拖慢設備收款，因此研究重點是交付能力與售後服務安排。',
    '檢測服務商為醫院處理臨床樣本，依照檢驗項目及服務量取得收入。臨床採用帶動實驗室使用，保險支付標準影響每份樣本的實收金額；若支付方降低報銷價格，樣本增加也可能無法抵銷單價壓力，需要關注支付覆蓋與處理成本。',
    '企業軟件平台協助客戶配置審批流程，採用按年訂閱及導入服務收費。客戶新增部門可擴大軟件席位，跨部門整合有助維持使用黏性；若競爭產品簡化移轉，續約議價便會轉弱，營運重點在既有客戶使用及實施成效。',
    '貨運代理安排港口至倉庫的運輸，利用承運網絡向進出口企業提供物流服務。訂單收入與貨物週轉及艙位價格相關，路線改道可能拉長運輸時間；承運成本上升若無法轉嫁予客戶，會壓縮服務差價，合約定價方式影響盈利。',
    '水處理設備公司向市政單位出售過濾系統，並收取耗材更換收入。污水廠升級形成較長的工程訂單，後續耗材提供持續服務需求；地方政府預算延後會影響工程付款，研究應連結項目進度與應收帳款回收，而非只看新簽總額。',
    '藥品企業供應慢性病處方治療，銷售透過分銷商及醫療體系進行。醫師採用與保險給付共同決定需求，製劑差異是其競爭定位；專利到期後的仿製藥可能降低售價，若產品組合過度集中，單一療法的競爭會放大盈利波動。',
    '網絡防護供應商出售端點安全訂閱，為大型企業管理員工裝置及威脅監測。遠端工作擴大保護範圍，也增加管理政策的複雜度；產品整合失誤可能降低防護可靠性，續約留存與服務品質因此比純粹新增帳戶更能說明業務韌性。',
    '零售商經營折扣食品門店，依靠採購效率與快速週轉提供日常商品。低價定位吸引對支出敏感的家庭，門店密度決定配送效率；若租金及人工上升超過客流改善，單店利潤便受擠壓，擴店速度應與物流承載能力一併分析。',
    '電力設備企業製造變壓器及配電控制系統，客戶涵蓋公用事業與大型工業設施。電網改造帶來工程需求，但訂製設備需要較長生產周期；銅材價格上漲與熟練工人不足可能增加交付成本，固定價格合約對毛利的影響尤其明顯。',
    '保險資訊公司彙整事故及理賠資料，按使用權或查詢量向保險商收費。模型品質與資料覆蓋增加客戶的定價效率，形成續約價值；若資料使用限制改變，產品更新成本可能提高，研究需重視資料權利、客戶留存及新產品採用。',
    '航空零件製造商供應發動機耐熱部件，收入來自新機配套及維修替換。飛行時數增加可支持備件需求，而新機交付依賴主機廠排程；品質認證延遲會阻礙出貨，材料加工良率及售後需求的占比共同影響其現金回收節奏。',
    '支付公司為商戶處理跨境交易，收取交易手續費及外匯服務費用。商戶國際銷售擴大可以提高處理量，但不同地區的監管與支付網絡費率各異；交易欺詐會增加賠付與審查支出，風險控制能力是維持費率收益的重要條件。',
    '家具品牌透過自營門店及網上渠道出售家居產品，提供配送與安裝配套。住宅搬遷及翻新需求支持客單價，產品設計影響品牌議價；若庫存品類偏離消費偏好，促銷折扣會侵蝕毛利，採購周期與庫存周轉因此需要同步觀察。',
    '半導體測試供應商設計自動化測試設備，服務晶片封裝廠及整合元件製造商。更高運算密度增加測試複雜度，可帶動設備規格升級；終端庫存調整則可能延後客戶採購，設備利用率與訂單取消條款決定下行期間的承受力。',
    '通訊營運商向住宅及企業提供寬頻連線，訂閱費是主要現金收入。網絡覆蓋與服務穩定性支持客戶續約，升級頻寬可提高套餐收入；無線替代方案壓低定價空間，基建投入與用戶流失率共同影響資本開支的回收效率。',
    '農業科技企業提供精準灌溉裝置，向農場銷售控制器與感測系統。水資源壓力增加節水設備需求，農民可依作物用水調整灌溉；農產品價格下跌會削弱農場投資能力，經銷商庫存與農戶融資條件會改變訂單轉換速度。',
    '數據中心冷卻公司製造液冷管路與控制設備，為高密度機櫃管理散熱。運算功率提升提高熱管理規格，工程服務協助現場系統整合；冷卻液洩漏或安裝缺陷可能導致維修責任，品質管理與施工夥伴能力影響專案盈利。',
    '醫療服裝品牌面向醫護人員直接銷售工作服，產品兼顧舒適度與功能設計。重複購買及新品搭配支持訂單，直接銷售有助掌握客戶偏好；廣告取得客戶的費用若升高，收入成長未必改善利潤，供應成本與回購比例是核心觀察。',
    '企業顧問公司提供稅務申報及跨境交易諮詢，主要依專業工時與項目合約收費。法規複雜度形成顧問需求，既有客戶可增加服務範圍；資深人才流失可能影響項目交付，薪酬增長與可收費工時利用率直接左右服務毛利。',
    '航天企業生產衛星零組件，並為商業及政府客戶提供任務整合服務。客戶任務設計決定產品規格，長期合約可支撐研發配置；發射時程調整會推遲交付付款，測試失敗亦會增加返工支出，訂單進度比單一任務數量更有意義。',
    '生命科學工具商向研究實驗室供應試劑及儀器耗材，產品在日常實驗中重複使用。藥物研究與學術專案形成終端需求，耗材收入具持續特性；科研預算削減會降低使用量，客戶庫存去化與新實驗啟動速度影響銷售復甦。',
    '背景審查企業協助僱主核實候選人的工作及資格紀錄，按查核件數取得服務費。招聘數量增加支持交易量，資料整合速度影響服務競爭力；企業凍結招聘將減少查詢需求，個人資料法規亦可能提高審核成本與作業時間。',
    '品牌化妝品公司透過零售通路與自營網站出售護膚產品，利用新品及社群推廣擴大客群。不同通路具有不同毛利與回款條件，產品回購可降低行銷取得成本；若新品熱度快速消退，庫存減值與廣告開支會同時壓低盈利。',
    '工業感測器廠商為工廠設備提供溫度及壓力監控，產品嵌入自動化產線。客戶認證後通常沿用既有規格，設備更新則創造新增需求；工業投資減速可能壓低訂購量，少量高規格產品的良率波動也會影響製造成本。',
    '腫瘤藥物研發公司透過授權與合作研發取得資金，主要候選藥仍受臨床試驗結果影響。合作夥伴分擔開發成本，但里程碑收入具有不連續性；若療效或安全性未達目標，專案價值及資金需求會改變，現金儲備決定研發延續空間。',
    '建築材料供應商向承包商出售隔熱及防水產品，並透過經銷網絡服務住宅翻修。節能改造有助增加高規格材料採用，地區天氣亦影響施工節奏；原料上漲若遇到需求疲弱，價格轉嫁便受限制，產品組合及區域庫存需要配合。',
    '內容管理軟件企業提供文件共享與存取控制，按員工帳戶收取雲端服務費。企業協作與合規要求支持使用，導入系統後的資料移轉形成切換成本；大型平台綑綁競爭可能壓低續約價格，新增功能的使用率影響客戶擴張。',
    '餐飲服務公司經營連鎖門店並授權加盟商使用品牌，收入包括自營銷售與加盟費。標準化菜單及供應鏈支持擴店，但不同城市的客流與租金差異明顯；食品安全事故會影響品牌信任，門店管理品質及原料成本決定利潤穩定性。',
    '電池回收企業從工業廢料提取鎳鈷等金屬，收入取決於處理費及回收金屬售價。製造廢料提供原料來源，回收效率影響可售產量；金屬價格下降與進料不足可能降低設備利用率，環保合規及處理良率共同構成經營門檻。',
    '教育科技平台為成人提供專業技能課程，透過企業培訓合約與個人訂閱收費。僱主需要更新員工技能時可帶動課程採購，學習內容品質影響留存；若課程與工作需求脫節，續訂會下降，講師投入及平台支出決定每名學員服務成本。'
  )
  foreach($row in @($ranking|Select-Object -First 30)){
    $researchIndex=[Array]::IndexOf($fixtureSymbols,[string]$row.Symbol)
    if($researchIndex-lt0-or$researchIndex-ge$companyResearch.Count){throw 'Unexpected synthetic ranking symbol.'}
    $companyLines.Add("## $($row.Symbol) $($row.Name)");$companyLines.Add($companyResearch[$researchIndex])
  }
  $companyPath=Join-Path $package "table-card-log\APL_Momentum_Leaders_Top_30_Company_Business_Analysis_$ScanDate.md"
  $companyDocument=$companyLines-join[Environment]::NewLine
  Write-Utf8 $companyPath $companyDocument

  $reviewPass=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Review -ScanDate $ScanDate 2>&1)
  Add-Result 'reader-review-pass-before-native-assets' ($LASTEXITCODE-eq0-and($reviewPass-join' ').Contains('DRAFT_READER_CHECKS_PASS')-and-not(Test-Path -LiteralPath (Join-Path $StagingDate 'cover-background.png'))) ($reviewPass-join' ')
  $copiedCompanyLines=New-Object Collections.Generic.List[string]
  $copiedCompanyLines.Add('# Top 30 Company Business Analysis')
  foreach($row in @($ranking|Select-Object -First 30)){$copiedCompanyLines.Add("## $($row.Symbol) $($row.Name)");$copiedCompanyLines.Add($companyResearch[0])}
  $copiedCompanyDocument=$copiedCompanyLines-join[Environment]::NewLine
  Write-Utf8 $companyPath $copiedCompanyDocument
  $previous=$ErrorActionPreference;$ErrorActionPreference='Continue'
  $reviewReject=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Review -ScanDate $ScanDate 2>&1)
  $reviewRejectExit=$LASTEXITCODE;$ErrorActionPreference=$previous
  Add-Result 'reader-review-rejects-copied-company-analysis' ($reviewRejectExit-ne0-and($reviewReject-join' ').Contains('Reader quality found a copied company-analysis sentence')) ($reviewReject-join' ')
  Write-Utf8 $companyPath $companyDocument

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

  Write-Utf8 $companyPath $copiedCompanyDocument
  $previous=$ErrorActionPreference;$ErrorActionPreference='Continue'
  $finalizeReaderReject=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Finalize -ScanDate $ScanDate 2>&1)
  $finalizeReaderRejectExit=$LASTEXITCODE;$ErrorActionPreference=$previous
  Add-Result 'finalize-runs-reader-gate-under-regression-mode' ($finalizeReaderRejectExit-ne0-and($finalizeReaderReject-join' ').Contains('Reader quality found a copied company-analysis sentence')) ($finalizeReaderReject-join' ')
  Add-Result 'reader-rejection-keeps-staging-unpublished' ((Test-Path -LiteralPath $StagingDate)-and-not(Test-Path -LiteralPath $ManagedDate))
  Write-Utf8 $companyPath $companyDocument
  Add-Result 'finalize-generates-html-in-staging' (Test-Path -LiteralPath $htmlPath -PathType Leaf)
  $revisedOpening='企業設備交付與醫療檢測各有明確需求。'
  Write-Utf8 $markdownPath ($markdownText.Replace('分別代表企業設備交付和醫療檢測需求。',$revisedOpening))

  $finalizePass=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Finalize -ScanDate $ScanDate -GenerateHtmlFromMarkdown 2>&1)
  Add-Result 'complete-work-order-finalize-pass' ($LASTEXITCODE-eq0) ($finalizePass-join' ')
  Add-Result 'managed-root-atomically-published' ((Test-Path -LiteralPath $ManagedDate -PathType Container)-and-not(Test-Path -LiteralPath $StagingDate))
  $finalState=Get-Content -LiteralPath (Join-Path $ManagedDate 'trigger-c-preparation.json') -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'final-state-preflight-pass' ([string]$finalState.Status-ceq'PREFLIGHT_PASS')
  $finalHtml=[IO.File]::ReadAllText((Join-Path $ManagedDate "publishing\production-package\APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.html.txt"))
  Add-Result 'regenerated-html-matches-revised-markdown' ($finalHtml.Contains($revisedOpening)-and-not$finalHtml.Contains('分別代表企業設備交付和醫療檢測需求。'))
  Add-Result 'editorial-audit-created' (Test-Path -LiteralPath (Join-Path $ManagedDate "publishing\production-package\APL_Editorial_Completion_Audit_$ScanDate.json") -PathType Leaf)
  $finalEditorialAudit=Get-Content -LiteralPath (Join-Path $ManagedDate "publishing\production-package\APL_Editorial_Completion_Audit_$ScanDate.json") -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'reader-gate-evidence-in-final-audit' ([string]$finalEditorialAudit.ReaderQuality.Status-ceq'PASS'-and[int]$finalEditorialAudit.ReaderQuality.CompanySections-eq30)
  $productionRoot=Join-Path $FixtureRoot 'production'
  $runnerErrorAction=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  $runnerOutput=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Produce -ScanDate $ScanDate -OutputRoot $productionRoot 2>&1)
  $runnerExit=$LASTEXITCODE
  $ErrorActionPreference=$runnerErrorAction
  Add-Result 'daily-production-consumes-finalized-bundle' ($runnerExit-eq0) ($runnerOutput-join' ')
  $dailyStatePath=Join-Path $productionRoot "logs\daily-production-state-$ScanDate.json"
  if(Test-Path -LiteralPath $dailyStatePath){$dailyState=Get-Content -LiteralPath $dailyStatePath -Raw -Encoding UTF8|ConvertFrom-Json;Add-Result 'daily-production-complete' ($dailyState.DailyProductionComplete-eq$true-and$dailyState.DailyProductionPublishable-eq$true-and[string]$dailyState.Status-ceq'PASS')}
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
  $rejected=@(Get-ChildItem -LiteralPath $RejectedStagingRoot -Directory -ErrorAction SilentlyContinue|Where-Object{$_.Name.StartsWith($SupersedeDate+'-')-and$initialRejectedPaths-notcontains$_.FullName})
  Add-Result 'supersede-preserves-prior-staging-in-quarantine' ($rejected.Count-eq1)
  Add-Result 'supersede-new-market-source-is-bound' ((Get-FileHash -LiteralPath (Join-Path $SupersedeStagingDate 'market-context.md') -Algorithm SHA256).Hash-ceq(Get-FileHash -LiteralPath $revisedMarket -Algorithm SHA256).Hash)
  $supersedeState=Get-Content -LiteralPath (Join-Path $SupersedeStagingDate 'trigger-c-preparation.json') -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'supersede-work-order-carries-cover-contract' ([string]$supersedeState.WorkOrder.NativeAssets.RequiredCoverBriefVersion-ceq'APL Cover Brief v1.1'-and[string]$supersedeState.WorkOrder.NativeAssets.RequiredCoverBriefScanDate-ceq$SupersedeDate-and[string]$supersedeState.WorkOrder.NativeAssets.RequiredCoreMarketThesis-ceq$revisedThesis)
  $afterHashes=@(@($input,$gainers,$market)|ForEach-Object{(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash})
  Add-Result 'intake-sources-unchanged' (-not(Compare-Object $sourceHashes $afterHashes))
}catch{
  Add-Result 'test-harness' $false $_.Exception.Message
}finally{
  $cleanupPaths=@($FixtureRoot)
  if($ownsReservedDates){
    $cleanupPaths+=@($StagingDate,$ManagedDate,$SupersedeStagingDate,$SupersedeManagedDate)
    $cleanupPaths+=@(Get-ChildItem -LiteralPath $RejectedStagingRoot -Directory -ErrorAction SilentlyContinue|Where-Object{$_.Name.StartsWith($SupersedeDate+'-')-and$initialRejectedPaths-notcontains$_.FullName}|ForEach-Object{$_.FullName})
  }
  foreach($path in $cleanupPaths){
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
