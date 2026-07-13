# APL US Stock Research Template

This template defines the standard structure for Deep-Scan Research Mode outputs.

It is used after Trigger B:

```text
APL Breakout Screener Cumulative
↓
Deep-Scan Research Mode
```

## Research Output Structure

```text
Overview
Ranking Summary
Top 30
Sector Distribution
Company Analysis
Research Notes
```

## 1. Overview

Purpose:

Summarize the current Deep-Scan research result.

Variable content:

```text
Date
Universe size
Qualified stocks
Momentum Leaders count
Leader Lock count
Top sector
Market theme
```

## 2. Ranking Summary

Purpose:

Summarize how the current ranking was produced.

Must reference:

```text
Composite Score
Momentum Score
Buyability Score
Relative Volume Bonus
Eligibility Rule
```

## 3. Top 30

Purpose:

Present current APL Momentum Leaders 領導股 ranked output.

Required fields may include:

```text
Rank
Symbol
Name
Composite Score
Momentum Score
Buyability
Relative Volume Bonus
Price / 52W
Perf 6M %
Perf 3M %
Rel Vol
```

## 4. Sector Distribution

Purpose:

Explain which sectors dominate the current Momentum Leaders structure.

## 5. Company Analysis

Purpose:

Explain company type, business role, supply chain position, core business, growth driver, key risk, and beta classification.

## 6. Research Notes

Purpose:

Record production notes, rule version, and any pending implementation gaps.
