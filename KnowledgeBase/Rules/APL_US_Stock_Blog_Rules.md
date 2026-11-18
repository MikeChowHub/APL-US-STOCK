# APL US Stock Blog Rules

## 2026-11-12 製作與閱讀品質合約

本節自 **ScanDate 2026-11-12 起**優先適用。現行起稿入口為 [Blog Template](../Templates/Blog_Template.md)；歷史日期依當時有效政策處理，既有發布及 Archive 原件保留。本次修訂不改變量化計分、排名、來源綁定、圖像生產、封存完整性及完成狀態合約。

### 先完成研究，再用八節交付判斷

報告直接回答「本期優先關注誰、為何選它、與其它機會有何差異」。每個主選公司都須有正式排名證據、至少一項具體業務證據，以及相對其它候選的選擇理由。業務證據可以是有來源的產品、客戶需求、收入結構、訂單或財務事實，不能只填產業熱門詞。正文把已核實事實與分析推論說清楚；自信來自證據，不保證回報。

| 固定章節 | 這節增加的內容 | 現行篇幅底線 |
| --- | --- | --- |
| Executive Summary｜執行摘要 | 本期核心判斷、主選及對讀者的意義 | 三段，至少 180 實質字符。 |
| Market Context｜市場背景 | 相關新聞如何改變需求、成本或估值 | 至少兩段，通常兩至三段；至少 240 實質字符。 |
| Why APL Momentum Leaders Matter｜為什麼要看領導股？ | 本期為何需要比較公司相對強度 | 簡短承接當期問題，不重複產品介紹。 |
| Top Gainers — 1 Day｜單日升幅榜 | 單日價格領先與持續動能的差異 | 有選擇的例子及固定 scope note。 |
| Momentum Leaders Analysis｜動能領導股分析 | 具體公司選擇與業務證據 | 至少兩段自然分析，完整 Top 30 另見公司分析。 |
| Sector Analysis｜板塊結構分析 | 個股之間的業務共通點與差異 | 至少兩段，不把排名分布冒充資金流。 |
| Investment Implication｜投資啟示 | 關注優先次序與機會比較 | 兩至三段，至少 180 實質字符；自然連接 APL Momentum Leaders。 |
| Risk｜風險 | 最重要風險的傳導機制及判斷收束 | 一至兩段，末句收束；不另設 Conclusion。 |

實質字符依現行工具正規化正文後計算，排除標題與格式標記。這是防止空殼的內容底線，不是寫作目標。**新稿取消投資啟示五段／650 字符及摘要、背景舊有長度要求**；不再強迫每節加入「等需求變收入／盈利」或未來驗證段。投資啟示給出優先次序和區別，不能重播背景、財報或逐股清單。每段只推進一個主要論點，刪除沒有新資訊的同義句。

### 把查核與分類完成於編輯端

- 保存 CSV 原始 Industry，配合公司產品與收入模式作有證據的業務分類，並留下來源與歸類依據。陌生公司先補研究；客戶稿不得以 Others、未分類或工具不支援作分析結論，不因名稱相似便歸入同一主題。正式圖卡數量與代表股票仍須符合來源綁定。
- 排名和升幅只證明該資料口徑下的相對價格表現。機構買入、資金淨流入、訂單或現金流改善必須另有直接證據。Price change %, 1 day 一律稱單日升幅；強勢股不等於已確認買點，不憑排名作必升判斷。
- 核對數字的方向、基期與單位。月增率由 0.6% 降至 0.4% 是漲幅放慢，不能寫成通脹加速；價格仍上升也不能寫成價格下跌。按年、按月、季度和年化數值各自比較，預測不寫成已公布結果。
- 僅保留有助理解本期選擇的數字。掃描母體、通過數、內部平均分、流程及分類缺口不放入客戶文章、WhatsApp 或摘要圖卡。
- 來源 URL、資料時間、SHA-256 與核對細節留在現有內部證據；正文不放來源連結、Sources、孤立引用標籤，亦不說「非即時報價」「請自行核對」。必要日期、季度或「盤中／一度」正常寫明；資料不足先補查、收窄或刪除主張。
- 唯讀比較最近三期可取得的標題、摘要、投資啟示及風險收束。記錄新證據、判斷變化或有證據的延續；缺少可比檔案時在現有編輯記錄說明限制，不硬湊新故事、不把歷史輸出變成執行依賴。

### 兩次審稿與既有製作流程銜接

Initialize 建立來源綁定 → 完成公司證據、Markdown 與 Top 30 公司分析 → 事實審稿 → 讀者審稿 → Review 草稿檢查 → WhatsApp、圖卡及原生背景 → Finalize 從定稿產生完整 HTML 並執行 Managed Input Preflight → Produce 以同日已定版資料啟動 Atomic Production（含公開預覽）→ Final Production Audit → Archive V2 完整性及索引／最終 manifest 驗證。正文有修改時先更新 Markdown，重跑工作單的 Finalize 指令以重建暫存 HTML。修改影響數字、公司或主張時，同步核對相關交付件；完成與可發布的權威狀態仍須均為 true。

