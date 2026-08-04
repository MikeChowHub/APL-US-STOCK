# APL US Stock Trigger Rules

This document defines the trigger system for APL US Stock production.

The purpose is to prevent incorrect production flows, especially accidental full Blog production from a single Screener CSV.

## CSV Input Routing Authority

Codex attachment recognition and the canonical User Input → Production Action Mapping are defined in:

```text
APL_US_Stock_CSV_Input_Trigger_Rule.md
```

When an uploaded CSV unambiguously matches that Rule, Codex must enter the mapped Trigger automatically instead of asking a generic question about how to process the CSV. This changes routing behavior only; all processing boundaries below remain authoritative.

## Highest Priority Rule

```text
Any Screener CSV alone must not trigger full Blog production.
```

## Trigger A｜Watchlist Update Mode

### Trigger

```text
APL Breakout Screener_YYYY-MM-DD.csv
APL Breakout Screener_YYYY-MM-DD_*.csv
```

### Purpose

Trigger A updates the cumulative TradingView Watchlist by adding newly discovered symbols.

It is a collection process, not a quality-cleaning or research process.

### Flow

```text
APL Breakout Screener
↓
Read Symbols
↓
Merge with Previous Watchlist
↓
Remove Duplicate Symbols
↓
Output Updated Cumulative Watchlist
```

### Allowed Output

```text
outputs/trigger-a/YYYY-MM-DD/APL_Quant_Cumulative_Watchlist_YYYY-MM-DD.txt
```

### Intake and execution order

If the uploaded daily CSV is outside the repository, first copy it to the managed intake path `work/trigger-a-inputs/YYYY-MM-DD/` and verify source／copy SHA-256 equality. Production scripts must reject direct `Downloads` or other external paths. Validate the CSV with the robust parser, run `tools/run_trigger_a.ps1` in `dry-run` mode, and only after PASS run it in `write-output` mode. Trigger A must not create `outputs/YYYY-MM-DD/`; that namespace belongs only to complete atomic Production.

### Forbidden Actions

Trigger A must not run:

```text
SMA200 Removal
Composite Score
Scoring
Ranking
Top 30
Dashboard
Social Card
Company Analysis
Formal Blog
Cover
SEO Image
Table Cards
WhatsApp
Publishing Materials
```

## Trigger B｜Deep-Scan Research Mode

### Trigger

```text
APL Breakout Screener Cumulative_YYYY-MM-DD.csv
APL Breakout Screener Cumulative_YYYY-MM-DD_*.csv
```

### Purpose

Trigger B re-evaluates the cumulative research universe, calculates scores, generates rankings, and produces Deep-Scan research outputs.

### Flow

```text
APL Breakout Screener Cumulative
↓
Re-evaluate Full Universe
↓
Apply Watchlist Cleaning Rules
↓
Score Calculation
↓
Composite Ranking
↓
Top 30
↓
Research Outputs
↓
Dashboard
↓
Social Card
```

### Allowed Outputs

```text
Standalone namespace: outputs/trigger-b/YYYY-MM-DD/
Composite Score
Full Ranking CSV
Top 30 TXT / Markdown
Cumulative TradingView Watchlist
APL Momentum Leaders Overview
Company Business Analysis
Dashboard SVG / PNG
Social Card SVG / PNG
Social Radar SVG / PNG (complete Top 30 radar format)
Research Outputs
```

`outputs/YYYY-MM-DD/` is reserved for the complete atomic Daily Production package. Standalone Trigger B must never create or occupy that Final Production namespace. The internal Trigger B step used by `run_daily_production.ps1` continues to write only to its orchestrator-owned staging root before atomic publish.

### Forbidden Actions

Trigger B must not create the formal Blog publishing package by itself.

Forbidden:

```text
Formal Blog
Cover
SEO Image
Blog Table Cards
WhatsApp Publishing Post
Final Publishing Materials
```

## Trigger C｜APL Momentum Leaders Blog Production Mode

### Trigger Condition

Trigger C requires all of the following:

