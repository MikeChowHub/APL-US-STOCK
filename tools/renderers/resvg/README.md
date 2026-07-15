# resvg renderer

This directory contains the repository-managed Windows x64 `resvg.exe` used by `tools/convert_svg_to_png.ps1`.

## Provenance

- Project: `linebender/resvg`
- Version: `0.47.0`
- Platform: Windows x64
- Official release page: https://github.com/linebender/resvg/releases/tag/v0.47.0
- Official release asset: `resvg-win64.zip`
- Asset URL: https://github.com/linebender/resvg/releases/download/v0.47.0/resvg-win64.zip
- License: `MIT OR Apache-2.0`

The release-asset and extracted executable SHA-256 values are authoritative in `renderer-manifest.json`.

## Production policy

`resvg` is the primary and only automatic renderer. `convert_svg_to_png.ps1 -Renderer Auto` and `-Renderer Resvg` use this executable. `-RendererPath` may explicitly point to a separately validated resvg executable.

Chromium is not an automatic fallback. The current `-Renderer Chromium` mode fails explicitly because Chromium GPU-process crashes were observed in this environment. Production must stop rather than silently use a browser or produce a degraded PNG.

The adapter invokes resvg with repository `Assets/Fonts` via `--use-fonts-dir` and `--skip-system-fonts`; it never depends on Windows-installed fonts. Dashboard and Social mapping uses Alibaba Sans HK 55/75 assets as the resvg family `Alibaba Sans HK` at weights 400/600, and Montserrat assets at weights 400/500/600/700. Until a licensed repository mono font is added, `.mono` uses Montserrat 500/600. Renderer audit returns the requested family policy and managed font files. Any font-fallback or invalid-geometry warning is a production failure and the partial PNG is deleted.

## Smoke-test rule

Before a renderer release is accepted, run it from an isolated `tmp/` fixture against:

1. a minimal local SVG at a controlled width and height; and
2. a representative production Dashboard SVG.

For each PNG, require: a newly created file, non-zero bytes, PNG magic bytes `89504E470D0A1A0A`, exact requested dimensions, and successful `System.Drawing.Image` load. Any non-zero renderer exit code, missing/partial output, invalid PNG signature, dimension mismatch, or unreadable image is a failure; partial output must be deleted.
