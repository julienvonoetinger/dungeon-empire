extends SceneTree
const SCENE=preload("res://scenes/DigBlocksPreview.tscn")
const OUT="res://artifacts/dig-spacing/"
var failures: Array[String]=[]
var checks:=0
var pairs: Array[Dictionary]=[]
var initial_sizes: Dictionary={}

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func inspect(preview: Node, stage: int) -> void:
	var blocks: Array=preview.targets.blocks
	var view: Node2D=preview.game.get_node("PlayArea/World/Dungeon")
	for block in blocks:
		var size: Vector3=block.support.max-block.support.min
		if stage==0:
			var label: String="%.2f x %.2f x %.6f" % [size.x,size.y,size.z]
			initial_sizes[label]=initial_sizes.get(label,0)+1
		check(size.is_equal_approx(Vector3(.87,.87,0)),"Stage "+str(stage)+" uniform flat footprint at "+str(block.cell))
		var top: PackedVector2Array=block.footprint
		check((top[1]-top[0]).distance_to(view.grid_to_local(Vector2(.87,0)))<.001 and (top[3]-top[0]).distance_to(view.grid_to_local(Vector2(0,.87)))<.001,"Stage "+str(stage)+" uniform projected tile at "+str(block.cell))
	for i in blocks.size():
		for j in range(i+1,blocks.size()):
			var a: Dictionary=blocks[i].support; var b: Dictionary=blocks[j].support
			var overlap:=Vector2(minf(a.max.x,b.max.x)-maxf(a.min.x,b.min.x),minf(a.max.y,b.max.y)-maxf(a.min.y,b.min.y))
			checks+=1
			if overlap.x>.0001 and overlap.y>.0001:
				failures.append("Stage "+str(stage)+" excavation footprints overlap: "+str(blocks[i].cell)+" / "+str(blocks[j].cell))
				pairs.append({"stage":stage,"a":str(blocks[i].cell),"a_min":str(a.min),"a_max":str(a.max),"b":str(blocks[j].cell),"b_min":str(b.min),"b_max":str(b.max),"overlap":str(overlap)})
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var preview=SCENE.instantiate(); root.add_child(preview)
	for i in 8: await process_frame
	inspect(preview,0)
	var initial_grid: Array=preview.game.sim.grid.duplicate(true)
	var initial_gold: int=preview.game.sim.gold
	var rng:=RandomNumberGenerator.new(); rng.seed=241025
	var transactions:=0
	for step in 24:
		var blocks: Array=preview.targets.blocks
		if blocks.is_empty(): break
		var cell: Vector2i=blocks[rng.randi_range(0,blocks.size()-1)].cell
		var gold: int=preview.game.sim.gold
		preview.game.dig_cell(cell)
		for i in 2: await process_frame
		check(preview.game.sim.grid[cell.y][cell.x]==preview.game.Types.Tile.FLOOR and preview.game.sim.gold==gold-5,"Expansion "+str(step)+" really excavates one cell")
		transactions+=1
		inspect(preview,step+1)
	for step in transactions:
		var gold: int=preview.game.sim.gold
		preview.game.undo_build()
		for i in 2: await process_frame
		check(preview.game.sim.gold==gold+5,"Undo "+str(step)+" really restores a transaction")
		inspect(preview,-step-1)
	check(transactions==24,"All24 planned expansions were exercised")
	check(preview.game.sim.grid==initial_grid and preview.game.sim.gold==initial_gold,"Undo restores the initial grid and balance")
	check(not preview.game.persistence_enabled,"Spacing fixture does not access player saves")
	FileAccess.open(OUT+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"pairs":pairs,"expansions":transactions,"seed":241025,"initial_sizes":initial_sizes},"\t"))
	print("Dig spacing: ",checks," checks, ",failures.size()," failures")
	for failure in failures: print(failure)
	preview.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)
