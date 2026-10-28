# APL US Stock Trigger Rules

## 每日 TradingView → Trigger A → Trigger C — 2026-10-07 起

- 每日 Asia/Shanghai 下午 14:00，由本對話排程執行。
- 連接或開啟 `https://www.tradingview.com/screener/wQ6xGU5d/`，確認為 `APL Breakout Screener`，重新整理頁面。
- 開啟篩選器名稱選單，按 `Download results as CSV`，確認本次下載的當日 CSV。下載通知逾時時先檢查本次實際下載檔案，不能以舊檔代替。
- 複製至 `work/trigger-a-inputs/YYYY-MM-DD/`，確認來源與副本 SHA-256 一致；依 `docs/TRIGGER_A_EXECUTION_SPECIFICATION.md` 先 dry-run，PASS 後 write-output。
- 交付 `outputs/trigger-a/APL_Quant_Cumulative_Watchlist_YYYY-MM-DD.txt`，回報新增數、累積數及下載連結。登入、下載或驗證受阻時明確回報，不聲稱成功。
- Trigger A PASS 後，在 `work/macro-requests/` 建立唯一名稱 `Macro6-<GUID>.request`，由使用者電腦已設定的 Quick Macros File／Added 觸發器執行 Macro6，完成 TradingView 名單上傳步驟；檔案建立不代表上傳成功，仍須核對本次已驗證 TXT 與網站名單。確認匯入名單為 `APL_Quant_Cumulative_Watchlist_YYYY-MM-DD`，日期使用當天 Asia/Shanghai 日期，並核對股票集合與本次輸出一致；上傳失敗不得沿用舊名單繼續。
- 到 `https://www.tradingview.com/screener/TCDepfA0/`，確認為 `APL Breakout Screener Cumulative`；Macro6 執行完成後必須等待 60 秒（一分鐘），再重新載入整個累積榜網頁以更新 Watchlist 選單，然後才開啟選單確認及選擇當日名單。60 秒從巨集執行完成時計起，不從觸發檔建立時計起；若完成狀態不明，先核對本機操作或向使用者確認，不把建立觸發檔當作完成。不能只打開舊選單就判斷名單缺失。若登入失效則先完成登入。在 Filters 的 Watchlist 精確選擇剛匯入的當日 `APL_Quant_Cumulative_Watchlist_YYYY-MM-DD`（例如 2026-10-07 選 `APL_Quant_Cumulative_Watchlist_2026-10-07`）；日期每日隨當天更新，不得選無日期或前一天名單。有 OK 則確認，若選擇後自動關閉則確認篩選已生效；再 Refresh，Download results as CSV。以實際 UI 名稱為準，不把語音轉錄的「APL Content Common Native Watchlist」當成另一份名單。若匯入產生同名副本，須確認所選名單含本次股票；不能只憑名稱猜測。
- 到 `https://www.tradingview.com/screener/YMSPlCDy/`，確認為 `Top Gainers`，Refresh，再 Download results as CSV。
- 每日輸入應有三份真實下載 CSV：`APL Breakout Screener_YYYY-MM-DD*.csv`、`APL Breakout Screener Cumulative_YYYY-MM-DD*.csv`、`Top Gainers_YYYY-MM-DD*.csv`；TXT 另作上傳名單。保留原始下載檔，核對各自日期、欄位、內容及下載時間，複製到當日 managed intake 並驗證 SHA-256。三份未齊或累積名單未確認時，回報缺項，不標示整套完成。
- 三份 CSV 收齊後，唯讀檢查 `F:/GitHub/APL/Global Trending Topics/KnowledgeBase/Outputs`，依有效日期資料夾選取不晚於 ScanDate 的最新一期 `canonical.md`，作新聞熱話來源。記錄來源日期、路徑及 SHA-256，複製為 Deep-Scan 當日 intake 的版本化快照並核對雜湊；不修改新聞專案，不建立兄弟專案執行依賴。若最新一期非當日，內部證據及交付狀態明示來源日期；缺失或不明確則回報，不捏造。
- 本排程獲授權在當日 Cumulative CSV、Top Gainers CSV 及新聞快照齊備後執行 Trigger C，取代舊有每日流程只執行 Trigger A 的限制。Trigger A 本身的累積模式及禁止評分規則維持；必要 Trigger B 由 Trigger C 正式準備流程執行。
- 依現行 `prepare_trigger_c_managed_inputs.ps1` Initialize → 本期編輯及原生素材 → Finalize，完成 Managed Input Preflight、Atomic Production、Final Production Audit 及 Archive 全部驗證。只有 `DailyProductionComplete=true` 且 `DailyProductionPublishable=true` 才回報正式報告完成；每次交付前檢查已保存的交付參考圖並交齊發布素材連結，另附三份 CSV 及累積 TXT。
- 不交易、不對外發布。Git 僅依下列 Trigger A 跨電腦同步授權執行；文章、圖卡、每日輸入及其他修改不自動提交推送。同日重跑及衝突依現行工具保護處理；排程步驟失敗時保留已完成檔案，回報缺項，不聲稱整套完成。

