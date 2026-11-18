## HTML 共用視覺合約 — 2026-10-19 修訂

自下一期 ScanDate 2026-10-20 起，完整 HTML 與公開預覽必須使用 `tools/client_article_html.ps1` 的同一製作方法。今期另交更正版，已發布與 Archive 原件保留。

- 透明背景容器：width 100%、max-width 800px、置中；Arial / Microsoft JhengHei / sans-serif。
- 正文 18px、行距 1.95、段落下距固定 23px；H3 25px、行距 1.5、章節前距 34px、下距 23px，附底部分隔線。
- 首段摘要使用深色重點框；金色文字只標示該段一個核心研究判斷。其餘正文保持淺色。
- 以當期 Top 30 及單日榜前五公司代碼為依據，文章中每家公司首次出現的代碼加粗一次，後續不重複加粗；股票代碼用淺色，不全部染金。
- 不加入 H1；容器內第一個內容標題仍為 Executive Summary H3。此條取代過往要求檔案第一個標籤必須為裸 H3 的格式限制，八節正文及無來源連結合約不變。
- 公開預覽沿用同一樣式，僅保留完整摘要、市場背景首段及第二段首句／分句加 ...。關閉樣式容器後，以唯一 `<div id="apl-member-content"></div>` 結束；不得洩漏其後會員內容。
- Finalize 在來源驗證後、內容 Preflight 前套用樣式；Preflight、補充檔產生與 Final Audit 必須檢查樣式。Notification 只以正規化內容檢查標題，來源雜湊仍使用實際交付檔。
- 不從歷史 work、更正版或對話記憶讀取製作邏輯。規則、共用工具及測試均在 Repository 內，跨電腦使用相同製作方法。

# APL Momentum Leaders Blog Template

## 客戶文章不展示來源連結 — 2026-10-12 修訂

今日更正版及往後客戶文章，不附新聞、公司公告或產品資料的來源超連結、URL、來源註腳或 Sources 清單。適用完整 Markdown 正文、完整 HTML、公開預覽及 WhatsApp 分析正文；HTML 不輸出 `<a href=...>` 來源標籤，也不留下「AP機場報道」「公司公告」等孤立引用文字。文章必要的事實、日期、期間及研究判斷保留，來源查核與來源路徑、URL、時間、SHA-256 留在內部新聞快照及編輯證據。Markdown 置頂 SEO and Sharing 的 Canonical URL、SEO 圖，以及 WhatsApp 固定文章／體驗 CTA 是交付用途，照常保留。此規則優先於下方保留正文來源連結的舊說明。已發布與 Archive 原件保留，修訂稿另存並交付。


## 完整 HTML 無 H1 — 2026-10-12 修訂

自下一期 ScanDate 2026-10-13 起，完整 `.html.txt` 與公開預覽均直接以 `<h3>Executive Summary｜執行摘要</h3>` 開頭，不得包含 `<h1>`，也不得在摘要之前加入標題、日期或導言。完整文章標題只留在 Markdown `#` 及 SEO Page title，兩者保持一致。完整 HTML 保留八節正文，來源記錄留於內部，以 Risk 結束；公開預覽及會員 SQL 其餘合約維持。此規則取代下方完整 HTML 必須含 H1／與 Markdown 標題相同的歷史說明。10 月 12 日已完成原稿及 Archive 保留，當期另交付無 H1 更正版。


## 升幅統計時段 — 2026-10-06 修訂

出稿前核對 CSV 升幅欄位。現行來源 `Price change %, 1 day` 為單日數據，文章標題須為 `Top Gainers — 1 Day｜單日升幅榜`，圖卡標題須為 `Top Gainers — 1 Day`；正文、百分比標籤及 WhatsApp 必須同樣採單日口徑。不得把觀察名單、匯出日期或累積掃描期間當成升幅計算期間。若來源改為七日數據，必須先同步更新欄位驗證與標題合約，再生產，不能用單日數值寫成七日升幅。此規則取代舊有固定七日標題；已封存原件保留，10月2日及5日另交付更正版。


## Markdown SEO 置頂規則 — 2026-10-05 修訂起執行

今日修訂版及往後新稿，完整 `## SEO and Sharing` 區塊置於 Markdown 檔案最上方，在 `#` 文章標題與 Executive Summary 之前；依次包含 Page title、Page description、Sharing summary、Canonical URL、SEO 圖。2026-10-06 修訂版及往後新稿，SEO 圖欄位必須提供同一期正式 SEO PNG 的可點擊 Markdown 連結，使用絕對路徑，含空格時以 `<...>` 包住；交付前確認圖片存在及日期一致。此連結是下方禁止圖片引用規則的唯一例外，只放於 SEO metadata，不嵌入文章正文。正文仍按八節順序，以 Risk 結束。SEO 只屬 Markdown，不加入完整 HTML 或公開預覽。此規則優先於下方 SEO 放在文末的歷史說明；已完成發布及封存的原版保留，更正以版本化修訂交付。

