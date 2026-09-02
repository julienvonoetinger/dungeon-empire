extends Control

# Prototype v0.2 — see GAME_DESIGN.md
# 3D orthographic dungeon (art bible: ~40° camera). Sim stays a 20×12 grid.
# Structural rules enforced here:
#  - two phases: preparation (everything editable) / raid (dungeon locked);
#  - persistent consequences: broken doors, spent traps, corpses, unsecured loot;
#  - dungeon wealth lives only inside storages (starter vaults around the Core);
#  - dead heroes leave loot on the body until the player stores it;
#  - a thief takes only what it can carry, then teleports out (no return trip);
#  - every hero rolls its own personality, so no dungeon is ever fully solved;
#  - the AI reasons on its partial knowledge, never on the real grid;
#  - no offline simulation: nothing advances while the application is closed.

# Logical grid is still COLS×ROWS. Presentation is 3D ortho ~40° / 45° yaw.
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
const COST_DOOR := 40
const COST_REPAIR_DOOR := 15
const COST_REPAIR_TRAP := 10

const TURN_TIME := 0.48
var PORTAL_HOLD := 1.15
const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

# What a hero believes a step through a cell costs. Traps and doors make a
# route expensive so an open detour wins whenever one exists, but they never
# veto it: a trapped corridor that is the only way on still gets crossed.
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

# Readable personalities (GAME_DESIGN.md §10). Every hero also rolls its own
# values around these, so two Vulpins never behave exactly alike.
# "Loyal" is left out: it only means something with parties, which this
# prototype does not simulate yet.
const TRAITS := {
	"Greedy": {"fear": -0.30, "trap": -0.20, "greed": 1.40, "flee": -0.08, "patience": 15},
	"Cautious": {"fear": 0.50, "trap": 0.40, "greed": 0.85, "flee": 0.10, "patience": -10},
	"Stubborn": {"fear": -0.20, "trap": -0.10, "greed": 1.00, "flee": -0.12, "patience": 35},
	"Cowardly": {"fear": 0.70, "trap": 0.50, "greed": 0.90, "flee": 0.15, "patience": -25}
}

# Palette straight from art-bible/palette/COLOR_PALETTE.md.
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
# Derived (UI text needs to stay legible on dark stone).
const C_TEXT := Color("#E8E6EC")
const C_BACKDROP := Color("#17161B")

enum Tile { ROCK, FLOOR, ENTRANCE, CORE, VAULT, SPIKE, SNARE, DOOR }
enum Tool { DIG, STORE, TRAP_SPIKE, TRAP_SNARE, BUILD_DOOR, BUILD_ENTRANCE, REPAIR, ABSORB, RESET }

var grid: Array = []
var selected_tool: int = Tool.DIG
var gold := START_GOLD
var core_hp := CORE_MAX
var raid_timer := RAID_DELAY
var raid_active := false
var game_over := false
var reset_armed := false
var raid_index := 0
var hero: Dictionary = {}
var loot_bags: Array = []
var corpses: Array = []
var door_hp: Dictionary = {}        # Vector2i -> remaining HP
var trap_charges: Dictionary = {}   # Vector2i -> remaining charges
var raid_stats: Dictionary = {}
var message := ""
var report := ""
var font := ThemeDB.fallback_font
var sprites: Dictionary = {}
var cam_zoom := ZOOM_DEFAULT
var cam_yaw := YAW_DEFAULT
var cam_pan := Vector2.ZERO
var cam_panning := false
var cam_orbiting := false
var _last_wheel_ms := 0
var _last_pointer_event: InputEvent
var _click_stamp := ""
var debug_clicks := 0
var debug_pointer := Vector2.ZERO
var tool_buttons: Array[Button] = []
var toolbar_host: Control
var _last_mouse_pos := Vector2.ZERO
var _cam_custom := false
var _last_view_size := Vector2.ZERO
var dungeon: Node3D
var _world_host: SubViewportContainer
var _world_port: SubViewport

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

func _enter_tree() -> void:
	set_process_input(true)
	set_process_unhandled_input(false)

func _ready() -> void:
	randomize()
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout_toolbar)
	_ensure_camera_actions()
	_load_sprites()
	_setup_world3d()
	_new_map()
	_setup_toolbar_buttons()
	_layout_toolbar()

func _ensure_camera_actions() -> void:
	if not InputMap.has_action("cam_zoom_in"):
		InputMap.add_action("cam_zoom_in")
		var wheel_up := InputEventMouseButton.new()
		wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
		InputMap.action_add_event("cam_zoom_in", wheel_up)
	if not InputMap.has_action("cam_zoom_out"):
		InputMap.add_action("cam_zoom_out")
		var wheel_down := InputEventMouseButton.new()
		wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
		InputMap.action_add_event("cam_zoom_out", wheel_down)
	_erase_physical_key("cam_zoom_in", KEY_E)
	_erase_physical_key("cam_zoom_out", KEY_Q)

func _erase_physical_key(action: String, keycode: Key) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
			InputMap.action_erase_event(action, ev)

func _setup_world3d() -> void:
	_ensure_dungeon()
	if _world_host != null:
		return
	_world_host = SubViewportContainer.new()
	_world_host.stretch = true
	_world_host.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_world_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_host.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var play := _play_rect()
	_world_host.position = play.position
	_world_host.size = play.size
	add_child(_world_host)
	move_child(_world_host, 0)
	_world_port = SubViewport.new()
	_world_port.own_world_3d = true
	_world_port.transparent_bg = false
	_world_port.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_world_port.handle_input_locally = false
	_world_port.msaa_3d = Viewport.MSAA_4X
	_world_port.size = _world_pixel_size()
	_world_host.add_child(_world_port)
	if dungeon.get_parent() != _world_port:
		if dungeon.get_parent() != null:
			dungeon.get_parent().remove_child(dungeon)
		_world_port.add_child(dungeon)

func _ensure_dungeon() -> Node3D:
	if dungeon == null:
		dungeon = load("res://scripts/DungeonWorld.gd").new()
	return dungeon

func _sync_world() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if dungeon != null and dungeon.has_method("sync") and not grid.is_empty():
		dungeon.sync(self)

func _view_size() -> Vector2:
	if is_inside_tree():
		var r := get_viewport_rect().size
		if r.x >= 64.0 and r.y >= 64.0:
			return r
	return DESIGN_SIZE

func _play_view() -> Vector2:
	return _play_rect().size

func _world_pixel_size() -> Vector2i:
	var s := _play_view()
	return Vector2i(maxi(64, int(round(s.x * WORLD_RENDER_SCALE))), maxi(64, int(round(s.y * WORLD_RENDER_SCALE))))

func _to_world_screen(local: Vector2) -> Vector2:
	return _play_rect().position + local

func _from_world_screen(screen: Vector2) -> Vector2:
	return screen - _play_rect().position

func _play_rect() -> Rect2:
	var s := _view_size()
	var top := HUD_TOP
	var bottom := TOOLBAR_MARGIN + 18.0
	return Rect2(PLAY_MARGIN, top, maxf(64.0, s.x - PLAY_MARGIN * 2.0), maxf(64.0, s.y - top - bottom))

func _base_scale() -> float:
	var play := _play_rect()
	var nat_w := float(COLS + ROWS) * TILE_W * 0.5
	var nat_h := float(COLS + ROWS) * TILE_H * 0.5 + 36.0
	return minf(play.size.x / nat_w, play.size.y / nat_h) * 0.96

func _tw() -> float:
	return TILE_W * _base_scale()

func _th() -> float:
	return TILE_H * _base_scale()

func _iso_origin() -> Vector2:
	var play := _play_rect()
	var tw := _tw()
	var th := _th()
	var lift := 12.0 * _base_scale()
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for p in [Vector2i(0, 0), Vector2i(COLS - 1, 0), Vector2i(0, ROWS - 1), Vector2i(COLS - 1, ROWS - 1)]:
		var n := Vector2(float(p.x - p.y) * tw * 0.5, float(p.x + p.y) * th * 0.5)
		for q in [n + Vector2(0, -lift), n + Vector2(tw * 0.5, th * 0.5), n + Vector2(0, th), n + Vector2(-tw * 0.5, th * 0.5)]:
			mn.x = minf(mn.x, q.x)
			mn.y = minf(mn.y, q.y)
			mx.x = maxf(mx.x, q.x)
			mx.y = maxf(mx.y, q.y)
	return play.get_center() - (mn + mx) * 0.5

func _fit_camera_to_view() -> void:
	cam_zoom = ZOOM_DEFAULT
	cam_yaw = YAW_DEFAULT
	cam_pan = Vector2.ZERO
	_cam_custom = false

func _btn_y() -> float:
	return _view_size().y - TOOLBAR_MARGIN

