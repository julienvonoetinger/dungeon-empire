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
	if not _check(_boundary_matches_floor_plane(game), "Core anchoring boundary must align with the Core marker plane"):
		return
	if not _check(_boundary_wraps_board_and_respects_depth(game), "Dungeon boundary must render outside the board and respect scene depth"):
		return
	if not game._has_core():
		game._place_core(GameTypes.core_origin_cell())
	game.dungeon.sync(game)
	if not _check(_boundary_matches_floor_plane(game), "Dungeon boundary must stay aligned with the floor after Core placement"):
		return
	var pad: Node3D = game.dungeon._expand_root
	var fill := VisualProbes.first_fill(pad)
	if not _check(fill != null, "a diggable cell must show a ground marker"):
		return
	var fill_material := fill.material_override as StandardMaterial3D
	if not _check(fill_material.albedo_color.is_equal_approx(BLUE_GRAY), "dig marker fill must use the dungeon stone palette"):
		return
	if not _check(fill_material.albedo_color.a <= 0.12, "dig marker fill must stay translucent"):
		return
	if not _check(not fill_material.emission_enabled, "dig marker fill must not glow over the dungeon"):
		return
	var dash_material := VisualProbes.first_dash(pad).material_override as StandardMaterial3D
	if not _check(dash_material.albedo_color.is_equal_approx(DARK_GOLD), "dig marker border must use the dark-gold accent"):
		return
	if not _check(not dash_material.emission_enabled, "dig marker border must not glow over the dungeon"):
		return
	var cost := VisualProbes.first_label(pad)
	if not _check(cost != null and cost.modulate.is_equal_approx(WARM_SAND), "dig cost must use the warm-sand UI accent"):
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

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: ", message)
	quit(1)
	return false
