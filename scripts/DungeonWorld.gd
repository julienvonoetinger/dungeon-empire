extends Node3D

# Art bible: elevated orthographic camera ~35–45°. Same COLS×ROWS sim as Main.

const CELL := 1.0
const PITCH := -40.0
const YAW := 45.0
var _yaw := 45.0
const CAM_DIST := 36.0
const BASE_ORTHO := 15.5
const FLOOR_Y := 0.12
const ROCK_H := 1.12
const FLOOR_H := 0.16
const MESH_PAD := 1.002
const WALL_THICK := 0.22
const PILLAR_W := 0.28
const WALL_JOIN := 0.1
const MESH_VER := 85
const CORE_GLB := "res://assets/models/core_healthy.glb"
const ROCK_GLB := "res://assets/models/walls/rock_block_match_door_v2.glb"
const WALL_STRAIGHT_GLB := "res://assets/models/walls/wall_straight_meshy.glb"
const WALL_PILLAR_GLB := "res://assets/models/walls/wall_pillar_meshy.glb"
const FLOOR_GLB := "res://assets/models/floors/floor_violet_rift.glb"
const STAIRS_GLB := "res://assets/models/environment/entrance_stairs.glb"
const SPIKE_GLB := "res://assets/models/traps/spike_voidspike.glb"
const SPIKE_SPRUNG_GLB := "res://assets/models/traps/spike_voidspike_sprung.glb"
const SPIKE_BROKEN_GLB := "res://assets/models/traps/spike_voidspike_broken.glb"
const DOOR_CLOSED_GLB := "res://assets/models/doors/door_violet_crypt_gate.glb"
const DOOR_DAMAGED_GLB := "res://assets/models/doors/door_shadowgem_gate.glb"
const DOOR_DESTROYED_GLB := "res://assets/models/doors/door_violet_ruin_gateway.glb"
const DOOR_OPENED_GLB := "res://assets/models/doors/door_opened.glb"
const VAULT_GLB := "res://assets/models/storage/vault_skull_treasure.glb"
const VAULT_EMPTY_GLB := "res://assets/models/storage/vault_empty_reliquary.glb"
var camera: Camera3D
var _sun: DirectionalLight3D
var _fill: OmniLight3D
var _cells: Dictionary = {}
var _hero: MeshInstance3D
var _hero_bar: MeshInstance3D
var _hero_tag: Label3D
var _core_spin: Node3D
var _core_inner: Node3D
var _core_drift: Node3D
var _core_vortex: Node3D
var _core_bolts: Array = []
var _core_debris: Array = []
var _spark_cd := 0.0
var _core_pulse := 0.0
var _core_fill_base := 0.95
var _core_vr := 0.22
var _core_base_y := 0.48
var _core_emit_mat: StandardMaterial3D
var _mat_rock: StandardMaterial3D
var _mat_floor: StandardMaterial3D
var _mat_dark: StandardMaterial3D
var _mat_void: StandardMaterial3D
var _mat_moss: StandardMaterial3D
var _mat_sand: StandardMaterial3D
var _mat_vein: StandardMaterial3D
var _mat_obsidian: StandardMaterial3D
var _mat_pool: StandardMaterial3D
var _mat_glint: StandardMaterial3D
var _mat_arc: StandardMaterial3D
var _mat_spark: StandardMaterial3D
var _mat_shell: StandardMaterial3D
var _mat_vortex: StandardMaterial3D
var _mat_wood: StandardMaterial3D
var _mat_iron: StandardMaterial3D
var _last_sig: Dictionary = {}
var _look := Vector3.ZERO
var _marker_sig := ""
var _rng := RandomNumberGenerator.new()
var _door_ref_scale := 0.0
var _door_stone_sh: Shader
var _wall_packed: Dictionary = {}
var _pillar_sig := ""
var _pillar_root: Node3D

func _init() -> void:
	_look = Vector3(10.0, 0.0, 6.0)
	_make_materials()
	_make_camera()
	_rng.seed = 7

func _ready() -> void:
	_make_environment()
	_make_hero()

func _make_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#17161B")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#3B414C")
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.light_color = Color(0.92, 0.94, 1.0)
	_sun.light_energy = 1.15
	_sun.shadow_enabled = true
	_sun.rotation_degrees = Vector3(-52, 38, 0)
	add_child(_sun)
	_fill = OmniLight3D.new()
	_fill.light_color = Color("#9B4DB5")
	_fill.light_energy = 0.0
	_fill.omni_range = 6.0
	add_child(_fill)

func _make_materials() -> void:
	_mat_rock = _tex_mat("res://assets/sprites/wrap_rock.png", false)
	_mat_floor = _tex_mat("res://assets/sprites/wrap_floor.png", true)
	_mat_dark = StandardMaterial3D.new()
	_mat_dark.albedo_color = Color(0.04, 0.04, 0.055)
	_mat_dark.roughness = 0.92
	_mat_void = StandardMaterial3D.new()
	_mat_void.albedo_color = Color(0.015, 0.012, 0.02)
	_mat_void.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_void.roughness = 1.0
	_mat_moss = StandardMaterial3D.new()
	_mat_moss.albedo_color = Color("#819568")
	_mat_moss.roughness = 0.9
	_mat_sand = StandardMaterial3D.new()
	_mat_sand.albedo_color = Color("#C9AC7A")
	_mat_sand.roughness = 0.85
	_mat_vein = StandardMaterial3D.new()
	_mat_vein.albedo_color = Color("#683276")
	_mat_vein.emission_enabled = true
	_mat_vein.emission = Color("#9B4DB5")
	_mat_vein.emission_energy_multiplier = 0.55
	_mat_vein.roughness = 0.4
	_mat_obsidian = StandardMaterial3D.new()
	_mat_obsidian.albedo_color = Color(0.06, 0.03, 0.1)
	_mat_obsidian.metallic = 0.85
	_mat_obsidian.roughness = 0.12
	_mat_obsidian.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mat_pool = StandardMaterial3D.new()
	_mat_pool.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_pool.albedo_color = Color("#9B4DB5")
	_mat_pool.emission_enabled = true
	_mat_pool.emission = Color("#CE72DF")
	_mat_pool.emission_energy_multiplier = 1.4
	_mat_glint = StandardMaterial3D.new()
	_mat_glint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_glint.albedo_color = Color(0.95, 0.9, 1.0)
	_mat_glint.emission_enabled = true
	_mat_glint.emission = Color(0.85, 0.75, 1.0)
	_mat_glint.emission_energy_multiplier = 2.4
	_mat_arc = StandardMaterial3D.new()
	_mat_arc.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_arc.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_arc.albedo_color = Color(0.61, 0.3, 0.71, 0.45)
	_mat_arc.emission_enabled = true
	_mat_arc.emission = Color("#9B4DB5")
	_mat_arc.emission_energy_multiplier = 0.7
	_mat_spark = StandardMaterial3D.new()
	_mat_spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_spark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_spark.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_spark.albedo_color = Color(0.82, 0.52, 1.0, 1.0)
	_mat_spark.emission_enabled = true
	_mat_spark.emission = Color("#CE72DF")
	_mat_spark.emission_energy_multiplier = 2.4
	_mat_spark.disable_receive_shadows = true
	_mat_shell = StandardMaterial3D.new()
	_mat_shell.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_shell.albedo_color = Color(0.04, 0.02, 0.07, 0.42)
	_mat_shell.metallic = 0.92
	_mat_shell.roughness = 0.08
	_mat_shell.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_shell.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_mat_vortex = StandardMaterial3D.new()
	_mat_vortex.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_vortex.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_vortex.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat_vortex.albedo_color = Color(0.72, 0.38, 0.95, 0.7)
	_mat_vortex.emission_enabled = true
	_mat_vortex.emission = Color("#9B4DB5")
	_mat_vortex.emission_energy_multiplier = 1.6
	_mat_vortex.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_vortex.disable_receive_shadows = true
	_mat_wood = StandardMaterial3D.new()
	_mat_wood.albedo_color = Color("#8B6A45")
	_mat_wood.roughness = 0.78
	_mat_iron = StandardMaterial3D.new()
	_mat_iron.albedo_color = Color("#2A2C32")
	_mat_iron.metallic = 0.65
	_mat_iron.roughness = 0.4