func _layout_toolbar() -> void:
	_setup_toolbar_buttons()
	var s := _view_size()
	if toolbar_host != null:
		toolbar_host.position = Vector2.ZERO
		toolbar_host.size = s
	if _world_host != null:
		var play := _play_rect()
		_world_host.position = play.position
		_world_host.size = play.size
	if _world_port != null:
		_world_port.size = _world_pixel_size()
	if not _cam_custom:
		_fit_camera_to_view()
	var specs := _buttons()
	for i in range(mini(tool_buttons.size(), specs.size())):
		var r: Rect2 = specs[i]["rect"]
		tool_buttons[i].position = r.position
		tool_buttons[i].custom_minimum_size = r.size
		tool_buttons[i].size = r.size
	queue_redraw()

func _setup_toolbar_buttons() -> void:
	if tool_buttons.size() != _buttons().size():
		for b in tool_buttons:
			if is_instance_valid(b):
				b.queue_free()
		tool_buttons.clear()
		if toolbar_host != null:
			var layer_node := toolbar_host.get_parent()
			toolbar_host.queue_free()
			toolbar_host = null
			if layer_node != null:
				layer_node.queue_free()
	if not tool_buttons.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.name = "ToolbarLayer"
	add_child(layer)
	var host := Control.new()
	host.name = "ToolbarHost"
	toolbar_host = host
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_preset(Control.PRESET_TOP_LEFT)
	host.position = Vector2.ZERO
	host.size = _view_size()
	layer.add_child(host)
	for spec in _buttons():
		var r: Rect2 = spec["rect"]
		var btn := Button.new()
		btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		btn.position = r.position
		btn.custom_minimum_size = r.size
		btn.size = r.size
		btn.clip_text = true
		btn.clip_contents = true
		btn.autowrap_mode = TextServer.AUTOWRAP_OFF
		btn.text = "%s\n%s" % [spec["label"], spec["cost"]]
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var tool := int(spec["tool"])
		btn.pressed.connect(_on_toolbar_button.bind(tool))
		host.add_child(btn)
		tool_buttons.append(btn)

func _on_toolbar_button(tool: int) -> void:
	debug_clicks += 1
	if raid_active:
		return
	_apply_toolbar_tool(tool)
	_refresh_toolbar_buttons()
	queue_redraw()

func _refresh_toolbar_buttons() -> void:
	var specs := _buttons()
	for i in range(mini(tool_buttons.size(), specs.size())):
		var spec: Dictionary = specs[i]
		var tool := int(spec["tool"])
		var label := String(spec["label"])
		if tool == Tool.RESET and reset_armed:
			label = "Confirm?"
		if tool == selected_tool:
			tool_buttons[i].modulate = Color(1.15, 1.05, 1.3)
		else:
			tool_buttons[i].modulate = Color.WHITE
		tool_buttons[i].text = "%s\n%s" % [label, spec["cost"]]

func _load_sprites() -> void:
	sprites.clear()
	for key in SPRITE_FILES.keys():
		sprites[key] = _load_tex(String(SPRITE_FILES[key]))
	# Prefer painted wraps from art_bible / assets; generate only if missing.
	sprites["rock"] = _load_wrap_tex("res://assets/sprites/wrap_rock.png", false)
	sprites["floor"] = _load_wrap_tex("res://assets/sprites/wrap_floor.png", true)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is Texture2D:
			return res
	var img := Image.new()
	if img.load(path) != OK:
		return null
	return ImageTexture.create_from_image(img)

func _load_wrap_tex(path: String, is_floor: bool) -> Texture2D:
	var tex := _load_tex(path)
	if tex == null:
		return _make_wrap_ground(is_floor)
	var img: Image = tex.get_image()
	if img == null:
		return tex
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	_blend_wrap_edges(img)
	return ImageTexture.create_from_image(img)

func _blend_wrap_edges(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var band := maxi(12, w / 24)
	for y in h:
		for i in band:
			var t := float(i) / float(band)
			var a := img.get_pixel(i, y)
			var b := img.get_pixel(w - 1 - i, y)
			img.set_pixel(i, y, a.lerp(b, 0.5 * (1.0 - t)))
			img.set_pixel(w - 1 - i, y, b.lerp(a, 0.5 * (1.0 - t)))
	for x in w:
		for i in band:
			var t := float(i) / float(band)
			var a := img.get_pixel(x, i)
			var b := img.get_pixel(x, h - 1 - i)
			img.set_pixel(x, i, a.lerp(b, 0.5 * (1.0 - t)))
			img.set_pixel(x, h - 1 - i, b.lerp(a, 0.5 * (1.0 - t)))

func _color_dist(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)

func _cutout_tex(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return tex
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	if w < 8 or h < 8:
		return tex
	var keys: Array[Color] = [
		img.get_pixel(1, 1),
		img.get_pixel(w - 2, 1),
		img.get_pixel(1, h - 2),
		img.get_pixel(w - 2, h - 2),
		img.get_pixel(w / 2, 1),
		img.get_pixel(1, h / 2)
	]
	var stack: Array[Vector2i] = []
	var seen := {}
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		var id := p.x * 100000 + p.y
		if seen.has(id) or p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		seen[id] = true
		var c := img.get_pixel(p.x, p.y)
		var knock := false
		for k in keys:
			if _color_dist(c, k) < 0.28:
				knock = true
				break
		if c.g > c.r + 0.12 and c.g > 0.32:
			knock = true
		if c.a < 0.08:
			knock = true
		if not knock:
			continue
		c.a = 0.0
		img.set_pixel(p.x, p.y, c)
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))
	return ImageTexture.create_from_image(img)

func _sprite(key: String) -> Texture2D:
	if sprites.is_empty():
		_load_sprites()
	return sprites.get(key) as Texture2D

func _draw_tex(tex: Texture2D, rect: Rect2, modulate: Color = Color.WHITE) -> void:
	if tex == null:
		draw_rect(rect, C_BLUE_GRAY.darkened(0.25))
		return
	draw_texture_rect(tex, rect, false, modulate)

func _hash01(ix: int, iy: int, salt: int) -> float:
	var n := sin(float(ix * 127.1 + iy * 311.7 + salt) * 0.017) * 43758.5453
	return n - floorf(n)

func _wrap_delta(d: float, size: float) -> float:
	d = fposmod(d + size * 0.5, size) - size * 0.5
	return d

func _slab_at(px: float, py: float, size: float, cols: int, jitter: float, salt: int) -> Dictionary:
	var cell := size / float(cols)
	var gx := floori(px / cell)
	var gy := floori(py / cell)
	var best_d := 1.0e9
	var second_d := 1.0e9
	var best_id := 0
	var best_cx := 0.0
	var best_cy := 0.0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var cx := posmod(gx + ox, cols)
			var cy := posmod(gy + oy, cols)
			var jx := (_hash01(cx, cy, salt) - 0.5) * jitter
			var jy := (_hash01(cx, cy, salt + 19) - 0.5) * jitter
			var sx := (float(cx) + 0.5 + jx) * cell
			var sy := (float(cy) + 0.5 + jy) * cell
			var dx := _wrap_delta(px - sx, size)
			var dy := _wrap_delta(py - sy, size)
			var d := sqrt(dx * dx + dy * dy)
			if d < best_d:
				second_d = best_d
				best_d = d
				best_id = cx * 131 + cy * 17 + salt
				best_cx = dx
				best_cy = dy
			elif d < second_d:
				second_d = d
	return {"d1": best_d, "d2": second_d, "id": best_id, "lx": best_cx, "ly": best_cy}

func _make_wrap_ground(is_floor: bool) -> Texture2D:
	# Seamless mineral slabs at gameplay scale (several per cell, not one giant cobble).
	const SIZE := 512
	const COLS := 16
	var jitter := 0.32 if is_floor else 0.48
	var salt := 21 if is_floor else 4
	var pal: Array[Color] = [
		C_ANTHRACITE,
		C_BLUE_GRAY,
		C_MID_STONE,
		C_BLUE_GRAY.darkened(0.12),
		C_ANTHRACITE.lightened(0.08),
		C_MID_STONE.darkened(0.18)
	]
	if is_floor:
		pal = [
			C_ANTHRACITE.darkened(0.06),
			C_BLUE_GRAY.darkened(0.16),
			C_ANTHRACITE.lerp(C_DEEP_VIOLET, 0.18),
			C_BLUE_GRAY.darkened(0.08),
			C_ANTHRACITE.lerp(C_BLUE_GRAY, 0.35)
		]
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var fs := float(SIZE)
	for y in SIZE:
		for x in SIZE:
			var s: Dictionary = _slab_at(float(x), float(y), fs, COLS, jitter, salt)
			var gap: float = float(s["d2"]) - float(s["d1"])
			var idx := posmod(int(s["id"]), pal.size())
			var col: Color = pal[idx]
			var lit := clampf(0.78 + (-0.008 * float(s["lx"]) - 0.01 * float(s["ly"])), 0.52, 1.08)
			col = Color(col.r * lit, col.g * lit, col.b * lit, 1.0)
			if gap < 3.2:
				var grout := C_ANTHRACITE.darkened(0.28)
				if is_floor:
					grout = grout.lerp(C_DEEP_VIOLET, 0.35)
					if gap < 1.2:
						grout = grout.lerp(C_INFLUENCE_PURPLE, 0.4)
				col = col.lerp(grout, clampf(1.0 - gap / 3.2, 0.0, 1.0))
			elif gap < 6.5:
				col = col.lerp(C_PALE_STONE, (1.0 - (gap - 3.2) / 3.3) * 0.18)
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	tex.resource_name = "floor_wrap" if is_floor else "rock_wrap"
	return tex

