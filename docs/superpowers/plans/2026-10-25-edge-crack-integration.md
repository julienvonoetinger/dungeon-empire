# Edge crack integration

> Execute inline with executing-plans; finish with a focused requesting-code-review review.

**Goal:** Adopt all three accepted edge/corner crack motifs, each on the floor and
both wall planes, alongside the existing chipped patch and violet corruption.

**Spec:** User accepted the v2-edge-cracks comparison then explicitly requested
all variants. Preserve that artwork, scale and prepared projections unchanged.

**Architecture:** Load the nine accepted prepared PNGs with selection hash guards.
Replace the six old ordinary-crack regions; retain the three chip and three violet
regions. Existing placement code keeps its eligible hosts and density; its motif
weights become corner25/vertical25/lateral20/chip25/corrupt5.

**Constraints:** Current ongoing migration checkout, no regeneration, runtime
geometry or new camera/layout changes. Historical reviews remain immutable.
No commit/push. Use image/pixel checks and Godot captures rather than adding tests
for this low-impact asset/configuration integration.

## Steps

- [x] Freeze v2 selection and snapshot current production files for comparison.
- [x] Update approved-decoration loader, export provenance and motif table.
- [x] Export/import once; check prior retained regions and all new selected pixels.
- [x] Capture production scenes, two seeds and editor previews; inspect visuals.
- [x] Verify staged resource export/startup, review focused changes, update docs.

## Review focus

All five motifs reachable; no old ordinary motifs or dangling references;
unchanged native-alpha art and frame/offsets; retained prior pixels and metadata;
no overwriting selected captures; no pending editor state resets.

## Rulings / progress

- Work in the existing codex/2d-foundation checkout: it contains the user-visible
  uncommitted isometric migration and all accepted assets needed for this change.
- "All variants" includes all three accepted new fissures plus existing chip and
  violet corruption, not the drafts rejected for coarse/repeated diagonal shapes.

## Completion evidence

50 regions, 580419 PNG bytes / 4 MiB RGBA. 41 retained atlas regions and metadata
unchanged; nine new regions equal selected atlas pixels, prepared files unchanged.
All 62 selected hashes retained. All five motifs observed. Runtime68/23 and focused5
exit0empty stderr; seed17 restored capture identical. Editor21/5 exit0, transient
historical-tool parse diagnostic absent at second full capture; native diagnostics
remain. Stage import/export and empty-directory package startup exit0empty stderr,
resource ZIP486487bytes. Focused independent review found no concrete issue.
Evidence in v2-edge-cracks/integration. No commit, push or device-profile claim.
