extends CanvasLayer

const UI=preload("res://scripts/game/ui/hud_theme.gd")
const StoneBand=preload("res://scripts/game/ui/intro_stone_band.gd")
const Catalog=preload("res://scripts/game/ui/hud_catalog.gd")
const BuildMenu=preload("res://scripts/game/ui/hud_build_radial.gd")
const Selection=preload("res://scripts/game/ui/hud_selection.gd")
const Header=preload("res://scripts/game/ui/hud_master_header.gd")
const DigTargets=preload("res://scripts/game/ui/hud_dig_blocks.gd")
const Types=preload("res://scripts/game/game_types.gd")
var session: IsometricGameSession
var root: Control
var dig_targets: Control
var header: Control
var footer: Control
var utilities: HBoxContainer
var dig_button: Button
var build_buttons: Dictionary[int, Button] = {}
var build_menu: BuildMenu
var speeds: HBoxContainer
var speed_buttons: Array[Button]=[]
var pose_bar: PanelContainer
var pose_label: Label
var stop_button: Button
var hint: Label
var catalog: PanelContainer
var selection: PanelContainer
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
	dig_targets=DigTargets.new(); dig_targets.hud=self; root.add_child(dig_targets)
	header=Header.new(); root.add_child(header); header.menu_requested.connect(_open_menu)
	footer=Control.new()
	footer.draw.connect(_draw_footer)
	footer.mouse_filter=Control.MOUSE_FILTER_STOP
	root.add_child(footer)
	utilities=HBoxContainer.new(); root.add_child(utilities)
	utilities.add_theme_constant_override("separation",0)
	dig_button=UI.tile(utilities,BuildMenu.TOOL_ICONS[Types.Tool.DIG],tr("Dig"),_toggle_dig)
	dig_button.accessibility_name=tr("Dig")
	dig_button.tooltip_text=tr("Toggle digging · %d gold per tile") % Types.COST_DIG
	for group: int in [Catalog.DOORS, Catalog.TRAPS, Catalog.CHESTS]:
		var button := UI.tile(utilities,BuildMenu.family_icon(group),tr(Catalog.GROUPS[group]),_toggle_group.bind(group))
		build_buttons[group]=button
	speeds=HBoxContainer.new(); root.add_child(speeds)
	for value in [1,2]:
		var button:=UI.button(speeds,"%d×" % value,func(): session.raid_speed=value; _refresh(false))
		button.toggle_mode=true; button.custom_minimum_size=Vector2(52,48); speed_buttons.append(button)
	pose_bar=_panel(root); pose_bar.name="PlacementBar"
	var placement_style:=StyleBoxEmpty.new()
	placement_style.content_margin_left=10
	placement_style.content_margin_right=6
	pose_bar.add_theme_stylebox_override("panel",placement_style)
	pose_bar.visibility_changed.connect(footer.queue_redraw)
	var pose_box:=HBoxContainer.new(); pose_bar.add_child(pose_box)
	pose_label=UI.label(pose_box,"",13); pose_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	pose_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	pose_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stop_button=UI.button(pose_box,tr("Stop"),_stop_placing,"cross")
	stop_button.add_theme_font_size_override("font_size",12); stop_button.add_theme_constant_override("icon_max_width",16)
	UI.strip_action(stop_button)
	stop_button.custom_minimum_size=Vector2(76,48)
	# Wrapped text/container minima settle after a viewport or width change.
	# Refit then, rather than retaining a transient oversized panel until a tap.
	pose_bar.minimum_size_changed.connect(_queue_layout)
	hint=UI.label(root,"",12,UI.MUTED); hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint.minimum_size_changed.connect(_queue_layout)
	catalog=Catalog.new(); root.add_child(catalog)
	catalog.tool_chosen.connect(_choose_tool); catalog.closed.connect(_close_catalog)
	catalog.minimum_size_changed.connect(_queue_layout)
	catalog.row.minimum_size_changed.connect(_queue_layout)
	for card in catalog.cards: card.button.gui_input.connect(func(event): session.get_node("Input").palette_event(card.button,card.id,event))
	selection=Selection.new(); selection.session=session; root.add_child(selection)
	selection.dismissed.connect(session.cancel_selection); selection.layout_changed.connect(_queue_layout)
	build_menu=BuildMenu.new()
	build_menu.hud_buttons.assign(utilities.get_children())
	build_menu.hud_buttons.append(header.eye_button)
	root.add_child(build_menu)
	build_menu.tool_chosen.connect(_choose_build_tool)
	build_menu.closed.connect(_close_build_menu)
	build_menu.visibility_changed.connect(footer.queue_redraw)
	_build_modal()
	modal_raid=UI.button(modal_scroll.get_child(0),tr("Start raid"),_launch_raid,"",true)
	modal_raid.get_parent().move_child(modal_raid,modal_resume.get_index()+1)
	modal_scroll.get_child(0).minimum_size_changed.connect(_queue_layout)
	session.changed.connect(_refresh); session.frame_updated.connect(_tick)
	get_viewport().size_changed.connect(_queue_layout)
	_last_gold=session.sim.gold; _queue_layout()

