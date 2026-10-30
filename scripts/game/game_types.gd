class_name GameTypes
extends Object

## Shared enums, economy, and presentation constants. No simulation.

enum Tile { ROCK, FLOOR, ENTRANCE, CORE, VAULT, SPIKE, SNARE, DOOR, VOID, MAGIC_DOOR }
enum Tool { DIG, STORE, TRAP_SPIKE, TRAP_SNARE, TRAP_VOID, BUILD_DOOR, BUILD_MAGIC_DOOR, BUILD_ENTRANCE, REPAIR, ABSORB, RESET, NONE, STORE_LOCKED, STORE_MAGIC }

const COLS := 16
const ROWS := 16
const RAID_DELAY := 25.0

const CORE_MAX := 100
const CORE_W := 1
const CORE_H := 1
const DOOR_MAX_HP := 60
const TRAP_MAX_CHARGES := 3
const VAULT_CAPACITY := 150
const START_GOLD := 320

const COST_DIG := 5
const COST_VAULT := 0
const VAULT_PROTECTION_COSTS := [0, 40, 80]
const COST_REPAIR_VAULT := 15
const COST_SPIKE := 35
const COST_SNARE := 30
const COST_VOID := 45
const COST_DOOR := 40
const COST_MAGIC_DOOR := 80
const COST_REPAIR_DOOR := 15
const COST_REPAIR_TRAP := 10

const DAMAGE_SPIKE := 30
const DAMAGE_SPIKE_PALADIN := 20
const DAMAGE_SNARE := 16

const TURN_TIME := 0.48
const SNARE_HOLD_TIME := 3.0
const TRAP_JUMP_TIME := 1.0
# Approved Vulpin recoil clip: recover on the struck tile before moving again.
const VULPIN_HURT_HOLD := .72
# Matches the 76-frame / 30 FPS Axe Spin Attack clip used by the Lithide paladin.
const CORE_STRIKE_HOLD := 76.0 / 30.0
# Matches the 181-frame / 30 FPS Collect Object clip used by the Vulpin thief.
const VULPIN_COLLECT_HOLD := 181.0 / 30.0
const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

const ROUTE_STEP := 1.0
const ROUTE_TRAP := 6.0
const ROUTE_DOOR := 2.5
const ROUTE_REVISIT := 1.5
const ROUTE_REVISIT_MAX := 6.0
const ROUTE_BIAS := 1.2

const TRAITS := {
	"Greedy": {"fear": -0.30, "trap": -0.20, "greed": 1.40, "flee": -0.08, "patience": 15},
	"Cautious": {"fear": 0.50, "trap": 0.40, "greed": 0.85, "flee": 0.10, "patience": -10},
	"Stubborn": {"fear": -0.20, "trap": -0.10, "greed": 1.00, "flee": -0.12, "patience": 35},
	"Cowardly": {"fear": 0.70, "trap": 0.50, "greed": 0.90, "flee": 0.15, "patience": -25}
}

static func is_trap_tile(t: int) -> bool:
	return t == Tile.SPIKE or t == Tile.SNARE or t == Tile.VOID

static func fixed_tool_cost(tool:int) -> int:
	# Only unconditional prices can signal poverty at catalogue selection.
	# DIG may clear for free; repair and vault upgrades depend on the structure.
	# Those are checked on the actual cell by report_rejected_action instead.
	return {Tool.TRAP_SPIKE:COST_SPIKE,Tool.TRAP_SNARE:COST_SNARE,
		Tool.TRAP_VOID:COST_VOID,Tool.BUILD_DOOR:COST_DOOR,Tool.BUILD_MAGIC_DOOR:COST_MAGIC_DOOR}.get(tool,0)

static func trap_max_charges(t: int) -> int:
	return 1 if t == Tile.VOID else TRAP_MAX_CHARGES

static func core_origin_cell() -> Vector2i:
	return Vector2i((COLS - CORE_W) / 2 - ((COLS - CORE_W) / 2) % CORE_W,
		(ROWS - CORE_H) / 2 - ((ROWS - CORE_H) / 2) % CORE_H)
