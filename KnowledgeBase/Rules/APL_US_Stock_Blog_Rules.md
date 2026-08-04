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

Editorial completion requires both Blog formats to contain the nine mandatory analysis sections with substantive issue-specific content, detailed Market Context derived from the approved market-topic input, current Trigger B numbers, current Top Gainers evidence, a continuous reasoning chain, a responsive conclusion, a substantive WhatsApp summary and non-empty Company Business Analysis. Relative Volume / Market Activity is no longer a mandatory Blog section; its metrics may remain in structured cards, Dashboard or internal audit evidence. Template placeholders, test sentences, summary shells and headings without analysis are not publishing artifacts.

`tools/validate_managed_inputs.ps1` is the fail-closed executable gate. It creates `APL_Editorial_Completion_Audit_<ScanDate>.json` v1.1 only after content, source evidence, Markdown／HTML equivalence, Table Card source integrity and distinct native-composition integrity pass. `tools/run_daily_production.ps1` must invoke this gate before scoring and must then prove that its newly generated Trigger B ranking is byte-identical to the ranking used during editorial preparation. Mechanical Production completion without this PASS evidence is not publishable completion.

Formal completion is:

```text
Mechanical Completion PASS
+ Editorial Completion PASS
→ DailyProductionComplete=true
→ DailyProductionPublishable=true
```

---

## Cross-platform editorial responsibility

The Production Package must share one issue-specific core market proposition without turning every artifact into a duplicate of the Blog or Dashboard.

- The Blog owns the complete market reasoning chain.
- WhatsApp owns the concise text distribution message: the first screen states the largest market change, followed by only the evidence and call to action needed for that channel. It must include the issue-matched `詳細文章：https://www.goinvestingnow.com/blog/apl-momentum-leaders-YYYY-MM-DD` link after its concise analysis and before the final disclaimer.
- The `ExecutiveSummary` Table Card owns three to five client-priority observations and their implications.
- Dashboard owns the complete systematic scan context, including the scan funnel, ranked structure, Buyability and sector distribution.
- Social has two independent roles: `Social Card` owns one mobile-first visual message supported by minimal current data; `Social Radar` owns a complete Top 30 radar view with the scan funnel, Buyability and sector distribution. Neither may re-score, re-rank or determine eligibility.
- Cover and SEO own the visual market story; they share one scene concept but use role-specific native compositions.
- `TopLeaders`, `TopGainers` and `SectorStructure` own company-level medium-term evidence, short-term price evidence and group-level structure respectively.
- Company Business Analysis owns the company and business-model reference for the current Top 30; it is not a second market commentary.

For new managed packages from 2026-08-05 onward, WhatsApp must follow one natural mobile-reading chain: issue-specific title and article URL → market event and core change → APL Deep-Scan／APL Momentum Leaders interpretation → investor watchpoints and falsification risk → reading CTA and disclaimer. Visible labels such as `市場事件：` or `APL 觀點：` are optional; the order is semantic and may be expressed as short paragraphs and bullet points. The message must contain the exact-date article URL, an explicit APL viewpoint, observable next signals, and a research disclaimer. The 2026-08-04 Archive message remains immutable legacy output.

Cross-platform consistency means that any repeated date, number, company identity, ranking fact or directional judgment remains accurate and non-contradictory. It does not mean every artifact must display the same facts, wording, rows or conclusion.

### Required Social publishing pair

Every completed Trigger C package must contain both independent Social artifacts under `production-package/`:

- `APL_DeepScan_Social_Card_<ScanDate>_1080x1350.png` — the concise, mobile-first message;
- `APL_DeepScan_Social_Radar_Top30_<ScanDate>_1080x1350.png` — the complete Top 30 Radar, including scan funnel, Buyability and sector distribution.

They must be rendered independently from the same validated Social runtime contract and each must pass fresh-PNG, 1080x1350, SHA/size, repository-font and zero-warning validation. A Social Card cannot substitute for the Radar; neither artifact may be created by cropping, resizing, re-encoding, or otherwise deriving it from the other.

Do not use source-integrity requirements to force low-priority metrics into client-facing content. Structured validators, manifests and audit evidence establish provenance; editorial preparation selects what each platform needs.

---

## 1. Article Flow

### Formal article-title prefix

For every newly created managed editorial package from **2026-08-03** onward, the formal article title and Page title must use this exact structure:

```text
APL Deep-Scan 美股深海雷達: [issue-specific market conclusion] | YYYY-MM-DD
```

