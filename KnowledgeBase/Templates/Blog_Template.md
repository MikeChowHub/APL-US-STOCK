# APL Momentum Leaders Blog Template
> **Effective-date editorial boundary:** For ScanDate 2026-08-28 onward, omit `Call to Action｜延伸閱讀` and `Disclaimer｜免責聲明` from both Markdown and HTML. `Deep-Scan Conclusion｜深度掃描結論` is the final article section, followed only by the Markdown-only `SEO and Sharing` metadata block. From 2026-08-30 onward, `Investment Implication｜投資啟示` is mandatory immediately after Sector Analysis and before Risk. CTA／Disclaimer examples below apply only to 2026-08-10 through 2026-08-27 legacy-compatible packages.

This template provides the production skeleton for formal APL Momentum Leaders 領導股 Blog articles.

It is used during Trigger C only:

```text
Trigger C Inputs
+
Top Gainers — Past 7 Days
+
Market Context
↓
Formal Blog Production
```

This template is private editorial guidance, never a publishable artifact. Every bracketed instruction and example sentence must be replaced with issue-specific analysis before Managed Input Preflight. Copying the skeleton, emitting only one section, or using a short summary as the Blog must fail editorial completion.

For newly created packages from 2026-08-03 onward, use this exact full title structure in Markdown, HTML and the Page title metadata:

```text
APL Deep-Scan｜美股深海雷達: [當期核心市場結論] | YYYY-MM-DD
```

The market conclusion is mandatory. Use an ASCII colon and the exact separator ` | ` before the ISO date. A prefix-only title or a prefix followed only by a date is invalid; `#`, `<h1>` and `Page title：` must use the same full string.

For newly created packages from 2026-08-05 onward, major Blog headings use English first followed by a short Chinese gloss with `｜`. Packages before that date retain English-only headings and are not rewritten. This presentation rule applies to Blog Markdown and Blog HTML only; Table Card semantic titles remain governed by their own contracts.

Trigger C preparation order is fixed:

```text
verified Trigger B metadata and ranking
+ approved detailed market-context.md
+ current Top Gainers CSV
→ complete Markdown draft
→ content-equivalent HTML draft
→ WhatsApp and Company Business Analysis
→ Managed Input Editorial Completion Gate
```

Do not use this template for Trigger A or Trigger B alone.

---

## 1. Narrative chain

Before drafting, define one issue-specific core market proposition. It is editorial guidance only and must not appear as a labelled field in the formal Blog.

```text
Executive Summary｜執行摘要
↓
Market Context｜市場背景
→ What is the largest structural market change?

Why APL Momentum Leaders Matter｜為什麼要看領導股？
→ Why is the broad index insufficient for understanding capital flow?

Deep-Scan Overview｜深度掃描概覽
→ Does quantitative evidence show leadership still exists?

Top Gainers — Past 7 Days｜最近七日升幅榜
→ Is short-term capital defensive, rotating, or pursuing risk?

Momentum Leaders Analysis｜動能領導股分析
→ Which companies and business models are receiving medium-term capital?

Sector Analysis｜板塊結構分析
→ Has individual strength formed an industry group?

Investment Implication｜投資啟示
→ How should investors interpret this environment, and how does the evidence connect to APL Momentum Leaders?

Risk｜風險
→ What could disprove the interpretation, how would the risk transmit, and which observable signal would confirm failure?

Deep-Scan Conclusion｜深度掃描結論
→ What answers the opening question, what remains unresolved, and what is the next confirmation or invalidation signal?

Call to Action｜延伸閱讀
→ What should the reader continue tracking through APL Deep-Scan?

Disclaimer｜免責聲明
→ State clearly that the article is research and not investment advice.
```

Use the following private editorial guidance for every major section; do not display these labels in the formal Blog:

- 本期核心命題；
- 上一節已確認什麼；
- 本節需要回答什麼；
- 本節使用哪些證據；
- 本節得到什麼結論；
- 下一節需要驗證什麼。

For ScanDate 2026-08-30 onward, draft the opening as an investment-weekly lead:

- Executive Summary paragraph 1: what changed and the issue conclusion;
- Executive Summary paragraph 2: why it matters and where capital is moving;
- Executive Summary paragraph 3: what observable signal should be watched next;
- Market Context paragraph 1: the managed event evidence and causal change;
- Market Context paragraph 2: transmission into valuation, risk appetite and capital allocation;
- Market Context paragraph 3: the next confirmation／invalidation point and the transition to why APL leadership evidence is needed.

