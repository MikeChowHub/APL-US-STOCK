# APL US Stock Renderer Input Contract

Version: APL Renderer Input Contract v1.0

This document defines the production input boundary for APL visual renderers.

Renderers are not research engines. They should receive prepared, structured data and render it consistently.

---

## 1. Renderer Classes

APL production uses three renderer classes:

```text
Deep-Scan Dashboard Renderer
Deep-Scan Social Card Renderer
Blog Table Card Renderer
```

Blog Cover is intentionally excluded from this contract because its main visual is generated through the separate cinematic ImageGen workflow.

---

## 2. Dashboard / Social Input Contract

Dashboard and Social renderers share the same Deep-Scan input contract.

Machine-readable schema:

```text
tools/deep_scan_renderer_input.schema.json
```

Required production inputs:

```text
RendererType
RankingCsv
ScanDate
SectorMapPath
```

Optional production inputs:

```text
OutputDir
LogoPath
WeekLabel
ScanUniverseCount
ScanQualifiedCount
LeaderCapacity
Meta
```

For a formal `Social` contract, `Meta.SocialHeadlineLines` and `Meta.CoreMarketThesis` are supplied together. The headline contains one or two mobile-readable lines from the approved Cover Brief; the thesis is the preflight-verified value shared verbatim by approved Market Context metadata and Cover Brief `sceneConcept.coreMarketThesis`. Regression／direct CLI rendering may omit both and use the renderer's conservative evidence-only fallback.

### RankingCsv

The ranking CSV must already be prepared by the research pipeline.

The renderer must not:

- calculate Momentum Score;
- calculate Buyability;
- calculate Composite Score;
- decide eligibility;
- reorder the ranking.

The renderer may only read Rank 1–30 from the prepared ranking output.

### SectorMapPath

Sector mapping must come from an external sector map file.

Default:

```text
tools/sector_map.json
```

Schema:

```text
tools/sector_map.schema.json
```

Dashboard and Social renderers must use the same sector map.

Renderer scripts must not maintain separate hardcoded symbol-sector maps.

---

## 3. Blog Table Card Input Contract

Table Card renderer uses a separate card-level input contract.

Machine-readable schema:

```text
tools/table_card_input.schema.json
```

Human-readable contract:

```text
KnowledgeBase/Templates/Table_Card_Input_Contract.md
```

Rules:

- one renderer run creates one card;
- one card has one clear purpose;
- card content must be structured JSON input;
- raw CSV screenshots are not valid production input;
- JSON `CardType`, if present, must match CLI `-CardType`.

---

## 4. Production Source Rules

Valid production sources:

```text
tools/render_deep_scan_dashboard_svg.ps1
tools/render_deep_scan_social_card_svg.ps1
tools/render_blog_table_cards.ps1
tools/render_blog_cover_overlay.ps1
```

Deprecated / non-production sources:

```text
tmp/
prototype scripts
old cover regeneration scripts
browser cache folders
manual screenshot-based render output
```

Temporary files may be used for testing, but they must not become production source of truth.

---

## 5. Production Validation

Before formal production, validate:

- required input files exist;
- ranking CSV has Rank and Symbol columns;
- sector map JSON is valid and contains Symbols;
- table card JSON is valid UTF-8;
- renderer output dimensions match the intended format;
- renderer log is created.

---

## 6. Related Templates

```text
KnowledgeBase/Templates/Dashboard_Render_Template.md
KnowledgeBase/Templates/Social_Card_Template.md
KnowledgeBase/Templates/Table_Card_Template.md
```
