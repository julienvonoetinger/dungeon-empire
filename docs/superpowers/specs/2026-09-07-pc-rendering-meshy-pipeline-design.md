# PC Rendering and Meshy Pipeline Design

## Objective

Bring the Godot dungeon view materially closer to the canonical Art Bible on PC, then make the existing Meshy API workflow safe, resumable, and manifest-driven. Gameplay behavior remains unchanged.

The canonical visual sources, in priority order, remain the validated individual production images, `art_bible/ART_BIBLE.md`, and the production manifests.

## Scope

This work has two sequential deliverables:

1. a PC-quality Godot rendering baseline demonstrated in an isolated reference scene and reused by the live dungeon;
2. a guarded Meshy orchestration tool built on the existing API clients.

Mobile optimization, new gameplay, world-map implementation, and wholesale generation of every missing 3D model are outside this design.

## Rendering baseline

### RenderLab

Create a standalone `RenderLab.tscn` that does not depend on simulation state. It contains a representative controlled floor, two walls meeting at a corner, a pillar, a torch, a full storage object, the Dungeon Core, and one hero. It uses the same camera orientation and rendering profile as the live game.

The scene is the visual calibration target. A capture tool renders it at a stable resolution and camera transform so lighting or material changes can be reviewed against the Art Bible without the noise of a full procedural dungeon.

### Render profile

Create a reusable Godot resource, `DungeonRenderProfile.tres`, with a small script-backed schema for:

- neutral ambient color and energy;
- cool key-light color, energy, angle, and shadow settings;
- warm practical-light color, energy, range, and maximum active count;
- Core/influence light color, energy, and range;
- exposure and filmic tonemapping;
- SSAO, glow, fog, and shadow-quality settings supported by the PC renderer;
- emission multipliers for stone influence, void effects, and flame effects.

Both `RenderLab` and `DungeonWorld` consume this resource. Rendering constants must not be duplicated between them.

### Renderer and camera

The PC project uses Godot Forward+ as its primary renderer. The existing orthographic camera remains, with approximately 40 degrees pitch and 45 degrees yaw. The camera settings are shared with `RenderLab` so the reference and gameplay views stay comparable.

The migration must preserve picking behavior and viewport sizing. The existing headless gameplay tests remain authoritative for camera-to-grid interaction.

## Models and materials

### Model normalization

Runtime model placement uses uniform scale only. Models may be translated and rotated, but the renderer must not independently stretch X, Y, and Z to force an asset into a cell.

A model validator reports:

- missing or unreadable GLB files;
- empty geometry bounds;
- dimensions outside the configured family envelope;
- non-bottom pivots where a bottom pivot is required;
- unexpected orientation;
- missing material surfaces.

Assets that fail validation are reported rather than silently distorted. Existing fallbacks may remain temporarily for missing models.

### Material families

Materials follow five explicit roles:

- dungeon stone: anthracite and blue-gray, high roughness, no emission;
- influence: restrained violet accents with moderate local emission;
- wealth: warm gold/brass with metallic response and no broad emission;
- void: near-black body plus separate halo/VFX;
- flame: emissive warm element plus a bounded practical light.

Imported Meshy materials may be adapted per family, but identity-bearing colors, ornaments, and textures must be preserved. Purple must not be applied as a global material tint.

### Floors and influence

Ordinary controlled floor uses continuous simple geometry and the canonical seamless floor texture. It is not represented by one detailed Meshy floor model per grid cell.

Violet fissures and strong-influence areas are separate sparse decals, overlay meshes, or VFX. They do not turn every floor tile into an emitter.

## Lighting

The live dungeon and `RenderLab` use the same hierarchy:

1. a low-energy, nearly neutral ambient source prevents unreadable black areas;
2. a soft cool directional key reveals silhouettes and bevels;
3. a limited set of warm torch lights adds local contrast and shadows;
4. one bounded violet light supports the Core and selected supernatural structures.

The current light-per-floor-cell behavior is removed. Lights are assigned by visual importance and culled or pooled to a profile-defined maximum. Opaque primary meshes cast and receive shadows. Tiny particles, transparent overlays, markers, and additive effects do not cast shadows.

## Runtime rendering structure

`DungeonWorld` remains the public rendering facade used by `Main`, but delegates visual construction to focused helpers:

```text
DungeonWorld
├── FloorRenderer
├── WallRenderer
├── PropRenderer
├── CoreRenderer
└── CharacterRenderer
```

