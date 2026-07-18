# Native Production Workflow v1

## Status

This workflow defines the native Cover／SEO source boundary used by managed-input preflight. It does not change scoring, ranking, publishing artifact names or Archive selection.

## Workflow

```text
AI Generation
    |
    v
Native Asset Capture
    |
    v
Contract Creation
    |
    v
Validation
    |
    v
Provenance Record
    |
    v
Archive / Publication Handoff
```

The final handoff is conceptual until a separate Production integration is approved. The framework does not write to the repository `outputs/` or `Archive/` directories.

## AI Generation

Cover and SEO are generated as independent views of one shared scene concept. A Cover asset cannot be reused as SEO and an SEO asset cannot be reused as Cover.

Requested native targets:

- `cover`: 4:5;
- `seo`: 16:9.

Cover uses a closer or medium-close portrait view, concentrated subject placement, vertical tension and a Cover-specific title／logo safe area. SEO uses a wider or more distant landscape view, lateral scene extension, more environmental narrative and an SEO-specific horizontal title／logo safe area.

Both generations must retain the same market thesis, subject identity, primary scene elements, palette, lighting direction, cinematic mood, brand atmosphere and art style. Only camera distance, field of view, framing, subject scale, negative space and text-safe geometry may change.

Normal generator pixel variance is accepted only through the `0.001` aspect-ratio tolerance. The generated result is never corrected to make it pass.

## Native Asset Capture

A Native Asset is the original generated file captured immediately after generation. Before capture completes it must not be:

- cropped;
- padded;
- resized;
- rotated;
- re-encoded;
- silently corrected.

Capture records the original decoded width and height plus SHA-256. The captured file is immutable for Native Contract validation.

## Contract Creation

Create one artifact contract JSON per native file using `KnowledgeBase/Templates/native_image_artifact_template.json`.

The logical roles are separated by `artifact_type`:

- `cover` with `aspect_ratio: 4:5`;
- `seo` with `aspect_ratio: 16:9`.

`transformation` must be `none`. A transformed artifact is not a Native Asset and cannot use this contract.

The paired records must use one `scene_concept_id`, different `artifact_type` values, different relative `source_path` values and different source SHA-256 values. Camera distance or framing must differ.

## Validation

Run `tools/validate_native_image.py` with the image file and its artifact contract. Validation is read-only and fail-closed.

It verifies:

- file existence and PNG structure;
- decoded width and height;
- contract dimension equality;
- role-specific aspect ratio within `0.001`;
- source SHA-256;
- artifact type;
- `transformation: none`;
- provenance fields.
- relative source path and scene concept identity;
- paired Cover／SEO role, path, byte and framing separation.

Any error returns a non-zero exit. The validator does not create a replacement file.

## Provenance Record

The validated contract is the provenance record for the native bytes. It records provider, workflow, generation time, immediate-generation capture stage, original size, source SHA and transformation status.

Changing the image bytes invalidates the source SHA and requires rejection. It must not be relabelled as a native asset after post-processing.

## Archive / Publication Handoff

A PASS pair may be passed to the existing local overlay stage. Cover and SEO overlays remain separate publication renders at 1080x1350 and 1280x720. Archive continues to copy the final publication artifacts under its existing policy.

## Native Asset versus Publication Render

### Native Asset

- original generation output;
- immutable during validation;
- geometry transformation prohibited;
- `transformation: none` required.

### Publication Render

- separate derived-artifact workflow;
- must never overwrite or impersonate the Native Asset;
- crop or resize, if ever approved, must be declared in separate derivative metadata;
- cannot claim `transformation: none` after geometry changes;
- requires a separate Production and renderer audit.