Review 使用現行 tools/prepare_trigger_c_managed_inputs.ps1 的 Review 模式，先檢查來源雜湊、長段／長句跨段複製、Top 30 公司段落、模板句及內部分類侷限字眼，不要求 HTML 或圖片完成，也不改動狀態。DRAFT_READER_CHECKS_PASS 僅代表這些機械檢查通過；MechanicalOnly=true、FullPreflightStillRequired=true，不等於可發布。

事實審稿確認日期、公司身份、排名、Industry、業務證據、數字方向／基期／單位、推論界線及跨格式一致。讀者審稿連續閱讀全文，判斷開頭有沒有答案、選擇理由是否具體、每節有沒有新資訊、句子是否易懂、結尾是否回答本期問題。兩次結果、實際發現及修改位置寫入**現有** editorial review evidence，不新增必填打勾表。機械閘門只排除已知缺陷；字數、關鍵字或 PASS 不能證明文章自然好讀，亦不得當成人工／agent 審稿已完成。

### 保持的交付合約

Markdown 最上為 SEO and Sharing，含同日 SEO 圖連結，再接完整 H1 標題及八節正文。完整 HTML 與公開預覽共用 tools/client_article_html.ps1，不含 H1，容器內第一標題為 Executive Summary H3；段距 23px、章節前距 34px、首次 ticker 加粗、金色只標核心判斷。公開預覽以唯一會員標記結束；SQL 的 content 恰為 `'<p>PASTE'`，不得自動執行。WhatsApp 保持品牌台頭、研究免責與兩組固定 CTA。每次交付前查看 Assets/Delivery/deep-scan-delivery-reference.png，逐項核對三組連結；Executive Summary 圖卡須含本期市場背景重點及選股意義。其餘視覺、來源、檔名與封存合約照常執行。

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

## 客戶文章不展示來源連結 — 2026-10-12 修訂

今日更正版及往後客戶文章，不附新聞、公司公告或產品資料的來源超連結、URL、來源註腳或 Sources 清單。適用完整 Markdown 正文、完整 HTML、公開預覽及 WhatsApp 分析正文；HTML 不輸出 `<a href=...>` 來源標籤，也不留下「AP機場報道」「公司公告」等孤立引用文字。文章必要的事實、日期、期間及研究判斷保留，來源查核與來源路徑、URL、時間、SHA-256 留在內部新聞快照及編輯證據。Markdown 置頂 SEO and Sharing 的 Canonical URL、SEO 圖，以及 WhatsApp 固定文章／體驗 CTA 是交付用途，照常保留。此規則優先於下方保留正文來源連結的舊說明。已發布與 Archive 原件保留，修訂稿另存並交付。


## 完整 HTML 無 H1 — 2026-10-12 修訂

自 ScanDate 2026-10-13 起，完整 `.html.txt` 與公開預覽不得包含 `<h1>`，也不得在摘要之前加入標題、日期或導言；2026-10-13 至 2026-10-19 直接以 `<h3>Executive Summary｜執行摘要</h3>` 開頭，2026-10-20 起依共用容器合約，以該 H3 作容器內第一個內容標題。完整文章標題只留在 Markdown `#` 及 SEO Page title，兩者保持一致。完整 HTML 保留八節正文，來源記錄留於內部，以 Risk 結束；公開預覽及會員 SQL 其餘合約維持。此規則取代下方完整 HTML 必須含 H1／與 Markdown 標題相同的歷史說明。10 月 12 日已完成原稿及 Archive 保留，當期另交付無 H1 更正版。


## 升幅統計時段 — 2026-10-06 修訂

出稿前核對 CSV 升幅欄位。現行來源 `Price change %, 1 day` 為單日數據，文章標題須為 `Top Gainers — 1 Day｜單日升幅榜`，圖卡標題須為 `Top Gainers — 1 Day`；正文、百分比標籤及 WhatsApp 必須同樣採單日口徑。不得把觀察名單、匯出日期或累積掃描期間當成升幅計算期間。若來源改為七日數據，必須先同步更新欄位驗證與標題合約，再生產，不能用單日數值寫成七日升幅。此規則取代舊有固定七日標題；已封存原件保留，10月2日及5日另交付更正版。


## Markdown SEO 置頂規則 — 2026-10-05 修訂起執行

今日修訂版及往後新稿，完整 `## SEO and Sharing` 區塊置於 Markdown 檔案最上方，在 `#` 文章標題與 Executive Summary 之前；依次包含 Page title、Page description、Sharing summary、Canonical URL、SEO 圖。2026-10-06 修訂版及往後新稿，SEO 圖欄位必須提供同一期正式 SEO PNG 的可點擊 Markdown 連結，使用絕對路徑，含空格時以 `<...>` 包住；交付前確認圖片存在及日期一致。此連結是下方禁止圖片引用規則的唯一例外，只放於 SEO metadata，不嵌入文章正文。正文仍按八節順序，以 Risk 結束。SEO 只屬 Markdown，不加入完整 HTML 或公開預覽。此規則優先於下方 SEO 放在文末的歷史說明；已完成發布及封存的原版保留，更正以版本化修訂交付。


