# APL US Stock Cover Image Prompt Template

This template defines the two-step production method for APL Momentum Leaders 領導股 Blog Cover and SEO visual creation.

When Trigger C inputs are complete, Codex owns this two-step workflow by default. It must create the brief and generate the background from the approved market narrative; it must not redirect normal background creation to the user.

It follows the XAUUSD-style workflow:

```text
Blog Article
↓
Extract Market Conclusion
↓
Extract Capital Flow
↓
Choose One Visual Metaphor
↓
Create ChatGPT Image Brief
↓
Generate cinematic background with ChatGPT / ImageGen
↓
Local text overlay
↓
Final QC
```

The main visual background must not be created by local SVG / shape rendering.

Local rendering is only for accurate overlay and final export.

---

## 1. Production Responsibility Split

### Default execution authority

```text
Approved Market Narrative
↓
Codex creates Cover Brief
↓
Codex invokes image generation workflow
↓
Codex saves the selected no-text background inside the Project Root
↓
Codex passes CoverBriefPath + CoverBackgroundPath to production runner
↓
Local renderer adds exact text, date, logo and SEO layout
```

The user may explicitly supply an approved external background, but that is an override, not the default prerequisite. If image generation is unavailable or fails, Codex must report that concrete blocker rather than asking the generic question of who should create the cover.

### ChatGPT / ImageGen

Responsible for:

- understanding article narrative;
- extracting market conclusion;
- extracting capital flow;
- choosing one main visual metaphor;
- generating cinematic financial market background;
- creating concrete market environment;
- showing capital flow, risk background, and leadership destination;
- preserving text-safe area.
- generating background only, with no production typography or brand asset;
- returning a final selected bitmap that Codex copies into an approved project production-input location.

Not responsible for:

- Chinese text;
- dates;
- logo;
- precise numeric data;
- table;
- dashboard UI;
- sector information boxes.

### Codex / Local Post-production

Responsible for:

- adding accurate Chinese title;
- adding subtitle;
- adding APL Momentum Leaders text;
- adding date;
- adding APL / Deep-Scan logo;
- adjusting spacing, line height, proportions, and position;
- exporting required final sizes.

Codex must not use local shapes / SVG renderer to create the Blog Cover main visual.

---

## 2. ChatGPT Cover Image Brief

Before image generation, create the following brief.

### Market Conclusion

What is the market doing in this issue?

Write one clear sentence.

### Capital Flow

Where is capital rotating from?

Where is capital rotating to?

### Risk Background

What risk remains visible in the market?

Examples:

- oil risk;
- rates;
- AI capex;
- valuation pressure;
- geopolitical risk;
- sector correction;
- liquidity pressure.

### Leadership Destination

Which leadership structures are receiving capital?

Examples:

- AI infrastructure;
- healthcare / bio;
- semiconductors;
- financials;
- industrials;
- energy;
- data centers.

### Main Visual Metaphor

If this article were a movie poster, what is the single strongest scene?

The metaphor must be concrete.

Avoid mixing too many metaphors.

### Composition

Required composition:

- top 35–40% reserved as text-safe area;
- bottom 60–65% carries cinematic market story;
- main object separated from text area;
- clear foreground / midground / background depth;
- no Dashboard;
- no floating widgets;
- no presentation-slide layout;
- no abstract decorative flow lines.

---

## 3. AI Background Rules

The AI-generated background must contain:

- concrete market environment;
- real industry scene;
- clear capital flow direction;
- risk background;
- cinematic lighting;
- depth;
- fog / particles / atmosphere;
- motion or directional energy;
- blue / cyan / gold primary palette;
- red / green only for risk / rotation signals.

The AI-generated background must not contain:

- text;
- date;
- logo;
- random letters;
- fake tickers;
- sector information boxes;
- table;
- dashboard;
- radar UI as main scene;
- floating widgets;
- generic abstract background.

---

## 4. Local Overlay Specification

Local post-production may add only:

- `Deep-Scan`;
- main Chinese title;
- subtitle;
- `APL Momentum Leaders`;
- `YYYY.MM.DD`;
- APL / Deep-Scan logo;
- necessary minimal sector labels.

Local post-production must not add:

- large information boxes;
- Dashboard widgets;
- decorative capital-flow curves;
- local-shape main scene;
- infographic layout that weakens the cinematic background.

---

## 5. Final Overlay Text Block

Use this structure:

```text
Deep-Scan

[Main Chinese Title]
[Subtitle]

APL Momentum Leaders | YYYY.MM.DD
```

Text must be:

- accurate;
- readable;
- high contrast;
- visually separated from the background story;
- aligned with APL brand.

---

## 6. Validation Checklist

Reject and redesign if any answer is No.

1. Does the cover show a market story?
2. Is the capital flow visible?
3. Is there one concrete visual metaphor?
4. Is the scene cinematic rather than diagram-like?
5. Are Risk + Rotation + Leadership Destination visible?
6. Is the local text readable?
7. Is it clearly not a Dashboard?
8. Is it clearly not a table card?
9. Is it clearly not a presentation slide?
10. Does it match the article's actual conclusion?

---

## 7. Deprecated Cover Methods

The following methods are deprecated for Blog Cover main visual creation:

- local SVG as final Blog Cover;
- PowerShell-created narrative background;
- shape-based cinematic simulation;
- abstract radar cover;
- flow-line infographic cover;
- card-based cover storytelling.

Local renderer may still be used for:

- precise text overlay;
- logo placement;
- final export;
- Dashboard;
- Social Card;
- Table Card.
