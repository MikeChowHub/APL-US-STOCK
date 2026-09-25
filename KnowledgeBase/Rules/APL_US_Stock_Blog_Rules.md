# APL US Stock Blog Rules

This document defines stable writing rules for formal APL Momentum Leaders 領導股 Blog production.

## Public preview and member SQL delivery — effective 2026-09-10

For future unpublished deliveries, retain the complete .html.txt article and add .public-preview.html.txt plus .article.sql using the same article filename stem. This supersedes the earlier single-HTML delivery wording.

Public preview: copy h1, the full Executive Summary, Market Context heading and its first paragraph verbatim. In its second paragraph, keep only the text before the first clause/sentence punctuation, replace the punctuation and remaining text with ASCII ..., close </p>, and finish with exactly <div id="apl-member-content"></div>. Decimal points inside numbers are not cutoffs. Never split HTML tags/entities. Missing sections, paragraphs or punctuation require a specific failure, not a guessed excerpt.

SQL delivery template (user revision effective 2026-09-11): INSERT INTO articles (slug, required_product, content) SELECT '<slug>', 'deepscan', '<p>PASTE' WHERE NOT EXISTS (SELECT 1 FROM articles WHERE slug = '<slug>');. Derive both slug values from the final path segment of the same-date 詳細文章 URL. Keep content exactly '<p>PASTE'; the user inserts the article manually. Do not embed full HTML, preview HTML or an empty string in this SQL template. This explicitly supersedes the earlier full-HTML SQL delivery requirement. Validate both slug values, required_product='deepscan' and literal content='<p>PASTE'. This intentional manual-insertion marker applies only to the SQL delivery template, never to the actual article or Production content. Preserve UTF-8. Before any separate database import, the user must replace PASTE and correctly escape SQL single quotes; never execute the delivered template automatically.

Display three links: 公開預覽 HTML TXT, 完整文章 HTML TXT, 會員文章 SQL. Creating SQL does not authorize database execution. WHERE NOT EXISTS avoids replacing an existing row during serial import; concurrent safety depends on database constraints.

Published outputs/Archive remain immutable. Historical same-date supplements already stored under `work/publishing-revisions/<ScanDate>/` remain non-archived legacy evidence and are not backfilled. For every new full Trigger C run after this integration, the runner must derive `.public-preview.html.txt` and `.article.sql` from the validated complete `.html.txt` before Final Audit and place all three in `production-package/`. They are required package artifacts, recorded by size and SHA-256, copied unchanged by Archive V2, and missing or malformed files fail Production closed.

### Fixed completion delivery list

Every successful Daily Production response must use three visible groups in this exact order and provide individual clickable absolute-path links rather than folder-only links:

Before sending the response, open and compare it against `Assets/Delivery/deep-scan-delivery-reference.png`. This repository asset is the permanent visual checklist for the human-facing delivery. Check the three group labels, every item, link target, and display order against the image and the list below. The image controls presentation only; the published artifacts and their validation rules remain authoritative for file contents.

1. `Table Cards`: `Executive Summary → Deep-Scan Dashboard → Top Gainers → Top Leaders → Sector Structure`.
2. `正式圖像`: `Social Card → Social 完整 Radar → Cover → SEO`.
3. `文章及發布文件`: `今日文章 Markdown → HTML 原始碼 TXT → WhatsApp → Top 30 公司分析 → 公開預覽 HTML 原始碼 → 會員文章 SQL`.

The complete HTML source, public preview and SQL are three distinct required deliveries. Listing one does not satisfy either of the other two. A correct package with an incomplete response is still an incomplete human delivery and must be corrected before handoff is reported complete.


Blog Rules answer:

- how the article should be structured;
- how market context should be integrated;
- what client-facing terminology must be used;
- how article text and visual artifacts must remain separated;
- what content is prohibited.

Visual styling belongs to Visual Rules and Templates.

## Editorial completion authority

### Reader-facing revision — effective ScanDate 2026-09-08

This section supersedes older Overview/section-count instructions below for new dates only. Published outputs and Archive remain immutable. The daily article has **nine** analysis sections: Executive Summary → Market Context → Why APL Momentum Leaders Matter → Top Gainers → Momentum Leaders Analysis → Sector Analysis → Investment Implication → Risk → Deep-Scan Conclusion. Markdown alone then appends SEO and Sharing. Why APL must bridge the current question, not repeat a product introduction.