This document defines stable writing rules for formal APL Momentum Leaders 領導股 Blog production.

## 客戶動能研究報告規則 — 2026-09-29 修訂，下一期 ScanDate 2026-09-30 起執行

本節優先於下方舊版九節架構、獨立結論及反覆確認訊號要求。歷史已發布產物保留原狀。

- 報告目的：識別市場相對動能較強、值得推薦客戶重點關注的股票。編輯須完成研究，明確提出本期首選關注公司、動能證據、選擇理由及主要風險。可以肯定陳述已確認的排名、價格表現和來源支持的業務事實；研究判斷清楚表達，不保證未來回報，也不虛構消息與股價的因果。
- 執行摘要直接回答「本期看好／重點關注哪些公司、原因是甚麼、對客戶有甚麼意義」。不報讀掃描母體、通過門檻數量、剔除數、Leader Lock、平均模型分數或內部操作流程。不把這些內容移到其他文章段落、WhatsApp 或 Executive Summary 卡片。既有量化 Dashboard 數據展示另按視覺合約管理。
- 語氣以有證據的研究結論為主。禁止每節反覆寫「仍待確認」「要等需求變收入／盈利」「請讀者自行核對公司」「價格隨時會變」等通用退讓句，或以「排名只提供起點」收回全文判斷。資料不足的特定公司或因果應收窄主張、補研究或不推薦，不將研究責任交回客戶。
- **直接陳述，時點核對留在內部：**正文、摘要、WhatsApp 及客戶圖卡不得出現「那是報道時點觀察，並非本篇發布時的即時報價」「非即時報價」「價格可能已變，請自行查證」等編輯過程或自我免責句，換句話說也不接受。資料核實、來源時間及截點記錄由編輯完成並留於內部。正文直接寫已核實事實，例如「美國10年期國債孳息率一度升穿5.27%，推高成長股估值壓力。」必要時正常標明日期、期間或「盤中／一度」，不得把歷史數字冒寫成即時數字。資料不足便先補足研究或刪除該主張，不要求客戶代做核對。此要求適用風險段落，不能把同類免責句搬到末段。
- 結構固定為八節：Executive Summary → Market Context → Why APL Momentum Leaders Matter → Top Gainers → Momentum Leaders Analysis → Sector Analysis → Investment Implication → Risk。取消獨立 Deep-Scan Conclusion。Markdown 的 SEO and Sharing 依置頂規則放在文章標題之前；HTML 以 Risk 結束。
- Risk 用一至兩段集中說明本期最重要、具體的風險及影響機制，最後一句收束本期判斷並提醒基本面差異。不另加三段結論、不重播全文、不用固定字數逼出重複懷疑。例：「本期能源與利率變化牽動部分強勢股，但各公司上升驅動並不相同，選股仍須兼顧個別基本面。」實際句子須按當期證據改寫。
- 摘要及背景保留因果解釋，但不再強制每節寫未來確認條件。投資啟示說明本期推薦關注的優先次序與理由；僅對實質不確定處作一次適度交代，風險集中在末節。
- 交付前人工審稿：能否讀完直接知道推薦關注誰及原因？有無內部數字？有無跨段重複等待盈利／收入驗證？結尾有無推翻前文或叫客戶代做研究？機械檢查只能攔截已知句式，不能代替此審稿。

## Public preview and member SQL delivery — effective 2026-09-10

For future unpublished deliveries, retain the complete .html.txt article and add .public-preview.html.txt plus .article.sql using the same article filename stem. This supersedes the earlier single-HTML delivery wording.

Public preview: for ScanDate before 2026-09-29, copy h1, the full Executive Summary, Market Context heading and its first paragraph verbatim. From ScanDate 2026-09-29 onward, omit the h1 and begin with <h3>Executive Summary｜執行摘要</h3>. In its second Market Context paragraph, keep only the text before the first clause/sentence punctuation, replace the punctuation and remaining text with ASCII ..., close </p>, and finish with exactly <div id="apl-member-content"></div>. Decimal points inside numbers are not cutoffs. Never split HTML tags/entities. Missing sections, paragraphs or punctuation require a specific failure, not a guessed excerpt. Only full .html.txt packages before 2026-10-13 retain an h1; later packages apply the no-H1 rule and, from 2026-10-20, the shared style container. Published outputs and Archive remain unchanged.

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

The nine-section structure in this paragraph applies only to ScanDate 2026-09-08 through 2026-09-29. From 2026-09-30 use the eight-section contract above. Published outputs and Archive remain immutable. The historical article has **nine** analysis sections: Executive Summary → Market Context → Why APL Momentum Leaders Matter → Top Gainers → Momentum Leaders Analysis → Sector Analysis → Investment Implication → Risk → Deep-Scan Conclusion. For those historical dates Markdown alone then appends SEO and Sharing. Why APL must bridge the current question, not repeat a product introduction.