# World-space wrap so neighbouring cells are one surface, not a stamped grid.
func _draw_seamless(tex: Texture2D, dest: Rect2, fallback: Color, modulate: Color = Color.WHITE) -> void:
	if tex == null:
		draw_rect(dest, fallback)
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var u0 := fposmod(dest.position.x, tw)
	var v0 := fposmod(dest.position.y, th)
	var remain_x := dest.size.x
	var dx := 0.0
	while remain_x > 0.5:
		var u := fposmod(u0 + dx, tw)
		var slice_w: float = minf(remain_x, tw - u)
		var remain_y := dest.size.y
		var dy := 0.0
		while remain_y > 0.5:
			var v := fposmod(v0 + dy, th)
			var slice_h: float = minf(remain_y, th - v)
			draw_texture_rect_region(
				tex,
				Rect2(dest.position + Vector2(dx, dy), Vector2(slice_w, slice_h)),
				Rect2(u, v, slice_w, slice_h),
				modulate
			)
			dy += slice_h
			remain_y -= slice_h
		dx += slice_w
		remain_x -= slice_w

func _new_map() -> void:
	grid.clear()
	door_hp.clear()
	trap_charges.clear()
	loot_bags.clear()
	corpses.clear()
	for y in range(ROWS):
		var row := []
		for x in range(COLS):
			row.append(Tile.ROCK)
		grid.append(row)

	var core := Vector2i(9, 5)
	for dy in range(CORE_H):
		for dx in range(CORE_W):
			grid[core.y + dy][core.x + dx] = Tile.CORE
	for y in range(core.y - 1, core.y + CORE_H + 1):
		for x in range(core.x - 1, core.x + CORE_W + 1):
			if int(grid[y][x]) == Tile.CORE:
				continue
			grid[y][x] = Tile.FLOOR
	_place_starter_storage()
	gold = START_GOLD
	core_hp = CORE_MAX
	raid_timer = RAID_DELAY
	raid_active = false
	game_over = false
	reset_armed = false
	raid_index = 0
	hero = {}
	raid_stats = {}
	report = ""
	message = "The Core is sealed. Starter vaults hold the dungeon's gold. Dig a layout, then place the entrance stair."
	_ensure_dungeon()
	if dungeon.has_method("clear_map"):
		dungeon.clear_map()
	_sync_world()
	queue_redraw()

func _process(delta: float) -> void:
	# While the application is not running nothing is simulated: the Master is absent.
	var pan := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan.y += 1.0
	if pan != Vector2.ZERO:
		cam_pan += pan.normalized() * 520.0 * delta
		_cam_custom = true
	var orbit := 0.0
	if Input.is_key_pressed(KEY_Q):
		orbit -= 1.0
	if Input.is_key_pressed(KEY_E):
		orbit += 1.0
	if orbit != 0.0:
		_orbit_yaw(orbit * ORBIT_SPEED * delta)
	var mouse := get_local_mouse_position() if is_inside_tree() else Vector2.ZERO
	debug_pointer = mouse
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		cam_pan += mouse - _last_mouse_pos
		_cam_custom = true
	if InputMap.has_action("cam_zoom_in") and Input.is_action_just_pressed("cam_zoom_in"):
		_zoom_at(mouse, ZOOM_STEP)
	if InputMap.has_action("cam_zoom_out") and Input.is_action_just_pressed("cam_zoom_out"):
		_zoom_at(mouse, 1.0 / ZOOM_STEP)
	_last_mouse_pos = mouse
	var vs := _view_size()
	if vs != _last_view_size:
		_last_view_size = vs
		_layout_toolbar()
	if is_inside_tree() and get_window() != null:
		var mp := get_local_mouse_position()
		get_window().title = "Dungeon Empire  |  mouse %d,%d  clicks %d" % [int(mp.x), int(mp.y), debug_clicks]
	_refresh_toolbar_buttons()
	if raid_active:
		_update_hero(delta)
	elif not game_over and _has_entrance():
		raid_timer = maxf(0.0, raid_timer - delta)
		if raid_timer <= 0.0:
			_start_raid()
	_sync_world()
	queue_redraw()

# --- Raids -----------------------------------------------------------------

func _has_entrance() -> bool:
	return _find_tile(Tile.ENTRANCE).x >= 0

func _start_raid() -> void:
	var entrance := _find_tile(Tile.ENTRANCE)
	if entrance.x < 0:
		return

	var template := _random_hero_template()
	var trait_name := _roll_trait()
	var mods: Dictionary = TRAITS[trait_name]
	var greed := maxf(0.15, _jitter(float(mods["greed"]), 0.15))
	var hp := maxi(20, int(template["hp"]) + randi_range(-6, 6))
	raid_index += 1
	hero = {
		"name": template["name"],
		"trait": trait_name,
		"display": "%s (%s)" % [template["name"], trait_name],
		"kind": template["kind"],
		"pos": entrance,
		"hp": hp,
		"max_hp": hp,
		"carried_gold": template["loot"],
		"move_cd": 0.0,
		"turns": 0,
		"known": {},
		"visited": {entrance: 1},
		"bias": {},
		"ignored": {},
		"fleeing": false,
		"portaling": false,
		"portal_t": 0.0,
		"portal_msg": "",
		"facing": _entrance_mouth(entrance),
		"greed": greed,
		"steal_capacity": maxi(1, int(round(float(template["steal_capacity"]) * greed))),
		"fear_weight": _jitter(float(template["fear_weight"]) + float(mods["fear"]), 0.20),
		"trap_weight": maxf(0.05, _jitter(float(template["trap_weight"]) + float(mods["trap"]), 0.20)),
		"objective": template["objective"],
		"door_damage": maxi(4, int(template["door_damage"]) + randi_range(-3, 3)),
		"flee_ratio": clampf(_jitter(float(template["flee_ratio"]) + float(mods["flee"]), 0.05), 0.05, 0.8),
		"patience": maxi(25, int(template["patience"]) + int(mods["patience"]) + randi_range(-10, 10))
	}
	raid_active = true
	raid_timer = 0.0
	raid_stats = {
		"killed": 0,
		"escaped": 0,
		"stolen": 0,
		"carried_out": 0,
		"doors_destroyed": 0,
		"traps_spent": 0,
		"core_lost": 0
	}
	report = ""
	message = "RAID %d: %s enters the dungeon. All changes are locked." % [raid_index, hero["display"]]

func _roll_trait() -> String:
	var names := TRAITS.keys()
	return String(names[randi() % names.size()])

func _jitter(base: float, spread: float) -> float:
	return base + randf_range(-spread, spread)

func _random_hero_template() -> Dictionary:
	var roll := randi() % 3
	if roll == 0:
		return {
			"name": "Vulpin Thief",
			"kind": "thief",
			"hp": 68,
			"loot": randi_range(80, 150),
			"steal_capacity": randi_range(90, 160),
			"fear_weight": 1.2,
			"trap_weight": 1.0,
			"objective": "vault",
			"door_damage": 18,
			"flee_ratio": 0.45,
			"patience": 90
		}
	elif roll == 1:
		return {
			"name": "Lithide Paladin",
			"kind": "paladin",
			"hp": 115,
			"loot": randi_range(140, 240),
			"steal_capacity": 0,
			"fear_weight": -0.25,
			"trap_weight": 0.55,
			"objective": "core",
			"door_damage": 34,
			"flee_ratio": 0.15,
			"patience": 140
		}
	return {
		"name": "Batrafian Ranger",
		"kind": "ranger",
		"hp": 82,
		"loot": randi_range(95, 175),
		"steal_capacity": 0,
		"fear_weight": 0.75,
		"trap_weight": 1.55,
		"objective": "explore",
		"door_damage": 20,
		"flee_ratio": 0.4,
		"patience": 70
	}

func _end_raid(result_text: String) -> void:
	raid_active = false
	raid_timer = RAID_DELAY
	hero = {}
	message = result_text
	if not game_over:
		message += "  Preparation: repairs and collection available."
	# Report fields follow GAME_DESIGN.md §3.
	report = "Raid %d report — killed: %d | escaped: %d | gold stolen: %d | carried out: %d | loot remaining: %d | doors destroyed: %d | structures damaged: %d | Core: %d%%" % [
		raid_index,
		int(raid_stats.get("killed", 0)),
		int(raid_stats.get("escaped", 0)),
		int(raid_stats.get("stolen", 0)),
		int(raid_stats.get("carried_out", 0)),
		_unsecured_loot_total(),
		int(raid_stats.get("doors_destroyed", 0)),
		_damaged_structure_count(),
		core_hp
	]