Do not display these paragraph labels in the final article. The required layers are semantic, so natural paragraph transitions are preferred over formulaic labels.

For ScanDate 2026-08-30 onward, draft `Investment Implication｜投資啟示` as a minimum five-paragraph bridge between sector evidence and risk:

1. interpret what the present regime means for investor selection standards;
2. identify the primary economically supported capital-expenditure／demand direction;
3. test whether a secondary beneficiary curve or broader sector expansion is forming;
4. connect the evidence explicitly to `APL Momentum Leaders`, cross-sector leadership and market breadth;
5. balance growth against valuation, cash flow, balance-sheet and macro constraints, then state the next confirmation／invalidation signal.

Use at least 650 substantive characters. Do not repeat Market Context, paste a stock list, or give direct buy／sell, target-price, stop-loss or personalized allocation instructions. The closing must lead naturally to `Risk｜風險`.
For Market Context, also answer privately before drafting:

- 哪些來源事實真正支持核心命題？
- 哪些新聞屬次要資料，可以刪除？
- 是否有兩項以上證據其實支持同一論點，可以合併？
- 是否重複解釋相同的估值、利率或資本回報概念？
- Market Context 是否能在最少必要篇幅內完成推理？

### Editorial contamination preflight

Before submitting the managed package, compare the normalized paragraphs in every major section. Do not copy the core thesis, the full Market Context source list or one long paragraph into multiple sections. Each section must contain a new section-specific inference and a transition to the next question. If a repeated block appears in three or more sections, rewrite the sections before preflight; character count and numeric-source coverage are not evidence of editorial completion.

Each section completes one reasoning task, begins with an issue-specific transition from the preceding conclusion, and ends by naturally introducing the next question. Sections must not be independently exchangeable.

---

## 2. Required References

Before writing, apply:

- `KnowledgeBase/Rules/APL_US_Stock_Blog_Rules.md`
- `KnowledgeBase/Rules/APL_US_Stock_Visual_Rules.md`
- `KnowledgeBase/Decision/APL_US_Stock_Visual_Decision_Tree.md`
- `KnowledgeBase/Templates/Cover_Image_Prompt_Template.md`
- `KnowledgeBase/Templates/Table_Card_Template.md`

Dashboard must not be used as Blog Cover.

Social Card must not replace Blog information cards.

All visual outputs are independent Production Package artifacts. None may be embedded or referenced inside the formal Blog manuscript.

---

## 3. Independent Output Files

Trigger C editorial production creates two separate text artifacts:

```text
APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.md
APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html.txt
```

The `.md` file is the editorial manuscript and must end with the Markdown-only `## SEO and Sharing` metadata block. The `.html` file is the publish-ready article source and contains article content only. Neither file may embed or reference images. A raw-code `.txt` presentation for operator viewing requires an explicit Production Artifact Contract migration; it must not silently rename or replace the required `.html` artifact.

The same editorial preparation also creates two independent companion text artifacts:

- `WhatsApp_<ScanDate>.md`: a concise distribution message whose first screen states the largest market change; it selects only the evidence needed for mobile reading and does not reproduce the complete Blog. From 2026-08-05, use this narrative order: title／article URL, market event, APL Deep-Scan viewpoint, investor watchpoints／risk, reading CTA and disclaimer. Short paragraphs and `•` bullets are encouraged; literal block labels are optional. The article URL must match the ScanDate exactly.

Recommended WhatsApp shape:

```markdown
**APL Deep-Scan 美股深海雷達**
**[Issue-specific conclusion] | YYYY-MM-DD**
https://www.goinvestingnow.com/blog/apl-momentum-leaders-YYYY-MM-DD

[Market event and why the market standard changed.]

📊 **APL Deep-Scan 觀察近期美股領導結構**，[APL interpretation and sectors/business models.]

• [Investor watchpoint 1]
• [Investor watchpoint 2]
• [Risk or falsification condition]

🐧 APL Deep-Scan [reading CTA].

研究摘要，不構成投資建議。
```
- `APL_Momentum_Leaders_Top_30_Company_Business_Analysis_<ScanDate>.md`: a company and business-model reference for the current Top 30; it does not repeat the Blog's market argument.

## 4. Market Context detailed structure

For ScanDate 2026-08-30 onward, Executive Summary is a three-paragraph investment-weekly opening and Market Context is a three-paragraph causal expansion. Executive Summary explains the conclusion, importance, capital direction and next watchpoint; Market Context provides the managed evidence, transmission mechanism and bridge into APL analysis. Earlier packages retain their historical concise format.

Use one or more optional subsections when they improve the causal structure:

```markdown
## Market Context

### [市場背景小標題一]

[只保留最能支持核心命題的事實，解釋其市場含義。]

### [可選：第二個分析小標題]

[合併相關證據，避免重複前一段的結論。]
```

The managed source is authoritative for facts, dates, numbers, company names, event topics and original meaning, not for final structure or source-item coverage. Omit weak evidence, merge related facts and reorder them where needed to form one causal argument. Do not invent evidence or mix Trigger B rankings, sector counts or Top Gainers results into source Market Context. Blog Markdown and HTML must remain equivalent for the final edited content. End by showing why the broad index alone cannot answer the capital-flow question.

## 5. Publish-ready HTML Skeleton

```html
<h1>APL Deep-Scan｜美股深海雷達: [當期核心市場結論] | YYYY-MM-DD</h1>

<h3>Executive Summary｜執行摘要</h3>
<p>[One concise market observation.]</p>

<h3>Market Context｜市場背景</h3>

<h4>[市場背景小標題一]</h4>
<p>[One or more paragraphs interpreting this market background through capital flow and leadership structure.]</p>

<h4>[市場背景小標題二]</h4>
<p>[One or more paragraphs preserving the next major market argument.]</p>

<h3>Why APL Momentum Leaders Matter｜為什麼要看領導股？</h3>
<p>[Transition from Market Context: explain why the broad index cannot reveal the capital shift, then explain the framework. End by asking whether the quantitative evidence still shows leadership. Not a recommendation list.]</p>

<h3>Deep-Scan Overview｜深度掃描概覽</h3>
<p>[Transition from framework to evidence: explain what the quantitative results support or challenge in the core proposition, not only the counts. End by asking whether short-term capital selection is consistent.]</p>

<h3>Top Gainers — Past 7 Days｜最近七日升幅榜</h3>
<p>[Transition from overview: contrast short-term price leadership with medium-term leadership, then ask where medium-term capital is actually moving.]</p>
<p>Scope: SPX／NDX／DJI constituents. The ranking, prices and changes are point-in-time market data and may change with the market.</p>

<h3>Momentum Leaders Analysis｜動能領導股分析</h3>
<p>[Transition from short-term comparison: explain which companies and business models receive medium-term capital, then ask whether they form an industry group.]</p>

<h3>Sector Analysis｜板塊結構分析</h3>
<p>[Transition from individual leaders: determine whether the strength forms an industry group, then ask what that structure means for investor interpretation and capital allocation.]</p>

<h3>Investment Implication｜投資啟示</h3>
<p>[Investor interpretation: explain how the current regime changes selection standards without repeating Market Context.]</p>
<p>[Primary economic direction: identify where demand or capital expenditure has the clearest path to revenue, earnings or cash flow.]</p>
<p>[Secondary curve and breadth: test whether leadership is expanding beyond a narrow core theme.]</p>
<p>[APL link: explain what current APL Momentum Leaders cross-sector evidence confirms or challenges.]</p>
<p>[Research posture and next signal: balance macro／valuation constraints, then lead into the falsification tests in Risk. No direct trading instruction.]</p>

<h3>Risk｜風險</h3>
<p>[Issue-specific falsification conditions: identify what could disprove the core proposition.]</p>
<p>[Transmission mechanism: explain how those conditions would affect earnings, valuation, liquidity or sector leadership.]</p>
<p>[Observable failure signals: state what evidence would show the interpretation is weakening, then lead to the final judgment without investment advice.]</p>

<h3>Deep-Scan Conclusion｜深度掃描結論</h3>
<p>[Return to and answer the Market Context opening question directly.]</p>
<p>[Integrate only prior leadership and sector evidence; explain what is confirmed and what remains selective or unresolved.]</p>
<p>[State the next confirmation or invalidation signal and end with a research-style market observation. Do not add a new argument.]</p>

<h3>Call to Action｜延伸閱讀</h3>
<p>[Text-only CTA.]</p>

<h3>Disclaimer｜免責聲明</h3>
<p>[Research disclaimer; no investment advice.]</p>

```

The fenced block above demonstrates the required source structure only. Write that source to `APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html.txt` without a surrounding Markdown code fence. Do not write it into the `.md` manuscript and do not create a duplicate `.html` file.

The HTML file must not end with `詳細文章`, `Page title` or `Page description` paragraphs. Keep those fields outside the HTML source.

From 2026-08-05, the Blog heading is `<h3>Top Gainers — Past 7 Days｜最近七日升幅榜</h3>`. The Table Card title remains exact English `Top Gainers — Past 7 Days` and must not receive the Chinese suffix. Put issue-specific interpretation in the following `<p>`.