func _panel(parent: Node) -> PanelContainer:
	var panel:=PanelContainer.new(); panel.mouse_filter=Control.MOUSE_FILTER_STOP
	parent.add_child(panel); return panel

func world_tapped(cell: Vector2i, world_point: Vector2 = Vector2.INF) -> void:
	if build_menu.visible: _close_build_menu(); return
	if not session.can_edit() or not session.sim._inside(cell) or shade.visible: return
	if _catalog_open: _close_catalog(); return
	if selection.visible and selection.removal_pending: session.cancel_selection(); return
	if session.selected.x>=0 and session.tool==Types.Tool.NONE: session.cancel_selection()
	var tile: int=session.sim.grid[cell.y][cell.x]
	if session.tool!=Types.Tool.NONE or not session.sim._has_core():
		var view = session.get_node("PlayArea/World/Dungeon")
		if world_point.is_finite():
			if session.tool==Types.Tool.DIG and view.solid_covers_point(world_point): return
			if view.build_site_icon and tile==Types.Tile.FLOOR and cell in view._valid_cells and view.solid_covers_point(world_point): return
		session.activate_cell(cell)
		return
	if tile not in [Types.Tile.ROCK,Types.Tile.FLOOR] or session.sim.floor_gold.has(cell) or session.sim.loot_bags.any(func(b): return b.pos==cell and b.gold>0) or session.sim.corpses.any(func(c): return c.pos==cell):
		session.select_cell(cell)

func _toggle_dig() -> void:
	if session.tool==Types.Tool.DIG:
		_stop_placing()
	else:
		_choose_tool(Types.Tool.DIG)

func _stop_placing() -> void:
	session.notice=""; session.cancel_selection()

func _open_menu() -> void:
	if session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked: return
	build_menu.hide()
	_catalog_open=false; session.catalog_open=false; session.set_paused(true)

func _toggle_group(group: int) -> void:
	if build_buttons[group].disabled or not utilities.visible: return
	if build_menu.visible and build_menu.category==group:
		_close_build_menu()
		return
	var items:=Catalog.unlocked_items(group,session.progression)
	if items.size()==1:
		var tool: int=items[0][0]
		if build_menu.visible: _close_build_menu()
		if session.tool==tool: _stop_placing()
		else: _choose_build_tool(tool)
	elif items.size()>1:
		_catalog_open=false
		session.catalog_open=true
		build_menu.open(session,group,items)
		_layout_build_menu()
		session.notice=""
		session.cancel_selection()

func _close_build_menu() -> void:
	if not build_menu.visible: return
	var restore_focus:=build_menu.has_focus()
	build_menu.hide()
	session.catalog_open=false
	session.notice=""
	_refresh(false)
	if restore_focus: build_buttons[build_menu.category].grab_focus()

func _open_catalog(category: int=0) -> void:
	if not session.can_edit(): return
	build_menu.hide()
	catalog._choose_category(category)
	_catalog_open=true; session.catalog_open=true; session.cancel_selection()

func _close_catalog() -> void:
	_catalog_open=false; session.catalog_open=false; _refresh(false)

func _choose_build_tool(tool: int) -> void:
	var cost:=BuildMenu.minimum_cost(session,tool)
	if session.sim.gold < cost:
		session.notice=tr("You need %d more gold (%d / %d).") % [cost-session.sim.gold,session.sim.gold,cost]
		session.presentation_event.emit("fauche")
		session.cancel_selection()
		return
	_choose_tool(tool)

func _choose_tool(tool: int) -> void:
	if not session.can_edit() or not session.progression.allows(tool): return
	if build_menu.has_focus(): build_buttons[build_menu.category].grab_focus()
	build_menu.hide()
	_catalog_open=false; session.catalog_open=false; session.notice=""; session.choose_tool(tool)

func _toggle_path() -> void:
	var view=session.get_node("PlayArea/World/Dungeon")
	view.access_visible=not view.access_visible; view.queue_redraw()
	_refresh_live()

