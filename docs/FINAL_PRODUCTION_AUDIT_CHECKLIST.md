# Final Production Audit Checklist

本 checklist 是 Archive gate。所有必要項目 PASS 後，runner 才可自動進入 Archive。

## Production output

- [ ] Project Root 與 Git Root 一致。
- [ ] `outputs/YYYY-MM-DD/` 已正式發布，沒有以 staging path 充當正式輸出。
- [ ] 所有 runner required artifacts 存在且非空。
- [ ] Ranking、Top 30、watchlist、SMA200 audits 與 metadata 數量一致。
- [ ] Dashboard、Social、Table Cards、Cover、SEO 的 required render/validation steps PASS。
- [ ] Table Card publication manifest（適用時）為 PASS。
- [ ] 已發布 machine artifacts 的 bytes 與 SHA-256 和 runner 記錄一致。
- [ ] 正式 Blog、HTML、Top 30 company analysis、publishing materials（若屬當次 Production scope）已置於日期輸出目錄。
- [ ] Final audit 證據已寫入 `Final_Production_Audit_YYYY-MM-DD.json`，`Status=PASS`。

## Automatic Archive gate

- [ ] Archive 只在 Final Production Audit PASS 後啟動。
- [ ] Source 為 `outputs/YYYY-MM-DD/`。
- [ ] Destination 為 `Archive/YYYY/YYYY-MM-DD/`。
- [ ] 使用 Copy；來源未 Move、Delete 或修改。
- [ ] 正式 Blog/HTML、Top 30 analysis、publishing materials、Dashboard、Social、Table Cards、Cover、SEO、manifest、必要 audit/logs 已納入。
- [ ] staging、temporary inputs、cache、diagnostics 及指定重複中間檔已排除。
- [ ] Copy 前後 relative path、file count、每檔 bytes、每檔 SHA-256 全部一致。
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
