Surface entrance — wireframe review, 2026-11-04

User rejects the glowing portal and asks for destruction of the rock followed
by real stairs. User then requests geometry integration BEFORE texture work,
rejects the oblique multi-cell draft, accepts the grid-aligned single-cell
direction, and asks for TWO cells with side walls and a stone arch, like the
attached reference. This folder describes that latest geometry-only proposal.

scenes/previews/SanctuaryStairwellWireframe.tscn is the review scene.
It reuses SanctuaryWireframe, removes Paroi4 in the after state, and displays
an entrance in cells(-3,-5),(-3,-4). First tread z=0; one continuous flight
has10treads at0,-.05,...,-.45; landing at-.5. Width1cell,
length2cells. No screen skew or different camera. Side walls rise .07 above
ground; arch has radius .36 inside/.5 outside, spring-.05, base-.5. The inner
opening has no closing face. Underground geometry/void are clipped at the
ground opening; above-ground masonry remains visible. Gold outline marks
the two-cell footprint; no construction line crosses the treads.

Preview-only layout adjustments: Paroi8 shifted+256screen-X and Eboulis13
shifted+128screen-X to clear the entry/view. They apply to both before/after
states. Runtime introduction and accepted apparition remain unchanged while
this wireframe is reviewed. No destruction animation or new texture applied.

Recipe: node tools/export_invocation_stairwell_wireframe.cjs
Uses the dungeon's existing 2:1 projection and .05 riser height.
Source and exported geometry retained here; original art is not repainted.
Rejected oblique generator/geometry retained with rejected-oblique prefix.
The earlier textured block in ../stairwell and its prepare script is a rejected
draft; it is NOT used by this wireframe or by the runtime scene.

Native check: artifacts/sanctuary-procession/check_stairwell_wireframe.gd.
Checks actual grid footprint, equal .16 tread depths/.05 risers, descending
elevations, open end, neighbouring rock footprints, before/after reset and
full framing at1280x800,390x844,844x390. Pass/empty stderr. Captures in the
same artifacts directory. This is geometry review, not gameplay integration,
hero traversal validation, or a final texture/animation approval.

Continuous-step correction: joining two stock flights repeated their wider
first tread (.218 versus .134667), creating two irregular steps. Uniform-run
regression fails on that version. Current single surface has10equal .16 treads,
no internal box faces, no intermediate landing and an exact join to the bottom
landing. Before generator/capture retained. Native checks pass/empty stderr;
landscape/portrait/detail captures refreshed.