func _launch_raid() -> void:
	if not session.ready_for_raid() or session.confirmation_open or session.result_open or session.save_blocked: return
	session.set_paused(false); session.start_raid()

func handle_back() -> void:
	if _reset_pending or session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked: return
	if session.paused: session.set_paused(false)
	elif build_menu.visible: _close_build_menu()
	elif _catalog_open: _close_catalog()
	elif session.selected.x>=0 or session.tool!=Types.Tool.NONE: session.cancel_selection()
	else: _open_menu()

func blocks_pointer(point: Vector2) -> bool:
	if shade.visible: return true
	var logical:=point/scale.x
	if not _safe.has_point(logical): return true
	if not visible: return false
	if build_menu.visible: return true
	for control in [header,footer,speeds,pose_bar,catalog,selection]:
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
	shade.visible=session.paused or session.result_open or session.sim.game_over or _reset_pending or session.save_blocked or (_welcome and not session.sim._has_core() and session.selected.x<0)
	var editable:=session.can_edit() and not shade.visible and session.sim.lesson==Types.Lesson.FREE
	if build_menu.visible:
		var items:=Catalog.unlocked_items(build_menu.category,session.progression)
		if editable and session.catalog_open and items.size()>1: build_menu.set_choices(items)
		else: build_menu.hide()
	session.catalog_open=_catalog_open or build_menu.visible
	catalog.visible=_catalog_open and editable; catalog.refresh(session)
	selection.visible=editable and not catalog.visible and session.selected.x>=0
	session.get_node("PlayArea/World/Dungeon").dig_guides_visible=editable and not session.catalog_open and session.selected.x<0 and session.tool==Types.Tool.DIG
	if selection.visible: selection.refresh()
	utilities.visible=not session.raid.raid_active and not shade.visible and not catalog.visible and not selection.visible
	footer.visible=utilities.visible
	dig_button.visible=not session.raid.raid_active
	dig_button.disabled=not editable or not session.sim._has_core() or not session.progression.allows(Types.Tool.DIG)
	dig_button.modulate=UI.MUTED.darkened(.32) if dig_button.disabled else Color.WHITE
	dig_button.set_pressed_no_signal(not dig_button.disabled and session.tool==Types.Tool.DIG)
	for group: int in build_buttons:
		_refresh_build_button(group,editable)
	speeds.visible=session.raid.raid_active and not shade.visible
	for i in speed_buttons.size(): speed_buttons[i].set_pressed_no_signal(session.raid_speed==i+1)
	if shade.visible:
		_refresh_modal()
		if not session.save_error.is_empty() and not modal_text.text.contains(session.save_error): modal_text.text+="\n\n"+session.save_error
		modal_raid.visible=session.paused and not _reset_pending and not session.result_open and not session.sim.game_over and not session.save_blocked
		modal_raid.disabled=not session.ready_for_raid()
	_refresh_live(); _queue_layout()

func _refresh_build_button(group: int, editable: bool) -> void:
	var button:=build_buttons[group]
	var items:=Catalog.unlocked_items(group,session.progression)
	var words: Label=button.get_meta("words")
	var mark: TextureRect=button.get_meta("mark")
	var armed: bool=Catalog.definition(session.tool)[4]==group
	button.visible=not session.raid.raid_active and not items.is_empty()
	button.disabled=not editable or not session.sim._has_core() or items.is_empty()
	var affordable:=true
	if items.size()==1:
		var item:=items[0]
		words.text=tr("Iron") if item[0]==Types.Tool.BUILD_REINFORCED_DOOR else BuildMenu.item_name(item)
		mark.texture=BuildMenu.item_icon(item)
		button.tooltip_text=tr("%s · %s") % [tr(item[1]),Catalog.price_text(item)]
		affordable=armed or session.sim.gold>=BuildMenu.minimum_cost(session,item[0])
	else:
		words.text=tr(Catalog.GROUPS[group])
		mark.texture=BuildMenu.family_icon(group)
		button.tooltip_text=tr("Choose a door") if group==Catalog.DOORS else tr("Choose a trap") if group==Catalog.TRAPS else tr("Choose a storage option")
	button.accessibility_name=button.tooltip_text
	button.set_pressed_no_signal(not button.disabled and (armed or (build_menu.visible and build_menu.category==group)))
	button.modulate=UI.MUTED.darkened(.32) if button.disabled or not affordable else Color.WHITE

