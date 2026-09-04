class_name DungeonGame
extends Control

# Conductor: camera, HUD paint, input, and wiring. Rules live in scripts/game/.
# See docs/GODOT_PROJECT_STRUCTURE.md

const Tile := GameTypes.Tile
const Tool := GameTypes.Tool
const TILE_W := GameTypes.TILE_W
const TILE_H := GameTypes.TILE_H
const DESIGN_SIZE := GameTypes.DESIGN_SIZE
const ISO_ORIGIN_DESIGN := GameTypes.ISO_ORIGIN_DESIGN
const COLS := GameTypes.COLS
const ROWS := GameTypes.ROWS
const RAID_DELAY := GameTypes.RAID_DELAY
const CORE_MAX := GameTypes.CORE_MAX
const CORE_W := GameTypes.CORE_W
const CORE_H := GameTypes.CORE_H
const DOOR_MAX_HP := GameTypes.DOOR_MAX_HP
const TRAP_MAX_CHARGES := GameTypes.TRAP_MAX_CHARGES
const VAULT_CAPACITY := GameTypes.VAULT_CAPACITY
const START_GOLD := GameTypes.START_GOLD
const COST_DIG := GameTypes.COST_DIG
const COST_VAULT := GameTypes.COST_VAULT
const COST_SPIKE := GameTypes.COST_SPIKE
const COST_SNARE := GameTypes.COST_SNARE
const COST_VOID := GameTypes.COST_VOID
const COST_DOOR := GameTypes.COST_DOOR
const COST_REPAIR_DOOR := GameTypes.COST_REPAIR_DOOR
const COST_REPAIR_TRAP := GameTypes.COST_REPAIR_TRAP
const TURN_TIME := GameTypes.TURN_TIME
const DIRS := GameTypes.DIRS
const ROUTE_STEP := GameTypes.ROUTE_STEP
const ROUTE_TRAP := GameTypes.ROUTE_TRAP
const ROUTE_DOOR := GameTypes.ROUTE_DOOR
const ROUTE_REVISIT := GameTypes.ROUTE_REVISIT
const ROUTE_REVISIT_MAX := GameTypes.ROUTE_REVISIT_MAX
const ROUTE_BIAS := GameTypes.ROUTE_BIAS
const TOOLBAR_MARGIN := GameTypes.TOOLBAR_MARGIN
const BTN_X := GameTypes.BTN_X
const BTN_GAP := GameTypes.BTN_GAP
const BTN_H := GameTypes.BTN_H
const CORPSE_OFFSET := GameTypes.CORPSE_OFFSET
const BAG_OFFSET := GameTypes.BAG_OFFSET
const CLICK_RADIUS := GameTypes.CLICK_RADIUS
const ZOOM_MIN := GameTypes.ZOOM_MIN
const ZOOM_MAX := GameTypes.ZOOM_MAX
const ZOOM_DEFAULT := GameTypes.ZOOM_DEFAULT
const WORLD_RENDER_SCALE := GameTypes.WORLD_RENDER_SCALE
const YAW_DEFAULT := GameTypes.YAW_DEFAULT
const ORBIT_SPEED := GameTypes.ORBIT_SPEED
const ZOOM_STEP := GameTypes.ZOOM_STEP
const HUD_TOP := GameTypes.HUD_TOP
const PLAY_MARGIN := GameTypes.PLAY_MARGIN
const TRAITS := GameTypes.TRAITS
const C_ANTHRACITE := GameTypes.C_ANTHRACITE
const C_BLUE_GRAY := GameTypes.C_BLUE_GRAY
const C_MID_STONE := GameTypes.C_MID_STONE
const C_PALE_STONE := GameTypes.C_PALE_STONE
const C_DEEP_VIOLET := GameTypes.C_DEEP_VIOLET
const C_INFLUENCE_PURPLE := GameTypes.C_INFLUENCE_PURPLE
const C_ARCANE_VIOLET := GameTypes.C_ARCANE_VIOLET
const C_ENERGY_MAGENTA := GameTypes.C_ENERGY_MAGENTA
const C_DARK_GOLD := GameTypes.C_DARK_GOLD
const C_WARM_GOLD := GameTypes.C_WARM_GOLD
const C_TREASURE_HIGHLIGHT := GameTypes.C_TREASURE_HIGHLIGHT
const C_FOREST_GREEN := GameTypes.C_FOREST_GREEN
const C_MOSS_GREEN := GameTypes.C_MOSS_GREEN
const C_WARM_SAND := GameTypes.C_WARM_SAND
const C_VILLAGE_BEIGE := GameTypes.C_VILLAGE_BEIGE
const C_DANGER_RED := GameTypes.C_DANGER_RED
const C_HOT_ORANGE := GameTypes.C_HOT_ORANGE
const C_TEXT := GameTypes.C_TEXT
const C_BACKDROP := GameTypes.C_BACKDROP
const SPRITE_FILES := GameTypes.SPRITE_FILES

var sim: DungeonSim = DungeonSim.new()
var raid: RaidDirector = RaidDirector.new()
var toolbar: GameToolbar = GameToolbar.new()

