# APL US Stock Trigger Rules

This document defines the trigger system for APL US Stock production.

The purpose is to prevent incorrect production flows, especially accidental full Blog production from a single Screener CSV.

## Highest Priority Rule

```text
Any Screener CSV alone must not trigger full Blog production.
```

## Trigger A｜Watchlist Update Mode

### Trigger

```text
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
APL_Quant_Cumulative_Watchlist_YYYY-MM-DD.txt
```

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
Composite Score
Full Ranking CSV
Top 30 TXT / Markdown
Cumulative TradingView Watchlist
APL Momentum Leaders Overview
Company Business Analysis
Dashboard SVG / PNG
Social Card SVG / PNG
Research Outputs
```

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
最近7日 Top Gainers
+
Market Context
```

### Purpose

Trigger C produces the formal APL Momentum Leaders 領導股 publishing package.

### Allowed Outputs

```text
Formal Blog
Cover
SEO Image
Table Cards
WhatsApp
Social Publishing Materials
Archive Package
```

## Input Alone Rules

```text
Top Gainers alone must not trigger scoring, Watchlist update, Dashboard, Blog, or Social package.

Market Context alone must not trigger scoring, Watchlist update, Dashboard, Blog, or Social package.
```
