# Final Production Audit Checklist

本 checklist 是 Archive gate。所有必要項目 PASS 後，runner 才可自動進入 Archive。

## Production output

- [ ] Project Root 與 Git Root 一致。
- [ ] `outputs/YYYY-MM-DD/` 已正式發布，沒有以 staging path 充當正式輸出。
- [ ] 所有 runner required artifacts 存在且非空。
- [ ] Ranking、Top 30、watchlist、SMA200 audits 與 metadata 數量一致。
- [ ] Dashboard、Social、Table Cards、Cover、SEO 的 required render/validation steps PASS。
- [ ] Table Card publication manifest（適用時）為 PASS。
- [ ] 每張 required Table Card 的 input SHA 與 publication manifest 一致，並通過 `APL Table Card Input v1.1` semantic contract。
- [ ] Table Card required semantic fields 全部非空；header/display column 數與 renderer mapping 一致；score、percentage、sector/theme、direction及symbols沒有錯欄。
- [ ] `production-package/APL_Production_Package_Manifest_<ScanDate>.json` schema/date/status PASS，required id/path集合完整且沒有重複。
- [ ] Package manifest file count、total bytes、逐檔relative path／size／SHA與實際package一致。
- [ ] 四張Table Card只在`production-package/Table Cards/`；Dashboard、Social、Cover、SEO及WhatsApp只在package，日期根目錄沒有重複。
- [ ] 已發布 machine artifacts 的 bytes 與 SHA-256 和 runner 記錄一致。
- [ ] 正式 Blog、HTML、Top 30 company analysis、publishing materials（若屬當次 Production scope）已置於日期輸出目錄。
- [ ] Blog Markdown 的 Market Context 在適用時保留 approved input 的小標題順序。
- [ ] Blog Markdown 的 Market Context 保留所有主要市場論點；「避免 news dump」不得被用作過度壓縮理由。
- [ ] Blog HTML 與 Markdown 的 Market Context 在小標題順序及主要論點上內容對等。
- [ ] HTML `<h3>` 只用於主 section；`<h4>` 只出現在 Market Context 的詳細 subsection。
- [ ] Executive Summary 仍為短版，且未取代詳細 Market Context。
- [ ] WhatsApp 可獨立摘要，不要求逐段與 Blog Market Context 對等。
- [ ] Trigger B 數據、ranking、sector counts 及 Top Gainers 結果沒有冒充或混入原始 Market Context。
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
