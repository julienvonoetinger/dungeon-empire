extends CanvasLayer

const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Catalog = preload("res://scripts/game/ui/hud_catalog.gd")
const Selection = preload("res://scripts/game/ui/hud_selection.gd")
const Types = preload("res://scripts/game/game_types.gd")
const RockBackdrop = preload("res://scripts/game/ui/hud_rock_backdrop.gd")
const Notices = preload("res://scripts/game/ui/hud_notices.gd")
## Landscape keeps one 136-unit column only when the four families, the
## placement bar and the actions all fit; otherwise the wide rail is used.
const COLUMN_HEIGHT := 600.0
const WIDE_WIDTH := 252.0
const ROW_HEIGHT := 58.0
const POSE_SLOT := 64.0
const DOCK_ACTIONS := 76.0
const DEFAULT_NOTICES := ["","Action effectuée.","Aménagement"]
var session: IsometricGameSession
var root: Control
var backdrop: MeshInstance2D
var rail: PanelContainer
var compact: VBoxContainer
var body: BoxContainer
var actions: BoxContainer
var tools_scroll: ScrollContainer
var families: GridContainer
var peek: BoxContainer
var observe_button: Button
var treasury: Button
var resource_rows: GridContainer
var gold_value: Label
var heart_value: Label
var clock_value: Label
var clock_title: Label
var clock_state: Label
var clock_panel: Button
var pause_button: Button
var center_button: Button
var undo_button: Button
var pose_bar: PanelContainer
var pose_box: BoxContainer
var pose_label: Label
var stop_button: Button
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
var mode := "column"
var _catalog_open := false
var _observe := false
var _welcome := true
var _reset_pending := false
var _reset_prepared := false
var _elapsed := 0.0
var _safe := Rect2()
var _world_rect := Rect2()
var _layout_queued := false
var _family_buttons: Array[Button] = []
var _family_rows: Array[HBoxContainer] = []
var _family_pictures: Array[TextureRect] = []
var _family_titles: Array[Label] = []
var _family_notes: Array[Label] = []
var _compact_clock := false

