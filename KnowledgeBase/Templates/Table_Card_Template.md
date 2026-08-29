# APL US Stock Table Card Template

This template defines Blog Research Information Cards.

Table Cards are not CSV screenshots.

They convert structured information into visual research insights for the Blog.

Production input contract:

```text
KnowledgeBase/Templates/Table_Card_Input_Contract.md
tools/table_card_input.schema.json
```

Daily Trigger C production uses a deterministic manifest:

```text
tools/table_card_manifest.schema.json
```

Each manifest item contains `CardType`, `InputPath`, `OutputName` and boolean `Required`. Input paths may be absolute or relative to the manifest file. CardType and OutputName must be unique.

### Daily Trigger C required profile

The standard daily Blog package requires these four cards:

| CardType | Blog role | Required |
|---|---|---:|
| `ExecutiveSummary` | Key Signals | Yes |
| `TopLeaders` | Top 3／Top 5 Leaders | Yes |
| `TopGainers` | SPX／NDX／DJI constituent Top Gainers | Yes |
| `SectorStructure` | Leadership／sector structure | Yes |
| `MarketObservation` | Additional issue-specific observation | No |
| `Comparison` | Optional comparison when supported by the article | No |

Do not generate all six merely because the renderer supports six types. Optional cards are selected only when the approved article narrative needs them.
### Fixed user-facing presentation sequence

The completed package must be presented to the user as five individual links in this fixed order:

1. `Executive Summary`
2. `Deep-Scan Dashboard`
3. `Top Gainers`
4. `Top Leaders`
5. `Sector Structure`

Dashboard remains an independent package-root artifact and is included only to give the reader complete scan context at the correct point in the presentation. This sequence does not change the four required `CardType` values, renderer inputs, manifest evidence or physical package structure. A folder-only `Table Cards` link is not a substitute for the five ordered links.

The four required cards are companion publishing assets, not four alternate summaries of the same dataset:

| CardType | Single reasoning responsibility |
|---|---|
| `ExecutiveSummary` | Select the issue's three to five highest-priority observations and explain why they matter |
| `TopLeaders` | Show representative medium-term company leadership from the current Trigger B ranking |
| `TopGainers` | Show representative short-term price leadership from the current Top Gainers source |
| `SectorStructure` | Determine whether current Top 30 representatives form meaningful groups |

Evidence may overlap when necessary, but repeating the same rows or conclusion without a different reasoning function is a role failure.

---

## 1. Common Style

Recommended base format:

```text
1600 × 900
```

Common visual language:

- deep navy dark card;
- rounded cyan frame;
- institutional research feel;
- fewer columns;
- large row spacing;
- observation / meaning first;
- only necessary data;
- high readability;
- no radar background;
- no full CSV export;
- no large empty table grid.

---

## 2. Card Type｜Executive Summary Card

### Purpose

Summarize the issue's most important observations.

### Fixed Elements

- title;
- 3–5 key observations;
- short implication for each observation.

For new packages, write both `Observation` and `Meaning` as concise Chinese reader-facing prose. Do not paste raw field labels such as `Universe 604; qualified 314`, or unexplained English-only metric names. If a metric is material, state what it implies for concentration, breadth, participation or entry difficulty; explain `Leader Lock`, `Buyability` and similar terms in the paired `Meaning` text.

### Variable Elements

- market theme;
- sector rotation;
- Leader Lock count;
- Top Gainers signal;
- risk background.

Universe, Qualified Stocks, Momentum Leaders, Leader Lock and other scan metrics are optional. Use one only when its level or change is itself a client-priority signal for the current issue.

### Recommended Columns

```text
Observation
Meaning
```

### Exclude

- full ranking;
- excessive metrics;
- raw CSV fields.
- a fixed Universe／Qualified／Leaders funnel that duplicates Deep-Scan Overview or Dashboard;
- row-level repetition of the TopLeaders, TopGainers or SectorStructure cards.

### ExecutiveSummary writing example

