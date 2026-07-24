# APL US Stock Archive Index Policy

`Archive/index.md` is a generated navigation and status index. It is not a substitute for a v2 archive manifest.

## Authority

- Adoption marker：`tools/archive-v2-policy.json`
- Marker schema：`tools/archive-v2-policy.schema.json`
- V2 manifest schema：`tools/archive_manifest.schema.json`
- Runtime validation：`tools/production_archive_common.ps1`
- Index generator：`tools/archive_daily_production.ps1`

## Row schema

```text
Date | Status | Files | Bytes | Manifest | Notes
```

### V2 Verified Archive

```text
YYYY-MM-DD | PASS | <verified count> | <verified bytes> | YYYY/YYYY-MM-DD/archive-manifest.json | V2 manifest verified
```

The manifest schema, date, status, file records, count, bytes and SHA-256 must match the actual Archive directory.

### Transient same-date recovery state

`PENDING_INDEX` is a provisional manifest state used only while the same date is being finalized or resumed by `archive_daily_production.ps1`. It is never a valid row in the durable Archive index and must not be carried into a different date's index update.

If index generation encounters `PENDING_INDEX` for a date other than the date currently being resumed, Archive must fail closed. The incomplete date must be resumed and reach final manifest `Status=PASS` before another date can complete Archive.

### Legacy Unverified Archive

```text
YYYY-MM-DD | LEGACY_UNVERIFIED | <inventory count> | <inventory bytes> | N/A | Pre-v2 archive; inventory-only counts; integrity not attested
```

Legacy classification requires both conditions:

1. date is earlier than the tracked `AdoptionDate`;
2. date is exactly present in `LegacyUnverifiedDates`.

The count and bytes are read-only current inventory statistics. They do not prove historical completeness, do not include historical SHA attestation, and must not be described as v2 verification.

## Fail-closed cases

Index generation fails when:

- an unknown date has no v2 manifest;
- an adoption-date-or-later directory has no v2 manifest;
- a v2 manifest is malformed, unsupported or inconsistent with actual files;
- a different date remains at provisional `PENDING_INDEX`;
- an allowlisted legacy date contains a purported v2 manifest without an approved migration;
- the index contains duplicate date rows or values inconsistent with a verified manifest／legacy inventory.

Index content is deterministically sorted by date descending and must be identical on an unchanged rerun. The workflow never creates historical manifests or modifies legacy files as part of index generation.
