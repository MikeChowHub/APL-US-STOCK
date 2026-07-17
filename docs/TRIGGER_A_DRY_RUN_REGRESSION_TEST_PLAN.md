# Trigger A Dry-Run Regression Test Plan

## 1. Scope

This plan validates `tools/run_trigger_a.ps1` in `dry-run` mode only. It verifies input validation, canonical baseline integrity checks, deterministic merge and deduplication, fail-closed behavior, and the absence of runtime writes.

The test suite must not:

- modify the formal canonical baseline;
- modify the formal watchlist manifest;
- read or write formal `outputs/`;
- read or write formal `Archive/`;
- create a Production result;
- stage, commit, or push.

## 2. Isolation model

All cases run inside:

```text
tmp/trigger-a-dry-run-regression/<CaseId>/repo/
```

Each case receives a fresh minimal fixture repository containing only:

```text
repo/
├─ tools/
│  ├─ run_trigger_a.ps1
│  └─ production_archive_common.ps1
├─ Assets/ReferenceData/Watchlists/
│  ├─ APL_Quant_Cumulative_Watchlist.txt
│  └─ watchlist-manifest.json
└─ inputs/
   └─ APL Breakout Screener_<ScanDate>.csv
```

The fixture copies are test data. Negative cases may remove or corrupt only those isolated copies. No case may point `run_trigger_a.ps1` at a daily CSV outside its fixture Project Root.

Before each invocation, record:

- baseline existence, bytes, and SHA-256;
- manifest existence, bytes, and SHA-256;
- the complete file inventory beneath the fixture root;
- confirmation that the fixture has no `outputs/` or `Archive/` directory.

After each invocation, compare the same evidence. Except for files deliberately changed during negative-case setup, the baseline and manifest must remain byte-identical. The invocation itself must create no file or directory.

## 3. Common valid fixture

Baseline:

```text
AAPL,MSFT,MOG.A
```

Manifest values must exactly match the baseline:

- supported `SchemaVersion`;
- `AsOfDate` earlier than the daily `ScanDate`;
- `File: APL_Quant_Cumulative_Watchlist.txt`;
- `SymbolCount: 3`;
- exact `Bytes`;
- exact uppercase SHA-256;
- provenance-only `SourceArchivePath`;
- valid UTC `UpdatedUtc`.

Unless a case states otherwise, the daily filename is:

```text
APL Breakout Screener_2040-01-02.csv
```

## 4. Regression cases

| Test | Fixture | Expected result | Required assertions |
|---:|---|---|---|
| 1 | Normal merge: daily symbols `NVDA`, `TSLA` | Exit `0`; `Status=DRY_RUN_PASS` | Baseline count `3`; daily unique count `2`; added symbols exactly `NVDA`, `TSLA` in CSV order; final count `5`; preview SHA present; no writes |
| 2 | Duplicate symbols: daily symbols `NVDA`, `nvda`, `AAPL`, `NVDA` | Exit `0`; `Status=DRY_RUN_PASS` | Normalize to uppercase; daily unique count `2`; only `NVDA` added; existing `AAPL` retained once; final count `4`; no writes |
| 3 | Invalid symbol: daily contains `BAD SYMBOL` | Exit non-zero | Error identifies invalid symbol; no preview PASS object; baseline and manifest unchanged; no outputs |
| 4 | Missing `Symbol` column: header contains `Ticker` instead | Exit non-zero | Error states exactly one `Symbol` column is required; baseline and manifest unchanged; no outputs |
| 5 | Missing baseline: omit the isolated baseline copy | Exit non-zero | Error states required canonical file does not exist; manifest remains unchanged; no baseline or output is created |
| 6 | SHA mismatch: set isolated manifest `SHA256` to a valid-format but incorrect value | Exit non-zero | Error states canonical SHA-256 does not match manifest; baseline and manifest remain unchanged after invocation; no outputs |
| 7 | Manifest mismatch: set isolated manifest `SymbolCount` to `4` while baseline contains `3` | Exit non-zero | Error states symbol count does not match manifest; baseline and manifest remain unchanged after invocation; no outputs |
| 8 | Empty CSV: valid `Symbol` header with zero data rows | Exit non-zero | Error states CSV contains no data rows; baseline and manifest unchanged; no outputs |

## 5. Detailed case requirements

### Test 1 — Normal merge

The preview sequence must be:

```text
AAPL,MSFT,MOG.A,NVDA,TSLA
```

Baseline ordering must be preserved. New symbols must be appended in first daily appearance order.

### Test 2 — Duplicate symbols

Deduplication uses normalized symbol equality. Case-only variants are the same symbol. Duplicates in the daily CSV are not errors, but they must not change the result more than once.

Duplicates already present in the canonical baseline are a separate integrity failure and are not silently repaired.

### Test 3 — Invalid symbol

At minimum, test whitespace inside a symbol. Additional negative variants may include commas, path separators, control characters, exchange prefixes, and characters outside the approved symbol grammar.

### Test 4 — Missing Symbol column

The validator must not guess that `Ticker`, `Code`, or another column means `Symbol`. It must fail before reading the canonical baseline into merge processing.

### Test 5 — Missing baseline

Only the fixture baseline is absent. The formal repository baseline remains untouched. The tool must not discover or copy a replacement from `Archive/`, `outputs/`, `work/`, or another date.

### Test 6 — SHA mismatch

The incorrect SHA retains the required 64-character uppercase hexadecimal format so the case specifically tests integrity mismatch rather than format validation.

### Test 7 — Manifest mismatch

The primary case uses an incorrect `SymbolCount`. Optional variants may independently test wrong `Bytes`, wrong `File`, unsupported `SchemaVersion`, invalid dates, or a malformed JSON document.

### Test 8 — Empty CSV

A header-only CSV is empty input and must fail. It must not be interpreted as an instruction to reuse or republish the unchanged baseline.

## 6. No-write audit

Every case must assert all of the following:

```text
WritesPerformed = false, when a PASS report exists
CanonicalUpdated = false, when a PASS report exists
ManifestUpdated = false, when a PASS report exists
```

For both PASS and FAIL cases:

- baseline hash and bytes are unchanged by invocation;
- manifest hash and bytes are unchanged by invocation;
- no `outputs/` directory is created;
- no `Archive/` directory is created;
- no temporary file, log, cache, state file, or preview artifact is created;
- the only output is stdout/stderr process output.

## 7. Compatibility and final acceptance

Run the suite with Windows PowerShell 5.1 using `-NoProfile`, `-NonInteractive`, and `-ExecutionPolicy Bypass`. Parse `tools/run_trigger_a.ps1` with the Windows PowerShell 5.1 AST parser before functional cases.

Final acceptance requires:

- AST errors: `0`;
- positive cases: `2/2 PASS`;
- negative cases: `6/6 rejected with non-zero exit`;
- baseline or manifest invocation mutations: `0`;
- output or Archive artifacts created: `0`;
- `git diff --check`: PASS.

Any failed assertion makes the Trigger A dry-run regression result FAIL.
