Rigged Oculin shadow deity supplied 2026-11-04

Original GLB archived byte-for-byte under source/, with SHA256 and original
path in source/provenance.json. No game/runtime or earlier prototype changed.
Run prepare.py with Python, then inspect.py with background Blender 5.2 and
--python-exit-code 1. Dedicated scene, no live Blender session modified.

Inspection: 58 bones, 14640 body vertices, 10446 triangles, one UV layer,
three packed 2048x2048 images. All body vertices have weights. All 58 bones
produce measured deformation under an eight-degree local X probe and restore.
No animation clips and no shape keys supplied. Bone names/hierarchy, rest
head/tail coordinates, displacement and restoration errors in inspection.json.
The importer creates an Icosphere custom bone shape: exclude bone custom-shape
objects from body bounds, weight counts and geometry checks, not from the rig.

Four static renders and a packed inspection blend preserve original painting,
mesh and UVs. Source SHA256 and geometry/UV fingerprint checked before/after.
Front and isometric appearance reviewed. Tests establish deformation response,
not anatomical rig suitability, collision-free animation or facial expression
control. No invocation animation or sanctuary integration completed here.
