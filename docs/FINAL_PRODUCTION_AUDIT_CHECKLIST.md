# Final Production Audit Checklist

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
- [ ] 自 2026-08-03 起，Blog Markdown `#` 與 HTML `<h1>` 均以固定身份前綴 `APL Deep-Scan 美股深海雷達` 開始，且其後接當期核心市場結論。
- [ ] Market Context提出清楚核心命題，以受管事實形成因果推理，並自然帶入APL Momentum Leaders；沒有被Executive Summary取代。
- [ ] Deep-Scan Overview數字與當次Trigger B metadata一致；Top Gainers section使用當次Top Gainers CSV證據。
- [ ] Deep-Scan Overview只使用自然讀者語言；不得顯示`universe`、`qualified`、`leaderLock`、`removedBelowSma200Count`、`finalWatchlistCount`、`averageMomentum`、`averageBuyability`、`Trigger B`或其他Production內部欄位名稱。
- [ ] Market Context至少包含兩段因果分析；Top Gainers括號平衡、使用少量例子並以獨立canonical scope paragraph結尾；Momentum Leaders及Sector Analysis各至少兩段，沒有分號串接的CSV／pseudo-table內容。
- [ ] 自 2026-08-30 起，Executive Summary 至少300個實質字符／三段／兩個因果連結；Market Context 至少420個實質字符／三段／三個因果連結。兩者都清楚涵蓋為何重要、資金如何流動及下一個觀察訊號，且沒有以重複文字湊長度。
- [ ] 自 2026-08-30 起，Investment Implication 至少650個實質字符及五個自然段落，回答投資者應如何理解當前環境，涵蓋主要經濟方向、次級受益／板塊擴散、資金與市場廣度、APL Momentum Leaders連結、宏觀／估值／現金流約束及下一個確認或反證訊號。
- [ ] CTA／Disclaimer policy matches ScanDate: required for 2026-08-10 through 2026-08-27 and prohibited from 2026-08-28 onward.
- [ ] WhatsApp第一屏交代最大市場改變，並只保留移動閱讀所需證據；新日期按「標題／文章 URL → 市場事件 → APL 觀點 → 投資者關注與風險 → CTA／disclaimer」的自然敘事順序，包含與ScanDate完全相符的文章 URL及研究 disclaimer；Company Business Analysis涵蓋當次完整Top 30 symbols且不是空殼。2026-08-04 legacy Archive不回寫。
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
- [ ] 每張 required Table Card 的 input SHA 與 publication manifest 一致，並通過 `APL Table Card Input v1.1` semantic contract。
- [ ] Table Card required semantic fields 全部非空；header/display column 數與 renderer mapping 一致；score、percentage、sector/theme、direction及symbols沒有錯欄。
- [ ] `TopLeaders`逐列rank／symbol／company identity／Composite Score與當次Trigger B full ranking一致；不得以其他日期或人工選股替代。
- [ ] `TopGainers`逐列symbol／company identity／change percentage與當次SPX／NDX／DJI成分股 Top Gainers CSV一致；重複的非Symbol header不影響核對。
- [ ] `SectorStructure`每個representative symbol均存在於當次Trigger B Top 30，沒有跨群組重複或虛構代表股。
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
- [ ] Destination 為 `Archive/YYYY/YYYY-MM-DD/`。
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
