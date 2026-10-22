# Horizontal corner corridors implementation plan

**Goal:** A3x3 visual study with west/east horizontal passages on rows0 and2.
**Architecture:** Extend the shared occupancy builder and floor extension with
configurable horizontal attachment rows; keep art/profile assembly shared.
**Spec:** GAME_DESIGN.md, modular study and durable rendering direction.

## Constraints

- Empty row configuration retains the centered cardinal studies.
- New scene uses connections10, length3 and rows[0,2]; no north/south passage.
- Whole existing native-alpha art; no scene-specific clipping, tint or overlap repairs.
- Preserve current3x3/5x5 captures and approved floor layout.
- Visual captures are review evidence, not artistic acceptance; report exposed defects.

## Steps

1. Add optional attachment-row metadata to modular_connection_plan.build.
2. Extend the corresponding two paving rows per attachment with per-branch bounds.
3. Add the scene and capture its four inner corners at1x/2x/4x.
4. Inspect joins; update scope/design and capture suite. Record limitations openly.
5. Re-render prior3x3/5x5 studies and compare their baseline hashes.

## Verification

Use the existing rendering/capture tools, as requested for these art studies.
Run the repository-required test-mobile-All-Capture command; its known F5 mismatch
does not prove anything about these joins. Do not introduce artistic test scores.

## Follow-up: shared narrow separator

The user reported the duplicate cap bands and overlapping inner turns in the
3x3 study. Two opposing boundaries around one empty logical row were each
rendered as a full wall. Their projected heights collide; moving the two corner
sprites alone cannot fix that composition.

- The contour resolver now selects a shared separator for this local topology:
  equal horizontal spans, one empty row, one common closed end and one open end.
- Consume both cap runs, the two corners and their short vertical return.
- Use a generated broad three-stone cap plus a dedicated left/right terminal,
  white tint, uniform scale, native alpha and the same476 straight cadence.
- Draw lower masonry courses once. Keep the original physical open-end bounds
  and approved central pavers. No room-specific rendering coordinates.
- Active sources: narrow-separator-v3.png, narrow-separator-ends-v5.png.
  Exact prompts, source history and measured ports are recorded in the shared kit
  and narrow-separator-generation.json.
- Review actual GPU captures for3x3 corner corridors at1x/2x and both noses4x;
  re-render the seven isolated studies, centered3x3, and wider5x5 configurations.
  Additional5x5 rows[0,2,4] exercises four shared separators with the same rule.
  Use visual captures only for this correction, following the user's instruction.

This is not an arbitrary-layout renderer or user artistic approval. Vertical
dividers and enclosed islands are outside the new selection rule.

## Follow-up: restore solid terminal volume

The first separator's flat ends-v5 were rejected: the wall body read as a thin
curtain below a slab. Replace the endpoint with solid-separator-ends-v7, a native
whole sprite containing its cap, both masonry courses and the chamfered end face
down to the base. Straight courses stop at the connecting edge instead of
continuing beneath the endpoint. Their whole-brick counts follow the measured
top/course/base ports; all source scaling remains uniform.

Record prompts and source measurements in solid-separator-generation.json.
Review3x3 at1x/2x and both tips4x, the shared5x5 rows[0,2,4] configuration,
centered3x3 and the seven isolated studies. This is visual review, not a claim
of user approval. The contour selection and central floor layout are unchanged.

## Follow-up: consistent orthographic perspective

The user rejected v7's large oblique end plane. Replace it with native v8:
two cap stones, two staggered front courses, and a closed edge at the same x
from top to foot. The front projects only down, matching the existing dungeon
camera. No diagonal side face, runtime silhouette repair or tint correction.
Whole regions and measured ports remain in modular_separator_kit.gd; keep the
existing topology rule, open-end bounds and central paving. Record the exact
ImageGen prompt and v7 rejection in solid-separator-generation.json. Inspect
actual3x3/5x5 narrow-strip captures and the seven isolated studies. User artistic
approval remains pending.
