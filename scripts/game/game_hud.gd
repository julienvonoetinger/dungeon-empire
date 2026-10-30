extends CanvasLayer

const UI=preload("res://scripts/game/ui/hud_theme.gd")
const Catalog=preload("res://scripts/game/ui/hud_catalog.gd")
const Selection=preload("res://scripts/game/ui/hud_selection.gd")
const Header=preload("res://scripts/game/ui/hud_master_header.gd")
const Radial=preload("res://scripts/game/ui/hud_build_radial.gd")
const Types=preload("res://scripts/game/game_types.gd")
const Notices=preload("res://scripts/game/ui/hud_notices.gd")
const DEFAULT_NOTICES:=["","Action effectuée.","Aménagement","Donjon retrouvé. La préparation reprend."]
var session: IsometricGameSession
var root: Control
var header: Control
var utilities: HBoxContainer
var undo_button: Button
var catalog_button: Button
var path_button: Button
var pause_button: Button
var speeds: HBoxContainer
var speed_buttons: Array[Button]=[]
var pose_bar: PanelContainer
var pose_label: Label
var stop_button: Button
var hint: Label
var catalog: PanelContainer
var selection: PanelContainer
var radial: Control
var radial_shield: Control
var shade: ColorRect
var modal: PanelContainer
var modal_scroll: ScrollContainer
var modal_title: Label
var modal_text: Label
var modal_resume: Button
var modal_new: Button
var modal_demo: Button
var modal_raid: Button
var result_stats: HBoxContainer
var result_values: Array[Label]=[]
var _catalog_open:=false
var _welcome:=true
var _reset_pending:=false
var _reset_prepared:=false
var _safe:=Rect2()
var _world_rect:=Rect2()
var _layout_queued:=false
var _elapsed:=0.0
var _last_gold:=0
var _last_hp:=100
var mode:="landscape"

func _ready() -> void:
	session=get_parent() as IsometricGameSession
	root=Control.new(); root.name="MasterHUD"; root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.theme=UI.create(); add_child(root)
	header=Header.new(); root.add_child(header); header.menu_requested.connect(_open_menu)
	utilities=HBoxContainer.new(); root.add_child(utilities)
	utilities.add_theme_constant_override("separation",8)
	catalog_button=UI.tile(utilities,"catalog","Catalogue",func(): _open_catalog(catalog.category))
	path_button=UI.tile(utilities,"path","Accès",_toggle_path); path_button.toggle_mode=true
	undo_button=UI.tile(utilities,"undo","Annuler",session.undo_build)
	pause_button=UI.tile(utilities,"pause","Pause",_open_menu)
	for button in [catalog_button,path_button,undo_button,pause_button]: button.custom_minimum_size=Vector2(58,54)
	speeds=HBoxContainer.new(); root.add_child(speeds)
	for value in [1,2]:
		var button:=UI.button(speeds,"%d×" % value,func(): session.raid_speed=value; _refresh(false))
		button.toggle_mode=true; button.custom_minimum_size=Vector2(52,48); speed_buttons.append(button)
	pose_bar=_panel(root); pose_bar.name="PlacementBar"
	pose_bar.add_theme_stylebox_override("panel",UI.command_surface(true,10))
	var pose_box:=HBoxContainer.new(); pose_bar.add_child(pose_box)
	pose_label=UI.label(pose_box,"",13); pose_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	pose_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	pose_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stop_button=UI.button(pose_box,"Arrêter",_stop_placing,"cross")
	stop_button.add_theme_font_size_override("font_size",12); stop_button.add_theme_constant_override("icon_max_width",16)
	stop_button.custom_minimum_size=Vector2(94,48)
	# Wrapped text/container minima settle after a viewport or width change.
	# Refit then, rather than retaining a transient oversized panel until a tap.
	pose_bar.minimum_size_changed.connect(_queue_layout)
	hint=UI.label(root,"",12,UI.MUTED); hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	radial_shield=Control.new(); root.add_child(radial_shield); radial_shield.mouse_filter=Control.MOUSE_FILTER_STOP
	radial_shield.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed: _close_radial())
	radial=Radial.new(); radial.session=session; radial_shield.add_child(radial)
	radial.tool_chosen.connect(_radial_tool); radial.catalogue_requested.connect(_open_catalog); radial.closed.connect(_close_radial)
	radial_shield.hide()
	catalog=Catalog.new(); root.add_child(catalog)
	catalog.tool_chosen.connect(_choose_tool); catalog.closed.connect(_close_catalog)
	catalog.minimum_size_changed.connect(_queue_layout)
	catalog.row.minimum_size_changed.connect(_queue_layout)
	for card in catalog.cards: card.button.gui_input.connect(func(event): session.get_node("Input").palette_event(card.button,card.id,event))
	selection=Selection.new(); selection.session=session; root.add_child(selection)
	selection.dismissed.connect(session.cancel_selection); selection.layout_changed.connect(_queue_layout)
	_build_modal()
	modal_raid=UI.button(modal_scroll.get_child(0),"Lancer le raid",_launch_raid,"",true)
	modal_raid.get_parent().move_child(modal_raid,modal_resume.get_index()+1)
	modal_scroll.get_child(0).minimum_size_changed.connect(_queue_layout)
	session.changed.connect(_refresh); session.frame_updated.connect(_tick)
	get_viewport().size_changed.connect(_queue_layout)
	_last_gold=session.sim.gold; _queue_layout()