func _unsecured_loot_total() -> int:
	var total := 0
	for bag in loot_bags:
		total += int(bag["gold"])
	return total

func _damaged_structure_count() -> int:
	var damaged := 0
	for key in door_hp.keys():
		var p: Vector2i = key
		if int(grid[p.y][p.x]) == Tile.DOOR and int(door_hp[p]) < DOOR_MAX_HP:
			damaged += 1
	for key in trap_charges.keys():
		var p: Vector2i = key
		var t := int(grid[p.y][p.x])
		if (t == Tile.SPIKE or t == Tile.SNARE) and int(trap_charges[p]) < TRAP_MAX_CHARGES:
			damaged += 1
	return damaged

func _update_hero(delta: float) -> void:
	if hero.is_empty():
		return

	if bool(hero.get("portaling", false)):
		hero["portal_t"] = float(hero.get("portal_t", 0.0)) - delta
		if float(hero["portal_t"]) <= 0.0:
			_finish_town_portal()
		return

	hero["move_cd"] = float(hero["move_cd"]) - delta
	if float(hero["move_cd"]) > 0.0:
		return
	hero["move_cd"] = TURN_TIME
	hero["turns"] = int(hero["turns"]) + 1

	_remember_nearby(hero)
	_update_flee_state()

	var pos: Vector2i = hero["pos"]

	# A fleeing hero leaves the dungeon as soon as it reaches the entrance again.
	if bool(hero["fleeing"]) and int(grid[pos.y][pos.x]) == Tile.ENTRANCE:
		_hero_escapes()
		return

	# Safety net: a lost hero must not lock the dungeon forever.
	if int(hero["turns"]) > int(hero["patience"]) * 3:
		raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
		_open_town_portal("%s gets lost in the maze and eventually finds the way out." % hero["display"])
		return

	var next := _choose_next_step(hero)
	if next == pos:
		_open_town_portal("%s gives up exploring for lack of a useful path." % hero["display"])
		return

	# An intact door blocks: it has to be broken before passing through.
	if _door_intact(next):
		_attack_door(next)
		return

	hero["facing"] = next - pos
	hero["visited"][next] = int(hero["visited"].get(next, 0)) + 1
	hero["pos"] = next
	if hero.get("trap_sprung_at", Vector2i(-1, -1)) != next:
		hero.erase("trap_sprung_at")
	_resolve_cell(next)

func _update_flee_state() -> void:
	if bool(hero["fleeing"]):
		return
	var ratio := float(hero["hp"]) / float(hero["max_hp"])
	if ratio <= float(hero["flee_ratio"]):
		hero["fleeing"] = true
		message = "%s is badly wounded and looks for the exit." % hero["display"]
	elif int(hero["turns"]) >= int(hero["patience"]):
		hero["fleeing"] = true
		message = "%s has seen enough and looks for the exit." % hero["display"]

# Resolves arriving on a cell: loot, traps, then objective.
func _resolve_cell(pos: Vector2i) -> void:
	_pick_up_loot(pos)

	var tile: int = int(grid[pos.y][pos.x])
	if tile == Tile.SPIKE or tile == Tile.SNARE:
		_trigger_trap(pos, tile)

	if int(hero["hp"]) <= 0:
		_kill_hero()
		return

	if bool(hero["fleeing"]):
		return

	if tile == Tile.VAULT and String(hero["kind"]) == "thief":
		_try_rob_vault(pos)
		return

	if tile == Tile.CORE:
		_hero_reaches_core()

func _pick_up_loot(pos: Vector2i) -> void:
	var taken := 0
	for bag in loot_bags:
		if bag["pos"] == pos:
			taken += int(bag["gold"])
			bag["taken"] = true
	if taken <= 0:
		return
	hero["carried_gold"] = int(hero["carried_gold"]) + taken
	loot_bags = loot_bags.filter(func(b): return not bool(b.get("taken", false)))
	message = "%s picks up %d gold of unsecured loot!" % [hero["display"], taken]

func _trigger_trap(p: Vector2i, tile: int) -> void:
	var charges := int(trap_charges.get(p, TRAP_MAX_CHARGES))
	if charges <= 0:
		return  # Spent defense: it stays inert until repaired.
	trap_charges[p] = charges - 1
	raid_stats["traps_spent"] = int(raid_stats["traps_spent"]) + 1
	if tile == Tile.SPIKE:
		var damage := 24
		if String(hero["kind"]) == "paladin":
			damage = 15   # Lithides resist physical hazards (GAME_DESIGN.md §8).
		hero["hp"] = int(hero["hp"]) - damage
		hero["trap_sprung_at"] = p
	else:
		hero["hp"] = int(hero["hp"]) - 10
		hero["move_cd"] = float(hero["move_cd"]) + 0.55
		hero["trap_sprung_at"] = p

func _attack_door(p: Vector2i) -> void:
	if int(door_hp.get(p, DOOR_MAX_HP)) <= 0:
		return
	var hp := int(door_hp.get(p, DOOR_MAX_HP)) - int(hero["door_damage"])
	hero["move_cd"] = float(hero["move_cd"]) + 0.35
	if hp <= 0:
		door_hp[p] = 0
		raid_stats["doors_destroyed"] = int(raid_stats["doors_destroyed"]) + 1
		message = "%s forces a door. The wreck stays after the raid." % hero["display"]
	else:
		door_hp[p] = hp
		message = "%s strikes a door (%d HP left)." % [hero["display"], hp]

# A thief carries away only what fits in its bag, then teleports out.
func _try_rob_vault(p: Vector2i) -> void:
	var storage := _storage_state()
	var vaults: Dictionary = storage["vaults"]
	var available := int(vaults.get(p, 0))
	if available <= 0:
		hero["ignored"][p] = true
		message = "%s finds nothing but an empty storage." % hero["display"]
		return
	var amount := mini(available, int(hero["steal_capacity"]))
	gold -= amount
	hero["carried_gold"] = int(hero["carried_gold"]) + amount
	raid_stats["stolen"] = int(raid_stats["stolen"]) + amount
	raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
	raid_stats["carried_out"] = int(hero["carried_gold"])
	var left := available - amount
	var rest := ""
	if left > 0:
		rest = " %d gold stays behind." % left
	_open_town_portal("%s steals %d gold and teleports out of the dungeon.%s" % [hero["display"], amount, rest])

func _hero_reaches_core() -> void:
	var damage := 24
	if String(hero["kind"]) == "paladin":
		damage = 42
	var lost := mini(core_hp, damage)
	core_hp = maxi(0, core_hp - damage)
	raid_stats["core_lost"] = int(raid_stats["core_lost"]) + lost
	raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
	raid_stats["carried_out"] = int(hero["carried_gold"])

	if core_hp <= 0:
		game_over = true
		_open_town_portal("DEFEAT — %s destroys the Core. Click Reset to start a new campaign." % hero["display"])
		return

	_open_town_portal("%s strikes the Core (-%d integrity) then vanishes." % [hero["display"], damage])

func _kill_hero() -> void:
	var death_pos: Vector2i = hero["pos"]
	corpses.append({
		"pos": death_pos,
		"name": hero["name"],
		"fear": 18.0
	})
	var carried := int(hero["carried_gold"])
	if carried > 0:
		loot_bags.append({
			"pos": death_pos,
			"gold": carried,
			"taken": false
		})

	# Essence absorbed by the Core (GAME_DESIGN.md §4: weak ~2, experienced ~3, champion ~5).
	var heal := 2
	if String(hero["kind"]) == "ranger":
		heal = 3
	elif String(hero["kind"]) == "paladin":
		heal = 5
	core_hp = mini(CORE_MAX, core_hp + heal)
	raid_stats["killed"] = int(raid_stats["killed"]) + 1
	_end_raid("%s dies. The Core absorbs its essence (+%d); body and loot stay where they fell." % [hero["display"], heal])

# --- AI: partial knowledge and decision ------------------------------------

func _remember_nearby(h: Dictionary) -> void:
	var radius := 3 if String(h["kind"]) == "ranger" else 2
	var p: Vector2i = h["pos"]
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var q := Vector2i(p.x + dx, p.y + dy)
			if _inside(q):
				# Rolled once per cell: two heroes never price a route alike.
				if not h["known"].has(q):
					h["bias"][q] = randf_range(0.0, ROUTE_BIAS)
				h["known"][q] = grid[q.y][q.x]

func _target_tile(h: Dictionary) -> int:
	if bool(h["fleeing"]):
		return Tile.ENTRANCE
	var objective := String(h["objective"])
	if objective == "vault":
		return Tile.VAULT
	if objective == "core":
		return Tile.CORE
	return -1  # The ranger maps the place without a fixed target.

