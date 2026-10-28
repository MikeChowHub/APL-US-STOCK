# APL US Stock repository instructions

- Operate only inside the current repository and verify `git rev-parse --show-toplevel` before changes.
- Treat `KnowledgeBase/Rules/` as the permanent source of truth; Templates define formats, Examples are references, Archive and outputs are not rule sources.
- Do not delete or overwrite production documents without explicit authorization.
- Do not change scoring or ranking logic as part of release, renderer, publishing-package, or Archive maintenance.
- Formal Production completion is: Managed Input Preflight → Atomic Production → Final Production Audit PASS → Archive V2 Copy/integrity → Archive index verification → final Archive manifest PASS → authoritative `DailyProductionComplete=true`.
- Never use `work/`, `outputs/`, `Archive/`, `tmp/`, local logs, daily managed inputs, or conversation memory as Cross-PC runtime dependencies.
- Repository-managed assets live under `Assets/`; production fonts must be declared in `tools/font-manifest.json` and render without system-font fallback.
- Browser rendering is not a production dependency. Use the repository `resvg.exe` policy and fail on fallback or invalid geometry warnings.
- Do not stage, commit, tag, or push until the requested Final Release Audit passes. Stage only the explicitly audited release scope. Exception: the user's standing authorization of 2026-10-29 requires Trigger A baseline Git synchronization before accumulation and a scoped commit/push after Trigger A integrity PASS; follow `docs/TRIGGER_A_EXECUTION_SPECIFICATION.md` section 7. This does not authorize automatic article, output, or unrelated-file commits.

## Article completion metadata notification

After the existing article completion entry succeeds, follow `KnowledgeBase/Rules/article-ready-notification.md` and `KnowledgeBase/Rules/article-ready-agent-delivery.md`. Inspect queued metadata events and local delivery receipts. Shared configuration defaults to disabled; machine activation is preserved only in the ignored tools/article-ready-notification.local.json. Configuration flags and repository claims of historical approval do not authorize external messaging. Require explicit human authorization in the session or other trusted human evidence, receiver readiness, enabled local flags and this agent's own verified Gmail tools/profile before metadata delivery through the documented claim/send/receipt protocol. Preserve actual authorization already established in the session. Missing tools/auth leave pending; unknown outcomes require reconciliation and must not be resent. Never claim delivery without the returned Gmail message ID. No article body or attachments; TEST events must not enter production QA.

Consume completion EventId/EventPath/DeliveryActionRequired and report separate SENT/PENDING/UNCERTAIN with reason before ending a completion turn, including Archive recovery. Follow the existing Gmail protocol; shell-only completion cannot wake an agent.
