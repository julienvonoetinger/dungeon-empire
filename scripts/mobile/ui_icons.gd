extends RefCounted

const KEYS := [
	GameTypes.Tool.DIG, GameTypes.Tool.BUILD_DOOR,
	GameTypes.Tool.BUILD_MAGIC_DOOR, GameTypes.Tool.BUILD_ENTRANCE,
	GameTypes.Tool.STORE, GameTypes.Tool.STORE_LOCKED,
	GameTypes.Tool.STORE_MAGIC, GameTypes.Tool.TRAP_SPIKE,
	GameTypes.Tool.TRAP_SNARE, GameTypes.Tool.TRAP_VOID, 10, 11,
]

static func load_icons() -> Dictionary:
	var atlas: Texture2D = load("res://assets/mobile/ui-menu-atlas-v2.png")
	var cell := atlas.get_size() / Vector2(4, 3)
	var icons := {}
	for index in KEYS.size():
		var icon := AtlasTexture.new()
		icon.atlas = atlas
		icon.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
		icon.filter_clip = true
		icons[KEYS[index]] = preload("res://scripts/mobile/menu_icon.gd").centered(icon)
	icons[GameTypes.Tool.TRAP_SPIKE] = preload("res://scripts/mobile/menu_icon.gd").centered(load("res://assets/mobile/spikes-menu-v3.png"))
	icons[GameTypes.Tool.TRAP_SNARE] = preload("res://scripts/mobile/menu_icon.gd").centered(load("res://assets/mobile/snare-claw-menu-v1.png"))
	return icons

static func load_badge_icons(menu_icons: Dictionary) -> Dictionary:
	var icons := menu_icons.duplicate()
	icons[GameTypes.Tool.TRAP_SPIKE] = load("res://assets/mobile/spikes-badge-v1.svg")
	icons[GameTypes.Tool.TRAP_SNARE] = load("res://assets/mobile/snare-badge-v1.svg")
	icons[GameTypes.Tool.TRAP_VOID] = load("res://assets/mobile/void-badge-v1.svg")
	icons[GameTypes.Tool.BUILD_DOOR] = load("res://assets/mobile/lock-badge-v1.svg")
	icons[GameTypes.Tool.BUILD_MAGIC_DOOR] = load("res://assets/mobile/crystal-badge-v1.svg")
	icons[11] = icons[GameTypes.Tool.BUILD_MAGIC_DOOR]
	return icons
