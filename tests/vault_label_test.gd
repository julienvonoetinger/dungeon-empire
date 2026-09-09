extends SceneTree

const MainScript := preload("res://scripts/Main.gd")

func _initialize() -> void:
	var game: Node = MainScript.new()
	root.add_child(game)
	await process_frame
	if game.grid.is_empty():
		game._new_map()
	game.dungeon.sync(game)
	var vault_label := _first_vault_label(game)
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

func _first_vault_label(game: Node) -> Label3D:
	for p in game.dungeon._cells:
		if int(game.grid[p.y][p.x]) != game.Tile.VAULT:
			continue
		for child in game.dungeon._cells[p].get_children():
			if child is Label3D:
				return child
	return null

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	printerr("FAIL: ", message)
	quit(1)
	return false
