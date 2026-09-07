# PC Rendering Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a repeatable Forward+ PC rendering baseline that brings the live orthographic dungeon materially closer to the Art Bible without changing gameplay.

**Architecture:** A typed `DungeonRenderProfile` resource owns visual constants and configures a shared environment. A standalone `RenderLab` scene consumes the same profile as `DungeonWorld`; focused floor and model-fit helpers are extracted only where required to remove per-cell lights and non-uniform scaling.

**Tech Stack:** Godot 4.7.2, GDScript, Forward+, GLB/glTF assets, headless Godot smoke tests and deterministic PNG captures.

**Spec:** `docs/superpowers/specs/2026-09-07-pc-rendering-meshy-pipeline-design.md`

## Global Constraints

- Preserve all simulation, raid, economy, building, and picking behavior.
- The canonical Art Bible remains `art_bible/ART_BIBLE.md` and validated individual production images take precedence.
- PC uses Forward+; mobile optimization is outside this plan.
- Camera remains orthographic at approximately 40 degrees pitch and 45 degrees yaw.
- Ordinary floor cells must not create individual lights.
- Runtime model fitting uses uniform scale only.
- Purple is restricted to supernatural influence; warm light comes from torches and wealth remains warm gold/brass.
- Do not include `art_bible/references/canonical/artbook_low_poly_dungeon_empire.png` in implementation commits.

---

### Task 1: Introduce the typed render profile

**Files:**
- Create: `scripts/world/dungeon_render_profile.gd`
- Create: `assets/rendering/dungeon_render_profile.tres`
- Create: `tests/render_profile_test.gd`

**Interfaces:**
- Produces: `DungeonRenderProfile extends Resource`
- Produces: `func apply_to_environment(env: Environment) -> void`
- Produces: `func configure_key(light: DirectionalLight3D) -> void`
- Produces: `func configure_practical(light: OmniLight3D) -> void`
- Produces: `func configure_core(light: OmniLight3D) -> void`

- [ ] **Step 1: Write the failing profile test**

Create `tests/render_profile_test.gd` with a `SceneTree` harness that loads `res://assets/rendering/dungeon_render_profile.tres`, asserts it is a `DungeonRenderProfile`, asserts `max_practical_lights == 12`, applies it to a new `Environment`, and asserts ambient energy is below `0.30` and the background is not violet-dominant.

```gdscript
extends SceneTree

func _initialize() -> void:
    var profile = load("res://assets/rendering/dungeon_render_profile.tres")
    assert(profile is DungeonRenderProfile)
    assert(profile.max_practical_lights == 12)
    var env := Environment.new()
    profile.apply_to_environment(env)
    assert(env.ambient_light_energy <= 0.30)
    assert(env.background_color.b < 0.16)
    print("OK: render profile")
    quit()
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```powershell
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --script res://tests/render_profile_test.gd
```

Expected: failure because `DungeonRenderProfile` or the resource does not exist.

- [ ] **Step 3: Implement the profile class**

Define exported colors and numeric settings using Art Bible values. Set a neutral `#17161B` background, neutral-blue ambient light at energy `0.22`, filmic tonemapping, cool key light, warm practical light, restrained Core light, fog, glow, SSAO, and `max_practical_lights = 12`. Guard renderer-specific properties with the Godot 4.7 `Environment` API rather than string-based reflection.

- [ ] **Step 4: Create the canonical resource**

Create `assets/rendering/dungeon_render_profile.tres` as a resource of the new class. Keep all tunable values in this file; do not duplicate them in `DungeonWorld`.

- [ ] **Step 5: Run the focused test**

Expected: `OK: render profile` and exit code 0.

- [ ] **Step 6: Commit**

```powershell
git add scripts/world/dungeon_render_profile.gd assets/rendering/dungeon_render_profile.tres tests/render_profile_test.gd
git commit -m "Add shared dungeon render profile"
```

### Task 2: Create the RenderLab calibration scene

**Files:**
- Create: `scenes/render_lab/RenderLab.tscn`
- Create: `scripts/world/render_lab.gd`
- Create: `tests/render_lab_load_test.gd`

**Interfaces:**
- Consumes: `DungeonRenderProfile`
- Produces: loadable `res://scenes/render_lab/RenderLab.tscn`
- Produces: nodes named `Camera3D`, `Environment`, `CoolKey`, `CoreLight`, `Floor`, `Walls`, `Torch`, `Vault`, `Core`, and `HeroProxy`

- [ ] **Step 1: Write the failing scene-load test**

The test loads and instantiates the scene, checks every required named node, confirms the camera is orthographic, and confirms exactly one directional key and no more than 12 `OmniLight3D` descendants.

- [ ] **Step 2: Run it and verify the missing-scene failure**

Use the same Godot command as Task 1 with `res://tests/render_lab_load_test.gd`.

- [ ] **Step 3: Build the minimal scene**

