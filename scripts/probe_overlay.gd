extends CanvasLayer

const MODEL := preload("res://scripts/dungeon_probes.gd")
const CATEGORIES := ["all","floor","wall","pier","entrance","heart","light","effect"]
const CATEGORY_NAMES := ["Tous les éléments","Sols","Murs","Piliers","Entrée","Cœur","Lumières","Effets"]

class Drawing:
	extends Control
	var inspector: CanvasLayer
	func _draw() -> void:
		inspector.draw_overlay(self)

@export var active := false
var selected_id := ""
var selected_probe_id := ""
var category := "all"
var snapshot: Dictionary = {"elements":[],"probes":[],"failures":[]}
var dungeon: Node2D
var drawing: Control
var status: Label
var details: Label
var outline_toggle: CheckButton
var probe_toggle: CheckButton
var _last_transform := Transform2D.IDENTITY
var _last_view_size := Vector2.ZERO

func _ready() -> void:
	layer = 100
	dungeon = get_parent().get_node("Dungeon")
	_build_ui()
	dungeon.rebuilt.connect(_on_rebuilt)
	set_active(active)

func set_active(value: bool) -> void:
	active = value
	visible = value
	set_process(value)
	if value and is_instance_valid(dungeon):
		refresh()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		set_active(not active)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local: Vector2 = dungeon.get_global_transform_with_canvas().affine_inverse()*event.position
		select_at(local)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			refresh()
		elif event.keycode == KEY_ESCAPE:
			set_active(false)

func _process(_delta: float) -> void:
	var transform := dungeon.get_global_transform_with_canvas()
	var size := get_viewport().get_visible_rect().size
	_layout_ui(size)
	if transform != _last_transform or size != _last_view_size:
		_last_transform = transform
		_last_view_size = size
		drawing.queue_redraw()

func _on_rebuilt() -> void:
	if active:
		refresh.call_deferred()

func refresh() -> void:
	snapshot = MODEL.inspect(dungeon)
	if _selected().is_empty():
		selected_id = ""
	_update_text()
	drawing.queue_redraw()

func select_at(point: Vector2) -> void:
	var element: Dictionary = MODEL.pick(snapshot.elements,point,category)
	selected_id = element.get("id","")
	selected_probe_id = ""
	var nearest := 7.0
	var transform := dungeon.get_global_transform_with_canvas()
	for probe: Dictionary in snapshot.probes:
		if not _probe_visible(probe):
			continue
		var distance: float = (transform*probe.position).distance_to(transform*point)
		if distance <= nearest:
			selected_probe_id = probe.id
			nearest = distance
	_update_text()
	drawing.queue_redraw()

func _probe_visible(probe: Dictionary) -> bool:
	return probe_toggle.button_pressed and (not probe.ok or category == "all" or category in probe.expected_kinds)

func _selected() -> Dictionary:
	for element: Dictionary in snapshot.elements:
		if element.id == selected_id:
			return element
	return {}

func _build_ui() -> void:
	drawing = Drawing.new()
	drawing.inspector = self
	drawing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(drawing)
	var toolbar := PanelContainer.new()
	toolbar.name = "Toolbar"
	toolbar.position = Vector2(12,12)
	add_child(toolbar)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",6)
	toolbar.add_child(box)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size",17)
	box.add_child(status)
	var controls := HFlowContainer.new()
	box.add_child(controls)
	var selector := OptionButton.new()
	for label in CATEGORY_NAMES:
		selector.add_item(label)
	selector.item_selected.connect(func(index: int):
		category = CATEGORIES[index]
		selected_id = ""
		selected_probe_id = ""
		_update_text()
		drawing.queue_redraw())
	controls.add_child(selector)
	outline_toggle = CheckButton.new()
	outline_toggle.text = "Contours"
	outline_toggle.button_pressed = true
	outline_toggle.toggled.connect(func(_pressed: bool): drawing.queue_redraw())
	controls.add_child(outline_toggle)
	probe_toggle = CheckButton.new()
	probe_toggle.text = "Sondes"
	probe_toggle.button_pressed = true
	probe_toggle.toggled.connect(func(_pressed: bool):
		selected_probe_id = ""
		_update_text()
		drawing.queue_redraw())
	controls.add_child(probe_toggle)
	var refresh_button := Button.new()
	refresh_button.text = "Actualiser · R"
	refresh_button.pressed.connect(refresh)
	controls.add_child(refresh_button)
	var export_button := Button.new()
	export_button.text = "Exporter JSON"
	export_button.pressed.connect(_export)
	controls.add_child(export_button)
	var close := Button.new()
	close.text = "Fermer · F3"
	close.pressed.connect(func(): set_active(false))
	controls.add_child(close)
	var legend := Label.new()
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.text = "Vert : sonde valide   Rouge : échec   Orange : sélection   Croix : origine"
	legend.add_theme_font_size_override("font_size",13)
	box.add_child(legend)
	var panel := PanelContainer.new()
	panel.name = "Details"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size",14)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(details)
	_layout_ui(get_viewport().get_visible_rect().size)

func _layout_ui(size: Vector2) -> void:
	get_node("Toolbar").size = Vector2(maxf(220,minf(size.x-24,850)),0)
	var panel := get_node("Details") as PanelContainer
	panel.size = Vector2(maxf(220,minf(size.x-24,430)),0)
	panel.position = Vector2(12,maxf(170,size.y-panel.size.y-12))

