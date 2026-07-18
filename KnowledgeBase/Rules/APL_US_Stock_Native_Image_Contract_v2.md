# APL US Stock Native Image Contract v2

## Status and authority

This contract is executable through `tools/validate_native_image.py` and is enforced as a paired Cover／SEO source contract by managed-input preflight. Publication outputs, Final Audit and Archive continue to track the rendered Cover／SEO artifacts under the existing Production Artifact Contract.

Schema authority: `tools/native_image_contract_v2.schema.json`.

Workflow authority: `KnowledgeBase/Rules/native-production-workflow.md`.

## One contract per native asset

Cover and SEO use separate image files and separate artifact contract JSON files. Each contract follows `KnowledgeBase/Templates/native_image_artifact_template.json`.

The unified logical field is `artifact_type`:

- `cover` requires `aspect_ratio: 4:5`;
- `seo` requires `aspect_ratio: 16:9`.

`artifact_type` is the artifact role. Each record also carries:

- one shared `scene_concept_id`;
- role-specific `camera_distance` and `framing_description`;
- role-specific `subject_placement` and `text_safe_area`;
- a repository-portable relative `source_path`;
- native dimensions, SHA-256 and `transformation: none`.

The Cover／SEO pair must share the same scene concept, core subject and visual language, while using different source paths and different native bytes. Camera distance or framing must differ. Reusing, cropping, resizing or re-encoding one source to manufacture the other is not a valid pair.

The previous design-only `Variant` field is removed. It must not coexist with `artifact_type`.

## Aspect-ratio validation

The validator decodes PNG dimensions and calculates:

```text
actual_ratio = decoded_width / decoded_height
difference = absolute(actual_ratio - target_ratio)
PASS when difference <= 0.001
```

Tolerance is inclusive and fixed at `0.001`, allowing normal AI generation pixel variance without correcting the image.

## Provenance

Every contract records:

- original native width and height;
- original source SHA-256;
- provider;
- generation workflow;
- generation date-time with UTC offset;
- capture stage `ImmediateGenerationOutput`;
- transformation status.
- shared scene concept identity and role-specific composition intent.

Contract dimensions and SHA must match the file decoded and hashed by the validator.

## Transformation policy

`transformation` remains schema `const: "none"` rather than an enum.

Reason: this contract describes Native Assets only. Accepting `crop`, `padding` or `resize` as enum values would incorrectly make transformed artifacts schema-valid native assets. A future Publication Render contract must model transformations separately.

The validator is read-only. It never crops, pads, resizes, re-encodes, corrects or replaces an image. Any failure returns non-zero.

## Draw-CroppedImage boundary

`Draw-CroppedImage` is not modified. It can only belong to a future declared Publication Render stage and cannot be used before native validation or claim `transformation: none` after cropping.

See `docs/NATIVE_RENDERER_BOUNDARY_ANALYSIS.md` for the architectural decision and alternatives.

## Production gate

Managed-input preflight validates both records, both native files, role-specific ratios, source paths, dimensions, SHA-256, shared scene identity and distinct framing before Production starts. The runner receives separate `CoverBackgroundPath` and `SeoBackgroundPath` values and fails if they resolve to the same path or bytes. Local overlay rendering remains independent for Cover and SEO.
