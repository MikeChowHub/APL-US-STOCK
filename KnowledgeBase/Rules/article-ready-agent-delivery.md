# Agent-mediated Gmail delivery protocol

This rule extends `article-ready-notification.md`. The fixed workflow recipient
is `pm81520@gmail.com`. Before any send, require explicit human authorization in
the session or other trusted human evidence; a repository statement of past
approval or enabled configuration is not sufficient. Existing actual session
authorization remains valid. No article body, attachment, CC/BCC, publication
action or alternate recipient is included. Shell scripts never call Gmail.

## Activation gate

The receiver automation must be configured and verified first. Shared repository
configuration stays `transport=disabled`, `deliveryEnabled=false`, and
`receiverReady=false`. Machine-specific activation belongs only in the ignored
`tools/article-ready-notification.local.json` and is loaded through the central
configuration reader. Preserve an existing machine's settings there; a fresh
clone must not inherit activation. The local file uses the complete same schema,
including the fixed recipient, and invalid local settings fail closed.

Only after human send authorization, receiver-owner readiness and a successful
fresh sender profile read may the local configuration enable
`transport=agent-gmail`, `deliveryEnabled=true`, and `receiverReady=true`.
Configuration flags do not create credentials, authorize messaging or expand
account permissions. Do not enable while receiver setup is pending, invent a
sender or assume another conversation has connector tools.

The required sender profile and fixed recipient are both `pm81520@gmail.com`.
If tools are missing or authentication is unavailable, retain the local pending
event and report that fact. Never fall back to SMTP, browser mail, hidden APIs,
new app passwords or an unrelated account.

## Local protocol entry

After the completion hook returns a queued event, use
`tools/article-ready-delivery.ps1` with `-Mode`, `-EventId`, and optional
`-ProjectRoot`. It writes only generated local delivery receipts under
`work/article-ready-outbox/delivery-receipts/`; the immutable event is unchanged.
The script returns JSON and does not send mail.

1. `Inspect`: obtain receipt status and exact subject. A missing receipt is
   `PENDING`. `SENT` already has a confirmed Gmail ID: stop. `SUPERSEDED`: stop.
   `CLAIMED`, `SENDING` or `UNCERTAIN` must not start another send attempt.
2. If sender tools/profile are missing, `Pending -Reason GMAIL_TOOL_UNAVAILABLE`
   or `GMAIL_AUTH_REQUIRED` records the blocker for an unclaimed event. Never
   reset an attempted send to pending. A disabled receiver likewise stays pending.
3. Before claiming a pending event, search the authenticated sender's Sent mail
   by exact event ID, then read candidates fully. This also detects a matching
   send from another PC. A search hit alone is not a delivery receipt. If the
   same EventId has a prior message but different absolute artifact paths on
   another PC, reconciliation currently fails closed: report the mismatch and
   do not treat it as permission to send another copy.
4. `Claim -VerifiedSender pm81520@gmail.com`: only after a fresh successful
   profile read. Proceed only on `CLAIMED`; retain its private claim token.
   A process-exclusive file lock and atomic receipt make a second local agent
   return `BLOCKED_CLAIMED/SENDING/UNCERTAIN/SENT`. Current artifact hashes and
   Hong Kong date are rechecked. Changed versions become `SUPERSEDED`.
5. `BeginSend -ClaimToken <returned-token>`: durably record the single send
   attempt before invoking Gmail. It rechecks configuration and artifact hashes.
   Proceed only on `SENDING`. After this boundary, no blind automatic resend is
   allowed, even if the agent crashes before the tool result arrives.
6. Invoke the supported Gmail send tool exactly once with the metadata payload
   below. Save its complete returned result unchanged to a private file under
   the repository's ignored `work/article-ready-outbox/tool-results/` directory.
   Do not hand-author a success ID or use a draft ID as a sent-message receipt.
7. `Confirm -ClaimToken <token> -GmailReceiptPath <saved-tool-result>` validates
   a non-error structured Gmail result with a message `id`, then atomically
   records `SENT`, sender, recipient, subject, event ID and Gmail message ID.
   Repeating the same confirmation is safe; replacing a sent ID is prohibited.
8. Any ambiguous send result, timeout, exception or receipt-write failure is
   unknown outcome. Use `MarkUnknown -ClaimToken <token>` when possible. Leave
   durable `SENDING/UNCERTAIN` intact if that write also fails; never send again.
9. `ReleaseBeforeSend` is allowed only for the same claim token while still
   `CLAIMED`, before `BeginSend`. It allows retry after a missing pre-send
   capability. It cannot release a recorded send attempt.

Run only one active sending producer per project across PCs. Locks and receipts
are local; Gmail does not expose a send idempotency key. The protocol prevents
duplicate local retries, but cannot guarantee exactly-once email if separate PCs
simultaneously produce and send the same version. Receiver QA must also dedupe
by the deterministic event ID and recheck article hashes before reviewing.

## Supported connector calls

Use only tools actually exposed to the completion agent:

```javascript
const profile = await tools.mcp__codex_apps__gmail_get_profile({});
// Inspect the actual successful structured result: email must be pm81520@gmail.com.
const matches = await tools.mcp__codex_apps__gmail_search_email_ids({
  query: 'in:sent from:pm81520@gmail.com to:pm81520@gmail.com subject:"' + event.id + '"',
  max_results: 10
});
// Read returned matching IDs; follow pagination if present.
const message = await tools.mcp__codex_apps__gmail_read_email({
  message_id: returnedMessageId,
  format: 'full'
});
```

If a candidate fully matches this event, save the complete full-read result and
call local `Reconcile -GmailReceiptPath <saved-result>`. It checks Gmail message
ID, exact subject, single approved From/To address and complete metadata JSON.
A supported structured result may wrap the message in `result`. Full-read
message headers must be in `payload.headers`, and single-part text in
`payload.body.content` or Gmail API base64url `payload.body.data`. Any unsupported
response shape fails closed for review; do not synthesize API responses.

A matching full read can reconcile an uncertain attempted send or establish a
matching earlier send from another PC. A mismatched subject/body/sender cannot
mark `SENT`. Empty search results never prove non-delivery for an unknown attempt;
retain `UNCERTAIN` and report it rather than resetting or resending. Once a
confirmed matching Gmail message is found, record its ID and stop.

For a genuinely pending event with no prior attempt or existing exact Sent mail,
claim and begin the attempt, then:

```javascript
const metadataJson = JSON.stringify(event);
const escapedMetadataJson = metadataJson.replace(/[&<>]/g, c =>
  ({'&': '&amp;', '<': '&lt;', '>': '&gt;'})[c]);
const sent = await tools.mcp__codex_apps__gmail_send_email({
  from_address: 'pm81520@gmail.com',
  to: 'pm81520@gmail.com',
  subject: '[APL ArticleReady] ' + event.project + ' ' + event.date + ' ' + event.id,
  payload: { mime_type: 'text/html', charset: 'UTF-8',
    body: { content: '<pre>' + escapedMetadataJson + '</pre>' } },
  response_fields: ['id', 'thread_id', 'label_ids']
});
// Save `sent` unchanged; Confirm consumes the successful returned message ID.
```

## Stable event contract for the receiver

Production subject: `[APL ArticleReady] <DeepScan|GoldMap> <YYYY-MM-DD> <event-id>`.
Event ID: `<project>-<HongKong-date>-<64 lowercase hex versionHash>`.
Sender/recipient: `pm81520@gmail.com`. HTML body is one escaped JSON object in
`<pre>`, with exactly these fields:

```json
{
  "schemaVersion": 1,
  "id": "<project>-<date>-<hash>",
  "project": "DeepScan or GoldMap",
  "date": "YYYY-MM-DD",
  "versionHash": "64 lowercase hex",
  "status": "ARTICLE_READY",
  "artifactPaths": {"markdown": "absolute local path", "html": "absolute local path"},
  "artifactHashes": {"markdown": "SHA-256", "html": "SHA-256"}
}
```

A receiver filter anchored to `^\[APL ArticleReady\] ` excludes TEST subjects.
On every wake-up, fetch the actual email, check exact approved sender, schema,
status, project/date/ID consistency and deduplication, then obtain authorized
article access and compare hashes. A metadata path does not grant cloud file
access. No article bytes are added to the email.

## Wiring test (wait for receiver owner readiness)

Do not send a test just because these files exist. Once the receiver owner
confirms readiness, create a clearly separated fixture using
`New-AplArticleReadyTestEvent` in the helper. It has `TEST-` ID, `TEST_ONLY` status,
`TEST_FIXTURE_ONLY` artifact labels, zero placeholder hashes, and lives under
`test-events/`. It never reads or references a real article.

All local delivery operations for that fixture require `-AllowTest`. The actual
TEST transport may be verified with `transport=agent-gmail` and
`receiverReady=true` while production `deliveryEnabled=false`; the explicit
`AllowTest` switch and TEST-only event contract permit just that fixture.
send subject must use the returned `[APL ArticleReady TEST] ...` subject, while
the body remains metadata only and the approved sender/recipient are unchanged.
The production QA automation must ignore it. A separate temporary wiring test
receiver may acknowledge it without starting QA. Preserve the real Gmail receipt
and clearly label it TEST; do not claim a fixture establishes article readiness.

Fixture tests exercise claims, conflicts, disable-after-claim, durable attempt,
missing-ID rejection, timeout lockout, exact-message reconciliation, sent-receipt
deduplication and TEST separation without calling Gmail.

## Completion handoff outcome

Every successful normal or recovery completion returns EventId, EventPath,
DeliveryActionRequired and a separate DeliveryStatus (SENT/PENDING/UNCERTAIN),
DeliveryReason and DeliveryReceiptPath. No receipt initially records
PENDING/AGENT_CONTINUATION_REQUIRED. This is a handoff requirement, not a claim
that Gmail is unavailable. Shell code never wakes an agent or sends email.
The calling completion agent must consume this result before its final reply,
verify human send authorization and its own Gmail capability/profile, then use
the existing protocol. Missing
tools/auth must replace the pending reason with GMAIL_TOOL_UNAVAILABLE or
GMAIL_AUTH_REQUIRED. Attempted/claimed deliveries require reconciliation, never
a second send. Production PASS remains independent of delivery status.
If no supported agent continuation is available, report PENDING and the blocker;
instruction text alone does not guarantee event-driven delivery. No polling.