The issue-specific market conclusion is mandatory; it is not a placeholder and must be written for the current market evidence. Use the ASCII colon, one space after the colon, and one space on each side of the date separator (` | `). Example: `APL Deep-Scan 美股深海雷達: 能源風險回歸，AI 回報受驗證 | 2026-08-04`.

The full string is the article title, the Markdown `#` value, the HTML `<h1>` value and the SEO／Sharing `Page title` value. They must be byte-equivalent after UTF-8 decoding. The title is not a subtitle, image-overlay line, or optional branding treatment; a prefix-only title or a prefix followed only by a date is invalid. This applies prospectively and does not alter already published outputs or Archive artifacts.

Formal Blog articles should follow this reading flow:

```text
Executive Summary｜執行摘要
↓
Market Context｜市場背景
↓
Why APL Momentum Leaders Matter｜為什麼要看領導股？
↓
Deep-Scan Overview｜深度掃描概覽
↓
Top Gainers — Past 7 Days｜最近七日升幅榜
↓
Momentum Leaders Analysis｜動能領導股分析
↓
Sector Analysis｜板塊結構分析
↓
Risk｜風險
↓
Deep-Scan Conclusion｜深度掃描結論
↓
SEO and Sharing
```

The Blog Markdown file is the formal article text manuscript. Visual artifacts are not part of this reading-flow source and must not be embedded or referenced inside it.

### Blog section heading language contract

For newly created managed Blog packages from **2026-08-05** onward, every major Blog section heading must place the English label first and a short, clear Chinese gloss second, separated by the full-width vertical bar `｜`:

```text
Executive Summary｜執行摘要
Market Context｜市場背景
Why APL Momentum Leaders Matter｜為什麼要看領導股？
Deep-Scan Overview｜深度掃描概覽
Top Gainers — Past 7 Days｜最近七日升幅榜
Momentum Leaders Analysis｜動能領導股分析
Sector Analysis｜板塊結構分析
Risk｜風險
Deep-Scan Conclusion｜深度掃描結論
```

The gloss is presentation text only; semantic roles, audit keys and renderer contracts remain unchanged. The `Top Gainers — Past 7 Days` Table Card title remains exact English with no suffix. Blog packages before 2026-08-05 retain the legacy English-only headings and are not rewritten.

### SEO and Sharing metadata

`## SEO and Sharing` is a required final Markdown-only section. It must follow `## Deep-Scan Conclusion` and include the current issue's `詳細文章：https://www.goinvestingnow.com/blog/apl-momentum-leaders-YYYY-MM-DD`, `Page title：` matching the article title, `Page description：` summarising APL Momentum Leaders and the issue theme, and one concise sharing summary. This metadata must never be copied into the independent publish-ready HTML article source.

### HTML source viewing rule

The independent `.html` artifact is publish-ready HTML. Opening it in a browser is expected to render the tags, so the browser view will not display the literal `<h1>`, `<h3>`, `<p>` or `<span>` characters.

When an operator needs to inspect or copy the raw HTML source, Production must provide a separate UTF-8 text artifact with a `.txt` extension (for example `APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.html.txt`). That file must contain the exact HTML source, including the literal angle brackets, without escaping, browser rendering, crop, or reformatting. The `.txt` source is a viewing／copying artifact and does not replace the publish-ready `.html` file unless the Production Artifact Contract is explicitly migrated and its validators／manifest／tests are updated together.

Never instruct an operator to use the browser-rendered `.html` file as a raw-source viewer, and never silently rename `.html` to `.txt` after publish.

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
Executive Summary｜執行摘要
↓
Market Context｜市場背景
→ What is the largest structural market change?

Why APL Momentum Leaders Matter｜為什麼要看領導股？
→ Why is the broad index insufficient for understanding capital flow?

Deep-Scan Overview｜深度掃描概覽
→ Does the quantitative result show that market leadership still exists?

Top Gainers — Past 7 Days｜最近七日升幅榜
→ Is short-term capital defensive, rotating, or pursuing risk?

Momentum Leaders Analysis｜動能領導股分析
→ Which companies and business models are receiving medium-term capital?

Sector Analysis｜板塊結構分析
→ Has individual strength formed an industry group?

Risk｜風險
→ What could disprove the interpretation?

Deep-Scan Conclusion｜深度掃描結論
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

Market Context is the Blog's market-reasoning section. It may be concise and may use one paragraph when that is the clearest complete argument, but it must not collapse into an unsupported summary shell.

It must state the issue's largest structural market change and establish the core market proposition that the following sections test.