- **開場與標題：**用當日具體事件、反差或新證據交代與前期的不同；沒有新轉折便如實說明延續。標題第二句提供有證據的研究發現或具體讀者問題，摘要必須回答；不以「待確認」等空泛語作賣點，不暗示知道未來必升必跌。
- **取消獨立 Deep-Scan Overview：**正文不再設此章節，也不改名重建公式化數字段落。不要求逐項報讀 universe、qualified、Leader Lock、平均分等。少量真正有解釋力的數字可融入領導股／板塊分析，交代期間、分母、意義及限制；沒有新增資訊就省略。Dashboard、四張 Table Cards、Company Business Analysis 和機械資料核對保留原有責任。
- **新入榜公司：**公開文章優先挑選少量值得解釋的新入榜公司，說明業務、來源支持的需求及與本期命題的關係；不要求每期一定有新公司，不羅列全部名單，不設退出名單或逐一討論退出股票。新入榜必須對照最近一期可比的正式 Top 30，列明比較日期於私有審稿記錄；資料缺失或評分版本不同時不得冒稱新入榜。現有內部 Top 10 回報研究不改變正式 Top 30 名單定義。
- **每節分工：**摘要給判斷及意義；背景只保留有關事件的因果鏈；短期升幅與中期領導作清楚對照；公司分析推進到板塊群組；投資啟示回答如何理解環境；Risk 解釋反證及機制；Conclusion 回答開頭並給下一個觀察點。較完整段落要增加解釋，不靠同義句或分號清單湊長度。
- **跨期審稿：**可取得時唯讀比較最近三期標題、開頭、命題及結論，記錄日期及差异／延續；缺少歷史便記錄未完成比較，不虛報。刪除無新資訊段落；分開事實與推論；相對強度不等於資金淨流入，排名高不等於買點理想。確認每期有一個有證據的獨特發現，Markdown與HTML source的順序、數據及論點一致。

### Internal research queue — never a client-facing list

累計上榜名單、排序、觸發門檻、內部優先級及5／10交易日回報追蹤，只限內部人員。不得出現在 Blog、WhatsApp、Cover／SEO、公開 Table Cards、客戶 publishing package 或公開公司文章的宣傳文案。公開公司研究講業務及證據，不宣傳「累計入榜幾次」或內部勝率。

1. 正式 Top 30 在 **4個不同 ScanDate** 出現（超過3次）可列入候選；同日重跑及Archive／outputs副本只計一次。記錄首次／最近日期、累計／連續期數及來源；累計不等於連續，不把間隔天數稱為連續持有期。
2. 保留完整歷史、退出記錄及失敗個案於內部，不因不公開退出名單便刪除研究證據。
3. 達門檻只進內部候選池，**不自動生成、發布或承諾公司文章**。同時十間達標也不安排十篇。
4. 每次編輯排期最多優先處理一間，亦可零間；由編輯明確選定，按研究價值、當期相關性、來源完整性及可用產能排序，不能只按出現次數。未選者保留待研究，沒有自動到期或補稿義務。
5. 先查已有已發布／製作中獨立公司文章及日期。沒有才考慮首篇；已有則只在新證據足以更新判斷時安排更新，避免重複出文。
6. 候選池與績效追蹤不是每日Production必需依賴；未研究候選不阻擋每日文章。此為內部編輯規則，不新增watcher、排程或自動公司研究流程。

Overview章節的日期要求由機械gate執行；敘事品質、跨期語義比較、內部資料不外洩及公司排期，由人工／agent審稿記錄判定，不得只憑machine PASS宣稱全部完成。

Trigger C editorial preparation is a required stage between verified Trigger B outputs and Managed Input Preflight. The runner does not write, expand or correct editorial content; it only copies validated publishing artifacts.

Editorial completion requires both Blog formats to contain all date-governed mandatory analysis sections with substantive issue-specific content (nine through 2026-08-29; ten from 2026-08-30 after adding Investment Implication), detailed Market Context derived from the approved market-topic input, current Trigger B numbers, current Top Gainers evidence, a continuous reasoning chain, a responsive conclusion, a substantive WhatsApp summary and non-empty Company Business Analysis. Relative Volume / Market Activity is no longer a mandatory Blog section; its metrics may remain in structured cards, Dashboard or internal audit evidence. Template placeholders, test sentences, summary shells and headings without analysis are not publishing artifacts.

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
- WhatsApp owns the concise text distribution message: the first screen states the largest market change and a reader-relevant question. The issue-matched article URL belongs in the closing fixed footer, after the issue-specific analysis and research disclaimer.
- The `ExecutiveSummary` Table Card owns three to five client-priority observations and their implications.
- Dashboard owns the complete systematic scan context, including the scan funnel, ranked structure, Buyability and sector distribution.
- Social has two independent roles: `Social Card` owns one mobile-first visual message supported by minimal current data; `Social Radar` owns a complete Top 30 radar view with the scan funnel, Buyability and sector distribution. Neither may re-score, re-rank or determine eligibility.
- Cover and SEO own the visual market story; they share one scene concept but use role-specific native compositions.
- `TopLeaders`, `TopGainers` and `SectorStructure` own company-level medium-term evidence, short-term price evidence and group-level structure respectively.
- Company Business Analysis owns the company and business-model reference for the current Top 30; it is not a second market commentary.