Use a short Chinese observation that gives the figure a reader-facing meaning, followed by a Chinese explanation:

```text
Observation：數據現狀：全市場 604 檔，經篩選後合格者 314 檔，最終 Top 30 僅佔 9.5%，顯示資金集中度極高。
Meaning：這個集中度表示指數反彈未等於全面擴散，後續要看領導股能否由少數個股擴展至更多產業群組。
```

Do not start the observation with raw labels such as `Universe`, `qualified`, `average Momentum` or `final watchlist`. Explain `Leader Lock` and `Buyability` in `Meaning` when those terms are material to the issue.

### Example Content Logic

```text
Observation: Healthcare / Bio dominates Momentum Leaders
Meaning: capital is rotating beyond a single AI trade
```

---

## 3. Card Type｜Top Leaders Card

### Purpose

Explain the most important APL Momentum Leaders 領導股.

### Fixed Elements

- rank;
- symbol;
- company / business area;
- core business;
- main driver.

### Variable Elements

- Top 3 / Top 5;
- business classification;
- sector theme;
- leadership implication.

### Recommended Columns

```text
Rank
Symbol
Core Business
Main Driver
```

### Exclude

- full composite formula;
- unnecessary score columns;
- long company descriptions.

### Example Content Logic

Focus on why these leaders matter, not just their score.

---

## 4. Card Type｜Top Gainers Card

### Purpose

Show recent 7-day market temperature using the approved SPX／NDX／DJI constituent Top Gainers input.

### Fixed Elements

- title: `Top Gainers — Past 7 Days` — fixed canonical English title; exact wording, capitalization, dash and spacing required;
- source note;
- leading sectors / companies;
- market implication.

The `TopGainers` contract and renderer must reject any other title, including titles with a `｜...` suffix. Issue-specific commentary belongs in `Subtitle`, rows or explanatory text, never in the fixed title.

### Variable Elements

- top names;
- sector grouping;
- short-term market signal.

### Recommended Columns

```text
Symbol
Company
Sector / Theme
Change
```

### Exclude

- too many ranks;
- price columns if not needed;
- raw screener-style table.

### Required Source Note

```text
Scope: SPX／NDX／DJI constituents. The ranking, prices and changes are point-in-time market data and may change with the market.
```

---

## 5. Card Type｜Sector Structure Card

### Purpose

Explain sector distribution and what it means.

### Fixed Elements

- sector / theme;
- representative direction;
- representative symbols;
- implication.

### Variable Elements

- dominant sector;
- emerging sector;
- capital rotation direction.

### Recommended Columns

```text
Theme
Direction
Representative Symbols
Implication
```

### Exclude

- full sector table;
- all minor categories;
- decorative bars without explanation.

---

## 6. Card Type｜Market Observation Card

### Purpose

Turn a research observation into an easy-to-read visual.

### Fixed Elements

- observation;
- implication;
- evidence.

### Variable Elements

- current market condition;
- capital flow;
- risk signal;
- leadership signal.

### Recommended Columns

```text
Observation
Meaning
```

### Exclude

- raw data dump;
- unsupported claims;
- excessive footnotes.

---

## 7. Card Type｜Comparison Card

### Purpose

Compare two market structures or two signal groups.

### Fixed Elements

- group A;
- group B;
- difference;
- implication.

### Variable Elements

- Top Gainers vs Momentum Leaders;
- short-term vs medium-term;
- AI vs Healthcare;
- risk-on vs defensive leadership.

### Recommended Columns

```text
Signal
What It Shows
Market Meaning
```

### Exclude

- full ranking;
- over-detailed statistical table.

---

## 8. General Table Card Rules

Every Table Card should answer:

```text
What does this data mean?
```

Before showing:

```text
What are the numbers?
```

If the reader cannot understand the card in a few seconds, reduce columns and increase spacing.

Before publication, confirm:

- the card performs only its assigned reasoning responsibility;
- repeated facts match the current managed source;
- the card adds independent client value rather than duplicating Dashboard, Social Card or another Table Card.
