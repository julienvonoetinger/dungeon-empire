extends "res://docs/reference/treasury-review/v3-salle-ouverte/capture.gd"
const OUT_V9 := "res://docs/reference/treasury-review/v9-sprite-unique/"
const Treasure := preload("res://docs/reference/treasury-review/v9-sprite-unique/renderer.gd")
const Layouts := "res://docs/reference/treasury-review/v5-wireframe/layouts.json"
func make_view() -> Node2D:
	return Treasure.new()

func review_directory() -> String:
	return OUT_V9

func check_placement(_row: Dictionary,inward: Vector2) -> void:
	assert(view.draw_count==1)
	assert((view.anchor-CENTER).dot(inward)+1.0-view.support_half.x >= .36)

func capture() -> void:
	stage.size=Vector2i(900,600)
	stage.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var game := IsometricGameSession.new()
	game.persistence_enabled=false
	var terrain := Terrain.new()
	game.add_child(terrain)
	terrain.owner=game
	view=make_view()
	game.add_child(view)
	stage.add_child(game)
	game.set_process(false)
	var camera := Camera2D.new()
	stage.add_child(camera)
	camera.zoom=Vector2.ONE*1.05
	camera.position=view.grid_to_local(CENTER)+Vector2(0,-44)
	var layouts: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Layouts))
	DirAccess.make_dir_recursive_absolute(review_directory()+"vues")
	for row: Dictionary in layouts.rows:
		game.sim.new_map()
		var cells: Dictionary={}
		for p in ROOM:
			cells[p]=true
			game.sim.grid[p.y][p.x]=Types.Tile.VAULT
		for delta: Array in row.passage:
			var p := Vector2i(6+delta[0],6+delta[1])
			cells[p]=true
			game.sim.grid[p.y][p.x]=Types.Tile.FLOOR
		game.changed.emit(true)
		var inward: Vector2={"N":Vector2.DOWN,"E":Vector2.LEFT,"S":Vector2.UP,"W":Vector2.RIGHT}[row.side]
		view.anchor=CENTER+inward*.135-Vector2(.05,.05)
		view.render_plan({"cells":cells,"openings":{},"wall_variants":true,"floor_variants":true},{},true,false)
		check_placement(row,inward)
		await process_frame
		await RenderingServer.frame_post_draw
		assert(stage.get_texture().get_image().save_webp(review_directory()+"vues/"+row.id+".webp",false)==OK)
	print("Eight ordinary-kit entrances, one shared treasure texture per view.")
	quit()
