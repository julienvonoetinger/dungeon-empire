extends SceneTree

class FakeGame:
	extends Node
	const PORTAL_HOLD := 1.0
	const CORE_W := 2
	const CORE_H := 2
	const Tile = GameTypes.Tile
	var trap_charges := {}
	var grid: Array = []
	func _trap_max_charges(_tile: int) -> int:
		return 3
	func _inside(_cell: Vector2i) -> bool:
		return true
	var core_hp := 100
	var raid_active := false
	var mobile_selection := Vector2i(2, 2)
	var hero := {"pos": Vector2i(5, 5), "kind": "proxy", "hp": 50,
		"max_hp": 100, "fleeing": false, "void_absorbing": false}

class DesktopGame:
	extends Node
	var raid_active := false
	var hero := {}

var failures := 0

func _initialize() -> void:
	if "--hero-capture" in OS.get_cmdline_user_args():
		call_deferred("_capture_hero")
		return
	call_deferred("_run")

func _run() -> void:
	var profile = load("res://assets/rendering/mobile_render_profile.tres")
	_check(profile != null, "explicit mobile profile exists")
	var desktop = load("res://assets/rendering/dungeon_render_profile.tres")
	_check(desktop.max_practical_lights == 12 and desktop.shadows_enabled, "desktop profile preserved")
	var env := Environment.new()
	profile.apply_to_environment(env)
	_check(not env.fog_enabled and not env.glow_enabled and not env.ssao_enabled
		and not env.ssil_enabled and not env.ssr_enabled and not env.sdfgi_enabled
		and not env.volumetric_fog_enabled, "mobile environment disables expensive effects")
	_check(env.tonemap_mode == Environment.TONE_MAPPER_LINEAR, "mobile uses compatibility tonemapping")
	var world = load("res://scripts/world/dungeon_world.gd").new()
	_check(not world.mobile_mode, "desktop is default")
	world.mobile_mode = true
	root.add_child(world)
	world.set_process(false)
	_check(world.render_profile == profile, "profile selected before ready")
	_check(profile.practical_energy >= 2.0 and profile.practical_range >= 3.8, "warm torch pools reach room floors")
	_check(profile.core_range <= 2.5, "purple light remains local to Core")
	_check(not world._mat_floor.emission_enabled, "stone floor does not emit purple")
	var stone_source := StandardMaterial3D.new()
	stone_source.albedo_color = Color.PURPLE
	var stone_material: ShaderMaterial = world._mobile_stone_material(stone_source)
	_check(world._mobile_stone_material(stone_source) == stone_material, "mobile stone materials reused")
	_check(world._mobile_stone_material(stone_source.duplicate()) == stone_material, "rebuilds reuse equivalent stone materials")
	_check(stone_source.albedo_color == Color.PURPLE, "source materials remain unchanged")
	var floor_cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	world._floor_renderer.sync_cells(floor_cells, 1.0)
	world._apply_mobile_stone(world._floor_renderer)
	_check(world._floor_renderer.material_override is ShaderMaterial, "continuous floor uses neutral stone")
	var relief: Node = world._floor_renderer.get_node("MeshyStoneRelief/FloorTile1x1")
	_check(relief.material_override is ShaderMaterial, "instanced floor relief uses neutral stone")
	_check(world._hero_preview_root == null, "mobile has no preview lineup")
	_check(world._hero.process_mode == Node.PROCESS_MODE_DISABLED, "inactive hero animation tree disabled")
	_check(world._hero_tag.get_parent() == world, "tag parent does not depend on preview")
	_check(not world._sun.shadow_enabled and not world._fill.shadow_enabled, "mobile lights have no shadows")
	var cells: Array[Vector2i] = []
	for y in 16:
		for x in 16:
			cells.append(Vector2i(x, y))
	world._torch_rig.sync_cells(cells, 1.0)
	_check(world.practical_light_count() == 4, "large mobile room has exactly four practical lights")
	for light in world._torch_rig.find_children("*", "OmniLight3D", true, false):
		_check(not light.shadow_enabled, "torch shadows disabled")
	world._spawn_town_portal()
	_check(world.practical_light_count() == 4, "portal does not exceed practical budget")
	var game := FakeGame.new()
	var prop_cell := Vector2i(1, 1)
	var prop_tiles := [GameTypes.Tile.VAULT, GameTypes.Tile.SPIKE, GameTypes.Tile.SNARE, GameTypes.Tile.VOID]
	for index in prop_tiles.size():
		world._rebuild_cell(prop_cell, prop_tiles[index], game, {prop_cell: 50}, false)
		var prop_root: Node3D = world._cells[prop_cell]
		var prop: Sprite3D = prop_root.get_node("MobileProp")
		var region := prop.texture as AtlasTexture
		_check(region != null and region.filter_clip, "mobile prop uses clipped atlas region")
		var atlas_cell := Vector2(region.atlas.get_width() / 4.0, region.atlas.get_height() / 3.0)
		_check(region.region.position.is_equal_approx(Vector2((index + 1) % 4, floori((index + 1) / 4.0)) * atlas_cell), "mobile prop selects matching HUD icon")
		_check(prop_root.find_children("*", "MeshInstance3D", true, false).is_empty(), "mobile prop skips old model")
		_check(not prop.shaded and not prop.no_depth_test, "mobile prop is unshaded and depth tested")
		_check((prop_root.get_node_or_null("MobileTrapCharges") != null) == (index > 0), "only traps have count marker")
	game.trap_charges[prop_cell] = 0
	world._rebuild_cell(prop_cell, GameTypes.Tile.SPIKE, game, {}, true)
	var broken: Node3D = world._cells[prop_cell]
	_check(broken.get_node("MobileProp").modulate.r < 0.5 and broken.get_node("MobileTrapCharges").text == "0", "spent trap dims and shows zero charges")
	world._sync_dig_bounds(game)
	world._sync_expand_pads(game)
	_check(world._dig_bound == null and world._expand_root == null, "mobile omits debug border and per-cell build markers")
	var core_root := Node3D.new()
	world.add_child(core_root)
	world._build_core(core_root, Vector2i.ZERO, game)
	var monument: Sprite3D = world._core_spin.get_node("CoreMonument")
	_check(monument != null and monument.texture != null, "mobile Core uses generated monument")
	_check(world._core_spin.get_script() == null and world._core_spin.find_children("*", "MeshInstance3D", true, false).is_empty(), "mobile skips old procedural Core")
	_check(is_equal_approx(monument.pixel_size * monument.texture.get_width(), 2.5), "Core billboard is 2.5 world units wide")
	_check(not monument.no_depth_test and not monument.shaded, "Core billboard is unshaded with depth test")
	_check(monument.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Core follows camera rotation")
	world._core_spin = null
	core_root.free()
	var before := game.hero.duplicate(true)
	world._sync_mobile_focus(game)
	_check(world._mobile_focus == world.cell_center(game.mobile_selection, 0.6), "selection is build focus")
	var wall := Node3D.new()
	world.add_child(wall)
	wall.position = world._mobile_focus + Vector3(0, -0.6, 1)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2, 2, 0.3)
	mesh.mesh = box
	mesh.position.y = 1
	wall.add_child(mesh)
	world._register_mobile_wall(wall)
	world.camera.rotation = Vector3.ZERO
	world._update_mobile_cutaway(1.0)
	_check(is_equal_approx(wall.scale.y, 0.16), "foreground wall reduced")
	wall.position.x += 1.8
	world._mobile_walls.clear()
	wall.scale = Vector3.ONE
	world._register_mobile_wall(wall)
	world._update_mobile_cutaway(1.0)
	_check(is_equal_approx(wall.scale.y, 0.16), "cutaway exposes room beside focus")
	world.camera.rotation.y = PI
	world._update_mobile_cutaway(1.0)
	_check(is_equal_approx(wall.scale.y, 1.0), "camera rotation restores wall")
	game.raid_active = true
	world._sync_hero(game)
	world._sync_mobile_focus(game)
	_check(world._mobile_focus == world.cell_center(game.hero.pos, 0.6), "raid hero overrides selection")
	_check(world._hero.scale.is_equal_approx(Vector3.ONE * 1.4), "mobile hero scale")
	_check(is_equal_approx(world._hero.position.y + world._vulpin.position.y * 1.4, world.FLOOR_H), "scaled hero remains on floor")
	_check(not world._hero_bar.visible and not world._hero_tag.visible, "3D hero HUD hidden")
	_check(world._hero.process_mode == Node.PROCESS_MODE_INHERIT and world._lithide.process_mode == Node.PROCESS_MODE_DISABLED, "active hero enabled, hidden archetypes disabled")
	_check(game.hero == before, "visual updates do not mutate simulation")
	game.hero.void_absorbing = true
	game.hero.portal_t = 0.5
	world._sync_hero(game)
	_check(not world._hero_bar.visible and not world._hero_tag.visible, "absorption keeps 3D HUD hidden")
	game.raid_active = false
	world._sync_hero(game)
	var legacy := DesktopGame.new()
	world._sync_mobile_focus(legacy)
	_check(not world._mobile_has_focus, "missing optional selection is supported")
	var core := Node3D.new()
	world.add_child(core)
	core.position = Vector3(4, 0, 4)
	world._core_spin = core
	world._sync_mobile_focus(legacy)
	_check(world._mobile_focus == Vector3(4, 0.6, 4), "Core is fallback focus")
	world._core_spin = null
	core.free()
	wall.free()
	world._update_mobile_cutaway(1.0)
	_check(world._mobile_walls.is_empty(), "freed walls pruned")
	legacy.free()
	game.free()
	world.free()
	_test_mobile_picking()
	if failures == 0:
		print("OK: mobile rendering profile, lights, hero and reversible cutaways")
	quit(1 if failures else 0)

