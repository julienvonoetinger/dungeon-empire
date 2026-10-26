extends SceneTree
## Static background presentation inventory. No player commands or save writes.
const Game = preload("res://scenes/game/DungeonGame.tscn")
const Types = preload("res://scripts/game/game_types.gd")
const OUT := "res://docs/reference/treasure-chest-review/v2/integration/"
var observations: Array = []

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var game := Game.instantiate()
	# Override before _ready reads anything; never touch the user's save slot.
	game.save_path = OUT + "never-created.save"
	game.set_process(false)
	root.add_child(game)
	game.set_process(false)
	await process_frame
	game.sim.new_map()
	for y in range(5, 10):
		for x in range(5, 10): game.sim.grid[y][x] = Types.Tile.FLOOR
	game.sim.grid[6][6] = Types.Tile.CORE
	var cells := [Vector2i(5,5),Vector2i(7,7),Vector2i(8,7),Vector2i(8,8)]
	for p in cells:
		game.sim.grid[p.y][p.x] = Types.Tile.VAULT
		game.sim.vault_gold[p] = 37
	game.sim.vault_gold[cells[0]] = 150
	game.sim.vault_gold[cells[3]] = 0
	game.sim.vault_locks[cells[1]] = 1
	game.sim.vault_locks[cells[2]] = 2
	var view = game.get_node("PlayArea/World/Dungeon")
	view.rebuild()
	await process_frame
	_observe("four-chests", view)
	game.sim.vault_gold[cells[1]] = 91
	view._update_markers()
	_observe("gold-without-rebuild", view)
	var previous_hash: int = game._structure_hash()
	game.sim.vault_opened[cells[1]] = true
	var opened_hash: int = game._structure_hash()
	view.rebuild()
	_observe("lock-forced", view)
	observations.back()["visual_hash_changed"] = previous_hash != opened_hash
	game.sim.vault_opened.erase(cells[1])
	view.rebuild()
	_observe("lock-restored", view)
	game.sim.grid[cells[2].y][cells[2].x] = Types.Tile.FLOOR
	view.rebuild()
	await process_frame
	_observe("removed", view)
	game.sim.grid[cells[2].y][cells[2].x] = Types.Tile.VAULT
	view.rebuild()
	await process_frame
	_observe("restored", view)
	game.raid.raid_active = true
	game.raid.hero = {"pos":Vector2i(7,6),"name":"Neris","kind":"thief","level":1,"hp":80,"max_hp":100}
	view.rebuild()
	await process_frame
	_observe("hero-behind", view)
	game.raid.hero.pos = Vector2i(7,8)
	view._update_markers()
	_observe("hero-in-front", view)
	var file := FileAccess.open(OUT + "scene-inventory.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures":observations,"kind":"Static headless inventory; no GPU capture or gameplay simulation"}, "\t"))
	file.close()
	print("Chest inventory: ", observations.size(), " static presentations, no player commands or save writes.")
	game.queue_free()
	await process_frame
	quit()

func _observe(title: String, view: Node2D) -> void:
	var sprites: Array = []
	var labels: Array = []
	_walk(view._world, sprites, labels)
	var solids: Array = []
	for p in view.solid_groups:
		solids.append({"id":p.get("id","proxy"),"at":[p.at.x,p.at.y],"index":p.node.get_index(),"min":[p.min.x,p.min.y,p.min.z],"max":[p.max.x,p.max.y,p.max.z]})
	var actor = view._actor
	observations.append({"capture":title,"issues":Array(view.get_decoration_issues()),"sprites":sprites,"labels":labels,"solids":solids,"hero_index":actor.get_index() if is_instance_valid(actor) else -1})

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
