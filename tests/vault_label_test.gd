extends SceneTree

const MainScript := preload("res://scripts/Main.gd")
const VisualProbes := preload("res://tests/probes/dungeon_visual_probes.gd")

func _initialize() -> void:
	var game: Node = MainScript.new()
	root.add_child(game)
	await process_frame
	if game.grid.is_empty():
		game._new_map()
	if not game._has_core():
		game._place_core(GameTypes.core_origin_cell())
	var core: Vector2i = game._find_tile(game.Tile.CORE)
	var vault := core + Vector2i(-1, -1)
	game.grid[vault.y][vault.x] = game.Tile.FLOOR
	game.selected_tool = game.Tool.STORE
	game._build_at(vault)
	game.dungeon.sync(game)
	var vault_label := VisualProbes.first_vault_label(game)
	if not _check(vault_label != null, "a vault must create a value label"):
		return
	if not _check(vault_label.position.y >= 1.1, "vault value must clear the chest lid"):
		return
	if not _check(vault_label.alpha_cut == Label3D.ALPHA_CUT_DISABLED, "vault value must preserve anti-aliased glyph edges"):
		return
	if not _check(vault_label.font_size >= 64, "vault value must use a high-resolution font"):
		return
	print("OK: vault labels clear chests and preserve readable text")
	quit()

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: ", message)
	quit(1)
	return false