func _panel(parent: Node) -> PanelContainer:
	var panel:=PanelContainer.new(); panel.mouse_filter=Control.MOUSE_FILTER_STOP
	parent.add_child(panel); return panel

func world_tapped(cell: Vector2i) -> void:
	if not session.can_edit() or not session.sim._inside(cell) or shade.visible: return
	if radial.visible: _close_radial(); return
	if _catalog_open: _close_catalog(); return
	if session.selected.x>=0 and session.tool==Types.Tool.NONE: session.cancel_selection()
	if session.tool!=Types.Tool.NONE or not session.sim._has_core(): session.activate_cell(cell); return
	var tile: int=session.sim.grid[cell.y][cell.x]
	if tile not in [Types.Tile.ROCK,Types.Tile.FLOOR] or session.sim.loot_bags.any(func(b): return b.pos==cell and b.gold>0) or session.sim.corpses.any(func(c): return c.pos==cell):
		session.select_cell(cell); return
	session.selected=cell; session.preview={}
	radial.open_at(cell); radial_shield.show(); session.catalog_open=true
	_position_radial(true); _refresh(false)

func _radial_tool(tool: int) -> void:
	if not session.can_edit() or not radial.visible: return
	var cell: Vector2i=radial.cell
	if not session.check_action(cell,tool).get("valid",false): return
	_close_radial(false); session.choose_tool(tool); session.activate_cell(cell)

func _close_radial(refresh: bool=true) -> void:
	var was_open:=radial.visible
	radial.hide(); radial_shield.hide(); session.catalog_open=_catalog_open
	if was_open: session.selected=Vector2i(-1,-1); session.preview={}
	if refresh: session.changed.emit(false)

func _position_radial(pan: bool) -> void:
	if not radial.visible: return
	var view: Node2D=session.get_node("PlayArea/World/Dungeon")
	var screen: Vector2=(view.get_global_transform_with_canvas()*view.grid_to_local(Vector2(radial.cell)+Vector2(.5,.5)))/scale.x
	var header_height:=header.size.y
	var area:=Rect2(_safe.position+Vector2(8,header_height),_safe.size-Vector2(16,header_height+4))
	radial.fit_available(area.size)
	var radial_center: Vector2=radial.menu_center()
	var origin: Vector2=(screen-radial_center).clamp(area.position,area.end-radial.size)
	radial.position=origin
	if pan:
		var camera: Camera2D=session.get_node("PlayArea/World/Camera2D")
		camera.position-=(origin+radial_center-screen)*scale.x/camera.zoom.x
		camera.force_update_scroll()

func _stop_placing() -> void:
	session.notice=""; session.cancel_selection()

func _open_menu() -> void:
	if session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked: return
	_close_radial(false); _catalog_open=false; session.catalog_open=false; session.set_paused(true)

func _open_catalog(category: int=0) -> void:
	if not session.can_edit(): return
	_close_radial(false); catalog._choose_category(category)
	_catalog_open=true; session.catalog_open=true; session.cancel_selection()

func _close_catalog() -> void:
	_catalog_open=false; session.catalog_open=false; _refresh(false)

func _choose_tool(tool: int) -> void:
	if not session.can_edit() or not session.progression.allows(tool): return
	_catalog_open=false; session.catalog_open=false; session.notice=""; session.choose_tool(tool)

func _toggle_path() -> void:
	var view=session.get_node("PlayArea/World/Dungeon")
	view.access_visible=not view.access_visible; view.queue_redraw()
	path_button.set_pressed_no_signal(view.access_visible)
	_refresh_live()