func _rock_mat(_p: Vector2i) -> StandardMaterial3D:
	return _mat_rock

func _apply_triplanar(m: StandardMaterial3D, scale: float) -> void:
	m.uv1_scale = Vector3(scale, scale, scale)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

func _tex_mat(path: String, emit_floor: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		m.albedo_texture = tex
		_apply_triplanar(m, 0.42)
	else:
		m.albedo_color = Color("#3B414C") if emit_floor else Color("#25232A")
	m.roughness = 0.82
	m.metallic = 0.04
	if emit_floor:
		m.emission_enabled = true
		m.emission = Color("#40204F")
		m.emission_energy_multiplier = 0.22
	return m

func _make_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	camera.near = 0.05
	camera.far = 120.0
	add_child(camera)

func _make_hero() -> void:
	_hero = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.18
	cap.height = 0.62
	_hero.mesh = cap
	_hero.visible = false
	add_child(_hero)
	_hero_bar = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.42, 0.05, 0.05)
	_hero_bar.mesh = bar
	_hero_bar.visible = false
	add_child(_hero_bar)
	_hero_tag = Label3D.new()
	_hero_tag.font_size = 48
	_hero_tag.pixel_size = 0.004
	_hero_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hero_tag.outline_render_priority = 1
	_hero_tag.outline_size = 4
	_hero_tag.visible = false
	add_child(_hero_tag)

func clear_map() -> void:
	for k in _cells.keys():
		(_cells[k] as Node).queue_free()
	_cells.clear()
	_last_sig.clear()
	_marker_sig = ""
	_pillar_sig = ""
	if _pillar_root != null:
		_pillar_root.queue_free()
		_pillar_root = null
	if _core_spin != null:
		_core_spin.queue_free()
		_core_spin = null
	_core_inner = null
	_core_drift = null
	_core_vortex = null
	_core_emit_mat = null
	_core_bolts.clear()
	_core_debris.clear()
	if _fill != null:
		_fill.light_energy = 0.0

func map_center(cols: int, rows: int) -> Vector3:
	return Vector3(float(cols) * 0.5 * CELL, 0.0, float(rows) * 0.5 * CELL)

func ortho_size(zoom: float) -> float:
	return BASE_ORTHO / maxf(zoom, 0.05)

func apply_camera(zoom: float, pan: Vector2, view: Vector2, cols: int, rows: int, yaw: float = 45.0) -> void:
	if camera == null:
		return
	_yaw = yaw
	camera.size = ortho_size(zoom)
	var k := camera.size / maxf(view.y, 1.0)
	var b := _cam_basis()
	var right := b.x
	right.y = 0.0
	if right.length() > 0.001:
		right = right.normalized()
	var fwd := -b.z
	fwd.y = 0.0
	if fwd.length() > 0.001:
		fwd = fwd.normalized()
	_look = map_center(cols, rows) + right * pan.x * k + fwd * (-pan.y) * k
	camera.transform = Transform3D(b, _look + b.z * CAM_DIST)

func _cam_basis() -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(PITCH), deg_to_rad(_yaw), 0.0))

func cell_center(p: Vector2i, height: float = FLOOR_Y) -> Vector3:
	return Vector3((float(p.x) + 0.5) * CELL, height, (float(p.y) + 0.5) * CELL)

func tile_height(t: int, game: Node) -> float:
	if t == game.Tile.ENTRANCE:
		return ROCK_H
	if t == game.Tile.ROCK:
		return ROCK_H
	if t == game.Tile.DOOR:
		return 1.08
	if t == game.Tile.VAULT:
		return 0.72
	if t == game.Tile.CORE:
		return 0.9
	return FLOOR_H

func cell_to_screen(p: Vector2i, view: Vector2, zoom: float, pan: Vector2, cols: int, rows: int, yaw: float = 45.0, game: Node = null) -> Vector2:
	apply_camera(zoom, pan, view, cols, rows, yaw)
	var hy := FLOOR_H
	if game != null and p.y >= 0 and p.y < game.grid.size() and p.x >= 0 and p.x < (game.grid[p.y] as Array).size():
		hy = tile_height(int(game.grid[p.y][p.x]), game)
	return _world_to_screen(cell_center(p, hy), view, zoom)

func _world_to_screen(world: Vector3, view: Vector2, zoom: float) -> Vector2:
	return _world_to_screen_math(world, view, zoom)

func _world_to_screen_math(world: Vector3, view: Vector2, zoom: float) -> Vector2:
	var xf := Transform3D(_cam_basis(), _look + _cam_basis().z * CAM_DIST)
	var local: Vector3 = xf.affine_inverse() * world
	var size := ortho_size(zoom)
	var half_h := size * 0.5
	var half_w := half_h * (view.x / maxf(view.y, 1.0))
	return Vector2((local.x / half_w * 0.5 + 0.5) * view.x, (-local.y / half_h * 0.5 + 0.5) * view.y)

func _screen_ray(screen: Vector2, view: Vector2, zoom: float) -> Array:
	var size := ortho_size(zoom)
	var half_h := size * 0.5
	var half_w := half_h * (view.x / maxf(view.y, 1.0))
	var nx := (screen.x / maxf(view.x, 1.0) - 0.5) * 2.0 * half_w
	var ny := -(screen.y / maxf(view.y, 1.0) - 0.5) * 2.0 * half_h
	var xf := Transform3D(_cam_basis(), _look + _cam_basis().z * CAM_DIST)
	var origin: Vector3 = xf * Vector3(nx, ny, 0.0)
	var dir: Vector3 = (xf.basis * Vector3(0, 0, -1)).normalized()
	return [origin, dir]

func screen_to_ground(screen: Vector2, view: Vector2, zoom: float) -> Vector3:
	var ray := _screen_ray(screen, view, zoom)
	var origin: Vector3 = ray[0]
	var dir: Vector3 = ray[1]
	if absf(dir.y) < 0.0001:
		return _look
	var t := (FLOOR_Y - origin.y) / dir.y
	return origin + dir * t

func _ray_aabb_t(origin: Vector3, dir: Vector3, aabb: AABB) -> float:
	var mn := aabb.position
	var mx := aabb.end
	var tmin := -INF
	var tmax := INF
	var orig := [origin.x, origin.y, origin.z]
	var d := [dir.x, dir.y, dir.z]
	var a0 := [mn.x, mn.y, mn.z]
	var a1 := [mx.x, mx.y, mx.z]
	for i in 3:
		if absf(d[i]) < 0.0000001:
			if orig[i] < a0[i] or orig[i] > a1[i]:
				return -1.0
		else:
			var t1: float = (a0[i] - orig[i]) / d[i]
			var t2: float = (a1[i] - orig[i]) / d[i]
			if t1 > t2:
				var tmp := t1
				t1 = t2
				t2 = tmp
			tmin = maxf(tmin, t1)
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return -1.0
	if tmax < 0.0:
		return -1.0
	if tmin >= 0.0:
		return tmin
	return tmax

