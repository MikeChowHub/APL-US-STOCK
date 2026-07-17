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
- `AsOfDate` is a strict real calendar date earlier than `ScanDate`;
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
- implicit Git stage, commit, tag, or push;
- silent symbol repair, silent row dropping, or partial-success publication.

## 5. Output

### 5.1 Dated execution result

The daily result is:

```text
outputs/<ScanDate>/APL_Quant_Cumulative_Watchlist_<ScanDate>.txt
```

The implementation must use no-overwrite behavior. An existing dated output may only be treated as an idempotent rerun after exact bytes and SHA-256 comparison; conflicting content must fail.

`outputs/` is an output destination only. A later Trigger A run must never read it as the previous baseline.

### 5.2 Canonical baseline promotion

After the dated result passes count, format, bytes, SHA-256, preservation, and deduplication checks, the same verified bytes become the next repository-managed canonical baseline:

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
