# APL US Stock Ranking Rules

This document defines how APL Momentum Leaders 領導股 rankings are generated.

## Core Rule

```text
Top 30 uses Composite Score ranking.
Full Ranking uses Composite Score.
Deep-Scan Watchlist sorting uses latest Composite Score.
```

## Ranking Inputs

Ranking is based on:

```text
Momentum Score
Buyability Score
Relative Volume Bonus
Composite Score
```

## Eligibility Rule

APL Momentum Leaders candidates must satisfy:

```text
Composite Score > universe average Composite Score
```

Only stocks that pass this eligibility rule belong to the APL Momentum Leaders candidate universe.

## Top 30

Top 30 is generated from the eligible universe.

If more than 30 stocks are eligible, select the highest 30 by Composite Score.

If fewer than 30 stocks are eligible, output only the eligible stocks.

## Full Ranking

Full Ranking may preserve the complete evaluated universe.

Full Ranking should include both eligible and non-eligible symbols when needed for audit, research, or reproducibility.

## Sort Order

The formal tie-breaker is:

1. Composite Score, descending
2. Momentum Score, descending
3. Relative Volume, descending
4. Symbol, alphabetical ascending

Status:

```text
Rule defined, implementation validation pending.
```

Current renderer and scoring scripts have already been observed using the first three ranking keys. Symbol alphabetical tie-breaker requires implementation validation.

## Watchlist Sorting

After Trigger B scoring, the cumulative TradingView Watchlist should be sorted by latest Composite Score.

Trigger A does not re-score or re-sort by Composite Score unless score data is already available and explicitly requested.

## Research Output Disclaimer

```text
Top 30 is research output.
Not investment recommendation.
```

APL Momentum Leaders 領導股 is a market structure and leadership research framework, not a stock recommendation list.

## Ranking Stability

Ranking should be reproducible from the same input data and scoring rules.

If the scoring formula changes, the change should be treated as a scoring version change.
