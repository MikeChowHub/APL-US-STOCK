# APL US Stock Visual Rules

This document defines the visual philosophy and role boundaries for all APL US Stock production assets.

Visual Rules answer:

- what each visual type is for;
- when it should be used;
- what it must contain;
- what it must not become;
- how it relates to other visual types.

Exact dimensions, layout grids, and export details belong in Templates, not in this Rules document.

---

## 1. Visual Philosophy

APL visual assets are not interchangeable.

Each asset has a specific job in the production system:

| Visual Type | Core Role |
|---|---|
| Blog Cover | Market story |
| SEO Image | Search / share thumbnail |
| Dashboard | Research UI |
| Social Card | Mobile-first summary |
| Table Card | Research information card |
| Charts | Data explanation |

The same article may require multiple visual assets, but each asset must serve its own role.

Do not reuse one visual type as another if doing so weakens the reader experience.

---

## 2. Blog Cover

### Purpose

Create a strong first impression for the formal Blog article.

The cover should help the reader understand the current market story before reading the article.

### Role

```text
Narrative Cinematic Financial Cover
```

### When to Use

Use for the main Blog cover and article hero image.

### Required Elements

Every Blog Cover must be built from:

- market story;
- market conclusion;
- capital flow;
- risk background;
- sector rotation;
- leadership destination;
- one dominant visual metaphor;
- cinematic market environment;
- APL / Deep-Scan identity through local overlay.

The correct production method is:

```text
AI-generated cinematic background
+
local-rendered Chinese text overlay
```

ChatGPT / ImageGen is responsible for the cinematic background.

Codex / local post-production is responsible only for accurate text, logo, spacing, date, and final export.

For a complete Trigger C input set, Codex must first derive one shared scene concept from the approved market narrative, then invoke the image generation workflow twice: a native 4:5 Cover view and a native 16:9 SEO view. Both no-text sources are saved within the Project Root with separate native records. It must not require the user to design or manufacture the normal production backgrounds. The local renderer remains the only authority for final title, date and logo composition.

### Prohibited Elements

Blog Cover must not become:

- Dashboard layout;
- radar-only background;
- generic finance poster;
- text-only cover;
- local SVG / shape-based illustration as final cover;
- abstract flow-line infographic;
- floating dashboard widgets;
- sector information card layout;
- presentation-slide composition;
- CSV or table visualization.

### Relationship with Other Visual Types

Blog Cover is not a Dashboard, not a Social Card, and not a Table Card.

Dashboard explains the data.

Table Card explains a specific observation.

Social Card summarizes for mobile.

Blog Cover sells the market story visually.

---

## 3. SEO Image

### Purpose

Support search, link previews, and social sharing.

### Role

```text
Search / Share Thumbnail
```

### When to Use

Use for Blog SEO, Open Graph, and share preview images.

### Required Elements

SEO Image must:

- preserve the same market story as the Blog Cover;
- remain readable at thumbnail size;
- simplify the metaphor if needed;
- keep text short and high contrast;
- work as a standalone share asset.
- use a native 16:9 view of the same scene concept as the Cover;
- use a wider or more distant field of view with lateral environmental context;
- reserve a landscape-specific title and logo safe area.

### Prohibited Elements

SEO Image must not:

- be a weak crop of the 4:5 Blog Cover;
- use Dashboard layout;
- overload text;
- include dense data;
- become a table, radar UI, or social card clone.
- be produced by cropping, resizing or re-encoding the Cover source.

### Relationship with Other Visual Types

SEO Image must share the Blog Cover scene concept, subject identity, primary scene elements, palette, lighting direction, cinematic mood, brand atmosphere and art style. It must use an independently generated camera distance／framing and a different native source file. Cover remains the concentrated 4:5 portrait view; SEO is the expanded 16:9 landscape view.

---

## 4. Dashboard

### Purpose

Provide a structured research interface for APL Momentum Leaders 領導股 data.

### Role

```text
Research UI
```

### When to Use

Use for Deep-Scan ranking, radar visualization, sector distribution, market scan summary, and systematic research display.

### Required Elements

Dashboard must include:

- fixed research UI layout;
- clear hierarchy;
- repeatable data mapping;
- consistent visual system;
- readable quantitative outputs;
- APL Deep-Scan brand identity.

### Prohibited Elements

Dashboard must not be used as:

- Blog Cover;
- cinematic market story;
- emotional poster;
- article hero replacement.

### Relationship with Other Visual Types

Dashboard is the research terminal.

It supports the article, but it must not replace the Blog Cover or Blog information cards.

---

## 5. Social Card

### Purpose

Deliver the daily / weekly Deep-Scan message in a mobile-first format.

### Role

```text
Mobile-first Summary
```

### When to Use

Use for Instagram, Facebook, Threads, Discord, WhatsApp preview, and other social platforms.

### Required Elements

Social Card must prioritize:

- mobile readability;
- concise headline;
- key metrics;
- simple hierarchy;
- strong brand recognition;
- minimal but meaningful data.

### Prohibited Elements

Social Card must not:

- simply shrink the Dashboard;
- include too much text;
- include dense tables;
- replace Blog information cards;
- overload the reader with all research outputs.

### Relationship with Other Visual Types

Social Card summarizes.

It does not replace the Blog, Dashboard, or Table Cards.

---

## 6. Table Card

### Purpose

Turn article tables and structured observations into reader-friendly visual insight cards.

### Role

```text
Blog Research Information Card
```

### When to Use

Use inside the Blog when tabular information would otherwise interrupt reading flow.

### Required Elements

Table Card must:

- prioritize observation and meaning;
- use only necessary data;
- use fewer columns;
- provide large row spacing;
- make the conclusion visible quickly;
- support the article argument.

### Prohibited Elements

Table Card must not become:

- CSV screenshot;
- large empty table;
- radar background;
- dense spreadsheet;
- full ranking export;
- decorative table with no market meaning.

### Relationship with Other Visual Types

Table Card supports the Blog publishing experience as an independent same-date Production Package artifact. It must not be embedded or referenced inside `APL_Momentum_Leaders_Market_Analysis_Blog_YYYY-MM-DD.md`.

It is not a Dashboard, not a full research export, and not a cover.

---

## 7. Charts

### Purpose

Explain numeric relationships visually.

### Role

```text
Visual data explanation
```

### When to Use

Use when a chart makes a relationship easier to understand than prose.

### Required Elements

Charts must:

- have clear labels;
- use accurate scale;
- reflect the source data;
- support the article argument;
- avoid unsupported conclusions.

### Prohibited Elements

Charts must not be used as:

- decorative background;
- misleading evidence;
- unsupported visual claim;
- filler image.

---

## 8. Brand Consistency

All APL US Stock visuals must retain an institutional Deep-Scan identity.

Core visual language:

- Deep Navy;
- Cyan;
- Gold;
- clean typography;
- institutional research feel;
- APL Deep-Scan identity.

Green and red should only be used for meaningful signals:

- capital rotation;
- risk;
- sector signal;
- positive / negative market state.

Do not use green or red as random decoration.

---

## 9. Visual Source of Truth

Visual Rules define purpose and boundaries.

Visual Templates define execution structure.

Renderers and scripts implement the rules but must not become rule sources.

`outputs/`, `Archive/`, and one-off image files are not visual rule sources.
