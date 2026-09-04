class_name GameTypes
extends Object

## Shared enums, economy, and presentation constants. No simulation.

enum Tile { ROCK, FLOOR, ENTRANCE, CORE, VAULT, SPIKE, SNARE, DOOR, VOID }
enum Tool { DIG, STORE, TRAP_SPIKE, TRAP_SNARE, TRAP_VOID, BUILD_DOOR, BUILD_ENTRANCE, REPAIR, ABSORB, RESET }

const TILE_W := 64
const TILE_H := 32
const DESIGN_SIZE := Vector2(1280, 720)
const ISO_ORIGIN_DESIGN := Vector2(512, 76)
const COLS := 20
const ROWS := 12
const RAID_DELAY := 25.0

const CORE_MAX := 100
const CORE_W := 2
const CORE_H := 2
const DOOR_MAX_HP := 60
const TRAP_MAX_CHARGES := 3
const VAULT_CAPACITY := 150
const START_GOLD := 320

const COST_DIG := 5
const COST_VAULT := 60
const COST_SPIKE := 35
const COST_SNARE := 30
const COST_VOID := 45
const COST_DOOR := 40
const COST_REPAIR_DOOR := 15
const COST_REPAIR_TRAP := 10

const TURN_TIME := 0.48
const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

const ROUTE_STEP := 1.0
const ROUTE_TRAP := 6.0
const ROUTE_DOOR := 2.5
const ROUTE_REVISIT := 1.5
const ROUTE_REVISIT_MAX := 6.0
const ROUTE_BIAS := 1.2

const TOOLBAR_MARGIN := 78
const BTN_X := 16
const BTN_GAP := 8.0
const BTN_H := 52.0

const CORPSE_OFFSET := Vector2(-8, 8)
const BAG_OFFSET := Vector2(9, -7)
const CLICK_RADIUS := 14.0
const ZOOM_MIN := 0.45
const ZOOM_MAX := 6.0
const ZOOM_DEFAULT := 1.35
const WORLD_RENDER_SCALE := 2.0
const YAW_DEFAULT := 45.0
const ORBIT_SPEED := 78.0
const ZOOM_STEP := 1.12
const HUD_TOP := 72.0
const PLAY_MARGIN := 28.0

const TRAITS := {
	"Greedy": {"fear": -0.30, "trap": -0.20, "greed": 1.40, "flee": -0.08, "patience": 15},
	"Cautious": {"fear": 0.50, "trap": 0.40, "greed": 0.85, "flee": 0.10, "patience": -10},
	"Stubborn": {"fear": -0.20, "trap": -0.10, "greed": 1.00, "flee": -0.12, "patience": 35},
	"Cowardly": {"fear": 0.70, "trap": 0.50, "greed": 0.90, "flee": 0.15, "patience": -25}
}

const C_ANTHRACITE := Color("#25232A")
const C_BLUE_GRAY := Color("#3B414C")
const C_MID_STONE := Color("#555765")
const C_PALE_STONE := Color("#858895")
const C_DEEP_VIOLET := Color("#40204F")
const C_INFLUENCE_PURPLE := Color("#683276")
const C_ARCANE_VIOLET := Color("#9B4DB5")
const C_ENERGY_MAGENTA := Color("#CE72DF")
const C_DARK_GOLD := Color("#80652A")
const C_WARM_GOLD := Color("#D4A83E")
const C_TREASURE_HIGHLIGHT := Color("#FFD878")
const C_FOREST_GREEN := Color("#56724C")
const C_MOSS_GREEN := Color("#819568")
const C_WARM_SAND := Color("#C9AC7A")
const C_VILLAGE_BEIGE := Color("#B99570")
const C_DANGER_RED := Color("#A74747")
const C_HOT_ORANGE := Color("#D9783C")
const C_TEXT := Color("#E8E6EC")
const C_BACKDROP := Color("#17161B")

const SPRITE_FILES := {
	"rock": "res://assets/sprites/tile_rock.png",
	"floor": "res://assets/sprites/tile_floor.png",
	"entrance": "res://assets/sprites/tile_entrance.png",
	"core": "res://assets/sprites/tile_core.png",
	"vault": "res://assets/sprites/tile_vault.png",
	"vault_full": "res://assets/sprites/tile_vault_full.png",
	"spike": "res://assets/sprites/tile_spike.png",
	"snare": "res://assets/sprites/tile_snare.png",
	"door": "res://assets/sprites/tile_door.png",
	"door_damaged": "res://assets/sprites/tile_door_damaged.png",
	"wrap_rock": "res://assets/sprites/wrap_rock.png",
	"wrap_floor": "res://assets/sprites/wrap_floor.png",
	"corpse": "res://assets/sprites/prop_corpse.png",
	"loot": "res://assets/sprites/prop_loot.png",
	"thief": "res://assets/sprites/hero_thief.png",
	"paladin": "res://assets/sprites/hero_paladin.png",
	"ranger": "res://assets/sprites/hero_ranger.png",
}

static func is_trap_tile(t: int) -> bool:
	return t == Tile.SPIKE or t == Tile.SNARE or t == Tile.VOID

static func trap_max_charges(t: int) -> int:
	return 1 if t == Tile.VOID else TRAP_MAX_CHARGES

static func toolbar_defs() -> Array:
	return [
		{"tool": Tool.DIG, "label": "Dig", "cost": "5"},
		{"tool": Tool.STORE, "label": "Storage", "cost": "60"},
		{"tool": Tool.TRAP_SPIKE, "label": "Spikes", "cost": "35"},
		{"tool": Tool.TRAP_SNARE, "label": "Snare", "cost": "30"},
		{"tool": Tool.TRAP_VOID, "label": "Void", "cost": "45"},
		{"tool": Tool.BUILD_DOOR, "label": "Door", "cost": "40"},
		{"tool": Tool.BUILD_ENTRANCE, "label": "Entrance", "cost": "free"},
		{"tool": Tool.REPAIR, "label": "Repair", "cost": "15 / 10"},
		{"tool": Tool.ABSORB, "label": "Absorb", "cost": "+2 Core"},
		{"tool": Tool.RESET, "label": "Reset", "cost": ""}
	]
