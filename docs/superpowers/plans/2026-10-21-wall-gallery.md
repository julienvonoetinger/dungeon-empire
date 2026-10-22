# Single-cell wall study — narrowed scope

The user narrowed the request: implement ONLY a closed room containing one
logical floor cell, without an entrance. The gallery plan below is deferred.

Update after the user's rejection of the single-cell fixture:
- Root cause: side spans started at the rear facade foot instead of its top;
  independent cap/front-face sprites and short fillers then repeated depth cues.
- Replace ONLY the 1x1 study assembly with two complete authored side cores,
  each connecting the rear top to the near facade foot, plus separate exterior
  backing. No extra piers or filler sprites. Uniform native scaling.
- Keep one 96 px floor cell and preserve the actual before capture. Match north
  and south facade height to this continuous projection. Main map is untouched.
- Regression must reject old fillers/stacked piers, require one core per side,
  equal horizontal facade height and matching endpoints. Inspect real GPU images.

Initial implementation (rejected):
- Separate F6 scene using the actual `six_room_view.gd` assembler and native-alpha
  kit: 1x1 layout, 96 px cell, 160 px margin, entrance disabled.
- Diagnostic fixture of the current visually unapproved renderer; not a new
  style reference or an assertion that its joins are correct.
- No new art, renderer rewrite, gameplay, probes or main-scene changes. The
  earlier generated wall-sheet draft stays unused outside the project.
- Check one floor cell, four boundaries/corners, separate exteriors, no fixtures,
  uniform scales and stable rebuilds. Capture at 1x and 2x for visual review.
- Run the capture suite and update GAME_DESIGN, README and AGENTS.

## Deferred plan (not being implemented)

**Goal:** eight runnable Godot scenes exposing wall/corridor combinations in the
current blue painted style, plus access to the existing entrance study.

**Architecture:** dedicated native-alpha study modules; fixed floor masks share
one assembly renderer. The gallery offers case selection, fit, native zoom and
pan. Each fixture can be opened directly with F6. The current main scene and
ReferenceCalibration remain intact. These are visual experiments, not approval
of a procedural kit or a replacement for the six-room map.

**Tech:** Godot 4 / GDScript; ImageGen native-alpha PNGs; GPU captures.
**Spec:** current user request, AGENTS.md and GAME_DESIGN.md section 0.

## Constraints and review focus

- No silhouette masks, polygon cutouts, rotated wall art or stretched stones.
- Atlas regions contain complete sprites with transparent margins.
- Shared facade height and scale; blue palette and reference projection.
- Floors must remain visible through every corridor and intersection.
- Exterior layers remain separate; corners must not accumulate stacked piers.
- Closing/reopening a case must not accumulate nodes or move fixtures.
- Zoom and navigation are study controls only; no gameplay or saved state.

## Implementation

- [ ] Generate missing wall, corner and floor modules using current study and
  original reference; record full prompts, source files and selected hashes.
- [ ] Create a small atlas definition file and fixed case definitions for a
  room, horizontal/vertical corridors, L, T, cross, two rooms and a chicane.
- [ ] Assemble separate sprites from exposed boundaries; preserve whole assets
  and use a separate exterior layer. Build eight individual scenes and gallery.
- [ ] Add focused checks for connectivity, complete native-alpha sprites,
  missing textures, stable rebuilds, zoom/reset and unobstructed passage centers.
- [ ] Capture every case at normal and double size; inspect and repair the
  composition. Run the repository capture suite and document actual limits.
- [ ] Update GAME_DESIGN.md / README / AGENTS.md; show actual Godot renders.

## Decisions

Implement in the current checkout: the requested gallery depends on the user's
existing uncommitted artwork and study. No Git cleanup, commit or push is part
of this request. The eight named scenarios are an implementation choice covering
the requested combinations. Existing rejected main-map art is not the gallery's
style source. Generate additional complete images where the study is incomplete.