## Trigger A 跨電腦 Git 同步 — 2026-10-29 修訂

使用者已明確授權：每次 Trigger A 執行前同步 Git 最新正式基準，驗證完成後立即提交及推送正式基準，讓其他電腦接續累積。此條取代舊有 Trigger A／每日排程一律禁止 Git 提交推送的說明；執行細節及衝突保護以 `docs/TRIGGER_A_EXECUTION_SPECIFICATION.md` 第 7 節為準。

- 每次先核對 Deep-Scan Git Root、目前分支、upstream 及 origin；成功 fetch 後才能判斷是否最新。遠端存取失敗時不得憑舊的 origin 快取聲稱同步完成，也不得用未同步的舊基準開始新累積。
- 其他電腦開始前必須取得已發布的最新 Git commit，核對正式名單及 manifest；不能只拿今天的 CSV 補一個月缺口。每日 CSV 並不保證包含中間曾出現的所有股票。
- `dry-run` → `write-output` → 正式基準／manifest／TXT 的日期、數量、位元組與 SHA-256 核對 PASS 後，僅提交 `Assets/ReferenceData/Watchlists/APL_Quant_Cumulative_Watchlist.txt` 與 `Assets/ReferenceData/Watchlists/watchlist-manifest.json`，並立即普通 push。相同內容已在遠端則不製造空 commit。
- Git 同步是執行代理必須完成的外層流程；`run_trigger_a.ps1` 本身仍只負責本機累積及驗證，不會自行連網或推送。手動執行該腳本後也必須補完本節同步才能回報跨電腦完成。
- 不提交 `work/`、`outputs/`、每日 CSV、Macro6 request、登入資料或其他未獲授權修改；不 force-push、不 reset、不自動 stash。兩邊分歧或推送被拒時保留兩邊資料，查明差異並保持全部既有股票，不能以日期較新為由覆蓋另一邊。
- 分開回報 `Trigger A 本機 PASS` 與 `Git 同步 PASS／待同步`；只有成功推送並重新 fetch 核對遠端 commit、名單及 manifest 後，才可回報跨電腦同步完成。同步失敗保留本機有效結果，明示具體阻礙及尚待上傳。

## 升幅統計時段 — 2026-10-06 修訂

出稿前核對 CSV 升幅欄位。現行來源 `Price change %, 1 day` 為單日數據，文章標題須為 `Top Gainers — 1 Day｜單日升幅榜`，圖卡標題須為 `Top Gainers — 1 Day`；正文、百分比標籤及 WhatsApp 必須同樣採單日口徑。不得把觀察名單、匯出日期或累積掃描期間當成升幅計算期間。若來源改為七日數據，必須先同步更新欄位驗證與標題合約，再生產，不能用單日數值寫成七日升幅。此規則取代舊有固定七日標題；已封存原件保留，10月2日及5日另交付更正版。


This document defines the trigger system for APL US Stock production.

The purpose is to prevent incorrect production flows, especially accidental full Blog production from a single Screener CSV.

## CSV Input Routing Authority

Codex attachment recognition and the canonical User Input → Production Action Mapping are defined in:

```text
APL_US_Stock_CSV_Input_Trigger_Rule.md
```

When an uploaded CSV unambiguously matches that Rule, Codex must enter the mapped Trigger automatically instead of asking a generic question about how to process the CSV. This changes routing behavior only; all processing boundaries below remain authoritative.

## Highest Priority Rule

```text
Any Screener CSV alone must not trigger full Blog production.
```

## Trigger A｜Watchlist Update Mode

### Trigger

```text
APL Breakout Screener_YYYY-MM-DD.csv
APL Breakout Screener_YYYY-MM-DD_*.csv
```

### Purpose

Trigger A updates the cumulative TradingView Watchlist by adding newly discovered symbols.

It is a collection process, not a quality-cleaning or research process.

### Flow

```text
APL Breakout Screener
↓
Read Symbols
↓
Merge with Previous Watchlist
↓
Remove Duplicate Symbols
↓
Output Updated Cumulative Watchlist
```

### Allowed Output

```text
outputs/trigger-a/APL_Quant_Cumulative_Watchlist_YYYY-MM-DD.txt
```

### Intake and execution order

If the uploaded daily CSV is outside the repository, first copy it to the managed intake path `work/trigger-a-inputs/YYYY-MM-DD/` and verify source／copy SHA-256 equality. Production scripts must reject direct `Downloads` or other external paths. Validate the CSV with the robust parser, run `tools/run_trigger_a.ps1` in `dry-run` mode, and only after PASS run it in `write-output` mode. Trigger A must not create `outputs/YYYY-MM-DD/`; that namespace belongs only to complete atomic Production.

### Forbidden Actions

Trigger A must not run:

```text
SMA200 Removal
Composite Score
Scoring
Ranking
Top 30
Dashboard
Social Card
Company Analysis
Formal Blog
Cover
SEO Image
Table Cards
WhatsApp
Publishing Materials
```

## Trigger B｜Deep-Scan Research Mode

### Trigger

```text
APL Breakout Screener Cumulative_YYYY-MM-DD.csv
APL Breakout Screener Cumulative_YYYY-MM-DD_*.csv
```

### Purpose

Trigger B re-evaluates the cumulative research universe, calculates scores, generates rankings, and produces Deep-Scan research outputs.

### Flow

```text
APL Breakout Screener Cumulative
↓
Re-evaluate Full Universe
↓
Apply Watchlist Cleaning Rules
↓
Score Calculation
↓
Composite Ranking
↓
Top 30
↓
Research Outputs
↓
Dashboard
↓
Social Card
```

### Allowed Outputs

```text
Standalone namespace: outputs/trigger-b/YYYY-MM-DD/
Composite Score
Full Ranking CSV
Top 30 TXT / Markdown
Cumulative TradingView Watchlist
APL Momentum Leaders Overview
Company Business Analysis
Dashboard SVG / PNG
Social Card SVG / PNG
Social Radar SVG / PNG (complete Top 30 radar format)
Research Outputs
```

`outputs/YYYY-MM-DD/` is reserved for the complete atomic Daily Production package. Standalone Trigger B must never create or occupy that Final Production namespace. The internal Trigger B step used by `run_daily_production.ps1` continues to write only to its orchestrator-owned staging root before atomic publish.

### Forbidden Actions

Trigger B must not create the formal Blog publishing package by itself.

Forbidden:

```text
Formal Blog
Cover
SEO Image
Blog Table Cards
WhatsApp Publishing Post
Final Publishing Materials
```

## Trigger C｜APL Momentum Leaders Blog Production Mode

### Trigger Condition

Trigger C requires all of the following:

```text
APL Breakout Screener Cumulative
+
Top Gainers — 1 Day
+
Market Context
```

### Purpose

Trigger C produces the formal APL Momentum Leaders 領導股 publishing package.

Trigger C must execute editorial preparation after Trigger B results exist and before Managed Input Preflight. It must not emit the Blog Template skeleton, placeholder text, a one-section summary or an English test sentence as a formal artifact. The current Trigger B metadata／ranking, Top Gainers CSV and detailed Market Context are mandatory editorial evidence.

