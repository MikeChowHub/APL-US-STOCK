# APL US Stock Blog Rules

This document defines stable writing rules for formal APL Momentum Leaders 領導股 Blog production.

Blog Rules answer:

- how the article should be structured;
- how market context should be integrated;
- what client-facing terminology must be used;
- how article text and visual artifacts must remain separated;
- what content is prohibited.

Visual styling belongs to Visual Rules and Templates.

## Editorial completion authority

Trigger C editorial preparation is a required stage between verified Trigger B outputs and Managed Input Preflight. The runner does not write, expand or correct editorial content; it only copies validated publishing artifacts.

Editorial completion requires both Blog formats to contain the ten mandatory analysis sections with substantive issue-specific content, detailed Market Context derived from the approved market-topic input, current Trigger B numbers, current Top Gainers evidence, a continuous reasoning chain, a responsive conclusion, a substantive WhatsApp summary and non-empty Company Business Analysis. Template placeholders, test sentences, summary shells and headings without analysis are not publishing artifacts.

`tools/validate_managed_inputs.ps1` is the fail-closed executable gate. It creates `APL_Editorial_Completion_Audit_<ScanDate>.json` only after content, source evidence and Markdown／HTML equivalence pass. Mechanical Production completion without this PASS evidence is not publishable completion.

Formal completion is:

```text
Mechanical Completion PASS
+ Editorial Completion PASS
→ DailyProductionComplete=true
→ DailyProductionPublishable=true
```

---

## 1. Article Flow

Formal Blog articles should follow this reading flow:

```text
Executive Summary
↓
Market Context
↓
為什麼要看 APL Momentum Leaders 領導股？
↓
Deep-Scan Overview
↓
最近7日 Top Gainers
↓
Momentum Leaders Analysis
↓
Sector Analysis
↓
Relative Volume / Market Activity
↓
Risk
↓
Deep-Scan Conclusion
↓
SEO / Publishing Notes
```

The Blog Markdown file is the formal article text manuscript. Visual artifacts are not part of this reading-flow source and must not be embedded or referenced inside it.

This structure reflects the research logic:

```text
What is happening in the market?
↓
Why does APL Momentum Leaders 領導股 matter?
↓
What did Deep-Scan find?
↓
What does it mean?
```

### Single narrative thread

Each issue must define one core market proposition. It is an issue-specific question and provisional market interpretation, not a fixed conclusion that every issue must use.

The article is a continuous reasoning chain, not a set of independent short articles. Each section performs one reasoning task, builds on the conclusion of the preceding section, and should end by naturally raising the next question. Do not restart the market background in each section or repeat the same conclusion without adding evidence or analytical progress.

```text
Market Context
→ What is the largest structural market change?

為什麼要看 APL Momentum Leaders 領導股？
→ Why is the broad index insufficient for understanding capital flow?

Deep-Scan Overview
→ Does the quantitative result show that market leadership still exists?

最近7日 Top Gainers
→ Is short-term capital defensive, rotating, or pursuing risk?

Momentum Leaders Analysis
→ Which companies and business models are receiving medium-term capital?

Sector Analysis
→ Has individual strength formed an industry group?

Relative Volume / Market Activity
→ Is the new leadership structure confirmed by volume and market participation?

Risk
→ What could disprove the interpretation?

Deep-Scan Conclusion
→ What answers the opening market question, and what is the next confirmation signal?
```

If the section order can be exchanged without changing the reasoning, or if removing a major section leaves the reasoning intact, the narrative chain has failed.

---

## 2. Executive Summary

The Executive Summary should state the most important market observation directly.

It should not begin with methodology.

It should answer:

- what changed;
- where capital is moving;
- which themes dominate;
- what the reader should watch.

---

## 3. Market Context

Market Context must explain the market environment before introducing the APL framework.

Market Context is the Blog's detailed market-analysis section. It must not be compressed into a single-paragraph summary merely because the input is long.

It must state the issue's largest structural market change and establish the core market proposition that the following sections test.

It should answer:

- current market condition;
- capital flow direction;
- sector rotation;
- risk background;
- how the context relates to APL Momentum Leaders 領導股.

When the approved `market-context.md` contains multiple subheadings and paragraphs, the Blog Markdown and companion HTML must preserve:

- the original subheading order;
- the semantic meaning of each subheading;
- all major market arguments and their causal relationships.

Editorial wording may be lightly reorganized for clarity, but it must not remove a major market-background argument. Executive Summary is a separate short-form observation and must not replace Market Context.

Trigger B data, ranking results, sector counts and 最近7日 Top Gainers results must not be presented as if they were source Market Context. Those inputs belong in their own Blog sections and may only be related back to the market background through editorial analysis.

Blog Markdown and Blog HTML must remain content-equivalent for Market Context: they must preserve the same subheading order and major arguments. WhatsApp is an independent social summary and is not required to retain each detailed Market Context subsection.

