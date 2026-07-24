[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$ProjectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$Script=Join-Path $ProjectRoot 'tools\prepare_trigger_c_managed_inputs.ps1'
$Runner=Join-Path $ProjectRoot 'tools\run_daily_production.ps1'
$ScanDate='2040-02-07'
$SupersedeDate='2040-02-08'
$FixtureRoot=Join-Path $ProjectRoot ("tmp\trigger-c-builder-fixture-"+[guid]::NewGuid().ToString('N'))
$BuilderRoot=Join-Path $ProjectRoot 'tmp\trigger-c-managed-input-builder'
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
    "publishing\production-package\APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.html",
    "publishing\production-package\WhatsApp_$ScanDate.md"
  )
  Add-Result 'no-placeholder-artifacts-created' (@($forbiddenCreated|Where-Object{Test-Path -LiteralPath (Join-Path $StagingDate $_)}).Count-eq0)

  $previous=$ErrorActionPreference
  $ErrorActionPreference='Continue'
  $finalize=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script -RegressionTest -Mode Finalize -ScanDate $ScanDate 2>&1)
  $finalizeExit=$LASTEXITCODE
  $ErrorActionPreference=$previous
  $finalizeText=$finalize-join' '
  Add-Result 'incomplete-work-order-finalize-fails-closed' ($finalizeExit-ne0-and$finalizeText.Contains('Required file does not exist')-and$finalizeText.Contains('table-card-')) $finalizeText
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
  $leaderRows=@(for($i=0;$i-lt3;$i++){$row=$ranking[$i];[ordered]@{rank="#$($i+1)";symbol=[string]$row.Symbol;companyName=[string]$row.Name;coreBusiness='企業營運與市場服務';mainDriver='相對強勢及盈利能見度';compositeScore=[double]$row.'Composite Score'}})
  $leaders=[ordered]@{SchemaVersion='APL Table Card Input v1.1';CardType='TopLeaders';Title='領導公司';Rows=$leaderRows}
  $gainersCard=[ordered]@{SchemaVersion='APL Table Card Input v1.1';CardType='TopGainers';Title='最近7日 Top Gainers';Rows=@(
    [ordered]@{symbol='T001';companyName='Alpha Research 1';sectorTheme='市場服務';changePct='+12.5%'},
    [ordered]@{symbol='T002';companyName='Alpha Research 2';sectorTheme='市場服務';changePct='+10.25%'},
    [ordered]@{symbol='T003';companyName='Alpha Research 3';sectorTheme='市場服務';changePct='+8%'}
  )}
  $sectorCard=[ordered]@{SchemaVersion='APL Table Card Input v1.1';CardType='SectorStructure';Title='產業結構';Rows=@(
    [ordered]@{theme='選擇性領導';count=3;direction='盈利能見度支持群組形成';representativeSymbols=(@($ranking|Select-Object -First 3|ForEach-Object{$_.Symbol})-join', ')}
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
  $overviewValues="Universe $($meta.universe)，Qualified $($meta.qualified)，Leaders $($meta.leaders)，Leader Lock $($meta.leaderLock)，Removed $($meta.removedBelowSma200Count)，Final Watchlist $($meta.finalWatchlistCount)，Average Momentum $($meta.averageMomentum)，Average Buyability $($meta.averageBuyability)。"
  $sections=[ordered]@{
    'Executive Summary'='能源與利率門檻提高後，市場沒有全面失去領導力，但資金更重視盈利能見度、現金流及資本效率。本文沿同一命題檢查短線與中期證據，並評估成交參與能否確認新結構。'
    'Market Context'='能源利率重估令企業成本與估值折現率同步受壓，市場因此不再只追逐表面增長，而是比較盈利兌現、自由現金流及管理層資本配置。這個結構變化令指數表現不足以解釋個別領導公司的相對強勢，因此需要進一步觀察量化領導股。'
    '為什麼要看 APL Momentum Leaders 領導股？'='當主要指數同時包含受壓與受惠公司，只看平均升跌會掩蓋資金真正選擇。領導股排名把相對強度、趨勢及參與度放在同一框架，讓分析可以判斷資金是否正建立新的中期方向。'
    'Deep-Scan Overview'=($overviewValues+' 整體數據顯示領導力仍然存在，但並非所有公司同步上升。數量與平均分數只用來判斷結構是否成立，下一步仍要比較短線升幅榜與中期排名是否指向相同風險取態。')
    '最近7日 Top Gainers'='TradingView短線資料顯示T001、T002及T003位於升幅前列，反映資金願意追逐具催化因素的公司。短線價格領導提供即時風險偏好證據，但單周升幅不能單獨證明中期趨勢，因此需要與Momentum Leaders排名對照。'
    'Momentum Leaders Analysis'='中期排名顯示領導公司同時保持相對強勢與較完整趨勢，資金不是無差別追價，而是集中於盈利路徑較清晰及資本效率較高的企業。這項結果承接短線證據，並帶出個股強勢能否形成群組。'
    'Sector Analysis'='由個股推進至群組後，可見選擇性領導並非單一偶然事件。代表公司在相近市場條件下維持強勢，說明資金正以盈利品質與催化因素組成新的結構，但群組能否成為主線仍需成交參與確認。'
    'Relative Volume / Market Activity'='成交與相對活躍度是確認領導結構的重要證據。若價格領導伴隨持續市場參與，群組延續機率較高；若成交迅速退潮，則目前結論只代表短期集中，而不是可靠的資金轉移。'
    'Risk'='核心命題可能被能源成本回落、利率預期逆轉、盈利不及預期或成交參與消失推翻。若領導公司失去相對強度並跌回主要趨勢下方，市場便可能重新回到指數主導而非選擇性領導。'
    'Deep-Scan Conclusion'='能源利率重估確實提高市場定價門檻，但量化結果仍顯示選擇性領導存在。最終判斷不是全面避險，而是資金轉向盈利能見度較高的公司；下一個確認訊號是成交參與與群組廣度能否持續。'
  }
  $sectionMinimum=[ordered]@{'Executive Summary'=80;'Market Context'=160;'為什麼要看 APL Momentum Leaders 領導股？'=120;'Deep-Scan Overview'=120;'最近7日 Top Gainers'=150;'Momentum Leaders Analysis'=180;'Sector Analysis'=120;'Relative Volume / Market Activity'=120;'Risk'=120;'Deep-Scan Conclusion'=120}
  $supportingSentence='這項證據必須與上一節的判斷連接，才能辨認資金選擇是否具有持續性，並為下一個分析問題建立可驗證的方向。'
  foreach($heading in $sectionMinimum.Keys){while(([string]$sections[$heading]).Length-lt([int]$sectionMinimum[$heading]+20)){$sections[$heading]=([string]$sections[$heading]+' '+$supportingSentence)}}
  $title='APL Deep Scan 市場領導分析'
  $markdown=New-Object Collections.Generic.List[string]
  $html=New-Object Collections.Generic.List[string]
  $markdown.Add("# $title");$markdown.Add('')
  $html.Add("<h1>$title</h1>")
  foreach($heading in $sections.Keys){$markdown.Add("## $heading");$markdown.Add('');$markdown.Add([string]$sections[$heading]);$markdown.Add('');$html.Add("<h3>$heading</h3>");$html.Add("<p>$($sections[$heading])</p>")}
  $package=Join-Path $StagingDate 'publishing\production-package'
  Write-Utf8 (Join-Path $package "APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.md") ($markdown-join[Environment]::NewLine)
  Write-Utf8 (Join-Path $package "APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.html") ($html-join[Environment]::NewLine)
  Write-Utf8 (Join-Path $package "WhatsApp_$ScanDate.md") ('能源利率重估正在提高估值與盈利門檻，市場資金轉向盈利能見度及資本效率較清晰的公司。量化領導股仍然存在，但成交參與尚需持續確認。短線升幅與中期排名共同顯示選擇性領導，而不是所有風險資產同步上升。投資者下一步應觀察相對強度、成交活躍度及群組廣度，並留意能源成本、利率預期及企業盈利變化可能推翻目前判斷。領導公司若能維持趨勢、成交與群組廣度，才足以確認資金已經建立新的中期方向；若相對強度迅速消失，則目前訊號只屬短期輪動。分析必須同時比較市場背景、價格表現、公司業務與風險條件，不能因單一指標改善便忽略反證。這份分析只用於市場研究及風險觀察，不構成個別證券投資建議。')
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
    overlay=[ordered]@{kicker='APL DEEP SCAN';titleLines=@('能源門檻提高','選擇性領導');subtitle='市場重新檢驗盈利能見度';series='APL US STOCK';date=$ScanDate;footer='Deep Scan'}
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
  $runnerOutput=@(& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Runner -RegressionTest `
    -InputCsv (Join-Path $ManagedDate 'source.csv') -TopGainersCsvPath (Join-Path $ManagedDate 'top-gainers.csv') `
    -MarketContextPath (Join-Path $ManagedDate 'market-context.md') -TriggerBMetaPath (Join-Path $ManagedDate "trigger-b\$ScanDate\APL_Momentum_Leaders_Meta_$ScanDate.json") `
    -TableCardManifestPath (Join-Path $ManagedDate 'table-card-manifest.json') -CoverBriefPath (Join-Path $ManagedDate 'cover-brief.json') `
    -CoverBackgroundPath (Join-Path $ManagedDate 'cover-background.png') -SeoBackgroundPath (Join-Path $ManagedDate 'seo-background.png') `
    -CoverNativeContractPath (Join-Path $ManagedDate 'cover-native-contract.json') -SeoNativeContractPath (Join-Path $ManagedDate 'seo-native-contract.json') `
    -PublishingArtifactsRoot (Join-Path $ManagedDate 'publishing') -ScanDate $ScanDate -WeekLabel 'Regression' -OutputRoot $productionRoot 2>&1)
  Add-Result 'daily-production-consumes-finalized-bundle' ($LASTEXITCODE-eq0) ($runnerOutput-join' ')
  $dailyState=Get-Content -LiteralPath (Join-Path $productionRoot "logs\daily-production-state-$ScanDate.json") -Raw -Encoding UTF8|ConvertFrom-Json
  Add-Result 'daily-production-complete' ($dailyState.DailyProductionComplete-eq$true-and[string]$dailyState.Status-ceq'PASS')
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
    if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path -Recurse -Force}
  }
}

$failed=@($results|Where-Object{-not$_.Passed})
[pscustomobject]@{Passed=($failed.Count-eq0);Total=$results.Count;Failed=$failed.Count;Results=[object[]]$results.ToArray()}|ConvertTo-Json -Depth 5
if($failed.Count-gt0){exit 1}
