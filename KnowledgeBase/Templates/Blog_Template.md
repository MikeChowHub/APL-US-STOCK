# APL Momentum Leaders Blog Template

This template provides the production skeleton for formal APL Momentum Leaders 領導股 Blog articles.

It is used during Trigger C only:

```text
Trigger C Inputs
+
最近7日 Top Gainers
+
Market Context
↓
Formal Blog Production
```

This template is private editorial guidance, never a publishable artifact. Every bracketed instruction and example sentence must be replaced with issue-specific analysis before Managed Input Preflight. Copying the skeleton, emitting only one section, or using a short summary as the Blog must fail editorial completion.

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
Market Context
→ What is the largest structural market change?

為什麼要看 APL Momentum Leaders 領導股？
→ Why is the broad index insufficient for understanding capital flow?

Deep-Scan Overview
→ Does quantitative evidence show leadership still exists?

最近7日 Top Gainers
→ Is short-term capital defensive, rotating, or pursuing risk?

Momentum Leaders Analysis
→ Which companies and business models are receiving medium-term capital?

Sector Analysis
→ Has individual strength formed an industry group?

Relative Volume / Market Activity
→ Is the leadership structure confirmed by volume and market participation?

Risk
→ What could disprove the interpretation?

Deep-Scan Conclusion
→ What answers the opening question, and what is the next confirmation signal?
```

Use the following private editorial guidance for every major section; do not display these labels in the formal Blog:

- 本期核心命題；
- 上一節已確認什麼；
- 本節需要回答什麼；
- 本節使用哪些證據；
- 本節得到什麼結論；
- 下一節需要驗證什麼。

For Market Context, also answer privately before drafting:

- 哪些來源事實真正支持核心命題？
- 哪些新聞屬次要資料，可以刪除？
- 是否有兩項以上證據其實支持同一論點，可以合併？
- 是否重複解釋相同的估值、利率或資本回報概念？
- Market Context 是否能在最少必要篇幅內完成推理？

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
APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html
```

The `.md` file is the editorial manuscript and may retain text-only publishing metadata. The `.html` file is the publish-ready article source and contains article content only. Neither file may embed or reference images.

The same editorial preparation also creates two independent companion text artifacts:

- `WhatsApp_<ScanDate>.md`: a concise distribution message whose first screen states the largest market change; it selects only the evidence needed for mobile reading and does not reproduce the complete Blog.
- `APL_Momentum_Leaders_Top_30_Company_Business_Analysis_<ScanDate>.md`: a company and business-model reference for the current Top 30; it does not repeat the Blog's market argument.

## 4. Market Context detailed structure

Executive Summary remains one concise market observation. Market Context is the shortest complete market argument that supports the issue's core proposition; it has no fixed length, paragraph count or subsection count.

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
<h1>[Article Title]</h1>

<h3>Executive Summary</h3>
<p>[One concise market observation.]</p>

<h3>Market Context</h3>

<h4>[市場背景小標題一]</h4>
<p>[One or more paragraphs interpreting this market background through capital flow and leadership structure.]</p>

<h4>[市場背景小標題二]</h4>
<p>[One or more paragraphs preserving the next major market argument.]</p>

<h3>為什麼要看 APL Momentum Leaders 領導股？</h3>
<p>[Transition from Market Context: explain why the broad index cannot reveal the capital shift, then explain the framework. End by asking whether the quantitative evidence still shows leadership. Not a recommendation list.]</p>

<h3>Deep-Scan Overview</h3>
<p>[Transition from framework to evidence: explain what the quantitative results support or challenge in the core proposition, not only the counts. End by asking whether short-term capital selection is consistent.]</p>

<h3>最近7日 Top Gainers</h3>
<p>[Transition from overview: contrast short-term price leadership with medium-term leadership, then ask where medium-term capital is actually moving.]</p>
<p>資料來源為 TradingView，排名、價格及升幅會隨市場變動。</p>

<h3>Momentum Leaders Analysis</h3>
<p>[Transition from short-term comparison: explain which companies and business models receive medium-term capital, then ask whether they form an industry group.]</p>

<h3>Sector Analysis</h3>
<p>[Transition from individual leaders: determine whether the strength forms an industry group, then ask whether participation confirms it.]</p>

<h3>Relative Volume / Market Activity</h3>
<p>[Transition from group structure: use volume and participation to confirm or question the leadership thesis, then identify its vulnerabilities.]</p>

<h3>Risk</h3>
<p>[Transition from participation evidence: identify conditions that could disprove the core proposition, then lead to the final judgment without investment advice.]</p>

<h3>Deep-Scan Conclusion</h3>
<p>[Return to the Market Context opening question; integrate only prior evidence and state the next confirmation signal without adding a new argument.]</p>

<h3>Call to Action</h3>
<p>[Text-only CTA.]</p>

<h3>Disclaimer</h3>
<p>[Research disclaimer; no investment advice.]</p>

```

The fenced block above demonstrates the required source structure only. Write that source to `APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html` without a surrounding Markdown code fence. Do not write it into the `.md` manuscript.

The HTML file must not end with `詳細文章`, `Page title` or `Page description` paragraphs. Keep those fields outside the HTML source.

`<h3>最近7日 Top Gainers</h3>` is canonical and immutable. Do not append `｜...`, a market theme or any issue-specific subtitle to this heading; place that context in the next `<p>`.

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
- risk background;
- conclusion;
- SEO metadata.

Do not insert internal production terminology into client-facing Blog text.

---

## 8. Prohibited Template Usage

Do not:

- use this template to produce a Blog from Screener alone;
- paste full CSV tables into the Blog;
- use Dashboard as Blog Cover;
- use Social Card as article analysis;
- embed or reference Hero Cover, Dashboard, Table Cards, SEO image, Social Card or any other image inside the Blog manuscript;
- put HTML source inside the `.md` manuscript instead of the independent `.html` file;
- use `<h4>` outside Market Context subsections; main HTML sections remain `<h3>`;
- leave HTML article prose outside `<p>`;
- append URL, Page title or Page description metadata paragraphs to the HTML source;
- treat APL Momentum Leaders 領導股 as investment advice;
- include price targets or recommendations.