Market Context does not reproduce every source item. It selects the managed facts that best support the issue's core proposition and turns them into the shortest complete, continuous market argument needed to:

1. state the structural market change;
2. explain how it affects capital cost, valuation or capital flow;
3. support the proposition with the most representative managed facts; and
4. lead naturally to why APL Momentum Leaders 領導股 must be examined.

Editorial completeness is determined by whether this reasoning is complete, not by source-item coverage, subsection count, paragraph count, source order or a fixed character target.

The approved Market Context input is authoritative for facts, dates, numbers, company names, event topics and their original meaning. It is not authoritative for final length, paragraph count, paragraph order, subsection count, inclusion of every news item or final wording.

The approved `market-context.md` must declare exactly one editorial-control line before its source evidence:

```text
本期核心市場命題是：[one substantive issue-specific proposition]
```

This line is managed source metadata used by preflight and audit evidence. It is not a mandatory sentence in the formal Blog and must not be copied mechanically. The formal Blog must express the same proposition through natural editorial prose; whether that expression is analytically faithful remains a human Final Audit decision.

The normalized value of this metadata line must equal Cover Brief `sceneConcept.coreMarketThesis`. Managed Input Preflight fails closed when they differ, preventing Cover, SEO and Social from using a different cross-platform proposition.

Editorial preparation may:

- omit secondary news that does not materially support the core proposition;
- merge related facts into one analytical point;
- reorder evidence to establish causality;
- rewrite subsection headings;
- use one or more subsections, or concise continuous prose where that is clearer;
- substantially shorten the source;
- combine evidence from different companies when it supports the same analytical point.

Editorial preparation must not:

- invent an unmanaged fact, date or number;
- change the meaning of managed evidence;
- present Trigger B ranking, sector counts or Top Gainers results as source Market Context;
- repeat the same conclusion merely to increase length;
- turn Market Context into a list of unrelated news items.

Executive Summary is a separate short-form observation and must not replace Market Context.

Trigger B data, ranking results, sector counts and Top Gainers — Past 7 Days results must not be presented as if they were source Market Context. Those inputs belong in their own Blog sections and may only be related back to the market background through editorial analysis.

Blog Markdown and Blog HTML must remain content-equivalent for the final edited Market Context. WhatsApp is an independent social summary and is not required to retain the same evidence or structure.

`Market Context must not become a news dump` means do not pile up unconnected headlines or repeat individual news items without analysis. Editorial preparation should omit or merge weaker items, while retaining enough managed evidence to make the selected causal argument complete.

### Editorial contamination guard

A managed input is not editorially complete merely because it contains the required headings, enough characters or source numbers. The following are hard FAIL conditions:

- copying the same Market Context paragraph, thesis sentence or raw news block into three or more major sections;
- appending the full approved Market Context to Executive Summary, Top Gainers, Momentum Leaders, Sector, Relative Volume, Risk or Conclusion without a new section-specific inference;
- using a mechanically repeated paragraph to satisfy minimum length, Chinese-character or source-coverage checks;
- putting ranking, Top Gainers or sector evidence into Market Context as if it were original market-context evidence;
- allowing a section to be removed or reordered without changing the reasoning chain.

Final Audit must compare normalized paragraph blocks across the nine mandatory sections, record any repeated long block, and fail closed when repeated material is not accompanied by a distinct section conclusion. A PASS requires each section to add new evidence, interpretation or a falsifiable next question. This guard applies to Markdown, HTML, WhatsApp, Company Business Analysis and Table Card semantic inputs; structured fields must remain concise and role-specific rather than carrying Blog prose.

### Market Context hierarchy

The Blog's main `Market Context` section remains Markdown H2 and HTML `<h3>`. Subsections are optional. When used:

- Market Context subsections use Markdown H3;
- the corresponding HTML subsections use `<h4>`;
- the final Markdown and HTML use the same subsection order and analytical content.

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

## 6. Top Gainers — Past 7 Days

Use Top Gainers — Past 7 Days to explain short-term market temperature among the approved SPX／NDX／DJI constituent universe.

It must contrast short-term price leadership with the medium-term Momentum Leaders structure, then lead into where medium-term capital is actually moving. Do not describe it as an independent market story.

`Top Gainers — Past 7 Days` remains the fixed canonical English title for the TopGainers Table Card. For Blog packages from 2026-08-05 onward, the Blog heading uses the bilingual presentation form `Top Gainers — Past 7 Days｜最近七日升幅榜`; legacy Blog packages before that date retain the English-only heading.

