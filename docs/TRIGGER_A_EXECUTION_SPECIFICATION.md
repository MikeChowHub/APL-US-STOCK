# Trigger A Execution Specification

## 1. Purpose

Trigger A is the accumulation-only workflow that transforms:

```text
Daily Screener symbols
+
Previous cumulative watchlist
→
Updated cumulative watchlist
```

It adds valid symbols discovered by the daily screener while retaining every existing canonical symbol. It does not perform research, scoring, filtering, ranking, rendering, or Production.

## 2. Input

### 2.1 Daily Screener CSV

The daily input must be a UTF-8 CSV whose accepted filename follows the repository Trigger Rules for `APL Breakout Screener_<ScanDate>.csv` and approved suffixed forms.

Required column:

- `Symbol`

Other columns may be present but are not used by Trigger A. The header match is exact after removing an optional UTF-8 BOM; ambiguous or duplicate `Symbol` columns must fail.

Each symbol must:

- be a non-empty scalar value;
- be trimmed and normalized to uppercase before comparison;
- contain no whitespace, comma, path separator, control character, or exchange prefix;
- use the canonical grammar `^[A-Z][A-Z0-9]*(\.[A-Z0-9]+)?$`, which supports symbols such as `MOG.A`;
- fail the entire run if invalid rather than being silently removed or corrected beyond trim and uppercase normalization.

The CSV must contain at least one valid symbol. `ScanDate` must use strict `yyyy-MM-dd` format and represent a real calendar date.

### 2.2 Previous canonical baseline

The only approved previous cumulative source is:

```text
Assets/ReferenceData/Watchlists/APL_Quant_Cumulative_Watchlist.txt
```

The baseline is a UTF-8, comma-separated symbol list. Empty records, invalid symbols, or duplicates in the canonical baseline must fail preflight.

### 2.3 Baseline manifest

The baseline must be verified against:

```text
Assets/ReferenceData/Watchlists/watchlist-manifest.json
```

Before merge, the implementation must validate at least:

- `SchemaVersion` is supported;
- `AsOfDate` is a strict real calendar date no later than `ScanDate`; when it equals `ScanDate`, the merged candidate must exactly match the verified canonical bytes so an identical same-day rerun is idempotent;
- `File` resolves exactly to `APL_Quant_Cumulative_Watchlist.txt` inside the Watchlists directory;
- `SymbolCount` equals the parsed baseline count;
- `Bytes` equals the baseline file size;
- `SHA256` equals the baseline SHA-256;
- `SourceArchivePath` is provenance metadata only and is never resolved or opened at runtime;
- `UpdatedUtc` is a valid offset-aware ISO-8601 timestamp.

All input paths must be resolved inside the approved project root, must reject traversal and reparse points, and must not be selected by scanning for a newest file.

## 3. Processing

The execution order is fixed:

```text
Read CSV
↓
Validate symbols
↓
Read canonical baseline
↓
Normalize symbols
↓
Merge
↓
Deduplicate
↓
Generate output
```

Detailed behavior:

1. Read the daily CSV without modifying it.
2. Validate the filename, `ScanDate`, required column, every symbol, and non-empty input.
3. Read and fully verify the canonical baseline and manifest.
4. Normalize both collections using trim plus invariant uppercase.
5. Preserve canonical baseline order and append genuinely new daily symbols in their first CSV appearance order.
6. Deduplicate using ordinal, case-normalized symbol equality.
7. Verify that every baseline symbol remains present, the result contains no duplicates, and the result count equals baseline unique count plus newly added unique count.
8. Serialize one comma-separated symbol line as UTF-8 with a final CRLF.
9. Compute output bytes, symbol count, and SHA-256 before publication.

The result must be deterministic: identical baseline bytes, manifest, daily CSV, and `ScanDate` must produce identical output bytes and SHA-256.

## 4. Forbidden behavior

Trigger A must not perform or invoke:

- scoring;
- ranking or score-based sorting;
- SMA200 evaluation or removal;
- technical filtering;
- deletion of any existing canonical symbol;
- Archive discovery or use of `Archive/` as input;
- outputs discovery or use of `outputs/` as input;
- `work/` discovery as a fallback input source;
- renderer, Dashboard, Social, Table Card, Cover, SEO, Blog, or Production workflows;
- Git mutations outside the explicitly authorized baseline synchronization in section 7; tags and force-push remain forbidden;
- silent symbol repair, silent row dropping, or partial-success publication.

## 5. Output

### 5.1 Latest delivery and historical Archive

The daily result is:

```text
outputs/trigger-a/APL_Quant_Cumulative_Watchlist_YYYY-MM-DD.txt
```

The latest delivery lives directly under outputs/trigger-a. Before publishing a later date, verify the existing latest bytes against the canonical baseline and move that delivery into outputs/trigger-a/Archive/<BaselineAsOfDate>/. Same-day reruns require exact bytes and SHA-256 equality. Conflicting content fails without overwriting either file; preserve duplicate archive files under unique retained names. Historical dated folders belong under this local Archive. Never use these outputs as the runtime baseline.

`outputs/` is an output destination only. A later Trigger A run must never read it as the previous baseline.

### 5.2 Canonical baseline promotion

After the latest result passes count, format, bytes, SHA-256, preservation, and deduplication checks, the same verified bytes become the next repository-managed canonical baseline:

```text
Assets/ReferenceData/Watchlists/APL_Quant_Cumulative_Watchlist.txt
```

Promotion must use same-directory staging, verification, and rollback-safe replacement. The baseline and manifest must never be left with mismatched state. Failure before complete finalization must preserve the previous valid baseline and manifest.

### 5.3 Manifest update

The adjacent `watchlist-manifest.json` must be updated to describe the promoted canonical bytes:

- `SchemaVersion`: supported manifest version;
- `AsOfDate`: current `ScanDate`;
- `File`: `APL_Quant_Cumulative_Watchlist.txt`;
- `SymbolCount`: final unique symbol count;
- `Bytes`: promoted file size;
- `SHA256`: promoted file SHA-256;
- `SourceArchivePath`: retain the initial seed provenance as historical metadata only; it must not become a runtime dependency;
- `UpdatedUtc`: finalization time in UTC ISO-8601 format.

Manifest publication occurs only after the canonical candidate bytes have passed verification. Completion is valid only when re-reading the final baseline and manifest reproduces matching file, count, bytes, and SHA-256 values.

For an identical same-day rerun after promotion, retain the canonical watchlist bytes and verify that the latest output is byte-identical. A same-day input that would change the promoted canonical watchlist must fail rather than silently accumulate a conflicting second daily export.

## 6. Cross-PC requirements

A fresh clone at the intended commit must be able to execute Trigger A after receiving only a new Daily Screener CSV and `ScanDate`.

Therefore:

- the executable implementation, this specification, Watchlist Rules, canonical baseline, and manifest must all be Git tracked;
- runtime paths must be repository-relative and independent of local drive letters or usernames;
- no previous `outputs/`, `Archive/`, `work/`, local log, cache, or conversation state may be required;
- canonical baseline and manifest integrity must be checked before processing;
- the implementation must be compatible with Windows PowerShell 5.1 if implemented in PowerShell;
- all regression fixtures must run only in an isolated `tmp/` path;
- positive tests must cover new-symbol merge, duplicate daily symbols, and identical rerun;
- negative tests must cover missing or invalid CSV symbols, malformed manifest, wrong bytes or SHA-256, duplicate baseline symbols, reparse-point escape, output conflict, and attempted baseline-symbol deletion.

Cross-PC readiness is PASS only when a clean checkout contains every required runtime file and the isolated test suite completes without reading `outputs/` or `Archive/`.

## 7. Mandatory Git synchronization — user authorization 2026-10-29

