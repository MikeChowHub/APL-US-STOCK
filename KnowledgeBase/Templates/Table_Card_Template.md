# APL US Stock Table Card Template

## 升幅統計時段 — 2026-10-06 修訂

出稿前核對 CSV 升幅欄位。現行來源 `Price change %, 1 day` 為單日數據，文章標題須為 `Top Gainers — 1 Day｜單日升幅榜`，圖卡標題須為 `Top Gainers — 1 Day`；正文、百分比標籤及 WhatsApp 必須同樣採單日口徑。不得把觀察名單、匯出日期或累積掃描期間當成升幅計算期間。若來源改為七日數據，必須先同步更新欄位驗證與標題合約，再生產，不能用單日數值寫成七日升幅。此規則取代舊有固定七日標題；已封存原件保留，10月2日及5日另交付更正版。


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
| `ExecutiveSummary` | In three to five rows, connect the concrete market background to its investment meaning and the issue's selected companies |
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

依 Visual Rules 的 2026-10-27 修訂，通常使用四行，先交代市場變化及意義，再交代本期公司選擇。下例只示範寫法；往後必須按當期綁定新聞及公司研究重寫：

```text
Observation：AI業績周聚焦資本投入與企業預算
Meaning：區分基建投資與持續使用的企業服務

Observation：AI代理供應鏈風險凸顯權限治理需要
Meaning：平台防護、開發與身份管理成為研究重點

Observation：CRWD與GTLB為本期主要關注
Meaning：分別對應企業防護與軟件開發交付

Observation：NTRA延伸精準檢測方向
Meaning：臨床需求提供不同於IT支出的業務來源
```

不得報讀 Universe、qualified、平均模型分數、final watchlist 或 Leader Lock；不可用漏斗數字推定資金集中或淨流入。每行以客戶需要理解的背景、影響及選擇為主。交付前核對三個問題：市場變化是否具體？對選股的意義是否清楚？主要關注公司是否有研究支持？

### Example Content Logic

```text
Observation：主要關注公司涵蓋企業防護與精準檢測
Meaning：客戶預算及臨床支付形成不同需求來源
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

- title: `Top Gainers — 1 Day` — fixed canonical English title; exact wording, capitalization, dash and spacing required;
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
