# Native alpha dungeon kit implementation plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task by task.

**Goal:** Replace all rendered cutout geometry in the six-room scene with complete generated RGBA sprites and inspect the joints at 2x.

**Architecture:** Keep the fixed floor topology, camera, authored heart placement and entrance. Generate source sheets with isolated complete sprites, select only complete rectangular regions preserving alpha, and assemble using uniform scale and overlap under whole edge/corner sprites. No image segmentation, masks, cutout shaders, silhouette polygons or clipping painted stones.

**Tech stack:** Godot 4 Sprite2D/AtlasTexture, built-in imagegen, existing PowerShell capture suite.

**Spec:** GAME_DESIGN.md, section 1 native transparency production rule; latest user approval to implement.

## Constraints

- Preserve the approved slate-blue painted style and orthographic overhead/front facade perspective.
- Keep the six-room topology, 96 px logical cells, 3008 x 2048 bounds, entrance and heart anchors.
- Native alpha must come from imagegen. Rectangular sprite selection and uniform scaling only.
- Preserve earlier uncommitted work; no git cleanup or commit.
- The old reference study is historical comparison only, not a source of production cutouts.

## Tasks

- [x] Add and run a failing regression requiring Sprite2D-only production art and source alpha.
- [x] Generate and inspect a masonry/floor kit, piers, entrance arch and complete heart, recording prompts and sources.
- [x] Replace six_room_view rendering with complete sprite assembly, independent of source-frame polygons; retain rebuild lifecycle and static lighting.
- [x] Replace heart contours with a complete alpha sprite in the authored scene.
- [x] Adapt spatial probes and tests from old UV coordinates to alpha coverage, anchors, continuity, no clipping and lifecycle checks; preserve independent floor/corridor positions.
- [x] Run tools/test-mobile.ps1 -All -Capture; inspect normal, 2x entry, vertical walls, junctions, heart and variation captures. Iterate on concrete visual defects.
- [x] Synchronize design/instructions/readme with actual assets, counts and limitations; report real captures.

## Execution record — 2026-10-21

- Native-alpha regression first reproduced the former production polygons.
  Replaced the current six-room production art with 21 complete sprite definitions
  in seven generated PNGs, plus the already-approved torch. Generated files are
  unchanged, with prompts and original output names in generation.json.
- Kept the fixed plan, camera, entrance/torch anchors and authored heart instance.
  Added whole floor substrates, whole entrance extensions and single-headed
  joined piers; corrected side-wall extensions that initially entered passages.
- Adapted the 644 fixed probes, editor lifecycle tests and GPU alpha checks.
  Default scene has 850 sprites plus three lights, including the heart.
- Independent review found missing atlas attribution in F3/JSON. Three regression
  assertions reproduced it, then the inspector was fixed to report backing PNG,
  full atlas region and sprite-local UVs. Review confirmed the correction.
- Added checks for source alpha and transparent boundaries of all 21 regions.
  No silhouette processing, masks or cutout shaders remain in production.
- Final command: tools/test-mobile.ps1 -All -Capture, exit 0.
  Log: artifacts/alpha-suite-final.log. All 644 probes pass.
  GPU: 599 map samples (max 0.892/255), 3828 entrance samples (1.165/255),
  2809 heart samples (1.018/255); tolerance 4/255, zero mismatches.
- Inspected actual normal scene, entrance, heart, vertical wall, junction at 2x,
  variation and historical reference captures. Checked git diff --check; no
  whitespace errors (only repository LF/CRLF conversion notices).
- Synchronized AGENTS.md, GAME_DESIGN.md, README.md and historical atlas notes.
  Review identified nominal wall heights; documentation now explicitly allows
  variant height differences caused by preserving native proportions.
- Limits: GPU tests derive current transforms and do not prove artistic fidelity;
  the retained historical reference study is separate. Arbitrary layouts,
  side entrances, memory optimization and real-phone validation remain future work.
  No commit, push or repository cleanup performed.