func _refresh_live() -> void:
	if not is_instance_valid(header): return
	_update_eye_target()
	header.refresh(session)
	var armed:=session.tool not in [Types.Tool.NONE,Types.Tool.DIG]
	var message:=""
	if not session.sim._has_core(): message=tr("Tap a tile to anchor the Core.")
	elif armed:
		var item:=Catalog.definition(session.tool)
		message=tr("%s · %s\nTap tiles to place.") % [tr(item[1]),Catalog.price_text(item)]
	if not session.notice.is_empty() and session.notice not in [tr("Action complete."), tr("Building"), tr("Dungeon restored. Preparation resumes.")]:
		message=session.notice
	if not session.save_error.is_empty(): message=session.save_error
	pose_label.text=message; stop_button.visible=armed
	pose_bar.visible=not shade.visible and not session.catalog_open and not selection.visible and not session.raid.raid_active and (armed or not message.is_empty())
	if session.sim.gold<_last_gold and not session.raid.raid_active and not shade.visible: _float_notice(tr("−%d gold") % (_last_gold-session.sim.gold),Color("e1bf72"))
	if session.sim.core_hp<_last_hp and not shade.visible: _float_notice("−%d %%" % (_last_hp-session.sim.core_hp),Color("e78392"))
	_last_gold=session.sim.gold; _last_hp=session.sim.core_hp
	hint.visible=not shade.visible and not pose_bar.visible and not session.catalog_open and not selection.visible
	if build_menu.visible and not session.notice.is_empty():
		hint.visible=true
		hint.text=session.notice
	elif session.tool==Types.Tool.DIG:
		hint.text=tr("Tap a pickaxe to dig · %d gold per tile") % Types.COST_DIG
	elif session.get_node("PlayArea/World/Dungeon").access_visible:
		hint.text=tr("Paths from the entrance · the hero chooses a route.")
	elif session.raid.raid_active:
		hint.text=tr("Raid in progress · Drag to explore")
	else:
		hint.text=tr("Choose a tool to build or dig")

func _float_notice(text: String, color: Color) -> void:
	var label:=UI.label(root,text,19,color)
	label.set_meta("transient_feedback",true)
	label.position=Vector2(_safe.get_center().x-38,header.position.y+100)
	var tween:=create_tween().set_parallel(true)
	tween.tween_property(label,"position:y",label.position.y+25,.9)
	tween.tween_property(label,"modulate:a",0,.9).set_delay(.25)
	tween.chain().tween_callback(label.queue_free)

func cancel_pointer() -> void:
	dig_targets.cancel_press()
	build_menu.cancel_pointer()
	# Drop pending presses without changing selected toggles or disabled actions.
	for button: BaseButton in root.find_children("*","BaseButton",true,false):
		if not button.disabled:
			button.disabled=true
			button.disabled=false

func _queue_layout() -> void:
	if _layout_queued: return
	_layout_queued=true; call_deferred("_layout")

func _layout() -> void:
	_layout_queued=false
	if not is_inside_tree(): return
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
	var compact:=mode=="portrait" or _safe.size.x<450
	var tab_height:=54 if compact else 48
	for button in utilities.get_children():
		var mark: TextureRect=button.get_meta("mark")
		var words: Label=button.get_meta("words")
		var box:=mark.get_parent() as BoxContainer
		box.vertical=compact
		box.add_theme_constant_override("separation",0 if compact else 7)
		mark.custom_minimum_size=Vector2.ONE*(25 if compact else 29)
		words.add_theme_font_size_override("font_size",13 if compact else 15)
	var bar_width:=minf(660,_safe.size.x)
	footer.position=Vector2(0,_safe.end.y-tab_height)
	footer.size=Vector2(root.size.x,root.size.y-footer.position.y)
	utilities.position=Vector2(roundf(_safe.get_center().x-bar_width/2),footer.position.y)
	utilities.size=Vector2(bar_width,tab_height)
	_layout_build_menu()
	speeds.position=Vector2(_safe.position.x+10,_safe.end.y-58)
	var pose_width:=minf(_safe.size.x-16,390)
	pose_bar.size=Vector2(pose_width,pose_bar.get_combined_minimum_size().y)
	pose_bar.position=Vector2(_safe.get_center().x-pose_width/2,footer.position.y-pose_bar.size.y)
	hint.size=Vector2(_safe.size.x-16,32)
	hint.position=Vector2(_safe.position.x+8,footer.position.y-hint.size.y-3)
	if build_menu.visible: hint.position.y-=build_menu.shelf.size.y
	if speeds.visible:
		hint.position=Vector2(speeds.position.x+speeds.size.x+8,_safe.end.y-48)
		hint.size.x=_safe.end.x-hint.position.x-8
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