Use existing runtime GLBs: controlled floor/stone assets, `wall_straight_meshy.glb`, `wall_pillar_meshy.glb`, `wall_torch_emberstone.glb`, `vault_skull_treasure.glb`, `core_void_nexus.glb`, and a temporary simple hero proxy because no shipped hero GLB is yet integrated. Arrange them as one compact isometric vignette with a stable camera transform.

- [ ] **Step 4: Apply the shared profile**

In `render_lab.gd`, load the profile once, configure the `Environment`, cool key, warm torch light, and bounded Core light. Do not add a violet light to the floor.

- [ ] **Step 5: Run the load test**

Expected: all named nodes found, orthographic camera confirmed, light budget respected.

- [ ] **Step 6: Commit**

```powershell
git add scenes/render_lab scripts/world/render_lab.gd tests/render_lab_load_test.gd
git commit -m "Add RenderLab calibration scene"
```

### Task 3: Switch the PC renderer to Forward+

**Files:**
- Modify: `project.godot`
- Modify: `tests/smoke.gd`

**Interfaces:**
- Produces: desktop setting `rendering/renderer/rendering_method = "forward_plus"`
- Preserves: mobile override `rendering/renderer/rendering_method.mobile = "gl_compatibility"`

- [ ] **Step 1: Add a failing project-setting assertion**

Add smoke assertions that the desktop rendering method equals `"forward_plus"` and the mobile override remains `"gl_compatibility"`. The installed Godot 4.7.2 executable has already accepted `--rendering-method forward_plus`, so the plan uses that verified identifier.

- [ ] **Step 2: Run smoke and verify the assertion fails on the current compatibility renderer**

Run `tests/smoke.gd`; expected failure names the current desktop renderer.

- [ ] **Step 3: Update the renderer setting**

Set the desktop renderer to the verified Forward+ identifier while preserving the mobile compatibility override. Do not alter viewport dimensions or stretch behavior in this task.

- [ ] **Step 4: Run smoke and RenderLab load tests**

Expected: both exit 0. Record any renderer warnings separately from assertion failures.

- [ ] **Step 5: Commit**

```powershell
git add project.godot tests/smoke.gd
git commit -m "Use Forward Plus for the PC renderer"
```

### Task 4: Replace per-cell lighting with the shared light rig

**Files:**
- Modify: `scripts/world/dungeon_world.gd:116-133`
- Modify: `scripts/world/dungeon_world.gd:776-793`
- Create: `tests/dungeon_lighting_test.gd`

**Interfaces:**
- Consumes: `DungeonRenderProfile`
- Produces: `func practical_light_count() -> int`
- Produces: one shared cool key, bounded warm practical lights, and one Core light

- [ ] **Step 1: Write a failing lighting regression test**

Instantiate `DungeonWorld`, build a map through the existing `Main` facade, call `sync`, recursively count lights, and assert that adding ten ordinary floor cells does not increase `OmniLight3D` count. Assert the world has one `DirectionalLight3D` and no more than the profile's practical-light maximum.

- [ ] **Step 2: Run it and confirm it fails because `_add_floor_light` creates one light per floor**

- [ ] **Step 3: Apply the render profile in `_make_environment`**

Load `DungeonRenderProfile`, configure the environment and cool key, and keep a single bounded Core light. Replace hard-coded violet ambient values.

- [ ] **Step 4: Remove ordinary floor lights**

Delete the `_add_floor_light(root)` call and its per-cell bookkeeping. Add warm lights only when a torch model is placed; enforce `max_practical_lights` deterministically by distance to the current camera target.

- [ ] **Step 5: Run lighting, RenderLab, and smoke tests**

Expected: stable light count and all existing behavior checks pass.

- [ ] **Step 6: Commit**

```powershell
git add scripts/world/dungeon_world.gd tests/dungeon_lighting_test.gd
git commit -m "Use a bounded dungeon lighting rig"
```

### Task 5: Add continuous floor rendering

**Files:**
- Create: `scripts/world/floor_renderer.gd`
- Modify: `scripts/world/dungeon_world.gd:526-604`
- Modify: `scripts/world/dungeon_world.gd:776-822`
- Test: `tests/floor_renderer_test.gd`

**Interfaces:**
- Produces: `FloorRenderer.sync_cells(open_cells: Array[Vector2i], cell_size: float) -> void`
- Produces: `FloorRenderer.surface_count() -> int`
- Consumes: `res://production/textures/floor/floor_controlled_seamless.png`

- [ ] **Step 1: Write a failing floor batching test**

Create four adjacent floor coordinates, call `sync_cells`, and assert one renderer-owned surface/root represents them and no lights are descendants. Verify repeated sync with identical cells does not recreate the mesh resource.

- [ ] **Step 2: Run it and verify failure because `FloorRenderer` is missing**