- **開場與標題：**用當日具體事件、反差或新證據交代與前期的不同；沒有新轉折便如實說明延續。標題第二句提供有證據的研究發現或具體讀者問題，摘要必須回答；不以「待確認」等空泛語作賣點，不暗示知道未來必升必跌。
- **取消獨立 Deep-Scan Overview：**正文不再設此章節，也不改名重建公式化數字段落。不要求逐項報讀 universe、qualified、Leader Lock、平均分等。少量真正有解釋力的數字可融入領導股／板塊分析，交代期間、分母、意義及限制；沒有新增資訊就省略。Dashboard、四張 Table Cards、Company Business Analysis 和機械資料核對保留原有責任。
- **新入榜公司：**公開文章優先挑選少量值得解釋的新入榜公司，說明業務、來源支持的需求及與本期命題的關係；不要求每期一定有新公司，不羅列全部名單，不設退出名單或逐一討論退出股票。新入榜必須對照最近一期可比的正式 Top 30，列明比較日期於私有審稿記錄；資料缺失或評分版本不同時不得冒稱新入榜。現有內部 Top 10 回報研究不改變正式 Top 30 名單定義。
- **每節分工：**摘要給判斷及意義；背景只保留有關事件的因果鏈；短期升幅與中期領導作清楚對照；公司分析推進到板塊群組；投資啟示回答如何理解環境；Risk 解釋反證及機制；2026-09-29 或之前的 Conclusion 回答開頭並給下一個觀察點；之後由 Risk 末句收束。較完整段落要增加解釋，不靠同義句或分號清單湊長度。
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

Editorial completion requires both Blog formats to contain all date-governed mandatory analysis sections with substantive issue-specific content (nine through 2026-08-29; ten from 2026-08-30 through 2026-09-07; nine from 2026-09-08 through 2026-09-29; eight from 2026-09-30), detailed Market Context derived from the approved market-topic input, current Trigger B numbers, current Top Gainers evidence, a continuous reasoning chain, a responsive final Risk paragraph (or the date-governed historical Conclusion), a substantive WhatsApp summary and non-empty Company Business Analysis. Relative Volume / Market Activity is no longer a mandatory Blog section; its metrics may remain in structured cards, Dashboard or internal audit evidence. Template placeholders, test sentences, summary shells and headings without analysis are not publishing artifacts.

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

For new managed packages from 2026-08-05 onward, WhatsApp must follow one natural mobile-reading chain: market event and core change → APL Deep-Scan／APL Momentum Leaders interpretation → investor watchpoints and falsification risk → issue-specific reading invitation. Visible labels such as `市場事件：` or `APL 觀點：` are optional; paragraphing and sentence shape must vary with the day's evidence. The message must contain an explicit APL viewpoint, issue-specific selection reasons and risk, and a research disclaimer. Observable next signals are optional when they add information; do not repeat verification requests. The 2026-08-04 Archive message remains immutable legacy output.

WhatsApp 固定台頭（2026-10-03 起的新 Production 及其後交付修正版）：第一行必須是 `🌊APL Deep-Scan 美股深海雷達`，下一行留空再接正文。不得省略、改字、加 Markdown 粗體或另加日期副標題。交付前必須檢查台頭；既有已封存版本保留，修正版另存於 `work/publishing-revisions/<ScanDate>/` 並交付修正版連結。

For new Production from **2026-09-26 onward**, the branded heading and final two CTA blocks are fixed; the analysis varies by issue. Put the research disclaimer before the CTA blocks; put no content after them. The preceding reading-invitation sentence must be rewritten for that issue and explain what the full article resolves, not repeat generic membership copy. Use plain URLs, not Markdown links. The footer is exactly:

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

The full string is the article title, the Markdown `#` value and the SEO／Sharing `Page title` value. These must be byte-equivalent after UTF-8 decoding. HTML `<h1>` equality applies only before 2026-10-13; later HTML contains no H1. The title is not a subtitle, image-overlay line, or optional branding treatment; a prefix-only title or a prefix followed only by a date is invalid. This applies prospectively and does not alter already published outputs or Archive artifacts.

This flow preserves historical vocabulary only: Overview applies through 2026-09-07, Conclusion through 2026-09-29, CTA／Disclaimer through 2026-08-27, and SEO moves to the top from 2026-10-05. New drafts use the opening eight-section table:

