# Local metadata only. No network, mail, credentials, or production mutations.

function Assert-AplNotificationPath {
  param([string]$Path, [string]$Root, [switch]$RequireFile)
  $full = [IO.Path]::GetFullPath($Path)
  $base = [IO.Path]::GetFullPath($Root).TrimEnd('\')
  if (-not ($full.Equals($base, [StringComparison]::OrdinalIgnoreCase) -or $full.StartsWith($base + '\', [StringComparison]::OrdinalIgnoreCase))) { throw 'Notification path escaped ProjectRoot.' }
  $walk = $full
  while ($walk -and $walk.Length -ge $base.Length) {
    if (Test-Path -LiteralPath $walk) {
      if (((Get-Item -LiteralPath $walk -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Notification paths must not use reparse points.' }
    }
    if ($walk.Equals($base, [StringComparison]::OrdinalIgnoreCase)) { break }
    $walk = Split-Path -Parent $walk
  }
  if ($RequireFile -and -not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Notification required file is missing: $full" }
  return $full
}

function Get-AplArticleReadyConfiguration {
  param([Parameter(Mandatory=$true)][string]$ProjectRoot)
  $root=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
  $basePath=Assert-AplNotificationPath (Join-Path $root 'tools\article-ready-notification.json') $root -RequireFile
  $localPath=Assert-AplNotificationPath (Join-Path $root 'tools\article-ready-notification.local.json') $root
  $paths=@($basePath)
  if(Test-Path -LiteralPath $localPath){$paths+=Assert-AplNotificationPath $localPath $root -RequireFile}
  $effective=$null
  foreach($path in $paths){
    $candidate=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)|ConvertFrom-Json
    if($null -eq $candidate -or $null -eq $candidate.PSObject.Properties['schemaVersion'] -or $candidate.schemaVersion -ne 1 -or
       $null -eq $candidate.PSObject.Properties['recipient'] -or $candidate.recipient -cne 'pm81520@gmail.com' -or
       $null -eq $candidate.PSObject.Properties['transport'] -or @('disabled','agent-gmail') -cnotcontains $candidate.transport -or
       $null -eq $candidate.PSObject.Properties['deliveryEnabled'] -or $candidate.deliveryEnabled -isnot [bool] -or
       ($null -ne $candidate.PSObject.Properties['receiverReady'] -and $candidate.receiverReady -isnot [bool])){
      throw 'Notification configuration is invalid; delivery remains blocked.'
    }
    $ready=$null -ne $candidate.PSObject.Properties['receiverReady'] -and $candidate.receiverReady -eq $true
    $effective=[pscustomobject]@{schemaVersion=1;recipient=$candidate.recipient;transport=$candidate.transport;deliveryEnabled=$candidate.deliveryEnabled;receiverReady=$ready}
  }
  # Routing flags are local configuration, not evidence of human authorization.
  return $effective
}

function Get-AplNotificationSha256 {
  param([byte[]]$Bytes)
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try { return [BitConverter]::ToString($algorithm.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
  finally { $algorithm.Dispose() }
}

function Invoke-AplArticleReadyEvent {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][ValidateSet('DeepScan','GoldMap')][string]$Project,
    [Parameter(Mandatory=$true)][string]$ScanDate,
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [Parameter(Mandatory=$true)][string]$CompletionStatePath,
    [string]$ExpectedArticleHash,
    [string]$ExpectedHtmlHash,
    [switch]$RegressionTest,
    [switch]$DryRun
  )
  # Called after the existing completion gate. Notification failure is non-fatal.
  Set-StrictMode -Version 2.0
  $ErrorActionPreference = 'Stop'
  $leases = New-Object System.Collections.Generic.List[System.IDisposable]
  $lockStream = $null
  $temporary = $null
  try {
    if ($RegressionTest) { return [pscustomobject]@{ Status='SKIPPED_REGRESSION'; Transport='DISABLED' } }
    $dateValue = [datetime]::ParseExact($ScanDate, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
    if ($dateValue.ToString('yyyy-MM-dd') -cne $ScanDate) { throw 'Invalid notification date.' }
    # Hong Kong is UTC+08:00 year-round, independent of the PC timezone.
    $hongKongDate = [DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(8)).ToString('yyyy-MM-dd')
    if ($ScanDate -cne $hongKongDate) { return [pscustomobject]@{ Status='SKIPPED_NONCURRENT_HK_DATE'; ScanDate=$ScanDate; HongKongDate=$hongKongDate; Transport='DISABLED' } }
    $root = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw 'Notification ProjectRoot is missing.' }
    $config = Get-AplArticleReadyConfiguration -ProjectRoot $root
    $transport = if ($config.transport -ceq 'agent-gmail' -and $config.deliveryEnabled -eq $true) { 'AGENT_REQUIRED' } else { 'DISABLED' }

    # Read leases prevent concurrent writers and replacements until event commit.
    $read = {
      param([string]$Path)
      $safe = Assert-AplNotificationPath $Path $root -RequireFile
      $stream = New-Object IO.FileStream($safe, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
      [void]$leases.Add($stream)
      if ($stream.Length -eq 0 -or $stream.Length -gt 20MB) { throw 'Notification source is empty or unexpectedly large.' }
      $memory = New-Object IO.MemoryStream
      try { $stream.CopyTo($memory); $bytes = $memory.ToArray() }
      finally { $memory.Dispose() }
      $encoding = New-Object Text.UTF8Encoding($false, $true)
      $text = $encoding.GetString($bytes).TrimStart([char]0xFEFF)
      return [pscustomobject]@{ Path=$safe; Bytes=$bytes; Text=$text; Hash=(Get-AplNotificationSha256 $bytes) }
    }
    $stateRecord = & $read $CompletionStatePath
    $state = $stateRecord.Text | ConvertFrom-Json
    $audit = $null
    if ($Project -ceq 'DeepScan') {
      if ($state.SchemaVersion -cne 'APL Daily Production State v1.0' -or $state.ScanDate -cne $ScanDate -or $state.Status -cne 'PASS' -or $state.DailyProductionComplete -ne $true -or $state.DailyProductionPublishable -ne $true) { throw 'DeepScan completion state is not current publishable PASS.' }
      $auditRecord = & $read ([string]$state.FinalProductionAudit)
      $audit = $auditRecord.Text | ConvertFrom-Json
      if ($audit.ScanDate -cne $ScanDate -or $audit.Status -cne 'PASS' -or $audit.EditorialCompletion.Status -cne 'PASS' -or $audit.EditorialCompletion.ProductionReadiness -ne $true -or $audit.EditorialCompletion.DailyProductionPublishable -ne $true) { throw 'DeepScan final editorial audit did not pass.' }
      $base = Join-Path $root "outputs\$ScanDate\production-package"
      $articlePath = Join-Path $base "APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.md"
      $htmlPath = Join-Path $base "APL_Momentum_Leaders_Market_Analysis_Blog_$ScanDate.html.txt"
    } else {
      $base = Join-Path $root ("Archive\{0}\{1}\{2}" -f $ScanDate.Substring(0,4),$ScanDate.Substring(5,2),$ScanDate)
      if ($stateRecord.Path -ine (Join-Path $base 'today-analysis-state.json')) { throw 'GoldMap state must be in the canonical daily Archive.' }
      if ($state.date -cne $ScanDate -or $state.phase -cne 'TodayAnalysis' -or $state.runner_status -cne 'PASS' -or $state.status -cne 'Awaiting Paragraph Images' -or $state.metadata_status -cne 'Awaiting Paragraph Images' -or $state.paragraph_image_count -ne 0 -or $state.completed_manifest_present -ne $false -or @($state.images).Count -ne 2) { throw 'GoldMap TodayAnalysis endpoint is incomplete.' }
      if (Test-Path -LiteralPath (Join-Path $base 'production-manifest.json')) { throw 'GoldMap TodayAnalysis must not contain a Complete manifest.' }
      if ($ExpectedArticleHash -cnotmatch '^[a-fA-F0-9]{64}$' -or $ExpectedHtmlHash -cnotmatch '^[a-fA-F0-9]{64}$') { throw 'GoldMap notification requires hashes of the validated source article and HTML.' }
      $articlePath = Join-Path $base "gold-analysis-$ScanDate.md"
      $htmlPath = Join-Path $base "blog-content-$ScanDate.txt"
    }
    $article = & $read $articlePath
    $html = & $read $htmlPath
    if($article.Text-notmatch'(?m)^#\s+\S'){throw 'Notification article title is missing.'}
    $titleHtml=$html.Text
    if($Project-ceq'DeepScan'-and$ScanDate-cge'2026-10-20'){
      . (Join-Path $PSScriptRoot 'client_article_html.ps1')
      Assert-AplStyledArticle -Html $titleHtml|Out-Null
      $titleHtml=ConvertTo-AplArticleBody $titleHtml
    }
    if($Project-ceq'DeepScan'-and$ScanDate-cge'2026-10-13'){if($titleHtml-match'(?is)<h1\b'-or$titleHtml-cnotmatch'(?s)^\s*<h3>Executive Summary｜執行摘要</h3>'){throw 'Full HTML must start with Executive Summary h3 and contain no h1 title.'}} elseif($html.Text-notmatch'<h1>[^<]+</h1>'){throw 'Notification HTML title is missing.'}
    if ($Project -ceq 'DeepScan') {
      foreach ($source in @($article,$html)) {
        $relative = $source.Path.Substring($root.Length + 1).Replace('\','/')
        $auditRelative = $relative.Substring(('outputs/' + $ScanDate + '/').Length)
        $matches = @($audit.Required | Where-Object { $_.Status -ceq 'PASS' } | ForEach-Object { $_.Files } | Where-Object { $_.RelativePath.Replace('\','/') -ceq $auditRelative })
        if ($matches.Count -ne 1 -or ([string]$matches[0].SHA256).ToLowerInvariant() -cne $source.Hash -or [long]$matches[0].Size -ne $source.Bytes.Length) { throw 'DeepScan article changed after its final audit.' }
      }
    } elseif ($article.Hash -cne $ExpectedArticleHash.ToLowerInvariant() -or $html.Hash -cne $ExpectedHtmlHash.ToLowerInvariant()) { throw 'GoldMap Archive articles do not match the validated source copy.' }

    $hashInput = $Project + "`n" + $ScanDate + "`n" + $article.Hash + "`n" + $html.Hash
    $versionHash = Get-AplNotificationSha256 ([Text.Encoding]::UTF8.GetBytes($hashInput))
    $id = $Project + '-' + $ScanDate + '-' + $versionHash
    $event = [ordered]@{
      schemaVersion=1; id=$id; project=$Project; date=$ScanDate
      versionHash=$versionHash; status='ARTICLE_READY'
      artifactPaths=[ordered]@{ markdown=$article.Path; html=$html.Path }
      artifactHashes=[ordered]@{ markdown=$article.Hash; html=$html.Hash }
    }
    if ($DryRun) { return [pscustomobject]@{ Status='DRY_RUN_PASS'; Event=[pscustomobject]$event; Transport='DISABLED'; WritesPerformed=$false } }
    $outbox = Assert-AplNotificationPath (Join-Path $root 'work\article-ready-outbox') $root
    $events = Assert-AplNotificationPath (Join-Path $outbox 'events') $root
    [IO.Directory]::CreateDirectory($events) | Out-Null
    Assert-AplNotificationPath $events $root | Out-Null
    # Short-lived process lock serializes enqueue; failure leaves production PASS.
    $lockPath = Assert-AplNotificationPath (Join-Path $outbox '.enqueue.lock') $root
    $lockStream = New-Object IO.FileStream($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    $eventPath = Assert-AplNotificationPath (Join-Path $events ($id + '.json')) $root
    $json = ($event | ConvertTo-Json -Depth 6) + "`n"
    if (Test-Path -LiteralPath $eventPath) {
      $existing = [IO.File]::ReadAllText($eventPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
      if ($existing.id -cne $id -or $existing.versionHash -cne $versionHash -or $existing.status -cne 'ARTICLE_READY' -or $existing.project -cne $Project -or $existing.date -cne $ScanDate -or $existing.artifactHashes.markdown -cne $article.Hash -or $existing.artifactHashes.html -cne $html.Hash -or $existing.artifactPaths.markdown -cne $article.Path -or $existing.artifactPaths.html -cne $html.Path) { throw 'Existing notification event is inconsistent; refusing to overwrite.' }
      return [pscustomobject]@{ Status='ALREADY_QUEUED'; EventId=$id; EventPath=$eventPath; Transport=$transport; WritesPerformed=$false }
    }
    $temporary = Join-Path $events ('.' + [guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllText($temporary, $json, (New-Object Text.UTF8Encoding($false)))
    [IO.File]::Move($temporary, $eventPath)
    $temporary = $null
    $queueStatus = if ($transport -ceq 'AGENT_REQUIRED') { 'QUEUED_AGENT_PENDING' } else { 'QUEUED_DISABLED' }
    return [pscustomobject]@{ Status=$queueStatus; EventId=$id; EventPath=$eventPath; Transport=$transport; WritesPerformed=$true }
  } catch {
    Write-Warning ('Article-ready metadata notification was not queued: ' + $_.Exception.Message)
    return [pscustomobject]@{ Status='NOTIFICATION_ERROR'; Transport='DISABLED'; Error=$_.Exception.Message; WritesPerformed=$false }
  } finally {
    if ($lockStream) { $lockStream.Dispose() }
    foreach ($lease in $leases) { $lease.Dispose() }
    if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
  }
}

# Agent-mediated delivery state only; this module never calls Gmail or the network.
function Invoke-AplArticleReadyDelivery {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][ValidateSet('Inspect','Pending','Claim','BeginSend','ReleaseBeforeSend','MarkUnknown','Confirm','Reconcile')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [Parameter(Mandatory=$true)][string]$EventId,
    [string]$VerifiedSender,
    [string]$ClaimToken,
    [string]$GmailReceiptPath,
    [ValidateSet('GMAIL_TOOL_UNAVAILABLE','GMAIL_AUTH_REQUIRED','RECEIVER_NOT_READY','SEND_OUTCOME_UNKNOWN','NO_EXACT_GMAIL_MATCH','AGENT_CONTINUATION_REQUIRED')][string]$Reason='GMAIL_TOOL_UNAVAILABLE',
    [switch]$AllowTest
  )
  Set-StrictMode -Version 2.0
  $ErrorActionPreference='Stop'
  $lock=$null; $eventLease=$null; $temporary=$null; $backup=$null; $replacementCommitted=$false
  try {
    if ($EventId -cnotmatch '^(TEST-)?(DeepScan|GoldMap)-\d{4}-\d{2}-\d{2}-[a-f0-9]{64}$') { throw 'Invalid article-ready EventId.' }
    $isTest=$EventId.StartsWith('TEST-', [StringComparison]::Ordinal)
    if ($isTest -and -not $AllowTest) { throw 'TEST event requires explicit AllowTest; production delivery is prohibited.' }
    $root=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
    $outbox=Assert-AplNotificationPath (Join-Path $root 'work\article-ready-outbox') $root
    $eventDirectory=if($isTest){'test-events'}else{'events'}
    $eventPath=Assert-AplNotificationPath (Join-Path (Join-Path $outbox $eventDirectory) ($EventId+'.json')) $root -RequireFile
    $eventLease=New-Object IO.FileStream($eventPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    $reader=New-Object IO.StreamReader($eventLease,[Text.Encoding]::UTF8,$true,1024,$true)
    try{$event=$reader.ReadToEnd()|ConvertFrom-Json}finally{$reader.Dispose()}
    $expectedStatus=if($isTest){'TEST_ONLY'}else{'ARTICLE_READY'}
    if($event.schemaVersion -ne 1 -or $event.id -cne $EventId -or $event.status -cne $expectedStatus -or @('DeepScan','GoldMap') -cnotcontains $event.project -or $event.versionHash -cnotmatch '^[a-f0-9]{64}$' -or @($event.PSObject.Properties).Count -ne 8){throw 'Invalid metadata event contract.'}
    $date=[datetime]::ParseExact($event.date,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture).ToString('yyyy-MM-dd')
    $idPrefix=if($isTest){'TEST-'}else{''}
    if($EventId -cne ($idPrefix+$event.project+'-'+$date+'-'+$event.versionHash)){throw 'EventId does not match metadata.'}
    $subjectPrefix=if($isTest){'[APL ArticleReady TEST] '}else{'[APL ArticleReady] '}
    $subject=$subjectPrefix+$event.project+' '+$date+' '+$EventId
    $config=Get-AplArticleReadyConfiguration -ProjectRoot $root
    $receipts=Assert-AplNotificationPath (Join-Path $outbox 'delivery-receipts') $root
    if($Mode -ceq 'Inspect' -and -not (Test-Path -LiteralPath $receipts)){
      return [pscustomobject]@{Status='PENDING';EventId=$EventId;Subject=$subject;Recipient=$config.recipient;EventPath=$eventPath;ReceiptPath=$null;GmailMessageId=$null;Reason=$null}
    }
    [IO.Directory]::CreateDirectory($receipts)|Out-Null
    Assert-AplNotificationPath $receipts $root|Out-Null
    $lockPath=Assert-AplNotificationPath (Join-Path $outbox '.delivery.lock') $root
    $lock=New-Object IO.FileStream($lockPath,[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $receiptPath=Assert-AplNotificationPath (Join-Path $receipts ($EventId+'.json')) $root
    $receipt=if(Test-Path -LiteralPath $receiptPath){[IO.File]::ReadAllText($receiptPath,[Text.Encoding]::UTF8)|ConvertFrom-Json}else{[pscustomobject][ordered]@{schemaVersion=1;eventId=$EventId;status='PENDING';claimToken=$null;sender=$null;recipient=$config.recipient;subject=$subject;gmailMessageId=$null;claimedUtc=$null;sendStartedUtc=$null;confirmedUtc=$null;updatedUtc=$null;reason=$null}}
    if($receipt.schemaVersion -ne 1 -or $receipt.eventId -cne $EventId -or $receipt.subject -cne $subject -or $receipt.recipient -cne $config.recipient -or @('PENDING','CLAIMED','SENDING','UNCERTAIN','SENT','SUPERSEDED') -cnotcontains $receipt.status){throw 'Invalid delivery receipt.'}
    if($Mode -ceq 'Inspect'){return [pscustomobject]@{Status=$receipt.status;EventId=$EventId;Subject=$subject;Recipient=$config.recipient;ReceiptPath=$receiptPath;GmailMessageId=$receipt.gmailMessageId;Reason=$receipt.reason}}
    $writeReceipt=$true
    $assertToken={if([string]::IsNullOrWhiteSpace($ClaimToken) -or $receipt.claimToken -cne $ClaimToken){throw 'Delivery claim token does not match.'}}
    $verifySources={
      if($isTest){
        if($event.artifactPaths.markdown -cne 'TEST_FIXTURE_ONLY' -or $event.artifactPaths.html -cne 'TEST_FIXTURE_ONLY' -or $event.artifactHashes.markdown -cne ('0'*64) -or $event.artifactHashes.html -cne ('0'*64)){throw 'TEST event must not reference production articles.'}
        return $true
      }
      if($date -cne [DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(8)).ToString('yyyy-MM-dd')){return $false}
      $expectedVersion=Get-AplNotificationSha256 ([Text.Encoding]::UTF8.GetBytes($event.project+"`n"+$date+"`n"+$event.artifactHashes.markdown+"`n"+$event.artifactHashes.html))
      if($expectedVersion -cne $event.versionHash){throw 'Event content-version hash is invalid.'}
      foreach($role in @('markdown','html')){
        $path=Assert-AplNotificationPath ([string]$event.artifactPaths.$role) $root -RequireFile
        if(([string]$event.artifactHashes.$role) -cnotmatch '^[a-f0-9]{64}$'){throw 'Invalid artifact hash.'}
        $lease=New-Object IO.FileStream($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        $algorithm=[Security.Cryptography.SHA256]::Create()
        try{$current=[BitConverter]::ToString($algorithm.ComputeHash($lease)).Replace('-','').ToLowerInvariant()}finally{$algorithm.Dispose();$lease.Dispose()}
        if($current -cne $event.artifactHashes.$role){return $false}
      }
      return $true
    }
    switch($Mode){
      'Pending' {if($receipt.status -cne 'PENDING'){throw 'Cannot reset a claimed, uncertain or sent delivery to pending.'};$receipt.reason=$Reason}
      'Claim' {
        if($receipt.status -cne 'PENDING'){return [pscustomobject]@{Status='BLOCKED_'+$receipt.status;EventId=$EventId;ReceiptPath=$receiptPath;GmailMessageId=$receipt.gmailMessageId}}
        $receiverReady=$null -ne $config.PSObject.Properties['receiverReady'] -and $config.receiverReady -eq $true
        if($config.transport -cne 'agent-gmail' -or (-not $isTest -and $config.deliveryEnabled -ne $true) -or -not $receiverReady){$receipt.reason='RECEIVER_NOT_READY'}
        elseif($VerifiedSender -cne 'pm81520@gmail.com'){throw 'Claim requires a fresh successful Gmail profile read for the approved sender.'}
        elseif(-not (& $verifySources)){$receipt.status='SUPERSEDED';$receipt.reason='ARTIFACT_OR_HK_DATE_CHANGED'}
        else{$receipt.status='CLAIMED';$receipt.claimToken=[guid]::NewGuid().ToString('N');$receipt.sender=$VerifiedSender;$receipt.claimedUtc=[DateTimeOffset]::UtcNow.ToString('o');$receipt.reason=$null}
      }
      'BeginSend' {& $assertToken;if($receipt.status -cne 'CLAIMED'){throw 'Only CLAIMED can begin one send attempt.'};if($config.transport -cne 'agent-gmail' -or (-not $isTest -and $config.deliveryEnabled -ne $true) -or $null -eq $config.PSObject.Properties['receiverReady'] -or $config.receiverReady -ne $true){throw 'Delivery or receiver was disabled after claim; do not send.'};if(-not (& $verifySources)){$receipt.status='SUPERSEDED';$receipt.reason='ARTIFACT_OR_HK_DATE_CHANGED'}else{$receipt.status='SENDING';$receipt.sendStartedUtc=[DateTimeOffset]::UtcNow.ToString('o')}}
      'ReleaseBeforeSend' {& $assertToken;if($receipt.status -cne 'CLAIMED' -or $receipt.sendStartedUtc){throw 'An attempted send cannot be released or retried blindly.'};$receipt.status='PENDING';$receipt.claimToken=$null;$receipt.reason=$Reason}
      'MarkUnknown' {& $assertToken;if(@('SENDING','UNCERTAIN') -cnotcontains $receipt.status){throw 'Only an attempted send can have unknown outcome.'};$receipt.status='UNCERTAIN';$receipt.reason='SEND_OUTCOME_UNKNOWN'}
      {$_ -ceq 'Confirm' -or $_ -ceq 'Reconcile'} {
        if($Mode -ceq 'Confirm'){& $assertToken;if(@('SENDING','UNCERTAIN','SENT') -cnotcontains $receipt.status){throw 'Confirmation requires a recorded send attempt.'}}
        elseif($receipt.status -ceq 'SUPERSEDED'){throw 'Superseded articles cannot be reconciled for new QA.'}
        $proofPath=Assert-AplNotificationPath $GmailReceiptPath $root -RequireFile
        $proof=[IO.File]::ReadAllText($proofPath,[Text.Encoding]::UTF8)|ConvertFrom-Json
        if($null -ne $proof.PSObject.Properties['isError'] -and $proof.isError -eq $true){throw 'Gmail error response is not a delivery receipt.'}
        if($null -eq $proof.PSObject.Properties['structuredContent']){throw 'A successful structured Gmail result with message ID is required.'}
        $message=$proof.structuredContent
        if($null -ne $message.PSObject.Properties['result']){$message=$message.result}
        if($null -eq $message.PSObject.Properties['id'] -or ([string]$message.id) -cnotmatch '^[A-Za-z0-9_-]{1,128}$'){throw 'Gmail message ID is absent; outcome remains unresolved.'}
        if($Mode -ceq 'Reconcile'){
          # Require a full Gmail message read, not a search hit or operator assertion.
          $headers=@{};foreach($header in $message.payload.headers){$headers[([string]$header.name).ToLowerInvariant()]=[string]$header.value}
          $from=New-Object Net.Mail.MailAddress($headers['from'])
          $to=New-Object Net.Mail.MailAddressCollection;$to.Add($headers['to'])
          if($headers['subject'] -cne $subject -or $from.Address -ine 'pm81520@gmail.com' -or $to.Count -ne 1 -or $to[0].Address -ine 'pm81520@gmail.com'){throw 'Gmail reconciliation headers do not match this approved event.'}
          $body=$message.payload.body
          $content=if($null -ne $body.PSObject.Properties['content']){[string]$body.content}else{
            $raw=[string]$body.data;$raw=$raw.Replace('-','+').Replace('_','/');$raw=$raw.PadRight($raw.Length+((4-$raw.Length%4)%4),'=');[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($raw))
          }
          $decoded=[Net.WebUtility]::HtmlDecode([regex]::Replace($content,'^\s*<pre>|</pre>\s*$',''))|ConvertFrom-Json
          if(@($decoded.PSObject.Properties).Count -ne 8 -or $decoded.schemaVersion -ne 1 -or $decoded.project -cne $event.project -or $decoded.date -cne $event.date -or $decoded.id -cne $event.id -or $decoded.versionHash -cne $event.versionHash -or $decoded.status -cne $event.status -or $decoded.artifactPaths.markdown -cne $event.artifactPaths.markdown -or $decoded.artifactPaths.html -cne $event.artifactPaths.html -or $decoded.artifactHashes.markdown -cne $event.artifactHashes.markdown -or $decoded.artifactHashes.html -cne $event.artifactHashes.html){throw 'Gmail reconciliation body does not match the metadata event.'}
        }
        if($receipt.status -ceq 'SENT' -and $receipt.gmailMessageId -cne [string]$message.id){throw 'Existing sent receipt cannot be replaced with another message ID.'}
        $receipt.status='SENT';$receipt.sender='pm81520@gmail.com';$receipt.gmailMessageId=[string]$message.id;$receipt.confirmedUtc=[DateTimeOffset]::UtcNow.ToString('o');$receipt.reason=$null
      }
    }
    $receipt.updatedUtc=[DateTimeOffset]::UtcNow.ToString('o')
    $temporary=Join-Path $receipts ('.'+[guid]::NewGuid().ToString('N')+'.tmp')
    [IO.File]::WriteAllText($temporary,($receipt|ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
    if(Test-Path -LiteralPath $receiptPath){$backup=Join-Path $receipts ('.'+[guid]::NewGuid().ToString('N')+'.bak');[IO.File]::Replace($temporary,$receiptPath,$backup,$true);$replacementCommitted=$true}else{[IO.File]::Move($temporary,$receiptPath)}
    $temporary=$null
    return [pscustomobject]@{Status=$receipt.status;EventId=$EventId;Subject=$subject;Recipient=$config.recipient;ClaimToken=$receipt.claimToken;ReceiptPath=$receiptPath;GmailMessageId=$receipt.gmailMessageId;Reason=$receipt.reason}
  }catch{
    return [pscustomobject]@{Status='DELIVERY_PROTOCOL_ERROR';EventId=$EventId;Error=$_.Exception.Message}
  }finally{
    if($replacementCommitted -and $backup -and [IO.File]::Exists($backup)){[IO.File]::Delete($backup)}
    if($lock){$lock.Dispose()};if($eventLease){$eventLease.Dispose()};if($temporary -and [IO.File]::Exists($temporary)){[IO.File]::Delete($temporary)}
  }
}

function New-AplArticleReadyTestEvent {
  [CmdletBinding()]
  param([Parameter(Mandatory=$true)][string]$ProjectRoot,[Parameter(Mandatory=$true)][ValidateSet('DeepScan','GoldMap')][string]$Project)
  $ErrorActionPreference='Stop'
  $root=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
  if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'Test event ProjectRoot is missing.'}
  $date=[DateTimeOffset]::UtcNow.ToOffset([TimeSpan]::FromHours(8)).ToString('yyyy-MM-dd')
  $hash=Get-AplNotificationSha256 ([Text.Encoding]::UTF8.GetBytes('TEST_ONLY-'+[guid]::NewGuid().ToString('N')))
  $id='TEST-'+$Project+'-'+$date+'-'+$hash
  $event=[ordered]@{schemaVersion=1;id=$id;project=$Project;date=$date;versionHash=$hash;status='TEST_ONLY';artifactPaths=[ordered]@{markdown='TEST_FIXTURE_ONLY';html='TEST_FIXTURE_ONLY'};artifactHashes=[ordered]@{markdown=('0'*64);html=('0'*64)}}
  $directory=Assert-AplNotificationPath (Join-Path $root 'work\article-ready-outbox\test-events') $root
  [IO.Directory]::CreateDirectory($directory)|Out-Null
  Assert-AplNotificationPath $directory $root|Out-Null
  $path=Join-Path $directory ($id+'.json')
  $temporary=Join-Path $directory ('.'+[guid]::NewGuid().ToString('N')+'.tmp')
  try{[IO.File]::WriteAllText($temporary,($event|ConvertTo-Json -Depth 6),(New-Object Text.UTF8Encoding($false)));[IO.File]::Move($temporary,$path)}finally{if([IO.File]::Exists($temporary)){[IO.File]::Delete($temporary)}}
  [pscustomobject]@{Status='TEST_ONLY';EventId=$id;EventPath=$path;Subject=('[APL ArticleReady TEST] '+$Project+' '+$date+' '+$id)}
}


# A shell queues metadata and reports handoff; it cannot wake a connector agent.
function Invoke-AplArticleReadyHandoff {
  [CmdletBinding()]
  param([ValidateSet('DeepScan','GoldMap')][string]$Project,[string]$ScanDate,
    [string]$ProjectRoot,[string]$CompletionStatePath,[string]$ExpectedArticleHash,
    [string]$ExpectedHtmlHash,[switch]$RegressionTest)
  $result=[ordered]@{EventId=$null;EventPath=$null;DeliveryActionRequired=$false;
    DeliveryStatus='PENDING';DeliveryReason='ENQUEUE_FAILED';DeliveryReceiptPath=$null;GmailMessageId=$null}
  try {
    $args=@{Project=$Project;ScanDate=$ScanDate;ProjectRoot=$ProjectRoot;CompletionStatePath=$CompletionStatePath;
      ExpectedArticleHash=$ExpectedArticleHash;ExpectedHtmlHash=$ExpectedHtmlHash;RegressionTest=$RegressionTest}
    $event=Invoke-AplArticleReadyEvent @args
    if (-not $event.PSObject.Properties['EventId']) {
      $result.DeliveryReason=$event.Status
      return [pscustomobject]$result
    }
    $result.EventId=$event.EventId; $result.EventPath=$event.EventPath
    $result.DeliveryActionRequired=$true
    $delivery=Invoke-AplArticleReadyDelivery -Mode Inspect -ProjectRoot $ProjectRoot -EventId $event.EventId
    if ($delivery.Status -ceq 'PENDING' -and -not $delivery.Reason) {
      $config=Get-AplArticleReadyConfiguration -ProjectRoot $ProjectRoot
      $reason='AGENT_CONTINUATION_REQUIRED'
      if($config.transport -cne 'agent-gmail' -or $config.deliveryEnabled -ne $true -or -not $config.PSObject.Properties['receiverReady'] -or $config.receiverReady -ne $true){$reason='RECEIVER_NOT_READY'}
      $delivery=Invoke-AplArticleReadyDelivery -Mode Pending -ProjectRoot $ProjectRoot -EventId $event.EventId -Reason $reason
    }
    if ($delivery.Status -ceq 'SENT') {
      $result.DeliveryStatus='SENT';$result.DeliveryReason=$null;$result.DeliveryActionRequired=$false
      $result.GmailMessageId=$delivery.GmailMessageId
    } elseif (@('CLAIMED','SENDING','UNCERTAIN') -ccontains $delivery.Status) {
      $result.DeliveryStatus='UNCERTAIN';$result.DeliveryReason=('RECONCILIATION_REQUIRED_'+$delivery.Status)
    } elseif ($delivery.Status -ceq 'SUPERSEDED') {
      $result.DeliveryReason='ARTIFACT_OR_HK_DATE_CHANGED';$result.DeliveryActionRequired=$false
    } elseif ($delivery.Status -ceq 'PENDING') {
      $result.DeliveryReason=$delivery.Reason
    } else { $result.DeliveryReason='DELIVERY_PROTOCOL_ERROR' }
    if ($delivery.PSObject.Properties['ReceiptPath']) {$result.DeliveryReceiptPath=$delivery.ReceiptPath}
  } catch { $result.DeliveryReason='HANDOFF_ERROR' }
  return [pscustomobject]$result
}