func screen_to_cell(screen: Vector2, view: Vector2, zoom: float, pan: Vector2, cols: int, rows: int, yaw: float = 45.0, game: Node = null) -> Vector2i:
	apply_camera(zoom, pan, view, cols, rows, yaw)
	if game != null and not game.grid.is_empty():
		var ray := _screen_ray(screen, view, zoom)
		var origin: Vector3 = ray[0]
		var dir: Vector3 = ray[1]
		var best_t := INF
		var best := Vector2i(-1, -1)
		for y in rows:
			for x in cols:
				var p := Vector2i(x, y)
				var h := tile_height(int(game.grid[y][x]), game)
				var aabb := AABB(Vector3(float(x) * CELL, 0.0, float(y) * CELL), Vector3(CELL, h, CELL))
				var t := _ray_aabb_t(origin, dir, aabb)
				if t >= 0.0 and t < best_t:
					best_t = t
					best = p
		if best.x >= 0:
			return best
	var hit := screen_to_ground(screen, view, zoom)
	return Vector2i(floori(hit.x / CELL), floori(hit.z / CELL))

func sync(game: Node) -> void:
	if camera == null:
		return
	var cols: int = game.COLS
	var rows: int = game.ROWS
	var view: Vector2 = game._play_view()
	apply_camera(game.cam_zoom, game.cam_pan, view, cols, rows, float(game.cam_yaw))
	var grid: Array = game.grid
	if grid.is_empty():
		return
	var vaults: Dictionary = game._storage_state()["vaults"]
	for y in rows:
		for x in cols:
			var p := Vector2i(x, y)
			var t: int = int(grid[y][x])
			var spent: bool = (t == game.Tile.SPIKE or t == game.Tile.SNARE) and int(game.trap_charges.get(p, game.TRAP_MAX_CHARGES)) <= 0
			var sig := "m%d:%d:%d:%s" % [MESH_VER, t, int(vaults.get(p, 0)), spent]
			if t == game.Tile.SPIKE:
				sig += ":s%d" % int(_spike_sprung(p, game))
			if t == game.Tile.ENTRANCE:
				var o := _entrance_face(p, game)
				sig += ":e%.0f,%.0f" % [o.x, o.z]
			if t == game.Tile.ROCK:
				sig += ":f%d" % _rock_face_mask(p, game)
				var co := _cliff_outward_for_rock(p, game)
				if co != Vector3.ZERO:
					sig += ":c%.0f,%.0f" % [co.x, co.z]
			if t == game.Tile.CORE:
				sig += ":h%d" % _core_band(int(game.core_hp))
			if t == game.Tile.DOOR:
				sig += ":%d:y%.2f:%s" % [int(game.door_hp.get(p, game.DOOR_MAX_HP)), _door_yaw(p, game), DOOR_CLOSED_GLB.get_file()]
			if t == game.Tile.VAULT:
				var vf := _vault_open_face(p, game)
				sig += ":v%.0f,%.0f" % [vf.x, vf.z]
			if str(_last_sig.get(p, "")) != sig:
				_last_sig[p] = sig
				_rebuild_cell(p, t, game, vaults, spent)
	_sync_pillars(game)
	_sync_markers(game)
	_sync_hero(game)

func _rebuild_cell(p: Vector2i, t: int, game: Node, vaults: Dictionary, spent: bool) -> void:
	if _cells.has(p):
		var old: Node = _cells[p]
		remove_child(old)
		old.queue_free()
		_cells.erase(p)
	var root := Node3D.new()
	root.position = Vector3(float(p.x) * CELL, 0, float(p.y) * CELL)
	add_child(root)
	_cells[p] = root
	match t:
		game.Tile.ROCK:
			_build_rock(root, p, game)
		game.Tile.FLOOR:
			_add_floor_tile(root)
		game.Tile.ENTRANCE:
			_build_entrance(root, p, game)
		game.Tile.CORE:
			_add_floor_tile(root)
			if p == game._core_origin():
				_build_core(root, p, game)
		game.Tile.VAULT:
			_add_floor_tile(root)
			var gold_amt := int(vaults.get(p, 0))
			if not _add_fitted_vault(root, gold_amt <= 0, _vault_open_face(p, game)):
				var gold_m := StandardMaterial3D.new()
				gold_m.albedo_color = Color("#D4A83E") if gold_amt > 0 else Color("#6A6458")
				gold_m.metallic = 0.45
				gold_m.roughness = 0.4
				gold_m.emission_enabled = gold_amt > 8
				gold_m.emission = Color("#80652A")
				gold_m.emission_energy_multiplier = 0.35
				_add_box(root, Vector3(0.62, 0.55, 0.62), Vector3(CELL * 0.5, 0.42, CELL * 0.5), gold_m)
			_label(root, str(gold_amt), Color("#FFD878"), Vector3(CELL * 0.5, 1.05, CELL * 0.5))
		game.Tile.SPIKE:
			if not _add_fitted_spike(root, spent, _spike_sprung(p, game)):
				_add_floor_tile(root)
				var sm := StandardMaterial3D.new()
				sm.albedo_color = Color("#A74747") if not spent else Color("#555765")
				sm.roughness = 0.35
				for i in 5:
					var cone := CylinderMesh.new()
					cone.top_radius = 0.0
					cone.bottom_radius = 0.07
					cone.height = 0.55 if not spent else 0.18
					var mi := MeshInstance3D.new()
					mi.mesh = cone
					mi.material_override = sm
					var a := TAU * float(i) / 5.0
					mi.position = Vector3(CELL * 0.5 + cos(a) * 0.18, 0.38, CELL * 0.5 + sin(a) * 0.18)
					root.add_child(mi)
			_label(root, str(int(game.trap_charges.get(p, game.TRAP_MAX_CHARGES))), Color("#D9783C"), Vector3(CELL * 0.5, 0.85, CELL * 0.5))
		game.Tile.SNARE:
			_add_floor_tile(root)
			var nm := StandardMaterial3D.new()
			nm.albedo_color = Color("#40204F") if not spent else Color("#3B414C")
			nm.roughness = 0.7
			for i in 4:
				var vine := _add_box(root, Vector3(0.08, 0.08, 0.72), Vector3(CELL * 0.5, 0.28, CELL * 0.5), nm)
				vine.rotation.y = PI * 0.25 * float(i)
			_label(root, str(int(game.trap_charges.get(p, game.TRAP_MAX_CHARGES))), Color("#D9783C"), Vector3(CELL * 0.5, 0.7, CELL * 0.5))
		game.Tile.DOOR:
			_build_door(root, p, game)
		_:
			_add_floor_tile(root)

func _entrance_outward(p: Vector2i, game: Node) -> Vector3:
	var m: Vector2i = game._entrance_mouth(p)
	if m == Vector2i.ZERO:
		return Vector3(-1, 0, 0)
	return Vector3(-float(m.x), 0.0, -float(m.y))

func _entrance_face(p: Vector2i, game: Node) -> Vector3:
	# Point the mouth at the corridor. Default yaw 45 sees south and east faces,
	# so a west-only hole sits on the hidden back of the hillside.
	return -_entrance_outward(p, game)

func _outside_cell(ent: Vector2i, game: Node) -> Vector2i:
	var o := _entrance_outward(ent, game)
	return ent + Vector2i(roundi(o.x), roundi(o.z))

