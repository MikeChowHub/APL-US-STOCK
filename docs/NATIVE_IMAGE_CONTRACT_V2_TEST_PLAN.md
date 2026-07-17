# Native Image Contract v2 Test Plan

## Scope

Tests use `tools/validate_native_image.py` and temporary fixtures outside `outputs/` and `Archive/`. They do not invoke Production or the renderer.

## Framework structure

Required files:

- `KnowledgeBase/Rules/APL_US_Stock_Native_Image_Contract_v2.md`;
- `KnowledgeBase/Rules/native-production-workflow.md`;
- `KnowledgeBase/Templates/native_image_artifact_template.json`;
- `tools/native_image_contract_v2.schema.json`;
- `tools/validate_native_image.py`;
- `docs/NATIVE_IMAGE_CONTRACT_V2_TEST_PLAN.md`;
- `docs/NATIVE_RENDERER_BOUNDARY_ANALYSIS.md`.

## Schema alignment

- artifact type field is `artifact_type`, never `Variant`;
- enum is exactly `cover`, `seo`;
- transformation remains `const: none`;
- tolerance is exactly `0.001`;
- cover maps to `4:5`; SEO maps to `16:9`;
- native dimensions are positive integers;
- SHA is uppercase hexadecimal with 64 characters;
- unknown fields fail.

## Positive regression

| Artifact type | PNG dimensions | Expected |
|---|---:|---|
| cover | 600x750 | PASS |
| cover | 1080x1350 | PASS |
| seo | 1280x720 | PASS |
| cover | 1122x1402 | PASS |
| seo | 1672x941 | PASS |

## Negative regression

| Case | Expected |
|---|---|
| 916x1717 PNG declared as 600x750 cover | FAIL dimension mismatch |
| 1024x1024 PNG declared as 1280x720 SEO | FAIL; allowed reason: dimension mismatch or aspect ratio mismatch |
| major ratio mismatch with matching declared dimensions | FAIL ratio mismatch |
| SHA-256 mismatch | FAIL |
| `artifact_type` outside cover/seo | FAIL |
| cover with `aspect_ratio: 16:9` | FAIL |
| SEO with `aspect_ratio: 4:5` | FAIL |
| tolerance other than 0.001 | FAIL |
| `transformation: crop` | FAIL |
| `transformation: resize` | FAIL |
| missing/empty/malformed PNG | FAIL |
| generation time without UTC offset | FAIL |
| capture stage other than ImmediateGenerationOutput | FAIL |

## Fail-closed checks

For every failure:

- exit code is non-zero;
- no corrected image is created;
- original file size and SHA remain unchanged;
- no crop, padding, resize or silent correction occurs;
- no file is written to Production, `outputs/` or `Archive/`.

## Renderer boundary

No renderer test or modification is part of this framework scope. Future integration must follow `docs/NATIVE_RENDERER_BOUNDARY_ANALYSIS.md` and distinguish immutable native records from transformed publication derivatives.
