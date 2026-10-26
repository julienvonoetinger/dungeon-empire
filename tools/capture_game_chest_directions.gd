extends SceneTree
## Static presentation inventory. No player commands, raid stepping or save writes.
const Game = preload("res://scenes/game/DungeonGame.tscn")
const Types = preload("res://scripts/game/game_types.gd")
const OUT := "res://docs/reference/treasure-chest-review/v4-directions/"
var observations: Array = []

func _initialize() -> void:
	call_deferred("_capture")

func _vault(sim: DungeonSim, p: Vector2i, locked := false) -> void:
	sim.grid[p.y][p.x] = Types.Tile.VAULT
	sim.vault_gold[p] = 95
	if locked: sim.vault_locks[p] = 1

func _capture() -> void:
	var game := Game.instantiate()
	game.save_path = OUT + "never-created.save"
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var sim: DungeonSim = game.sim
	var view = game.get_node("PlayArea/World/Dungeon")
	sim.new_map()
	for y in range(5,10):
		for x in range(5,10): sim.grid[y][x] = Types.Tile.FLOOR
	sim.grid[7][7] = Types.Tile.CORE
	var corners := [Vector2i(5,5), Vector2i(9,5), Vector2i(9,9), Vector2i(5,9)]
	for i in corners.size(): _vault(sim, corners[i], i % 2 == 0)
	view.rebuild()
	await process_frame
	_observe("corners-mixed", view)
	var before: int = game._structure_hash()
	for p in corners: sim.vault_opened[p] = true
	var after: int = game._structure_hash()
	view.rebuild()
	await process_frame
	_observe("corners-open", view)
	observations.back()["unlock_changes_structure"] = before != after
	sim.vault_gold[corners[0]] = 12
	view._update_markers()
	_observe("gold-without-rebuild", view)
	sim.vault_opened.clear()
	view.rebuild()
	await process_frame
	_observe("corners-restored", view)
	for direction in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]:
		sim.new_map()
		var p := Vector2i(7,7)
		_vault(sim, p, true)
		for n in [1,2]:
			var floor_cell: Vector2i = p + direction * n
			sim.grid[floor_cell.y][floor_cell.x] = Types.Tile.FLOOR
		view.rebuild()
		await process_frame
		_observe("single-exit-" + str(direction), view)
	sim.new_map()
	_vault(sim, Vector2i(7,7), true)
	view.rebuild()
	await process_frame
	_observe("enclosed-fallback", view)
	sim.new_map()
	_vault(sim, Vector2i.ZERO)
	sim.grid[0][1] = Types.Tile.FLOOR
	view.rebuild()
	await process_frame
	_observe("border", view)
	sim.new_map()
	_vault(sim, Vector2i(7,7))
	_vault(sim, Vector2i(8,7))
	sim.grid[8][7] = Types.Tile.CORE
	sim.grid[6][7] = Types.Tile.FLOOR
	sim.grid[7][6] = Types.Tile.DOOR
	sim.door_hp[Vector2i(6,7)] = 100
	sim.grid[7][5] = Types.Tile.FLOOR
	view.rebuild()
	await process_frame
	_observe("heart-vault-door-obstacles", view)
	sim.door_hp[Vector2i(6,7)] = 0
	view.rebuild()
	await process_frame
	_observe("door-open-clearance", view)
	sim.grid[6][7] = Types.Tile.ENTRANCE
	view.rebuild()
	await process_frame
	_observe("stairs-excluded", view)
	var file := FileAccess.open(OUT + "scene-inventory.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures":observations,"kind":"Static headless inventory; no GPU capture or gameplay simulation"}, "\t"))
	file.close()
	print("Chest direction inventory: ", observations.size(), " static presentations; no player commands or save writes.")
	game.queue_free()
	await process_frame
	quit()

func _observe(title: String, view: Node2D) -> void:
	var sprites: Array = []
	var labels: Array = []
	_walk(view._world, sprites, labels)
	var facings: Array = []
	for p: Vector2i in view.chest_facings:
		facings.append({"cell":[p.x,p.y],"facing":view.chest_facings[p].facing,"accessible":view.chest_facings[p].accessible})
	var solids: Array = []
	for p in view.solid_groups:
		solids.append({"id":p.get("id","proxy"),"at":[p.at.x,p.at.y],"index":p.node.get_index(),"min":[p.min.x,p.min.y,p.min.z],"max":[p.max.x,p.max.y,p.max.z]})
	observations.append({"capture":title,"issues":Array(view.get_decoration_issues()),"facings":facings,"sprites":sprites,"labels":labels,"solids":solids})

func _walk(node: Node, sprites: Array, labels: Array) -> void:
	for child in node.get_children():
		if child is Sprite2D and child.has_meta("prepared_id"):
			var id := str(child.get_meta("prepared_id"))
			var receiving: Dictionary = child.get_meta("receiving",{})
			var r := {}
			if not receiving.is_empty(): r={"origin":[receiving.origin.x,receiving.origin.y],"bits":receiving.bits,"enabled":receiving.enabled}
			sprites.append({"id":id,"atlas":child.texture.atlas.resource_path,"position":[child.global_position.x,child.global_position.y],"size":[child.texture.get_width()*child.scale.x,child.texture.get_height()*child.scale.y],"z":child.z_index+child.get_parent().z_index,"index":child.get_index(),"parent_index":child.get_parent().get_index(),"receiving":r})
		if child is Label and child.get_parent().get("kind") == "chest":
			labels.append({"text":child.text,"position":[child.global_position.x,child.global_position.y],"width":child.size.x})
		_walk(child,sprites,labels)