The helpers own presentation only. They do not mutate simulation, raid, economy, pathfinding, or build rules. `DungeonWorld.sync(game)` may continue reading the game facade and translating state into renderer inputs.

The extraction is limited to code touched by the rendering work; unrelated refactoring is excluded.

## Meshy orchestration

### Existing clients

The existing `meshy_image_to_3d.py` and `meshy_image_to_image.py` retain responsibility for Meshy HTTP requests, authorization, task polling, and downloads. Shared request behavior is made importable without changing their supported direct CLI usage.

### Manifest-driven orchestrator

Add an orchestrator that selects one explicit manifest entry or an explicit list. It never submits the entire manifest merely because no selector was provided.

Task states are:

```text
pending -> submitted -> processing -> downloaded -> validated
                              \-> failed
```

Dry-run is the default. A distinct execution flag is required before any paid API submission. Existing destination files are protected unless the user also supplies `--force`.

Before submission, the orchestrator validates that:

- the manifest entry exists;
- the source image exists and is non-empty;
- the source is not marked `2d_only_not_for_meshy`;
- the requested destination stays under the repository's approved model directory;
- parameters are within configured limits.

### Resumption journal

Store task metadata in a Git-ignored local journal. Each record contains:

- stable asset identifier;
- source path and content hash;
- Meshy task identifier;
- non-secret generation parameters;
- intended destination;
- current state and progress;
- consumed credits when returned by Meshy;
- timestamps and a sanitized error summary.

The journal never stores the API key, authorization headers, source data URIs, signed download URLs, or full API payloads that may contain sensitive temporary data.

If a matching submitted task exists for the same source hash and parameters, the orchestrator resumes it instead of submitting a duplicate.

### Safe download and validation

Download into a temporary sibling file. Validate before installation:

- non-zero length;
- GLB magic header and declared length;
- parseable container structure;
- at least one mesh when practical with the available local tooling.

Only a validated file is atomically moved into `assets/models`. Failed or incomplete downloads never replace an existing model.

## Error handling

Errors use concise actionable messages and non-zero exit codes. Network failures, authentication failures, Meshy task failures, canceled tasks, malformed responses, timeouts, invalid downloads, and destination conflicts are distinguished.

Interrupted processing preserves the task ID and journal state. Retrying resumes the known task. A new paid submission requires either changed source/parameters or an explicit resubmit action.

## Verification

### Godot

- Existing `tests/smoke.gd` passes unchanged in behavior.
- Focused tests cover uniform scale calculations and render-profile limits where possible without a GPU.
- Godot loads `RenderLab.tscn` and the main scene without resource errors.
- An automated stable-resolution RenderLab capture is produced for manual Art Bible comparison.
- The live dungeon contains no light per ordinary floor cell.
- Camera picking remains correct after the renderer migration.

### Meshy

Network-free tests use mocked API responses and temporary directories to cover:

- valid and invalid manifest entries;
- rejection of 2D-only assets;
- dry-run behavior;
- protection of an existing GLB;
- successful submission and download;
- interrupted-task resumption;
- failed or canceled tasks;
- absent credentials;
- malformed or truncated GLB data;
- sanitized journal contents.

No test performs a paid Meshy submission.

## Delivery order

### Phase 1: PC rendering baseline

1. Add the render profile and RenderLab scene.
2. Migrate the project to Forward+.
3. Establish the lighting and environment baseline.
4. Introduce continuous floor rendering and sparse influence overlays.
5. Enforce uniform runtime model scale.
6. Apply the profile to the live dungeon.
7. Capture and review the reference scene.

### Phase 2: Meshy pipeline

1. Refactor existing API helpers for safe reuse.
2. Add manifest selection and validation.
3. Add dry-run and overwrite guards.
4. Add the resumable sanitized journal.
5. Add atomic GLB download and validation.
6. Add network-free tests and usage documentation.

## Success criteria

The work is complete when:

- the RenderLab capture visibly follows the Art Bible's cold readable stone, warm wealth/torch contrast, and restrained violet influence;
- the live dungeon uses the same profile without changing gameplay or picking;
- ordinary floor tiles no longer create individual lights;
- runtime models are never non-uniformly distorted to fit cells;
- existing gameplay smoke tests pass;
- a Meshy asset can be dry-run, submitted explicitly, interrupted, resumed, validated, and installed without exposing secrets or accidentally replacing an existing model;
- all Meshy pipeline tests run without consuming API credits.