- [ ] **Step 3: Implement floor geometry generation**

Generate horizontal quads in world coordinates with UVs derived from cell coordinates so the seamless texture continues across cells. Use one material and one mesh per connected update, not one imported floor GLB per cell. Set roughness high, metallic near zero, and no emission.

- [ ] **Step 4: Delegate floor creation from `DungeonWorld`**

Collect all excavated non-rock cells during sync and pass them to `FloorRenderer`. Tile-specific structures remain separate. Remove ordinary `_add_fitted_floor` calls after the continuous surface is proven.

- [ ] **Step 5: Run floor, lighting, picking, and smoke tests**

Expected: one continuous UV field, no floor lights, unchanged cell picking.

- [ ] **Step 6: Commit**

```powershell
git add scripts/world/floor_renderer.gd scripts/world/dungeon_world.gd tests/floor_renderer_test.gd
git commit -m "Render dungeon floors as a continuous surface"
```

### Task 6: Enforce uniform model fitting and validation

**Files:**
- Create: `scripts/world/model_fit.gd`
- Create: `tools/validate_runtime_models.gd`
- Modify: `scripts/world/dungeon_world.gd:690-822`
- Modify: `scripts/world/dungeon_world.gd:975-1221`
- Test: `tests/model_fit_test.gd`

**Interfaces:**
- Produces: `ModelFit.uniform_scale(bounds: AABB, target_footprint: float) -> float`
- Produces: `ModelFit.place_on_floor(instance: Node3D, floor_y: float) -> void`
- Produces: validator exit code 0 only when all runtime GLBs load and contain geometry

- [ ] **Step 1: Write failing scale tests**

Assert that a `Vector3(2, 4, 1)` bound fitted to footprint `1.0` produces scalar `0.5`, and that every axis receives the same scalar. Add a zero-size bound test returning `1.0` with an explicit validation error.

- [ ] **Step 2: Run and verify `ModelFit` is missing**

- [ ] **Step 3: Implement `ModelFit`**

Centralize AABB traversal, scalar footprint fitting, centering in X/Z, and bottom placement. Return structured validation messages rather than silently applying non-uniform scale.

- [ ] **Step 4: Replace non-uniform floor/wall/pillar scaling paths**

Use `Vector3.ONE * scalar` for imported assets. Preserve intended rotations and positions. If an asset no longer fits, report its path and measured bounds; do not stretch it.

- [ ] **Step 5: Add the runtime-model validator**

Validate every GLB constant referenced by `DungeonWorld`; print path, dimensions, pivot result, and material count. Exit non-zero for missing or empty models.

- [ ] **Step 6: Run focused tests, validator, and smoke**

Expected: uniform scales, all referenced models load, gameplay tests pass.

- [ ] **Step 7: Commit**

```powershell
git add scripts/world/model_fit.gd tools/validate_runtime_models.gd scripts/world/dungeon_world.gd tests/model_fit_test.gd
git commit -m "Normalize runtime model fitting"
```

### Task 7: Add deterministic visual capture and final integration

**Files:**
- Create: `tools/capture_render_lab.gd`
- Modify: `tools/capture_entrance.gd`
- Modify: `README.md`
- Create: `artifacts/.gitignore`

**Interfaces:**
- Produces: `artifacts/render_lab.png`
- Produces: `artifacts/dungeon_baseline.png`

- [ ] **Step 1: Implement the RenderLab capture script**

Load the scene, wait for imports and three rendered frames, force a draw, capture the viewport at a fixed resolution, and save `artifacts/render_lab.png`. Exit non-zero if the image is null or smaller than the requested dimensions.

- [ ] **Step 2: Update the dungeon capture script**

Save to `artifacts/dungeon_baseline.png` rather than overwriting a runtime sprite. Keep camera, seed, zoom, and target deterministic.

- [ ] **Step 3: Document exact commands**

Add PowerShell commands using the Steam Godot executable for smoke tests, model validation, RenderLab capture, and dungeon capture.

- [ ] **Step 4: Run the full verification suite**

```powershell
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --script res://tests/render_profile_test.gd
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --script res://tests/render_lab_load_test.gd
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --script res://tests/dungeon_lighting_test.gd
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --script res://tests/floor_renderer_test.gd
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --script res://tests/model_fit_test.gd
& 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . --script res://tests/smoke.gd
```

Expected: every process exits 0 and smoke prints `OK: all checks pass.`

- [ ] **Step 5: Capture and inspect both images**

Confirm full silhouettes, readable anthracite stone, warm torch/wealth contrast, restrained violet, no per-cell purple wash, and no obvious floor seam. Record any remaining visual differences as follow-up work rather than changing gameplay.

- [ ] **Step 6: Commit**

```powershell
git add tools/capture_render_lab.gd tools/capture_entrance.gd README.md artifacts/.gitignore
git commit -m "Add deterministic rendering captures"
```
