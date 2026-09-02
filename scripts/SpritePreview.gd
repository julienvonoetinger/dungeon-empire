extends Control

const PACK := [
	["wrap_rock", "res://assets/sprites/wrap_rock.png"],
	["wrap_floor", "res://assets/sprites/wrap_floor.png"],
	["entrance", "res://assets/sprites/tile_entrance.png"],
	["core", "res://assets/sprites/tile_core.png"],
	["door", "res://assets/sprites/tile_door.png"],
	["door_damaged", "res://assets/sprites/tile_door_damaged.png"],
	["vault", "res://assets/sprites/tile_vault.png"],
	["vault_full", "res://assets/sprites/tile_vault_full.png"],
	["spike", "res://assets/sprites/tile_spike.png"],
	["snare", "res://assets/sprites/tile_snare.png"],
	["thief", "res://assets/sprites/hero_thief.png"],
	["paladin", "res://assets/sprites/hero_paladin.png"],
	["ranger", "res://assets/sprites/hero_ranger.png"],
	["corpse", "res://assets/sprites/prop_corpse.png"],
	["loot", "res://assets/sprites/prop_loot.png"],
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	var title := Label.new()
	title.text = "Sprite preview — Esc to quit. These are the PNG files, not the in-game board."
	title.add_theme_font_size_override("font_size", 18)
	grid.add_child(title)
	for i in range(3):
		grid.add_child(Control.new())
	for item in PACK:
		var box := VBoxContainer.new()
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(220, 220)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture = load(item[1]) as Texture2D
		var lab := Label.new()
		lab.text = item[0]
		box.add_child(tex)
		box.add_child(lab)
		grid.add_child(box)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
