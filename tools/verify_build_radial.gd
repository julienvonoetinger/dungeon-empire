extends SceneTree
## Real HUD, no player save and no simulation clock. Run graphically for captures.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
const OUT = "res://artifacts/radial-review/"
var failures: Array[String] = []
var checks := 0
var captures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func settle() -> void:
	for i in 8: await process_frame

func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+name+".png")
	captures.append(name)

func mouse(point: Vector2,pressed: bool) -> InputEventMouseButton:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed; event.position=point
	return event

func click(control: Control,point: Vector2,hud: CanvasLayer) -> void:
	var screen: Vector2=(control.position+point)*hud.scale.x
	root.push_input(mouse(screen,true),true)
	await process_frame
	root.push_input(mouse(screen,false),true)
	await settle()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1280,720)
	var game = GAME.instantiate()
	game.persistence_enabled = false
	root.add_child(game); game.set_process(false)
	await settle()
	var hud = game.get_node("HUD")
	hud._welcome = false
	game.restart(true)
	game.notice = ""
	game.sim.gold = 225
	game.progression.xp = 280
	game.changed.emit(true)
	for node in hud.root.get_children():
		if node.has_meta("transient_feedback"): node.queue_free()
	await settle()
	hud.world_tapped(Vector2i(7,8))
	await settle()
	check(hud.radial.visible, "A free floor cell opens construction")
	check(hud.radial.size.x >= 330, "Desktop radial must have room for larger icons and a separate price rim")
	var centre: Vector2 = hud.radial.menu_center() if hud.radial.has_method("menu_center") else Vector2(130,130)
	check(hud.radial._choice_at(centre + Vector2(0,-160)) >= 0, "The enlarged outer price rim must be an actionable part of its sector")
	await capture("desktop")
	hud.handle_back()
	var before: int=game.sim.gold
	var shapes: Array=[]
	for extent in [Vector2i(1280,720),Vector2i(844,390),Vector2i(740,360),Vector2i(667,375),Vector2i(568,320),Vector2i(568,299),Vector2i(390,844),Vector2i(320,568),Vector2i(390,390),Vector2i(480,320),Vector2i(512,320)]:
		root.size=extent; await settle()
		for target in [Vector2i(0,0),Vector2i(15,0),Vector2i(0,15),Vector2i(15,15),Vector2i(7,8)]:
			hud.world_tapped(target); await settle()
			var radial=hud.radial
			var rect: Rect2=radial.get_global_rect()
			check(hud._safe.grow(.1).encloses(rect),"Radial stays within safe area: %s %s" % [extent,target])
			check(rect.position.y>=hud.header.position.y+hud.header.size.y-.1,"Radial keeps clear of the header: "+str(extent))
			check(Rect2(Vector2.ZERO,radial.size).encloses(radial.cancel_button.get_rect()),"Close button is not clipped: "+str(extent))
			check(radial.inner-radial.centre_radius>=48 and radial.radius-radial.inner>=48,"Touch sectors retain 48-unit radial depth")
			var view: Node2D=game.get_node("PlayArea/World/Dungeon")
			var cell_screen: Vector2=(view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(target)+Vector2(.5,.5)))/hud.scale.x
			check(cell_screen.distance_to(radial.position+radial.menu_center())<.1,"Camera aligns the chosen cell with the resized menu")
			for group in 4:
				radial._choose_family(group)
				for index in radial.choices.size():
					check(radial._choice_at(radial.choice_point(index))==index,"Icon belongs to its action")
					check(radial._choice_at(radial.choice_point(index,true))==index,"Price band belongs to the same action")
					var definition: Array=radial.choices[index]
					var action: Dictionary=game.check_action(target,definition[0])
					if action.valid:
						check(radial._price(definition,action)==str(action.cost),"Displayed price matches the live transaction")
			if target==Vector2i(7,8):
				radial._choose_family(2)
				await capture("%dx%d-traps" % [extent.x,extent.y])
				var price: Vector2=radial.choice_point(0,true)
				radial._gui_input(mouse(price,true))
				check(radial._hover==0 and game.sim.gold==before,"Press highlights the price without buying")
				await capture("%dx%d-price" % [extent.x,extent.y])
				# Sample a point near the outside of the rim, away from its number.
				var direction: Vector2=(price-radial.menu_center()).normalized().rotated(.13)
				var sample: Vector2=(radial.position+radial.menu_center()+direction*(radial.radius-6))*hud.scale.x
				var pixels:=root.get_texture().get_image()
				sample*=Vector2(pixels.get_size())/root.get_visible_rect().size
				var color:=pixels.get_pixelv(Vector2i(sample))
				check(absf(color.r-0.85)<.03 and absf(color.g-.71)<.03,"The pressed price band is visibly highlighted: "+str(extent))
				radial.cancel_pointer()
				shapes.append({"viewport":str(extent),"radius":radial.radius,"menu":str(radial.size)})
			hud.handle_back()
	check(game.sim.gold==before,"Navigation and layout changes never spend gold")
	root.size=Vector2i(844,390); await settle()
	hud.world_tapped(Vector2i(7,8)); await settle()
	# Invalid actions are still inspectable but cannot spend or close the menu.
	hud.radial._choose_family(0)
	await click(hud.radial,hud.radial.choice_point(0,true),hud)
	check(game.sim.gold==before and hud.radial.visible,"An invalid price-band click cannot buy")
	hud.radial._choose_family(2)
	# The centre is visibly round. Its rectangular control corners must not
	# steal taps that belong to the four neighbouring family wedges.
	var directions: Array[Vector2]=[Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]
	for index in 4:
		var corner: Vector2=hud.radial.menu_center()+directions[index]*(hud.radial.centre_radius-5)
		await click(hud.radial,corner,hud)
		check(hud.radial.visible and not hud.catalog.visible and hud.radial.category==index,"Round Tout hit area must not steal family corner "+str(index))
		if hud.catalog.visible:
			hud._close_catalog(); hud.world_tapped(Vector2i(7,8)); await settle()
	hud.radial._choose_family(2)
	var price_point: Vector2=hud.radial.choice_point(0,true)
	# An emulated mouse stream cannot duplicate a native touch. Nor may a
	# canceled or out-and-back drag become a purchase when released at its start.
	var synthetic:=mouse(price_point,true); synthetic.device=-1
	hud.radial._gui_input(synthetic)
	synthetic=mouse(price_point,false); synthetic.device=-1
	hud.radial._gui_input(synthetic)
	check(game.sim.gold==before and not hud.radial._down,"Synthetic mouse events do not rearm a touch")
	var local_touch:=InputEventScreenTouch.new(); local_touch.index=0
	local_touch.position=price_point; local_touch.pressed=true
	hud.radial._gui_input(local_touch)
	var drag:=InputEventScreenDrag.new(); drag.index=0; drag.position=price_point+Vector2(32,0)
	hud.radial._gui_input(drag)
	drag.position=price_point; hud.radial._gui_input(drag)
	local_touch=local_touch.duplicate(); local_touch.pressed=false
	hud.radial._gui_input(local_touch)
	check(game.sim.gold==before and hud.radial.visible,"Dragging out and back cannot buy on release")
	local_touch=local_touch.duplicate(); local_touch.pressed=true
	hud.radial._gui_input(local_touch)
	local_touch=local_touch.duplicate(); local_touch.pressed=false; local_touch.canceled=true
	hud.radial._gui_input(local_touch)
	check(game.sim.gold==before and not hud.radial._down,"Canceled native touch cannot buy")
	var touch := InputEventScreenTouch.new()
	touch.index=0; touch.pressed=true
	touch.position=(hud.radial.position+hud.radial.choice_point(0,true))*hud.scale.x
	root.push_input(touch,true); await process_frame
	check(hud.radial._hover==0,"A real touchscreen press highlights the price band")
	touch=touch.duplicate(); touch.pressed=false
	root.push_input(touch,true); await settle()
	check(game.sim.gold==before-35 and game.sim.grid[8][7]==TYPES.Tile.SPIKE,"A real touchscreen release on the price band buys exactly once")
	check(game.tool==TYPES.Tool.TRAP_SPIKE and not hud.radial.visible,"Price-band selection keeps repeat placement")
	game.cancel_selection()
	hud.world_tapped(Vector2i(8,7)); await settle()
	hud.radial._choose_family(3)
	await click(hud.radial,hud.radial.all_button.get_rect().get_center(),hud)
	check(hud.catalog.visible and hud.catalog.category==3,"The centred Tout control opens the current family")
	hud._close_catalog()
	game.queue_free(); await process_frame
	var report = FileAccess.open(OUT+"report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"layouts":shapes,"captures":captures},"\t")); report.close()
	print("Build radial: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
