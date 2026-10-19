[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][ValidateSet('Inspect','Pending','Claim','BeginSend','ReleaseBeforeSend','MarkUnknown','Confirm','Reconcile')][string]$Mode,
  [Parameter(Mandatory=$true)][string]$EventId,
  [string]$ProjectRoot,
  [string]$VerifiedSender,
  [string]$ClaimToken,
  [string]$GmailReceiptPath,
  [ValidateSet('GMAIL_TOOL_UNAVAILABLE','GMAIL_AUTH_REQUIRED','RECEIVER_NOT_READY','SEND_OUTCOME_UNKNOWN','NO_EXACT_GMAIL_MATCH','AGENT_CONTINUATION_REQUIRED')][string]$Reason='GMAIL_TOOL_UNAVAILABLE',
  [switch]$AllowTest
)
$ErrorActionPreference='Stop'
if(-not $ProjectRoot){$ProjectRoot=Split-Path -Parent $PSScriptRoot}
. (Join-Path $PSScriptRoot 'article-ready-notification.ps1')
Invoke-AplArticleReadyDelivery -Mode $Mode -ProjectRoot $ProjectRoot -EventId $EventId -VerifiedSender $VerifiedSender -ClaimToken $ClaimToken -GmailReceiptPath $GmailReceiptPath -Reason $Reason -AllowTest:$AllowTest | ConvertTo-Json -Depth 8