`tools/prepare_trigger_c_managed_inputs.ps1` is the Cross-PC executable preparation entry. `Initialize` accepts the three approved intake files, runs Trigger B in isolated staging and emits a source-bound work order without placeholders. Codex completes the issue-specific editorial and two-image native work inside that staging root. `Finalize` verifies the original hashes, runs Managed Input Preflight against staging and atomically publishes `work/managed-inputs/<ScanDate>/` only after PASS. Direct manual construction of the final managed-input directory is not the normal workflow.

If a source correction is required before Finalize, `Supersede` is the only replacement path: it validates the new input contract before preserving the matching old builder staging directory under the controlled rejected namespace, then creates a new hash-bound staging bundle. It must never edit a source already listed in SourceEvidence, overwrite a finalized managed bundle or delete the previous staging evidence.

Only a PASS `APL Editorial Completion Audit v1.1` with `ProductionReadiness=true` may enter the Production runner. The runner must execute the managed-input preflight itself before scoring; a separately executed preflight is useful operator feedback but is not authority to bypass the runner gate. `DailyProductionComplete=true` without `DailyProductionPublishable=true` is not a completed Trigger C production.

The v1.1 readiness evidence must bind the current cumulative screener, Trigger B metadata and full ranking, Top Gainers CSV, Market Context, all four Table Card semantic inputs, Cover Brief, the two distinct native backgrounds and both native composition records by path, byte size and SHA-256. Top Leaders rows must match the current Trigger B ranking in order, symbol, company identity and score; Top Gainers rows must match the current approved SPX／NDX／DJI constituent input in order, symbol, company identity and price change; and every Sector Structure representative must exist in the current Trigger B Top 30. Schema-only validation is insufficient.

### Allowed Outputs

```text
Formal Blog editorial manuscript (.md, text-only, no image references)
Publish-ready Blog HTML source (`.html.txt`, visible literal tags, article content only, no publishing metadata footer)
Cover (independent artifact)
SEO Image (independent artifact)
Table Cards (independent artifacts)
WhatsApp
Social Publishing Materials
Social Card PNG (mobile-first single-message visual)
Social Radar PNG (complete Top 30 radar visual, converted from its SVG)
Archive Package
```

Both Social artifacts are required in every Trigger C Production Package. They are separate renderer outputs: `APL_DeepScan_Social_Card_<ScanDate>_1080x1350.png` carries the concise mobile-first message, while `APL_DeepScan_Social_Radar_Top30_<ScanDate>_1080x1350.png` carries the complete Top 30 radar view. The Radar must be rendered from its own SVG and validated as a fresh 1080x1350 PNG; it must never replace, crop, or be derived from the Social Card.

The `.md` manuscript, independent `.html.txt` source and visual artifacts share the same-date Production Package but remain separate outputs. Production must not create an additional `.html` duplicate. Visual artifacts must never be embedded or referenced inside either text file. HTML article subheadings use `<h3>` and HTML article paragraphs use `<p>`. URL, Page title and Page description metadata must not be appended to the HTML source.

The Markdown manuscript must conclude with `## SEO and Sharing`, including the issue URL, Page title, Page description and a sharing summary. WhatsApp must include the same issue URL after its analysis and before its disclaimer. The required operator-delivery artifact is the raw-code `.html.txt` source; it replaces the former `.html` artifact and must display literal angle-bracket tags directly.

## Input Alone Rules

```text
Top Gainers alone must not trigger scoring, Watchlist update, Dashboard, Blog, or Social package.

Market Context alone must not trigger scoring, Watchlist update, Dashboard, Blog, or Social package.
```


### Trigger A 根目錄交付及日期檔名 — 2026-10-07

交付檔名為 `APL_Quant_Cumulative_Watchlist_YYYY-MM-DD.txt`，以檔名顯示日期；最新檔直接放在 `outputs/trigger-a/`；舊日期資料夾放入 `outputs/trigger-a/Archive/YYYY-MM-DD/`。歷史帶日期檔及其追溯記錄保留；最新交付與 TradingView 上傳均使用根目錄的當日日期檔。
