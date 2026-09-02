# Godot Asset State Plan

## Standard Door
Use one base scene:
- frame mesh;
- left/right door leaves or a single hinged leaf;
- `closed` / `open` via AnimationPlayer;
- `damaged` may use a material/decal or alternate mesh;
- `destroyed` swaps to a destroyed mesh and disables blocking collision.

## Vault Chest
Use one base chest mesh:
- lid is a hinge node;
- `closed/open` is animation;
- treasure is a separate child mesh toggled for `empty/full`;
- `destroyed` swaps to a destroyed mesh.

This means four visual image states do **not** require four final 3D models.

## Spines Trap
- base plate + spike child nodes;
- `armed/triggered` use animation/translation;
- `broken` swaps to a damaged mesh.

## Grasp Trap
- floor base;
- supernatural hand below floor;
- `hidden/active` via animation;
- `broken` separate mesh.

## Void Trap
The portal itself should mostly be VFX/shader.
- base ring: static mesh;
- `inactive`: no/low VFX;
- `active`: portal shader/particles;
- `collapsed`: damaged ring mesh + residual VFX.

## Watcher
- statue/construct mesh;
- eye/head can rotate;
- alert/firing use VFX;
- destroyed uses alternate mesh.

## Dungeon Core
Treat the black void itself as VFX/shader, surrounded by a reusable stone assembly.
Damage states can progressively replace or hide stone fragments and adjust particles/emissive effects.