func _launch_raid() -> void:
	if not session.ready_for_raid() or session.confirmation_open or session.result_open or session.save_blocked: return
	_close_radial(false); session.set_paused(false); session.start_raid()

func handle_back() -> void:
	if _reset_pending or session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked: return
	if session.paused: session.set_paused(false)
	elif radial.visible: _close_radial()
	elif _catalog_open: _close_catalog()
	elif session.selected.x>=0 or session.tool!=Types.Tool.NONE: session.cancel_selection()
	else: _open_menu()

func blocks_pointer(point: Vector2) -> bool:
	if shade.visible or radial.visible: return true
	var logical:=point/scale.x
	if not _safe.has_point(logical): return true
	for control in [header,utilities,speeds,pose_bar,catalog,selection]:
		if control.visible and control.get_global_rect().has_point(logical): return true
	return false

func _update_eye_target() -> void:
	header.world_target=Vector2.INF
	var view=session.get_node("PlayArea/World/Dungeon")
	var local:=Vector2.INF
	if session.raid.raid_active and not session.raid.hero.is_empty():
		# The renderer owns interpolation, jumps and exit offsets. Reuse its
		# actual actor anchor rather than following cell centers in discrete hops.
		if is_instance_valid(view._actor) and view._actor.visible:
			local=view._actor.position
	elif session.selected.x>=0:
		local=view.grid_to_local(Vector2(session.selected)+Vector2(.5,.5))
	if not local.is_finite(): return
	var play:SubViewportContainer=session.get_node("PlayArea")
	var world:SubViewport=session.get_node("PlayArea/World")
	var in_world:Vector2=view.get_global_transform_with_canvas()*local
	header.world_target=play.get_global_transform_with_canvas()*(in_world*play.size/Vector2(world.size))

func _tick() -> void:
	_update_eye_target()
	var dt:=get_process_delta_time(); header.refresh(session,dt); _elapsed+=dt
	if _elapsed<.1: return
	_elapsed=0; _refresh_live()

func _refresh(_structure: bool) -> void:
	if not is_instance_valid(modal): return
	if not session.can_edit():
		_catalog_open=false
		if radial.visible: _close_radial(false)
	session.catalog_open=_catalog_open or radial.visible
	shade.visible=session.paused or session.result_open or session.sim.game_over or _reset_pending or session.save_blocked or (_welcome and not session.sim._has_core() and session.selected.x<0)
	var editable:=session.can_edit() and not shade.visible
	catalog.visible=_catalog_open and editable; catalog.refresh(session)
	selection.visible=editable and not catalog.visible and not radial.visible and session.selected.x>=0
	if selection.visible: selection.refresh()
	utilities.visible=not shade.visible and not catalog.visible and not selection.visible and not radial.visible
	catalog_button.visible=not session.raid.raid_active; undo_button.visible=not session.raid.raid_active
	undo_button.disabled=not session.can_undo(); catalog_button.disabled=not editable or not session.sim._has_core()
	speeds.visible=session.raid.raid_active and not shade.visible
	for i in speed_buttons.size(): speed_buttons[i].set_pressed_no_signal(session.raid_speed==i+1)
	if shade.visible:
		_refresh_modal()
		if not session.save_error.is_empty() and not modal_text.text.contains(session.save_error): modal_text.text+="\n\n"+session.save_error
		modal_raid.visible=session.paused and not _reset_pending and not session.result_open and not session.sim.game_over and not session.save_blocked
		modal_raid.disabled=not session.ready_for_raid()
	_refresh_live(); _queue_layout()

func _refresh_live() -> void:
	if not is_instance_valid(header): return
	_update_eye_target()
	header.refresh(session)
	var armed:=session.tool!=Types.Tool.NONE
	var message:=""
	if not session.sim._has_core(): message="Touchez une case pour ancrer le cœur."
	elif armed:
		var item:=Catalog.definition(session.tool)
		message="%s · %s\nTouchez les cases pour poser." % [item[1],item[2]]
	if not session.notice in DEFAULT_NOTICES: message=Notices.french(session.notice)
	if not session.save_error.is_empty(): message=session.save_error
	pose_label.text=message; stop_button.visible=armed
	pose_bar.visible=not shade.visible and not catalog.visible and not selection.visible and not radial.visible and not session.raid.raid_active and (armed or not message.is_empty())
	if session.sim.gold<_last_gold and not session.raid.raid_active and not shade.visible: _float_notice("−%d or" % (_last_gold-session.sim.gold),Color("e1bf72"))
	if session.sim.core_hp<_last_hp and not shade.visible: _float_notice("−%d %%" % (_last_hp-session.sim.core_hp),Color("e78392"))
	_last_gold=session.sim.gold; _last_hp=session.sim.core_hp
	hint.visible=not shade.visible and not pose_bar.visible and not catalog.visible and not selection.visible and not radial.visible
	if session.get_node("PlayArea/World/Dungeon").access_visible:
		hint.text="Accès possibles depuis l’entrée · le héros choisit son trajet."
	elif session.raid.raid_active:
		hint.text="Raid en cours · Glissez pour explorer"
	else:
		hint.text="Touchez une case pour bâtir · Glissez pour explorer"

