[CmdletBinding()]
param([string]$HelperPath)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
if (-not $HelperPath) { $HelperPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\article-ready-notification.ps1' }
. $HelperPath
$date = [DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(8)).ToString('yyyy-MM-dd')
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('apl-article-ready-test-' + [guid]::NewGuid().ToString('N'))
$encoding = New-Object Text.UTF8Encoding($false)
$checks = 0
function Assert-Result([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "TEST FAILED: $Message" }
  $script:checks++
}
function Write-TestFile([string]$Path, [string]$Text) {
  [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
  [IO.File]::WriteAllText($Path, $Text, $encoding)
}
function Write-TestJson([string]$Path, [object]$Value) { Write-TestFile $Path ($Value | ConvertTo-Json -Depth 12) }
function New-TestFixture([string]$Project) {
  $root = Join-Path $testRoot $Project
  Write-TestJson (Join-Path $root 'tools\article-ready-notification.json') @{schemaVersion=1;recipient='pm81520@gmail.com';transport='disabled';deliveryEnabled=$false}
  if ($Project -ceq 'DeepScan') {
    $base = Join-Path $root "outputs\$date\production-package"
    $md = Join-Path $base "APL_Momentum_Leaders_Market_Analysis_Blog_$date.md"
    $html = Join-Path $base "APL_Momentum_Leaders_Market_Analysis_Blog_$date.html.txt"
    $state = Join-Path $root "outputs\logs\daily-production-state-$date.json"
    $audit = Join-Path $root "outputs\$date\Final_Production_Audit_$date.json"
  } else {
    $base = Join-Path $root ("Archive\{0}\{1}\{2}" -f $date.Substring(0,4),$date.Substring(5,2),$date)
    $md = Join-Path $base "gold-analysis-$date.md"
    $html = Join-Path $base "blog-content-$date.txt"
    $state = Join-Path $base 'today-analysis-state.json'
    $audit = $null
  }
  Write-TestFile $md "# A complete fixture article`n`nA source-bound test paragraph."
  if($Project-ceq'DeepScan'-and$date-cge'2026-10-20'){
    . (Join-Path (Split-Path -Parent $HelperPath) 'client_article_html.ps1')
    Write-TestFile $html (ConvertTo-AplStyledArticle '<h3>Executive Summary｜執行摘要</h3><p>A source-bound test paragraph.</p>')
  }elseif($Project-ceq'DeepScan'-and$date-cge'2026-10-13'){Write-TestFile $html '<h3>Executive Summary｜執行摘要</h3><p>A source-bound test paragraph.</p>'}else{Write-TestFile $html '<h1>A complete fixture article</h1><p>A source-bound test paragraph.</p>'}
  $fixture = [pscustomobject]@{Project=$Project;Root=$root;Markdown=$md;Html=$html;State=$state;Audit=$audit}
  Set-TestEvidence $fixture
  return $fixture
}
function Set-TestEvidence([object]$Fixture) {
  if ($Fixture.Project -ceq 'DeepScan') {
    $records = @()
    foreach ($path in @($Fixture.Markdown,$Fixture.Html)) {
      $relative = $path.Substring((Join-Path $Fixture.Root "outputs\$date").Length + 1).Replace('\','/')
      $records += @{Status='PASS';Files=@(@{RelativePath=$relative;Size=(Get-Item -LiteralPath $path).Length;SHA256=(Get-FileHash -LiteralPath $path).Hash})}
    }
    Write-TestJson $Fixture.Audit @{ScanDate=$date;Status='PASS';EditorialCompletion=@{Status='PASS';ProductionReadiness=$true;DailyProductionPublishable=$true};Required=$records}
    Write-TestJson $Fixture.State @{SchemaVersion='APL Daily Production State v1.0';ScanDate=$date;Status='PASS';DailyProductionComplete=$true;DailyProductionPublishable=$true;FinalProductionAudit=$Fixture.Audit}
  } else {
    Write-TestJson $Fixture.State @{date=$date;phase='TodayAnalysis';runner_status='PASS';status='Awaiting Paragraph Images';metadata_status='Awaiting Paragraph Images';paragraph_image_count=0;completed_manifest_present=$false;images=@(@{file='cover.png'},@{file='seo.png'})}
  }
}
function Invoke-TestEvent([object]$Fixture, [switch]$DryRun, [switch]$RegressionTest, [string]$Date=$date) {
  Invoke-AplArticleReadyEvent -Project $Fixture.Project -ScanDate $Date -ProjectRoot $Fixture.Root -CompletionStatePath $Fixture.State -ExpectedArticleHash (Get-FileHash -LiteralPath $Fixture.Markdown).Hash -ExpectedHtmlHash (Get-FileHash -LiteralPath $Fixture.Html).Hash -DryRun:$DryRun -RegressionTest:$RegressionTest
}
try {
  $configurationRoot=Join-Path $testRoot 'Configuration'
  $baseConfig=Join-Path $configurationRoot 'tools\article-ready-notification.json'
  $localConfig=Join-Path $configurationRoot 'tools\article-ready-notification.local.json'
  $disabledConfig=@{schemaVersion=1;recipient='pm81520@gmail.com';transport='disabled';deliveryEnabled=$false;receiverReady=$false}
  Write-TestJson $baseConfig $disabledConfig
  $loaded=Get-AplArticleReadyConfiguration -ProjectRoot $configurationRoot
  Assert-Result ($loaded.transport -ceq 'disabled' -and -not $loaded.deliveryEnabled -and -not $loaded.receiverReady) 'new clone without local override stays disabled'
  Write-TestJson $localConfig @{schemaVersion=1;recipient='pm81520@gmail.com';transport='agent-gmail';deliveryEnabled=$true;receiverReady=$true}
  $loaded=Get-AplArticleReadyConfiguration -ProjectRoot $configurationRoot
  Assert-Result ($loaded.transport -ceq 'agent-gmail' -and $loaded.deliveryEnabled -and $loaded.receiverReady) 'local configuration preserves enabled machine settings'
  Assert-Result ((Get-Content -LiteralPath $baseConfig -Raw|ConvertFrom-Json).transport -ceq 'disabled') 'local activation never rewrites repository defaults'
  Write-TestJson $localConfig @{schemaVersion=1;recipient='unapproved@example.invalid';transport='agent-gmail';deliveryEnabled=$true;receiverReady=$true}
  $rejected=$false;try{Get-AplArticleReadyConfiguration -ProjectRoot $configurationRoot|Out-Null}catch{$rejected=$true}
  Assert-Result $rejected 'local override cannot replace approved recipient'
  Write-TestJson $localConfig @{schemaVersion=1;recipient='pm81520@gmail.com';transport='agent-gmail';deliveryEnabled='true';receiverReady=$true}
  $rejected=$false;try{Get-AplArticleReadyConfiguration -ProjectRoot $configurationRoot|Out-Null}catch{$rejected=$true}
  Assert-Result $rejected 'local override rejects non-boolean activation flags'
  Write-TestFile $localConfig '{'
  $rejected=$false;try{Get-AplArticleReadyConfiguration -ProjectRoot $configurationRoot|Out-Null}catch{$rejected=$true}
  Assert-Result $rejected 'malformed local configuration fails closed'
  foreach ($project in @('DeepScan','GoldMap')) {
    $f = New-TestFixture $project
    $dry = Invoke-TestEvent $f -DryRun
    Assert-Result ($dry.Status -ceq 'DRY_RUN_PASS') "$project dry-run passes"
    Assert-Result (-not (Test-Path -LiteralPath (Join-Path $f.Root 'work'))) "$project dry-run creates no outbox"
    $first = Invoke-TestEvent $f
    Assert-Result ($first.Status -ceq 'QUEUED_DISABLED') "$project stable completed article queues metadata"

    $handoffArgs=@{Project=$project;ScanDate=$date;ProjectRoot=$f.Root;CompletionStatePath=$f.State;ExpectedArticleHash=(Get-FileHash -LiteralPath $f.Markdown -Algorithm SHA256).Hash;ExpectedHtmlHash=(Get-FileHash -LiteralPath $f.Html -Algorithm SHA256).Hash}
    $initialInspect=Invoke-AplArticleReadyDelivery -Mode Inspect -ProjectRoot $f.Root -EventId $first.EventId
    Assert-Result ($null -ne $initialInspect.PSObject.Properties['Reason'] -and $null -eq $initialInspect.Reason) "$project initial Inspect reason is strict-mode safe"
    $normal=Invoke-AplArticleReadyHandoff @handoffArgs
    Assert-Result ($normal.EventId -ceq $first.EventId -and $normal.EventPath -ceq $first.EventPath -and $normal.DeliveryStatus -ceq 'PENDING' -and $normal.DeliveryReason -ceq 'RECEIVER_NOT_READY') "$project normal completion records pending handoff"
    $recordedInspect=Invoke-AplArticleReadyDelivery -Mode Inspect -ProjectRoot $f.Root -EventId $first.EventId
    Assert-Result ($recordedInspect.Reason -ceq 'RECEIVER_NOT_READY') "$project Inspect returns stored blocker under strict mode"
    $recovery=Invoke-AplArticleReadyHandoff @handoffArgs
    Assert-Result ($recovery.DeliveryActionRequired -and $recovery.EventId -ceq $normal.EventId) "$project recovery reuses event without sending"
    $firstHash = (Get-FileHash -LiteralPath $first.EventPath).Hash
    $second = Invoke-TestEvent $f
    Assert-Result ($second.Status -ceq 'ALREADY_QUEUED') "$project duplicate version suppressed"
    Assert-Result ((Get-FileHash -LiteralPath $first.EventPath).Hash -ceq $firstHash) "$project event unchanged on retry"
    $event = Get-Content -LiteralPath $first.EventPath -Raw | ConvertFrom-Json
    Assert-Result ($event.date -ceq $date -and $event.schemaVersion -eq 1 -and $event.status -ceq 'ARTICLE_READY') "$project HK date and schema"
    Assert-Result ($event.artifactHashes.markdown -ceq (Get-FileHash -LiteralPath $f.Markdown).Hash.ToLowerInvariant()) "$project exact content hash"
    Assert-Result ($event.PSObject.Properties.Name.Count -eq 8 -and $null -eq $event.PSObject.Properties['body']) "$project metadata only"
    $disabled=Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $first.EventId -VerifiedSender 'pm81520@gmail.com'
    Assert-Result ($disabled.Status -ceq 'PENDING') "$project disabled sender does not claim or send"
    $pending=Invoke-AplArticleReadyDelivery -Mode Pending -ProjectRoot $f.Root -EventId $first.EventId -Reason GMAIL_TOOL_UNAVAILABLE
    Assert-Result ($pending.Status -ceq 'PENDING' -and $null -eq $pending.GmailMessageId) ("$project absent connector remains pending: " + ($pending | ConvertTo-Json -Compress))
    Write-TestJson (Join-Path $f.Root 'tools\article-ready-notification.json') @{schemaVersion=1;recipient='pm81520@gmail.com';transport='agent-gmail';deliveryEnabled=$true;receiverReady=$true}
    $freshReason=Invoke-AplArticleReadyDelivery -Mode Pending -ProjectRoot $f.Root -EventId $first.EventId -Reason AGENT_CONTINUATION_REQUIRED
    $enabledHandoff=Invoke-AplArticleReadyHandoff @handoffArgs
    Assert-Result ($enabledHandoff.DeliveryStatus -ceq 'PENDING' -and $enabledHandoff.DeliveryReason -ceq 'AGENT_CONTINUATION_REQUIRED') "$project enabled completion explicitly needs agent"
    $badSender=Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $first.EventId -VerifiedSender 'wrong@example.invalid'
    Assert-Result ($badSender.Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project wrong sender rejected"
    $claim=Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $first.EventId -VerifiedSender 'pm81520@gmail.com'
    Assert-Result ($claim.Status -ceq 'CLAIMED' -and $claim.ClaimToken -match '^[a-f0-9]{32}$') "$project exclusive durable claim"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $first.EventId -VerifiedSender 'pm81520@gmail.com').Status -ceq 'BLOCKED_CLAIMED') "$project second agent cannot claim same event"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode BeginSend -ProjectRoot $f.Root -EventId $first.EventId -ClaimToken 'wrong').Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project claim token required"
    $begin=Invoke-AplArticleReadyDelivery -Mode BeginSend -ProjectRoot $f.Root -EventId $first.EventId -ClaimToken $claim.ClaimToken
    Assert-Result ($begin.Status -ceq 'SENDING') "$project attempt durable before connector invocation"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode BeginSend -ProjectRoot $f.Root -EventId $first.EventId -ClaimToken $claim.ClaimToken).Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project second attempt prohibited"
    $proof=Join-Path $f.Root 'work\article-ready-outbox\tool-results\fixture-gmail-result.json'
    Write-TestJson $proof @{isError=$false;structuredContent=@{}}
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode Confirm -ProjectRoot $f.Root -EventId $first.EventId -ClaimToken $claim.ClaimToken -GmailReceiptPath $proof).Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project no message ID means no delivery success"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode MarkUnknown -ProjectRoot $f.Root -EventId $first.EventId -ClaimToken $claim.ClaimToken).Status -ceq 'UNCERTAIN') "$project timeout becomes uncertain"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $first.EventId -VerifiedSender 'pm81520@gmail.com').Status -ceq 'BLOCKED_UNCERTAIN') "$project unknown outcome never auto-resends"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode ReleaseBeforeSend -ProjectRoot $f.Root -EventId $first.EventId -ClaimToken $claim.ClaimToken).Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project attempted send cannot be released"
    $uncertainHandoff=Invoke-AplArticleReadyHandoff @handoffArgs
    Assert-Result ($uncertainHandoff.DeliveryStatus -ceq 'UNCERTAIN') "$project handoff preserves unknown send"
    Write-TestJson $proof @{isError=$false;structuredContent=@{id='fixture-message';payload=@{headers=@(@{name='Subject';value='Wrong subject'},@{name='From';value='pm81520@gmail.com'},@{name='To';value='pm81520@gmail.com'});body=@{content=($event|ConvertTo-Json -Depth 6)}}}}
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode Reconcile -ProjectRoot $f.Root -EventId $first.EventId -GmailReceiptPath $proof).Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project unrelated Gmail result cannot reconcile"
    Write-TestJson $proof @{isError=$false;structuredContent=@{id='fixture-message';payload=@{headers=@(@{name='Subject';value=$claim.Subject},@{name='From';value='Mike <pm81520@gmail.com>'},@{name='To';value='pm81520@gmail.com'});body=@{content=('<pre>'+[Net.WebUtility]::HtmlEncode(($event|ConvertTo-Json -Depth 6))+'</pre>')}}}}
    $confirmed=Invoke-AplArticleReadyDelivery -Mode Reconcile -ProjectRoot $f.Root -EventId $first.EventId -GmailReceiptPath $proof
    Assert-Result ($confirmed.Status -ceq 'SENT' -and $confirmed.GmailMessageId -ceq 'fixture-message') "$project exact message read reconciles confirmed receipt"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $first.EventId -VerifiedSender 'pm81520@gmail.com').Status -ceq 'BLOCKED_SENT') "$project receipt suppresses later send"
    $sentHandoff=Invoke-AplArticleReadyHandoff @handoffArgs
    Assert-Result ($sentHandoff.DeliveryStatus -ceq 'SENT' -and -not $sentHandoff.DeliveryActionRequired) "$project recovery of sent event never sends again"
    $testEvent=New-AplArticleReadyTestEvent -ProjectRoot $f.Root -Project $project
    Assert-Result ($testEvent.Subject.StartsWith('[APL ArticleReady TEST] ') -and $testEvent.Status -ceq 'TEST_ONLY') "$project TEST uses separate subject and status"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $testEvent.EventId -VerifiedSender 'pm81520@gmail.com').Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project TEST cannot enter production delivery"
    Write-TestJson (Join-Path $f.Root 'tools\article-ready-notification.json') @{schemaVersion=1;recipient='pm81520@gmail.com';transport='agent-gmail';deliveryEnabled=$false;receiverReady=$true}
    $testClaim=Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $testEvent.EventId -VerifiedSender 'pm81520@gmail.com' -AllowTest
    Assert-Result ($testClaim.Status -ceq 'CLAIMED') "$project explicit TEST claim supports wiring test"
    $release=Invoke-AplArticleReadyDelivery -Mode ReleaseBeforeSend -ProjectRoot $f.Root -EventId $testEvent.EventId -ClaimToken $testClaim.ClaimToken -AllowTest -Reason GMAIL_TOOL_UNAVAILABLE
    Assert-Result ($release.Status -ceq 'PENDING' -and $null -eq $release.GmailMessageId) "$project pre-send missing capability safely releases claim"
    $testClaim=Invoke-AplArticleReadyDelivery -Mode Claim -ProjectRoot $f.Root -EventId $testEvent.EventId -VerifiedSender 'pm81520@gmail.com' -AllowTest
    Write-TestJson (Join-Path $f.Root 'tools\article-ready-notification.json') @{schemaVersion=1;recipient='pm81520@gmail.com';transport='disabled';deliveryEnabled=$false;receiverReady=$false}
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode BeginSend -ProjectRoot $f.Root -EventId $testEvent.EventId -ClaimToken $testClaim.ClaimToken -AllowTest).Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project disable after claim prevents send"
    Write-TestJson (Join-Path $f.Root 'tools\article-ready-notification.json') @{schemaVersion=1;recipient='pm81520@gmail.com';transport='agent-gmail';deliveryEnabled=$true;receiverReady=$true}
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode BeginSend -ProjectRoot $f.Root -EventId $testEvent.EventId -ClaimToken $testClaim.ClaimToken -AllowTest).Status -ceq 'SENDING') "$project explicit TEST attempt"
    Write-TestJson $proof @{isError=$false;structuredContent=@{id='fixture-test-message'}}
    $testConfirmed=Invoke-AplArticleReadyDelivery -Mode Confirm -ProjectRoot $f.Root -EventId $testEvent.EventId -ClaimToken $testClaim.ClaimToken -GmailReceiptPath $proof -AllowTest
    Assert-Result ($testConfirmed.Status -ceq 'SENT' -and $testConfirmed.GmailMessageId -ceq 'fixture-test-message') "$project successful connector ID persisted"
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode Confirm -ProjectRoot $f.Root -EventId $testEvent.EventId -ClaimToken $testClaim.ClaimToken -GmailReceiptPath $proof -AllowTest).Status -ceq 'SENT') "$project repeat confirmation is idempotent"
    Write-TestJson $proof @{isError=$false;structuredContent=@{id='different-fixture-message'}}
    Assert-Result ((Invoke-AplArticleReadyDelivery -Mode Confirm -ProjectRoot $f.Root -EventId $testEvent.EventId -ClaimToken $testClaim.ClaimToken -GmailReceiptPath $proof -AllowTest).Status -ceq 'DELIVERY_PROTOCOL_ERROR') "$project sent receipt cannot be replaced with another message"
    Write-TestJson (Join-Path $f.Root 'tools\article-ready-notification.json') @{schemaVersion=1;recipient='pm81520@gmail.com';transport='disabled';deliveryEnabled=$false;receiverReady=$false}
    $completionHashBefore = (Get-FileHash -LiteralPath $f.State).Hash
    $outboxLock = New-Object IO.FileStream((Join-Path $f.Root 'work\article-ready-outbox\.enqueue.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try { $busy = Invoke-TestEvent $f } finally { $outboxLock.Dispose() }
    Assert-Result ($busy.Status -ceq 'NOTIFICATION_ERROR') "$project outbox contention is non-fatal"
    Assert-Result ((Get-FileHash -LiteralPath $f.State).Hash -ceq $completionHashBefore) "$project notification failure does not alter production state"
    Assert-Result ((Invoke-TestEvent $f).Status -ceq 'ALREADY_QUEUED') "$project contention recovery does not duplicate event"
    $held = New-Object IO.FileStream($f.Markdown,[IO.FileMode]::Open,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $locked = Invoke-AplArticleReadyEvent -Project $project -ScanDate $date -ProjectRoot $f.Root -CompletionStatePath $f.State -ExpectedArticleHash ('0'*64) -ExpectedHtmlHash ('0'*64) }
    finally { $held.Dispose() }
    Assert-Result ($locked.Status -ceq 'NOTIFICATION_ERROR') "$project writer in progress cannot emit ready"
    Write-TestFile $f.Markdown "# A revised complete fixture`n`nA second verified version."
    if ($project -ceq 'DeepScan') {
      $stale = Invoke-TestEvent $f
      Assert-Result ($stale.Status -ceq 'NOTIFICATION_ERROR') 'DeepScan stale audit rejects changed article'
    } else {
      $stale = Invoke-AplArticleReadyEvent -Project GoldMap -ScanDate $date -ProjectRoot $f.Root -CompletionStatePath $f.State -ExpectedArticleHash $event.artifactHashes.markdown -ExpectedHtmlHash $event.artifactHashes.html
      Assert-Result ($stale.Status -ceq 'NOTIFICATION_ERROR') 'GoldMap stale validated-source hash rejected'
    }
    Set-TestEvidence $f
    $revised = Invoke-TestEvent $f
    Assert-Result ($revised.Status -ceq 'QUEUED_DISABLED' -and $revised.EventId -cne $first.EventId) "$project revised verified version gets distinct event"
    $count = @(Get-ChildItem -LiteralPath (Split-Path -Parent $first.EventPath) -Filter '*.json').Count
    Assert-Result ($count -eq 2) "$project single event per version"
    $yesterday = [DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(8)).AddDays(-1).ToString('yyyy-MM-dd')
    Assert-Result ((Invoke-TestEvent $f -Date $yesterday).Status -ceq 'SKIPPED_NONCURRENT_HK_DATE') "$project yesterday is not reported as today"
    Assert-Result ((Invoke-TestEvent $f -RegressionTest).Status -ceq 'SKIPPED_REGRESSION') "$project regression suppressed"
    $stateBefore = [IO.File]::ReadAllBytes($f.State)
    Write-TestFile $f.State '{}'
    $failedHandoff=Invoke-AplArticleReadyHandoff @handoffArgs
    Assert-Result ($failedHandoff.DeliveryStatus -ceq 'PENDING' -and $failedHandoff.DeliveryReason -ceq 'NOTIFICATION_ERROR' -and -not $failedHandoff.DeliveryActionRequired) "$project notification failure returns without failing completion"
    Assert-Result ((Invoke-TestEvent $f).Status -ceq 'NOTIFICATION_ERROR') "$project incomplete state rejected"
    [IO.File]::WriteAllBytes($f.State,$stateBefore)
    if ($project -ceq 'GoldMap') {
      $fullManifest = Join-Path (Split-Path -Parent $f.State) 'production-manifest.json'
      Write-TestFile $fullManifest '{}'
      Assert-Result ((Invoke-TestEvent $f).Status -ceq 'NOTIFICATION_ERROR') 'GoldMap later full phase is not a duplicate TodayAnalysis event'
    }
    Assert-Result (@(Get-ChildItem -LiteralPath (Split-Path -Parent $first.EventPath) -Filter '*.json').Count -eq 2) "$project failures create no false ready"
  }
  Write-Output "ARTICLE_READY_NOTIFICATION_TEST_PASS Checks=$checks FixtureRoot=$testRoot"
} finally {
  # Cleanup only this verified GUID-scoped temporary fixture.
  $resolved = [IO.Path]::GetFullPath($testRoot)
  $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
  if ($resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolved) -match '^apl-article-ready-test-[a-f0-9]{32}$') {
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
  }
}