func _ready() -> void:
	session = get_parent() as IsometricGameSession
	root = Control.new()
	root.name = "ForgeHUD"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.create()
	add_child(root)
	backdrop=RockBackdrop.new(); backdrop.hud=self; root.add_child(backdrop)
	rail = _panel(root)
	var background := UI.surface("panel",8)
	rail.add_theme_stylebox_override("panel",background)
	compact = VBoxContainer.new(); rail.add_child(compact)
	tools_scroll=ScrollContainer.new(); compact.add_child(tools_scroll)
	tools_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tools_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	tools_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	UI.slim_scrollbar(tools_scroll)
	# Families and actions: stacked in landscape, side by side in the portrait dock.
	body=BoxContainer.new(); body.vertical=true; tools_scroll.add_child(body)
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",4)
	families=GridContainer.new(); body.add_child(families)
	families.columns=1
	families.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	families.add_theme_constant_override("h_separation",4)
	families.add_theme_constant_override("v_separation",4)
	_build_families()
	actions=BoxContainer.new(); body.add_child(actions)
	actions.add_theme_constant_override("separation",4)
	# Stable, labelled actions: each keeps one meaning in every state.
	undo_button=UI.tile(actions,"undo","Annuler",session.undo_build)
	observe_button=UI.tile(actions,"eye","Observer",_show_world)
	for button in [undo_button,observe_button]:
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	# Repeated placement gets its own bar in a reserved slot above the families:
	# arming a tool never resizes the dungeon view.
	pose_bar=_panel(root)
	pose_bar.name="PlacementBar"
	pose_bar.add_theme_stylebox_override("panel",UI.surface("selected",8))
	pose_box=BoxContainer.new(); pose_bar.add_child(pose_box)
	pose_box.add_theme_constant_override("separation",6)
	pose_label=UI.label(pose_box,"",11)
	pose_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	pose_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	pose_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	pose_label.max_lines_visible=2
	pose_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	stop_button=UI.button(pose_box,"Arrêter",_stop_placing,"cross")
	stop_button.tooltip_text="Arrêter la pose"
	stop_button.custom_minimum_size=Vector2(98,48)
	stop_button.add_theme_font_size_override("font_size",12)
	stop_button.add_theme_constant_override("icon_max_width",20)
	stop_button.add_theme_constant_override("h_separation",6)
	pose_bar.hide()
	treasury = UI.button(root,"",_open_menu)
	treasury.name="Resources"
	resource_rows=GridContainer.new(); treasury.add_child(resource_rows)
	resource_rows.columns=1
	resource_rows.mouse_filter=Control.MOUSE_FILTER_IGNORE
	resource_rows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resource_rows.offset_left=14; resource_rows.offset_right=-14; resource_rows.offset_top=12; resource_rows.offset_bottom=-12
	resource_rows.add_theme_constant_override("v_separation",2)
	resource_rows.add_theme_constant_override("h_separation",8)
	var gold_row := _icon_row(resource_rows,"coin")
	gold_value=UI.label(gold_row,"",18,Color("efd08e"))
	gold_value.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	var heart_row := _icon_row(resource_rows,"health")
	heart_row.alignment=BoxContainer.ALIGNMENT_END
	heart_value=UI.label(heart_row,"",18)
	heart_value.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	# Expand the columns so the two groups can reach opposite padded edges.
	for row in [gold_row,heart_row]:
		row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for value in [gold_value,heart_value]:
		value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	peek = BoxContainer.new(); peek.vertical=true; rail.add_child(peek)
	peek.add_theme_constant_override("separation",4)
	var edit := UI.tile(peek,"pick","Bâtir",_show_tools)
	center_button=UI.tile(peek,"target","Centrer",func(): session.get_node("Input").center_core())
	var spring := Control.new(); peek.add_child(spring)
	spring.size_flags_vertical=Control.SIZE_EXPAND_FILL; spring.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	pause_button=UI.tile(peek,"pause","Pause",_open_menu)
	for tile in [edit,center_button,pause_button]: tile.custom_minimum_size.x=56
	# Separate from every scrolling menu: the phase/time stays on screen.
	clock_panel=UI.button(root,"",_open_menu)
	clock_panel.name="RaidClock"
	var clock_contents := VBoxContainer.new(); clock_panel.add_child(clock_contents)
	clock_contents.mouse_filter=Control.MOUSE_FILTER_IGNORE
	clock_contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clock_contents.offset_left=10; clock_contents.offset_right=-10
	clock_contents.offset_top=12; clock_contents.offset_bottom=-12
	clock_contents.alignment=BoxContainer.ALIGNMENT_CENTER
	clock_contents.add_theme_constant_override("separation",0)
	clock_title=UI.label(clock_contents,"",10,UI.MUTED)
	clock_value=UI.label(clock_contents,"",22,Color("efd08e"))
	clock_state=UI.label(clock_contents,"",10,UI.MUTED)
	for label in [clock_title,clock_value,clock_state]:
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	catalog=Catalog.new(); root.add_child(catalog)
	catalog.tool_chosen.connect(_choose_tool); catalog.closed.connect(_close_catalog)
	for card in catalog.cards: _wire_palette(card.button,card.id)
	selection=Selection.new(); selection.session=session; root.add_child(selection)
	selection.dismissed.connect(session.cancel_selection)
	selection.layout_changed.connect(_queue_layout)
	_build_modal()
	modal_raid=UI.button(modal_scroll.get_child(0),"Lancer le raid",_launch_raid,"",true)
	modal_raid.get_parent().move_child(modal_raid,modal_resume.get_index()+1)
	for button in [modal_resume,modal_new,modal_demo,modal_raid]: button.add_theme_font_size_override("font_size",13)
	# Portrait sheets follow their content height.
	modal_scroll.get_child(0).minimum_size_changed.connect(_queue_layout)
	session.changed.connect(_refresh)
	session.frame_updated.connect(_tick)
	rail.minimum_size_changed.connect(_queue_layout)
	get_viewport().size_changed.connect(_queue_layout)
	_queue_layout()