---

## 6. Independent Visual Package

Generate and publish visual assets separately from the Blog manuscript:

- Blog Cover: independent Hero artifact;
- Table Cards: independently distributed companion research cards, each with one structured-observation role;
- Dashboard: complete systematic research UI;
- Social Card: one mobile-first visual message with minimal supporting data;
- SEO Image: independent search／share artifact.

Visual selection must follow the Visual Decision Tree.

Each visual must still be validated and recorded with byte size and SHA-256 in the Production Package. Do not place Markdown image syntax, HTML image elements, image filenames, image paths or image URLs in the Blog `.md` file.

Cross-platform consistency requires the same core market proposition and accurate repeated facts, but not identical content. Do not copy the complete scan funnel into ExecutiveSummary, Social Card and WhatsApp merely because Dashboard displays it. Do not copy full Table Card rows into the Blog when prose analysis already performs a different function.

---

## 7. Variable Content Blocks

Replace the following per issue:

- date;
- market context;
- market theme;
- Top Gainers interpretation;
- Momentum Leaders structure;
- sector rotation;
- investment implication and APL Momentum Leaders interpretation;
- risk background;
- conclusion;
- SEO metadata.

Do not insert internal production terminology into client-facing Blog text. In particular, translate `universe`, `qualified`, `leaderLock`, `removedBelowSma200Count`, `finalWatchlistCount`, `averageMomentum`, `averageBuyability` and `Trigger B` into natural reader-facing Chinese sentences. The underlying values remain source-bound, but the property names must never be printed.

For managed packages dated 2026-08-10 or later:

- Market Context contains at least two causal analytical paragraphs rather than one headline dump;
- Top Gainers uses selected examples with balanced punctuation and ends with the canonical scope／point-in-time note as a separate paragraph;
- Momentum Leaders and Sector Analysis each contain at least two prose paragraphs and no semicolon-delimited pseudo-table;
- the exact conclusion heading is `Deep-Scan Conclusion｜深度掃描結論`;
- Markdown and HTML both include `Call to Action｜延伸閱讀` and `Disclaimer｜免責聲明`;
- `SEO and Sharing` follows the disclaimer and remains the final Markdown-only section.

For managed packages dated 2026-08-28 or later:

- Risk contains at least three natural prose paragraphs covering falsification conditions, transmission mechanisms and observable failure signals;
- Deep-Scan Conclusion contains at least three natural prose paragraphs answering the opening question, integrating prior evidence and identifying the next confirmation or invalidation signal;
- neither section may copy a fixed prior-issue passage, repeat the same conclusion to increase length or introduce claims unsupported by the current managed evidence.

For managed packages dated 2026-08-30 or later:

- `Investment Implication｜投資啟示` appears after Sector Analysis and before Risk in both Markdown and HTML;
- it contains at least five natural prose paragraphs and 650 substantive characters;
- it answers how investors should interpret the environment, connects explicitly to `APL Momentum Leaders`, and covers capital flow, economic translation, breadth and the next risk signal;
- it does not copy a Market Context paragraph or contain direct trading instructions.
---

## 8. Prohibited Template Usage

Do not:

- use this template to produce a Blog from Screener alone;
- paste full CSV tables into the Blog;
- use Dashboard as Blog Cover;
- use Social Card as article analysis;
- embed or reference Hero Cover, Dashboard, Table Cards, SEO image, Social Card or any other image inside the Blog manuscript;
- put HTML source inside the `.md` manuscript instead of the independent `.html.txt` file;
- use `<h4>` outside Market Context subsections; main HTML sections remain `<h3>`;
- leave HTML article prose outside `<p>`;
- append URL, Page title or Page description metadata paragraphs to the HTML source;
- treat APL Momentum Leaders 領導股 as investment advice;
- include price targets or recommendations.

---

## 9. Markdown-only SEO and Sharing block

For ScanDate 2026-08-28 onward, append this final block directly after `## Deep-Scan Conclusion｜深度掃描結論`. For 2026-08-10 through 2026-08-27 legacy-compatible packages, append it after CTA／Disclaimer. Replace every field with issue-specific values.

```markdown
## SEO and Sharing

詳細文章：https://www.goinvestingnow.com/blog/apl-momentum-leaders-YYYY-MM-DD

Page title：[Must exactly match the article title]

Page description：[One issue-specific summary of APL Momentum Leaders, market leadership and the current theme.]

Sharing summary：[One concise message for distribution.]
```

Do not copy this block to the independent HTML article source.
