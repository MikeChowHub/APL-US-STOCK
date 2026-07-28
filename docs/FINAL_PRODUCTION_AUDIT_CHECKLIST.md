# Final Production Audit Checklist

本 checklist 是 Archive gate。所有必要項目 PASS 後，runner 才可自動進入 Archive。

## Production output

### Editorial completion gate

- [ ] `APL_Editorial_Completion_Audit_<ScanDate>.json`為required publishing artifact，schema/date/status及四份editorial artifact SHA均PASS。
- [ ] Blog Markdown及HTML均包含十個mandatory sections，順序一致且每節有實質內容。
- [ ] Blog沒有placeholder、template instruction、英文test sentence、單段摘要殼或只有標題的section。
- [ ] Market Context提出清楚核心命題，以受管事實形成因果推理，並自然帶入APL Momentum Leaders；沒有被Executive Summary取代。
- [ ] Deep-Scan Overview數字與當次Trigger B metadata一致；Top Gainers section使用當次Top Gainers CSV證據。
- [ ] WhatsApp第一屏交代最大市場改變，並只保留移動閱讀所需證據；在分析後、disclaimer前包含與ScanDate完全相符的`詳細文章：https://www.goinvestingnow.com/blog/apl-momentum-leaders-YYYY-MM-DD`；Company Business Analysis涵蓋當次完整Top 30 symbols且不是空殼。
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
- [ ] 每張 required Table Card 的 input SHA 與 publication manifest 一致，並通過 `APL Table Card Input v1.1` semantic contract。
- [ ] Table Card required semantic fields 全部非空；header/display column 數與 renderer mapping 一致；score、percentage、sector/theme、direction及symbols沒有錯欄。
- [ ] `TopLeaders`逐列rank／symbol／company identity／Composite Score與當次Trigger B full ranking一致；不得以其他日期或人工選股替代。
- [ ] `TopGainers`逐列symbol／company identity／change percentage與當次TradingView Top Gainers CSV一致；重複的非Symbol header不影響核對。
- [ ] `SectorStructure`每個representative symbol均存在於當次Trigger B Top 30，沒有跨群組重複或虛構代表股。
- [ ] `ExecutiveSummary`包含3至5個當期最高優先觀察及其意義；沒有被固定Universe／Qualified／Leaders funnel佔據，亦沒有複製其他Table Card rows。
- [ ] Editorial Completion Audit為v1.1、`ProductionReadiness=true`，14個source roles的relative path／bytes／SHA-256完整且唯一，Table Card及native composition integrity checks全部PASS。
- [ ] Runner trace顯示`ManagedInputPreflight`在`ScoringRanking`之前PASS，並在其後完成`VerifyTriggerBEvidence`；正式run不可只依賴人工先行preflight。
- [ ] `production-package/APL_Production_Package_Manifest_<ScanDate>.json` schema/date/status PASS，required id/path集合完整且沒有重複。
- [ ] Package manifest file count、total bytes、逐檔relative path／size／SHA與實際package一致。
- [ ] 四張Table Card只在`production-package/Table Cards/`；Dashboard、Social、Cover、SEO及WhatsApp只在package，日期根目錄沒有重複。
- [ ] 已發布 machine artifacts 的 bytes 與 SHA-256 和 runner 記錄一致。
- [ ] 正式 Blog、HTML、Top 30 company analysis、publishing materials（若屬當次 Production scope）已置於日期輸出目錄。
- [ ] Market Context只有一個清楚的核心市場命題，並說明結構變化如何影響資金成本、估值或資金流。
- [ ] 正式內容只保留支持核心命題的主要證據；次要新聞可省略，相關事實可合併及重新排序。
- [ ] 內容具有因果關係而非新聞排列，沒有重複相同結論、為滿足字數擴寫或堆砌互不相關消息。
- [ ] Market Context在最少必要篇幅內完成推理，並自然帶入為何需要觀察APL Momentum Leaders領導股。
- [ ] Blog HTML 與 Markdown 的最終Market Context在subsection順序及分析內容上對等。
- [ ] HTML `<h3>` 只用於主 section；`<h4>` 只出現在 Market Context 的詳細 subsection。
- [ ] Executive Summary 仍為短版，且未取代詳細 Market Context。
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
- [ ] 最近7日 Top Gainers 與 Momentum Leaders 有清楚的短線／中期資金對照。
- [ ] Sector Analysis 由個股強勢推進至產業群組判斷。
- [ ] Relative Volume／Market Activity 實際參與確認或質疑核心命題，而非獨立描述成交量。
- [ ] Risk 直接提出可能推翻核心命題的條件；Deep-Scan Conclusion 回答文章開頭的市場問題，且沒有新增前文未出現的論點。
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