var PORTAL_HOLD: float:
	get:
		return raid.portal_hold
	set(value):
		raid.portal_hold = value

var grid: Array:
	get:
		return sim.grid
	set(value):
		sim.grid = value

var selected_tool: int:
	get:
		return sim.selected_tool
	set(value):
		sim.selected_tool = value

var gold: int:
	get:
		return sim.gold
	set(value):
		sim.gold = value

var core_hp: int:
	get:
		return sim.core_hp
	set(value):
		sim.core_hp = value

var loot_bags: Array:
	get:
		return sim.loot_bags
	set(value):
		sim.loot_bags = value

var corpses: Array:
	get:
		return sim.corpses
	set(value):
		sim.corpses = value

var door_hp: Dictionary:
	get:
		return sim.door_hp
	set(value):
		sim.door_hp = value

var trap_charges: Dictionary:
	get:
		return sim.trap_charges
	set(value):
		sim.trap_charges = value

var message: String:
	get:
		return sim.message
	set(value):
		sim.message = value

var report: String:
	get:
		return sim.report
	set(value):
		sim.report = value

var game_over: bool:
	get:
		return sim.game_over
	set(value):
		sim.game_over = value

var reset_armed: bool:
	get:
		return sim.reset_armed
	set(value):
		sim.reset_armed = value

var raid_timer: float:
	get:
		return raid.raid_timer
	set(value):
		raid.raid_timer = value

var raid_active: bool:
	get:
		return raid.raid_active
	set(value):
		raid.raid_active = value

var raid_index: int:
	get:
		return raid.raid_index
	set(value):
		raid.raid_index = value

var hero: Dictionary:
	get:
		return raid.hero
	set(value):
		raid.hero = value

var raid_stats: Dictionary:
	get:
		return raid.raid_stats
	set(value):
		raid.raid_stats = value

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

func _init() -> void:
	raid.sim = sim
	sim.raid = raid
	toolbar.g = self

func _new_map() -> void:
	sim.new_map()
	raid.reset_for_new_map()
	_ensure_dungeon()
	if dungeon.has_method("clear_map"):
		dungeon.clear_map()
	_sync_world()
	queue_redraw()

func _has_entrance() -> bool:
	return sim._has_entrance()

func _unsecured_loot_total() -> int:
	return sim._unsecured_loot_total()

func _damaged_structure_count() -> int:
	return sim._damaged_structure_count()

func _inside(p: Vector2i) -> bool:
	return sim._inside(p)

func _walkable(p: Vector2i) -> bool:
	return sim._walkable(p)

func _is_trap_tile(t: int) -> bool:
	return sim._is_trap_tile(t)

func _trap_max_charges(t: int) -> int:
	return sim._trap_max_charges(t)

func _entrance_mouth(p: Vector2i) -> Vector2i:
	return sim._entrance_mouth(p)

func _can_step(from: Vector2i, to: Vector2i) -> bool:
	return sim._can_step(from, to)

func _door_intact(p: Vector2i) -> bool:
	return sim._door_intact(p)

func _core_origin() -> Vector2i:
	return sim._core_origin()

func _find_tile(tile: int) -> Vector2i:
	return sim._find_tile(tile)

func _storage_state() -> Dictionary:
	return sim._storage_state()

func _deposit_gold(amount: int) -> int:
	return sim._deposit_gold(amount)

func _build_at(gp: Vector2i) -> void:
	sim._build_at(gp)

func _repair_structures() -> void:
	sim._repair_structures()

func _start_raid() -> void:
	raid._start_raid()

func _update_hero(delta: float) -> void:
	raid._update_hero(delta)

func _resolve_cell(pos: Vector2i) -> void:
	raid._resolve_cell(pos)

func _storage_capacity() -> int:
	return sim._storage_capacity()

func _attack_door(p: Vector2i) -> void:
	raid._attack_door(p)

func _corpse_danger_near(p: Vector2i) -> float:
	return raid._corpse_danger_near(p)

func _end_raid(result_text: String) -> void:
	raid._end_raid(result_text)

func _kill_hero() -> void:
	raid._kill_hero()

func _btn_y() -> float:
	return toolbar._btn_y()

func _setup_toolbar_buttons() -> void:
	toolbar._setup_toolbar_buttons()

func _on_toolbar_button(tool: int) -> void:
	toolbar._on_toolbar_button(tool)

func _refresh_toolbar_buttons() -> void:
	toolbar._refresh_toolbar_buttons()

func _buttons() -> Array:
	return toolbar._buttons()

func _toolbar_hit(mp: Vector2) -> bool:
	return toolbar._toolbar_hit(mp)

func _handle_toolbar(mp: Vector2) -> void:
	toolbar._handle_toolbar(mp)

func _apply_toolbar_tool(tool: int) -> void:
	toolbar._apply_toolbar_tool(tool)

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
		dungeon = load("res://scripts/world/dungeon_world.gd").new()
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

func _layout_toolbar() -> void:
	toolbar._layout_toolbar()
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
		Tile.SPIKE, Tile.SNARE, Tile.VOID:
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
		Tile.VOID:
			return C_INFLUENCE_PURPLE.darkened(0.15)
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
