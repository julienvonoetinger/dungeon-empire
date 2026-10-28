# Door height and hardware — wireframe review

This is an isolated proposal awaiting the user's wireframe approval. The user
reported a door too small for the Vulpin, no readable keyhole, and no visible
hinges. Their latest instruction explicitly requires validating the wireframe
before painting or integration.

The low wall junctions and XY footprint are copied unchanged from accepted
`wireframe-v6-clean-leaf/geometry.json`. The upper arch is raised by 0.55 case;
three courses extend each post. The clear profile grows from 0.513 to 1.063
case. The current standing Vulpin is 0.852685 case tall at its unchanged .85
native scale. The first +.47 trial failed two running poses and is preserved
as `first-height-rejected.json`.

The leaf remains two smooth planes and perimeter faces, without plank, lock,
or hinge geometry. Gold marks in `hardware-review.svg` propose painted hinges
at X=.255, Z=.24/.70 and a keyhole at X=.5, Z=.275. The latter preserves the
existing lockpick tool contact; this is a visual placement proposal, not a
tested hinge mechanism or a swinging-door animation.

## Reproduce

From the repository root, using Node with `sharp` available:

1. `node tools/prepare_hero_scale_door.cjs`
2. `node tools/prepare_door_fit_preview.cjs`
3. Blender background: `--background --factory-startup --python-exit-code 1 --python tools/verify_hero_door_passage.py`
4. Godot: `--path . --script res://tools/capture_door_fit_wireframe.gd --rendering-method gl_compatibility`
5. `node tools/build_door_fit_review.cjs`

The Godot capture uses isolated resources, the real dungeon projection and
solid ordering, and real Vulpin SpriteFrames. `door_fit_review_stage.gd`
duplicates the catalogue before changing any entries. Native images use one
common scale and frame across revisions. No gameplay or save is instantiated.
The HTML displays native captures, with optional cycling of held poses.

## Evidence and limits

- `checks.json`: blank leaf, identical original junctions, size and markers.
- `passage-validation.json`: whole evaluated mesh in 17 held poses lies inside
  the convex XZ leaf profile; all fail the old profile. This is a conservative
  translational sweep through that opening, not continuous motion, self-
  collision, floor clearance, or future hinge-swing validation. Width is
  unchanged, with very little lateral margin (~.00003 case in a running pose).
  Crochetage is not a traversal pose: its wider arms remain in front of the
  door. Eight lockpick poses use a separate conservative triangle/plane test:
  clip each triangle to each masonry face's XZ bounding box and check its Y
  separation, excluding intentional tools. This tests triangle interiors too.
- `native/validation.json`: same .85 hero scale, 32 projected lock/tool contacts,
  64 held passage views, captures, no failures. Native inspection includes
  standing before/after, open passage, and ghost contact views. Masonry occludes
  the actor normally; ghost mode is only an inspection aid.
- `production-preserved.json`: production door code, catalogue and atlas hashes.
  Production artwork, main scenes, rules and player saves are untouched.

`source/paint-trial-not-integrated.png` and its prompt are an exploratory image
generated before the user reiterated wireframe-first. It is not approved, is
not mapped onto this geometry, and is not used in any review capture. It also
predates the final .55 height adjustment. Do not integrate it automatically.

No APK, commit or push is part of this review. Validate these proportions and
hardware placement with the user before preparing new production paint.