```text
Executive Summary｜執行摘要
↓
Market Context｜市場背景
↓
Why APL Momentum Leaders Matter｜為什麼要看領導股？
↓
Deep-Scan Overview｜深度掃描概覽
↓
Top Gainers — 1 Day｜單日升幅榜
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

From **2026-08-05**, major Blog headings place English first and a short Chinese gloss second, separated by `｜`. The vocabulary below includes historical removed headings; include only sections valid for the ScanDate:

```text
Executive Summary｜執行摘要
Market Context｜市場背景
Why APL Momentum Leaders Matter｜為什麼要看領導股？
Deep-Scan Overview｜深度掃描概覽
Top Gainers — 1 Day｜單日升幅榜
Momentum Leaders Analysis｜動能領導股分析
Sector Analysis｜板塊結構分析
Investment Implication｜投資啟示
Risk｜風險
Deep-Scan Conclusion｜深度掃描結論
Call to Action｜延伸閱讀
Disclaimer｜免責聲明
```

The gloss is presentation text only; semantic roles, audit keys and renderer contracts remain unchanged. The `Top Gainers — 1 Day` Table Card title remains exact English with no suffix. Blog packages before 2026-08-05 retain the legacy English-only headings and are not rewritten. From 2026-08-10 through 2026-08-27, `Call to Action｜延伸閱讀` and `Disclaimer｜免責聲明` are mandatory in both Markdown and HTML. From 2026-08-28 onward, both sections are prohibited. Conclusion closes only through 2026-09-29; Risk closes from 2026-09-30. For historical packages requiring a conclusion, the exact heading is `Deep-Scan Conclusion｜深度掃描結論`; shortened or misspelled forms such as `深度掃結論` must fail.

### SEO and Sharing metadata

`## SEO and Sharing` is required and, from the 2026-10-05 revision onward, is the first block before the article title. The following placement instructions describe historical packages only. From 2026-08-10 through 2026-08-27 it must follow `Call to Action｜延伸閱讀` and `Disclaimer｜免責聲明`; from 2026-08-28 through 2026-09-29 it follows `Deep-Scan Conclusion｜深度掃描結論`, and from 2026-09-30 through 2026-10-04 it follows Risk, and include the current issue's `詳細文章：https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD`, `Page title：` matching the article title, `Page description：` summarising APL Momentum Leaders and the issue theme, and one concise sharing summary. This metadata must never be copied into the independent publish-ready HTML article source.

### HTML source delivery rule

Production delivers one complete HTML source plus the required public-preview HTML source and member SQL supplement:

```text
APL_Momentum_Leaders_Market_Analysis_Blog_<ScanDate>.html.txt
```

The UTF-8 `.html.txt` file contains the publish-ready HTML source verbatim, including visible literal `<h3>`, `<p>` and `<span>` tags. An `<h1>` title is allowed only in historical packages before 2026-10-13. Production must not also create a same-date `.html` copy. The publishing operator copies the source from `.html.txt` into the target publishing system; a local browser-renderable duplicate is unnecessary and is treated as a duplicate artifact.

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

Each section performs one reasoning task and builds on preceding evidence; transitions need not be questions. The diagram preserves historical roles only: Overview through 2026-09-07 and Conclusion through 2026-09-29. New drafts use the opening eight-section table. Do not restart the market background in each section or repeat the same conclusion without adding evidence or analytical progress.

