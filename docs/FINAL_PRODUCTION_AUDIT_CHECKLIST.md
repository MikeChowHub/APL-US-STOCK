# Final Production Audit Checklist


## Reader-first editorial review（新起稿自 2026-09-05）

## Public preview and member SQL delivery check

- [ ] Full HTML remains equivalent to Markdown article content.
- [ ] Preview retains h1, Executive Summary, Market Context first paragraph and only the second paragraph's first clause.
- [ ] Cutoff excludes decimal points; clause ends in ... followed by </p>.
- [ ] Preview ends with exactly <div id="apl-member-content"></div>; later member content is absent.
- [ ] SQL slug in SELECT and WHERE equals the final path segment of the 詳細文章 URL.
- [ ] required_product is deepscan; SQL template content is exactly <p>PASTE (manual insertion), not full HTML, preview HTML or an empty string. Actual article content remains complete and placeholder-free.
- [ ] SQL is a delivery file only; no database execution is inferred.
- [ ] Supplements to an existing publication are outside immutable outputs/Archive and are not presented as already archived.
- [ ] Rule-level delivery review is distinguished from runner/Archive contract enforcement of the new files.


### 2026-09-08 起優先檢查（下方Overview項目只適用歷史日期）

- [ ] 九節分析，不含獨立Deep-Scan Overview或改名數字摘要；Dashboard及四張Table Cards不變。
- [ ] 標題第二句提供具體發現，開頭有當期差異或有證據延續；對照最近三期標題／開場／結論並記錄日期，缺失不虛報。
- [ ] 新入榜以最近可比正式Top30核對，只選有研究意義公司；沒有公開退出名單、保證升跌或排名高等於買點好的暗示。
- [ ] 每節有獨立推理功能，數字有用途，沒有重複背景、分號清單或無來源資金淨流入聲稱。
- [ ] 客戶文章、WhatsApp、公開圖表及publishing package沒有內部累計名單／次數／門檻、候選排期或5／10日績效。
- [ ] 內部保留全部歷史及失敗個案；累計4個不同日期只列候選，單次編輯排期最多一間或零間，查已有／製作中稿件，不自動批量起稿。
- [ ] Markdown／HTML內容對等，Conclusion收尾、SEO僅在Markdown；人工品質判定與機械gate分開記錄。

2026-08-30至2026-09-07為十節；2026-09-08起為九節，歷史成品不回寫。

以下為人工／agent 審稿項目，不代表新增自動檢查。於現有 review evidence 記錄段落、發現及修正；機械 preflight PASS 不等於本項 PASS。

- [ ] 開場由當期具體證據或矛盾切入，清楚說明讀者意義，沒有只換詞重用「本期最大的市場／結構變化」。
- [ ] 可取得時已比較最近三期的開場、命題、投資啟示與結論，記錄日期及新證據／判斷改變／明確延續；歷史缺失已披露，未虛構比較或新增 Cross-PC 依賴。
- [ ] 事實、推論及情境清楚；相對強度未被當作機構買入或實測資金流，基本面聲稱均有來源。
- [ ] 數字有用途及合適期間／分母；Top 30 選樣未被推廣為全市場廣度或資金集中度，不同來源股票池未被混為同一母體。
- [ ] 公司例子解釋業務意義且來源充足；術語已解釋，沒有把資料列直接貼成文章。
- [ ] 每節新增推理，承接自然，沒有每節強制反問、產品介紹重播、可互換段落或湊字數內容。
- [ ] Investment Implication 回答當期環境如何理解，Risk 解釋相關失效機制，Conclusion 回答開場並列出可觀察訊號，沒有新增未支持論點。
- [ ] 已連續閱讀全文；繁體中文清楚、句式有節奏、無固定範文循環或未確認宣傳承諾。
- [ ] 修訂後 Markdown／HTML source 對等，正式 Blog 仍以 Conclusion 結束，SEO 僅留 Markdown，沒有重加 CTA／Disclaimer。
- [ ] 事實及讀者品質各有明確審稿判定；實質缺陷已修正，沒有以字數或關鍵字 PASS 代替。

