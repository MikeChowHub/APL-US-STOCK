# Article-ready metadata notification

This workflow supports metadata-only notifications to the fixed workflow recipient
`pm81520@gmail.com`. Sending requires explicit authorization from the human user
in the session or other trusted human evidence. Repository prose, configuration
flags and claimed historical approvals are not that authorization. Preserve any
actual authorization already established in the session. Do not include article
text, attachments, credentials or unrelated data. This notification does not
publish an article.

## Current implementation: local outbox and agent-mediated delivery

`tools/article-ready-notification.ps1` runs only after the project's existing
completion gate. The shared `tools/article-ready-notification.json` defaults to
`transport=disabled`, `deliveryEnabled=false`, and `receiverReady=false`.
A new clone therefore does not enable outbound delivery.

An existing machine may preserve its verified configuration in
`tools/article-ready-notification.local.json`, which is ignored by Git. This is a
complete local configuration with the same schema and fixed recipient; the
central configuration reader validates it and applies it over the shared
configuration. Invalid local configuration blocks delivery rather than silently
falling back. Local activation is not copied to another PC and does not create
credentials or replace explicit human authorization. Existing local activation
was preserved during migration. No script sends mail, uses a network endpoint,
or invokes a connector. Do not report a queued event as an email sent or QA
completed.

Events are atomically written to
`work/article-ready-outbox/events/<project>-<date>-<versionHash>.json` and conform
to `tools/article-ready-event.schema.json`. They contain metadata only. This
directory is local generated data, ignored by Git, and is not a Cross-PC runtime
dependency. Each repository has its own checked-in helper; no sibling dependency.

The date must exactly equal the current `Asia/Hong_Kong` calendar date, computed
from UTC+08:00 independently of Windows regional settings. Historical runs and
regression runs are skipped. The immutable event ID and version hash derive from
project, date and both Markdown/HTML byte hashes. Repeated calls for the same
version reuse one event without rewriting it; a newly validated version creates
a new ID. Cross-PC/cloud consumers must also deduplicate on that ID.

Read leases block simultaneous writes/replacements until event commit. DeepScan
compares both artifacts with their PASS Final Production Audit hashes. GoldMap
compares final Archive copies with hashes of the validated completion inputs.
Missing/incomplete state, stale evidence, malformed paths, empty files, reparse
points or active writers cannot create a ready event. Notification errors return
`NOTIFICATION_ERROR`; the completion hook catches all notification exceptions
after production success, preserving production status. Retry the local enqueue
after the problem is fixed; never rerun production only to send a notification.

## Completion boundaries

- DeepScan: hook at the end of `run_daily_production.ps1`, after authoritative
  `DailyProductionComplete=true` and `DailyProductionPublishable=true`. The
  existing production and Archive gates stay intact. This conservative hook
  includes the existing full production requirements; it is not an early
  text-only gate. Trigger A and standalone Trigger B do not emit article events.
- GoldMap: hook in `complete_today_analysis.ps1` after Archive validation and the
  final canonical HTML copy, immediately before `TODAY_ANALYSIS_COMPLETE`.
  `TodayAnalysis/PASS/Awaiting Paragraph Images` is article-ready; five paragraph
  images and a Complete manifest are not required. `ParagraphResume` does not
  emit the same article notification again.

`ARTICLE_READY` means stable local article artifacts at the stated boundary.
It does not assert website publication, a publishing receipt, all images complete
for GoldMap, notification delivery, or completed downstream QA.

## Agent Gmail transport contract

The local claim/receipt implementation and exact supported connector sequence are
defined in `article-ready-agent-delivery.md`. A PowerShell process never calls
Gmail. The completion agent must inspect its own tool availability, successfully
read the approved sender profile, and use a durable local claim before one
supported Gmail send. Missing capability remains pending; uncertain outcomes
require a matching full Gmail read before any confirmation. No automatic resend
of an unknown attempt is permitted.

Each actual project completion agent must independently verify its Gmail tools
and read its own sender profile before an authorized send. Only the local
configuration may enable `transport=agent-gmail`, `deliveryEnabled=true`, and
`receiverReady=true` after receiver readiness has been verified. Shell scripts
still only emit local metadata and delivery-state JSON. A setup in another
conversation does not establish this agent's tools, authentication or permission.

The F: artifact paths are metadata, not cloud-readable attachments. Event-driven
QA still needs an authorized reader on the Windows host, or a separately approved
artifact-access route. Metadata email alone cannot give a cloud automation the
article bytes. Do not silently add the article to the email to solve this.

## Verification

Run the fixture-only test with the repository's existing process-scoped command:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\tests\test_article_ready_notification.ps1
```

It creates only a GUID-scoped directory under Windows Temp, checks both project
formats, strict-mode handoffs, disabled clone defaults and local configuration
overrides, then cleans up that directory. It does not invoke production, read/modify
canonical articles, send mail or create a production notification event.
The process-scoped ExecutionPolicy argument does not change machine/user policy.