`Market Context must not become a news dump` means do not pile up unconnected headlines or repeat individual news items without analysis. It does not permit removal of an already organized, market-logical detailed context.

### Market Context hierarchy

The Blog's main `Market Context` section remains Markdown H2 and HTML `<h3>`. Within that section only:

- Market Context subsections use Markdown H3;
- the corresponding HTML subsections use `<h4>`;
- each prose block remains its own paragraph.

No other Blog section may use arbitrary `<h4>` headings.

Daily news should be interpreted through the lens of capital flow and leadership structure.

---

## 4. 為什麼要看 APL Momentum Leaders 領導股？

This section explains the framework for readers who are new to APL.

It must continue directly from Market Context: explain why a broad market index alone cannot reveal the capital shift identified above.

Required message:

APL Momentum Leaders 領導股 is not a stock recommendation list.

It is a quantitative research framework for observing:

- market leadership structure;
- capital concentration;
- sector rotation;
- emerging themes.

The purpose is not to predict the next rising stock.

The purpose is to understand where market leadership is forming.

---

## 5. Deep-Scan Overview

This section summarizes the current Deep-Scan result.

It must not be a list of numbers. Explain how the quantitative evidence supports or challenges the core market proposition, then lead into whether short-term capital selection agrees with it.

It may include:

- scan universe;
- qualified stocks;
- Momentum Leaders count;
- Leader Lock count;
- top sector;
- market theme;
- key change versus prior issue.

Internal data source names must not appear in client-facing text.

---

## 6. 最近7日 Top Gainers

Use 最近7日 Top Gainers to explain short-term market temperature.

It must contrast short-term price leadership with the medium-term Momentum Leaders structure, then lead into where medium-term capital is actually moving. Do not describe it as an independent market story.

`最近7日 Top Gainers` is the fixed canonical section title across the Blog manuscript and TopGainers Table Card. It must be emitted exactly as:

```html
<h3>最近7日 Top Gainers</h3>
```

Do not append a theme, commentary or separator such as `｜...` to this heading. Put issue-specific interpretation in the following `<p>` paragraph instead.

It should help compare:

```text
short-term price strength
vs
medium-term leadership structure
```

Required source note:

```text
資料來源為 TradingView，排名、價格及升幅會隨市場變動。
```

Top Gainers must not be treated as stock recommendations.

---

## 7. Momentum Leaders Analysis

This section explains what the APL Momentum Leaders 領導股 structure reveals.

It must answer which companies, business models or new directions are receiving medium-term capital, then lead into whether their strength has formed an industry group.

It should focus on:

- leadership quality;
- sector concentration;
- business themes;
- capital flow implication;
- what the market may be repricing.

Do not simply list stocks one by one.

---

## 8. Sector Analysis

Sector Analysis should explain why certain sectors dominate the current scan.

It must move from individual-stock strength to an industry-group judgment, then lead into whether volume and participation confirm that group.

It should connect:

```text
sector distribution
→ business structure
→ capital flow
→ market implication
```

If structured data needs a visual treatment, generate a separate Blog Table Card artifact. Do not embed or reference that artifact inside the Blog Markdown file.

---

## 9. Relative Volume / Market Activity

Relative Volume should be interpreted as market activity, not as a standalone buy signal.

It must be evidence that confirms or questions the new leadership structure, then lead into its vulnerabilities and the Risk section.

Explain whether capital participation is broad, concentrated, or selective.

---

## 10. Risk

Risk section is mandatory.

It must directly test conditions that could disprove the core proposition; unrelated generic risks are not sufficient. Its closing should lead to the final market judgment.

It should discuss:

- macro risk;
- sector risk;
- valuation risk;
- liquidity risk;
- positioning risk;
- theme overcrowding risk.

Do not provide investment advice.

Do not predict price targets.

Do not imply certainty.

---

## 11. Deep-Scan Conclusion

The conclusion should summarize the market state and identify what deserves continued observation.

It must answer the Market Context question that opened the article, integrate only prior evidence and identify the next confirmation signal. Do not introduce a new argument.

It should not repeat the whole article.

It should end with a research-style market observation.

---

## 12. Client-facing Naming

Always use:

- `APL Momentum Leaders 領導股`
- `APL Deep-Scan`
- `最近7日 Top Gainers`

The capitalization, spacing and wording of `最近7日 Top Gainers` are fixed. Blog headings, Table Card contracts and renderer output must not substitute or extend this title.

Do not use these internal terms in client-facing Blog text:

- `APL Breakout Screener`
- `Cumulative Screener`
- internal ranking terminology;
- internal script names;
- internal production mode names.

---

## 13. Blog Manuscript and Visual Artifact Separation

The formal article manuscript filename is:

```text
APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.md
```