func _float_notice(text: String, color: Color) -> void:
	var label:=UI.label(root,text,19,color)
	label.set_meta("transient_feedback",true)
	label.position=Vector2(_safe.get_center().x-38,header.position.y+100)
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(label,"position:y",label.position.y+25,.9)
	tween.tween_property(label,"modulate:a",0,.9).set_delay(.25)
	tween.chain().tween_callback(label.queue_free)

func cancel_pointer() -> void:
	# Drop pending presses without changing selected toggles or disabled actions.
	radial.cancel_pointer()
	for button: BaseButton in root.find_children("*","BaseButton",true,false):
		if not button.disabled:
			button.disabled=true
			button.disabled=false

func _queue_layout() -> void:
	if _layout_queued: return
	_layout_queued=true; call_deferred("_layout")

func _layout() -> void:
	_layout_queued=false
	var viewport_size:=get_viewport().get_visible_rect().size
	var window_size:=Vector2(get_window().size)
	if viewport_size.x<=0 or window_size.x<=0: return
	var density:=clampf(DisplayServer.screen_get_dpi()/160.0,1,4) if OS.has_feature("mobile") else 1.0
	var factor:=viewport_size.x/window_size.x*density
	scale=Vector2.ONE*factor; root.size=viewport_size/factor; _safe=Rect2(Vector2.ZERO,root.size)
	if OS.has_feature("mobile"):
		var pixels:=Rect2(DisplayServer.get_display_safe_area()).intersection(Rect2(Vector2(get_window().position),window_size))
		if pixels.has_area(): _safe=Rect2((pixels.position-Vector2(get_window().position))/density,pixels.size/density)
	_world_rect=Rect2(Vector2.ZERO,viewport_size)
	var play: Control=session.get_node("PlayArea"); play.position=Vector2.ZERO; play.size=viewport_size
	mode="portrait" if _safe.size.y>_safe.size.x else "landscape"
	header.size=Vector2(minf(_safe.size.x-12,760),84 if _safe.size.y<352 else 96); header.position=Vector2(_safe.get_center().x-header.size.x/2,_safe.position.y)
	utilities.reset_size(); utilities.position=Vector2(_safe.end.x-utilities.size.x-10,_safe.end.y-utilities.size.y-10)
	speeds.position=Vector2(_safe.position.x+10,_safe.end.y-58)
	var pose_width:=minf(_safe.size.x-20,390) if mode=="portrait" else minf(_safe.size.x-utilities.size.x-30,390)
	pose_bar.position=Vector2(_safe.get_center().x-pose_width/2,_safe.end.y-utilities.size.y-90) if mode=="portrait" else Vector2(_safe.position.x+10,_safe.end.y-80)
	pose_bar.size=Vector2(pose_width,70)
	hint.position=Vector2(_safe.position.x+8,_safe.end.y-utilities.size.y-50); hint.size=Vector2(_safe.size.x-16,32)
	if mode=="landscape":
		var speed_space:=speeds.size.x+12 if speeds.visible else 0.0
		hint.position=Vector2(_safe.position.x+10+speed_space,_safe.end.y-48)
		hint.size=Vector2(_safe.size.x-utilities.size.x-speed_space-30,32)
	var sheet_width:=minf(_safe.size.x-16,386)
	var sheet_height:=minf(_safe.size.y-112,520) if mode=="landscape" else minf(_safe.size.y*.60,_safe.size.y-112)
	catalog.fit_width(sheet_width)
	if catalog.visible: sheet_height=minf(sheet_height,catalog.preferred_height())
	var sheet:=Rect2(Vector2(_safe.end.x-sheet_width-8,_safe.end.y-sheet_height-8),Vector2(sheet_width,sheet_height))
	if mode=="portrait": sheet.position.x=_safe.get_center().x-sheet_width/2
	catalog.fit_width(sheet.size.x); catalog.position=sheet.position; catalog.size=sheet.size
	selection.position=sheet.position; selection.fit_width(sheet.size.x,sheet.size.y); selection.size=sheet.size
	shade.position=Vector2.ZERO; shade.size=root.size
	var modal_size:=Vector2(minf(_safe.size.x-24,430),minf(_safe.size.y-112,460))
	modal.position=Vector2(_safe.get_center().x-modal_size.x/2,_safe.end.y-modal_size.y-12); modal.size=modal_size
	modal_scroll.get_child(0).custom_minimum_size.x=modal_size.x-32
	radial_shield.position=Vector2.ZERO; radial_shield.size=root.size; _position_radial(false)

