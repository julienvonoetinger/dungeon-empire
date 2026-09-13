extends SceneTree

const MainScript := preload("res://scripts/Main.gd")
const VisualProbes := preload("res://tests/probes/dungeon_visual_probes.gd")
const BLUE_GRAY := Color("#3B414C1A")
const DARK_GOLD := Color("#80652A99")
const WARM_SAND := Color("#C9AC7A")

func _initialize() -> void:
	var game: Node = MainScript.new()
	root.add_child(game)
	await process_frame
	if game.grid.is_empty():
		game._new_map()
	game.dungeon.sync(game)
	var core_pad: Node3D = game.dungeon._expand_root
	var core_fill := VisualProbes.first_fill_for_label(core_pad, "Core")
	if not _check(core_fill != null, "a Core anchoring site must show a ground marker"):
		return
	if not _check(core_fill.mesh is QuadMesh and (core_fill.mesh as QuadMesh).size.is_equal_approx(Vector2(2.0, 2.0)), "a Core anchoring marker must display the full 2x2 footprint"):
		return
	var anchors := VisualProbes.core_anchor_report(game)
	if not _check(int(anchors["count"]) == 64, "Core anchoring must be drawn as a complete non-overlapping 8x8 grid of 2x2 sites"):
		return
	if not _check(bool(anchors["has_origin"]) and bool(anchors["has_far_corner"]), "Core anchoring markers must cover the whole board"):
		return
	if not _check(int(anchors["overlaps"]) == 0, "Core anchoring markers overlap instead of snapping to a 2x2 grid"):
		return
	var core_style := VisualProbes.core_marker_style_report(core_pad)
	if not _check(int(core_style["icons"]) == 0 and int(core_style["corners"]) == 0,
			"Core anchoring markers must not use dig construction icons"):
		return
	if not _check(_boundary_matches_floor_plane(game), "Core anchoring boundary must align with the Core marker plane"):
		return
	if not _check(_boundary_wraps_board_and_respects_depth(game), "Dungeon boundary must render outside the board and respect scene depth"):
		return
	if not game._has_core():
		game._place_core(GameTypes.core_origin_cell())
	game.dungeon.sync(game)
	if not _check(_boundary_matches_floor_plane(game), "Dungeon boundary must stay aligned with the floor after Core placement"):
		return
	var slab_report := VisualProbes.rock_slab_report(game)
	if not _check(int(slab_report["slabs"]) == int(slab_report["rock_cells"]),
			"every rock cell inside the buildable board must render an immersive stone slab"):
		return
	if not _check((slab_report["extra"] as Array).is_empty(),
			"only rock cells should render diggable rock slabs"):
		return
	var rock_slab := VisualProbes.first_diggable_rock_slab(game)
	if not _check(rock_slab != null, "a diggable rock cell must render an immersive stone slab"):
		return
	var rock_mesh := rock_slab.mesh as BoxMesh
	if not _check(rock_mesh != null and rock_mesh.size.x >= game.dungeon.CELL - game.dungeon.WALL_THICK
			and rock_mesh.size.z >= game.dungeon.CELL - game.dungeon.WALL_THICK,
			"diggable rock blocks must fill the rock mass behind the wall"):
		return
	var pair := VisualProbes.first_rock_slab_wall_pair(game)
	if not _check(not pair.is_empty() and float(pair["slab_top"]) <= float(pair["wall_top"]) - 0.03,
			"diggable rock blocks must sit just below the rendered wall lip"):
		return
	if not _check(not pair.is_empty() and float(pair["slab_top"]) >= float(pair["wall_top"]) - 0.07,
			"diggable rock blocks must still read as wall-height rock"):
		return
	if not _check(_rock_block_leaves_wall_faces_clear(game, rock_slab, rock_mesh),
			"diggable rock blocks must not cover visible dungeon walls"):
		return
	var rock_material := rock_slab.material_override as StandardMaterial3D
	if not _check(rock_material != null and rock_material.albedo_texture != null,
			"diggable rock slab must use a generated stone texture"):
		return
	if not _check(rock_material.albedo_texture.resource_path == "res://production/textures/rock/diggable_rock_slab.png",
			"diggable rock slab must use the art-bible rock texture"):
		return
	var pad: Node3D = game.dungeon._expand_root
	var fill := VisualProbes.first_fill(pad)
	if not _check(fill != null, "a diggable cell must show a ground marker"):
		return
	if not _check(fill.position.y > game.dungeon.ROCK_BLOCK_H + 0.01,
			"dig markers must render above the rock blocks"):
		return
	var fill_material := fill.material_override as StandardMaterial3D
	if not _check(fill_material.albedo_color.is_equal_approx(BLUE_GRAY), "dig marker fill must use the dungeon stone palette"):
		return
	if not _check(fill_material.albedo_color.a <= 0.12, "dig marker fill must stay translucent"):
		return
	if not _check(not fill_material.emission_enabled, "dig marker fill must not glow over the dungeon"):
		return
	var first_corner := VisualProbes.first_dash(pad)
	if not _check(first_corner != null, "dig marker must expose restrained corner markings"):
		return
	var dash_material := first_corner.material_override as StandardMaterial3D
	if not _check(dash_material.albedo_color.is_equal_approx(DARK_GOLD), "dig marker border must use the dark-gold accent"):
		return
	if not _check(not dash_material.emission_enabled, "dig marker border must not glow over the dungeon"):
		return
	var dig_icon := VisualProbes.first_dig_icon(pad)
	if not _check(dig_icon != null, "dig markers must include a floating pickaxe icon"):
		return
	if not _check(dig_icon.position.y > first_corner.position.y + 0.35,
			"dig icon must float above the yellow corner markings"):
		return
	if not _check(dig_icon.position.y < first_corner.position.y + 0.65,
			"dig icon must stay visually anchored to the diggable tile"):
		return
	if not _check(dig_icon.no_depth_test and dig_icon.render_priority > dash_material.render_priority,
			"dig icon must render above the yellow corner markings without moving too high"):
		return
	var style_report := VisualProbes.dig_marker_style_report(pad)
	if not _check(int(style_report["corners"]) >= 8,
			"dig markers must use restrained corner markings instead of a full dashed square"):
		return
	if not _check(int(style_report["billboards"]) >= 1,
			"dig markers must include a vertical construction-style icon billboard"):
		return
	if not _check(int(style_report["icons"]) == 0,
			"dig markers must not use flat geometric tool icons"):
		return
	if not _check(int(style_report["long_dashes"]) == 0,
			"dig marker strokes must stay short and engraved rather than editor-like"):
		return
	var cost := VisualProbes.first_label(pad)
	if not _check(cost != null and cost.modulate.is_equal_approx(WARM_SAND), "dig cost must use the warm-sand UI accent"):
		return
	if not _check(cost.font_size <= 44, "dig cost must read as a small engraved mark"):
		return
	if not _check(cost.font_size <= 56, "dig cost must remain secondary to the board"):
		return
	print("OK: dig markers use a restrained art-bible style")
	quit()