```text
Executive Summary｜執行摘要
↓
Market Context｜市場背景
→ What is the largest structural market change?

Why APL Momentum Leaders Matter｜為什麼要看領導股？
→ What company differences does the broad index hide?

Deep-Scan Overview｜深度掃描概覽
→ Does the quantitative result show that market leadership still exists?

Top Gainers — 1 Day｜單日升幅榜
→ Which business directions show single-day price strength?

Momentum Leaders Analysis｜動能領導股分析
→ Which companies show sustained relative strength with supporting business evidence?

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

This standard governs new editorial preparation and human／agent review. Source, date, section and Markdown／HTML equivalence gates remain in force; length and paragraph gates follow the applicable ScanDate policy, including the 2026-11-12 revision. It does not claim that the current validator can certify narrative quality. Published articles remain unchanged.

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

Executive Summary 給出判斷與讀者意義；Market Context 解釋來源證據及傳導機制，不能重播摘要。Why APL Momentum Leaders Matter 要把本期疑問連接至相對強度研究能看見與不能證明的事情，不是每期照抄產品介紹。Overview 只屬 2026-09-07 或以前的歷史章節。Top Gainers 與 Momentum Leaders 對照短期價格領先與中期持續性，不能把不同來源股票池當成同一母體。Sector Analysis 檢查個股是否形成來源支持的板塊群組。

Investment Implication 排出本期關注優先次序及業務差異，不硬套 AI／資安／能源故事或重播財報。Risk 解釋最重要風險及傳導方式，末句收束開場判斷。獨立 Conclusion 只適用 2026-09-29 或以前。

2026-11-11 或以前按當時有效的篇幅門檻；2026-11-12 起按本文件開首新門檻。所有日期每段都須增加證據、解釋、比較或判斷。不可用固定連接詞、相同結論或無來源細節湊足字數。

### 公開引流與會員內容

另行要求公開引流稿時，以一個有吸引力的問題、少量有用見解、清楚研究價值及自然閱讀邀請組成。可以保留完整 watchlist，但公開內容仍要讓讀者得到實質理解。免費閱讀、會員權益及期限必須符合使用者已確認的當前安排。AI Electricity 只是當期主題例子，不能成為未來文章的預設主線。

WhatsApp 以「市場事件 → APL 觀點 → 應觀察什麼 → 閱讀引導」形成自然手機文章；不照抄固定宣傳段落，不強制每步顯示標籤。此規則不恢復正式 Blog 已移除的 CTA／Disclaimer，2026-09-30 起 Blog 以 Risk 結束，2026-10-05 起 Markdown 的 SEO and Sharing 放最上。

### 兩次審稿、兩個明確判定

先做事實審稿：來源、日期、公司身份、分母、推論界線、Markdown／HTML 對等。再做讀者審稿：開場是否具體、因果是否連貫、解釋是否有用、是否重複、結尾是否回答開場。把文章連續讀一次，暫時忽略標題，檢查是否仍像一篇文章。

在現有 editorial review evidence 記錄具體段落、發現及修正，分別寫明事實與讀者品質判定。機械 preflight PASS、字數或關鍵字不能替代讀者審稿。無來源聲稱、把舊論點偽裝成新變化、資料堆砌等實質問題必須先修訂才可 editorial approval。這是人工／agent 審稿要求；Review 僅排除已知機械缺陷，不能把語意審稿虛報為 machine-enforced PASS。

## 2. Executive Summary

The Executive Summary should state the most important market observation directly and must not begin with methodology.

The following expanded opening applies only from 2026-08-30 through 2026-11-11, subject to the 2026-09-30 revision replacing repetitive verification with client significance. From 2026-11-12 use three paragraphs and the opening 180-character floor. Historical coverage was:

1. the issue-specific market change and the opening conclusion;
2. why that change matters and how it is affecting capital allocation, rotation or leadership; and
3. the next observable confirmation or invalidation signal the reader should watch.

For 2026-08-30 through 2026-11-11 only, the floor is 300 substantive characters with two causal links. Later customer-report revisions override repetitive watchpoints; from 2026-11-12 no fixed importance／capital-flow／watchpoint keyword trio is required. Repetition, generic filler and copying Market Context do not satisfy this requirement.

---

## 3. Market Context

Market Context must explain the market environment before introducing the APL framework.

Market Context is the Blog's market-reasoning section. From 2026-08-30 through 2026-11-11 its floor is three paragraphs and 420 substantive characters. From 2026-11-12 use at least two paragraphs (normally two to three) and 240 substantive characters: explain the relevant event and its demand, cost or valuation effects, without a mandatory future-verification paragraph. Earlier packages retain their date-governed policy.

It must state the issue's largest structural market change and establish the core market proposition that the following sections test.

Market Context does not reproduce every source item. It selects the managed facts that best support the issue's core proposition and turns them into the shortest complete, continuous market argument needed to:

1. state the structural market change;
2. explain how it affects capital cost, valuation or capital flow;
3. support the proposition with the most representative managed facts; and
4. lead naturally to why APL Momentum Leaders 領導股 must be examined.

Editorial completeness is determined by whether this reasoning is complete, not by source-item coverage or source order. For 2026-08-30 through 2026-11-11 the historical three-paragraph and minimum-character gates guard against summary shells; from 2026-11-12 revised floors apply; they never authorize repetition or unmanaged facts.

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

Executive Summary remains distinct from Market Context and must not replace it. It states the conclusion and reader significance while Market Context supplies causal evidence and transmission; its length follows the ScanDate policy.

Trigger B data, ranking results, sector counts and Top Gainers — 1 Day results must not be presented as if they were source Market Context. Those inputs belong in their own Blog sections and may only be related back to the market background through editorial analysis.

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
- pasting Top Gainers rows as a punctuation-heavy CSV-like sentence, using unbalanced brackets, or omitting the separate canonical scope paragraph `Scope: SPX／NDX／DJI constituents.`; the longer point-in-time warning is historical only before 2026-09-30;
- writing Momentum Leaders or Sector Analysis as a single semicolon-delimited row list instead of at least two prose paragraphs that interpret company／business-model evidence and then advance the argument;
- omitting `Call to Action｜延伸閱讀` or `Disclaimer｜免責聲明` from either Markdown or HTML for packages dated 2026-08-10 through 2026-08-27, or including either removed section for packages dated 2026-08-28 or later;
- using any conclusion heading other than the exact `Deep-Scan Conclusion｜深度掃描結論` for historical packages through 2026-09-29 that require a conclusion; from 2026-09-30 no separate Conclusion is allowed.

### Natural editorial quality gate (effective 2026-08-10)

Machine-readable evidence must be translated into reader-facing analysis before publication. Numeric provenance remains mandatory, but raw field labels belong only to manifests, logs and audits.

- For historical packages through 2026-09-07 only, `Deep-Scan Overview` may state the current counts and averages in natural Chinese, but it must explain what they mean for leadership concentration. It must never print internal property names.
- `Market Context` must contain at least two analytical prose paragraphs and at least two explicit causal links such as `因此`, `反映`, `意味`, `導致` or `這代表`. Source headlines are evidence, not the article structure.
- Historical floors from 2026-08-30 through 2026-11-11: Executive Summary has at least three paragraphs and 300 substantive characters; Market Context at least three paragraphs and 420 substantive characters. The 2026-09-30 revision removes repetitive verification narration. From 2026-11-12 the opening table replaces these lengths and fixed rhetorical-keyword layers.
- `Top Gainers` must use a small number of selected examples in balanced sentences, followed by the canonical scope note as its own paragraph. The point-in-time warning is historical only before 2026-09-30. It must not serialize the input rows into one sentence.
- `Momentum Leaders Analysis` and `Sector Analysis` must each contain at least two natural prose paragraphs. No paragraph may use more than three semicolons to simulate a table or CSV row list.
- For ScanDate 2026-08-10 through 2026-08-27, Markdown and HTML must contain content-equivalent CTA and disclaimer sections. From 2026-08-28 onward neither section may appear. Conclusion closes only through 2026-09-29; Risk closes from 2026-09-30.
- `SEO and Sharing` remains Markdown-only and must be the first block before the article title from the 2026-10-05 revision onward. Earlier packages retain their historical placement. It must not appear in HTML.

`tools/validate_managed_inputs.ps1` must fail closed on every condition above before Atomic Production starts. Character count, presence of headings and source-number matches are insufficient to override this gate.

Final Audit must compare normalized paragraph blocks across all date-governed mandatory sections (nine through 2026-08-29; ten from 2026-08-30 through 2026-09-07; nine from 2026-09-08 through 2026-09-29; eight from 2026-09-30), record any repeated long block, and fail closed when repeated material is not accompanied by a distinct section conclusion. A PASS requires each section to add new evidence, interpretation or a falsifiable next question. This guard applies to Markdown, HTML, WhatsApp, Company Business Analysis and Table Card semantic inputs; structured fields must remain concise and role-specific rather than carrying Blog prose.

### Market Context hierarchy

The Blog's main `Market Context` section remains Markdown H2 and HTML `<h3>`. Subsections are optional. When used:

- Market Context subsections use Markdown H3;
- the corresponding HTML subsections use `<h4>`;
- the final Markdown and HTML use the same subsection order and analytical content.

No other Blog section may use arbitrary `<h4>` headings.

Interpret relevant news through demand, cost, valuation and company leadership; do not infer measured capital flows from ranking alone.

---

## 4. 為什麼要看 APL Momentum Leaders 領導股？

Explain why the current question benefits from comparing company relative strength; do not repeat a generic product introduction.

It must continue directly from Market Context: explain company differences hidden by a broad index. Do not claim a measured capital shift without direct evidence.

APL Momentum Leaders supplies relative-strength evidence. The report recommends research attention only after business research; it does not prescribe personalized trades or guarantee returns.

It is a quantitative research framework for observing:

- market leadership structure;
- concentration within the ranked sample;
- sector rotation;
- emerging themes.

The purpose is not to predict the next rising stock.

The purpose is to understand where market leadership is forming.

---

## 5. Deep-Scan Overview — historical through 2026-09-07 only

Do not generate this section for later dates or move its internal figures into other customer prose. The following describes the historical section only.

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

## 6. Top Gainers — 1 Day

Use Top Gainers — 1 Day to explain short-term market temperature among the approved SPX／NDX／DJI constituent universe.

It must contrast short-term price leadership with the medium-term Momentum Leaders structure, then lead into which companies show sustained relative strength. Rankings alone do not measure capital flows. Do not describe it as an independent market story.

`Top Gainers — 1 Day` remains the fixed canonical English title for the TopGainers Table Card. For Blog packages from 2026-08-05 onward, the Blog heading uses the bilingual presentation form `Top Gainers — 1 Day｜單日升幅榜`; legacy Blog packages before that date retain the English-only heading.

```html
<h3>Top Gainers — 1 Day｜單日升幅榜</h3>
```

Do not append any other theme, commentary or date to this heading. Put issue-specific interpretation in the following `<p>` paragraph instead.

It should help compare:

```text
short-term price strength
vs
medium-term leadership structure
```

Required current scope note:

```text
Scope: SPX／NDX／DJI constituents.
```

The longer point-in-time warning applies only before 2026-09-30. Do not append it to current customer prose.

Top Gainers must not be treated as stock recommendations.

---

## 7. Momentum Leaders Analysis

This section explains what the APL Momentum Leaders 領導股 structure reveals.

Explain which companies show sustained relative strength, the source-supported business evidence and why the selected companies deserve priority over alternatives. Then assess whether their strength forms an industry group. Capital-inflow claims require separate direct evidence.

It should focus on:

- leadership quality;
- sector concentration;
- business themes;
- business implications of relative strength;
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
→ supported relative-strength comparison
→ market implication
```

