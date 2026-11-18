# APL Momentum Leaders Blog Template

適用 **ScanDate 2026-11-12 起**的 Trigger C 起稿。長期權威為 [Blog Rules](../Rules/APL_US_Stock_Blog_Rules.md) 的「2026-11-12 製作與閱讀品質合約」。本檔是私有編輯模板，方括號內指示必須改成本期有證據的內容，不能交付模板、範例句或佔位文字。

舊版完整保存於 [2026-11-12 前模板快照](../../docs/history/templates/Blog_Template.before-2026-11-12.md)，僅供舊日期相容查閱。新稿與跨電腦製作不載入該快照、歷史輸出或對話記憶作執行依賴；既有發布與 Archive 原件保持不變。

## 起稿順序

1. 以 Initialize 綁定本期 Cumulative CSV、Top Gainers CSV、新聞快照及經驗證的 Trigger B 排名。讀取原始 `Industry` 欄，按公司業務作有證據的歸類；補查未知公司，保留原欄及分類依據於內部。
2. 寫下一個本期核心判斷，選少量重點公司。每個首選都要有排名證據、具體業務證據，以及優先於另一類候選的理由。來源缺口先補研究或收窄主張，不交由讀者核對。
3. 可取得時唯讀比較最近三期標題、摘要、投資啟示及風險收束，記錄新證據或延續；無可比檔案便在現有編輯記錄說明限制，不硬湊新故事。
4. 先完成公司證據、八節 Markdown 和 Top 30 公司分析；先事實審稿，再連續閱讀作讀者審稿。在現有 editorial review evidence 記錄發現、修正與判定，不新增必填打勾表。
5. 使用 `tools/prepare_trigger_c_managed_inputs.ps1 -Mode Review` 檢查來源雜湊、重複長段／長句及公司段落。Review 不依賴 HTML／圖片，也不改動狀態；`DRAFT_READER_CHECKS_PASS` 是機械檢查結果，`MechanicalOnly=true`、`FullPreflightStillRequired=true`，不能當成正式完成。
6. 從定稿製作 WhatsApp、圖卡和原生背景。執行工作單的 `FinalizeCommand` 從 Markdown 產生完整 HTML 並預檢，再用同日的 `ProduceCommand` 生產、製作公開預覽及歸檔；各交付件依同一正文及來源核對。

## 八節各自回答的問題

| 章節 | 對讀者的唯一工作 | 篇幅與界線 |
| --- | --- | --- |
| Executive Summary | 直接給出本期判斷、首選及關注意義 | 三段，正文至少 180 實質字符；不報掃描／通過數、平均分或內部流程。 |
| Market Context | 用少量相關事件解釋本期需求、成本或估值變化 | 至少兩段，通常兩至三段；至少 240 實質字符；不用新聞清單或重播摘要。 |
| Why APL Momentum Leaders Matter | 交代本期為何要比較相對強度與個別公司 | 簡短連接當期問題；不複製產品介紹。 |
| Top Gainers — 1 Day | 交代單日價格領先，與動能領導比較 | 選有解釋力例子；不把單日升幅寫成七日回報或確定買點。 |
| Momentum Leaders Analysis | 說明選哪家公司，以及為何選它 | 至少兩段；每個首選有排名、具體業務證據及選擇理由。 |
| Sector Analysis | 檢查個股是否形成有業務關係的群組 | 至少兩段；以原始 Industry 和公司業務為依據，客戶稿不寫 Others 或工具分類侷限。 |
| Investment Implication | 排出關注優先次序、比較不同機會 | 兩至三段，至少 180 實質字符；自然連接 APL Momentum Leaders，不重播財報、背景或逐股清單。 |
| Risk | 說清最重要風險如何影響本期判斷 | 一至兩段；末句收束本期方向及公司差異，不另加 Conclusion 或通用免責段。 |

字符與段數是防止空殼的底線，不是寫作目標。每段新增一項證據、解釋或比較；不得為湊字數增加同義句、無來源細節或反覆等待收入／盈利驗證。肯定陳述已核實事實和有根據的研究判斷；不保證回報，不把排名當資金淨流入，也不把短期強勢當成確定買點。

## Markdown 起稿骨架

以下為文章的固定順序。第一塊必須是 SEO and Sharing；將日期、標題、描述、圖片路徑及所有正文替換為本期內容。SEO 圖只作 metadata 的可點擊連結，文章正文不嵌圖。Page title 與 Markdown H1 的完整字串相同。

