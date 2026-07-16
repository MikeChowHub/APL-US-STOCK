# APL US Stock Archive Rules

## 1. Authority and completion boundary

本文件是當日 Production Archive 的永久規則來源。

當日 Production 的唯一完成鏈如下：

```text
Production PASS
→ Final Production Audit PASS
→ Archive Copy
→ file count / size / SHA-256 audit
→ Archive index update
→ Archive PASS
→ Daily Production Complete
```

Final Production Audit PASS 之前禁止執行 Archive。Archive PASS 之前，不得把當日 Production 標示為 Complete。

## 2. Source and destination

- 正式來源：`outputs/YYYY-MM-DD/`
- 正式目標：`Archive/YYYY/YYYY-MM-DD/`
- 日期目標不得覆蓋。既有目標只可在 manifest 為 PASS 且逐檔重新驗證一致時視為可重用。
- Archive 必須 Copy 來源檔案；不得以 Move 或 Delete 取代來源。
- 驗證後將 Archive staging directory 發布至日期目標，不會移動或刪除 `outputs/YYYY-MM-DD/`。

Regression 只能在 `tmp/` 內使用隔離的 `_archive/` 驗證同一流程，不得寫入正式 `Archive/`。

## 3. Archive v2 adoption and legacy compatibility

Repository marker `tools/archive-v2-policy.json` is the authority for Archive v2 adoption. Its initial policy is:

```text
AdoptionDate: 2026-07-15
MarkerId: APL-ARCHIVE-V2-2026-07-15
```

Archive dates have two distinct classifications:

1. `PASS` — V2 Verified Archive. It has a supported `archive-manifest.json`; relative paths, file count, bytes, SHA-256 and index row have been verified.
2. `LEGACY_UNVERIFIED` — a pre-v2 date explicitly listed in `LegacyUnverifiedDates`, with no v2 manifest. Its files are retained unchanged, but integrity is not attested.

Manifest absence alone never grants legacy status. A date may be `LEGACY_UNVERIFIED` only when it is earlier than `AdoptionDate` and exactly allowlisted by the tracked policy. Any adoption-date-or-later directory, or any unknown pre-adoption directory, must fail if its v2 manifest is missing or invalid.

An allowlisted legacy date must not contain or claim a v2 PASS manifest. Moving a date from legacy to v2 requires a separate approved migration backed by trustworthy source artifacts and historical evidence; the policy must be updated at the same time. Inventory-only observation must never be represented as historical v2 verification.

## 4. Retention scope

應保留正式且可發布、可稽核的內容，包括：

- Blog Markdown 與 HTML
- Top 30、ranking、watchlist 與 company analysis
- publishing materials 與 WhatsApp materials
- Dashboard、Social Card、Table Cards
- Cover、SEO
- publication manifest、Final Production Audit
- 必要 contracts、audit 與 renderer logs

來源的相對目錄結構必須保留，避免重新分類造成 trace path 與檔名歧義。

新式 Trigger C output 必須包含已通過 Final Audit 的 `production-package/`。Archive V2 必須原樣保留該目錄、`Table Cards/` 子目錄及 package manifest。Archive executor不得將 package檔案攤平、重新命名或搬回日期根目錄。Final Audit未提供 `ProductionPackage.Status=PASS`及四張Table Card semantic PASS evidence時，Archive必須拒絕執行。

## 5. Exclusions

不得納入：

- `.staging/`、`staging/`
- `tmp/`、`temp/`、`temporary/`
- `cache/`、`.cache/`、`node_modules/`
- `typography-comparison/`、FontAudit、Typography Comparison、diagnostic、environment test
- `*.tmp`、`*.temp`、`*.bak`、`*.cache`、`*.partial` 及 `~` 開頭暫存檔

排除只影響 Archive selection，不得刪除或修改來源檔案。

## 6. Verification and evidence

Archive Copy 後必須逐檔核對：

1. 相對路徑
2. file count
3. 每檔 bytes
4. 每檔 SHA-256
5. total bytes

全部一致才可寫入 `archive-manifest.json`，其 `Status` 必須為 `PASS`。任何 count、size、SHA-256 或路徑不一致都必須 fail-fast，且不得更新為 Daily Production Complete。

Archive PASS 後必須更新 `Archive/index.md`。索引至少記錄日期、狀態、檔案數、總 bytes 與 manifest 路徑。

Index schema is fixed:

```text
Date | Status | Files | Bytes | Manifest | Notes
```

- V2 row：`PASS`、verified file count／bytes、`YYYY/YYYY-MM-DD/archive-manifest.json`、`V2 manifest verified`。
- Legacy row：`LEGACY_UNVERIFIED`、read-only inventory count／bytes、`N/A`、`Pre-v2 archive; inventory-only counts; integrity not attested`。

Legacy Files／Bytes are current read-only inventory statistics only. They are not historical SHA evidence and are not equivalent to a v2 manifest. Index generation must be deterministic and idempotent. Legacy rows must not block a valid new v2 Archive, but an unknown or post-adoption manifest-less date must block it.

## 7. Historical backfill prohibition

Unless complete and trustworthy original source plus historical evidence exist:

- do not create a historical `archive-manifest.json`;
- do not mark a legacy date PASS;
- do not modify, delete or overwrite historical Archive files;
- do not present a newly calculated inventory as if it were contemporaneous verification.

An optional future `legacy-inventory.json` may be inventory-only, but must declare its generation time, `inventory-only`, `not an integrity attestation`, and `not equivalent to v2 manifest`. The current workflow does not create this file.

## 8. Workflow ownership

- Archive 是 Production workflow 的必要步驟，由 `tools/run_daily_production.ps1` 在 Final Production Audit PASS 後自動呼叫 `tools/archive_daily_production.ps1`。
- 不需要等待使用者額外指示。
- Git Commit／Push／Tag 不負責觸發或補做 Archive。
- Production workflow 不自動 stage、commit、push 或 tag。
