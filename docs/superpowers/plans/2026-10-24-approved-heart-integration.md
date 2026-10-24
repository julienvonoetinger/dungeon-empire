# Approved vortex heart integration

> **For agentic workers:** Use superpowers:executing-plans to implement these tasks inline.

**Goal:** Integrate the selected ritual-v3 heart into the active mobile kit and Godot previews.
**Architecture:** Pack the already prepared native-alpha sprite into the common atlas. Place it through the existing support-depth sorter; retain the standalone DungeonHeart scene using that same renderer.
**Tech Stack:** Godot 4 GDScript, Node.js/Sharp offline atlas tools.
**Spec:** User's “Oui” to integration, `docs/reference/mobile-heart-review/ritual-v3/selection.json` and its approved game-scale comparison.

## Constraints and choices

- Preserve exact approved 289×289 source-density-256 sprite, anchor [144.5,155.792663476874], ~156 displayed px base, .75 zoom, native alpha, no runtime painting/warping.
- Retain existing architecture/door pixels, geometry, layouts, camera/panning and editor state.
- Use the current checkout: the approved artwork, doors and editor workspace are uncommitted here. No branch move, commit or push is requested.
- Scope user-authorized heart trials to this integration. No unrelated suite or device profiling.
- Place one heart at ground centre (1.5,1) in MobileReference and (12,14) in SixRoomPreview/DungeonPreview. Positions are in cell units; these are presentation placements, not new dungeon-generation rules.
- Keep earlier review inputs frozen; new evidence lives in ritual-v3/integration/.

## Review focus

1. Atlas repacking retains all 47 previous sprites and their offsets/bounds.
2. The heart uses the reviewed alpha/anchor/scale and shares the wall draw order.
3. Floor placement accepts the whole footprint and avoids stairs/doors; blank settings show no heart.
4. Editor refresh does not duplicate sprites; standalone and in-dungeon views share the asset.
5. Export includes the new scene/script but excludes the old large heart artwork and authoring sources.

## Task 1: Approved asset and scene integration

- [x] Add focused Godot trials against the production renderer; run before implementation and observe missing prepared heart.
- [x] Freeze pre-heart catalog/atlas in integration/source for a repacking comparison.
- [x] Add `tools/mobile_approved_heart.cjs`: verify approved source/prepared hashes and return the unchanged prepared sprite, anchor and support bounds to the existing packer.
- [x] Extend `tools/export_mobile_kit.cjs` with the heart and provenance. Export 48 prepared sprites.
- [x] Extend `mobile_dungeon_renderer.gd` to draw plan.hearts with normal support ordering. Expose ground-centre positions in `wireframe_cell_study.gd`, validate full support on floor without specials.
- [x] Update `alpha_heart.gd`/DungeonHeart.tscn to render only that prepared heart. Remove the obsolete review-independent dynamic light so appearance matches approval.
- [x] Set positions in the three presentation scenes. Other layout studies remain undecorated by default.
- [x] Import and rerun focused trials: no-heart default, invalid placement rejected, native size, repeat refresh, standalone, near/far wall ordering, presentation scenes.

## Task 2: Export and evidence

- [x] Compare old/new atlas regions and approved heart after identical alpha compositing; retain report and actual-size captures.
- [x] Include DungeonHeart in explicit mobile export graph, stage/import/export resources using existing workflow; inspect package inventory.
- [x] Capture affected runtime/editor previews at game scale and inspect them.
- [x] Document current kit size, exact selection, reproduction and limits in AGENTS.md and review docs.
- [x] Fresh focused code review, resolve material findings, report completion without commit/push.

## Execution record

- Prior user-authorized visual tests are reused for the heart integration. No new art generation is needed.
- Implementation and documentation proceed under the user's integration approval; no additional approval gate.
- Task 1 complete: missing-heart trial RED, then 60 checks GREEN / 11 captures. The wall test locates shared AtlasTextures rather than generated node names, which Godot renames when duplicated.
- Task 2 complete: 47 retained regions unchanged, approved heart matched after equivalent alpha composition; 63 runtime captures / 21 scenes, 11 editor captures / 3 scenes, matching focus views. Staged import/export/open successful, 42 dependencies, resource ZIP 705339 bytes.
- Source review `/root/review_approved_heart_integration`: no actionable findings. Artistic selection, unrelated doors, future arbitrary layouts, gameplay systems and device profiling are outside this appearance integration; these limits are explicit in its README.
- Windows locked-file capture failure reproduced; write to a fresh capture root and publish atomically using the established writer. The helper now exits on write failures rather than hanging on a null inventory writer. User editor left running.
- Capture pixel deltas are reported, not used as an invented fixed-tolerance gate: exact source packing is independently checked. Max rendered channel delta 11/255, mean 0.00305; inspection retained the approved appearance.