func _panel(parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	parent.add_child(panel)
	return panel

func _icon_row(parent: Node, glyph: String) -> HBoxContainer:
	var row := HBoxContainer.new(); parent.add_child(row)
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",8)
	var picture := UI.picture(row,glyph,30)
	picture.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return row

func _build_families() -> void:
	for child in families.get_children(): families.remove_child(child); child.queue_free()
	_family_buttons.clear(); _family_rows.clear(); _family_pictures.clear(); _family_titles.clear(); _family_notes.clear()
	for index in Catalog.GROUPS.size():
		var button := UI.button(families,"",func(): _open_catalog(index))
		button.toggle_mode=true
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y=ROW_HEIGHT
		var row := _icon_row(button,Catalog.GROUP_ICONS[index])
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_top=12; row.offset_bottom=-12
		var words := VBoxContainer.new(); words.mouse_filter=Control.MOUSE_FILTER_IGNORE
		words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		words.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		words.add_theme_constant_override("separation",0); row.add_child(words)
		var title := UI.label(words,Catalog.GROUPS[index],13)
		title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		# While a variant is armed, the row names it and its cost.
		var note := UI.label(words,"",11,UI.GOLD)
		note.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		note.hide()
		button.tooltip_text=Catalog.GROUPS[index]
		_family_buttons.append(button)
		_family_rows.append(row)
		_family_pictures.append(row.get_child(0))
		_family_titles.append(title)
		_family_notes.append(note)

## Narrow grid cells keep a readable label by tightening icon and padding
## together, never by shrinking the 58-unit touch target.
func _fit_family_rows(cell_width: float) -> void:
	var tight := cell_width < 120
	for index in _family_rows.size():
		var row := _family_rows[index]
		row.offset_left=10 if tight else 14
		row.offset_right=-10 if tight else -14
		row.add_theme_constant_override("separation",6 if tight else 8)
		_family_pictures[index].custom_minimum_size=Vector2.ONE*(26 if tight else 30)

## Leaves repeated placement; a refusal shown for that tool is dismissed too.
func _stop_placing() -> void:
	if not session.notice in DEFAULT_NOTICES: session.notice=""
	session.cancel_selection()

func _wire_palette(button: Button, id: int) -> void:
	button.gui_input.connect(func(event): session.get_node("Input").palette_event(button,id,event))

func _open_menu() -> void:
	if session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked: return
	_catalog_open=false
	session.set_paused(true)

func _open_catalog(category: int = 0) -> void:
	if not session.can_edit(): return
	catalog._choose_category(category)
	_catalog_open=true
	_observe=false
	session.catalog_open=true
	session.cancel_selection()

func _close_catalog() -> void:
	_catalog_open=false
	session.catalog_open=false
	_refresh(false)

func _choose_tool(value: int) -> void:
	_catalog_open=false
	_observe=false
	session.catalog_open=false
	session.choose_tool(value)

func _show_world() -> void:
	_observe=true; _catalog_open=false; session.catalog_open=false
	session.cancel_selection()

func _show_tools() -> void:
	_observe=false
	_refresh(false)

func _launch_raid() -> void:
	if not session.ready_for_raid() or session.confirmation_open or session.result_open or session.save_blocked: return
	_observe=true
	session.set_paused(false)
	session.start_raid()

func handle_back() -> void:
	if _reset_pending or session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked: return
	if session.paused: session.set_paused(false)
	elif _catalog_open: _close_catalog()
	elif session.selected.x>=0 or session.tool!=Types.Tool.NONE: session.cancel_selection()
	elif not _observe: _show_world()
	else: _open_menu()

func blocks_pointer(viewport_position: Vector2) -> bool:
	if shade.visible: return true
	return not _world_rect.has_point(viewport_position)

func _tick() -> void:
	_elapsed+=get_process_delta_time()
	if _elapsed<.1: return
	_elapsed=0
	_refresh_live()

func _refresh(_structure: bool) -> void:
	if not is_instance_valid(modal): return
	if session.raid.raid_active or session.result_open or session.sim.game_over: _catalog_open=false
	session.catalog_open=_catalog_open
	var sim := session.sim
	shade.visible=session.paused or session.result_open or sim.game_over or _reset_pending or session.save_blocked or (_welcome and not sim._has_core() and session.selected.x<0)
	var editable := session.can_edit() and not shade.visible
	catalog.visible=_catalog_open and editable
	catalog.refresh(session)
	selection.visible=editable and not catalog.visible and session.selected.x>=0
	if selection.visible: selection.refresh()
	compact.visible=not shade.visible and not catalog.visible and not selection.visible and not _observe and not session.raid.raid_active
	peek.visible=not shade.visible and not catalog.visible and not selection.visible and not compact.visible
	treasury.visible=not peek.visible or mode=="dock"
	rail.visible=compact.visible or peek.visible
	undo_button.disabled=not session.can_undo()
	_dim_tile(undo_button)
	var armed := session.tool!=Types.Tool.NONE
	var item := Catalog.definition(session.tool)
	for index in _family_buttons.size():
		var button := _family_buttons[index]
		button.disabled=not editable or not sim._has_core()
		var active: bool=armed and item[4]==index
		button.set_pressed_no_signal(active)
		_family_pictures[index].texture=UI.icon(item[3] if active else Catalog.GROUP_ICONS[index])
		_family_titles[index].text=item[1] if active else Catalog.GROUPS[index]
		_family_notes[index].text=item[2] if active else ""
		_family_notes[index].visible=active
		button.tooltip_text="%s · pose répétée" % item[1] if active else Catalog.GROUPS[index]
	stop_button.visible=armed
	if shade.visible:
		_refresh_modal()
		modal_raid.visible=session.paused and not _reset_pending and not session.result_open and not sim.game_over and not session.save_blocked
		modal_raid.disabled=not session.ready_for_raid()
		if session.paused and not _reset_pending and not session.result_open and not sim.game_over and not session.save_blocked:
			modal_title.text="Votre domaine"
			var notice: String=session.notice
			notice="" if notice in DEFAULT_NOTICES else Notices.french(notice)
			modal_text.text="Cœur · Niveau %d" % session.progression.level()+("\n\n"+notice if not notice.is_empty() else "")
			if session.raid.raid_active and not session.raid.hero.is_empty():
				var hero: Dictionary=session.raid.hero
				modal_text.text="%s · Niv. %d\n%d / %d PV\n\n" % [hero.get("name","Visiteur"),hero.get("level",1),hero.get("hp",0),hero.get("max_hp",1)]+modal_text.text
	_refresh_live()
	_queue_layout()

func _dim_tile(tile: Button) -> void:
	tile.get_meta("mark").get_parent().modulate=Color(1,1,1,.45) if tile.disabled else Color.WHITE

## Placement bar text: a refusal or result first, then what the armed tool does.
func _pose_message() -> String:
	if not session.save_error.is_empty(): return session.save_error
	if not session.sim._has_core(): return "Touchez une case pour ancrer le cœur."
	if not session.notice in DEFAULT_NOTICES: return Notices.french(session.notice)
	if session.tool!=Types.Tool.NONE:
		var item := Catalog.definition(session.tool)
		return "%s · %s\nTouchez une case." % [item[1],item[2]]
	return ""

func _refresh_live() -> void:
	gold_value.text=str(session.sim.gold)
	heart_value.text="%d %%" % session.sim.core_hp
	treasury.tooltip_text="%d or · Vie du cœur : %d %%" % [session.sim.gold,session.sim.core_hp]
	var message := _pose_message()
	if pose_label.text!=message:
		pose_label.text=message
		pose_label.tooltip_text=message
	var showing := compact.visible and not message.is_empty()
	if pose_bar.visible!=showing:
		pose_bar.visible=showing
	_refresh_clock()

func _refresh_clock() -> void:
	var raid := session.raid.raid_active
	var ready := session.ready_for_raid()
	var stopped := session.paused or session.confirmation_open or session.result_open or session.sim.game_over or session.save_blocked
	var building := not raid and (session.catalog_open or session.tool!=Types.Tool.NONE or session.selected.x>=0)
	var seconds := int(session.raid.elapsed_seconds) if raid else ceili(session.raid.raid_timer)
	var heading := "RAID EN COURS" if raid else "PROCHAIN RAID"
	var note := "En pause" if stopped else "Délai suspendu" if building else ""
	if session.result_open: note="Raid terminé"
	elif session.sim.game_over: note="Cœur détruit"
	elif not raid and not ready:
		if not session.sim._has_core(): note="Cœur requis"
		elif not session.sim._has_entrance(): note="Entrée requise"
		else: note="Stockage requis"
	var narrow := peek.visible and mode!="dock"
	clock_title.text="RAID" if narrow else heading
	clock_value.text="%02d:%02d" % [seconds/60,seconds%60] if raid or ready else "—:—"
	clock_value.add_theme_font_size_override("font_size",12 if narrow else 16 if _compact_clock else 22)
	clock_state.text=("Pause" if stopped or building else "Attente" if not ready and not raid else "") if narrow else note
	clock_state.visible=not _compact_clock and not clock_state.text.is_empty()
	if _compact_clock:
		if session.result_open: clock_title.text="BILAN" if narrow else "RAID TERMINÉ"
		elif session.sim.game_over: clock_title.text="DÉFAITE"
		elif stopped or building: clock_title.text="PAUSE" if narrow else "RAID · PAUSE"
		elif not raid and not ready: clock_title.text="ATTENTE" if narrow else note.to_upper()
	clock_panel.tooltip_text=heading+" · "+clock_value.text+(" · "+note if not note.is_empty() else "")

func _queue_layout() -> void:
	if _layout_queued: return
	_layout_queued=true
	call_deferred("_layout")

func _layout() -> void:
	_layout_queued=false
	var viewport_size := get_viewport().get_visible_rect().size
	var window_size := Vector2(get_window().size)
	if viewport_size.x<=0 or window_size.x<=0: return
	var density := clampf(DisplayServer.screen_get_dpi()/160.0,1,4) if OS.has_feature("mobile") else 1.0
	var factor := viewport_size.x/window_size.x*density
	scale=Vector2.ONE*factor
	root.size=viewport_size/factor
	_safe=Rect2(Vector2.ZERO,root.size)
	if OS.has_feature("mobile"):
		var pixels := Rect2(DisplayServer.get_display_safe_area()).intersection(Rect2(Vector2(get_window().position),window_size))
		if pixels.has_area(): _safe=Rect2((pixels.position-Vector2(get_window().position))/density,pixels.size/density)
	# dock: portrait. column: tall landscape. wide: short landscape, where a
	# single 136-unit column would hide a family below the fold.
	var next := "dock" if _safe.size.y>_safe.size.x else "column" if _safe.size.y>=COLUMN_HEIGHT else "wide"
	var compact_clock := next=="dock" or (next=="column" and _safe.size.y<500)
	if next!=mode or compact_clock!=_compact_clock:
		mode=next
		_compact_clock=compact_clock
		_refresh(false)
	families.columns=1 if mode=="column" else 2
	body.vertical=mode!="dock"
	actions.vertical=mode=="dock"
	peek.vertical=mode!="dock"
	pose_box.vertical=mode=="column"
	stop_button.size_flags_horizontal=Control.SIZE_FILL
	if mode!="column": stop_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	pose_label.custom_minimum_size.y=30 if mode=="column" else 0
	pose_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if mode=="column" else HORIZONTAL_ALIGNMENT_LEFT
	for tile in [undo_button,observe_button]:
		tile.custom_minimum_size.x=DOCK_ACTIONS if mode=="dock" else 56.0
	var style := rail.get_theme_stylebox("panel") as StyleBoxTexture
	style.content_margin_left=4 if peek.visible and mode!="dock" else 8
	style.content_margin_right=style.content_margin_left
	if peek.visible: compact.hide()
	var contents: Control=modal_scroll.get_child(0)
	modal_title.add_theme_font_size_override("font_size",19)
	modal_text.add_theme_font_size_override("font_size",14)
	modal_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var expanded := shade.visible or catalog.visible or selection.visible
	match mode:
		"dock": _layout_dock(factor,expanded,contents)
		"wide": _layout_wide(factor,expanded,contents)
		_: _layout_column(factor,expanded,contents)
	call_deferred("_fit_family_titles")

## A long armed variant name wraps on two lines instead of being cut; its cost
## then remains readable in the placement bar.
func _fit_family_titles() -> void:
	for index in _family_titles.size():
		var title := _family_titles[index]
		var row := _family_rows[index]
		var room := _family_buttons[index].size.x+row.offset_right-row.offset_left-_family_pictures[index].custom_minimum_size.x-row.get_theme_constant("separation")
		var font := title.get_theme_font("font")
		var caption := title.text.replace("\n"," ")
		var long: bool=room>0 and caption.contains(" ") and font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x>room
		# Explicit line break: no autowrap collapse inside the row.
		title.text=caption.replace(" ","\n") if long else caption
		title.add_theme_font_size_override("font_size",12 if long else 13)
		if long: _family_notes[index].hide()

func _place_world(width: float, height: float, factor: float) -> void:
	_world_rect=Rect2(_safe.position*factor,Vector2(maxf(1,width),maxf(1,height))*factor)
	var play: Control=session.get_node("PlayArea")
	play.position=_world_rect.position; play.size=_world_rect.size

## Catalogue, selection and menus share one area below the timer/resources.
func _place_sheets(area: Rect2, contents: Control) -> void:
	catalog.fit_width(area.size.x)
	catalog.position=area.position; catalog.size=area.size
	selection.position=area.position
	selection.fit_width(area.size.x,area.size.y)
	selection.size=area.size
	shade.position=area.position; shade.size=area.size
	modal.position=Vector2.ZERO; modal.size=area.size
	contents.custom_minimum_size.x=maxf(0,area.size.x-36)

## Families + actions at the bottom (thumb side), the placement slot just above.
func _place_tools(top: float, x: float, width: float) -> void:
	var panel_height := minf(body.get_combined_minimum_size().y+16,_safe.end.y-top-POSE_SLOT)
	rail.position=Vector2(x,_safe.end.y-panel_height); rail.size=Vector2(width,panel_height)
	var slot := maxf(POSE_SLOT,pose_bar.get_combined_minimum_size().y)
	pose_bar.position=Vector2(x,rail.position.y-slot); pose_bar.size=Vector2(width,slot)

func _layout_column(factor: float, expanded: bool, contents: Control) -> void:
	var width := minf(244,_safe.size.x*.66) if expanded else 64.0 if peek.visible else 136.0
	var area := Rect2(Vector2(_safe.end.x-width,_safe.position.y),Vector2(width,_safe.size.y))
	backdrop.area=area
	_place_world(_safe.size.x-width,_safe.size.y,factor)
	_fit_family_rows(width-16)
	var clock_height := 60.0 if peek.visible or _compact_clock else 84.0
	clock_panel.position=area.position; clock_panel.size=Vector2(width,clock_height)
	var top := area.position.y+clock_height
	if treasury.visible:
		resource_rows.columns=2 if expanded else 1
		for value in [gold_value,heart_value]:
			value.size_flags_horizontal=Control.SIZE_FILL if expanded else Control.SIZE_EXPAND_FILL
		var resource_height := 54.0 if expanded else 86.0
		treasury.custom_minimum_size.y=resource_height
		treasury.position=Vector2(area.position.x,top); treasury.size=Vector2(width,resource_height)
		top+=resource_height
	var rest := Rect2(Vector2(area.position.x,top),Vector2(width,_safe.end.y-top))
	if peek.visible:
		rail.position=rest.position; rail.size=rest.size
	elif not expanded:
		_place_tools(top,area.position.x,width)
	_place_sheets(rest,contents)

func _layout_wide(factor: float, expanded: bool, contents: Control) -> void:
	var width := 64.0 if peek.visible else minf(WIDE_WIDTH,_safe.size.x*.5)
	var area := Rect2(Vector2(_safe.end.x-width,_safe.position.y),Vector2(width,_safe.size.y))
	backdrop.area=area
	_place_world(_safe.size.x-width,_safe.size.y,factor)
	_fit_family_rows((width-20)/2)
	if peek.visible:
		clock_panel.position=area.position; clock_panel.size=Vector2(width,60)
		rail.position=area.position+Vector2(0,60); rail.size=Vector2(width,area.size.y-60)
		return
	# Timer and resources side by side: one 86-unit row instead of two blocks.
	var clock_width := roundf(width*.43)
	clock_panel.position=area.position; clock_panel.size=Vector2(clock_width,86)
	resource_rows.columns=1
	for value in [gold_value,heart_value]: value.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	treasury.custom_minimum_size.y=86
	treasury.position=area.position+Vector2(clock_width,0); treasury.size=Vector2(width-clock_width,86)
	var top := area.position.y+86
	if not expanded: _place_tools(top,area.position.x,width)
	_place_sheets(Rect2(Vector2(area.position.x,top),Vector2(width,_safe.end.y-top)),contents)

## Portrait: a full-width dock at the bottom (thumb reach) and the whole width
## above it for the isometric dungeon. Timer and resources share its first row.
func _layout_dock(factor: float, _expanded: bool, contents: Control) -> void:
	var width := _safe.size.x
	var limit := maxf(ROW_HEIGHT+64,_safe.size.y*.55)-ROW_HEIGHT
	_fit_family_rows((width-16-DOCK_ACTIONS-8)/2)
	contents.custom_minimum_size.x=maxf(0,width-36)
	var panel_height := peek.get_combined_minimum_size().y+16
	var slot := 0.0
	if shade.visible:
		panel_height=minf(limit,contents.get_combined_minimum_size().y+30)
	elif catalog.visible:
		catalog.fit_width(width)
		panel_height=minf(limit,catalog.preferred_height())
	elif selection.visible:
		selection.fit_width(width,limit)
		panel_height=selection.size.y
	elif compact.visible:
		panel_height=body.get_combined_minimum_size().y+16
		slot=POSE_SLOT
	var dock := Rect2(_safe.position.x,_safe.end.y-ROW_HEIGHT-slot-panel_height,width,ROW_HEIGHT+slot+panel_height)
	backdrop.area=dock
	_place_world(width,dock.position.y-_safe.position.y,factor)
	var clock_width := clampf(width*.38,120,170)
	clock_panel.position=dock.position
	clock_panel.size=Vector2(clock_width,ROW_HEIGHT)
	resource_rows.columns=2
	for value in [gold_value,heart_value]: value.size_flags_horizontal=Control.SIZE_FILL
	treasury.custom_minimum_size.y=ROW_HEIGHT
	treasury.position=dock.position+Vector2(clock_width,0)
	treasury.size=Vector2(width-clock_width,ROW_HEIGHT)
	pose_bar.position=dock.position+Vector2(0,ROW_HEIGHT); pose_bar.size=Vector2(width,slot)
	var area := Rect2(dock.position+Vector2(0,ROW_HEIGHT+slot),Vector2(width,panel_height))
	rail.position=area.position; rail.size=area.size
	_place_sheets(area,contents)
	selection.size=area.size

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
	modal_text = UI.label(box, "", 16)
	modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_resume = UI.button(box, "Reprendre", _resume, "", true)
	modal_new = UI.button(box, "Nouveau donjon…", func(): _request_reset(false))
	modal_demo = UI.button(box, "Donjon d’essai…", func(): _request_reset(true))
	shade.hide()


func _refresh_modal() -> void:
	modal_resume.show(); modal_new.show(); modal_demo.show()
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
		modal_title.text = "LE CŒUR EST TOMBÉ" if session.sim.game_over else "RAID TERMINÉ"
		modal_text.text = "%s\n\nVaincus : %d · Sortis : %d\nOr volé : %d · Butin à ramasser : %d\nDéfenses à réparer : %d\nCœur : %d%% · +%d XP" % [result.get("hero_name", ""), result.get("killed", 0), result.get("escaped", 0), result.get("stolen", 0), session.sim._unsecured_loot_total(), session.sim._damaged_structure_count(), session.sim.core_hp, session.last_reward.get("xp", 0)]
		modal_resume.text = "RETOUR AU DONJON"
		modal_resume.visible = not session.sim.game_over
	elif session.paused:
		modal_title.text = "PAUSE"
		modal_text.text = "Votre donjon vous attend.\nGlissez pour déplacer la vue, touchez pour sélectionner.\nQuitter pendant le raid reprend la préparation sauvegardée."
		modal_resume.text = "REPRENDRE"
	else:
		modal_title.text = "VOTRE DONJON"
		modal_text.text = "Ancrez le cœur, aménagez votre donjon et observez les aventuriers.\n\nCommencez librement ou découvrez un donjon déjà préparé."
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