func _draw_footer() -> void:
	var base:=Rect2(Vector2.ZERO,footer.size)
	var cap:=Rect2()
	if is_instance_valid(build_menu) and build_menu.visible and not build_menu.cards.is_empty():
		cap=build_menu.shelf
	elif is_instance_valid(pose_bar) and pose_bar.visible:
		cap=pose_bar.get_rect()
	var areas:Array[Rect2]=[base]
	if cap.has_area():
		cap.position-=footer.position
		areas.append(cap)
	var paint_size:=Vector2(StoneBand.STONE.get_size())
	# Both rows reveal adjacent parts of a single, proportionally scaled painting.
	var upper_height:=maxf(BuildMenu.SHELF_HEIGHT,cap.size.y)
	var zoom:=maxf(1.0,maxf(base.size.x/paint_size.x,(base.size.y+upper_height)/paint_size.y))
	var uv_origin:=paint_size/2 - Vector2(base.size.x/2,(base.size.y-upper_height)/2)/zoom
	for area in areas:
		var source:=Rect2(uv_origin+area.position/zoom,area.size/zoom)
		footer.draw_texture_rect_region(StoneBand.STONE,area,source)
		footer.draw_rect(Rect2(area.position,Vector2(area.size.x,1)),Color("4c72a1"))

func _layout_build_menu() -> void:
	if build_menu.visible:
		build_menu.fit(_safe,footer.position.y)
	footer.queue_redraw()

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
	modal_title = UI.label(box, "", 24, UI.TEXT)
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_stats=HBoxContainer.new(); box.add_child(result_stats)
	for caption in [tr("defeated"),tr("dropped loot"),tr("Core")]:
		var card:=_panel(result_stats); card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",UI.surface("panel",8))
		var content:=VBoxContainer.new(); card.add_child(content)
		var value:=UI.label(content,"0",22,UI.TEXT); value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var label:=UI.label(content,caption,11); label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		result_values.append(value)
	result_stats.hide()
	modal_text = UI.label(box, "", 16)
	modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_resume = UI.button(box, tr("Resume"), _resume, "", true)
	modal_new = UI.button(box, tr("New dungeon…"), func(): _request_reset(false))
	modal_demo = UI.button(box, tr("Demo dungeon…"), func(): _request_reset(true))
	shade.hide()


func _refresh_modal() -> void:
	modal_resume.show(); modal_new.show(); modal_demo.show()
	result_stats.hide()
	modal_new.text = tr("New dungeon…")
	modal_demo.text = tr("Demo dungeon…")
	if _reset_pending:
		modal_title.text = tr("REPLACE THIS DUNGEON?")
		modal_text.text = tr("The layout, gold and visitors will be reset. Core experience is kept.")
		modal_resume.text = tr("Confirm replacement")
		modal_new.text = tr("Cancel")
		modal_demo.hide()
	elif session.save_blocked:
		modal_title.text = tr("UNREADABLE SAVE")
		modal_text.text = session.save_error
		modal_resume.hide()
	elif session.result_open or session.sim.game_over:
		var result: Dictionary = session.raid.last_result
		modal_title.text = tr("THE CORE HAS FALLEN") if session.sim.game_over else tr("FEAST") if result.get("killed",0)>0 else tr("RAID COMPLETE")
		result_stats.show()
		result_values[0].text=str(result.get("killed",0))
		result_values[1].text=str(session.sim._unsecured_loot_total())
		result_values[2].text="%d %%" % session.sim.core_hp
		modal_text.text = tr("%s · %d escaped\n%d gold stolen · +%d XP\nDefenses to repair: %d") % [result.get("hero_name", ""),result.get("escaped",0),result.get("stolen",0),session.last_reward.get("xp",0),session.sim._damaged_structure_count()]
		modal_resume.text = tr("BACK TO DUNGEON")
		modal_resume.visible = not session.sim.game_over
	elif session.paused:
		modal_title.text = tr("YOUR DOMAIN")
		modal_text.text = tr("Core · Level %d") % session.progression.level()
		if session.raid.raid_active and not session.raid.hero.is_empty(): modal_text.text+="\n"+tr("Intruder: %s") % session.raid.hero.get("name",tr("Visitor"))
		modal_resume.text = tr("RESUME")
	else:
		modal_title.text = tr("YOUR DUNGEON")
		modal_text.text = tr("Anchor the Core, dig out your domain and set your traps.")
		modal_resume.text = tr("PLACE MY CORE")
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
		session.restart(_reset_prepared, not _reset_prepared)
	elif session.result_open: session.continue_preparation()
	elif session.paused: session.set_paused(false)
	else:
		_welcome = false
		_refresh(false)
