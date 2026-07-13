# APL Deep-Scan Dashboard Render Template

This template defines the standard render structure for the APL Deep-Scan Radar Dashboard.

The Dashboard is a product UI render, not a decorative illustration.

## Canvas

```text
1920 × 1080
```

## Output

```text
SVG + PNG
```

## Layout

```text
Left Panel
Center Radar
Right Dashboard
Bottom Status Rail
```

## Left Panel

Purpose:

Provide scan context and legend.

Typical sections:

```text
Logo
Scan Summary
Radar Legend
Buyability Score
Leader Lock
```

## Center Radar

Purpose:

Show the ranked APL Momentum Leaders 領導股 visually.

Core elements:

```text
APL Deep-Scan Core
Core Zone
Watch Zone
Observation Zone
Stock Nodes
Buyability Glow
Sector Border
Leader Lock
```

## Right Dashboard

Purpose:

Summarize current scan structure.

Typical sections:

```text
Buyability Distribution
Sector Distribution
Market Scan Summary
```

## Bottom Status Rail

Purpose:

Provide terminal-style status information.

Do not use it as a marketing slogan area.

## Data Binding

Dashboard data should come from the current scored ranking output.

It should not rely on hardcoded daily values when production data is available.

Production input contract:

```text
KnowledgeBase/Templates/Renderer_Input_Contract.md
tools/deep_scan_renderer_input.schema.json
tools/sector_map.json
tools/sector_map.schema.json
```
