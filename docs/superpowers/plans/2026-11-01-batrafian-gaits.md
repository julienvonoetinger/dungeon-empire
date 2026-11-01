# Batrafian walk and run

Request: render the equipped Batrafian walking and running, following the
approved whole-mesh Blender-to-sprite pipeline. No APK, save access, commit,
push or production raid integration is requested.

## Decisions

- Continue in the existing `codex/2d-foundation` workspace: the equipped source
  and all four user GLBs are uncommitted inputs here. Preserve them unchanged.
- Use v3-equipment-orientation, including the raised bow handle, forearm roll
  and outward-facing quiver. Keep the spare arrow hidden.
- Eight held poses per gait, four actual orthographic isometric renders per
  pose, fixed camera registration; no mirrored views or body-part compositing.
- Walk at 15 poses/s, run at 16 poses/s, with root travel calibrated to stance
  displacement. Verify evaluated frog soles, including the long toes.
- Reuse the existing corridor preview without changing Vulpin/Paladin behavior.
  Provide separate BatrafianWalk and BatrafianRun scenes, pause/step and x2.

## Execution

1. Create pose/render and independent saved-scene verification scripts. Render
   extreme front/rear pilot poses; inspect grip, feet, quiver and silhouette.
2. Render all 64 transparent masters. Reopen the packed held-pose source and
   check source hashes, feet/stride, attachments, prop/body crossings and bounds.
3. Pack eight 2048x256 atlases and SpriteFrames. Add two isolated native scenes.
   Run a missing-scene regression before installing them, then native checks
   of playback, x2, turning, four directions, registration and viewport fitting.
4. Inspect contact sheets, animated reviews and native captures; preserve
   reproduction commands and limitations. One independent final review.

## Evidence ledger

- Initial state: only .gitattributes, AGENTS.md and Batrafian review inputs
  already modified/untracked. Shared runtime scripts are not being changed.
- Pilot: three run poses crossed the quiver with the tunic. Lower foot lift/
  pitch and bob alone did not resolve this. An outward knee pole appropriate to
  the frog anatomy resolves it with the original equipment transforms retained.
- Complete: 64 renders; independent replay of 16 poses, 12 support intervals,
  four source hashes, original equipped scene hash, 12 packed textures; no
  nonhand prop/body edge crossings and no floor penetration in sampled poses.
- Native: missing-scene fixture first produced 2 failures; after generation,
  import and all 708 native checks pass, empty stderr. Three viewport formats,
  four directions, reversal, pause/step/x2 and support ordering checked.
- Pose boards, native front/back and portrait captures inspected. Recipe, size
  accounting and animated review preserved. Shared runtime scripts unchanged.
- Local review auto-opening was blocked by the in-app browser URL policy;
  no workaround attempted. Deliver normal local links and inline media instead.
- Final independent review: no important finding. All 64 master hashes checked,
  all eight atlases rebuilt in memory and matched pixel-for-pixel, both WebP
  timings verified; code/recipe/captures reviewed. No files changed by reviewer.
- Complete within requested preview scope. No APK, commit or push.