For new managed packages from 2026-08-05 onward, WhatsApp must follow one natural mobile-reading chain: market event and core change → APL Deep-Scan／APL Momentum Leaders interpretation → investor watchpoints and falsification risk → issue-specific reading invitation. Visible labels such as `市場事件：` or `APL 觀點：` are optional; paragraphing and sentence shape must vary with the day's evidence. The message must contain an explicit APL viewpoint, observable next signals, and a research disclaimer. The 2026-08-04 Archive message remains immutable legacy output.

For new Production from **2026-09-26 onward**, only the final two CTA blocks are fixed. Put the research disclaimer before them; put no content after them. The preceding reading-invitation sentence must be rewritten for that issue and explain what the full article resolves, not repeat generic membership copy. Use plain URLs, not Markdown links. The footer is exactly:

```markdown
📖 今日完整研究：
https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD

🐧 APL 三日免費體驗｜工具・分析・課程
https://www.goinvestingnow.com/ExploreCourses
```

Only the YYYY-MM-DD in the article URL changes with ScanDate; the two CTA labels, order, spacing and trial URL stay fixed. Do not use the gold-product label `今日完整黃金分析` in APL US STOCK. The completed 2026-09-25 package and Archive retain their historical Markdown-link footer and remain immutable; do not silently replace published bytes or SHA.

For ScanDate **2026-09-04 onward**, the canonical article URL is `https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD`. The same exact-date URL must be used in WhatsApp and the Markdown-only `SEO and Sharing` section. Packages through 2026-09-03 retain the historical `apl-momentum-leaders-YYYY-MM-DD` slug and must not be rewritten.

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
APL Deep-Scan｜美股深海雷達: [issue-specific market conclusion] | YYYY-MM-DD
```

The issue-specific market conclusion is mandatory; it is not a placeholder and must be written for the current market evidence. Use the ASCII colon, one space after the colon, and one space on each side of the date separator (` | `). Example: `APL Deep-Scan｜美股深海雷達: 能源風險回歸，AI 回報受驗證 | 2026-08-04`.

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
Investment Implication｜投資啟示
↓
Risk｜風險
↓
Deep-Scan Conclusion｜深度掃描結論
↓
Call to Action｜延伸閱讀
↓
Disclaimer｜免責聲明
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
Investment Implication｜投資啟示
Risk｜風險
Deep-Scan Conclusion｜深度掃描結論
Call to Action｜延伸閱讀
Disclaimer｜免責聲明
```

The gloss is presentation text only; semantic roles, audit keys and renderer contracts remain unchanged. The `Top Gainers — Past 7 Days` Table Card title remains exact English with no suffix. Blog packages before 2026-08-05 retain the legacy English-only headings and are not rewritten. From 2026-08-10 through 2026-08-27, `Call to Action｜延伸閱讀` and `Disclaimer｜免責聲明` are mandatory in both Markdown and HTML. From 2026-08-28 onward, both sections are prohibited in the formal Blog; `Deep-Scan Conclusion｜深度掃描結論` is the final article section. The exact conclusion heading is `Deep-Scan Conclusion｜深度掃描結論`; shortened or misspelled forms such as `深度掃結論` must fail.

### SEO and Sharing metadata

`## SEO and Sharing` is a required final Markdown-only section. From 2026-08-10 through 2026-08-27 it must follow `Call to Action｜延伸閱讀` and `Disclaimer｜免責聲明`; from 2026-08-28 onward it must immediately follow `Deep-Scan Conclusion｜深度掃描結論`, and include the current issue's `詳細文章：https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD`, `Page title：` matching the article title, `Page description：` summarising APL Momentum Leaders and the issue theme, and one concise sharing summary. This metadata must never be copied into the independent publish-ready HTML article source.

### HTML source delivery rule

Production delivers one HTML-source artifact only:

```text
APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.html.txt
```

The UTF-8 `.html.txt` file contains the publish-ready HTML source verbatim, including visible literal `<h1>`, `<h3>`, `<p>` and `<span>` tags. Production must not also create a same-date `.html` copy. The publishing operator copies the source from `.html.txt` into the target publishing system; a local browser-renderable duplicate is unnecessary and is treated as a duplicate artifact.

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

Investment Implication｜投資啟示
→ How should investors interpret this environment, and how does it connect to APL Momentum Leaders?

Risk｜風險
→ What could disprove the interpretation?

Deep-Scan Conclusion｜深度掃描結論
→ What answers the opening market question, and what is the next confirmation signal?
```

If the section order can be exchanged without changing the reasoning, or if removing a major section leaves the reasoning intact, the narrative chain has failed.

---


## Reader-first editorial standard (effective 2026-09-05)

This standard governs new editorial preparation and human／agent review. Existing source, date, section, minimum-length and Markdown／HTML equivalence gates remain in force. It does not claim that the current validator can certify narrative quality. Published articles remain unchanged.

### 當期切入點與跨期差異

起稿前先確定：讀者今期最需要釐清什麼、哪項當期證據最重要、證據之間存在什麼矛盾。從具體事件、價格與盈利的分歧、供應瓶頸或短中期領導差異切入；只能選來源支持的切入點。

不得連續以「本期最大的市場變化」「本期最大的結構變化」或「市場正由……轉向……」換詞起稿。這些句式並非一律禁用，但同義改寫不構成新觀點。市場沒有重大改變時，明確說明原判斷仍成立，以及當期哪些新證據正在確認或挑戰它，不得為求新鮮虛構轉折。

可取得時，唯讀比較最近三期的開場、核心命題、Investment Implication 與 Conclusion，記錄比較日期，以及本期屬新證據、判斷改變或明確延續。品牌、固定標題、URL 與必需 scope note 不納入創新度判斷。取不到歷史文章時，記錄限制並審核當期內容；不得聲稱已比較，亦不得把歷史 outputs 變成 Cross-PC runtime dependency。字串不同不能證明語義不同。

### 自然文章與證據界線

- 使用清楚繁體中文、自然而有判斷力的研究語氣。專有名詞首次出現便解釋；少用沒有具體主體的「結構驗證／敘事兌現／領導擴散」串句。
- 每段推進一個主要論點，以相關證據解釋其意義。長短句交替；承接可以含蓄，不必每節以問題作結或寫「下一節將驗證」。既有因果關鍵字檢查只是機械條件，加入「因此」並不等於完成推理。
- 清楚分開已知事實、分析推論與條件情境。價格／排名強勢可支持相對強度判斷，但不能單憑它聲稱機構買入、資金淨流入、現金流改善或特定業務催化。直接資金流及基本面聲稱需要相應來源。
- 選少量有代表性的公司，解釋它供應什麼、需求從何而來、如何支持或挑戰核心命題。不能由 ticker、公司名或板塊自行補出合約、盈利趨勢或催化劑；完整 Top 30 參考仍由 Company Business Analysis 負責。
- 每個數字都要有閱讀用途；需要時交代期間、分母及比較基準。Top 30 是篩選樣本，入選比例不等於市場資金集中度，樣本板塊分布亦不能直接證明全市場廣度。保留來源數值準確，避免無助理解的小數堆疊。
- 比喻只用來解釋經濟機制，隨後交代實際含義。不可虛構個人經歷、煽動急迫感、保證回報，或反覆使用口號代替分析。

### 每節給讀者不同收穫

Executive Summary 給出判斷與讀者意義；Market Context 解釋來源證據及傳導機制，不能重播摘要。Why APL Momentum Leaders Matter 要把本期疑問連接至相對強度研究能看見與不能證明的事情，不是每期照抄產品介紹。Overview 解釋樣本及限制。Top Gainers 與 Momentum Leaders 對照短期價格領先與中期持續性，不能把不同來源股票池當成同一母體。Sector Analysis 檢查個股是否形成來源支持的板塊群組。

Investment Implication 回答如何理解環境：哪個經濟環節值得觀察、什麼證據可以確認、什麼仍未知。不能每期硬套 AI／資安／能源故事。Risk 優先解釋最能推翻本期命題的風險及傳導方式，不必列齊所有通用風險。Conclusion 更新開場答案、說清已確認與未確認之處，留下少量可觀察訊號，不再逐節摘要全文。

既有較長段落與字數要求仍適用，但每段必須增加證據、解釋、限制或判斷。不可用固定連接詞、相同結論或無來源細節湊足字數。

### 公開引流與會員內容

另行要求公開引流稿時，以一個有吸引力的問題、少量有用見解、清楚研究價值及自然閱讀邀請組成。可以保留完整 watchlist，但公開內容仍要讓讀者得到實質理解。免費閱讀、會員權益及期限必須符合使用者已確認的當前安排。AI Electricity 只是當期主題例子，不能成為未來文章的預設主線。

WhatsApp 以「市場事件 → APL 觀點 → 應觀察什麼 → 閱讀引導」形成自然手機文章；不照抄固定宣傳段落，不強制每步顯示標籤。此規則不恢復正式 Blog 已移除的 CTA／Disclaimer，Blog 仍以 Conclusion 結束，Markdown 再附 SEO and Sharing。

### 兩次審稿、兩個明確判定

先做事實審稿：來源、日期、公司身份、分母、推論界線、Markdown／HTML 對等。再做讀者審稿：開場是否具體、因果是否連貫、解釋是否有用、是否重複、結尾是否回答開場。把文章連續讀一次，暫時忽略標題，檢查是否仍像一篇文章。

在現有 editorial review evidence 記錄具體段落、發現及修正，分別寫明事實與讀者品質判定。機械 preflight PASS、字數或關鍵字不能替代讀者審稿。無來源聲稱、把舊論點偽裝成新變化、資料堆砌等實質問題必須先修訂才可 editorial approval。這是人工／agent 審稿要求，不新增自動 validator，亦不可虛報為 machine-enforced PASS。

## 2. Executive Summary

The Executive Summary should state the most important market observation directly and must not begin with methodology.

For ScanDate 2026-08-30 onward, it is the analytical opening of an investment weekly rather than a short abstract. It must contain at least three natural prose paragraphs and cover, in order:

1. the issue-specific market change and the opening conclusion;
2. why that change matters and how it is affecting capital allocation, rotation or leadership; and
3. the next observable confirmation or invalidation signal the reader should watch.

It must contain at least 300 substantive characters, at least two causal links, and explicit language for importance, capital flow and the next watchpoint. Repetition, generic filler and copying Market Context do not satisfy this requirement.

---

## 3. Market Context

Market Context must explain the market environment before introducing the APL framework.

Market Context is the Blog's market-reasoning section. For ScanDate 2026-08-30 onward, it must contain at least three natural prose paragraphs and 420 substantive characters: first establish the causal market event, then explain the transmission into valuation, risk appetite and capital flow, and finally identify the next observation point while leading naturally into APL Momentum Leaders. Earlier packages retain their historical two-paragraph policy.

It must state the issue's largest structural market change and establish the core market proposition that the following sections test.

Market Context does not reproduce every source item. It selects the managed facts that best support the issue's core proposition and turns them into the shortest complete, continuous market argument needed to:

1. state the structural market change;
2. explain how it affects capital cost, valuation or capital flow;
3. support the proposition with the most representative managed facts; and
4. lead naturally to why APL Momentum Leaders 領導股 must be examined.

Editorial completeness is determined by whether this reasoning is complete, not by source-item coverage or source order. From 2026-08-30 onward, the three-paragraph and minimum-character gates are additional safeguards against summary shells; they never authorize repetition or unmanaged facts.

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

Executive Summary remains distinct from Market Context and must not replace it. From 2026-08-30 onward it is a fuller investment-weekly opening, but it states the conclusion and reader significance while Market Context supplies the causal market evidence and transmission mechanism.

Trigger B data, ranking results, sector counts and Top Gainers — Past 7 Days results must not be presented as if they were source Market Context. Those inputs belong in their own Blog sections and may only be related back to the market background through editorial analysis.

Blog Markdown and Blog HTML must remain content-equivalent for the final edited Market Context. WhatsApp is an independent social summary and is not required to retain the same evidence or structure.

`Market Context must not become a news dump` means do not pile up unconnected headlines or repeat individual news items without analysis. Editorial preparation should omit or merge weaker items, while retaining enough managed evidence to make the selected causal argument complete.

### Editorial contamination guard

A managed input is not editorially complete merely because it contains the required headings, enough characters or source numbers. The following are hard FAIL conditions:

- copying the same Market Context paragraph, thesis sentence or raw news block into three or more major sections;
- appending the full approved Market Context to Executive Summary, Top Gainers, Momentum Leaders, Sector, Relative Volume, Risk or Conclusion without a new section-specific inference;
- using a mechanically repeated paragraph to satisfy minimum length, Chinese-character or source-coverage checks;
- putting ranking, Top Gainers or sector evidence into Market Context as if it were original market-context evidence;
- allowing a section to be removed or reordered without changing the reasoning chain;
- exposing internal field or workflow labels in client-facing prose, including `universe`, `qualified`, `leaderLock`, `removedBelowSma200Count`, `finalWatchlistCount`, `averageMomentum`, `averageBuyability`, `Trigger B`, `managed input`, `renderer`, `validator` or `pipeline`;
- writing Market Context as one compressed headline dump instead of at least two causal analytical paragraphs;
- pasting Top Gainers rows as a punctuation-heavy CSV-like sentence, using unbalanced brackets, or omitting the separate canonical scope paragraph `Scope: SPX／NDX／DJI constituents. The ranking, prices and changes are point-in-time market data and may change with the market.`;
- writing Momentum Leaders or Sector Analysis as a single semicolon-delimited row list instead of at least two prose paragraphs that interpret company／business-model evidence and then advance the argument;
- omitting `Call to Action｜延伸閱讀` or `Disclaimer｜免責聲明` from either Markdown or HTML for packages dated 2026-08-10 through 2026-08-27, or including either removed section for packages dated 2026-08-28 or later;
- using any conclusion heading other than the exact `Deep-Scan Conclusion｜深度掃描結論` for packages governed by the bilingual heading contract.

### Natural editorial quality gate (effective 2026-08-10)

Machine-readable evidence must be translated into reader-facing analysis before publication. Numeric provenance remains mandatory, but raw field labels belong only to manifests, logs and audits.

- `Deep-Scan Overview` may state the current counts and averages in natural Chinese, but it must explain what they mean for leadership concentration. It must never print internal property names.
- `Market Context` must contain at least two analytical prose paragraphs and at least two explicit causal links such as `因此`, `反映`, `意味`, `導致` or `這代表`. Source headlines are evidence, not the article structure.
- From ScanDate 2026-08-30 onward, Executive Summary must contain at least three natural paragraphs, 300 substantive characters, two causal links and all three layers: why the change matters, how capital is moving, and what to watch next. Market Context must contain at least three natural paragraphs, 420 substantive characters, three causal links and the same three layers grounded only in approved market-context evidence.
- `Top Gainers` must use a small number of selected examples in balanced sentences, followed by the canonical scope／point-in-time note as its own paragraph. It must not serialize the input rows into one sentence.
- `Momentum Leaders Analysis` and `Sector Analysis` must each contain at least two natural prose paragraphs. No paragraph may use more than three semicolons to simulate a table or CSV row list.
- For ScanDate 2026-08-10 through 2026-08-27, Markdown and HTML must contain content-equivalent CTA and disclaimer sections. From 2026-08-28 onward, neither section may appear; the Conclusion must close the article.
- `SEO and Sharing` remains Markdown-only and must be the final section. It must not appear in HTML.

`tools/validate_managed_inputs.ps1` must fail closed on every condition above before Atomic Production starts. Character count, presence of headings and source-number matches are insufficient to override this gate.

Final Audit must compare normalized paragraph blocks across all date-governed mandatory sections (nine through 2026-08-29; ten from 2026-08-30), record any repeated long block, and fail closed when repeated material is not accompanied by a distinct section conclusion. A PASS requires each section to add new evidence, interpretation or a falsifiable next question. This guard applies to Markdown, HTML, WhatsApp, Company Business Analysis and Table Card semantic inputs; structured fields must remain concise and role-specific rather than carrying Blog prose.

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

It must move from individual-stock strength to an industry-group judgment, then lead into what that structure means for investor interpretation and capital allocation.

It should connect:

```text
sector distribution
→ business structure
→ capital flow
→ market implication
```

If structured data needs a visual treatment, generate a separate Blog Table Card artifact. Do not embed or reference that artifact inside the Blog Markdown file.

---

## 9. Investment Implication

From **2026-08-30** onward, `Investment Implication｜投資啟示` is a mandatory client-facing analysis layer immediately after `Sector Analysis｜板塊結構分析` and before `Risk｜風險`. It must answer: **所以投資者而家應該點理解呢個環境？** It is an interpretation of the preceding evidence, not a repetition of Market Context and not personalized investment advice.

The section must contain at least five natural prose paragraphs and at least 650 substantive characters. It must form a continuous argument that covers:

1. how investors should interpret the current market regime and what selection standard has changed;
2. which primary capital-expenditure, demand or leadership direction has the strongest economic support;
3. whether a secondary beneficiary curve or broader sector expansion is emerging;
4. how current `APL Momentum Leaders` cross-sector evidence and market breadth support or challenge that interpretation;
5. how macro costs, valuation, cash flow and balance-sheet quality affect resilience, followed by the next confirmation or invalidation signal.

The section should translate theme exposure into sustainable economic benefit. It should distinguish being associated with a popular narrative from converting demand into revenue, earnings and free cash flow. It should also explain whether leadership is broadening beyond a small group, because the breadth and quality of that expansion determine whether the market is still trading one core story or building a healthier growth structure.

`APL Momentum Leaders` must be connected explicitly and naturally: the framework is used to observe where relative strength, demand, earnings expectations and catalysts are improving together across sectors. Do not assume in advance that the next leader must come from a particular industry, and do not turn the section into a stock list.

The final paragraph must state the current research posture in plain language, such as selective participation rather than indiscriminate chasing, and then lead into the Risk section's falsification tests. Direct buy／sell instructions, target prices, stop losses, personalized allocation commands and certainty claims are prohibited.

Fail closed when the section is missing, too short, fewer than five paragraphs, lacks the explicit `APL Momentum Leaders` link, lacks investor／capital-flow／fundamental／forward-risk layers, copies a Market Context paragraph, or contains direct trading instructions.

---

## 10. Risk

Risk section is mandatory.

It must directly test conditions that could disprove the core proposition; unrelated generic risks are not sufficient. Its closing should lead to the final market judgment.

For newly created managed Blog packages from **2026-08-28** onward, Risk must use a fuller explanatory treatment rather than a short checklist. It must contain at least three natural prose paragraphs and normally cover:

1. the issue-specific falsification conditions;
2. how those conditions would transmit through earnings, valuation, liquidity or sector leadership;
3. the observable market evidence that would show the core proposition is weakening or failing.

The section must be substantive enough to explain causality. Do not lengthen it by repeating the same warning, copying a generic risk list or restating the Market Context without a new risk inference.

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

For newly created managed Blog packages from **2026-08-28** onward, Deep-Scan Conclusion must contain at least three natural prose paragraphs. It must:

1. answer the opening market question directly;
2. explain what the leadership evidence confirms and what remains selective or unresolved;
3. state the next confirmation or invalidation signal and finish with a research-style market observation.

The longer format is an explanatory requirement, not a fixed passage. Every issue must be rewritten from its own approved Market Context, ranking evidence and sector structure; copying a previous conclusion or adding repetitive filler is prohibited.

It should not repeat the whole article.

It should end with a research-style market observation.

---

## 12. Client-facing Naming

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
### Formal output presentation order

When Codex or an operator lists the completed visual research package for the user, the `Table Cards` delivery group must use this fixed, individually linked order:

```text
Executive Summary
→ Deep-Scan Dashboard
→ Top Gainers
→ Top Leaders
→ Sector Structure
```

`Deep-Scan Dashboard` is deliberately included in the presentation sequence between Executive Summary and Top Gainers because it supplies the complete scan context before the short-term and medium-term evidence. It remains a standalone Dashboard artifact at `production-package/`; it is not reclassified as a Table Card and is not moved into `production-package/Table Cards/`.

The four Table Card schemas, filenames, source bindings and physical package paths remain unchanged. This rule governs the human-facing output list／handoff order, not scoring, ranking, renderer sequencing, manifest evidence order or Archive layout. Do not replace the five individual artifact links with a single folder link, and do not list Top Leaders before Top Gainers in this presentation group.

Required Table Cards are source-bound publishing evidence, not free-form illustrations. `TopLeaders` must reproduce the selected current Trigger B ranking rows in rank order with matching symbols, company identities and Composite Scores; `TopGainers` must reproduce the selected current Top Gainers CSV rows in source order with matching symbols, company identities and percentage changes; and `SectorStructure` representative symbols must belong to the current Trigger B Top 30. Any displayed source fact that does not match the current managed evidence is a preflight failure and Production must not start.

`SectorStructure.direction` is a concise Chinese market-direction／capital-structure summary and must contain Chinese text. English-only direction values are invalid; symbols belong only in `representativeSymbols`. This rule applies to new managed packages from 2026-08-05 onward. Existing 2026-08-04 Archive artifacts remain immutable legacy output and are not silently rewritten.

For new managed packages from 2026-09-03 onward, every `SectorStructure.theme` must be a canonical sector in `tools/sector_map.json`; generic labels such as `領導結構`, `選擇性領導` or `市場主線` are not sectors and must fail. Every representative symbol must map to that same sector, and `count` must equal the number of current Trigger B Top 30 symbols mapped to that sector. The card may select the most decision-relevant sector groups for readability, but it must never manufacture a mixed-symbol group or use the number of displayed representatives as the sector count.

`ExecutiveSummary` must contain three to five issue-specific priority observations with a short implication for each. Universe, qualified, leaders, Leader Lock or other scan metrics may appear only when they materially support one of those priority observations. They are not mandatory content because Deep-Scan Overview and Dashboard already own the complete scan context.

For new managed packages, every `ExecutiveSummary` `observation` must be reader-facing Chinese prose, not an English-only label or a raw machine metric dump. When figures are used, the sentence must connect the numbers to a market implication (for example, concentration, breadth or difficulty of entry). The paired `meaning` field must explain the implication in Chinese and define specialist terms such as `Leader Lock` and `Buyability` when they appear. A row that only lists numbers, leaves the implication implicit, or uses unexplained English terminology fails the semantic gate. This rule is effective from 2026-08-05; the 2026-08-04 archived card remains immutable legacy output.

The four required cards must not collapse into four presentations of the same data:

- `ExecutiveSummary` synthesizes priority conclusions;
- `TopLeaders` provides medium-term company-level evidence;
- `TopGainers` provides short-term price-leadership evidence;
- `SectorStructure` provides group-level structural evidence.

---

## 14. HTML Source Contract

### Source and table-note typography — effective 2026-09-17

資料來源及表註屬輔助文字。Blog 的獨立範圍註記使用 `<sup><small>Scope: SPX／NDX／DJI constituents.</small></sup>`；HTML source 將它包於獨立 `<p>` 內，保留上標小字，不轉義成可見標籤。Markdown 可保留此局部行內排版標記，主要文章仍為 Markdown。其他來源／表註採同等輔助字級，不能與正文等大。Table Card 的 SourceNote／FooterNote 保留現有獨立小字區；不得縮小主欄位來代替註記排版。既有已發布文件不改寫。

The publish-ready HTML source must be delivered as a separate same-date file:

```text
APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html.txt
```

The `.md` manuscript and `.html.txt` source are two independent editorial artifacts. Do not place HTML source inside the `.md` file and do not generate an additional `.html` duplicate.

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
<p>詳細文章：https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD</p>
<p>Page title：...</p>
<p>Page description：...</p>
```

