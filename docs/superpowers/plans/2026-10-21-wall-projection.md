# Coherent wall projection and separate outside edges

> Execution: superpowers:executing-plans, in the existing workspace.

**Goal:** Correct the current wall/pier perspective against the original art and
separate exterior backing from wall cores, as explicitly requested by the user.

**Architecture:** Complete native-alpha sprites, shared anchors and consistent
south-facing height. Place independent exterior strips only where exposed; stop
them beneath corner piers and horizontal wall junctions. No bitmap cutouts.

**Spec:** Latest user screenshots and GAME_DESIGN.md art/transparency rules.

**Status — rejected visual result, 2026-10-21:** The user rejected both the
side-wall assembly and the resulting room. Native transparency and independent
exterior layers are present, but separately generated cap blocks, upright piers
and thin packing pieces do not share a coherent apparent volume. Floor art has
also drifted from the reference. Do not mark this plan complete based on passing
technical checks. Reconsider the assembly approach and establish one coherent
wall/corner/floor study against the original before another map-wide revision.

Latest acceptance criteria: same wall elevation and masonry around the entrance
and elsewhere; staggered floor/masonry joints without recurring vertical seams;
separate exterior art covers the actual exposed perimeter including junctions.
For the art study the user explicitly prioritizes direct visual comparison and
asks to set probes aside. Produce a small assembled study from coherent native
alpha assets and inspect its real rendered capture against the original.

Study produced: `ReferenceCalibration.tscn`, six actual Sprite2D elements and
two lights. It uses a connected north/east architectural module, separate floor,
exterior layer and door, with the existing torch sprite. The first floor patch
was visibly too wide/brick-like and was replaced by v2. The comparison still
serves as an art review, not approval. No six-room rollout has been performed.

Door follow-up: the user identified its overly frontal appearance in the study.
Generated entrance-v2 from the original, v1 and the assembled scene: upper arch
depth, inner reveals, recessed wooden leaf and visible threshold. Replaced only
the study door, keeping uniform scale 0.232 and front feet near y=225. Actual
Godot captures at normal scale and 2x, plus original/before/after comparison,
were inspected. The full study and six-room correction remain unapproved.

Door integration follow-up: the user requested projecting jamb feet/threshold
and fitted wall pieces on both sides. The continuous wall was replaced in the
study by complete native-alpha left/right returns. Door scale is now 0.25 at
(112,11): feet reach about y=247 over the continuous slabs, beyond the y=225 wall
foot. Door and wall now receive the same torch lighting. The left return was
regenerated narrower to leave the recessed leaf area fully open. Captures show
the opening with the arch hidden, plus original/before/current and 2x views.
The focused capture regression checks opening coverage, feet on floor, complete
uniformly scaled sprites and missing resources. This remains a study-only change;
the main scene has not been promoted to these assets.

Subsequent rejection: even with an opening, the separate arch still read as
pasted onto the facade. Replaced that architecture in the study with a single
native-alpha masonry module bonding the wall courses into the arch. Only the
wooden leaf is separate, behind the inner reveals and threshold. The corner
module no longer includes the north facade hidden behind the entry. The leaf
was regenerated with broader proportions to fit its aperture; the narrow first
leaf draft cropped out its wooden crown when positioned behind the arch.
The smaller torch scale 0.36 is retained. Door-masonry comparison shows the last
rejected assembly beside the current Godot render and original reference.
This changes the study assembly, not the main six-room scene or approval status.

Door proportion follow-up: the user rejected the broad doorway. Regenerated the
masonry as v3 and wooden leaf as v3, keeping the common masonry architecture,
native alpha, projected feet and small torches. The measured aperture changes
from 118 x 113 to 107 x 119 px. Leaf scale is 0.145 at (219,40), masonry remains
0.44 at (27,-86). The proportion regression reproduced the old square opening
failure, then passed with the selected assets. Normal and 2x Godot captures
and original/before/current comparison were inspected. This is still an
unapproved study; the broader reference-fidelity tasks below remain open.

- [ ] Reproduce combined-sidewall regression and add exterior-edge topology checks.
- [ ] Generate coherent complete wall/core/edge/pier sprites from original reference.
- [ ] Integrate independent layers, preserve six-room floor/door/heart anchors.
- [ ] Inspect normal and 2x captures, including entrance/right-room comparison.
- [ ] Run full capture suite; update design, instructions and provenance.
- [ ] Fresh review, address findings, present actual Godot capture.

Ruling: retain palette, floor layout, entrance/heart fixtures and existing project;
replace only masonry art and assembly needed for this perspective correction.
Ruling: never treat spatial/alpha passing tests as artistic approval.
Ruling: the initial combined-side sheet was superseded by the user's explicit
request to separate exterior strips; it will not become a runtime dependency.