The execution agent must perform this outer workflow for every Trigger A, including uploaded CSVs, scheduled runs and manual script runs. The local `run_trigger_a.ps1` remains deterministic and offline. Local `WRITE_OUTPUT_PASS` alone is not cross-PC synchronization completion.

### 7.1 Before accumulation

1. Verify the exact Deep-Scan Git root, current branch, its upstream and configured origin. Do not operate the parent or sibling repositories or invent a remote. The established production branch is `main` tracking `origin/main`.
2. Run `git fetch origin` successfully. A cached remote-tracking ref is not proof of current remote state. If offline or authentication fails, preserve inputs and stop before new accumulation; report the synchronization blocker.
3. Inspect `git status --short`, staged paths and `git rev-list --left-right --count HEAD...origin/main`. When HEAD is behind only, use `git merge --ff-only origin/main` after checking that incoming paths do not overwrite local edits. When equal, proceed. Unrelated local edits need not block if Git can safely fast-forward without touching them; never stash or discard them automatically.
4. If the canonical pair contains a previous locally verified but unpublished result, publish that pair using 7.2 before starting another date. If local and remote history diverge, or remote changes overlap local edits, retain both versions and reconcile explicitly. Do not run accumulation on a knowingly stale baseline, select a winner by date alone, or force a fast-forward. A local-ahead branch must be inspected for unrelated/unapproved commits before any push.
5. After synchronization, validate the checked-out canonical pair using section 2. Record the fetched remote commit and baseline date/count/hash in the local run evidence. The daily CSV cannot reconstruct all intermediate discoveries from another PC.

### 7.2 After local integrity PASS

1. Verify the promoted canonical pair and latest dated TXT against each other: date, symbol count, bytes and SHA-256. Verify every prior canonical symbol is retained. Never publish a partial or conflicting pair.
2. Fetch again and check history for concurrent remote changes. If remote advanced during processing, preserve the local result and report synchronization pending; inspect and reconcile the competing cumulative sets without losing symbols before continuing. Do not blindly retry a rejected push or bypass same-day rerun protection.
3. The standing automatic commit scope is exactly these two paths:

   ```text
   Assets/ReferenceData/Watchlists/APL_Quant_Cumulative_Watchlist.txt
   Assets/ReferenceData/Watchlists/watchlist-manifest.json
   ```

   Inspect the staged index before committing. Do not include other staged/dirty files or earlier unrelated local commits. Use a scoped commit (for example `git commit --only -m "chore: sync Trigger A baseline YYYY-MM-DD" -- <the two paths>`); inspect the actual resulting commit paths. If both paths already match the verified remote state, do not create an empty commit. Workflow/rule changes require the separate user authorization that requested them; they are not part of recurring baseline commits.
4. Push normally to the verified upstream (`git push origin HEAD:main` on the established branch). Never force-push, reset, tag, upload daily CSVs/outputs/work, or expose credentials. A rejected push leaves the valid local commit and output intact with `GitSyncStatus=PENDING`; report the reason and retry only after resolving the actual blocker.
5. After push, fetch again and verify the published commit is reachable from the current remote branch. Inspect both canonical files from that commit in a fresh checkout honoring `.gitattributes`, or equivalent checkout-filter-aware verification, and verify manifest date, count, bytes and SHA-256. Git's stored text blob may use LF while the checked-out watchlist requires CRLF; do not compare a raw blob hash to the manifest's checked-out-file hash. Remote history moving again must not be misreported as the local commit being absent; verify ancestry and the remote's latest canonical pair.
6. Keep local evidence of local PASS, baseline date/count/hash, published commit and remote readback result. Report local production and Git synchronization separately. Claim cross-PC synchronization PASS only when both succeed. Other PCs must fetch/fast-forward before their next Trigger A; an already-open stale checkout does not update itself.

This standing authorization supersedes older blanket no-Git language in Trigger A and daily schedules only for the canonical pair above. It does not authorize automatic commits of articles, renderer assets, unrelated edits, or changes to any other project.