# The hero reasons on routes, never on a single step: a trap or a corpse makes
# a corridor expensive, it never makes it impassable. Judging one neighbour at
# a time made a hero retreat into the entrance forever in front of a trapped
# corridor, because backing off always looked cheaper than the only way on.
# GAME_DESIGN.md §10: "high-level AI decides what it wants, pathfinding decides
# how to reach what it currently knows".
func _choose_next_step(h: Dictionary) -> Vector2i:
	var start: Vector2i = h["pos"]
	var candidates: Array[Vector2i] = []
	for d in DIRS:
		var q := start + d
		if _can_step(start, q):
			candidates.append(q)
	if candidates.is_empty():
		return start

	# 1. Objective already spotted: head there using the mental map only.
	var target_tile := _target_tile(h)
	if target_tile >= 0:
		var step := _route_step(h, _known_targets(h, target_tile))
		if step != start:
			return step

	# 2. Nothing spotted: walk towards the closest edge of the known world.
	var explore := _route_step(h, _frontier_cells(h))
	if explore != start:
		return explore

	# 3. Everything reachable is mapped: go back over the least trodden ground.
	var revisit := _route_step(h, _least_visited_cells(h))
	if revisit != start:
		return revisit

	# 4. Nowhere left to route: decide on the spot.
	return _local_step(h, candidates)

# Cells of the wanted kind the hero remembers, minus those it wrote off.
func _known_targets(h: Dictionary, target_tile: int) -> Dictionary:
	var goals := {}
	for k in h["known"].keys():
		var p: Vector2i = k
		if int(h["known"][p]) == target_tile and not h["ignored"].has(p):
			goals[p] = true
	return goals

# Known passages touching something still unseen: the edge of the mental map.
func _frontier_cells(h: Dictionary) -> Dictionary:
	var goals := {}
	for k in h["known"].keys():
		var p: Vector2i = k
		if int(h["known"][p]) == Tile.ROCK:
			continue
		for d in DIRS:
			var n := p + d
			if _inside(n) and not h["known"].has(n):
				goals[p] = true
				break
	return goals

func _least_visited_cells(h: Dictionary) -> Dictionary:
	var start: Vector2i = h["pos"]
	var lowest := 1 << 30
	var goals := {}
	for k in h["known"].keys():
		var p: Vector2i = k
		if int(h["known"][p]) == Tile.ROCK or p == start:
			continue
		var seen_count := int(h["visited"].get(p, 0))
		if seen_count < lowest:
			lowest = seen_count
			goals.clear()
		if seen_count == lowest:
			goals[p] = true
	return goals

# Price the hero puts on entering a cell, based on what it believes is there.
# Never zero or negative: a route always costs something to walk.
func _step_cost(h: Dictionary, p: Vector2i) -> float:
	var cost := ROUTE_STEP
	cost += minf(float(int(h["visited"].get(p, 0))) * ROUTE_REVISIT, ROUTE_REVISIT_MAX)
	var seen := int(h["known"].get(p, Tile.ROCK))
	if seen == Tile.SPIKE or seen == Tile.SNARE:
		cost += ROUTE_TRAP * float(h["trap_weight"])
	elif seen == Tile.DOOR:
		cost += ROUTE_DOOR
	# A Paladin has a negative fear weight: corpses draw it in instead.
	cost += _corpse_danger_near(p) * float(h["fear_weight"])
	cost += float(h["bias"].get(p, 0.0))
	return maxf(0.05, cost)

# Cheapest route to any of the goals, over the mental map alone (never the real
# grid). Returns the first step, or the current cell when nothing is reachable.
func _route_step(h: Dictionary, goals: Dictionary) -> Vector2i:
	var start: Vector2i = h["pos"]
	if goals.is_empty():
		return start

	var dist := {start: 0.0}
	var came := {}
	var closed := {}
	var open: Array[Vector2i] = [start]
	var reached := Vector2i(-1, -1)

	while not open.is_empty():
		var best_i := 0
		for i in range(1, open.size()):
			if float(dist[open[i]]) < float(dist[open[best_i]]):
				best_i = i
		var cur: Vector2i = open[best_i]
		open.remove_at(best_i)
		if closed.has(cur):
			continue
		closed[cur] = true
		if cur != start and goals.has(cur):
			reached = cur
			break
		for d in DIRS:
			var n := cur + d
			if closed.has(n) or not h["known"].has(n):
				continue
			if int(h["known"][n]) == Tile.ROCK:
				continue
			if not _can_step(cur, n):
				continue
			var nd := float(dist[cur]) + _step_cost(h, n)
			if nd < float(dist.get(n, INF)):
				dist[n] = nd
				came[n] = cur
				open.append(n)

	if reached.x < 0:
		return start
	# Walk the parent chain back down to the cell right next to the hero.
	var cur2 := reached
	while came.has(cur2) and came[cur2] != start:
		cur2 = came[cur2]
	if not came.has(cur2):
		return start
	return cur2

# Last resort, used only when the whole known dungeon is already routed out:
# a plain local preference so the hero still does something readable.
func _local_step(h: Dictionary, candidates: Array[Vector2i]) -> Vector2i:
	var best := candidates[0]
	var best_score := -INF
	for q in candidates:
		var score := randf_range(-2.5, 2.5)
		score -= float(int(h["visited"].get(q, 0))) * 4.0
		score -= _corpse_danger_near(q) * float(h["fear_weight"])
		var seen := int(h["known"].get(q, Tile.ROCK))
		if seen == Tile.SPIKE or seen == Tile.SNARE:
			score -= 8.0 * float(h["trap_weight"])
		if seen == Tile.ENTRANCE and bool(h["fleeing"]):
			score += 25.0
		if score > best_score:
			best_score = score
			best = q
	return best

func _corpse_danger_near(p: Vector2i) -> float:
	var danger := 0.0
	for corpse in corpses:
		var cp: Vector2i = corpse["pos"]
		var dist := absi(cp.x - p.x) + absi(cp.y - p.y)
		if dist == 0:
			danger += float(corpse["fear"])
		elif dist == 1:
			danger += float(corpse["fear"]) * 0.5
	return danger / 10.0

func _hero_escapes() -> void:
	var carried := int(hero["carried_gold"])
	raid_stats["escaped"] = int(raid_stats["escaped"]) + 1
	raid_stats["carried_out"] = carried
	var ent: Vector2i = hero["pos"]
	hero["facing"] = -_entrance_mouth(ent)
	_open_town_portal("%s walks out of the dungeon alive with %d gold." % [hero["display"], carried])

func _open_town_portal(result_text: String) -> void:
	if hero.is_empty() or bool(hero.get("portaling", false)):
		return
	hero["portaling"] = true
	hero["portal_t"] = PORTAL_HOLD
	hero["portal_msg"] = result_text
	message = "%s opens a town portal." % hero["display"]

func _finish_town_portal() -> void:
	var text := String(hero.get("portal_msg", "The hero leaves the dungeon."))
	_end_raid(text)

# --- Grid and storage ------------------------------------------------------

func _inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < COLS and p.y < ROWS

func _walkable(p: Vector2i) -> bool:
	return _inside(p) and int(grid[p.y][p.x]) != Tile.ROCK

# Stairs only connect along their run: corridor mouth, not the left/right flanks.
func _entrance_mouth(p: Vector2i) -> Vector2i:
	var core := _core_origin()
	var best := Vector2i.ZERO
	var best_score := -INF
	for d in DIRS:
		var n: Vector2i = p + d
		if not _walkable(n):
			continue
		if int(grid[n.y][n.x]) == Tile.ENTRANCE:
			continue
		var score := float(d.x) * float(core.x - p.x) + float(d.y) * float(core.y - p.y)
		if score > best_score:
			best_score = score
			best = d
	return best if best != Vector2i.ZERO else Vector2i.RIGHT

func _can_step(from: Vector2i, to: Vector2i) -> bool:
	if not _walkable(to):
		return false
	if absi(from.x - to.x) + absi(from.y - to.y) != 1:
		return false
	if int(grid[from.y][from.x]) == Tile.ENTRANCE:
		return to - from == _entrance_mouth(from)
	if int(grid[to.y][to.x]) == Tile.ENTRANCE:
		return from - to == _entrance_mouth(to)
	return true

func _door_intact(p: Vector2i) -> bool:
	return _inside(p) and int(grid[p.y][p.x]) == Tile.DOOR and int(door_hp.get(p, DOOR_MAX_HP)) > 0

func _core_origin() -> Vector2i:
	return _find_tile(Tile.CORE)

func _find_tile(tile: int) -> Vector2i:
	for y in range(ROWS):
		for x in range(COLS):
			if int(grid[y][x]) == tile:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _place_starter_storage() -> void:
	var origin := Vector2i(9, 5)
	var needed := ceili(float(START_GOLD) / float(VAULT_CAPACITY))
	var placed := 0
	for y in range(origin.y + CORE_H, origin.y - 2, -1):
		for x in range(origin.x - 1, origin.x + CORE_W + 1):
			if placed >= needed:
				return
			if not _inside(Vector2i(x, y)):
				continue
			if int(grid[y][x]) != Tile.FLOOR:
				continue
			grid[y][x] = Tile.VAULT
			placed += 1

