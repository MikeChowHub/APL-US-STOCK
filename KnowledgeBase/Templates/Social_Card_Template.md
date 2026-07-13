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
Radar Hero
Summary Cards
Buyability
Sector
Footer
```

## Logo

Logo should appear near the top-left and should provide brand identity without crowding the Radar Hero.

## Date

Date should appear near the top-right.

Use a compact format suitable for mobile viewing.

## Radar Hero

The Radar Hero should be the main visual element.

It should communicate APL Deep-Scan and Momentum Leaders clearly on mobile.

## Summary Cards

May include:

```text
Universe
Qualified Stocks
Momentum Leaders
Leader Lock
Average Momentum
Average Buyability
```

## Buyability

Use a mobile-readable version of the Dashboard Buyability expression.

Text must be large enough for phone viewing.

## Sector

Show only the most important sector information.

Do not overload the card with too many rows.

## Footer

Footer should be minimal.

Suggested content:

```text
APL Deep-Scan
Week / Date
```

## Data Binding

Social Card data should come from the current scored ranking output and the shared external sector map.

Production input contract:

```text
KnowledgeBase/Templates/Renderer_Input_Contract.md
tools/deep_scan_renderer_input.schema.json
tools/sector_map.json
tools/sector_map.schema.json
```