> **目前模板：ScanDate 2026-09-30 起**採八節研究報告，取消下方歷史範本的 Deep-Scan Conclusion，Markdown-only SEO and Sharing 依置頂規則放在文章標題之前，正文以 Risk 結束。摘要三段依次交代本期判斷、重點關注公司與理由、客戶應如何理解領導股；不得加入掃描／通過門檻數量。Risk 一至兩段，末句連結本期局勢及個別基本面差異。避免反覆等待收入／盈利驗證或要求讀者自行研究。禁止「報道時點觀察、非即時報價、價格可能已變、請自行查證」等編輯免責說明；以必要的日期、期間或「一度／盤中」直接交代事實，核對紀錄留在內部。歷史範本的獨立結論、三段風險、下一個確認訊號要求僅適用 2026-09-29 或之前。

> **Effective-date editorial boundary:** For ScanDate 2026-08-28 onward, omit `Call to Action｜延伸閱讀` and `Disclaimer｜免責聲明` from both Markdown and HTML. `Deep-Scan Conclusion｜深度掃描結論` is the final article section, followed only by the Markdown-only `SEO and Sharing` metadata block. From 2026-08-30 onward, `Investment Implication｜投資啟示` is mandatory immediately after Sector Analysis and before Risk. CTA／Disclaimer examples below apply only to 2026-08-10 through 2026-08-27 legacy-compatible packages.

This template provides the production skeleton for formal APL Momentum Leaders 領導股 Blog articles.

## Public preview and member SQL supplement

Apply the Blog Rules public-preview/member-SQL rule. Keep the full .html.txt unchanged as complete article source. Derive .public-preview.html.txt from it; from ScanDate 2026-09-29 onward, this preview starts at <h3>Executive Summary｜執行摘要</h3> without an h1, while the complete HTML retains its h1. For .article.sql, keep content exactly '<p>PASTE' for the user to fill manually, required_product='deepscan', and both slug values equal to the final path segment of the same-date 詳細文章 URL. Never embed article HTML or execute the SQL template.

Example preview ending:
<p>供稿所列 Brent 早段約報每桶101.52美元...</p>

<div id="apl-member-content"></div>

Use the actual second Market Context paragraph, not this example sentence. The decimal point is not punctuation for truncation. The public preview contains no later article content. HTML source files contain literal tags without Markdown fences. Historical supplements under `work/publishing-revisions/<ScanDate>/` remain legacy evidence; new full Trigger C runs generate the complete HTML source, public preview and member SQL natively inside `production-package/` before Final Audit.


## 2026-09-08 起稿優先指引

省略下方legacy示例的 Deep-Scan Overview（Markdown及HTML均不生成），其餘九個分析章節保留，不改名重建公式化數字摘要。下方Overview僅供2026-09-07及以前歷史相容。新稿由Why APL當期問題直接帶入Top Gainers，再推進公司與板塊分析。

私有編輯卡（不得複製到客戶稿）：
- 標題第二句有何具體發現？摘要是否回答，而非只說待確認？
- 與最近三期相比，有何新證據或有證據的延續？
- 新入榜以最近可比正式Top30作對照，記錄日期；只挑值得解釋公司，不寫退出名單，不硬湊新公司。
- 每節有何新推理？數字若無助理解便省略，不以分號長串或平均分代替業務解釋。
- 累計上榜名單／次數／4期門檻、候選排序、5／10日績效完全限內部，不進公開文章、分享稿或圖表。
- 獨立公司文章先查已有及製作中稿件；每次編輯排期最多一間或零間，候選達標不自動起稿或發布。
- Markdown與HTML順序及論點對等；人工讀者審稿不得冒充machine自動判定。

It is used during Trigger C only:

```text
Trigger C Inputs
+
Top Gainers — 1 Day
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


### Reader-first drafting card（私有指引；2026-09-05 起）

起稿前簡短回答：
- 讀者今期最需要釐清哪一個問題？
- 哪項當期事實或矛盾值得開場？為何重要？
- 哪些是來源事實、分析推論或條件情境？
- 與最近三期可取得文章相比，是新證據、判斷改變，還是原判斷延續？記錄比較日期；取不到舊稿便記錄限制。
- 哪幾個公司／數字最能解釋問題？每個例子增加什麼理解？
- 結尾回答什麼，下一步可以觀察哪些具體訊號？

以上是思考問題，不是可複製的文章句子。依 Blog Rules 的 Reader-first editorial standard 起稿；保留固定 section 次序，讓行文及承接由當期證據推動。不得只把昨日「結構變化」換成今日「市場變化」。

完成後連續閱讀全文：刪去重複背景、解釋術語、把數字連接至讀者意義，確認價格／排名證據沒有被寫成已量度的資金淨流入。分別記錄事實審稿與讀者品質判定；machine preflight 不代表文章自然好讀。

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

Top Gainers — 1 Day｜單日升幅榜
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

The `.md` manuscript starts with the complete Markdown-only `## SEO and Sharing` block before the article title (2026-10-05 revision onward). From the 2026-10-06 revision onward, this metadata includes a hyperlink to the same-date formal SEO PNG. The `.html.txt` file contains publish-ready HTML source with literal tags visible to the operator and article content only. The article body and HTML must not embed or reference images. Do not generate a duplicate `.html` artifact.