func _boundary_matches_floor_plane(game: Node) -> bool:
	var boundary := VisualProbes.dungeon_boundary(game)
	return bool(boundary["exists"]) and absf(float(boundary["y"]) - (game.dungeon.FLOOR_Y + 0.12)) <= 0.001

func _boundary_wraps_board_and_respects_depth(game: Node) -> bool:
	var boundary := VisualProbes.dungeon_boundary(game)
	return not bool(boundary["no_depth_test"]) \
		and float(boundary["min_x"]) < 0.0 \
		and float(boundary["min_z"]) < 0.0 \
		and float(boundary["max_x"]) > float(game.COLS) \
		and float(boundary["max_z"]) > float(game.ROWS)

func _rock_block_leaves_wall_faces_clear(game: Node, rock_slab: MeshInstance3D, rock_mesh: BoxMesh) -> bool:
	var root := rock_slab.get_parent() as Node3D
	if root == null:
		return false
	var p := Vector2i(roundi(root.position.x / game.dungeon.CELL), roundi(root.position.z / game.dungeon.CELL))
	var min_x := rock_slab.position.x - rock_mesh.size.x * 0.5
	var max_x := rock_slab.position.x + rock_mesh.size.x * 0.5
	var min_z := rock_slab.position.z - rock_mesh.size.z * 0.5
	var max_z := rock_slab.position.z + rock_mesh.size.z * 0.5
	var wall_back: float = game.dungeon.WALL_THICK
	if game.dungeon._rock_faces_dug(p, Vector2i.LEFT, game) and min_x < wall_back - 0.001:
		return false
	if game.dungeon._rock_faces_dug(p, Vector2i.RIGHT, game) and max_x > game.dungeon.CELL - wall_back + 0.001:
		return false
	if game.dungeon._rock_faces_dug(p, Vector2i.UP, game) and min_z < wall_back - 0.001:
		return false
	if game.dungeon._rock_faces_dug(p, Vector2i.DOWN, game) and max_z > game.dungeon.CELL - wall_back + 0.001:
		return false
	return true

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: ", message)
	quit(1)
	return false
