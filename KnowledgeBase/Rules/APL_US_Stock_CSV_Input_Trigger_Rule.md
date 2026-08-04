# APL US Stock CSV Input Trigger Rule

This Rule defines how Codex must classify an uploaded CSV and route it into the existing APL US Stock Production Workflow.

It controls input recognition and action selection only. It does not change scoring, ranking, renderer logic, or the production workflow.

## 1. Authority

For CSV attachment recognition, this file is the canonical **User Input → Production Action Mapping**.

It must be read together with:

- `APL_US_Stock_Trigger_Rules.md`;
- `APL_US_Stock_Watchlist_Rules.md`;
- Project Root `APL_US_Stock_Production_Workflow_Specification_v1.0.md`.

If this routing Rule conflicts with scoring, ranking, watchlist, Blog, or visual Rules, the domain Rule controls the processing logic. This file controls only which existing workflow is selected.

## 2. Repository onboarding behavior

When Codex is working inside the APL-US-STOCK repository, it must inspect the uploaded file name before asking a generic intent question.

If the file name unambiguously matches a mapping in this Rule, Codex must:

1. identify the matched input type;
2. announce the selected Trigger and mode briefly;
3. inspect and validate the CSV;
4. begin the mapped workflow using the repository Rules;
5. ask only for a specific missing required companion input or a concrete ambiguity.

For an unambiguous recognized input, Codex must not ask:

```text
希望如何處理這份 CSV？
```

Uploading a recognized file is the user's authorization to start the mapped existing workflow. It is not authorization to Commit, Push, create a tag, overwrite production output, or bypass validation.

## 3. Filename recognition

Recognition is case-insensitive on Windows. `YYYY-MM-DD` must be a valid calendar date. An optional suffix may follow the date, separated by `_`.

### Daily breakout screener

Accepted forms:

```text
APL Breakout Screener_YYYY-MM-DD.csv
APL Breakout Screener_YYYY-MM-DD_<suffix>.csv
```

This includes the canonical upload name:

```text
APL Breakout Screener_YYYY-MM-DD.csv
```

### Cumulative breakout screener

Accepted forms:

```text
APL Breakout Screener Cumulative_YYYY-MM-DD.csv
APL Breakout Screener Cumulative_YYYY-MM-DD_<suffix>.csv
```

`Cumulative` is significant. A daily breakout screener must never be promoted to cumulative input merely because cumulative processing would produce more outputs.

## 4. User Input → Production Action Mapping

| User input | Classification | Automatic action | Forbidden escalation |
|---|---|---|---|
| `APL Breakout Screener_YYYY-MM-DD.csv` or accepted suffixed form | Daily Breakout Screener | Enter Trigger A — Watchlist Update Mode | No SMA200 removal, scoring, ranking, Top 30, Dashboard, Social Card, Blog, Cover, SEO, or Table Cards |
| `APL Breakout Screener Cumulative_YYYY-MM-DD.csv` or accepted suffixed form | Cumulative Breakout Screener | Enter Trigger B — Deep-Scan Research Mode | No formal Blog package unless all Trigger C inputs are present |
| Cumulative Breakout Screener + recent 7-day Top Gainers + Market Context | Complete Trigger C input set | Enter Trigger C — APL Momentum Leaders Blog Production Mode | No bypass of Trigger B validation or production guards |
| Top Gainers only | Supporting input only | Record and validate the input; wait for the remaining Trigger C inputs | No scoring, Watchlist update, Dashboard, Blog, or Social package |
| Market Context only | Supporting input only | Record and validate the input; wait for the remaining Trigger C inputs | No scoring, Watchlist update, Dashboard, Blog, or Social package |
| Unknown CSV filename | Unclassified input | Inspect non-destructively, then ask a focused classification question | Do not infer Trigger A, B, or C |

## 4A. External upload intake and Trigger A output boundary

An uploaded CSV may initially be located in `Downloads` or another path outside the repository. That path is intake-only and must never be passed directly to a production script. The workflow must first copy the file into the repository-managed, date-scoped intake directory:

```text
work/trigger-a-inputs/YYYY-MM-DD/
```

