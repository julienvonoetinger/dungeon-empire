# Stone variation implementation plan

> Execute inline with superpowers:executing-plans in the current feature checkout.

**Goal:** Make the existing dungeon less repetitive through floor and wall material
variation, retaining its blue-violet art, approved wall volumes and heart.

**Spec:** The user requests wall/floor variations like the original illustrated
concept, applied to the current implementation. Prior exclusions of decorative
pots, roots and crystals remain in force. This step remains static.

**Architecture:** Reuse five clean native slab crops grouped by their natural row
height, with deterministic selection, staggered joints and restrained per-stone
tones. Vary the order of existing facade crops and tone lateral cap stones while
preserving their geometry. No new bitmap assets or texture memory are required.

**Tech stack:** Godot 4.7, GDScript, existing Polygon2D atlas assembly.

## Decisions

- Default variation enabled, reproducible visual seed 173. Inspector toggle and
  seed affect artwork only; no gameplay or persistence is added.
- Keep native crops and orientation. Floor sources: three 89 px slabs and two clean
  83 px slabs. Discard candidates containing chest shadow or
  foreground wall fragments, identified in `artifacts/variation-source-inspection.png`.
- Keep entrance artwork, heart, piers and sidewall dimensions. Material colour
  variation is now authorized by this request; no architectural redesign.
- Same full slab must retain the same source and tint across clipped fragments.
- Keep the current checkout and existing uncommitted work. No commit or push.

## Task

- [x] Add failing material-variation regression: diversified floor sources/tones,
  repeated-build stability, seed sensitivity, consistent clipping and preserved
  lateral wall/pier geometry. Run it before implementation.
- [x] Add `scripts/stone_variation.gd` and integrate selection/tones into
  `scripts/six_room_view.gd`; include settings in the editor refresh signature.
- [x] Update GPU source comparison for deliberate modulation, keep all existing
  passage/entrance/heart checks, and extend the isolated editor dependencies.
- [x] Capture the actual before/after at equal camera scale. Inspect full map,
  native details and joints, and iterate any seams or excessive contrast.
- [x] Update design, atlas notes and README; run the full capture suite and get
  one read-only review of this addition.

## Review focus

- Unintended props or baked object shadows must not be repeated.
- Variation must not introduce a checkerboard look or change wall perspective.
- No tint seams within one clipped slab; floor covers passages continuously.
- Rebuild/seed changes must be stable and preserve the authored heart.
- Tests distinguish source geometry/provenance from intentionally changed tone.

## Iteration notes

- Initial implementation and technical checks passed, but the 86 px left-room
  source created repeated violet bands and thick seams in the actual capture.
  Removed that candidate after visual inspection; the five retained stones have
  compatible neutral blue illumination. Repetition now allows at most two equal
  adjacent source slabs, breaking the strict two-source ABAB pattern.

## Verification and review

- Initial regression failed before implementation because material settings did
  not exist (`artifacts/variation-red.out.log` and `.err.log`).
- `tools/test-mobile.ps1 -All -Capture` passed with five clean sources and the
  final tone palettes. Default assembly: 970 masonry/floor surfaces plus three
  heart surfaces. Full-map GPU source/modulation error: 0.82/255 maximum; heart
  source probes: 0/255. Editor inspector updates and authored-node preservation pass.
- Inspected full-map, native wall/junction and equal-scale before/after captures.
  No new bitmap asset was introduced; the change adds ten generated surfaces
  for the default seed, not a new texture allocation.
- Read-only review found no blockers. Its minor request to assert the maximum
  consecutive slab repeat was implemented: group unique slab origins by row,
  sort by x and count physically adjacent equal sources. The amended regression
  passed for both seeds (`artifacts/verify-variations-final.out.log`).
- Design, README, atlas notes and repository instructions now reflect the default
  settings, source sizes, modulation and static scope. `git diff --check` passed.
- Artistic approval for every possible seed, arbitrary maps and mobile profiling
  remain outside this change. The checks do not claim exhaustive visual fidelity.