func _storage_capacity() -> int:
	return _vault_positions().size() * VAULT_CAPACITY

func _storage_free() -> int:
	return maxi(0, _storage_capacity() - gold)

func _deposit_gold(amount: int) -> int:
	var take := mini(maxi(0, amount), _storage_free())
	gold += take
	return take

func _spill_overflow_at(p: Vector2i) -> void:
	var extra := gold - _storage_capacity()
	if extra <= 0:
		return
	gold -= extra
	loot_bags.append({"pos": p, "gold": extra, "taken": false})

func _vault_positions() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(ROWS):
		for x in range(COLS):
			if int(grid[y][x]) == Tile.VAULT:
				out.append(Vector2i(x, y))
	return out

# Dungeon wealth is physical: it fills the storages one by one and the
# surplus stays exposed next to the Core (GAME_DESIGN.md §5).
func _storage_state() -> Dictionary:
	var vaults := {}
	var remaining := gold
	for p in _vault_positions():
		var amount := mini(remaining, VAULT_CAPACITY)
		vaults[p] = amount
		remaining -= amount
	return {"vaults": vaults, "unstored": 0, "capacity": _storage_capacity()}

func _has_open_neighbour(p: Vector2i) -> bool:
	for d in DIRS:
		if _walkable(p + d):
			return true
	return false

func _clear_cell_state(p: Vector2i) -> void:
	door_hp.erase(p)
	trap_charges.erase(p)

# --- Player input ----------------------------------------------------------

func _board_center() -> Vector2:
	return _cell_pos(Vector2i(COLS / 2, ROWS / 2))

func _board_xform() -> Transform2D:
	return Transform2D.IDENTITY

func _board_to_screen(board: Vector2) -> Vector2:
	return board

func _screen_to_board(screen: Vector2) -> Vector2:
	return screen