## Blog heading language gate

- [ ] For ScanDate 2026-08-05 through 2026-08-29, all nine major Blog headings use `English｜short Chinese gloss` in both Markdown and HTML in the established fixed order. From 2026-08-30 onward, `Investment Implication｜投資啟示` is inserted immediately after `Sector Analysis｜板塊結構分析` and before `Risk｜風險`, making ten mandatory analysis headings.
- [ ] The bilingual `Top Gainers — Past 7 Days｜最近七日升幅榜` form is a Blog heading only; the TopGainers Table Card title remains exact English `Top Gainers — Past 7 Days`.
- [ ] For ScanDate 2026-08-10 and later, the exact conclusion heading is `Deep-Scan Conclusion｜深度掃描結論`; `深度掃結論` and other shortened forms FAIL.
- [ ] For ScanDate 2026-08-10 through 2026-08-27, Markdown and HTML contain CTA／Disclaimer; from 2026-08-28 onward, both are absent, Conclusion closes the article, and `SEO and Sharing` follows as the final Markdown-only section.
- [ ] Cover／SEO use exactly one renderer-owned identity kicker, `APL DEEP-SCAN | YYYY-MM-DD`; Cover Brief `overlay.subtitle` is an issue-specific description of the main title and contains no APL／Deep-Scan／Momentum Leaders／美股深海雷達 identity, scan date, or duplicated title line.
- [ ] Packages before 2026-08-05 retain their legacy English-only headings and are not rewritten.
- [ ] `SectorStructure.direction` contains a concise Chinese market-direction／capital-structure summary; English-only text fails the Table Card semantic gate. `representativeSymbols` remains the only symbol-list field.

本 checklist 是 Archive gate。所有必要項目 PASS 後，runner 才可自動進入 Archive。

## Production output

### Editorial completion gate

- [ ] `APL_Editorial_Completion_Audit_<ScanDate>.json`為required publishing artifact，schema/date/status及四份editorial artifact SHA均PASS。
- [ ] Blog Markdown及HTML均包含ScanDate規定的mandatory sections（至2026-08-29為九個；自2026-08-30起為十個），順序一致且每節有實質內容；Relative Volume / Market Activity 不再是必需 Blog section。
- [ ] Blog沒有placeholder、template instruction、英文test sentence、單段摘要殼或只有標題的section。
- [ ] 自 2026-09-02 起，Blog Markdown `#` 與 HTML `<h1>` 均以固定身份前綴 `APL Deep-Scan｜美股深海雷達` 開始，且其後接當期核心市場結論；已發布日期不回寫。
- [ ] Market Context提出清楚核心命題，以受管事實形成因果推理，並自然帶入APL Momentum Leaders；沒有被Executive Summary取代。
- [ ] Deep-Scan Overview數字與當次Trigger B metadata一致；Top Gainers section使用當次Top Gainers CSV證據。
- [ ] Deep-Scan Overview只使用自然讀者語言；不得顯示`universe`、`qualified`、`leaderLock`、`removedBelowSma200Count`、`finalWatchlistCount`、`averageMomentum`、`averageBuyability`、`Trigger B`或其他Production內部欄位名稱。
- [ ] Market Context至少包含兩段因果分析；Top Gainers括號平衡、使用少量例子並以獨立canonical scope paragraph結尾；Momentum Leaders及Sector Analysis各至少兩段，沒有分號串接的CSV／pseudo-table內容。
- [ ] 自 2026-08-30 起，Executive Summary 至少300個實質字符／三段／兩個因果連結；Market Context 至少420個實質字符／三段／三個因果連結。兩者都清楚涵蓋為何重要、資金如何流動及下一個觀察訊號，且沒有以重複文字湊長度。
- [ ] 自 2026-08-30 起，Investment Implication 至少650個實質字符及五個自然段落，回答投資者應如何理解當前環境，涵蓋主要經濟方向、次級受益／板塊擴散、資金與市場廣度、APL Momentum Leaders連結、宏觀／估值／現金流約束及下一個確認或反證訊號。
- [ ] CTA／Disclaimer policy matches ScanDate: required for 2026-08-10 through 2026-08-27 and prohibited from 2026-08-28 onward.
- [ ] WhatsApp第一屏交代最大市場改變，並只保留移動閱讀所需證據；按「市場事件 → APL 觀點 → 投資者關注與風險 → 當期閱讀引導」自然成文，包含與ScanDate完全相符的文章 URL及研究 disclaimer；自2026-09-25起連結只在固定頁腳，不要求開頭放 URL。Company Business Analysis涵蓋當次完整Top 30 symbols且不是空殼。既有 Archive 不回寫。
- [ ] 自2026-09-26起，WhatsApp上半部按當期事件自然成文，閱讀引導回答當期文章的具體問題；研究 disclaimer 在固定頁腳之前。最後只保留「📖 今日完整研究：」＋當日 `https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD` 純文字 URL、空行、「🐧 APL 三日免費體驗｜工具・分析・課程」＋固定 `https://www.goinvestingnow.com/ExploreCourses` 純文字 URL；只有文章日期可變，頁腳後無其他內容。2026-09-25 及更早正式 package／Archive 不回寫。
- [ ] ScanDate 2026-09-04 起，WhatsApp 與 Markdown `SEO and Sharing` 均使用 `https://www.goinvestingnow.com/blog/apl-deep-scan-YYYY-MM-DD`；沒有再生成舊 `apl-momentum-leaders-YYYY-MM-DD` slug。2026-09-03 及之前的正式歷史輸出不回寫。
- [ ] Final authoritative state同時為`DailyProductionComplete=true`及`DailyProductionPublishable=true`；任一為false即FAIL。