func _test_mobile_picking() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	game.starter_enabled = false
	root.add_child(game)
	game.mobile_ui.paused = true
	load("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	# Clear the center of the starter trap chamber for an unobstructed floor probe.
	var cell := Vector2i(11, 4)
	game.grid[cell.y][cell.x] = GameTypes.Tile.FLOOR
	game.mobile_selection = cell
	game.dungeon.sync(game)
	var view := Vector2(1280, 720)
	var rock := Vector2i(12, 3)
	var marker_screen: Vector2 = game.dungeon.cell_to_screen(rock, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, 45, game)
	_check(game.dungeon._expand_cell_from_ground(marker_screen, view, 1.35, game) == Vector2i(-1, -1), "hidden mobile dig markers cannot intercept picking")
	for yaw in [45.0, 135.0, 225.0, 315.0]:
		var screen: Vector2 = game.dungeon.cell_to_screen(cell, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, yaw, game)
		game.dungeon._update_mobile_cutaway(1.0)
		var picked: Vector2i = game.dungeon.screen_to_cell(screen, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, yaw, game)
		_check(picked == cell, "visible starter floor roundtrip at yaw %s: got %s" % [yaw, picked])
	# A real foreground rock must remain pickable until its visual is cut away.
	var foreground := Vector2i(12, 5)
	game.grid[foreground.y][foreground.x] = GameTypes.Tile.ROCK
	game.dungeon.sync(game)
	var screen: Vector2 = game.dungeon.cell_to_screen(cell, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, 45, game)
	game.dungeon._mobile_has_focus = false
	game.dungeon._update_mobile_cutaway(1.0)
	var blocked: Vector2i = game.dungeon.screen_to_cell(screen, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, 45, game)
	_check(blocked != cell, "unreduced foreground rock blocks floor picking")
	game.dungeon._sync_mobile_focus(game)
	game.dungeon._update_mobile_cutaway(1.0)
	var revealed: Vector2i = game.dungeon.screen_to_cell(screen, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, 45, game)
	_check(revealed == cell, "cutaway reduction exposes the same floor to picking")
	game.free()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _capture_hero() -> void:
	root.size = Vector2i(960, 540)
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	game.starter_enabled = false
	root.add_child(game)
	await process_frame
	load("res://scripts/mobile/mobile_starter.gd").populate(game.sim, game.raid)
	game.mobile_ui.paused = false
	game.mobile_ui._start_raid()
	game.mobile_ui.paused = true
	game.hero.kind = "paladin"
	game.cam_zoom = 1.35
	for cell in [Vector2i(3, 10), Vector2i(4, 10)]:
		game.hero.pos = cell
		game.mobile_ui._center(cell)
		for frame in 45:
			await process_frame
		await create_timer(0.6).timeout
		RenderingServer.force_draw()
		await process_frame
		var path := "res://artifacts/mobile-hero-%s.png" % ("entrance" if cell.x == 3 else "floor")
		root.get_texture().get_image().save_png(path)
		print("Saved ", path, " hero origin=", game.dungeon._hero.position)
	game.queue_free()
	await process_frame
	quit()
