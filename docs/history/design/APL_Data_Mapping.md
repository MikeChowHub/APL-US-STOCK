# APL Data Mapping

> Version: v1.1  
> Purpose: 定義最新 APL Top30 CSV 如何映射到 Deep-Scan Dashboard。

## 1. CSV Source

Standard input:

```text
APL_Momentum_Score_Full_Ranking_[YYYY-MM-DD].csv
```

Render uses first 30 rows by `Rank`.

## 2. Required Fields

| Field | Required | Usage |
|---|---|---|
| `Rank` | Yes | Radar position |
| `Symbol` | Yes | Stock node ticker |
| `Name` | Optional | Metadata only |
| `Momentum Score` | Yes | Node size and score label |
| `Buyability Score` | Yes | Glow / Lock / Buyability bucket |
| `Buyability` | Optional | Human-readable rating |
| `Rel Vol` | Optional | Highest Rel Vol / average Rel Vol |
| `Perf 6M %` | Optional | Avg 6M performance |
| `Perf 3M %` | Optional | Avg 3M performance |
| `Sector` | Preferred | Sector color and distribution |

If `Sector` is missing, renderer must use approved fixed mapping from Top30 company/business analysis.

## 3. Current CSV Schema

Current latest CSV contains:

```text
Rank
Symbol
Name
Momentum Score
Buyability
Buyability Score
Price
Price / 52W
Price vs 20MA %
Perf 6M %
Perf 3M %
Price vs SMA50 %
Price vs SMA200 %
Rel Vol
```

Because current CSV does not include `Sector`, sector must be mapped externally.

## 4. Rank Mapping

Rank controls radar position only.

| Rank | Zone |
|---:|---|
| 1–5 | Core Zone |
| 6–15 | Watch Zone |
| 16–30 | Observation Zone |

No visual re-sorting by sector is allowed.

## 5. Momentum Mapping

Momentum Score controls:

- node diameter;
- displayed score;
- dashboard average.

Formula:

```text
finalDiameter = baseDiameter + ((MomentumScore - 56) / 34) × 18
```

Clamp by rank group:

```text
min = baseDiameter - 8
max = baseDiameter + 28
```

## 6. Buyability Mapping

`Buyability Score` controls:

- glow;
- inner ring;
- buyability label;
- Leader Lock.

| Score | Bucket | Glow | Lock |
|---:|---|---:|---|
| 8–10 | 5-star | 24px | Yes |
| 6–7 | 4-star | 18px | No |
| 4–5 | 3-star | 10px | No |
| 2–3 | 2-star | 5px | No |
| 0–1 | 1-star | 0px | No |

Leader Lock condition:

```text
Buyability Score >= 8
```

## 7. Sector Mapping

### Preferred

CSV should include:

```text
Sector
```

Allowed sector values:

- AI
- Semiconductor
- Healthcare
- Bio
- Networking
- Industrial
- Consumer
- Software
- Others

### Fallback Mapping

If CSV does not include Sector, use fixed mapping:

| Symbol | Sector |
|---|---|
| AGL | Healthcare |
| ATEX | Industrial |
| ORKA | Bio |
| MU | Semiconductor |
| SNDK | Semiconductor |
| MTRN | Industrial |
| APPS | Software |
| AIP | Semiconductor |
| ICHR | Semiconductor |
| ACMR | Semiconductor |
| UCTT | Semiconductor |
| INTC | Semiconductor |
| AMD | AI |
| OSCR | Healthcare |
| EXTR | Networking |
| ALAB | AI |
| SIMO | Semiconductor |
| NWPX | Industrial |
| LQDA | Bio |
| RVMD | Bio |
| COHU | Semiconductor |
| TWST | Bio |
| TXG | Bio |
| VSXY | Consumer |
| VPG | Industrial |
| TH | Industrial |
| DELL | AI |
| FTNT | Networking |
| VICR | Semiconductor |
| ALKS | Bio |

## 8. Dashboard Summary Mapping

| Dashboard Item | Formula |
|---|---|
| Total | count Rank 1–30 |
| Avg Momentum Score | average `Momentum Score` |
| Avg Buyability Score | average `Buyability Score` |
| Avg 6M Performance | average `Perf 6M %` |
| Avg 3M Performance | average `Perf 3M %` |
| Avg Relative Volume | average `Rel Vol` |
| High Buyability | count `Buyability Score >= 8` |
| Top Sector | most frequent Sector |
| Market Theme | from Top Sector |
| Highest Rel Vol | Symbol with max `Rel Vol` |
| Buyability Distribution | count by Buyability bucket |
| Sector Distribution | count by Sector |

## 8.1 Sector Border Mapping

Purpose:

Stock node border color must stay aligned with the visible Sector Distribution module.

Rules:

- Normalize sectors before counting.
- Sort sectors by rendered Momentum Leaders count, descending.
- Select the Top 5 sectors.
- Use official sector colors only for those Top 5 sectors.
- If a stock belongs to any sector outside the Top 5 list, map its node border to `Others`.
- Do not assign unique border colors to sectors that are not visible in the Top 5 Sector Distribution.

Mapping:

```text
Normalized Sector in Top 5 -> Sector Color
Normalized Sector not in Top 5 -> Others Gray
```

## 9. Market Theme Mapping

| Top Sector | Market Theme |
|---|---|
| AI | AI Infrastructure |
| Semiconductor | AI Hardware Chain |
| Healthcare | Healthcare Rotation |
| Bio | Biotech Risk Appetite |
| Industrial | Industrial / Infrastructure |
| Networking | AI Network Infrastructure |
| Consumer | Defensive Consumption |
| Software | Software Re-acceleration |
| Others | Market Leadership Rotation |