### Cover／SEO native composition

- [ ] Cover及SEO的native records引用相同且非空的`scene_concept_id`。
- [ ] Cover source為原生4:5，使用較近／中近距離、集中主體、直向張力及Cover標題／Logo安全區。
- [ ] SEO source為原生16:9，使用較遠／廣角視角、左右延展環境及SEO橫向標題／Logo安全區。
- [ ] 兩個records的`artifact_type`、`source_path`及SHA-256各自正確；source path及正式背景檔案互不相同。
- [ ] Cover與SEO的camera distance或framing不同，但核心市場命題、主體身份、主要場景元素、色調、光線方向、電影感、品牌氣氛及藝術風格一致。
- [ ] 兩個native records的dimensions及SHA-256與實際來源逐一吻合，`transformation=none`。
- [ ] SEO不是Cover的center crop、resize或re-encode；Cover亦不是由SEO衍生。
- [ ] 如兩張圖是相同來源、衍生版本或互不相關場景，Final Production Audit必須FAIL CLOSED。
- [ ] Cover及SEO overlay仍各自輸出1080x1350及1280x720，文字與Logo layout保持角色獨立。

- [ ] Project Root 與 Git Root 一致。
- [ ] `outputs/YYYY-MM-DD/` 已正式發布，沒有以 staging path 充當正式輸出。
- [ ] 所有 runner required artifacts 存在且非空。
- [ ] Ranking、Top 30、watchlist、SMA200 audits 與 metadata 數量一致。
- [ ] Dashboard、Social Card、Social Radar、Table Cards、Cover、SEO 的 required render/validation steps PASS；Social Radar保留完整Top 30、scan funnel、Buyability及sector distribution，Social Card保留單一命題的mobile-first訊息。
- [ ] Table Card publication manifest（適用時）為 PASS。
- [ ] 使用者向正式交付清單中的`Table Cards`組別按固定次序逐項列出並連結：`Executive Summary → Deep-Scan Dashboard → Top Gainers → Top Leaders → Sector Structure`；沒有以資料夾連結取代個別artifact，亦沒有把Top Leaders列在Top Gainers之前。
- [ ] Deep-Scan Dashboard只在上述人類閱讀次序中插入；其artifact仍在`production-package/`根目錄，沒有被誤分類或搬入`Table Cards/`。
- [ ] `正式圖像`按`Social Card → Social 完整 Radar → Cover → SEO`逐項列出；`文章及發布文件`按`今日文章 Markdown → HTML 原始碼 TXT → WhatsApp → Top 30 公司分析 → 公開預覽 HTML 原始碼 → 會員文章 SQL`逐項列出。
- [ ] 完整 HTML、公開預覽與會員 SQL 均在`production-package/`且各自只有一份；公開預覽只有一個空的`apl-member-content`邊界，SQL使用同日`apl-deep-scan-<ScanDate>`及精確`'<p>PASTE'`模板。
- [ ] 每張 required Table Card 的 input SHA 與 publication manifest 一致，並通過 `APL Table Card Input v1.1` semantic contract。
- [ ] Table Card required semantic fields 全部非空；header/display column 數與 renderer mapping 一致；score、percentage、sector/theme、direction及symbols沒有錯欄。
- [ ] `TopLeaders`逐列rank／symbol／company identity／Composite Score與當次Trigger B full ranking一致；不得以其他日期或人工選股替代。
- [ ] `TopLeaders.mainDriver`逐列提供與該公司業務相關的需求或營運檢驗變數，沒有把排名、分數或相對強勢換字重述，也沒有多家公司共用套話；無證據的催化不寫成已發生。
- [ ] `TopGainers`逐列symbol／company identity／change percentage與當次SPX／NDX／DJI成分股 Top Gainers CSV一致；重複的非Symbol header不影響核對。
- [ ] `SectorStructure`每個representative symbol均存在於當次Trigger B Top 30，沒有跨群組重複或虛構代表股。
- [ ] `SectorStructure.theme`為`tools/sector_map.json`正式sector；每個代表股映射至同一sector，且`count`等於當次Top 30中該sector的完整實際數量。泛稱或混合板塊必須FAIL。
- [ ] `ExecutiveSummary`包含3至5個當期最高優先觀察及其意義；沒有被固定Universe／Qualified／Leaders funnel佔據，亦沒有複製其他Table Card rows。
- [ ] 新日期 `ExecutiveSummary` 的 `observation`／`meaning` 均為中文讀者向文字；數字必須連接至市場含義，且 Leader Lock、Buyability 等術語已在 meaning 解釋。只有 raw metric dump、英文-only 或未解釋術語必須令 semantic gate FAIL；2026-08-04 legacy Archive 維持 immutable。
- [ ] Editorial Completion Audit為v1.1、`ProductionReadiness=true`，14個source roles的relative path／bytes／SHA-256完整且唯一，Table Card及native composition integrity checks全部PASS。
- [ ] Runner trace顯示`ManagedInputPreflight`在`ScoringRanking`之前PASS，並在其後完成`VerifyTriggerBEvidence`；正式run不可只依賴人工先行preflight。
- [ ] `production-package/APL_Production_Package_Manifest_<ScanDate>.json` schema/date/status PASS，required id/path集合完整且沒有重複。
- [ ] Package manifest file count、total bytes、逐檔relative path／size／SHA與實際package一致。
- [ ] 四張Table Card只在`production-package/Table Cards/`；Dashboard、Social Card、Social Radar、Cover、SEO及WhatsApp只在package，日期根目錄沒有重複。Social Card與Social Radar均為required，且各自只有一張1080×1350 PNG。
- [ ] 已發布 machine artifacts 的 bytes 與 SHA-256 和 runner 記錄一致。
- [ ] 正式 Blog、HTML、Top 30 company analysis、publishing materials（若屬當次 Production scope）已置於日期輸出目錄。
- [ ] Market Context只有一個清楚的核心市場命題，並說明結構變化如何影響資金成本、估值或資金流。
- [ ] 正式內容只保留支持核心命題的主要證據；次要新聞可省略，相關事實可合併及重新排序。
- [ ] 內容具有因果關係而非新聞排列，沒有重複相同結論、為滿足字數擴寫或堆砌互不相關消息。
- [ ] Market Context在最少必要篇幅內完成推理，並自然帶入為何需要觀察APL Momentum Leaders領導股。
- [ ] Blog HTML 與 Markdown 的最終Market Context在subsection順序及分析內容上對等。
- [ ] HTML `<h3>` 只用於主 section；`<h4>` 只出現在 Market Context 的詳細 subsection。
- [ ] 自 2026-08-30 起，Executive Summary 是至少三段的投資週報開場：交代核心變化與結論、為何重要及資金流向、後續觀察點；它仍不可取代 Market Context。
- [ ] WhatsApp 可獨立摘要，不要求逐段與 Blog Market Context 對等。
- [ ] Market Context沒有未受管事實、日期或數字；引用數據保持來源原意。
- [ ] Trigger B數據、ranking、sector counts及Top Gainers結果沒有冒充Market Context原始來源。
- [ ] Blog、WhatsApp、ExecutiveSummary Card、Social Card、Cover及SEO的核心市場命題方向一致；任何重複數字、公司身份及方向性判斷均沒有矛盾。
- [ ] Blog保留完整推理鏈；Markdown以`## SEO and Sharing`為最終metadata section，包含當期URL、Page title、Page description及sharing summary；HTML不得包含該metadata section。WhatsApp是簡潔文字分發訊息，不是Blog縮寫或Dashboard數字清單。
- [ ] Dashboard保留完整系統性scan context；Social Card只傳遞一個mobile-first主訊息及最少必要證據，不是縮小版Dashboard。
- [ ] Cover與SEO保持同一市場故事及視覺語言，但Cover使用較近4:5 Hero視角，SEO使用較遠16:9 search／share視角。
- [ ] 四張required Table Cards各自完成priority synthesis、medium-term leaders、short-term gainers及group structure職責；沒有重複同一批rows或結論而不增加不同意義。
- [ ] Company Business Analysis是完整Top 30公司／商業模式參考，不是另一篇市場評論，亦沒有只覆蓋Top 10後以一般文字填充。
- [ ] 沒有因source-integrity檢查而強迫所有平台重複scan funnel、完整ranking、sector counts或同一句結論。
- [ ] 全文有唯一、當期特定的核心市場命題；沒有預設固定股票、板塊或市場結論。
- [ ] 每個主要 section 只完成一個明確推理任務，並建立在上一節的結果之上。
- [ ] 沒有重複結論卻未新增證據、重新由零開始解釋市場背景，或可任意交換順序的獨立 section。
- [ ] 已對ScanDate規定的所有主要 sections（至2026-08-29為九個；自2026-08-30起為十個）做 normalized paragraph comparison；沒有同一個長段落／完整 Market Context source block 在三個或以上 section 重複，亦沒有以重複文字滿足長度或字符 gate。
- [ ] Executive Summary、Top Gainers、Momentum Leaders、Sector、Risk 及 Conclusion 都有自己的新推論；任何跨 section 重複句只可作短句承接，不可承載整段分析。
- [ ] Top Gainers — Past 7 Days 與 Momentum Leaders 有清楚的短線／中期資金對照。
- [ ] Sector Analysis 由個股強勢推進至產業群組判斷。
- [ ] 自 2026-08-30 起，Investment Implication 承接Sector Analysis而不是重講Market Context，明確連接APL Momentum Leaders，並以研究取態自然帶入Risk；缺少語義層、複製Market Context段落或出現直接買賣指示均FAIL。
- [ ] 如 Blog 選擇保留 Relative Volume／Market Activity，該段只能作補充證據，不得重新成為必需 section 或獨立市場評論。
- [ ] Risk 直接提出可能推翻核心命題的條件；Deep-Scan Conclusion 回答文章開頭的市場問題，且沒有新增前文未出現的論點。
- [ ] 自 2026-08-28 起，Risk 至少有三個自然段落，分別解釋當期反證條件、風險傳導機制及可觀察失效訊號；不是簡短清單、通用風險或重複 Market Context。
- [ ] 自 2026-08-28 起，Deep-Scan Conclusion 至少有三個自然段落，直接回答開頭問題、整合既有領導／板塊證據，並交代下一個確認或反證訊號；不是固定範文或為湊字數重複結論。
- [ ] 移除任一主要分析 section 會令推理鏈中斷，證明各 section 不可任意交換。
- [ ] Final audit 證據已寫入 `Final_Production_Audit_YYYY-MM-DD.json`，`Status=PASS`。

