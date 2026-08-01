# APL US Stock Table Card Input Contract

Version: APL Table Card Input v1.1

This document defines the production input contract for APL Blog Table Cards.

Table Cards are research information cards. They are not CSV screenshots and should not reproduce full raw tables.

---

## 1. Renderer Responsibility

The Table Card renderer accepts:

```text
CardType
Structured JSON input
Output path
Canvas size
```

The renderer is responsible for:

- applying the APL Table Card visual style;
- rendering one card per run;
- using the canonical CardType semantic-field-to-column mapping;
- preserving readability at 1600×900.

The renderer is not responsible for:

- deciding article conclusions;
- calculating rankings;
- transforming raw CSV into research meaning;
- selecting which table belongs in the Blog.

---

## 2. CardType

Valid CardType values:

```text
ExecutiveSummary
TopLeaders
TopGainers
SectorStructure
MarketObservation
Comparison
```

The command line `-CardType` is the production source of routing.

The JSON input must include `CardType`, and it must match the command line `-CardType`.

---

## 3. Required JSON Fields

Minimum valid input:

```json
{
  "SchemaVersion": "APL Table Card Input v1.1",
  "CardType": "TopGainers",
  "Title": "Top Gainers — Past 7 Days",
  "Rows": [
    {
      "symbol": "SYM",
      "companyName": "Company",
      "sectorTheme": "Technology services",
      "changePct": "+12.30%"
    }
  ]
}
```

For `CardType: TopGainers`, `Title` must be exactly `Top Gainers — Past 7 Days`. This is a fixed cross-output title and validation must fail if wording, spacing, capitalization or a suffix differs.

Required:

- `SchemaVersion`
- `CardType`
- `Title`
- `Rows`

Recommended:

- `Subtitle`
- `SourceNote`
- `Meta`

Optional:

- `FooterNote`

---

## 4. Canonical semantic fields and columns

`Columns` is renderer-owned and must not be supplied in v1.1 input. The renderer and validator share one mapping:

- `ExecutiveSummary`: `observation`, `meaning`.
- `TopLeaders`: `rank`, `symbol`, `companyName`, `coreBusiness`, `mainDriver`, `compositeScore`.
- `TopGainers`: `symbol`, `companyName`, `sectorTheme`, `changePct`.
- `SectorStructure`: `theme`, `count`, `direction`, `representativeSymbols`.

TopLeaders renders Score as its own column. SectorStructure renders `theme | count` in the Theme column. No positional array mapping is permitted.

---

## 5. Rows

Rows must be JSON objects with the exact named fields required by their `CardType`.

Rules:

- 1–8 rows.
- Required values cannot be null, empty, or whitespace-only.
- Header count must equal the renderer's mapped display-field count.
- `compositeScore` must be numeric and cannot occupy `coreBusiness`.
- `changePct` must be a signed percentage and cannot occupy `sectorTheme`.
- `representativeSymbols` must be a symbol list and cannot occupy `direction`.
- Cell content should be concise.
- Avoid paragraph-length cells.
- Do not include raw CSV columns that do not support the article conclusion.

Recommended row count:

```text
3–5 rows for Blog readability.
```

---

## 6. Source Note

TopGainers cards should include or default to:

```text
Scope: SPX／NDX／DJI constituents. Rankings, prices and changes are point-in-time market data and may change with the market.
```

Do not wrap the note in HTML tags.

---

## 7. Meta

`Meta` is optional and used for traceability.

Example:

```json
{
  "Meta": {
    "Date": "2026-07-12",
    "Source": "SPX/NDX/DJI constituents",
    "MarketTheme": "AI Infrastructure / Healthcare",
    "ProductionNote": "Formal Blog table card"
  }
}
```

Meta should not be rendered unless the renderer explicitly supports it.

---

## 8. Production Rules

Table Card production must follow these rules:

- One renderer run creates one card.
- One card has one clear purpose.
- Card content must be structured input, not copied CSV.
- Blog Table Cards should communicate meaning before raw numbers.
- Do not use radar background as a generic table background.
- Do not generate large empty table grids.
- Do not use more columns than needed.
- Do not include full Top 30 ranking tables in a Blog Table Card.

---

## 9. Related Files

Machine-readable schema:

```text
tools/table_card_input.schema.json
```

Renderer:

```text
tools/render_blog_table_cards.ps1
```

Visual / content template:

```text
KnowledgeBase/Templates/Table_Card_Template.md
```
