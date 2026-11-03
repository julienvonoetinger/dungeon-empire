extends Control

const Game = preload("res://scenes/game/DungeonGame.tscn")
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const SANCTUM = preload("res://assets/ui/main-menu/core-sanctum.png")
const LOGO = preload("res://assets/ui/main-menu/dungeon-empire-logo.png")

var save_path := IsometricGameSession.launch_save_path()
var backdrop := TextureRect.new()
var logo := TextureRect.new()
var actions := VBoxContainer.new()
var message: Label
var primary: Button
var secondary: Button
var confirming := false
var resumable := false

func _ready() -> void:
	theme = UI.create()
	backdrop.texture = SANCTUM
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.texture = LOGO
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.accessibility_name = "Dungeon Empire"
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	add_child(actions)
	actions.add_theme_constant_override("separation",8)
	message = UI.label(actions,"",16)
	message.add_theme_constant_override("outline_size",5)
	message.add_theme_color_override("font_outline_color",Color("10121b"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	primary = UI.button(actions,"",_primary_pressed,"",true)
	secondary = UI.button(actions,"",_secondary_pressed)
	resized.connect(_layout)
	actions.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	_show_choices()

func _show_choices() -> void:
	confirming = false
	var occupied := FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak")
	var data := GameplaySave.read_save(save_path)
	resumable = not data.is_empty()
	message.visible = occupied and not resumable
	message.text = "La sauvegarde est illisible." if message.visible else ""
	primary.text = "Continuer" if resumable else "Nouvelle partie"
	secondary.text = "Nouvelle partie"
	secondary.visible = resumable
	primary.grab_focus()
	_layout()

func _primary_pressed() -> void:
	if confirming:
		_show_choices()
	elif resumable:
		_enter_game(false)
	else:
		_new_game()

func _secondary_pressed() -> void:
	if confirming:
		_enter_game(true)
	else:
		_new_game()

func _new_game() -> void:
	if not FileAccess.file_exists(save_path) and not FileAccess.file_exists(save_path+".bak"):
		_enter_game(true)
		return
	confirming = true
	message.text = "Remplacer le donjon sauvegardé ?"
	message.show()
	primary.text = "Annuler"
	secondary.text = "Remplacer le donjon"
	secondary.show()
	primary.grab_focus()
	_layout()

func _enter_game(fresh: bool) -> void:
	var session: IsometricGameSession = Game.instantiate()
	session.save_path = save_path
	session.get_node("HUD")._welcome = false
	if fresh:
		session.ready.connect(session.restart.bind(false), CONNECT_ONE_SHOT)
	if get_tree().change_scene_to_node(session) != OK:
		session.free()
		message.text = "Impossible d’ouvrir le donjon."
		message.show()
		_layout()

func _unhandled_input(event: InputEvent) -> void:
	if confirming and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_show_choices()

func _layout() -> void:
	if not is_inside_tree() or not is_instance_valid(primary) or size.x <= 0: return
	var pixels := Vector2(get_window().size)
	var density := clampf(DisplayServer.screen_get_dpi()/160.0,1,4) if OS.has_feature("mobile") else 1.0
	var unit := size.x/maxf(1,pixels.x)*density
	var safe := Rect2(Vector2.ZERO,size/unit)
	if OS.has_feature("mobile"):
		var area := Rect2(DisplayServer.get_display_safe_area()).intersection(Rect2(Vector2(get_window().position),pixels))
		if area.has_area(): safe = Rect2((area.position-Vector2(get_window().position))/density,area.size/density)
	var width := maxf(1,safe.size.x-32)
	var center := safe.get_center()
	var aspect := LOGO.get_size().aspect()
	var logo_width := minf(minf(width*.94,600),safe.size.y*.32*aspect)
	logo.size = Vector2(logo_width,logo_width/aspect)*unit
	logo.position = Vector2(center.x-logo_width/2,safe.position.y+safe.size.y*.045)*unit
	actions.scale = Vector2.ONE*unit
	actions.size = Vector2(minf(width,330),0)
	actions.size.y = actions.get_combined_minimum_size().y
	actions.position = Vector2(center.x-actions.size.x/2,safe.end.y-safe.size.y*.065-actions.size.y)*unit