The same editorial preparation also creates two independent companion text artifacts:

- `WhatsApp_<ScanDate>.md`: a concise distribution message whose first screen states the largest market change and the question it raises. Select only the evidence needed for mobile reading; do not reproduce the complete Blog. Use a natural market event → APL viewpoint → investor watchpoints／risk → issue-specific reading invitation sequence. Vary paragraphing and sentence shape; literal block labels are optional. From 2026-09-25, put the disclaimer before the fixed two-link footer below.
- For ScanDate 2026-09-04 onward, use the canonical URL `https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD`; do not generate the retired `apl-momentum-leaders-YYYY-MM-DD` slug for a new package.

Recommended WhatsApp shape (the prose above the footer is guidance, not a fill-in form):

```markdown
🌊APL Deep-Scan 美股深海雷達

[Market event and why the market standard changed.]

📊 **APL Deep-Scan 觀察近期美股領導結構**，[APL interpretation and sectors/business models.]

• [Investor watchpoint 1]
• [Investor watchpoint 2]
• [Risk or falsification condition]

[One natural sentence explaining what today's full research resolves.]

研究摘要，不構成投資建議。

📖 今日完整研究：
https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD

🐧 APL 三日免費體驗｜工具・分析・課程
https://www.goinvestingnow.com/ExploreCourses
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


<h3>Executive Summary｜執行摘要</h3>
<p>[Open with current source-supported evidence or tension and the issue judgment.]</p>
<p>[Explain reader significance and leadership implications, separating facts from inference.]</p>
<p>[Identify the next observable confirmation or invalidation signal; complete required depth without filler.]</p>

<h3>Market Context｜市場背景</h3>

<h4>[市場背景小標題一]</h4>
<p>[One or more paragraphs interpreting this market background through capital flow and leadership structure.]</p>

<h4>[市場背景小標題二]</h4>
<p>[One or more paragraphs preserving the next major market argument.]</p>

<h3>Why APL Momentum Leaders Matter｜為什麼要看領導股？</h3>
<p>[Transition from Market Context: explain why the broad index cannot reveal the capital shift, then explain the framework. End by asking whether the quantitative evidence still shows leadership. Not a recommendation list.]</p>

<h3>Deep-Scan Overview｜深度掃描概覽</h3>
<p>[Transition from framework to evidence: explain what the quantitative results support or challenge in the core proposition, not only the counts. End by asking whether short-term capital selection is consistent.]</p>

<h3>Top Gainers — 1 Day｜單日升幅榜</h3>
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


```

The fenced block above demonstrates the required source structure only. Write that source to `APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html.txt` without a surrounding Markdown code fence. Do not write it into the `.md` manuscript and do not create a duplicate `.html` file.

The HTML file must not end with `詳細文章`, `Page title` or `Page description` paragraphs. Keep those fields outside the HTML source.

From 2026-08-05, the Blog heading is `<h3>Top Gainers — 1 Day｜單日升幅榜</h3>`. The Table Card title remains exact English `Top Gainers — 1 Day` and must not receive the Chinese suffix. Put issue-specific interpretation in the following `<p>`.

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

## Markdown-only SEO and Sharing block

For historical packages before the 2026-10-05 revision, append this final block directly after `## Deep-Scan Conclusion｜深度掃描結論`. For 2026-08-10 through 2026-08-27 legacy-compatible packages, append it after CTA／Disclaimer. Replace every field with issue-specific values.

```markdown
## SEO and Sharing

詳細文章：https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD

Page title：[Must exactly match the article title]

Page description：[One issue-specific summary of APL Momentum Leaders, market leadership and the current theme.]

Sharing summary：[One concise message for distribution.]
```

For current manuscripts, put this block at the top, use `Canonical URL：` for the article URL, and append the required SEO image field after it:

```markdown
SEO 圖：[SEO 圖](<ABSOLUTE_PRODUCTION_PACKAGE_PATH/APL_Momentum_Leaders_Blog_SEO_YYYY-MM-DD_1280x720.png>)
```

Replace the placeholder with the verified absolute path for that issue. Do not copy this block to the independent HTML article source.
