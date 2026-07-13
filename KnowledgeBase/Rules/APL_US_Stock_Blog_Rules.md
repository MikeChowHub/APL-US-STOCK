# APL US Stock Blog Rules

This document defines stable writing rules for formal APL Momentum Leaders 領導股 Blog production.

Blog Rules answer:

- how the article should be structured;
- how market context should be integrated;
- what client-facing terminology must be used;
- how article text and visual artifacts must remain separated;
- what content is prohibited.

Visual styling belongs to Visual Rules and Templates.

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

It should answer:

- current market condition;
- capital flow direction;
- sector rotation;
- risk background;
- how the context relates to APL Momentum Leaders 領導股.

Market Context must not become a news dump.

Daily news should be interpreted through the lens of capital flow and leadership structure.

---

## 4. 為什麼要看 APL Momentum Leaders 領導股？

This section explains the framework for readers who are new to APL.

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

Explain whether capital participation is broad, concentrated, or selective.

---

## 10. Risk

Risk section is mandatory.

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

- every small／section heading must use lowercase HTML `<h3>` tags;
- every prose block must be enclosed in its own lowercase HTML `<p>` tags;
- do not use Markdown `##`／`###` headings for article content;
- do not leave bare prose outside `<p>`;
- do not use `<h2>`, `<h4>` or deeper heading levels for the standard article structure;
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
