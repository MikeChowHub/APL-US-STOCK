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

Do not use this template for Trigger A or Trigger B alone.

---

## 1. Required References

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

## 2. Independent Output Files

Trigger C editorial production creates two separate text artifacts:

```text
APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.md
APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html
```

The `.md` file is the editorial manuscript and may retain text-only publishing metadata. The `.html` file is the publish-ready article source and contains article content only. Neither file may embed or reference images.

## 3. Publish-ready HTML Skeleton

```html
<h1>[Article Title]</h1>

<h3>Executive Summary</h3>
<p>[One concise market observation.]</p>

<h3>Market Context</h3>
<p>[Interpret current market events through capital flow and leadership structure.]</p>

<h3>為什麼要看 APL Momentum Leaders 領導股？</h3>
<p>[Explain framework. Not a recommendation list.]</p>

<h3>Deep-Scan Overview</h3>
<p>[Summarize scan results and market theme.]</p>

<h3>最近7日 Top Gainers</h3>
<p>[Explain short-term market temperature.]</p>
<p>資料來源為 TradingView，排名、價格及升幅會隨市場變動。</p>

<h3>Momentum Leaders Analysis</h3>
<p>[Explain leadership structure.]</p>

<h3>Sector Analysis</h3>
<p>[Explain dominant sectors and capital rotation.]</p>

<h3>Relative Volume / Market Activity</h3>
<p>[Explain activity and participation.]</p>

<h3>Risk</h3>
<p>[Explain risks without investment advice.]</p>

<h3>Deep-Scan Conclusion</h3>
<p>[Research-style conclusion.]</p>

<h3>Call to Action</h3>
<p>[Text-only CTA.]</p>

<h3>Disclaimer</h3>
<p>[Research disclaimer; no investment advice.]</p>

```

The fenced block above demonstrates the required source structure only. Write that source to `APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html` without a surrounding Markdown code fence. Do not write it into the `.md` manuscript.

The HTML file must not end with `詳細文章`, `Page title` or `Page description` paragraphs. Keep those fields outside the HTML source.

`<h3>最近7日 Top Gainers</h3>` is canonical and immutable. Do not append `｜...`, a market theme or any issue-specific subtitle to this heading; place that context in the next `<p>`.

---

## 4. Independent Visual Package

Generate and publish visual assets separately from the Blog manuscript:

- Blog Cover: independent Hero artifact;
- Table Cards: independent structured-observation artifacts;
- Dashboard: independent research artifact;
- Social Card: independent publishing artifact;
- SEO Image: independent search／share artifact.

Visual selection must follow the Visual Decision Tree.

Each visual must still be validated and recorded with byte size and SHA-256 in the Production Package. Do not place Markdown image syntax, HTML image elements, image filenames, image paths or image URLs in the Blog `.md` file.

---

## 5. Variable Content Blocks

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

## 6. Prohibited Template Usage

Do not:

- use this template to produce a Blog from Screener alone;
- paste full CSV tables into the Blog;
- use Dashboard as Blog Cover;
- use Social Card as article analysis;
- embed or reference Hero Cover, Dashboard, Table Cards, SEO image, Social Card or any other image inside the Blog manuscript;
- put HTML source inside the `.md` manuscript instead of the independent `.html` file;
- use heading elements other than `<h3>` for HTML article sections;
- leave HTML article prose outside `<p>`;
- append URL, Page title or Page description metadata paragraphs to the HTML source;
- treat APL Momentum Leaders 領導股 as investment advice;
- include price targets or recommendations.