## Automatic Archive gate

- [ ] Archive 只在 Final Production Audit PASS 後啟動。
- [ ] Source 為 `outputs/YYYY-MM-DD/`。
- [ ] Destination 為 `Archive/YYYY/MM/YYYY-MM-DD/`。
- [ ] 使用 Copy；來源未 Move、Delete 或修改。
- [ ] 正式 Blog/HTML、Top 30 analysis、publishing materials、Dashboard、Social、Table Cards、Cover、SEO、manifest、必要 audit/logs 已納入。
- [ ] staging、temporary inputs、cache、diagnostics 及指定重複中間檔已排除。
- [ ] Copy 前後 relative path、file count、每檔 bytes、每檔 SHA-256 全部一致。
- [ ] `production-package/`及`Table Cards/`相對結構在Archive保持不變，package manifest本身亦按SHA原樣複製。
- [ ] `archive-manifest.json` 為 PASS。
- [ ] `Archive/index.md` 已更新。
- [ ] `tools/archive-v2-policy.json` schema、MarkerId、AdoptionDate及 legacy allowlist有效。
- [ ] 有 v2 manifest的日期在 index為 `PASS`，manifest／count／bytes一致。
- [ ] allowlisted pre-v2日期只標記 `LEGACY_UNVERIFIED`，Manifest為 `N/A`且 Notes明示 inventory不構成 integrity attestation。
- [ ] 未知 pre-v2日期或 adoption後日期缺／壞 manifest時 workflow FAIL。
- [ ] 沒有為 legacy日期補造 manifest、標記 PASS或改寫歷史檔案。