These publishing metadata values may remain in the separate `.md` manuscript or another publishing record, but they are not part of publishable article HTML.

---

## 15. URL and Publishing

Formal Blog URL format for ScanDate 2026-09-04 onward:

```text
https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD
```

Page title should match the article title.

Page description should summarize APL Momentum Leaders 領導股, market leadership, and current theme.

---

## 16. Prohibited Blog Patterns

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
- generate a same-date `.html` duplicate beside the required `.html.txt` source;
- append URL, Page title or Page description metadata paragraphs to the independent HTML source.

## Answer-led headline rule (effective 2026-09-06)

- 前半句交代市場變化；後半句交付研究價值：具體領導方向、受惠機制、分化結果，或正文能回答的具體問題。
- 禁止「領導結構待確認」「有待觀察」「方向未明」「等待市場驗證」等空泛結尾。突出目前已知的發現，把反證條件留在 Risk，而不是以等待代替答案。
- 優先「事件 → 具體研究發現」，其次「事件 → 具體讀者問題」。問題須指向哪些公司、哪類業務或何種機制，Executive Summary 必須交代答案，不可只吊胃口。
- 私有編輯卡記錄讀者問題、證據支持的答案、來源及正文兌現位置；不得輸出內部編輯欄位。
- 肯定不等於保證升跌：禁止必升、穩賺、一定受惠。排名只支持相對強勢觀察，不能冒充資金淨流入；業務受惠須有来源與因果機制，不可因油價上升就推定所有能源公司受惠。
- 每期由當期證據產生標題，不套用固定板塊或句型；觀察到相對強勢不等於盈利已兌現。
- 適用 Blog、Page title、Cover／SEO；既有品牌、日期及跨格式一致性不變，視覺標題可精簡但不可改變結論。
- 必須進行人工／agent 語意審核；不代表現有 validator 已自動辨識弱標題。未核對承諾與證據不得宣稱 editorial review PASS。
- 僅適用後續製作，不改寫既有 outputs 或 Archive。