func _zoom_wheel(screen_pt: Vector2, factor: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_wheel_ms < 50:
		return
	_last_wheel_ms = now
	_zoom_at(screen_pt, factor)

func _zoom_at(screen_pt: Vector2, factor: float) -> void:
	if screen_pt == Vector2.ZERO:
		screen_pt = _cell_pos(Vector2i(COLS / 2, ROWS / 2))
	_ensure_dungeon()
	var view := _play_view()
	dungeon.apply_camera(cam_zoom, cam_pan, view, COLS, ROWS, cam_yaw)
	var ground: Vector3 = dungeon.screen_to_ground(_from_world_screen(screen_pt), view, cam_zoom)
	cam_zoom = clampf(cam_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	dungeon.apply_camera(cam_zoom, cam_pan, view, COLS, ROWS, cam_yaw)
	var ground2: Vector3 = dungeon.screen_to_ground(_from_world_screen(screen_pt), view, cam_zoom)
	var err: Vector3 = ground - ground2
	var k: float = dungeon.ortho_size(cam_zoom) / maxf(view.y, 1.0)
	if k > 0.00001:
		var b: Basis = dungeon._cam_basis()
		var right := Vector3(b.x.x, 0, b.x.z)
		if right.length() > 0.001:
			right = right.normalized()
		var fwd := Vector3(-b.z.x, 0, -b.z.z)
		if fwd.length() > 0.001:
			fwd = fwd.normalized()
		cam_pan.x += err.dot(right) / k
		cam_pan.y += -err.dot(fwd) / k
	_cam_custom = true
	queue_redraw()

func _orbit_yaw(degrees: float) -> void:
	if is_zero_approx(degrees):
		return
	_ensure_dungeon()
	var view := _play_view()
	dungeon.apply_camera(cam_zoom, cam_pan, view, COLS, ROWS, cam_yaw)
	var keep: Vector3 = dungeon._look
	cam_yaw = wrapf(cam_yaw + degrees, 0.0, 360.0)
	var k: float = dungeon.ortho_size(cam_zoom) / maxf(view.y, 1.0)
	dungeon._yaw = cam_yaw
	var b: Basis = dungeon._cam_basis()
	var right := Vector3(b.x.x, 0, b.x.z)
	if right.length() > 0.001:
		right = right.normalized()
	var fwd := Vector3(-b.z.x, 0, -b.z.z)
	if fwd.length() > 0.001:
		fwd = fwd.normalized()
	if k > 0.00001:
		var err: Vector3 = keep - dungeon.map_center(COLS, ROWS)
		cam_pan.x = err.dot(right) / k
		cam_pan.y = -err.dot(fwd) / k
	_cam_custom = true
	queue_redraw()

func _reset_camera() -> void:
	cam_panning = false
	cam_orbiting = false
	_fit_camera_to_view()
	queue_redraw()

func _gui_input(_event: InputEvent) -> void:
	pass

func _unhandled_input(_event: InputEvent) -> void:
	pass

func _input(event: InputEvent) -> void:
	_handle_event(event)

func _mouse_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouse:
		debug_pointer = (event as InputEventMouse).position
		return debug_pointer
	if event is InputEventGesture:
		debug_pointer = (event as InputEventGesture).position
		return debug_pointer
	if is_inside_tree():
		debug_pointer = get_local_mouse_position()
		return debug_pointer
	return Vector2.ZERO

func _already_handled(event: InputEvent) -> bool:
	if _last_pointer_event == event:
		return true
	_last_pointer_event = event
	return false

func _handle_event(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		var mag := event as InputEventMagnifyGesture
		if mag.factor > 0.0 and not is_equal_approx(mag.factor, 1.0):
			_zoom_at(_mouse_pos(mag), mag.factor)
		return
	if event is InputEventPanGesture:
		cam_pan += (event as InputEventPanGesture).delta
		_cam_custom = true
		queue_redraw()
		return

	if event is InputEventMouseMotion and cam_orbiting:
		_orbit_yaw(event.relative.x * 0.28)
		return
	if event is InputEventMouseMotion and cam_panning:
		cam_pan += event.relative
		_cam_custom = true
		queue_redraw()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_zoom_at(_board_to_screen(_board_center()), ZOOM_STEP)
			return
		if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_zoom_at(_board_to_screen(_board_center()), 1.0 / ZOOM_STEP)
			return
		if event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			_reset_camera()
			return

	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if _already_handled(mb):
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		var stamp := "%d:%s:%.0f:%.0f" % [Engine.get_process_frames(), mb.pressed, mb.position.x, mb.position.y]
		if stamp == _click_stamp:
			return
		_click_stamp = stamp
	var mp := _mouse_pos(mb)
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_wheel(mp, ZOOM_STEP)
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_wheel(mp, 1.0 / ZOOM_STEP)
		return
	if mb.button_index == MOUSE_BUTTON_MIDDLE:
		cam_orbiting = mb.pressed
		cam_panning = false
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		cam_panning = mb.pressed
		cam_orbiting = false
		return
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		debug_clicks += 1
	else:
		return

	if _toolbar_hit(mp):
		# Live clicks are handled by the Button nodes. Tests inject events
		# without a pressed OS mouse, so they still go through here.
		# Do not mark the event handled or the toolbar Buttons never fire.
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not raid_active:
				_handle_toolbar(mp)
				queue_redraw()
		return

	if is_inside_tree():
		get_viewport().set_input_as_handled()

	if raid_active:
		return

	if game_over:
		return

	reset_armed = false
	var grab := 24.0

	for bag in loot_bags:
		if _board_to_screen(_bag_pos(bag)).distance_to(mp) <= grab:
			var want := int(bag["gold"])
			var got := _deposit_gold(want)
			if got <= 0:
				message = "No storage space. Build more storage first."
				queue_redraw()
				return
			bag["gold"] = want - got
			if int(bag["gold"]) <= 0:
				bag["taken"] = true
				loot_bags = loot_bags.filter(func(b): return not bool(b.get("taken", false)))
				message = "Loot stored: +%d gold." % got
			else:
				message = "Stored %d gold. %d remains on the body — need more storage." % [got, int(bag["gold"])]
			_sync_world()
			queue_redraw()
			return

	if selected_tool == Tool.ABSORB:
		for corpse in corpses:
			if _board_to_screen(_corpse_pos(corpse)).distance_to(mp) <= grab:
				core_hp = mini(CORE_MAX, core_hp + 2)
				corpses.erase(corpse)
				message = "Corpse absorbed: +2 integrity. It frightens nobody anymore."
				queue_redraw()
				return
		message = "No corpse under the cursor."
		queue_redraw()
		return

	_build_at(_screen_to_grid(mp))
	_sync_world()
	queue_redraw()

func _toolbar_hit(mp: Vector2) -> bool:
	for b in _buttons():
		var rect: Rect2 = b["rect"]
		if rect.has_point(mp):
			return true
	return false

func _handle_toolbar(mp: Vector2) -> void:
	for b in _buttons():
		var rect: Rect2 = b["rect"]
		if not rect.has_point(mp):
			continue
		_apply_toolbar_tool(int(b["tool"]))
		return

func _apply_toolbar_tool(tool: int) -> void:
	if tool == Tool.RESET:
		if reset_armed or game_over:
			_new_map()
		else:
			reset_armed = true
			message = "Reset: click a second time to wipe everything."
		return
	reset_armed = false
	if game_over:
		return
	if tool == Tool.REPAIR:
		_repair_structures()
		return
	selected_tool = tool

func _build_at(gp: Vector2i) -> void:
	if not _inside(gp):
		message = "No tile under the cursor."
		return
	var current := int(grid[gp.y][gp.x])
	if current == Tile.ENTRANCE or current == Tile.CORE:
		message = "The entrance and the Core cannot be modified."
		return

	match selected_tool:
		Tool.DIG:
			if current == Tile.ROCK:
				if not _has_open_neighbour(gp):
					message = "You must dig from an existing passage."
				elif gold < COST_DIG:
					message = "Not enough gold to dig (%d)." % COST_DIG
				else:
					gold -= COST_DIG
					grid[gp.y][gp.x] = Tile.FLOOR
					message = "Dug a passage."
			else:
				var was_vault := current == Tile.VAULT
				_clear_cell_state(gp)
				grid[gp.y][gp.x] = Tile.FLOOR
				if was_vault:
					_spill_overflow_at(gp)
				message = "Structure cleared."
		Tool.STORE:
			_place(gp, Tile.VAULT, COST_VAULT)
		Tool.TRAP_SPIKE:
			_place(gp, Tile.SPIKE, COST_SPIKE)
		Tool.TRAP_SNARE:
			_place(gp, Tile.SNARE, COST_SNARE)
		Tool.BUILD_DOOR:
			_place(gp, Tile.DOOR, COST_DOOR)
		Tool.BUILD_ENTRANCE:
			_place_entrance(gp)

func _place_entrance(p: Vector2i) -> void:
	if _has_entrance():
		message = "The entrance stair is already set. It cannot be moved."
		return
	if int(grid[p.y][p.x]) != Tile.FLOOR:
		message = "Place the stair on an open passage."
		return
	grid[p.y][p.x] = Tile.ENTRANCE
	raid_timer = RAID_DELAY
	message = "Entrance opened. Heroes will find it in %ds." % int(RAID_DELAY)

func _place(p: Vector2i, tile: int, cost: int) -> void:
	var current := int(grid[p.y][p.x])
	if current == Tile.ROCK:
		message = "Dig this passage first."
		return
	if tile == Tile.DOOR and current != Tile.DOOR and not _door_between_walls(p):
		message = "A door must sit in a gap between two walls."
		return
	if current == tile:
		if tile != Tile.DOOR or int(door_hp.get(p, DOOR_MAX_HP)) > 0:
			return
	if gold < cost:
		message = "Not enough gold (%d required)." % cost
		return
	gold -= cost
	var was_vault := current == Tile.VAULT
	_clear_cell_state(p)
	grid[p.y][p.x] = tile
	if was_vault and tile != Tile.VAULT:
		_spill_overflow_at(p)
	if tile == Tile.DOOR:
		door_hp[p] = DOOR_MAX_HP
	elif tile == Tile.SPIKE or tile == Tile.SNARE:
		trap_charges[p] = TRAP_MAX_CHARGES

func _door_between_walls(p: Vector2i) -> bool:
	# Opposite rocks: a 1-tile corridor or a hole punched through a wall.
	var ew := _is_rock_cell(p + Vector2i.LEFT) and _is_rock_cell(p + Vector2i.RIGHT)
	var ns := _is_rock_cell(p + Vector2i.UP) and _is_rock_cell(p + Vector2i.DOWN)
	return ew or ns

func _is_rock_cell(n: Vector2i) -> bool:
	return _inside(n) and int(grid[n.y][n.x]) == Tile.ROCK

# Repairs: outside raids only (GAME_DESIGN.md §7).
func _repair_structures() -> void:
	var doors := 0
	var charges := 0
	for key in door_hp.keys():
		var p: Vector2i = key
		if int(grid[p.y][p.x]) != Tile.DOOR:
			continue
		if int(door_hp[p]) <= 0 or int(door_hp[p]) >= DOOR_MAX_HP:
			continue
		if gold < COST_REPAIR_DOOR:
			break
		gold -= COST_REPAIR_DOOR
		door_hp[p] = DOOR_MAX_HP
		doors += 1
	for key in trap_charges.keys():
		var p: Vector2i = key
		var t := int(grid[p.y][p.x])
		if t != Tile.SPIKE and t != Tile.SNARE:
			continue
		while int(trap_charges[p]) < TRAP_MAX_CHARGES and gold >= COST_REPAIR_TRAP:
			gold -= COST_REPAIR_TRAP
			trap_charges[p] = int(trap_charges[p]) + 1
			charges += 1
	if doors == 0 and charges == 0:
		message = "Nothing to repair (or not enough gold)."
	else:
		message = "Repairs: %d door(s), %d trap charge(s)." % [doors, charges]

func _iso_top(p: Vector2i) -> Vector2:
	return _iso_origin() + Vector2(float(p.x - p.y) * _tw() * 0.5, float(p.x + p.y) * _th() * 0.5)

func _iso_diamond(p: Vector2i, lift: float = 0.0) -> PackedVector2Array:
	var t := _iso_top(p) + Vector2(0, -lift)
	var tw := _tw()
	var th := _th()
	return PackedVector2Array([
		t,
		t + Vector2(tw * 0.5, th * 0.5),
		t + Vector2(0, th),
		t + Vector2(-tw * 0.5, th * 0.5)
	])

func _screen_to_grid(p: Vector2) -> Vector2i:
	_ensure_dungeon()
	return dungeon.screen_to_cell(_from_world_screen(p), _play_view(), cam_zoom, cam_pan, COLS, ROWS, cam_yaw, self)

func _cell_pos(p: Vector2i) -> Vector2:
	_ensure_dungeon()
	return _to_world_screen(dungeon.cell_to_screen(p, _play_view(), cam_zoom, cam_pan, COLS, ROWS, cam_yaw, self))

func _bag_pos(bag: Dictionary) -> Vector2:
	return _cell_pos(bag["pos"]) + BAG_OFFSET

func _corpse_pos(corpse: Dictionary) -> Vector2:
	return _cell_pos(corpse["pos"]) + CORPSE_OFFSET

func _buttons() -> Array:
	var defs := [
		{"tool": Tool.DIG, "label": "Dig", "cost": "5"},
		{"tool": Tool.STORE, "label": "Storage", "cost": "60"},
		{"tool": Tool.TRAP_SPIKE, "label": "Spikes", "cost": "35"},
		{"tool": Tool.TRAP_SNARE, "label": "Snare", "cost": "30"},
		{"tool": Tool.BUILD_DOOR, "label": "Door", "cost": "40"},
		{"tool": Tool.BUILD_ENTRANCE, "label": "Entrance", "cost": "free"},
		{"tool": Tool.REPAIR, "label": "Repair", "cost": "15 / 10"},
		{"tool": Tool.ABSORB, "label": "Absorb", "cost": "+2 Core"},
		{"tool": Tool.RESET, "label": "Reset", "cost": ""}
	]
	var n: int = defs.size()
	var view := _view_size()
	var usable: float = maxf(view.x - BTN_X * 2.0, 200.0)
	var w: float = (usable - BTN_GAP * float(n - 1)) / float(n)
	var out := []
	for i in range(n):
		var d: Dictionary = defs[i]
		d["rect"] = Rect2(Vector2(BTN_X + float(i) * (w + BTN_GAP), _btn_y()), Vector2(w, BTN_H))
		out.append(d)
	return out

# --- Rendering -------------------------------------------------------------

# Draws one HUD segment and returns the x position for the next one
# (semantic colors follow GAME_DESIGN.md §24).
func _hud_segment(x: float, text: String, color: Color, size: int) -> float:
	draw_string(font, Vector2(x, 34), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	return x + font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

func _tile_height(t: int) -> float:
	match t:
		Tile.ROCK:
			return 12.0
		Tile.FLOOR:
			return 0.0
		Tile.ENTRANCE:
			return 4.0
		Tile.CORE:
			return 22.0
		Tile.VAULT:
			return 16.0
		Tile.SPIKE, Tile.SNARE:
			return 8.0
		Tile.DOOR:
			return 18.0
	return 8.0

func _ground_tex(t: int) -> Texture2D:
	if t == Tile.ROCK:
		return _sprite("rock")
	return _sprite("floor")

func _uv_from_unscaled(local: Vector2, tex: Texture2D) -> Vector2:
	if tex == null:
		return Vector2.ZERO
	# One wrap covers many cells so slabs continue instead of stamping gravel.
	const PERIOD := 256.0
	return Vector2(local.x / PERIOD, local.y / PERIOD)

func _unscaled_iso_top(p: Vector2i) -> Vector2:
	return Vector2(float(p.x - p.y) * TILE_W * 0.5, float(p.x + p.y) * TILE_H * 0.5)

func _draw_textured_poly(pts: PackedVector2Array, uvs: PackedVector2Array, tex: Texture2D, modulate: Color) -> void:
	if tex == null or pts.size() < 3:
		draw_colored_polygon(pts, modulate)
		return
	var colors := PackedColorArray()
	colors.resize(pts.size())
	colors.fill(modulate)
	draw_polygon(pts, colors, uvs, tex)

func _tile_top_color(p: Vector2i, t: int, vaults: Dictionary) -> Color:
	var checker := 0.04 if (p.x + p.y) % 2 == 0 else 0.0
	match t:
		Tile.ROCK:
			return C_BLUE_GRAY.darkened(0.12 + checker)
		Tile.FLOOR:
			return C_DEEP_VIOLET.lightened(0.04 - checker)
		Tile.ENTRANCE:
			return C_FOREST_GREEN
		Tile.CORE:
			return C_INFLUENCE_PURPLE.lightened(0.1)
		Tile.VAULT:
			var fill := float(int(vaults.get(p, 0))) / float(VAULT_CAPACITY)
			return C_DARK_GOLD.lerp(C_WARM_GOLD, fill)
		Tile.SPIKE:
			return C_DANGER_RED.darkened(0.15)
		Tile.SNARE:
			return C_HOT_ORANGE.darkened(0.2)
		Tile.DOOR:
			return C_VILLAGE_BEIGE.darkened(0.25)
	return C_MID_STONE

func _draw_iso_prism(p: Vector2i, top: Color, height: float, tex: Texture2D) -> void:
	var n := _iso_top(p)
	var tw := _tw()
	var th := _th()
	var e := n + Vector2(tw * 0.5, th * 0.5)
	var s := n + Vector2(0, th)
	var w := n + Vector2(-tw * 0.5, th * 0.5)
	var lift := Vector2(0, -height)
	var un := _unscaled_iso_top(p)
	var left := C_ANTHRACITE.lerp(top, 0.35)
	var right := C_ANTHRACITE.lerp(top, 0.18)
	if height > 0.5:
		var u_w := _uv_from_unscaled(un + Vector2(-TILE_W * 0.5, TILE_H * 0.5), tex)
		var u_s := _uv_from_unscaled(un + Vector2(0, TILE_H), tex)
		var u_e := _uv_from_unscaled(un + Vector2(TILE_W * 0.5, TILE_H * 0.5), tex)
		_draw_textured_poly(PackedVector2Array([w, s, s + lift, w + lift]), PackedVector2Array([u_w, u_s, u_s, u_w]), tex, left)
		_draw_textured_poly(PackedVector2Array([e, s, s + lift, e + lift]), PackedVector2Array([u_e, u_s, u_s, u_e]), tex, right)
	var diamond := _iso_diamond(p, height)
	var uvs := PackedVector2Array([
		_uv_from_unscaled(un, tex),
		_uv_from_unscaled(un + Vector2(TILE_W * 0.5, TILE_H * 0.5), tex),
		_uv_from_unscaled(un + Vector2(0, TILE_H), tex),
		_uv_from_unscaled(un + Vector2(-TILE_W * 0.5, TILE_H * 0.5), tex)
	])
	_draw_textured_poly(diamond, uvs, tex, top)

func _draw_contact_shadow(p: Vector2i, height: float, spread: float = 1.0) -> void:
	var c := _iso_top(p) + Vector2(0, _th() * 0.55) + Vector2(0, -height * 0.12)
	var rx := _tw() * 0.32 * spread
	var ry := _th() * 0.22 * spread
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * float(i) / 14.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, Color(0.02, 0.02, 0.04, 0.45))

func _draw_cave_mouth(p: Vector2i, height: float) -> void:
	var t := _iso_top(p) + Vector2(0, -height)
	var tw := _tw()
	var th := _th()
	draw_colored_polygon(PackedVector2Array([
		t + Vector2(0, th * 0.18),
		t + Vector2(tw * 0.32, th * 0.48),
		t + Vector2(0, th * 0.72),
		t + Vector2(-tw * 0.32, th * 0.48)
	]), Color(0.03, 0.03, 0.05, 0.92))

func _draw_iso_decal(tex: Texture2D, p: Vector2i, height: float, modulate: Color) -> void:
	if tex == null:
		return
	var diamond := _iso_diamond(p, height)
	var uvs := PackedVector2Array([
		Vector2(0.5, 0.12),
		Vector2(0.9, 0.5),
		Vector2(0.5, 0.9),
		Vector2(0.1, 0.5)
	])
	var colors := PackedColorArray()
	colors.resize(4)
	colors.fill(modulate)
	draw_polygon(diamond, colors, uvs, tex)

func _draw_iso_sprite(tex: Texture2D, p: Vector2i, height: float, size: Vector2, modulate: Color = Color.WHITE) -> void:
	if tex == null:
		return
	var sc := _base_scale()
	var foot := _iso_top(p) + Vector2(0, _th() * 0.62) + Vector2(0, -height)
	var w := size.x * sc
	var hgt := size.y * sc
	draw_texture_rect(tex, Rect2(foot - Vector2(w * 0.5, hgt), Vector2(w, hgt)), false, modulate)

func _dungeon_modulate(base: Color = Color.WHITE) -> Color:
	return base * Color(0.68, 0.74, 0.88)

func _draw() -> void:
	var s := _view_size()
	draw_rect(Rect2(Vector2.ZERO, Vector2(s.x, 68)), Color(0.09, 0.09, 0.11, 0.72))
	draw_string(font, Vector2(34, 35), "Dungeon Empire — Prototype v0.2", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, C_TEXT)
	draw_string(font, Vector2(34, 56), "clicks %d   mouse %d,%d   cell %s   zoom %.2f   yaw %d°" % [debug_clicks, int(debug_pointer.x), int(debug_pointer.y), _screen_to_grid(debug_pointer), cam_zoom, int(cam_yaw)], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_TREASURE_HIGHLIGHT)

	var storage := _storage_state()
	var phase := "RAID" if raid_active else "PREPARATION"
	var phase_color := C_HOT_ORANGE if raid_active else C_ARCANE_VIOLET
	if game_over:
		phase = "DEFEAT"
		phase_color = C_DANGER_RED
	var x := maxf(620.0, s.x * 0.48)
	x = _hud_segment(x, phase + "   ", phase_color, 17)
	x = _hud_segment(x, "Gold: %d/%d   " % [gold, int(storage["capacity"])], C_WARM_GOLD, 17)
	var loose := _unsecured_loot_total()
	if loose > 0:
		x = _hud_segment(x, "loot: %d   " % loose, C_HOT_ORANGE, 17)
	x = _hud_segment(x, "Core: %d%%   " % core_hp, C_DANGER_RED, 17)
	if _has_entrance() or raid_active:
		x = _hud_segment(x, "Raid: %02ds" % int(ceilf(raid_timer)), C_TEXT, 17)
	else:
		x = _hud_segment(x, "Raid: sealed", C_MOSS_GREEN, 17)

	if report != "":
		draw_string(font, Vector2(34, s.y - 132), report, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_PALE_STONE)
	draw_string(font, Vector2(34, s.y - 110), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, C_TEXT)

	if tool_buttons.is_empty():
		for b in _buttons():
			var rr: Rect2 = b["rect"]
			var tool := int(b["tool"])
			var label := String(b["label"])
			var cost := String(b["cost"])
			var bg := C_ANTHRACITE
			var border := C_MID_STONE
			if tool == selected_tool:
				bg = C_DEEP_VIOLET
				border = C_ARCANE_VIOLET
			if tool == Tool.RESET and reset_armed:
				bg = C_DANGER_RED.darkened(0.5)
				border = C_DANGER_RED
				label = "Confirm?"
			draw_rect(rr, bg)
			draw_rect(rr, border, false, 1)
			draw_string(font, rr.position + Vector2(8, 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_TEXT)
			draw_string(font, rr.position + Vector2(8, 40), cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_WARM_GOLD)

	if game_over:
		var box := Rect2(Vector2((s.x - 440) * 0.5, (s.y - 120) * 0.5), Vector2(440, 120))
		draw_rect(box, C_ANTHRACITE.darkened(0.35))
		draw_rect(box, C_DANGER_RED, false, 2)
		draw_string(font, box.position + Vector2(24, 50), "CAMPAIGN LOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, C_DANGER_RED)
		draw_string(font, box.position + Vector2(24, 86), "The Core was destroyed. Reset to start over.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_TEXT)
	elif raid_active:
		draw_string(font, Vector2(s.x - 205, s.y - 110), "Dungeon locked", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_DANGER_RED)
	else:
		draw_string(font, Vector2(s.x - 240, s.y - 110), "Loot / corpses clickable", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_PALE_STONE)
	draw_string(font, Vector2(maxf(34.0, s.x - 620), 56), "Q/E orbit · wheel zoom · WASD pan · right-drag pan · middle-drag orbit · 0 reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_PALE_STONE)