```markdown
## SEO and Sharing

Page title：APL Deep-Scan｜美股深海雷達: [本期有證據的研究判斷] | YYYY-MM-DD

Page description：[核心市場背景、主選公司與研究價值]

Sharing summary：[一句說清本期最值得閱讀的發現]

Canonical URL：https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD

SEO 圖：[SEO 圖](<本期正式 SEO PNG 的絕對路徑>)

# APL Deep-Scan｜美股深海雷達: [本期有證據的研究判斷] | YYYY-MM-DD

## Executive Summary｜執行摘要

[第一段：直接提出本期主選或核心判斷，連接最相關的市場背景。]

[第二段：首選公司、業務方向及選它的原因。]

[第三段：讀者應如何理解這次選擇，以及與其它領導股的差別。]

## Market Context｜市場背景

[第一段：已核實事件與最直接的需求、成本或估值傳導。]

[第二段：另一項相關證據、反差或限制如何形成這一期的選股環境。需要時才加第三段。]

## Why APL Momentum Leaders Matter｜為什麼要看領導股？

[連接本期問題與公司相對強度的用途，補充指數無法顯示的差異。]

## Top Gainers — 1 Day｜單日升幅榜

[有選擇地解釋單日榜公司的價格表現，與後文動能領導作比較。]

<sup><small>Scope: SPX／NDX／DJI constituents.</small></sup>

## Momentum Leaders Analysis｜動能領導股分析

[首選：正式排名、具體業務證據、相對另一類公司的選擇理由。]

[第二方向或具解釋力的對照：新增證據與業務差異；不照抄首選段落。]

## Sector Analysis｜板塊結構分析

[由原始 Industry 和公司業務判讀領導群組。]

[比較不同群組的需求來源與影響因素；樣本分布不冒充全市場資金流。]

## Investment Implication｜投資啟示

[第一段：明確本期優先關注哪個方向，並解釋此排序如何承接 APL Momentum Leaders 的證據。]

[第二段：區分下一順位機會及不應混為一談的業務模式；需要時才加第三段。]

## Risk｜風險

[最具體、最能影響本期選擇的風險及傳導機制。一至兩段，末句收束本期研究判斷。]
```

## HTML 與公開預覽

- 完整 HTML 檔名為 `APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.html.txt`。它與 Markdown 的八節正文、數字及判斷對等，使用實際 HTML 標籤、不加 Markdown fence；不另產生同名 `.html`。
- 定稿只編輯 Markdown。用工作單的 `FinalizeCommand` 重新產生暫存中的完整 HTML，正文由 Executive Summary 開始。章節標題、段落和市場背景子標題以空行分隔；公開預覽由正式生產從已核對的完整 HTML 產生。
- 完整 HTML 和公開預覽共用 `tools/client_article_html.ps1`：透明、置中、最大寬 800px；正文 18px、行距 1.95、段距 23px；H3 25px、章節前距 34px、下距 23px。
- 容器內第一個內容標題是 `<h3>Executive Summary｜執行摘要</h3>`，禁止 H1、SEO metadata、日期導言、獨立 Conclusion、CTA／Disclaimer 章節及正文圖像。完整正文以 Risk 結束。
- 摘要首段使用深色重點框；金色只標該段一項核心判斷。每家公司首次出現的 ticker 加粗一次，依當期 Top 30 和單日榜前五公司辨識；其它文字保持淺色，不把所有股票代碼染金。
- 公開預覽保留完整摘要、Market Context 標題與首段，以及第二段第一句／分句後加 ASCII `...`；不把數字小數點當截斷點、不拆 HTML tags/entities。關閉樣式容器後以唯一 `<div id="apl-member-content"></div>` 結尾。
- 客戶正文不附新聞／公司來源超連結、URL、註腳、Sources 清單或孤立引用標籤。來源 URL、日期、期間、雜湊與查核留在內部；正文可正常標明已核實的日期、季度、「盤中／一度」。禁止「非即時報價」「請自行核對」等編輯免責句。

## WhatsApp 與會員 SQL

WhatsApp 第一行固定為 `🌊APL Deep-Scan 美股深海雷達`，空一行後接自然分析。用不同句子濃縮本期背景、APL 判斷、主選理由和具體風險，不複製全篇或掃描數字。保留簡短研究免責及當期閱讀邀請，再以以下兩組 CTA 結尾，之後不加內容：

```text
📖 今日完整研究：
https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD

🐧 APL 三日免費體驗｜工具・分析・課程
https://www.goinvestingnow.com/ExploreCourses
```

會員 `.article.sql` 仍用 Blog Rules 既定手動貼上模板：兩個 slug 均來自同日文章 URL 最後一段，`required_product='deepscan'`，content **恰為** `'<p>PASTE'`。這個標記僅用於 SQL 模板，不可混入文章；不可嵌入全文或自動執行資料庫操作。

## 審稿、製作與交付

事實審稿核對資料時段、公司身份、排名、Industry、業務主張、數字方向／基期／單位及 Markdown／HTML 對等。例如月增率由 0.6% 降至 0.4% 是漲幅放慢，不能寫成通脹加速；月增率仍為正也不等於物價下跌。讀者審稿要連續讀全文，確認開頭有答案、每節增加資訊、主選理由具體、投資啟示不重複財報、風險沒有推翻前文。兩次判定與修改位置記在現有編輯證據。機械閘門只能排除已知缺陷，不能證明文章自然好讀。

完成流程維持：Managed Input Preflight → Atomic Production → Final Production Audit PASS → Archive V2 Copy/integrity → Archive index verification → final Archive manifest PASS。只有權威完成與可發布狀態均通過，才可宣稱整套完成。

每次交付前查看 `Assets/Delivery/deep-scan-delivery-reference.png`；依以下三組提供每項獨立、可點擊絕對路徑連結：

1. Table Cards：Executive Summary → Deep-Scan Dashboard → Top Gainers → Top Leaders → Sector Structure。
2. 正式圖像：Social Card → Social 完整 Radar → Cover → SEO。
3. 文章及發布文件：今日文章 Markdown → HTML 原始碼 TXT → WhatsApp → Top 30 公司分析 → 公開預覽 HTML 原始碼 → 會員文章 SQL。

Executive Summary 圖卡必須包含當期市場背景重點及主選意義，與文章同一判斷。其內容、渲染、來源綁定及完整素材要求依現行 Visual Rules，不把文字摘要當作完成整套圖像。
