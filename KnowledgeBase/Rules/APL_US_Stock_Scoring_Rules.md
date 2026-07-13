# APL US Stock Scoring Rules

Scoring Version: APL Scoring v1.0

This document defines the scoring system for APL Momentum Leaders 領導股.

The scoring system is used to identify market leadership, entry quality, and capital activity.

## Scoring Philosophy

APL Momentum Leaders 領導股 are primarily defined by Momentum.

Buyability and Relative Volume are supporting dimensions:

- Momentum Score answers: who is showing market leadership?
- Buyability Score answers: is the current position still reasonable?
- Relative Volume Bonus answers: is recent participation active?

Buyability must not replace Momentum.

Relative Volume must not dominate the ranking by itself.

## Momentum Score

### Purpose

```text
Measure market leadership strength.
```

Momentum Score reflects price momentum, relative strength, trend condition, and leadership characteristics.

### Current Momentum Score Weights

| Component | Weight |
|---|---:|
| Price / 52W High | 25% |
| Performance 6M | 20% |
| Performance 3M | 15% |
| Buyability | 15% |
| Price vs SMA50 | 10% |
| Price vs SMA200 | 10% |
| Relative Volume | 5% |

## Buyability Score

### Purpose

```text
Measure entry position quality.
```

Buyability evaluates whether a strong stock is still near a reasonable observation or entry zone.

Buyability should be used inside the Momentum Leaders universe, not as a replacement for Momentum.

## Relative Volume Bonus

### Purpose

Relative Volume Bonus measures capital activity and recent participation.

### Bonus Table

| Relative Volume | Raw Bonus |
|---:|---:|
| RV ≤ 1.1 | +0 |
| 1.1–1.5 | +3 |
| 1.5–2.0 | +6 |
| >2.0 | +10 |

### Cap Rule

```text
RV Bonus = min(RV Bonus, Buyability)
```

This prevents extreme relative volume from dominating the ranking when Buyability is weak.

## Composite Score

### Formula

```text
Composite Score =
Momentum Score
+ Buyability Score
+ Relative Volume Bonus
```

Where:

```text
Relative Volume Bonus = min(Raw RV Bonus, Buyability Score)
```

## Output Fields

Scoring outputs may include:

```text
Composite Score
Momentum Score
Buyability
Relative Volume Bonus
Price / 52W
Perf 6M %
Perf 3M %
Price vs SMA50 %
Price vs SMA200 %
Rel Vol
```

## Rule Versioning

Any future change to scoring weights, RV Bonus, Buyability mapping, or Composite Score formula must be treated as a scoring version change.