This file is the text-only editorial manuscript. It must contain only:

- article title;
- section headings;
- article paragraphs;
- CTA;
- disclaimer;
- publishing metadata.

It must not embed or reference any image, including:

- Hero Cover;
- Dashboard;
- Table Cards;
- SEO image;
- Social Card;
- any other PNG, SVG, JPG, JPEG, WEBP, GIF or visual asset.

Prohibited image-reference forms include, but are not limited to:

```text
![alt](path-or-url)
<img ...>
<picture>...</picture>
<source ...>
background-image: ...
direct image paths or URLs presented as article-body media references
```

Cover, Dashboard, Table Cards, SEO image and other required visuals must continue to be generated as independent artifacts in the same-date Production Package. Each visual remains subject to its own validation, no-overwrite guard, artifact tracking, byte size, SHA-256 trace and publication requirements. Their presence in the package does not authorize a reference inside the Blog `.md` manuscript.

Publishing systems may associate or upload those independent artifacts outside the manuscript, but that platform action must not be serialized back into `APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.md` or its companion HTML source.

### Daily Table Card completeness

The standard Trigger C Production Package must publish the successful required entries in its Table Card publication manifest:

- `ExecutiveSummary` — Key Signals;
- `TopLeaders` — representative Top Leaders;
- `TopGainers` — short-term market temperature;
- `SectorStructure` — sector／leadership structure.

`MarketObservation` and `Comparison` are optional and must not be generated without an article-specific reason. No Table Card, whether required or optional, may be referenced inside the Blog manuscript. A publishing operation outside the manuscript may use only cards recorded as `PASS` in the publication manifest.

---

## 14. HTML Source Contract

The publish-ready HTML source must be delivered as a separate same-date file:

```text
APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html
```

The `.md` manuscript and `.html` source are two independent editorial artifacts. Do not place HTML source inside the `.md` file.

Required element mapping:

```text
Article title              → <h1>...</h1>
Every section subheading   → <h3>...</h3>
Every body paragraph       → <p>...</p>
CTA heading                → <h3>...</h3>
CTA copy                   → <p>...</p>
Disclaimer heading         → <h3>...</h3>
Disclaimer copy            → <p>...</p>
```

Rules:

- every main／section heading must use lowercase HTML `<h3>` tags;
- `<h4>` is allowed only for Market Context subsections that correspond to detailed Markdown H3 subsections; all other Blog sections must not use `<h4>`;
- every prose block must be enclosed in its own lowercase HTML `<p>` tags;
- do not use Markdown `##`／`###` headings inside the HTML source;
- do not leave bare prose outside `<p>`;
- do not use `<h2>` or heading levels deeper than `<h4>`; do not use `<h4>` outside Market Context subsections;
- do not add `<img>`, `<picture>`, `<source>` or CSS image references;
- do not append publishing metadata to the HTML source;
- the HTML source must end with the final article／disclaimer paragraph, not URL, Page title or Page description fields.

The following lines are specifically prohibited at the bottom of the HTML source:

```html
<p>詳細文章：https://www.goinvestingnow.com/blog/apl-momentum-leaders-YYYY-MM-DD</p>
<p>Page title：...</p>
<p>Page description：...</p>
```

These publishing metadata values may remain in the separate `.md` manuscript or another publishing record, but they are not part of publishable article HTML.

---

## 15. URL and Publishing

Formal Blog URL format:

```text
https://www.goinvestingnow.com/blog/apl-momentum-leaders-YYYY-MM-DD
```

Page title should match the article title.

Page description should summarize APL Momentum Leaders 領導股, market leadership, and current theme.

---

## 16. Prohibited Blog Patterns

### Published machine artifact immutability

After the production runner publishes and traces machine-generated artifacts, the editorial stage is read-only with respect to those artifacts.

```text
Publish complete
→ machine artifacts become immutable
→ editorial stage reads only
→ editorial outputs use separate files
```

Editorial work must never reopen and save, normalize encoding, normalize line endings, format, append to, or replace a machine artifact. This includes ranking CSV, Top 30 TXT／Markdown, Overview Markdown, Watchlist, SMA200 audits, metadata, runtime contracts, renderer outputs and renderer logs.

Formal Blog, company business analysis, WhatsApp copy and publishing notes must be written to independent filenames. Any attempted later write to a published machine artifact must fail.

Do not:

- write the article as a raw report summary;
- list every stock one by one;
- paste internal CSV table logic into the article;
- treat Top Gainers as recommendations;
- use internal workflow names;
- make investment recommendations;
- predict stock prices;
- overload the article with data before explaining meaning.
- embed or reference any production image artifact inside the Blog Markdown manuscript;
- store the publish-ready HTML source inside the `.md` manuscript;
- append URL, Page title or Page description metadata paragraphs to the independent HTML source.