func _build_modal() -> void:
	shade = ColorRect.new()
	shade.color = Color.TRANSPARENT
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(shade)
	modal = _panel(shade)
	modal_scroll = ScrollContainer.new()
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	modal.add_child(modal_scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	modal_scroll.add_child(box)
	modal_title = UI.label(box, "", 24, UI.GOLD)
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_stats=HBoxContainer.new(); box.add_child(result_stats)
	for caption in ["vaincus","butin au sol","cœur"]:
		var card:=_panel(result_stats); card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",UI.command_surface(false,8))
		var content:=VBoxContainer.new(); card.add_child(content)
		var value:=UI.label(content,"0",22,UI.GOLD); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var label:=UI.label(content,caption,11); label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		result_values.append(value)
	result_stats.hide()
	modal_text = UI.label(box, "", 16)
	modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_resume = UI.button(box, "Reprendre", _resume, "", true)
	modal_new = UI.button(box, "Nouveau donjon…", func(): _request_reset(false))
	modal_demo = UI.button(box, "Donjon d’essai…", func(): _request_reset(true))
	shade.hide()


func _refresh_modal() -> void:
	modal_resume.show(); modal_new.show(); modal_demo.show()
	result_stats.hide()
	modal_new.text = "Nouveau donjon…"
	modal_demo.text = "Donjon d’essai…"
	if _reset_pending:
		modal_title.text = "REMPLACER CE DONJON ?"
		modal_text.text = "Le plan, l’or et les visiteurs seront réinitialisés. L’expérience du cœur est conservée."
		modal_resume.text = "Confirmer le remplacement"
		modal_new.text = "Annuler"
		modal_demo.hide()
	elif session.save_blocked:
		modal_title.text = "SAUVEGARDE ILLISIBLE"
		modal_text.text = session.save_error
		modal_resume.hide()
	elif session.result_open or session.sim.game_over:
		var result: Dictionary = session.raid.last_result
		modal_title.text = "LE CŒUR EST TOMBÉ" if session.sim.game_over else "FESTIN" if result.get("killed",0)>0 else "RAID TERMINÉ"
		result_stats.show()
		result_values[0].text=str(result.get("killed",0))
		result_values[1].text=str(session.sim._unsecured_loot_total())
		result_values[2].text="%d %%" % session.sim.core_hp
		modal_text.text = "%s · %d sorti\n%d or volé · +%d XP\n%d défense(s) à réparer" % [result.get("hero_name", ""),result.get("escaped",0),result.get("stolen",0),session.last_reward.get("xp",0),session.sim._damaged_structure_count()]
		modal_resume.text = "RETOUR AU DONJON"
		modal_resume.visible = not session.sim.game_over
	elif session.paused:
		modal_title.text = "VOTRE DOMAINE"
		modal_text.text = "Cœur · Niveau %d" % session.progression.level()
		if session.raid.raid_active and not session.raid.hero.is_empty(): modal_text.text+="\nProie : %s" % session.raid.hero.get("name","Visiteur")
		modal_resume.text = "REPRENDRE"
	else:
		modal_title.text = "VOTRE DONJON"
		modal_text.text = "Ancrez le cœur, creusez votre domaine et tendez vos pièges."
		modal_resume.text = "PLACER MON CŒUR"
		modal_new.hide()

func _request_reset(prepared: bool) -> void:
	if _reset_pending and not prepared:
		_reset_pending = false
		session.confirmation_open = false
		_refresh(false)
		return
	_reset_pending = true
	_reset_prepared = prepared
	session.confirmation_open = true
	session.set_paused(true)

func _resume() -> void:
	if _reset_pending:
		_reset_pending = false
		_welcome = false
		_catalog_open = false
		session.restart(_reset_prepared)
	elif session.result_open: session.continue_preparation()
	elif session.paused: session.set_paused(false)
	else:
		_welcome = false
		_refresh(false)
