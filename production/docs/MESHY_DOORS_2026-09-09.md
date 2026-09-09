# Meshy wall doors — 9 September 2026

## Visual direction

The previous runtime doors used monumental arched stone bases with several
large violet gems. At gameplay distance the whole asset read as a freestanding
slab placed inside a floor cell rather than a door built into the wall.

The active `wall_v2` family is a compact rectangular wall module. Its jambs
and lintel use the same broad rounded anthracite blocks as the controlled wall
kit. The center uses two weathered charcoal wood leaves with broad forged-iron
braces. One small violet keystone carries the controlled-dungeon identity.
A shallow single-row threshold meets the 1x1 paver floor.

Four state references were made from one canonical design:

- closed: both leaves meet at a clear center seam;
- open: the same leaves fold back against the jambs;
- damaged: a readable breach and bent braces, while passage remains blocked;
- destroyed: leaves collapse into low debris and the passage is visibly clear.

The source PNGs are in `production/meshy_assets/doors/wall_v2/`. The four
textured Meshy GLBs are in `assets/models/doors/wall_v2/`. Manifest records use
the `door_wall_v2` family, Meshy `meshy-t2`, smart topology and a 6,500 polygon
target. Local task IDs, credit use and validation records remain in the ignored
`.meshy/tasks.json` journal.

## Runtime fit

Every state is fitted independently to the same architectural volume:

- width: 0.98 cell;
- height: from the floor surface at Y=0.16 to the wall top at Y=1.12;
- depth: 0.28 cell, close to the 0.22 wall thickness.

A neutral wrapper applies this fit outside Meshy's imported root transform.
Door bounds use forward `Transform3D * AABB` composition so translated source
nodes remain measured correctly. The destroyed state no longer displays a
large `broken` label because the open geometry already communicates passage.

## Verification

- `tests/meshy_door_fit_test.gd` checks all four paths and exact fitted bounds.
- `tests/labyrinth_integration_test.gd` checks placement, blocking, damage and
  destruction through natural raids.
- `tools/capture_meshy_doors.gd -- --capture` renders closed, damaged and
  destroyed states in the constructed labyrinth.