The source and managed copy must have identical bytes and SHA-256. The managed copy is then parsed with the approved robust CSV parser; ordinary `Import-Csv` must not be used when duplicate headers are present. Trigger A must run in this order:

```text
Repository intake copy
→ SHA-256 verification
→ robust CSV validation
→ Trigger A dry-run
→ Trigger A write-output
```

The dry-run must pass before any output write. The only Trigger A output is written to:

```text
outputs/trigger-a/YYYY-MM-DD/APL_Quant_Cumulative_Watchlist_YYYY-MM-DD.txt
```

Trigger A must never create `outputs/YYYY-MM-DD/`, which is reserved for the complete atomic Production package. The intake copy is an input fixture, not a rule source, and must not be used to bypass the canonical repository-managed watchlist baseline.

## 5. Trigger A automatic response

For a canonical daily input such as:

```text
APL Breakout Screener_2026-07-13.csv
```

Codex should respond in substance:

```text
已識別為 APL Breakout Screener daily CSV，進入 Trigger A／Watchlist Update Mode。我會先驗證 CSV，然後按 Watchlist Rules 合併、去重並輸出 cumulative watchlist；不會執行 scoring、ranking 或 renderer。
```

Codex then starts the workflow. If the previous cumulative watchlist required for merging is unavailable, Codex asks specifically for that file or identifies the approved repository source. It must not fall back to a generic question about the purpose of the CSV.

## 6. Trigger B automatic response

For a canonical cumulative input such as:

```text
APL Breakout Screener Cumulative_2026-07-13.csv
```

Codex should respond in substance:

```text
已識別為 APL Breakout Screener Cumulative CSV，進入 Trigger B／Deep-Scan Research Mode。我會先驗證 cumulative input，再按既有 scoring、ranking、watchlist、validation 及 renderer workflow 執行；不會自動升級為 Trigger C Blog production。
```

Codex must use the existing implementation. It must not recreate or modify scoring or ranking logic.

## 7. Trigger C Cover workflow

When Cumulative Breakout Screener, recent 7-day Top Gainers and Market Context are all present, Codex must not treat `CoverBackgroundPath` or `SeoBackgroundPath` as a background-design task for the user. The default action is:

1. derive the formal Cover Brief from the approved market narrative and research conclusion;
2. validate the Cover Brief against `tools/cover_image_brief.schema.json`;
3. define one shared scene concept and invoke the image generation workflow for a native 4:5 Cover view and an independent native 16:9 SEO view;
4. reject either generated background if it contains text, logo, ticker, table, dashboard UI or floating information cards;
5. save both selected backgrounds and their separate native records to an approved Project Root production-input path outside `tmp/`;
6. validate the shared scene identity, role-specific framing, paths, dimensions, SHA-256 and `transformation=none`;
7. pass the sources as `CoverBackgroundPath` and `SeoBackgroundPath` to the existing production runner;
8. use the local renderer for exact title, subtitle, date, logo and role-specific overlay layout without deriving one background from the other.

The user may explicitly provide an approved background, but Codex must not require this during the normal Trigger C flow. If image generation is unavailable or fails, Codex reports that specific blocker and preserves all validation and no-overwrite boundaries.

## 8. Validation and ambiguity rules

Before producing output, Codex must verify at minimum:

- the attachment is readable CSV;
- the filename date is valid;
- the CSV structure is compatible with the selected existing workflow;
- the filename classification does not conflict with the file content;
- required companion inputs for the selected mode are available.

If validation fails, Codex must stop the mapped production action and report the exact failure. It must not silently route the file to a different Trigger.

Examples requiring a focused question or failure:

- a filename says `Cumulative` but the content is clearly a daily incremental export;
- the date is missing or invalid;
- required columns cannot be read;
- two uploaded files map to conflicting scan dates;
- a Trigger C request is missing Top Gainers or Market Context.

## 9. Cross-PC alignment rule

The expected behavior on every clone is:

```text
Recognized CSV attachment
↓
Filename classification
↓
Input validation
↓
Mapped existing APL Trigger
↓
Production action allowed by that Trigger
```

Machine-specific chat history, prior conversation memory, local outputs, Archive, and examples must not be required for classification. The routing decision must be reproducible from repository Rules.
