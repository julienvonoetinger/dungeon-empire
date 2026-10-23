# Wireframe cell kit implementation plan

**Goal:** Replace the modular study scenes' stone-by-stone renderer with complete cell images selected from occupancy.

**Architecture:** A deterministic offline exporter produces a finite SVG catalogue from the square, two-course geometry. Godot imports the SVGs as textures and places complete floor and wall sprites at integer cell coordinates. Cardinal neighbours select the 16 wall combinations; diagonal neighbours add concave junction piers. Open study endpoints additionally retain their exposed end faces.

**Spec:** `docs/reference/two-course-square-room.json`, model `after`, and the user's request to integrate the wireframes into Godot.

**Constraints:** 1×1 cells; one-cell corridors; thickness 1/6; height 1.88/6; one course joint at .94/6; projection X=(1,0), Y=(0,1), height=(-.18,-.9). No mirrored sprites, stretched geometry, thin third course or vertically divided piers. These are vector wireframe placeholders, not painted production assets. Future painted assets must retain native alpha and the same ports/anchors.

## Tasks

- [x] Export the complete catalogue, including four-wall cells, diagonal pier configurations and exposed corridor ends. Keep floors and walls separate. Restore the authored 19-slab floor-only pattern, normalized to the square grid, instead of inventing a replacement motif.
- [x] Add a shared grid renderer and preset occupancy builder. Preserve existing study dimensions, open endpoints, attachment rows/columns, inspector refresh getter and camera framing. Add the closed 17-cell wireframe example. Switch the modular study scenes to this renderer; preserve legacy six-room scenes.
- [x] Update reference metadata, README, game design and repository instructions. Inspect generated source and changes; provide the scene to open.

## Review focus

Whole cell sprites must omit internal end faces; diagonal gaps must receive piers; independently authored west/east geometry must use one height vector; floors must remain continuous across cell boundaries; open ends and closed three-wall terminals must select different images.

## Execution record

The user already authorized integration. Work stays in the existing feature checkout to retain the current wireframe sources. No new test suite or test execution: the session instructions prohibit tests unless requested. No automatic commit/push of unrelated pending changes. SVG images use opaque neutral faces solely to hide lines behind the wireframe volumes; this is not processing or repairing painted sprites.

User clarification: no image or geometry creation in Godot. The offline Node exporter is a preparation tool only. Godot only loads imported textures, chooses catalogue entries and positions Sprite2D nodes. The provisional newly invented floor pattern was removed; the existing floor-only drawing supplies the motif. The assembled whole-room study's global paving is not being represented as a single room image.

## Completion evidence

- Godot 4.7.2 imported the prepared images with exit code 0. Native log: `artifacts/wireframe-import-native.log`.
- Fourteen real Godot scenes captured at 1280×960 and 2560×1920, with exit code 0 and no errors in `artifacts/wireframe-capture.log`. No test suite was added or run.
- Inspected isolated room, north/south and east/west passages, closed 17-cell room, corner-corridor joins and 5x5 vertical-corner joins. Source geometry uses the same height vector everywhere. User visual acceptance remains pending.
- A read-only code reviewer inspected the new catalogue, selection, placement, scene settings and seven enlarged captures: no Critical/Important findings. Its minor suggestion to distinguish intentionally empty states from missing catalogue entries was applied.
- Capture-helper teardown initially resized a viewport while a queued scene still had its resize callback connected. The helper now frees the detached scene before resizing; subsequent capture logs are clean.
- A transparent four-pixel floor-image gutter retains the complete source top-edge stroke. Imported mipmaps and linear mipmap filtering keep narrow lines visible when the whole dungeon is reduced on screen; the grid pitch and original joint positions do not move.