If structured data needs a visual treatment, generate a separate Blog Table Card artifact. Do not embed or reference that artifact inside the Blog Markdown file.

---

## 9. Investment Implication

From **2026-08-30** onward, `Investment Implication｜投資啟示` is a mandatory client-facing analysis layer immediately after `Sector Analysis｜板塊結構分析` and before `Risk｜風險`. It must answer: **所以投資者而家應該點理解呢個環境？** It is an interpretation of the preceding evidence, not a repetition of Market Context and not personalized investment advice.

The five-paragraph／650-character policy below applies only to 2026-08-30 through 2026-11-11, subject to the 2026-09-30 revision removing repetitive verification. From 2026-11-12 use two to three paragraphs and 180 substantive characters; explain priority and comparison without replaying results. Historical coverage was:

1. how investors should interpret the current market regime and what selection standard has changed;
2. which primary capital-expenditure, demand or leadership direction has the strongest economic support;
3. whether a secondary beneficiary curve or broader sector expansion is emerging;
4. how current `APL Momentum Leaders` cross-sector evidence and market breadth support or challenge that interpretation;
5. how macro costs, valuation, cash flow and balance-sheet quality affect resilience, followed by the next confirmation or invalidation signal.

For current drafts, turn the completed analysis into an order of attention and compare primary and secondary choices. Reuse only evidence needed for that comparison; do not repeat financial figures or ask readers to wait for demand to become revenue, earnings or cash flow. Broad-market claims need evidence beyond the selected Top 30 sample.

