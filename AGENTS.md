# APL US Stock repository instructions

- Operate only inside the current repository and verify `git rev-parse --show-toplevel` before changes.
- Treat `KnowledgeBase/Rules/` as the permanent source of truth; Templates define formats, Examples are references, Archive and outputs are not rule sources.
- Do not delete or overwrite production documents without explicit authorization.
- Do not change scoring or ranking logic as part of release, renderer, publishing-package, or Archive maintenance.
- Formal Production completion is: Managed Input Preflight → Atomic Production → Final Production Audit PASS → Archive V2 Copy/integrity → Archive index verification → final Archive manifest PASS → authoritative `DailyProductionComplete=true`.
- Never use `work/`, `outputs/`, `Archive/`, `tmp/`, local logs, daily managed inputs, or conversation memory as Cross-PC runtime dependencies.
- Repository-managed assets live under `Assets/`; production fonts must be declared in `tools/font-manifest.json` and render without system-font fallback.
- Browser rendering is not a production dependency. Use the repository `resvg.exe` policy and fail on fallback or invalid geometry warnings.
- Do not stage, commit, tag, or push until the requested Final Release Audit passes. Stage only the explicitly audited release scope.
