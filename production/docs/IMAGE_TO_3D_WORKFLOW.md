# Image → Meshy → Godot Workflow

## 1. Generate the canonical image
Generate exactly one isolated asset. Never generate a sheet.

For a family with several states, create or choose one `*_reference.png` first.

## 2. Generate state images by editing the canonical reference
Do not ask for a new object "in the same style".
Use the canonical reference and change only the gameplay state.

Examples:
- Door `closed -> open`: same frame and door leaves, only hinge rotation changes.
- Door `destroyed`: same identity but broken geometry; usually a separate mesh.
- Chest `closed -> open`: same chest and hinge.
- Chest `empty -> full`: keep the same chest and add/remove a detachable treasure-content mesh.
- Trap `armed -> triggered`: animate the same mechanism when possible.
- Core states: same void anomaly identity; vary damage/fragments/VFX only.

## 3. Meshy
Prefer one 3D model when state changes can be animated or toggled:
- opening doors/chests;
- extending/retracting spikes;
- watcher rotation/beam;
- visibility of treasure contents.

Create separate 3D variants when topology is genuinely destroyed:
- destroyed doors;
- broken traps;
- destroyed Core;
- destroyed structures.

## 4. Godot
Recommended pattern:

```text
AssetFamily.tscn
├── VisualRoot
│   ├── BaseMesh
│   ├── MovingParts
│   ├── DamageVariant
│   └── Contents
├── AnimationPlayer
├── StateMachine
├── Collision
└── VFX
```

Do not encode every gameplay state as a completely independent scene unless the topology requires it.