func _update_text() -> void:
	status.text = "SONDES · %d éléments · %d / %d points valides · F3"%[
		snapshot.elements.size(),snapshot.probes.size()-snapshot.failures.size(),snapshot.probes.size()]
	status.modulate = Color("ff7688") if not snapshot.failures.is_empty() else Color("8cefc5")
	var element := _selected()
	var text := "Cliquer sur un élément pour voir sa position.\nCoordonnées locales au donjon, en pixels.\nContrôles spatiaux ; le rendu GPU est testé séparément."
	if not element.is_empty():
		var cell := Vector2i(((element.anchor-Vector2.ONE*dungeon.layout.margin)/float(dungeon.layout.cell_size)).floor())
		text = "%s · %s\nOrigine : (%.1f, %.1f) px · case de l’origine : (%d, %d)\nEmprise : %.1f × %.1f px · Z effectif : %d\nAtlas : %s"%[
			element.id,element.kind,element.anchor.x,element.anchor.y,cell.x,cell.y,
			element.bounds.size.x,element.bounds.size.y,element.z,element.texture.get_file()]
		if not element.uv.is_empty():
			var uv_bounds: Rect2 = MODEL._bounds(element.uv)
			var region: Rect2 = element.source_region
			text += "\nRégion atlas : (%.0f, %.0f), %.0f × %.0f"%[region.position.x,region.position.y,region.size.x,region.size.y]
			text += "\nUV locales : (%.0f, %.0f), %.0f × %.0f"%[uv_bounds.position.x,uv_bounds.position.y,uv_bounds.size.x,uv_bounds.size.y]
	for probe: Dictionary in snapshot.probes:
		if probe.id == selected_probe_id:
			text += "\nSonde %s · %s\n%s"%[probe.id,"VALIDE" if probe.ok else "ÉCHEC",probe.message]
			break
	details.text = text
	_layout_ui(get_viewport().get_visible_rect().size)

func _export() -> void:
	refresh()
	var file := FileAccess.open("user://dungeon-probes.json",FileAccess.WRITE)
	if file == null:
		details.text = "Échec de l’export : "+error_string(FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(MODEL.report(snapshot),"\t"))
	details.text = "Rapport enregistré :\n"+ProjectSettings.globalize_path("user://dungeon-probes.json")

func draw_overlay(canvas: Control) -> void:
	if not active or not is_instance_valid(dungeon):
		return
	var transform := dungeon.get_global_transform_with_canvas()
	if outline_toggle.button_pressed:
		for element: Dictionary in snapshot.elements:
			if not element.visible or (category != "all" and element.kind != category):
				continue
			if category == "all" and element.kind in ["effect","light"]:
				continue
			var contour: PackedVector2Array = transform*element.contour
			if contour.size() < 2:
				continue
			contour.append(contour[0])
			canvas.draw_polyline(contour,Color(0.25,0.8,1,0.26),1,true)
	if probe_toggle.button_pressed:
		var labels: Array[Rect2] = [get_node("Toolbar").get_global_rect(),get_node("Details").get_global_rect()]
		for probe: Dictionary in snapshot.probes:
			if not _probe_visible(probe):
				continue
			var point: Vector2 = transform*probe.position
			if probe.ok:
				canvas.draw_circle(point,2.3,Color("67dbb3"))
			else:
				_cross(canvas,point,6,Color("ff526f"))
				# Dense join probes share pixels; place readable labels separately.
				var label_rect := failure_label_rect(point,probe.id,labels)
				if label_rect.has_area():
					labels.append(label_rect)
					canvas.draw_line(point,label_rect.get_center(),Color(1,0.3,0.45,0.5),1,true)
					canvas.draw_rect(label_rect,Color(0.03,0.05,0.09,0.9))
					canvas.draw_string(ThemeDB.fallback_font,label_rect.position+Vector2(4,13),probe.id,0,-1,12,Color("ff93a3"))
	var element := _selected()
	if not element.is_empty():
		var contour: PackedVector2Array = transform*element.contour
		if not contour.is_empty():
			contour.append(contour[0])
			canvas.draw_polyline(contour,Color("ffd166"),2.5,true)
		var anchor: Vector2 = transform*element.anchor
		_cross(canvas,anchor,8,Color("ffd166"))
		canvas.draw_string(ThemeDB.fallback_font,anchor+Vector2(12,-12),element.id,0,-1,15,Color("ffd166"))
		var bounds: PackedVector2Array = transform*MODEL._rect_polygon(element.bounds)
		bounds.append(bounds[0])
		canvas.draw_polyline(bounds,Color(1,0.82,0.4,0.4),1,true)

func _cross(canvas: Control,point: Vector2,radius: float,color: Color) -> void:
	canvas.draw_line(point-Vector2(radius,0),point+Vector2(radius,0),color,2,true)
	canvas.draw_line(point-Vector2(0,radius),point+Vector2(0,radius),color,2,true)

func failure_label_rect(point: Vector2,id: String,occupied: Array[Rect2]) -> Rect2:
	var view_size := get_viewport().get_visible_rect().size
	if not Rect2(Vector2.ZERO,view_size).has_point(point) or occupied.size() >= 18:
		return Rect2()
	var width := ThemeDB.fallback_font.get_string_size(id,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+8
	var x := clampf(point.x+10,4,view_size.x-width-4)
	for offset in range(30):
		var y := point.y-15+offset*19
		if y+18 > view_size.y-4:
			break
		var candidate := Rect2(x,maxf(4,y),width,18)
		if not occupied.any(func(rect: Rect2): return rect.intersects(candidate.grow(2))):
			return candidate
	return Rect2()