## Completion decision

只有下列完整序列成立時才勾選：

- [ ] `Production PASS → Archive Copy → SHA/size audit → Archive index update → Archive PASS → Daily Production Complete`

Git Commit／Push 不屬於此完成鏈，runner 不得自動執行。

## Answer-led headline editorial gate (effective 2026-09-06)

## Social Logo final-pass audit (2026-09-11)

- [ ] Social Card／完整 Radar 先完成圖表，再由共用 compositor 按最終像素尺寸疊加已核准原始 Logo。
- [ ] Logo 來源及 SHA 與品牌 manifest 相符；保持比例，不使用未核准的比較稿。
- [ ] 以最終 PNG 100% 尺寸檢查品牌文字、企鵝、雷達細線、透明邊緣；無拉伸、裁切、重影或明顯鋸齒。此項是獨立視覺檢查，不可由 PNG magic／尺寸檢查代替。
- [ ] 最終 artifact SHA 在 Logo 疊加完成後計算；Final Audit PASS 後才 Archive，Archive bytes／SHA 與完成圖一致。
- [ ] 發布後不再貼 Logo 或重存檔案；任何後續修改必須走受控重跑。

### Answer-led headline checks

- [ ] Blog／Page title／Cover／SEO 與當期證據的結論一致。
- [ ] 前半句交代事件，後半句提供具體發現、受惠機制或明確問題。
- [ ] 不含「領導結構待確認」「有待觀察」等空泛結尾。
- [ ] Executive Summary 回答標題承諾，正文解釋機制及來源。
- [ ] 不將相對強勢冒充資金淨流入、盈利兌現或未來股價保證。
- [ ] Risk 保留必要限定及反證條件。
- [ ] 人工／agent 語意審核獨立完成；machine PASS 不代表本項自動通過。
