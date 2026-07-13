# APL US Stock Table Card Input Contract

Version: APL Table Card Input v1.0

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
- using the selected CardType layout defaults when columns are omitted;
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

The JSON input may also include `CardType` for auditability. If JSON `CardType` is present, it must match the command line `-CardType`.

---

## 3. Required JSON Fields

Minimum valid input:

```json
{
  "SchemaVersion": "APL Table Card Input v1.0",
  "CardType": "TopGainers",
  "Title": "最近7日 Top Gainers",
  "Rows": [
    ["SYM", "Company", "Sector / Theme", "+12.3%"]
  ]
}
```

Required:

- `Title`
- `Rows`

Recommended:

- `SchemaVersion`
- `CardType`
- `Subtitle`
- `SourceNote`
- `Meta`

Optional:

- `Columns`
- `FooterNote`

---

## 4. Columns

Columns are optional.

If `Columns` is omitted, the renderer uses the default column structure for the selected CardType.

Column object:

```json
{
  "Label": "Symbol",
  "Width": 0.15,
  "Align": "Center",
  "Bold": true
}
```

Rules:

- 1–5 columns only.
- Column widths should sum to 1.0.
- If widths do not sum to 1.0, renderer may normalize them.
- Use fewer columns when the card is for Blog reading.

Allowed alignment:

```text
Near
Center
Far
```

---

## 5. Rows

Rows must be structured arrays.

Rules:

- 1–8 rows.
- Each row should match the intended column count.
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
資料來源為 TradingView，排名、價格及升幅會隨市場變動。
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
    "Source": "TradingView",
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