```html
<h3>Top Gainers — Past 7 Days｜最近七日升幅榜</h3>
```

Do not append any other theme, commentary or date to this heading. Put issue-specific interpretation in the following `<p>` paragraph instead.

It should help compare:

```text
short-term price strength
vs
medium-term leadership structure
```

Required source note:

```text
Scope: SPX／NDX／DJI constituents. The ranking, prices and changes are point-in-time market data and may change with the market.
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

## 9. Risk

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

## 10. Deep-Scan Conclusion

The conclusion should summarize the market state and identify what deserves continued observation.

It must answer the Market Context question that opened the article, integrate only prior evidence and identify the next confirmation signal. Do not introduce a new argument.

It should not repeat the whole article.

It should end with a research-style market observation.

---

## 11. Client-facing Naming

Always use:

- `APL Momentum Leaders 領導股`
- `APL Deep-Scan`
- Blog heading: `Top Gainers — Past 7 Days｜最近七日升幅榜` from 2026-08-05 onward;
- Table Card title: `Top Gainers — Past 7 Days` (exact English, immutable).

The capitalization, dash, spacing and wording of the English Table Card title are fixed. A platform name is not a client-facing source label for this section; the required disclosure is the SPX／NDX／DJI constituent scope.

Do not use these internal terms in client-facing Blog text:

- `APL Breakout Screener`
- `Cumulative Screener`
- internal ranking terminology;
- internal script names;
- internal production mode names.

---

## 12. Blog Manuscript and Visual Artifact Separation

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

Required Table Cards are source-bound publishing evidence, not free-form illustrations. `TopLeaders` must reproduce the selected current Trigger B ranking rows in rank order with matching symbols, company identities and Composite Scores; `TopGainers` must reproduce the selected current Top Gainers CSV rows in source order with matching symbols, company identities and percentage changes; and `SectorStructure` representative symbols must belong to the current Trigger B Top 30. Any displayed source fact that does not match the current managed evidence is a preflight failure and Production must not start.

`SectorStructure.direction` is a concise Chinese market-direction／capital-structure summary and must contain Chinese text. English-only direction values are invalid; symbols belong only in `representativeSymbols`. This rule applies to new managed packages from 2026-08-05 onward. Existing 2026-08-04 Archive artifacts remain immutable legacy output and are not silently rewritten.

`ExecutiveSummary` must contain three to five issue-specific priority observations with a short implication for each. Universe, qualified, leaders, Leader Lock or other scan metrics may appear only when they materially support one of those priority observations. They are not mandatory content because Deep-Scan Overview and Dashboard already own the complete scan context.

For new managed packages, every `ExecutiveSummary` `observation` must be reader-facing Chinese prose, not an English-only label or a raw machine metric dump. When figures are used, the sentence must connect the numbers to a market implication (for example, concentration, breadth or difficulty of entry). The paired `meaning` field must explain the implication in Chinese and define specialist terms such as `Leader Lock` and `Buyability` when they appear. A row that only lists numbers, leaves the implication implicit, or uses unexplained English terminology fails the semantic gate. This rule is effective from 2026-08-05; the 2026-08-04 archived card remains immutable legacy output.

The four required cards must not collapse into four presentations of the same data:

- `ExecutiveSummary` synthesizes priority conclusions;
- `TopLeaders` provides medium-term company-level evidence;
- `TopGainers` provides short-term price-leadership evidence;
- `SectorStructure` provides group-level structural evidence.

---

## 13. HTML Source Contract

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

## 14. URL and Publishing

Formal Blog URL format:

```text
https://www.goinvestingnow.com/blog/apl-momentum-leaders-YYYY-MM-DD
```

Page title should match the article title.

Page description should summarize APL Momentum Leaders 領導股, market leadership, and current theme.

---

## 15. Prohibited Blog Patterns

### Published artifact immutability

After the production runner publishes the complete same-date package, every published artifact present before Final Production Audit becomes read-only. Final Production Audit is then created separately and immediately made read-only.

```text
Publish complete
→ all published artifacts become immutable
→ Final Production Audit is created and locked
→ Archive copies the immutable package
```

No post-publish process may reopen and save, normalize encoding, normalize line endings, format, append to, or replace a published artifact. This includes Blog／HTML, WhatsApp, Company Business Analysis, Table Cards, ranking CSV, Top 30 TXT／Markdown, Overview Markdown, Watchlist, SMA200 audits, metadata, runtime contracts, renderer outputs and renderer logs.

All editorial and machine artifacts must be complete before atomic publish. Any attempted later write to a published artifact must fail.

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
