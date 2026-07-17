# Native Production Workflow v1

## Status

This is an executable framework boundary, not a Production integration. It does not change the APL Production runner, renderer, outputs or Archive workflow.

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

Cover and SEO are generated as independent images. A Cover asset cannot be reused as SEO and an SEO asset cannot be reused as Cover.

Requested native targets:

- `cover`: 4:5;
- `seo`: 16:9.

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

Any error returns a non-zero exit. The validator does not create a replacement file.

## Provenance Record

The validated contract is the provenance record for the native bytes. It records provider, workflow, generation time, immediate-generation capture stage, original size, source SHA and transformation status.

Changing the image bytes invalidates the source SHA and requires rejection. It must not be relabelled as a native asset after post-processing.

## Archive / Publication Handoff

A PASS native asset may be offered to a future Archive or Publication workflow only after that workflow is separately approved. This framework performs no handoff automatically.

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

