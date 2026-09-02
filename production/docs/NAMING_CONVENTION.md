# Naming Convention

Use lowercase `snake_case`.

## Image reference
`<category>/<family>/<family>_<state>.png`

Examples:
- `doors/standard/door_standard_closed.png`
- `storage/vault_chest/vault_chest_open_full.png`
- `traps/grasp/trap_grasp_active.png`
- `core/core_critical.png`

## 3D models
`models/<category>/<family>.glb`

Create state-specific GLBs only when topology changes:
- `door_standard_destroyed.glb`
- `trap_spines_broken.glb`

## Canonical reference
Every multi-state family should have:
`<family>_reference.png`

All future states must be produced by editing that canonical reference.
