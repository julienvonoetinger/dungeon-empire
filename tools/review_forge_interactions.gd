extends SceneTree
## Isolated interaction review of the Forge HUD. Synthetic mouse taps are pushed
## through the real viewport (GUI picking + game input), on an in-memory fixture.
## Saves go only to a dedicated review slot, removed afterwards; the player's
## isometric_run_v1.save is hashed before and after and never opened for writing.
const GAME = preload("res://scenes/game/DungeonGame.tscn")
const TYPES = preload("res://scripts/game/game_types.gd")
const OUT := "res://docs/reference/interface-review/design-pass-2/interaction/"
const REVIEW_SAVE := "user://forge_ux_review_v2.save"
const PLAYER_SAVE := "user://isometric_run_v1.save"
var steps: Array = []
var failures := 0
var game: Node
var hud: Node

func _initialize() -> void:
	call_deferred("_run")

func _hash(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"

func _clear_review_slot() -> void:
	for path in [REVIEW_SAVE,REVIEW_SAVE+".bak",REVIEW_SAVE+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var player_before := _hash(PLAYER_SAVE)
	for extent in [Vector2i(844,390),Vector2i(667,375),Vector2i(390,844),Vector2i(320,568)]:
		await _scenario(extent)
	var player_after := _hash(PLAYER_SAVE)
	_check("sauvegarde joueur inchangée",player_before==player_after,"%s → %s" % [player_before.left(12),player_after.left(12)])
	var file := FileAccess.open(OUT+"interaction-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"steps":steps,"player_save_sha256_before":player_before,"player_save_sha256_after":player_after},"\t")); file.close()
	print("Forge interaction review: ",steps.size()," checks, ",failures," failures. Review slot only.")
	quit(1 if failures>0 else 0)

func _scenario(extent: Vector2i) -> void:
	_clear_review_slot()
	root.size=extent
	game=GAME.instantiate()
	game.save_path=REVIEW_SAVE
	root.add_child(game)
	await _settle()
	hud=game.get_node("HUD")
	game.sim.new_map()
	for y in range(5,10):
		for x in range(5,10): game.sim.grid[y][x]=TYPES.Tile.FLOOR
	game.sim.grid[7][7]=TYPES.Tile.CORE
	game.sim.grid[7][9]=TYPES.Tile.ENTRANCE
	game.sim.grid[5][5]=TYPES.Tile.VAULT; game.sim.vault_gold[Vector2i(5,5)]=40
	game.sim.gold=225
	game.notice=""; game.save_error=""; game.save_blocked=false; hud._welcome=false
	game.changed.emit(true)
	game.get_node("Input").center_core()
	await _settle()
	var tag := "%dx%d" % [extent.x,extent.y]
	var world_idle: Rect2=hud._world_rect
	_check(tag+" quatre familles visibles",_all_visible(hud._family_buttons),hud.mode)
	await _tap_control(hud._family_buttons[2])
	_check(tag+" Pièges ouvre les variantes",hud.catalog.visible,"")
	await _shot(tag,"1-variantes")
	var spike: Button
	for card in hud.catalog.cards:
		if card.id==TYPES.Tool.TRAP_SPIKE: spike=card.button
	await _tap_control(spike)
	_check(tag+" variante armée, catalogue replié",game.tool==TYPES.Tool.TRAP_SPIKE and not hud.catalog.visible,"")
	_check(tag+" barre de pose + Arrêter visibles",hud.pose_bar.visible and hud.stop_button.visible,hud.pose_label.text.replace("\n"," / "))
	_check(tag+" armer ne déplace pas la vue",hud._world_rect==world_idle,str(hud._world_rect))
	await _shot(tag,"2-armee")
	var gold: int=game.sim.gold
	await _tap_cell(Vector2i(6,6))
	_check(tag+" pose directe 1",game.sim.grid[6][6]==TYPES.Tile.SPIKE and game.sim.gold==gold-35,"or %d" % game.sim.gold)
	await _tap_cell(Vector2i(8,6))
	_check(tag+" pose répétée 2, outil conservé",game.sim.grid[6][8]==TYPES.Tile.SPIKE and game.tool==TYPES.Tool.TRAP_SPIKE,"")
	game.sim.gold=0; game.changed.emit(false)
	await _tap_cell(Vector2i(6,8))
	_check(tag+" refus affiché dans la barre",game.sim.grid[8][6]==TYPES.Tile.FLOOR and hud.pose_bar.visible and hud.pose_label.text==game.notice and not game.notice.is_empty(),hud.pose_label.text)
	await _shot(tag,"3-refus")
	game.sim.gold=200; game.changed.emit(false)
	await _tap_control(hud.stop_button)
	_check(tag+" Arrêter désarme et efface le refus",game.tool==TYPES.Tool.NONE and not hud.pose_bar.visible,"")
	_check(tag+" vue stable pendant toute la pose",hud._world_rect==world_idle,"")
	await _tap_control(hud.undo_button)
	_check(tag+" Annuler retire la dernière pose",game.sim.grid[6][8]==TYPES.Tile.FLOOR and game.sim.grid[6][6]==TYPES.Tile.SPIKE,"")
	await _shot(tag,"4-annule")
	await _tap_control(hud.observe_button)
	_check(tag+" Observer libère la vue",hud.peek.visible and not hud.compact.visible,"")
	await _shot(tag,"5-observer")
	await _tap_control(hud.peek.get_child(0))
	_check(tag+" Bâtir revient aux familles",hud.compact.visible,"")
	game.queue_free()
	await _settle()
	_clear_review_slot()

func _all_visible(buttons: Array) -> bool:
	var view: Rect2=hud.root.get_global_rect()
	for button in buttons:
		var rect: Rect2=button.get_global_rect()
		var clip: Rect2=hud.tools_scroll.get_global_rect()
		if not button.is_visible_in_tree() or not view.encloses(rect) or not clip.grow(.5).encloses(rect) or rect.size.y<48: return false
	return true

func _check(name: String, ok: bool, detail: String) -> void:
	steps.append({"check":name,"ok":ok,"detail":detail})
	if not ok:
		failures+=1
		printerr("ÉCHEC ",name," ",detail)

func _tap_control(control: Control) -> void:
	await _tap(control.get_global_transform_with_canvas()*(control.size/2))

func _tap_cell(cell: Vector2i) -> void:
	var view: Node2D=game.get_node("PlayArea/World/Dungeon")
	var play: Control=game.get_node("PlayArea")
	await _tap(play.position+view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(cell)+Vector2(.5,.5)))

func _tap(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed
		event.position=point; event.global_position=point
		root.push_input(event,true)
		await process_frame
	await _settle()

func _settle() -> void:
	for frame in 6: await process_frame

func _shot(tag: String, title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+tag+"-"+title+".png")
