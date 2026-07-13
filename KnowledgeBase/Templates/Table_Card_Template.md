# APL US Stock Table Card Template

This template defines Blog Research Information Cards.

Table Cards are not CSV screenshots.

They convert structured information into visual research insights for the Blog.

Production input contract:

```text
KnowledgeBase/Templates/Table_Card_Input_Contract.md
tools/table_card_input.schema.json
```

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

### Variable Elements

- market theme;
- sector rotation;
- Leader Lock count;
- Top Gainers signal;
- risk background.

### Recommended Columns

```text
Observation
Meaning
```

### Exclude

- full ranking;
- excessive metrics;
- raw CSV fields.

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

Show recent 7-day market temperature using TradingView Top Gainers.

### Fixed Elements

- title: 最近7日 Top Gainers;
- source note;
- leading sectors / companies;
- market implication.

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
資料來源為 TradingView，排名、價格及升幅會隨市場變動。
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
