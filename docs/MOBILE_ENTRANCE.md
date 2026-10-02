# Wall-mounted mobile entrance

Approved design: a graphite stone arch embedded into the room perimeter,
dark stair tunnel, flush threshold, and small torch brackets. The arch remains
visible when ordinary walls are hidden.

## Placement and migration

- Placement requires FLOOR, a solid backing (ROCK or map edge), and a walkable
  cell immediately in front. Open room centers are rejected by the simulation,
  so mobile previews and commits use the same rules.
- The mouth prefers a valid wall-facing direction. Legacy mouth selection is
  retained for manually authored invalid layouts pending migration.
- Rock directly adjacent to an entrance is protected from excavation to keep
  its backing and orientation stable.
- Starter entrance moved from (3,10) to (2,10), facing into the same room.
- Mobile save restore relocates an invalid entrance to the nearest connected
  FLOOR with valid backing/front, using a deterministic breadth-first search.
  Paid structures, gold, health and progression are preserved. Knowledge of
  the old/new entrance cells is invalidated. Migration is idempotent and does
  not change the version-1 save format.
- If no legal floor exists, the old entrance becomes FLOOR and placement stays
  free; a simulation message explains the missing entrance. No rock is dug and
  no paid structure is overwritten to force migration.

## Visuals

### Current renderer (0.2.3)

The world entrance is now a cached volumetric masonry arch with individual
extruded stones, an open center, four real steps and a recessed dark end.
Two wall_torch_emberstone.glb instances use the exact same fitting helper as
wall fixtures. The old frontal sprite is no longer drawn in the world.
The existing illustration remains the toolbar icon only.

Mobile wall spans leave the entrance's backing face open and split adjacent
paired spans so masonry cannot fill the tunnel. Ordinary torch models on
the entrance cell are hidden to avoid duplicates, but their budgeted lights
are retained. The arch and its attached torches remain visible when walls
are hidden. Hero ground and placement/save rules are unchanged.

### Previous renderer (0.1.7)

scripts/world/mobile_entrance.gd uses a shared 1024px mipmapped alpha texture
on a fixed vertical plane plus one cached stone backing mesh. No billboard,
no per-frame image allocations. The entrance front faces the passage; from
behind it appears as solid stone. Hero ground stays at FLOOR_H, not at the
top of the backing mesh. The toolbar uses the same arch texture.

Generated with the built-in image tool. Production prompt: front orthographic
graphite stone arch, transparent exterior, opaque dark stair tunnel, three
worn rising steps, two restrained torch brackets, no surrounding floor or
wall wings, neutral stone lighting, reference-matched stylized finish.
Source: exec-1de8f795-329f-4f33-ad55-498d4cb1a4f6.png from this task's
generated_images folder; copied to assets/mobile/entrance-arch-v2.png.
Approved concept: exec-8468e9a4-b9cc-492b-9961-51c0768e8e9a.png.

## Verification

tools/capture_entrance.gd captures both wall modes at four camera angles on
Vulkan PC, then a real spawned hero and a moved hero at 960x540. Headless tests
cover placement, support protection, starter connectivity, migration,
fixed orientation, texture alpha/budget and floor-level hero positioning.
APK 0.1.7-entrance remains Vulkan. Pixel performance requires device testing;
this change does not claim to fix the OpenGL crash.
