extends SceneTree
## Art-review fixture. Render the game's existing kit, without touching a saved dungeon.
const OUT := "res://docs/reference/treasury-review/v3-salle-ouverte/"
const Renderer = preload("res://scripts/mobile_dungeon_renderer.gd")
const Terrain = preload("res://scripts/game/excavation_terrain.gd")
const Types = preload("res://scripts/game/game_types.gd")
const ROOM := [Vector2i(6,6), Vector2i(7,6), Vector2i(6,7), Vector2i(7,7)]
const PASSAGE := [Vector2i(6,8), Vector2i(6,9), Vector2i(6,10), Vector2i(6,11)]
const CENTER := Vector2(7,7)
var view: Node2D
var stage := SubViewport.new()

func _initialize() -> void:
	call_deferred("capture")

func save_view(name_: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var err := stage.get_texture().get_image().save_png(OUT + name_ + ".png")
	if err != OK:
		push_error("Save failed: " + name_)
		quit(1)

func capture() -> void:
	stage.size = Vector2i(880, 500)
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(stage)
	var game := IsometricGameSession.new()
	game.persistence_enabled = false
	var terrain := Terrain.new()
	game.add_child(terrain)
	terrain.owner = game
	view = Renderer.new()
	game.add_child(view)
	stage.add_child(game)
	game.set_process(false)
	var cells := {}
	for p in ROOM + PASSAGE:
		game.sim.grid[p.y][p.x] = Types.Tile.FLOOR
		cells[p] = true
	game.changed.emit(true)
	var camera := Camera2D.new()
	stage.add_child(camera)
	camera.zoom = Vector2(1.28, 1.28)
	camera.position = view.grid_to_local(CENTER) + Vector2(-35, -15)
	var chests := {
		Vector2(6.5,6.5): "prop-chest-open",
		Vector2(7.5,6.5): "prop-chest-open-west",
		Vector2(6.5,7.5): "prop-chest-open-east",
		Vector2(7.5,7.5): "prop-chest-open-north"
	}
	var plan := {"cells":cells, "openings":{}, "wall_variants":true, "floor_variants":true,
		"decoration_positions":chests}
	view.render_plan(plan, {}, true, false)
	if not view.get_decoration_issues().is_empty():
		push_error(str(view.get_decoration_issues()))
		quit(1)
		return
	await save_view("avant")
	plan["decoration_positions"] = {}
	for style: String in ["eboulis","cuve"]:
		# Existing wall fittings of the kit keep the same mounting, masonry and scale.
		plan["torch_north_cells"] = [Vector2i(7,6)] if style == "eboulis" else []
		plan["torch_west_cells"] = [Vector2i(6,6)] if style == "eboulis" else []
		if style == "cuve":
			plan["decoration_positions"] = {Vector2(6.36,6.38):"prop-crystals"}
		view.render_plan(plan, {}, true, false)
		if not view.get_decoration_issues().is_empty():
			push_error(str(view.get_decoration_issues()))
			quit(1)
			return
		# Set a small bronze lozenge INTO the paving at the open threshold.
		lozenge(Vector2(6.5,7.94))
		if style == "eboulis":
			for node in view._world.get_children():
				if node is PointLight2D:
					node.energy *= .52
			lozenge(Vector2(6.45,6.45))
		var file := OUT + "source/" + style + ".png"
		if not FileAccess.file_exists(file):
			push_error("Missing proposal artwork: " + file)
			quit(1)
			return
		var art := Image.load_from_file(file)
		assert(art != null and art.detect_alpha() != Image.ALPHA_NONE)
		# Measured at alpha >= 100 on the original PNG. Keep the surrounding
		# contact shadow without letting faint stray alpha set the scale.
		var silhouette := Rect2i(332,277,994,354) if style == "eboulis" else Rect2i(279,235,972,544)
		var crop := art.get_region(silhouette.grow(45))
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		# Mipmaps preserve the grouped gold tones at gameplay distance.
		crop.generate_mipmaps()
		sprite.texture = ImageTexture.create_from_image(crop)
		sprite.scale = Vector2.ONE * ((266.0 if style == "eboulis" else 297.0) / silhouette.size.x)
		sprite.position = view.grid_to_local(CENTER) + Vector2(0,-9 if style == "eboulis" else -4)
		sprite.light_mask = 0
		view._world.add_child(sprite)
		# Draw at floor level so the perimeter masonry occludes the insert if needed.
		await save_view(style)
	print("Treasury proposals complete.")
	quit()

func lozenge(at: Vector2) -> void:
	inset(at, Vector2(.17,.17), Color("131b2a"))
	inset(at, Vector2(.13,.13), Color("67614f"))
	inset(at, Vector2(.085,.085), Color("303848"))

func inset(at: Vector2, size_: Vector2, tone: Color) -> void:
	var shape := Polygon2D.new()
	var vertices := PackedVector2Array()
	for sign_: Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		vertices.append(view.grid_to_local(at + sign_ * size_ * .5))
	shape.polygon = vertices
	shape.color = tone
	view._world.add_child(shape)