## 10. Data Validation

Before render:

- verify first 30 ranks exist;
- verify Rank is numeric;
- verify Symbol is non-empty;
- verify Momentum Score is numeric;
- verify Buyability Score is numeric;
- if Sector missing, apply fallback mapping;
- if Rel Vol missing, omit Highest Rel Vol stat;
- if Perf fields missing, omit performance averages.

If required fields are missing, do not render final SVG.

## Buyability Mapping

If Buyability score >= 8:

- category: 5-star
- color: #00D8FF
- glow: 24px
- lock: true

If Buyability score >= 6 and < 8:

- category: 4-star
- color: #00D97B
- glow: 18px
- lock: false

If Buyability score >= 4 and < 6:

- category: 3-star
- color: #008BFF
- glow: 10px
- lock: false

If Buyability score >= 2 and < 4:

- category: 2-star
- color: #6B7C8F
- glow: 5px
- lock: false

If Buyability score < 2:

- category: 1-star
- color: #FF4E5E
- glow: 0px
- lock: false

## Buyability Halo Mapping v1.3

Stock nodes must show different halo intensity by Buyability star category.

| Buyability | Category | Halo Color | Halo Radius | Halo Opacity | Lock |
|---:|---|---|---:|---:|---|
| 8-10 | 5-star | #00D8FF | 24px | 0.26 | true |
| 6-7 | 4-star | #00D97B | 18px | 0.21 | false |
| 4-5 | 3-star | #008BFF | 10px | 0.16 | false |
| 2-3 | 2-star | #FF9D00 | 5px | 0.12 | false |
| 0-1 | 1-star | #FF4E5E | 0px | 0.00 | false |

The halo color must match the Buyability Score legend color. This makes node quality readable without reading text.

## Buyability Glow Intensity Mapping v1.5

| Buyability | Category | Blur | Fill Opacity | Ring Count | Visual Strength |
|---:|---|---:|---:|---:|---|
| 8-10 | 5-star | 16px | 0.42 | 3 | Very Strong |
| 6-7 | 4-star | 11px | 0.24 | 2 | Strong |
| 4-5 | 3-star | 6px | 0.09 | 1 | Normal |
| 2-3 | 2-star | 3px | 0.04 | 1 | Weak |
| 0-1 | 1-star | 0px | 0.00 | 0 | None |

The renderer must use different blur filters or equivalent SVG filter settings for each glow tier.

## Composite Ranking Rule v2.0

APL Deep-Scan Dashboard ranking must use both Momentum Score and Buyability Score, while keeping Momentum Score as the dominant factor.

Purpose:

Provide the final ranking used by the APL Deep-Scan Dashboard.

APL Momentum Leaders must remain Momentum-led.

Buyability is an entry-quality adjustment, not the primary definition of market leadership.

Formula:

```text
APL Composite Score = Momentum Score + (Buyability x Weight)
```

Default Buyability weight:

```text
Weight = 2.0
```

Current formula:

```text
APL Composite Score = Momentum Score + (Buyability x 2)
```

Why the old formula is not used:

```text
Composite Score = (Momentum Score + Buyability x 10) / 2
```

The old formula is rejected because:

1. Buyability weight becomes too high.
   - Example: Momentum 70 / Buyability 10 can outrank Momentum 90 / Buyability 2.
   - This turns the system into Buyability Leaders, not Momentum Leaders.

2. Buyability is a discrete score.
   - Buyability values are normally 0, 2, 3, 5, 8, or 10.
   - Momentum Score is continuous.
   - Direct averaging creates unnatural ranking jumps.

3. Momentum must remain the primary signal.
   - Momentum Score measures market leadership.
   - Buyability measures current entry quality.
   - Buyability already includes Price vs 20MA and related entry factors.

Weight Parameter:

- Default: 2.0.
- If later backtesting shows Buyability has stronger performance impact, the weight may be raised to 2.5.
- If Momentum should remain more dominant, keep the weight between 1.5 and 2.0.

Sorting:

1. Sort by Composite Score descending.
2. If tied, sort by Momentum Score descending.
3. If still tied, sort by Relative Volume descending.
4. Assign Dashboard Rank after sorting.

Eligibility:

1. Calculate APL Composite Score for the full current input universe.
2. Calculate the average APL Composite Score of the current universe.
3. A stock qualifies as a Momentum Leader only if:

```text
APL Composite Score > Current Universe Average Composite Score
```

Dashboard Capacity:

- TOP30 is no longer fixed membership.
- The dashboard renders up to 30 highest-qualifying Momentum Leaders.
- If fewer than 30 stocks qualify, render only the actual qualifying count.
- If more than 30 stocks qualify, render the highest 30 by APL Composite Score.

Meaning:

Momentum Score measures leadership strength.

Buyability Score measures current entry quality.

The combined ranking highlights stocks that are market leaders first, then gives additional priority to better entry-position quality.

## Dashboard Sector Mapping Extension v1.6

Composite ranking may introduce symbols outside the previous Momentum-only Top 30.

Renderer fallback sector mapping must be extended when new Composite Top 30 symbols appear.

Current additional mappings:

| Symbol | Sector |
|---|---|
| HUM | Healthcare |
| PANW | Networking |
| FROG | Software |
| PBI | Industrial |
| DVA | Healthcare |
| RIOT | Financial |
| AMN | Healthcare |
| PDFS | Semiconductor |
| ATEN | Networking |
| CMI | Industrial |
| LRCX | Semiconductor |
| PLPC | Industrial |
| AMBQ | Semiconductor |
| MRX | Bio |
| CAT | Industrial |
