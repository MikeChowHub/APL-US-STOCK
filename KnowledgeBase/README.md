# APL US Stock KnowledgeBase

This KnowledgeBase is the source of truth for the APL US Stock Production System.

It controls how APL Momentum Leaders 領導股 research, watchlists, rankings, Blogs, dashboards, social assets, and visual materials should be produced.

---

## 1. Source of Truth

KnowledgeBase is the only production rule source.

Scripts are implementation.

Scripts must follow KnowledgeBase, but scripts are not rule sources.

The following are not rule sources:

- `outputs/`
- `Archive/`
- `tmp/`
- one-off generated images
- historical Blog files
- prototype renderers
- old production notes

Examples are references only.

Archive is independent historical storage.

---

## 2. KnowledgeBase Hierarchy

Use this hierarchy:

```text
Rules
>
Decision Trees
>
Templates
>
Examples
```

Meaning:

- Rules define stable system logic.
- Decision Trees choose the correct production path.
- Templates define reusable output structure.
- Examples calibrate quality but do not override Rules.

---

## 3. Rules

Rules contain long-term production logic.

Current Rule files:

- `Rules/APL_US_Stock_Trigger_Rules.md`
- `Rules/APL_US_Stock_Watchlist_Rules.md`
- `Rules/APL_US_Stock_Scoring_Rules.md`
- `Rules/APL_US_Stock_Ranking_Rules.md`
- `Rules/APL_US_Stock_Blog_Rules.md`
- `Rules/APL_US_Stock_Visual_Rules.md`
- `Rules/APL_US_Stock_Production_Package_Rules.md`
- `Rules/APL_US_Stock_Native_Image_Contract_v2.md`
- `Rules/APL_US_Stock_Archive_Rules.md`
- `Rules/APL_US_Stock_Production_Artifact_Contract.json`

Rules should not contain daily market opinions, one-off stock rankings, or single-day article content.

---

## 4. Decision Trees

Decision Trees select the appropriate workflow or visual type before production begins.

Current Decision files:

- `Decision/APL_US_Stock_Visual_Decision_Tree.md`

Decision Trees reduce rule drift by preventing a visual, article, or output from being produced using the wrong template.

---

## 5. Templates

Templates define reusable output structures.

Current Template files:

- `Templates/Research_Template.md`
- `Templates/Blog_Template.md`
- `Templates/Dashboard_Render_Template.md`
- `Templates/Social_Card_Template.md`
- `Templates/Cover_Image_Prompt_Template.md`
- `Templates/Table_Card_Template.md`

Templates may define layout, sections, required fields, and production format.

Templates must not contain one-off market commentary or fixed daily stock lists.

---

## 6. Examples

Examples are not created in Phase 1 or Phase 2A.

Official Examples require at least five high-quality production cases before promotion.

Examples are calibration references, not source of truth.

---

## 7. Archive

Archive is not part of KnowledgeBase.

Archive lives independently at Project Root:

```text
Archive/
└── YYYY/
    └── YYYY-MM-DD/
        ├── data/
        ├── research/
        ├── blog/
        ├── visuals/
        ├── social/
        ├── metadata/
        └── index.md
```

Archive preserves historical production outputs.

Archive must not be treated as Rules, Templates, or Examples.

---

## 8. Production Boundary

When production behavior conflicts with KnowledgeBase:

```text
KnowledgeBase wins.
```

When a renderer or script contains hardcoded behavior not reflected in KnowledgeBase, it should be treated as implementation debt until refactored.

No production decision should be derived from outputs, old Markdown, screenshots, or historical assets unless it has been promoted into KnowledgeBase.