func _cliff_outward_for_rock(p: Vector2i, game: Node) -> Vector3:
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var n: Vector2i = p + d
		if not game._inside(n):
			continue
		if int(game.grid[n.y][n.x]) != game.Tile.ENTRANCE:
			continue
		if _outside_cell(n, game) == p:
			return _entrance_face(n, game)
	return Vector3.ZERO

func _core_band(hp: int) -> int:
	if hp <= 20:
		return 3
	if hp <= 45:
		return 0
	if hp <= 80:
		return 1
	return 2

func _add_sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material, shadow: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = 24
	sph.rings = 16
	mi.mesh = sph
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _add_cyl(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	return _add_funnel(parent, radius, radius, height, pos, mat, rot)

func _add_funnel(parent: Node3D, top_r: float, bot_r: float, height: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = height
	cyl.radial_segments = 20
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

func _add_well_ring(parent: Node3D, pos: Vector3, outer_r: float, inner_r: float, height: float, mat: Material) -> void:
	var comb := CSGCombiner3D.new()
	comb.material_override = mat
	comb.position = pos
	parent.add_child(comb)
	var body := CSGCylinder3D.new()
	body.radius = outer_r
	body.height = height
	body.sides = 18
	comb.add_child(body)
	var hole := CSGCylinder3D.new()
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	hole.radius = inner_r
	hole.height = height + 0.08
	hole.sides = 16
	comb.add_child(hole)

func _build_core(root: Node3D, _p: Vector2i, game: Node) -> void:
	var band := _core_band(int(game.core_hp))
	var span_x := float(int(game.CORE_W)) * CELL
	var span_z := float(int(game.CORE_H)) * CELL
	var mid := Vector3(span_x * 0.5, 0.0, span_z * 0.5)
	var fit := span_x * 0.94
	if band == 0:
		fit = span_x * 0.86
	elif band == 2:
		fit = span_x * 0.98
	elif band == 3:
		fit = span_x * 0.90
	if _core_spin != null:
		_core_spin.queue_free()
	_core_spin = Node3D.new()
	_core_spin.position = mid
	root.add_child(_core_spin)
	_core_inner = null
	_core_drift = null
	_core_vortex = null
	_core_debris.clear()
	_core_bolts.clear()
	if _add_fitted_model(_core_spin, CORE_GLB, fit) == null:
		_add_sphere(_core_spin, 0.55, Vector3(0.0, 0.7, 0.0), _mat_shell, true)
	if _fill != null:
		_fill.light_energy = 0.0

func _add_fitted_model(parent: Node3D, path: String, footprint: float) -> Node3D:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate()
	if inst == null:
		return null
	parent.add_child(inst)
	var aabb := _model_aabb(inst)
	if aabb.size == Vector3.ZERO:
		return inst
	var span := maxf(aabb.size.x, aabb.size.z)
	var s := footprint / maxf(span, 0.01)
	inst.scale = Vector3.ONE * s
	inst.position.y = FLOOR_H - aabb.position.y * s
	_prep_core_meshes(inst)
	return inst

func _build_rock(root: Node3D, p: Vector2i, game: Node) -> void:
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not _rock_faces_dug(p, d, game):
			continue
		if not _add_edge_wall(root, d):
			_add_edge_wall_box(root, d)

func _rock_face_mask(p: Vector2i, game: Node) -> int:
	var m := 0
	var i := 0
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _rock_faces_dug(p, d, game):
			m |= 1 << i
		i += 1
	return m

func _rock_faces_dug(p: Vector2i, d: Vector2i, game: Node) -> bool:
	var n: Vector2i = p + d
	return game._inside(n) and int(game.grid[n.y][n.x]) != game.Tile.ROCK

func _wall_scene(path: String) -> PackedScene:
	if not _wall_packed.has(path):
		if ResourceLoader.exists(path):
			_wall_packed[path] = load(path)
		else:
			_wall_packed[path] = null
	return _wall_packed[path] as PackedScene

func _add_floor_tile(root: Node3D) -> void:
	if _add_fitted_floor(root):
		return
	_add_box(root, Vector3(MESH_PAD, FLOOR_H, MESH_PAD), Vector3(CELL * 0.5, FLOOR_H * 0.5, CELL * 0.5), _mat_floor)

func _add_fitted_floor(root: Node3D) -> bool:
	var packed := _wall_scene(FLOOR_GLB)
	if packed == null:
		return false
	var holder := Node3D.new()
	holder.position = Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	root.add_child(holder)
	var inst := packed.instantiate()
	if inst == null:
		holder.queue_free()
		return false
	holder.add_child(inst)
	var aabb := _model_aabb(inst)
	if aabb.size == Vector3.ZERO:
		return true
	var span := maxf(aabb.size.x, aabb.size.z)
	inst.scale = Vector3(
		CELL / maxf(span, 0.01),
		FLOOR_H / maxf(aabb.size.y, 0.01),
		CELL / maxf(span, 0.01)
	)
	var fitted := _model_aabb(inst)
	inst.position.x += -fitted.get_center().x
	inst.position.z += -fitted.get_center().z
	inst.position.y += -fitted.position.y
	_prep_core_meshes(inst)
	return true

func _spike_sprung(p: Vector2i, game: Node) -> bool:
	if game.hero.is_empty():
		return false
	return game.hero.get("trap_sprung_at", Vector2i(-1, -1)) == p

func _add_fitted_spike(root: Node3D, spent: bool, sprung: bool) -> bool:
	var path := SPIKE_GLB
	if sprung:
		path = SPIKE_SPRUNG_GLB
	elif spent:
		path = SPIKE_BROKEN_GLB
	var packed := _wall_scene(path)
	if packed == null:
		packed = _wall_scene(SPIKE_GLB)
	if packed == null:
		return false
	var holder := Node3D.new()
	holder.position = Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	root.add_child(holder)
	var inst := packed.instantiate()
	if inst == null:
		holder.queue_free()
		return false
	holder.add_child(inst)
	var aabb := _model_aabb(inst)
	if aabb.size == Vector3.ZERO:
		return true
	var span := maxf(aabb.size.x, aabb.size.z)
	var s := CELL / maxf(span, 0.01)
	inst.scale = Vector3.ONE * s
	var fitted := _model_aabb(inst)
	inst.position.x += -fitted.get_center().x
	inst.position.z += -fitted.get_center().z
	inst.position.y += -fitted.position.y
	_prep_core_meshes(inst)
	return true

func _vault_open_face(p: Vector2i, game: Node) -> Vector3:
	var wall := _vault_wall_dir(p, game)
	if wall != Vector2i.ZERO:
		return Vector3(-float(wall.x), 0.0, -float(wall.y))
	var core: Vector2i = game._core_origin()
	var dx := core.x - p.x
	var dz := core.y - p.y
	if dx == 0 and dz == 0:
		return Vector3(0, 0, -1)
	return Vector3(float(dx), 0.0, float(dz))

func _vault_wall_dir(p: Vector2i, game: Node) -> Vector2i:
	var rocks: Array[Vector2i] = []
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _door_is_rock(p + d, game):
			rocks.append(d)
	if rocks.is_empty():
		return Vector2i.ZERO
	if rocks.size() == 1:
		return rocks[0]
	for d in rocks:
		var along := Vector2i(-d.y, d.x)
		for s in [-1, 1]:
			var n: Vector2i = p + along * s
			if not game._inside(n):
				continue
			if int(game.grid[n.y][n.x]) != game.Tile.VAULT:
				continue
			if _door_is_rock(n + d, game):
				return d
	var core: Vector2i = game._core_origin()
	var best := rocks[0]
	var best_score := -INF
	for d in rocks:
		var w: Vector2i = p + d
		var score := float(absi(w.x - core.x) + absi(w.y - core.y))
		if game._walkable(p - d):
			score += 10.0
		if score > best_score:
			best_score = score
			best = d
	return best

func _add_fitted_vault(root: Node3D, empty: bool, face: Vector3) -> bool:
	var path := VAULT_EMPTY_GLB if empty else VAULT_GLB
	var packed := _wall_scene(path)
	if packed == null:
		packed = _wall_scene(VAULT_GLB)
	if packed == null:
		return false
	var holder := Node3D.new()
	holder.position = Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	holder.rotation.y = atan2(face.x, face.z)
	root.add_child(holder)
	var inst := packed.instantiate()
	if inst == null:
		holder.queue_free()
		return false
	holder.add_child(inst)
	var aabb := _model_aabb(inst)
	if aabb.size == Vector3.ZERO:
		return true
	var span := maxf(aabb.size.x, aabb.size.z)
	var s := (CELL * 0.78) / maxf(span, 0.01)
	inst.scale = Vector3.ONE * s
	var fitted := _model_aabb(inst)
	inst.position.x += -fitted.get_center().x
	inst.position.z += -fitted.get_center().z
	inst.position.y += FLOOR_H - fitted.position.y
	_prep_core_meshes(inst)
	return true

func _pillar_gap() -> float:
	# Negative = walls overlap the pillars so the visible stone meets.
	return -WALL_JOIN if _wall_scene(WALL_PILLAR_GLB) != null else 0.0

func _sync_pillars(game: Node) -> void:
	var pts := _wall_joint_positions(game)
	pts.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		if a.z == b.z:
			return a.x < b.x
		return a.z < b.z
	)
	var sig := "p%d" % MESH_VER
	for p in pts:
		sig += ":%.2f,%.2f" % [p.x, p.z]
	if sig == _pillar_sig:
		return
	_pillar_sig = sig
	if _pillar_root != null:
		_pillar_root.queue_free()
	_pillar_root = Node3D.new()
	_pillar_root.name = "WallPillars"
	add_child(_pillar_root)
	for p in pts:
		_add_pillar(_pillar_root, p)

func _wall_joint_positions(game: Node) -> Array[Vector3]:
	var dirs_at: Dictionary = {}
	var rows: int = game.ROWS
	var cols: int = game.COLS
	for y in rows:
		for x in cols:
			if int(game.grid[y][x]) != game.Tile.ROCK:
				continue
			var p := Vector2i(x, y)
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not _rock_faces_dug(p, d, game):
					continue
				for v in _face_verts(p, d):
					if not dirs_at.has(v):
						dirs_at[v] = []
					var arr: Array = dirs_at[v]
					var got := false
					for existing in arr:
						if existing == d:
							got = true
							break
					if not got:
						arr.append(d)
	var seen: Dictionary = {}
	var out: Array[Vector3] = []
	for v in dirs_at.keys():
		var vv: Vector2i = v
		var dirs: Array = dirs_at[vv]
		var inner := Vector3(float(vv.x) * CELL, 0.0, float(vv.y) * CELL)
		_remember_pillar(seen, out, inner)
		if dirs.size() == 2:
			var a: Vector2i = dirs[0]
			var b: Vector2i = dirs[1]
			if a.x * b.x + a.y * b.y == 0:
				var back := Vector3(-float(a.x + b.x), 0.0, -float(a.y + b.y)) * (WALL_THICK * 0.6)
				_remember_pillar(seen, out, inner + back)
				continue
		for d in dirs:
			var dd: Vector2i = d
			_remember_pillar(seen, out, inner + Vector3(-float(dd.x), 0.0, -float(dd.y)) * WALL_THICK)
	return out

func _remember_pillar(seen: Dictionary, out: Array[Vector3], pos: Vector3) -> void:
	var key := Vector2i(roundi(pos.x * 40.0), roundi(pos.z * 40.0))
	if seen.has(key):
		return
	seen[key] = true
	out.append(pos)

func _face_verts(p: Vector2i, toward: Vector2i) -> Array[Vector2i]:
	var x0 := p.x
	var z0 := p.y
	var x1 := p.x + 1
	var z1 := p.y + 1
	if toward == Vector2i.LEFT:
		return [Vector2i(x0, z0), Vector2i(x0, z1)]
	if toward == Vector2i.RIGHT:
		return [Vector2i(x1, z0), Vector2i(x1, z1)]
	if toward == Vector2i.UP:
		return [Vector2i(x0, z0), Vector2i(x1, z0)]
	return [Vector2i(x0, z1), Vector2i(x1, z1)]

func _add_pillar(parent: Node3D, pos: Vector3) -> void:
	var packed := _wall_scene(WALL_PILLAR_GLB)
	if packed == null:
		return
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	var inst := packed.instantiate()
	if inst == null:
		holder.queue_free()
		return
	holder.add_child(inst)
	var aabb := _model_aabb(inst)
	if aabb.size == Vector3.ZERO:
		return
	var span := maxf(aabb.size.x, aabb.size.z)
	var s := PILLAR_W / maxf(span, 0.01)
	inst.scale = Vector3(s, ROCK_H / maxf(aabb.size.y, 0.01), s)
	var fitted := _model_aabb(inst)
	inst.position.x += -fitted.get_center().x
	inst.position.z += -fitted.get_center().z
	inst.position.y += -fitted.position.y
	_prep_core_meshes(inst)

func _add_edge_wall(root: Node3D, toward: Vector2i) -> bool:
	var packed := _wall_scene(WALL_STRAIGHT_GLB)
	if packed == null:
		packed = _wall_scene(ROCK_GLB)
	if packed == null:
		return false
	var gap := _pillar_gap()
	var holder := Node3D.new()
	holder.rotation.y = 0.0 if toward.y != 0 else PI * 0.5
	root.add_child(holder)
	var inst := packed.instantiate()
	if inst == null:
		holder.queue_free()
		return false
	holder.add_child(inst)
	var aabb := _model_aabb(inst)
	if aabb.size == Vector3.ZERO:
		return true
	if aabb.size.z > aabb.size.x + 0.02:
		inst.rotation.y += PI * 0.5
		aabb = _model_aabb(inst)
	var z_s := 1.0 if aabb.size.z <= WALL_THICK * 1.5 else WALL_THICK / maxf(aabb.size.z, 0.01)
	var wall_len := CELL - gap
	inst.scale = Vector3(
		wall_len / maxf(aabb.size.x, 0.01),
		ROCK_H / maxf(aabb.size.y, 0.01),
		z_s
	)
	var fitted := _model_aabb(inst)
	inst.position.x += -fitted.get_center().x
	inst.position.z += -fitted.get_center().z
	inst.position.y += -fitted.position.y
	var thick: float = maxf(fitted.size.z, 0.08)
	holder.position = Vector3(
		CELL * 0.5 + float(toward.x) * (CELL * 0.5 - thick * 0.5),
		0.0,
		CELL * 0.5 + float(toward.y) * (CELL * 0.5 - thick * 0.5)
	)
	_prep_core_meshes(inst)
	return true

func _add_edge_wall_box(root: Node3D, toward: Vector2i) -> void:
	var gap := _pillar_gap()
	var wall_len := CELL - gap
	var along_z: bool = toward.x != 0
	var sz := Vector3(WALL_THICK, ROCK_H, wall_len) if along_z else Vector3(wall_len, ROCK_H, WALL_THICK)
	_add_box(root, sz, _wall_face_pos(toward) + Vector3(0.0, ROCK_H * 0.5, 0.0), _mat_rock)

func _wall_face_pos(toward: Vector2i) -> Vector3:
	return Vector3(
		CELL * 0.5 + float(toward.x) * (CELL * 0.5 - WALL_THICK * 0.5),
		0.0,
		CELL * 0.5 + float(toward.y) * (CELL * 0.5 - WALL_THICK * 0.5)
	)

func _door_closed_scale() -> float:
	if _door_ref_scale > 0.0:
		return _door_ref_scale
	var packed: PackedScene = load(DOOR_CLOSED_GLB) as PackedScene
	if packed == null:
		_door_ref_scale = 1.0
		return _door_ref_scale
	var probe: Node = packed.instantiate()
	var aabb := _model_aabb(probe)
	probe.free()
	var span := maxf(aabb.size.x, aabb.size.z)
	_door_ref_scale = 1.12 / maxf(span, 0.01)
	return _door_ref_scale

func _add_fitted_door(parent: Node3D, path: String) -> Node3D:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate()
	if inst == null:
		return null
	parent.add_child(inst)
	var s := _door_closed_scale()
	inst.scale = Vector3.ONE * s
	var fitted := _model_aabb(inst)
	if fitted.size != Vector3.ZERO:
		inst.position.x += -fitted.get_center().x
		inst.position.z += -fitted.get_center().z
		inst.position.y += FLOOR_H - fitted.position.y
	_prep_core_meshes(inst)
	return inst

func _model_aabb(n: Node) -> AABB:
	return _model_aabb_xf(n, Transform3D.IDENTITY)

func _model_aabb_xf(n: Node, xf: Transform3D) -> AABB:
	var local := xf
	if n is Node3D:
		local = xf * (n as Node3D).transform
	var acc := AABB()
	var got := false
	if n is MeshInstance3D:
		acc = (n as MeshInstance3D).get_aabb() * local
		got = true
	for c in n.get_children():
		var sub := _model_aabb_xf(c, local)
		if sub.size == Vector3.ZERO:
			continue
		if not got:
			acc = sub
			got = true
		else:
			acc = acc.merge(sub)
	return acc if got else AABB()

func _prep_core_meshes(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mi.lod_bias = 16.0
		var mat := mi.get_active_material(0)
		if mat is BaseMaterial3D:
			var bm := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
			bm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mi.material_override = bm
	for c in n.get_children():
		_prep_core_meshes(c)

func _prep_door_meshes(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mi.lod_bias = 16.0
		var mat := mi.get_active_material(0)
		if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		if mat is BaseMaterial3D:
			mi.material_override = _door_stone_mat(mat as BaseMaterial3D)
	for c in n.get_children():
		_prep_door_meshes(c)

func _door_stone_mat(src: BaseMaterial3D) -> Material:
	if src.albedo_texture == null:
		var bm := src.duplicate() as BaseMaterial3D
		bm.albedo_color = Color("#3B414C")
		bm.metallic = 0.04
		bm.roughness = 0.7
		return bm
	if _door_stone_sh == null:
		_door_stone_sh = Shader.new()
		_door_stone_sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec3 lift = vec3(0.72, 0.70, 0.78);
uniform vec3 stone = vec3(0.231, 0.255, 0.298);
uniform float mix_amt = 0.58;
void fragment() {
	vec4 t = texture(albedo_tex, UV);
	bool gem = t.b > t.r + 0.07 && t.b > 0.2;
	vec3 shifted = clamp(t.rgb * lift, 0.0, 1.0);
	vec3 stone_col = mix(shifted, stone, mix_amt);
	ALBEDO = gem ? t.rgb : stone_col;
	ROUGHNESS = 0.72;
	METALLIC = 0.0;
	EMISSION = gem ? t.rgb * 0.45 : vec3(0.0);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = _door_stone_sh
	sm.set_shader_parameter("albedo_tex", src.albedo_texture)
	sm.set_shader_parameter("lift", Vector3(0.72, 0.70, 0.78))
	sm.set_shader_parameter("stone", Vector3(0.231, 0.255, 0.298))
	sm.set_shader_parameter("mix_amt", 0.58)
	return sm

func _add_core_vortex(parent: Node3D, vr: float) -> void:
	_core_vortex = Node3D.new()
	parent.add_child(_core_vortex)
	for i in 6:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		var t: float = float(i) / 5.0
		torus.inner_radius = 0.006 + (1.0 - t) * 0.005
		torus.outer_radius = vr * (0.32 + t * 0.5)
		torus.rings = 12
		torus.ring_segments = 20
		ring.mesh = torus
		ring.material_override = _mat_vortex
		ring.rotation_degrees = Vector3(22.0 * float(i) - 48.0, 28.0 * float(i), 8.0 * float(i % 3))
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_core_vortex.add_child(ring)
	for k in 10:
		var t: float = float(k) / 10.0
		var ang: float = t * TAU * 2.4
		var rad: float = vr * (0.18 + t * 0.55)
		var y: float = (t - 0.5) * vr * 1.15
		var slab := _add_box(_core_vortex, Vector3(0.035, 0.01, 0.018), Vector3(cos(ang) * rad, y, sin(ang) * rad), _mat_vortex)
		slab.rotation_degrees = Vector3(12.0, rad_to_deg(-ang), 0.0)
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _make_spark_bolt(parent: Node3D) -> Node3D:
	var bolt := Node3D.new()
	parent.add_child(bolt)
	for _s in 7:
		var seg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.01, 0.01, 0.08)
		seg.mesh = box
		seg.material_override = _mat_spark
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bolt.add_child(seg)
	bolt.visible = false
	return bolt

func _orient_seg(seg: MeshInstance3D, mid: Vector3, delta: Vector3, thick: float) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(thick, thick * 0.55, maxf(delta.length(), 0.03))
	seg.mesh = box
	var n := delta.normalized() if delta.length() > 0.001 else Vector3.UP
	var up := Vector3.UP
	if absf(n.dot(up)) > 0.92:
		up = Vector3.RIGHT
	seg.transform = Transform3D(Basis.looking_at(n, up), mid)

func _shape_spark_bolt(bolt: Node3D) -> void:
	# Chord across the throat, or rim into the pinch.
	var a := _rng.randf() * TAU
	var r0 := _rng.randf_range(_core_vr * 0.7, _core_vr * 1.05)
	var start := Vector3(cos(a) * r0, _rng.randf_range(-_core_vr * 0.35, _core_vr * 0.35), sin(a) * r0)
	var end: Vector3
	if _rng.randf() > 0.45:
		var b := a + PI + _rng.randf_range(-0.7, 0.7)
		var r1 := _rng.randf_range(_core_vr * 0.65, _core_vr * 1.0)
		end = Vector3(cos(b) * r1, _rng.randf_range(-_core_vr * 0.35, _core_vr * 0.35), sin(b) * r1)
	else:
		end = Vector3(_rng.randf_range(-0.02, 0.02), _rng.randf_range(-_core_vr * 0.2, _core_vr * 0.2), _rng.randf_range(-0.02, 0.02))
	var segs: Array = bolt.get_children()
	var prev := start
	for i in segs.size():
		var t: float = (float(i) + 1.0) / float(segs.size())
		var nxt: Vector3 = start.lerp(end, t)
		nxt += Vector3(_rng.randf_range(-0.05, 0.05), _rng.randf_range(-0.04, 0.04), _rng.randf_range(-0.05, 0.05))
		if i == segs.size() - 1:
			nxt = end
		var thick := 0.007 if i > 1 and i < segs.size() - 1 else 0.013
		_orient_seg(segs[i], (prev + nxt) * 0.5, nxt - prev, thick + _rng.randf() * 0.005)
		prev = nxt

func _add_core_sparks(parent: Node3D, radius: float) -> void:
	var parts := GPUParticles3D.new()
	parts.amount = 18
	parts.lifetime = 0.28
	parts.preprocess = 0.15
	parts.randomness = 0.85
	parts.explosiveness = 0.35
	parts.visibility_aabb = AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = radius * 0.7
	proc.direction = Vector3(0, 1, 0)
	proc.spread = 160.0
	proc.initial_velocity_min = 0.45
	proc.initial_velocity_max = 1.9
	proc.gravity = Vector3.ZERO
	proc.damping_min = 0.8
	proc.damping_max = 2.2
	proc.scale_min = 0.02
	proc.scale_max = 0.06
	proc.color = Color(0.9, 0.62, 1.0)
	parts.process_material = proc
	var quad := QuadMesh.new()
	quad.size = Vector2(0.035, 0.08)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.albedo_color = Color(0.85, 0.5, 1.0, 0.9)
	pm.emission_enabled = true
	pm.emission = Color("#CE72DF")
	pm.emission_energy_multiplier = 2.2
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = pm
	parts.draw_pass_1 = quad
	parent.add_child(parts)

func _add_core_debris_dust(parent: Node3D) -> void:
	var parts := GPUParticles3D.new()
	parts.amount = 16
	parts.lifetime = 2.4
	parts.preprocess = 1.2
	parts.randomness = 0.6
	parts.visibility_aabb = AABB(Vector3(-1.2, -1.2, -1.2), Vector3(2.4, 2.4, 2.4))
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc.emission_sphere_radius = 0.38
	proc.direction = Vector3(0, 1, 0)
	proc.spread = 180.0
	proc.initial_velocity_min = 0.04
	proc.initial_velocity_max = 0.18
	proc.gravity = Vector3.ZERO
	proc.radial_accel_min = -0.12
	proc.radial_accel_max = -0.04
	proc.scale_min = 0.35
	proc.scale_max = 0.9
	parts.process_material = proc
	var pebble := BoxMesh.new()
	pebble.size = Vector3(0.04, 0.03, 0.035)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("#3B414C")
	pm.roughness = 0.9
	pebble.material = pm
	parts.draw_pass_1 = pebble
	parent.add_child(parts)

func _build_entrance(root: Node3D, p: Vector2i, game: Node) -> void:
	var face := _entrance_face(p, game)
	if _add_fitted_stairs(root, face):
		return
	var east_west: bool = absf(face.x) > 0.5
	var well := 0.58
	for s in [-1.0, 1.0]:
		var wall_pos := Vector3(CELL * 0.5, ROCK_H * 0.5, CELL * 0.5)
		var wall_sz: Vector3
		if east_west:
			wall_sz = Vector3(MESH_PAD, ROCK_H, 0.2)
			wall_pos.z += s * 0.4
		else:
			wall_sz = Vector3(0.2, ROCK_H, MESH_PAD)
			wall_pos.x += s * 0.4
		_add_box(root, wall_sz, wall_pos, _mat_rock)
	var steps := 4
	var step_len: float = CELL / float(steps)
	for i in steps:
		var u: float = (float(i) + 0.5) / float(steps)
		var h: float = lerpf(ROCK_H * 0.82, FLOOR_H, float(i) / float(steps - 1))
		var pos := Vector3(CELL * 0.5, h * 0.5, CELL * 0.5) - face * 0.5 + face * u
		var sz := Vector3(step_len * 0.92, h, well) if east_west else Vector3(well, h, step_len * 0.92)
		_add_box(root, sz, pos, _mat_floor)
	var pit := Vector3(CELL * 0.5, 0.025, CELL * 0.5)
	if east_west:
		_add_box(root, Vector3(0.78, 0.04, well), pit, _mat_void)
	else:
		_add_box(root, Vector3(well, 0.04, 0.78), pit, _mat_void)

func _add_fitted_stairs(root: Node3D, face: Vector3) -> bool:
	var packed := _wall_scene(STAIRS_GLB)
	if packed == null:
		return false
	var holder := Node3D.new()
	holder.position = Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	holder.rotation.y = atan2(face.x, face.z)
	root.add_child(holder)
	var inst := packed.instantiate()
	if inst == null:
		holder.queue_free()
		return false
	holder.add_child(inst)
	var aabb := _model_aabb(inst)
	if aabb.size == Vector3.ZERO:
		return true
	if aabb.size.x > aabb.size.z + 0.02:
		inst.rotation.y += PI * 0.5
		aabb = _model_aabb(inst)
	var span := maxf(aabb.size.x, aabb.size.z)
	inst.scale = Vector3(
		CELL / maxf(span, 0.01),
		ROCK_H / maxf(aabb.size.y, 0.01),
		CELL / maxf(span, 0.01)
	)
	var fitted := _model_aabb(inst)
	inst.position.x += -fitted.get_center().x
	inst.position.z += -fitted.get_center().z
	inst.position.y += -fitted.position.y
	_prep_core_meshes(inst)
	return true

func _door_yaw(p: Vector2i, game: Node) -> float:
	# Local slab is wide on X, thin on Z. Yaw 0 blocks north-south traffic.
	var rock_l := _door_is_rock(p + Vector2i.LEFT, game)
	var rock_r := _door_is_rock(p + Vector2i.RIGHT, game)
	var rock_u := _door_is_rock(p + Vector2i.UP, game)
	var rock_d := _door_is_rock(p + Vector2i.DOWN, game)
	if rock_l and rock_r:
		return 0.0
	if rock_u and rock_d:
		return PI * 0.5
	var walk_l := _door_is_open(p + Vector2i.LEFT, game)
	var walk_r := _door_is_open(p + Vector2i.RIGHT, game)
	var walk_u := _door_is_open(p + Vector2i.UP, game)
	var walk_d := _door_is_open(p + Vector2i.DOWN, game)
	if (walk_l or walk_r) and not (walk_u or walk_d):
		return PI * 0.5
	if (walk_u or walk_d) and not (walk_l or walk_r):
		return 0.0
	if walk_l and walk_r:
		return PI * 0.5
	return 0.0

func _door_is_rock(n: Vector2i, game: Node) -> bool:
	return game._inside(n) and int(game.grid[n.y][n.x]) == game.Tile.ROCK

func _door_is_open(n: Vector2i, game: Node) -> bool:
	return game._inside(n) and game._walkable(n) and int(game.grid[n.y][n.x]) != game.Tile.ROCK

func _build_door(root: Node3D, p: Vector2i, game: Node) -> void:
	_add_floor_tile(root)
	var hp := int(game.door_hp.get(p, game.DOOR_MAX_HP))
	var intact: bool = hp > 0
	var frame := Node3D.new()
	frame.position = Vector3(CELL * 0.5, 0.0, CELL * 0.5)
	frame.rotation.y = _door_yaw(p, game)
	root.add_child(frame)
	var path := DOOR_CLOSED_GLB
	if hp <= 0:
		path = DOOR_DESTROYED_GLB
	elif hp < int(game.DOOR_MAX_HP):
		path = DOOR_DAMAGED_GLB
	if _add_fitted_door(frame, path) == null:
		_build_door_boxes(frame, intact)
	if intact:
		_label(root, str(hp), Color("#C9AC7A"), Vector3(CELL * 0.5, 1.28, CELL * 0.5))
	else:
		_label(root, "broken", Color("#A74747"), Vector3(CELL * 0.5, 1.12, CELL * 0.5))

func _build_door_boxes(frame: Node3D, intact: bool) -> void:
	var stone: Material = _mat_rock
	_add_box(frame, Vector3(0.16, 0.98, 0.22), Vector3(-0.4, 0.57, 0.0), stone)
	_add_box(frame, Vector3(0.16, 0.98, 0.22), Vector3(0.4, 0.57, 0.0), stone)
	_add_box(frame, Vector3(0.96, 0.16, 0.24), Vector3(0.0, 1.02, 0.0), stone)
	_add_box(frame, Vector3(0.12, 0.12, 0.12), Vector3(0.0, 1.14, 0.0), stone)
	if intact:
		_add_box(frame, Vector3(0.3, 0.78, 0.07), Vector3(-0.16, 0.5, 0.0), _mat_wood)
		_add_box(frame, Vector3(0.3, 0.78, 0.07), Vector3(0.16, 0.5, 0.0), _mat_wood)
		_add_box(frame, Vector3(0.28, 0.05, 0.09), Vector3(-0.16, 0.62, 0.0), _mat_iron)
		_add_box(frame, Vector3(0.28, 0.05, 0.09), Vector3(-0.16, 0.38, 0.0), _mat_iron)
		_add_box(frame, Vector3(0.28, 0.05, 0.09), Vector3(0.16, 0.62, 0.0), _mat_iron)
		_add_box(frame, Vector3(0.28, 0.05, 0.09), Vector3(0.16, 0.38, 0.0), _mat_iron)
		_add_cyl(frame, 0.03, 0.04, Vector3(-0.05, 0.48, 0.05), _mat_iron, Vector3(90, 0, 0))
		_add_cyl(frame, 0.03, 0.04, Vector3(0.05, 0.48, 0.05), _mat_iron, Vector3(90, 0, 0))
	else:
		var hanging := _add_box(frame, Vector3(0.28, 0.62, 0.07), Vector3(-0.22, 0.42, 0.1), _mat_wood)
		hanging.rotation_degrees = Vector3(18.0, 12.0, -28.0)
		var fallen := _add_box(frame, Vector3(0.42, 0.07, 0.28), Vector3(0.14, 0.2, 0.16), _mat_wood)
		fallen.rotation_degrees = Vector3(8.0, 22.0, 6.0)
		var splinter := _add_box(frame, Vector3(0.16, 0.05, 0.08), Vector3(-0.05, 0.18, -0.12), _mat_wood)
		splinter.rotation_degrees = Vector3(0.0, 40.0, 0.0)
		_add_box(frame, Vector3(0.22, 0.04, 0.08), Vector3(0.22, 0.22, -0.08), _mat_iron)

func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi

func _label(parent: Node3D, text: String, color: Color, pos: Vector3) -> void:
	var lab := Label3D.new()
	lab.text = text
	lab.font_size = 42
	lab.pixel_size = 0.0045
	lab.modulate = color
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.position = pos
	lab.outline_size = 3
	parent.add_child(lab)

func _sync_markers(game: Node) -> void:
	if not is_inside_tree():
		return
	var sig := "%s|%s" % [str(game.corpses), str(game.loot_bags)]
	if sig == _marker_sig:
		return
	_marker_sig = sig
	for n in get_tree().get_nodes_in_group("dyn_marker"):
		n.queue_free()
	for corpse in game.corpses:
		var p: Vector2i = corpse["pos"]
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.12, 0.22)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#555765")
		mi.material_override = mat
		mi.position = cell_center(p, 0.28)
		mi.add_to_group("dyn_marker")
		add_child(mi)
	for bag in game.loot_bags:
		var p: Vector2i = bag["pos"]
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.22, 0.18, 0.16)
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#D4A83E")
		mat.metallic = 0.5
		mi.material_override = mat
		mi.position = cell_center(p, 0.32)
		mi.add_to_group("dyn_marker")
		add_child(mi)

func _sync_hero(game: Node) -> void:
	if _hero == null:
		return
	var show: bool = bool(game.raid_active) and not game.hero.is_empty()
	_hero.visible = show
	_hero_bar.visible = show
	_hero_tag.visible = show
	if not show:
		return
	var p: Vector2i = game.hero["pos"]
	var kind := String(game.hero["kind"])
	var mat := StandardMaterial3D.new()
	match kind:
		"paladin":
			mat.albedo_color = Color(0.72, 0.7, 0.62)
			mat.metallic = 0.2
		"ranger":
			mat.albedo_color = Color(0.38, 0.55, 0.32)
		_:
			mat.albedo_color = Color(0.82, 0.42, 0.18)
	mat.roughness = 0.55
	_hero.material_override = mat
	_hero.position = cell_center(p, 0.48)
	var hp_ratio := clampf(float(game.hero["hp"]) / float(game.hero["max_hp"]), 0.05, 1.0)
	_hero_bar.position = _hero.position + Vector3(0, 0.48, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.42 * hp_ratio, 0.05, 0.05)
	_hero_bar.mesh = bm
	var bm_mat := StandardMaterial3D.new()
	bm_mat.albedo_color = Color("#819568")
	bm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hero_bar.material_override = bm_mat
	var tag := String(game.hero["trait"])
	if bool(game.hero["fleeing"]):
		tag += " · fleeing"
	_hero_tag.text = tag
	_hero_tag.modulate = Color("#D9783C")
	_hero_tag.position = _hero.position + Vector3(0, 0.72, 0)

func _process(delta: float) -> void:
	_core_pulse += delta
	if _core_vortex != null and is_instance_valid(_core_vortex):
		if _core_spin != null:
			_core_spin.rotate_y(delta * 0.45)
		_core_vortex.rotate_y(delta * 5.2)
		_core_vortex.rotate_x(delta * 0.55)
	if _core_drift != null:
		_core_drift.rotate_y(delta * 0.28)
		_core_drift.rotate_z(sin(_core_pulse * 0.7) * delta * 0.35)
	for bit in _core_debris:
		if bit is Node3D and is_instance_valid(bit):
			(bit as Node3D).rotate_x(delta * 0.9)
			(bit as Node3D).rotate_z(delta * 0.55)
	if _mat_pool != null:
		_mat_pool.emission_energy_multiplier = 1.05 + sin(_core_pulse * 5.5) * 0.4
	if _mat_vein != null:
		_mat_vein.emission_energy_multiplier = 0.45 + sin(_core_pulse * 4.2 + 0.7) * 0.2
	if _mat_spark != null:
		_mat_spark.emission_energy_multiplier = 1.8 + absf(sin(_core_pulse * 28.0)) * 1.6
		_mat_spark.albedo_color = Color(0.75 + absf(sin(_core_pulse * 22.0)) * 0.2, 0.42, 1.0, 1.0)
	if _mat_vortex != null:
		_mat_vortex.emission_energy_multiplier = 1.2 + absf(sin(_core_pulse * 7.5)) * 0.7
	if _mat_glint != null:
		_mat_glint.emission_energy_multiplier = 1.8 + sin(_core_pulse * 9.0) * 0.5
	if _fill != null and _fill.light_energy > 0.01:
		_fill.light_energy = _core_fill_base + sin(_core_pulse * 7.0) * 0.18
	_spark_cd -= delta
	if _spark_cd <= 0.0 and not _core_bolts.is_empty():
		_spark_cd = _rng.randf_range(0.035, 0.08)
		for bolt in _core_bolts:
			var n: Node3D = bolt
			n.visible = _rng.randf() > 0.35
			if n.visible:
				_shape_spark_bolt(n)
