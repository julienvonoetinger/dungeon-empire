extends SceneTree

class FakeGame:
	extends Node
	const PORTAL_HOLD := 1.0
	const CORE_W := 2
	const CORE_H := 2
	const Tile = GameTypes.Tile
	var trap_charges := {}
	var grid: Array = []
	var sim := DungeonSim.new()
	func _init() -> void:
		sim.new_map()
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
	_check(profile.practical_energy >= 1.5 and profile.practical_range >= 2.5 and profile.practical_range <= 3.2, "warm torch pools reach nearby paving without tinting whole rooms")
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
		var prop: Node3D = prop_root.get_node("MobileProp")
		if index == 0:
			_check(prop is Sprite3D and prop.texture.resource_path.ends_with("chest-full-v3.png"), "vault uses updated chest without a billboard floor")
		else:
			_check(not prop is Sprite3D, "traps are floor-bound mechanisms")
			_check(prop.get_children().is_empty() if prop_tiles[index] == GameTypes.Tile.SNARE else not prop.get_children().is_empty(), "armed snare belongs to floor; other trap geometry exists")
		_check((prop_root.get_node_or_null("MobileTrapCharges") != null) == (index > 0), "only traps have count marker")
	game.trap_charges[prop_cell] = 0
	for gold in [0, 50, 0]:
		world._rebuild_cell(prop_cell, GameTypes.Tile.VAULT, game, {prop_cell: gold}, false)
		var chest: Sprite3D = world._cells[prop_cell].get_node("MobileProp")
		_check(chest.modulate == Color.WHITE, "empty and full chests retain colors")
		_check(chest.texture.resource_path.ends_with("chest-empty-v3.png" if gold == 0 else "chest-full-v3.png"), "chest changes image on depletion and refill")
		_check(chest.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, "chest writes depth")
		_check(is_equal_approx(chest.pixel_size * chest.texture.get_width(), 0.78), "chest has a compact tile-relative size")
		var contact = world._cells[prop_cell].get_node_or_null("ChestContact")
		_check(contact == null, "integral stone base replaces detached shadow")
		var footprint := Vector2(chest.texture.get_width() * 0.50, chest.texture.get_height() * 0.69)
		var anchor := Vector2(chest.texture.get_width() * 0.5 - chest.offset.x, chest.texture.get_height() * 0.5 + chest.offset.y)
		_check(anchor.is_equal_approx(footprint), "chest anchors its ground-footprint center, not its front foot")
		_check(chest.material_override is ShaderMaterial, "centered chest stays above paving with normal occlusion")
	world._rebuild_cell(prop_cell, GameTypes.Tile.SPIKE, game, {}, true)
	var broken: Node3D = world._cells[prop_cell]
	_check(broken.get_node("MobileTrapCharges").text == "0", "spent trap shows zero charges")
	_check(not broken.get_node("MobileTrapCharges").visible, "screen-space charge badge replaces legacy count")
	var broken_spikes := broken.get_node("MobileProp").find_children("Spike*", "Sprite3D", false, false)
	_check(broken_spikes.size() == 9, "spent trap preserves nine spike positions")
	for part in broken_spikes:
		_check(part.texture.resource_path.ends_with("spike-broken-v2.png"), "spent spikes use fractured artwork")
		_check(part.pixel_size * part.texture.get_height() <= 0.26, "broken spikes stay close to floor")
	game.hero["trap_sprung_at"] = prop_cell
	world._rebuild_cell(prop_cell, GameTypes.Tile.SPIKE, game, {}, true)
	var last_spike: Sprite3D = world._cells[prop_cell].get_node("MobileProp/Spike0")
	_check(last_spike.texture.resource_path.ends_with("spike-active-v2.png"), "last charge activates before breaking")
	game.hero.erase("trap_sprung_at")
	for absorbing in [true, false]:
		if absorbing:
			game.hero["trap_sprung_at"] = prop_cell
		world._rebuild_cell(prop_cell, GameTypes.Tile.VOID, game, {}, true)
		var void_floor: Sprite3D = world._cells[prop_cell].get_node("MobileProp/VoidFloor")
		_check(void_floor.texture.resource_path.ends_with("void-active-v3.png" if absorbing else "void-broken-v3.png"), "Void stays open until absorption finishes")
		game.hero.erase("trap_sprung_at")
	world._sync_dig_bounds(game)
	world._sync_expand_pads(game)
	_check(world._dig_bound == null and world._expand_root == null, "mobile omits debug border and per-cell build markers")
	var core_root := Node3D.new()
	world.add_child(core_root)
	world._build_core(core_root, Vector2i.ZERO, game)
	var monument: Sprite3D = world._core_spin.get_node("CoreMonument")
	_check(monument != null and monument.texture != null, "mobile Core uses generated monument")
	_check(world._core_spin.get_script() == null and world._core_spin.find_children("*", "MeshInstance3D", true, false).is_empty(), "mobile skips old procedural Core")
	_check(is_equal_approx(monument.pixel_size * monument.texture.get_width(), 2.2), "Core fits reserved footprint")
	_check(monument.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, "Core writes opaque depth")
	var states := {100: "core-monument-v2.png", 51: "core-monument-v2.png", 50: "core-damaged-v2.png", 1: "core-damaged-v2.png", 0: "core-destroyed-v2.png"}
	for hp in [100, 51, 50, 1, 0, 50, 100]:
		world._sync_mobile_core_health(hp)
		_check(monument.modulate == Color.WHITE, "all Core states preserve artwork color")
		_check(monument.texture.resource_path.ends_with(states[hp]), "Core image follows health and repair at %d" % hp)
		_check(is_equal_approx(monument.pixel_size * monument.texture.get_width(), 2.2), "Core state preserves canvas width")
		_check(is_equal_approx(monument.offset.y / monument.texture.get_height(), 0.14), "Core states preserve ground registration")
		_check(is_equal_approx(monument.material_override.get_shader_parameter("rune_energy"), 0.8 if hp > 0 else 0.0), "Destroyed Core has no emissive runes")
		var artwork := monument.texture.get_image()
		if artwork.is_compressed():
			artwork.decompress()
		_check(artwork.get_width() == artwork.get_height(), "Core state keeps square canvas")
		_check(artwork.get_pixel(0, 0).a == 0.0 and artwork.get_pixel(artwork.get_width() - 1, artwork.get_height() - 1).a == 0.0, "Core assets have real transparent backgrounds")
	_check(not monument.no_depth_test and monument.shaded, "Core stone receives dungeon lighting with depth test")
	_check(monument.material_override.shader.resource_path.ends_with("core_masonry.gdshader"), "Core has its own lit grounded material")
	_check(monument.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Core follows camera rotation")
	world._core_spin = null
	core_root.free()
	var before := game.hero.duplicate(true)
	world._sync_mobile_focus(game)
	_check(world._mobile_focus == world.cell_center(game.mobile_selection, 0.6), "selection is build focus")
	_check(world.mobile_walls_visible, "mobile walls default visible")
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
	_check(wall.scale.is_equal_approx(Vector3.ONE), "newly registered wall keeps full height")
	world.set_mobile_walls_visible(false)
	_check(not world.mobile_walls_visible, "manual wall toggle records hidden state")
	_check(is_equal_approx(wall.scale.y, 0.16), "hidden wall keeps foundation")
	world._sync_mobile_focus(game)
	_check(wall.scale.is_equal_approx(Vector3(1, 0.16, 1)), "focus changes do not alter hidden wall height")
	world._sync_hero(game)
	_check(wall.scale.is_equal_approx(Vector3(1, 0.16, 1)), "hero updates do not alter hidden wall height")
	world.set_mobile_walls_visible(true)
	_check(world.mobile_walls_visible and wall.scale.is_equal_approx(Vector3.ONE), "manual toggle restores original wall height")
	wall.position.x += 1.8
	world._mobile_walls.clear()
	wall.scale = Vector3.ONE
	world._register_mobile_wall(wall)
	_check(wall.scale.is_equal_approx(Vector3.ONE), "newly registered wall honors visible state")
	world.set_mobile_walls_visible(false)
	_check(is_equal_approx(wall.scale.y, 0.16), "newly registered wall honors hidden state")
	world.set_mobile_walls_visible(true)
	_check(wall.scale.is_equal_approx(Vector3.ONE), "new wall restores its full height")
	var masonry_holder := Node3D.new()
	world.add_child(masonry_holder)
	masonry_holder.name = "MobileMasonry"
	var masonry := MeshInstance3D.new()
	masonry.name = "MobileMasonryMesh"
	masonry.mesh = BoxMesh.new()
	(masonry.mesh as BoxMesh).size = Vector3(1, 1.1, 0.28)
	var foundation := BoxMesh.new()
	foundation.size = Vector3(1, 0.23, 0.28)
	masonry.set_meta("full_mesh", masonry.mesh)
	masonry.set_meta("foundation_mesh", foundation)
	masonry_holder.add_child(masonry)
	world._register_mobile_wall(masonry_holder)
	var original_masonry_mesh: Mesh = masonry.mesh
	world.set_mobile_walls_visible(false)
	_check(masonry_holder.scale.is_equal_approx(Vector3.ONE), "real masonry visibility does not squash its holder")
	_check(masonry.mesh != original_masonry_mesh and masonry.mesh.get_aabb().size.y < original_masonry_mesh.get_aabb().size.y, "real masonry swaps to a foundation mesh")
	world.set_mobile_walls_visible(true)
	_check(masonry_holder.scale.is_equal_approx(Vector3.ONE) and masonry.mesh == original_masonry_mesh, "real masonry restores original mesh and scale")
	masonry_holder.free()
	var rock_mass := Node3D.new()
	rock_mass.name = "MobileRockMass"
	world.add_child(rock_mass)
	rock_mass.set_meta("mobile_natural_rock", true)
	rock_mass.set_meta("preserve_rock_height", true)
	var rock_mesh := MeshInstance3D.new()
	rock_mesh.mesh = BoxMesh.new()
	rock_mass.add_child(rock_mesh)
	world._register_mobile_wall(rock_mass)
	_check(world._mobile_walls.has(rock_mass), "natural rock remains registered for picking cutaway")
	world.set_mobile_walls_visible(false)
	_check(is_equal_approx(rock_mass.scale.y, 0.16), "natural rock uses reduced-height fallback")
	world._mobile_backdrop = Node3D.new()
	world.add_child(world._mobile_backdrop)
	world.set_mobile_walls_visible(false)
	_check(is_equal_approx(world._mobile_backdrop.scale.y, rock_mass.scale.y), "distant rocks and passage rocks share the same cutaway height")
	world.set_mobile_walls_visible(true)
	_check(world._mobile_backdrop.scale.is_equal_approx(Vector3.ONE) and rock_mass.scale.is_equal_approx(Vector3.ONE), "wall toggle restores all geological relief")
	world._mobile_backdrop.free()
	world._mobile_backdrop = null
	rock_mass.free()
	game.raid_active = true
	world._sync_hero(game)
	world._sync_mobile_focus(game)
	_check(world._mobile_focus == world.cell_center(game.hero.pos, 0.6), "raid hero overrides selection")
	_check(world._hero.scale.is_equal_approx(Vector3.ONE * 1.4), "mobile hero scale")
	_check(is_equal_approx(world._hero.position.y + world._vulpin.position.y * 1.4, world.FLOOR_H), "scaled hero remains on floor")
	_check(not world._hero_bar.visible and not world._hero_tag.visible, "3D hero HUD hidden")
	_check(world._hero.process_mode == Node.PROCESS_MODE_INHERIT and world._lithide.process_mode == Node.PROCESS_MODE_DISABLED, "active hero enabled, hidden archetypes disabled")
	_check(game.hero == before, "visual updates do not mutate simulation")
	game.hero.core_striking = true
	game.hero.facing = Vector2i.RIGHT
	world._hero.rotation.y = PI
	world._sync_hero(game)
	_check(is_equal_approx(world._hero.rotation.y, PI / 2.0), "stationary Core attack faces target")
	game.hero.erase("core_striking")
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
	legacy.free()
	game.free()
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var border_root := Node3D.new()
		world.add_child(border_root)
		world._add_edge_wall(border_root, direction, 1, true)
		var holder: Node3D = border_root.get_child(0)
		var stone: MeshInstance3D = holder.get_child(0)
		for full in [true, false]:
			world.set_mobile_walls_visible(full)
			var bounds: AABB = holder.transform * stone.transform * stone.get_aabb()
			var outside := bounds.end.x <= 0.001 if direction == Vector2i.LEFT else bounds.position.x >= 0.999 if direction == Vector2i.RIGHT else bounds.end.z <= 0.001 if direction == Vector2i.UP else bounds.position.z >= 0.999
			_check(outside, "border walls leave the whole floor cell available, raised or hidden")
		border_root.free()
	world.free()
	_test_mobile_picking()
	if failures == 0:
		print("OK: mobile rendering profile, lights, hero and manual wall visibility")
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
	var entrance_pos := Vector2i(2, 10)
	var entrance_root: Node3D = game.dungeon._cells[entrance_pos]
	var entrance_arch := entrance_root.find_child("EntranceArch", true, false) as MeshInstance3D
	_check(entrance_arch != null and entrance_arch.mesh != null and entrance_arch.get_aabb().size.z >= 0.4,
		"starter entrance uses a volumetric masonry arch")
	_check(entrance_root.find_children("*", "Sprite3D", true, false).is_empty(), "entrance has no billboard sprite fixtures")
	if entrance_arch != null:
		game.dungeon.set_mobile_walls_visible(false)
		_check(entrance_arch.is_visible_in_tree(), "entrance remains visible when walls are hidden")
	var face: Vector3 = game.dungeon._entrance_face(entrance_pos, game)
	var direction := Vector2i(roundi(face.x), roundi(face.z))
	var hole_cell := entrance_pos - direction
	_check(game.dungeon._wall_span(hole_cell, direction, game) == 0, "entrance opens the wall on its actual facing")
	var along := Vector2i.RIGHT if direction.y != 0 else Vector2i.DOWN
	var coordinate := hole_cell.x if direction.y != 0 else hole_cell.y
	var paired_cell := hole_cell - along if posmod(coordinate, 2) == 1 else hole_cell + along
	_check(game.dungeon._wall_span(paired_cell, direction, game) == 1,
		"entrance hole breaks the adjacent paired wall span")
	var backing_cell: Vector2i = game.dungeon._outside_cell(entrance_pos, game)
	var backing_rock: Node3D = game.dungeon._cells.get(backing_cell)
	var backing_mass := backing_rock.get_node_or_null("MobileRockMass") as Node3D if backing_rock != null else null
	var backing_mesh := backing_mass.find_child("*", true, false) as MeshInstance3D if backing_mass != null else null
	var backing_trimmed := backing_mesh != null and minf(backing_mesh.get_aabb().size.x, backing_mesh.get_aabb().size.z) < 0.9
	_check(game.grid[backing_cell.y][backing_cell.x] == GameTypes.Tile.ROCK and backing_mass != null
		and backing_mass.get_meta("mobile_natural_rock", false) and backing_trimmed,
		"wall opening preserves trimmed natural backface rock")
	_check(is_equal_approx(game.dungeon._mobile_hero_ground(entrance_pos, game), game.dungeon.FLOOR_H),
		"mobile hero stands on the entrance floor, not the old model top")
	var stale_wall := Node3D.new()
	game.dungeon.add_child(stale_wall)
	var stale_mesh := MeshInstance3D.new()
	stale_mesh.mesh = BoxMesh.new()
	stale_wall.add_child(stale_mesh)
	game.dungeon._register_mobile_wall(stale_wall)
	stale_wall.free()
	game.dungeon.sync(game)
	_check(not game.dungeon._mobile_walls.has(stale_wall), "freed walls pruned on world sync")
	var view := Vector2(1280, 720)
	var rock := Vector2i(12, 3)
	var marker_screen: Vector2 = game.dungeon.cell_to_screen(rock, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, 45, game)
	_check(game.dungeon._expand_cell_from_ground(marker_screen, view, 1.35, game) == Vector2i(-1, -1), "hidden mobile dig markers cannot intercept picking")
	game.dungeon.set_mobile_walls_visible(false)
	for yaw in [45.0, 135.0, 225.0, 315.0]:
		var screen: Vector2 = game.dungeon.cell_to_screen(cell, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, yaw, game)
		game.dungeon._update_mobile_cutaway(1.0)
		var picked: Vector2i = game.dungeon.screen_to_cell(screen, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, yaw, game)
		_check(picked == cell, "visible starter floor roundtrip at yaw %s: got %s" % [yaw, picked])
	# A real foreground rock blocks picking while walls are visible; hiding walls reveals the same floor.
	var foreground := Vector2i(12, 5)
	game.grid[foreground.y][foreground.x] = GameTypes.Tile.ROCK
	game.dungeon.sync(game)
	game.dungeon.set_mobile_walls_visible(true)
	var screen: Vector2 = game.dungeon.cell_to_screen(cell, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, 45, game)
	game.dungeon._mobile_has_focus = false
	game.dungeon.set_mobile_walls_visible(true)
	var blocked: Vector2i = game.dungeon.screen_to_cell(screen, view, 1.35, Vector2.ZERO, game.COLS, game.ROWS, 45, game)
	_check(blocked != cell, "unreduced foreground rock blocks floor picking")
	game.dungeon.set_mobile_walls_visible(false)
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
