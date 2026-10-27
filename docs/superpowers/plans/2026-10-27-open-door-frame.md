# Open door frame correction

User: unlocked doors disappear; keep the stone frame without the wooden leaf.

Root cause: isometric_game_view only emits door specials while _door_intact.
Prepared leaf/arch IDs are height splits, not material splits; hiding the lower
sprite alone would also remove jambs and leave the upper wood.

- [x] Reproduce missing open-frame parts and wall contacts in an isolated game.
- [x] Render the same accepted model without leaf/leaf-edge faces for all four
  orientations; preserve closed assets and original painting/geometry. Pack new
  parts on a small separate page to avoid enlarging/repacking existing pages.
- [x] Keep door specials and wall contacts for unlocked/forced doors; select
  prepared empty frames. Repair restores wood; removal removes the frame.
- [x] Check closed/open/broken/repaired/removed, saved-state reconstruction and
  actor overlap; compare all existing atlas regions/pixels and source hashes.
- [x] Focused read-only review, document evidence; create updated test APK if
  validation passes, using existing authorized downloadable-release workflow.

No new generated painting, new rules, save schema or player-save access.
The existing native geometry/texture preparation is code, not AI image editing.

## Results

- Baseline28checks/6fail, final40/0. Actual thief and mage callbacks, live session
  refresh, in-memory save reconstruction, force/repair/removal. Native actor
  captures cover both corridor axes before/after the aperture. Seven contact
  states and existing mobile interaction harness pass. No normal saves touched.
- Asset verification:151 existing entries/pixels and3 atlas pages unchanged;
 8new entries,512x512 page,140335PNG bytes/1MiB RGBA. 1782 clear interior pixels
  per direction; filtering-support boundary excluded. Accepted sources immutable.
- Read-only review found no actionable defect. Native import/export and packaged
  startup/40checks pass; empty Godot stderr. Actor occlusion inspected visually,
  no pixel oracle; no physical phone/performance validation.
- APK0.1.3-test/code4,61191095bytes, same package/cert. Published prerelease
  android-test-0.1.3, uploaded digest matched, anonymous downloadHTTP200.
  SHA25613793b9e2beb2bb70f3959761555caf8fe5a9d6fbddfced8f364c6fe2a6dfc7f.
  Current uncommitted work included; release tag refers to baseHEAD only.