```text
APL Breakout Screener Cumulative
+
Top Gainers — Past 7 Days
+
Market Context
```

### Purpose

Trigger C produces the formal APL Momentum Leaders 領導股 publishing package.

Trigger C must execute editorial preparation after Trigger B results exist and before Managed Input Preflight. It must not emit the Blog Template skeleton, placeholder text, a one-section summary or an English test sentence as a formal artifact. The current Trigger B metadata／ranking, Top Gainers CSV and detailed Market Context are mandatory editorial evidence.

`tools/prepare_trigger_c_managed_inputs.ps1` is the Cross-PC executable preparation entry. `Initialize` accepts the three approved intake files, runs Trigger B in isolated staging and emits a source-bound work order without placeholders. Codex completes the issue-specific editorial and two-image native work inside that staging root. `Finalize` verifies the original hashes, runs Managed Input Preflight against staging and atomically publishes `work/managed-inputs/<ScanDate>/` only after PASS. Direct manual construction of the final managed-input directory is not the normal workflow.

If a source correction is required before Finalize, `Supersede` is the only replacement path: it validates the new input contract before preserving the matching old builder staging directory under the controlled rejected namespace, then creates a new hash-bound staging bundle. It must never edit a source already listed in SourceEvidence, overwrite a finalized managed bundle or delete the previous staging evidence.

Only a PASS `APL Editorial Completion Audit v1.1` with `ProductionReadiness=true` may enter the Production runner. The runner must execute the managed-input preflight itself before scoring; a separately executed preflight is useful operator feedback but is not authority to bypass the runner gate. `DailyProductionComplete=true` without `DailyProductionPublishable=true` is not a completed Trigger C production.

The v1.1 readiness evidence must bind the current cumulative screener, Trigger B metadata and full ranking, Top Gainers CSV, Market Context, all four Table Card semantic inputs, Cover Brief, the two distinct native backgrounds and both native composition records by path, byte size and SHA-256. Top Leaders rows must match the current Trigger B ranking in order, symbol, company identity and score; Top Gainers rows must match the current approved SPX／NDX／DJI constituent input in order, symbol, company identity and price change; and every Sector Structure representative must exist in the current Trigger B Top 30. Schema-only validation is insufficient.

### Allowed Outputs

```text
Formal Blog editorial manuscript (.md, text-only, no image references)
Publish-ready Blog HTML source (.html, article content only, no publishing metadata footer)
Cover (independent artifact)
SEO Image (independent artifact)
Table Cards (independent artifacts)
WhatsApp
Social Publishing Materials
Social Card PNG (mobile-first single-message visual)
Social Radar PNG (complete Top 30 radar visual, converted from its SVG)
Archive Package
```

Both Social artifacts are required in every Trigger C Production Package. They are separate renderer outputs: `APL_DeepScan_Social_Card_<ScanDate>_1080x1350.png` carries the concise mobile-first message, while `APL_DeepScan_Social_Radar_Top30_<ScanDate>_1080x1350.png` carries the complete Top 30 radar view. The Radar must be rendered from its own SVG and validated as a fresh 1080x1350 PNG; it must never replace, crop, or be derived from the Social Card.

The `.md` manuscript, independent `.html` source and visual artifacts share the same-date Production Package but remain separate outputs. Visual artifacts must never be embedded or referenced inside either text file. HTML article subheadings use `<h3>` and HTML article paragraphs use `<p>`. URL, Page title and Page description metadata must not be appended to the HTML source.

The Markdown manuscript must conclude with `## SEO and Sharing`, including the issue URL, Page title, Page description and a sharing summary. WhatsApp must include the same issue URL after its analysis and before its disclaimer. A raw-code `.txt` presentation of HTML source is an operator-delivery convention and requires an explicit Production Artifact Contract migration before it can replace or supplement the required `.html` artifact.

## Input Alone Rules

```text
Top Gainers alone must not trigger scoring, Watchlist update, Dashboard, Blog, or Social package.

Market Context alone must not trigger scoring, Watchlist update, Dashboard, Blog, or Social package.
```
