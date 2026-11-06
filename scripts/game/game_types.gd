class_name GameTypes
extends Object

## Shared enums, economy, and presentation constants. No simulation.

enum Tile { ROCK, FLOOR, ENTRANCE, CORE, VAULT, SPIKE, SNARE, DOOR, VOID, MAGIC_DOOR, REINFORCED_DOOR }
enum Tool { DIG, STORE, TRAP_SPIKE, TRAP_SNARE, TRAP_VOID, BUILD_DOOR, BUILD_MAGIC_DOOR, BUILD_ENTRANCE, REPAIR, ABSORB, RESET, NONE, STORE_LOCKED, STORE_MAGIC, BUILD_REINFORCED_DOOR }

# Existing numeric values are stored in saves.
enum Lesson { FREE, DOOR, ALCOVE, CHEST, MEET_MINER, MEET_CARPENTER, MEET_SCIENTIST, SPIKES, VILLAGE_GIFT, INVOKER_OFFER }
const FIRST_STAIR := Vector2i(3, 8)
const FIRST_DOOR := Vector2i(5, 8)
const FIRST_ALCOVE := Vector2i(6, 7)
const COUNCIL_INVOKER := Vector2(-.5, .23)
const COUNCIL_ARTISANS: Array[Vector2] = [Vector2(1.45,1.48), Vector2(.40,1.48), Vector2(-.65,1.48)]

const COLS := 16
const ROWS := 16
const RAID_DELAY := 25.0

const CORE_MAX := 100
const CORE_W := 1
const CORE_H := 1
const DOOR_MAX_HP := 60
const REINFORCED_DOOR_MAX_HP := 120
const TRAP_MAX_CHARGES := 3
const VAULT_CAPACITY := 150
const GOLD_BAG_CAPACITY := 50
const VILLAGE_BAG_COUNT := 2
const TREASURY_CAPACITY_BONUS := 300
const TREASURY_MEMBER_CAPACITY := VAULT_CAPACITY + TREASURY_CAPACITY_BONUS / 4
const START_GOLD := 320

const COST_DIG := 5
const COST_VAULT := 0
const VAULT_PROTECTION_COSTS := [0, 40, 80]
const COST_REPAIR_VAULT := 15
const COST_SPIKE := 35
const COST_SNARE := 30
const COST_VOID := 45
const COST_DOOR := 40
const COST_REINFORCED_DOOR := 60
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

static func capacity_per_chest(store: Array) -> int:
	return TREASURY_MEMBER_CAPACITY if store.size() == 4 else VAULT_CAPACITY

static func store_capacity(store: Array) -> int:
	return store.size() * capacity_per_chest(store)

static func is_trap_tile(t: int) -> bool:
	return t == Tile.SPIKE or t == Tile.SNARE or t == Tile.VOID

static func has_standard_door_lock(t: int) -> bool:
	return t == Tile.DOOR or t == Tile.REINFORCED_DOOR

static func is_door_tile(t: int) -> bool:
	return has_standard_door_lock(t) or t == Tile.MAGIC_DOOR

static func door_material(t: int) -> String:
	match t:
		Tile.DOOR: return "wood"
		Tile.MAGIC_DOOR: return "arcane"
		Tile.REINFORCED_DOOR: return "iron"
	return ""

static func door_max_hp(t: int) -> int:
	return REINFORCED_DOOR_MAX_HP if t == Tile.REINFORCED_DOOR else DOOR_MAX_HP

static func door_build_cost(t: int) -> int:
	return {Tile.DOOR: COST_DOOR, Tile.REINFORCED_DOOR: COST_REINFORCED_DOOR, Tile.MAGIC_DOOR: COST_MAGIC_DOOR}.get(t, 0)

static func fixed_tool_cost(tool:int) -> int:
	# Only unconditional prices can signal poverty at catalogue selection.
	# DIG may clear for free; repair and vault upgrades depend on the structure.
	# Those are checked on the actual cell by report_rejected_action instead.
	return {Tool.TRAP_SPIKE:COST_SPIKE,Tool.TRAP_SNARE:COST_SNARE,
		Tool.TRAP_VOID:COST_VOID,Tool.BUILD_DOOR:COST_DOOR,Tool.BUILD_REINFORCED_DOOR:COST_REINFORCED_DOOR,
		Tool.BUILD_MAGIC_DOOR:COST_MAGIC_DOOR}.get(tool,0)

static func trap_max_charges(t: int) -> int:
	return 1 if t == Tile.VOID else TRAP_MAX_CHARGES

static func core_origin_cell() -> Vector2i:
	return Vector2i((COLS / CORE_W / 2) * CORE_W, (ROWS / CORE_H / 2) * CORE_H)
