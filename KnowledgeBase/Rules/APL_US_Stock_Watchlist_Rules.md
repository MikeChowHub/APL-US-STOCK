# APL US Stock Watchlist Rules

This document defines how the cumulative TradingView Watchlist is updated and cleaned.

The Watchlist is a long-term cumulative research asset. It must not be accidentally reduced by incomplete daily data.

## Core Principle

```text
Trigger A collects.
Trigger B cleans.
```

## Trigger A｜Daily Watchlist Accumulation

### Purpose

Trigger A adds new symbols from the daily APL Breakout Screener into the cumulative TradingView Watchlist.

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
Output Updated Watchlist
```

### Rules

```text
New symbols are added.
Existing symbols are preserved.
Duplicate symbols are removed.
The cumulative Watchlist is retained.
```

### Forbidden Actions

Trigger A must not perform:

```text
SMA200 Removal
Score Calculation
Composite Ranking
Top 30 Generation
Dashboard Production
Social Card Production
Blog Production
```

## Trigger B｜Cumulative Watchlist Cleaning

### Purpose

Trigger B re-evaluates the full cumulative universe using APL Breakout Screener Cumulative data.

This is the only mode where Watchlist cleaning is allowed.

### SMA200 Rule

```text
Price < SMA200
→ Remove from Watchlist
```

### Missing Data Rule

```text
Missing SMA200 data must never trigger removal.
```

### Reason

Cumulative Screener is the safer source for full-universe cleaning because it contains the broader cumulative research pool.

## Watchlist Sorting

After Trigger B scoring, the cumulative TradingView Watchlist should be sorted using the latest Composite Score.

Trigger A does not sort by Composite Score unless score data already exists and the user explicitly requests it.

## Implementation Status

The SMA200 removal rule is implemented in Trigger B processing.

Implementation behavior:

```text
If SMA200 is valid and Price < SMA200
→ Remove from Watchlist

If SMA200 is missing, zero, invalid, or unavailable
→ Keep in Watchlist
```

Trigger A remains accumulation-only and must not run SMA200 removal.