`APL Momentum Leaders` must be connected explicitly and naturally: the framework is used to observe where relative strength, demand, earnings expectations and catalysts are improving together across sectors. Do not assume in advance that the next leader must come from a particular industry, and do not turn the section into a stock list.

The final paragraph must state the current research posture in plain language, such as selective participation rather than indiscriminate chasing, and then lead into the specific Risk mechanism without requiring another future-verification paragraph. Direct buy／sell instructions, target prices, stop losses, personalized allocation commands and certainty claims are prohibited.

Fail closed when the section is missing, violates applicable date-governed paragraph／character requirements, lacks the natural `APL Momentum Leaders` link, copies Market Context, or contains direct trading instructions. Five paragraphs and fixed investor／capital-flow／fundamental／forward-risk keyword layers apply only through 2026-11-11; the priority-and-comparison contract applies from 2026-11-12.

---

## 10. Risk

Risk section is mandatory.

It must directly test conditions that could disprove the core proposition; unrelated generic risks are not sufficient. Its closing should lead to the final market judgment.

For historical packages from **2026-08-28 through 2026-09-29** only, Risk used at least three paragraphs. From 2026-09-30 use one to two paragraphs with a final sentence closing the research judgment. Historical coverage was:

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

## 11. Deep-Scan Conclusion — historical through 2026-09-29 only

Do not generate this section from 2026-09-30; Risk supplies the final judgment. The following rules document historical packages only.

The conclusion should summarize the market state and identify what deserves continued observation.

It must answer the Market Context question that opened the article, integrate only prior evidence and identify the next confirmation signal. Do not introduce a new argument.

For historical managed Blog packages from **2026-08-28 through 2026-09-29**, Deep-Scan Conclusion must contain at least three natural prose paragraphs. It must:

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
- Blog heading: `Top Gainers — 1 Day｜單日升幅榜` from 2026-08-05 onward;
- Table Card title: `Top Gainers — 1 Day` (exact English, immutable).

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
- CTA and disclaimer only for historical packages through 2026-08-27;
- publishing metadata.

Except for the same-date SEO PNG hyperlink in the top Markdown-only SEO metadata block (2026-10-06 revision onward), it must not embed or reference any image, including:

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

Cover, Dashboard, Table Cards, SEO image and other required visuals must continue to be generated as independent artifacts in the same-date Production Package. Each visual remains subject to its own validation, no-overwrite guard, artifact tracking, byte size, SHA-256 trace and publication requirements. Only the SEO PNG may be linked in the Markdown SEO metadata; no visual may be embedded or referenced in the article body or HTML source.

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

`ExecutiveSummary` has three to five issue-specific observations and implications, including the current market background and selection significance. From 2026-09-30 internal universe／qualified／Leader Lock／average-score metrics are prohibited on this card; Dashboard retains its own quantitative contract. Earlier allowances are historical only.

For new managed packages, every `ExecutiveSummary` `observation` must be reader-facing Chinese prose, not an English-only label or a raw machine metric dump. When figures are used, the sentence must connect the numbers to a market implication (for example, concentration, breadth or difficulty of entry). The paired `meaning` field explains the implication in Chinese. The instruction to define `Leader Lock` or `Buyability` applies only before 2026-09-30; these internal terms must not enter current customer prose. A row that only lists numbers, leaves the implication implicit, or uses unexplained English terminology fails the semantic gate. This rule is effective from 2026-08-05; the 2026-08-04 archived card remains immutable legacy output.

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
Article title              → Markdown H1 and Page title only; no HTML H1 from 2026-10-13
Every section subheading   → <h3>...</h3>
Every body paragraph       → <p>...</p>
Historical CTA/disclaimer → <h3> and <p> only through 2026-08-27
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
- complete HTML ends after the final Risk paragraph and shared-container closure; historical packages retain their date-governed ending. Do not append URL, Page title or Page description fields.

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
- give personalized buy／sell or allocation instructions, or promise returns; source-supported research priorities are required;
- predict stock prices;
- overload the article with data before explaining meaning.
- embed or reference any production image artifact inside the Blog Markdown manuscript, except the same-date SEO PNG hyperlink in the top SEO metadata block;
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
