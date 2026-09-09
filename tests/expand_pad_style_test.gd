extends SceneTree

const MainScript := preload("res://scripts/Main.gd")
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
	var pad: Node3D = game.dungeon._expand_root
	var fill := _fill_mesh(pad)
	if not _check(fill != null, "a diggable cell must show a ground marker"):
		return
	var fill_material := fill.material_override as StandardMaterial3D
	if not _check(fill_material.albedo_color.is_equal_approx(BLUE_GRAY), "dig marker fill must use the dungeon stone palette"):
		return
	if not _check(fill_material.albedo_color.a <= 0.12, "dig marker fill must stay translucent"):
		return
	if not _check(not fill_material.emission_enabled, "dig marker fill must not glow over the dungeon"):
		return
	var dash_material := _dash_mesh(pad).material_override as StandardMaterial3D
	if not _check(dash_material.albedo_color.is_equal_approx(DARK_GOLD), "dig marker border must use the dark-gold accent"):
		return
	if not _check(not dash_material.emission_enabled, "dig marker border must not glow over the dungeon"):
		return
	var cost := _cost_label(pad)
	if not _check(cost != null and cost.modulate.is_equal_approx(WARM_SAND), "dig cost must use the warm-sand UI accent"):
		return
	if not _check(cost.font_size <= 56, "dig cost must remain secondary to the board"):
		return
	print("OK: dig markers use a restrained art-bible style")
	quit()

func _fill_mesh(pad: Node3D) -> MeshInstance3D:
	for child in pad.get_children():
		if child is MeshInstance3D and child.mesh is QuadMesh:
			return child
	return null

func _cost_label(pad: Node3D) -> Label3D:
	for child in pad.get_children():
		if child is Label3D:
			return child
	return null

func _dash_mesh(pad: Node3D) -> MeshInstance3D:
	for child in pad.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			return child
	return null

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: ", message)
	quit(1)
	return false
