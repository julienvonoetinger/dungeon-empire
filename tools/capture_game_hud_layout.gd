extends SceneTree
## Background layout inventory, not a gameplay test or rendered screenshot.
## Uses in-memory presentation fixtures; never calls a save or player command.
const Game = preload("res://scenes/game/DungeonGame.tscn")
const Types = preload("res://scripts/game/game_types.gd")
var observations: Array = []

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var game := Game.instantiate()
	game.save_path = "res://artifacts/hud-layout-never-created.save"
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var hud = game.get_node("HUD")
	game.sim.new_map()
	game.sim._place_core(Vector2i(8, 8))
	for x in range(3, 7): game.sim.grid[8][x] = Types.Tile.FLOOR
	game.sim._place_entrance(Vector2i(3, 8))
	for p in [Vector2i(7, 7), Vector2i(9, 7), Vector2i(9, 9)]: game.sim.build_vault(p, 0)
	game.sim._storage_state()
	hud._welcome = false
	game.notice = ""
	game.save_error = ""
	game.save_blocked = false
	for extent in [Vector2i(844, 390), Vector2i(740, 360), Vector2i(1280, 720)]:
		root.size = extent
		for state in ["accueil", "preparation", "catalogue", "pose", "pose-refusee", "coffre", "transfert", "transfert-butin-corps", "raid", "pause", "confirmation", "bilan", "defaite", "sauvegarde-illisible"]:
			game.selected = Vector2i(-1, -1)
			game.tool = Types.Tool.NONE
			game.preview = {}
			game.sim.grid[8][8] = Types.Tile.ROCK if state == "accueil" else Types.Tile.CORE
			game.save_blocked = state == "sauvegarde-illisible"
			game.save_error = "Sauvegarde illisible : elle est conservée. Recommencer pour créer une nouvelle partie." if game.save_blocked else ""
			game.raid.raid_active = state == "raid"
			game.raid.hero = {"name": "Neris", "class_name": "Vulpin", "level": 1, "hp": 80, "max_hp": 100} if state == "raid" else {}
			hud._welcome = state == "accueil"
			game.sim.loot_bags = []
			game.sim.corpses = []
			game.paused = state == "pause" or state == "confirmation"
			game.confirmation_open = state == "confirmation"
			game.result_open = state == "bilan" or state == "defaite"
			game.sim.game_over = state == "defaite"
			hud._reset_pending = state == "confirmation"
			hud._catalog_open = state == "catalogue"
			if state.begins_with("pose"):
				game.tool = Types.Tool.TRAP_SPIKE
				game.selected = Vector2i(7, 8)
				game.preview = {"valid": true, "cost": 35}
				if state == "pose-refusee": game.preview = {"valid": false, "cost": 0, "reason": "Creusez cette case avant de bâtir."}
			if state == "coffre" or state.begins_with("transfert"): game.selected = Vector2i(7, 7)
			if state == "transfert-butin-corps":
				game.sim.loot_bags = [{"pos": Vector2i(7, 7), "gold": 10}]
				game.sim.corpses = [{"pos": Vector2i(7, 7)}]
			hud._refresh(false)
			if state.begins_with("transfert"):
				hud.selection._transfer_open = true
				hud.selection._amount = 150
				hud.selection.refresh()
			for frame in 5: await process_frame
			hud._layout()
			for frame in 3: await process_frame
			var items: Array = []
			_describe(hud.root, items)
			observations.append({"window": [extent.x, extent.y], "state": state, "ui_scale": hud.scale.x, "root": [hud.root.size.x, hud.root.size.y], "safe": str(hud._safe), "controls": items})
	var file := FileAccess.open("res://artifacts/hud-layout.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(observations, "\t"))
	file.close()
	print("HUD layout inventory: ", observations.size(), " static presentations; no player commands or saves.")
	game.queue_free()
	await process_frame
	quit()

func _describe(node: Node, items: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Button or node is Label or node is PanelContainer:
		var bounds: Rect2 = node.get_global_rect()
		items.append({"type": node.get_class(), "path": str(node.get_path()), "text": node.text if node is Button or node is Label else "", "position": [bounds.position.x, bounds.position.y], "size": [bounds.size.x, bounds.size.y], "minimum": [node.get_combined_minimum_size().x, node.get_combined_minimum_size().y], "disabled": node.disabled if node is Button else false})
	for child in node.get_children(): _describe(child, items)
