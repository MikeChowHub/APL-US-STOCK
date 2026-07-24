# APL Deep-Scan Social Card Template

This template defines the standard render structure for the APL Deep-Scan Social Card.

The Social Card is mobile-first.

It is not a resized Dashboard.

## Canvas

```text
1080 × 1350
```

## Output

```text
SVG + PNG
```

## Layout

```text
Logo
Date
Issue-specific Headline
Primary Visual Signal
Selected Supporting Evidence
Footer
```

## Logo

Logo should appear near the top-left and should provide brand identity without crowding the issue-specific headline.

## Date

Date should appear near the top-right.

Use a compact format suitable for mobile viewing.

## Issue-specific Headline

State one current market or leadership message that remains understandable on a phone without reading the Dashboard.

The headline must be consistent with the issue's core market proposition. It must not be a generic `APL Deep-Scan` label or a list of scan statistics.

## Primary Visual Signal

Use one dominant mobile-readable visual signal. This may be a simplified radar, selected leadership group, Buyability signal or sector observation, depending on what supports the headline.

Do not reproduce the Dashboard's complete radar, scan funnel, Buyability distribution and sector distribution in one smaller layout.

## Selected Supporting Evidence

Select only the minimum current evidence required to make the headline credible. Possible evidence includes:

```text
one material scan metric
one leadership observation
one sector observation
one participation signal
```

Universe, Qualified Stocks, Momentum Leaders, Leader Lock, Average Momentum and Average Buyability are not a mandatory set. If a metric does not change the mobile message, omit it.

## Footer

Footer should be minimal.

Suggested content:

```text
APL Deep-Scan
Week / Date
```

## Data Binding

Social Card data should come from the current scored ranking output and the shared external sector map.

Any displayed number, symbol, ranking fact or sector classification must match those managed sources. Source accuracy does not require displaying every available metric.

For formal Daily Production, renderer input `Meta` also carries:

- `SocialHeadlineLines`: one or two issue-specific lines taken from the approved Cover Brief overlay;
- `CoreMarketThesis`: the same managed market／scene thesis used by the Cover and SEO concept.

This binds the Social Card headline to the current cross-platform proposition. Ranking and sector evidence may support that headline, but must not replace it with an unrelated automatically inferred theme.

Production input contract:

```text
KnowledgeBase/Templates/Renderer_Input_Contract.md
tools/deep_scan_renderer_input.schema.json
tools/sector_map.json
tools/sector_map.schema.json
```
