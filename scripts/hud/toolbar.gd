class_name GameToolbar
extends RefCounted

const Tool := GameTypes.Tool
const TILE_W := GameTypes.TILE_W
const TILE_H := GameTypes.TILE_H
const COLS := GameTypes.COLS
const ROWS := GameTypes.ROWS
const TOOLBAR_MARGIN := GameTypes.TOOLBAR_MARGIN
const BTN_X := GameTypes.BTN_X
const BTN_GAP := GameTypes.BTN_GAP
const BTN_H := GameTypes.BTN_H
const HUD_TOP := GameTypes.HUD_TOP
const PLAY_MARGIN := GameTypes.PLAY_MARGIN
const DESIGN_SIZE := GameTypes.DESIGN_SIZE

var g: DungeonGame


func _btn_y() -> float:
	return g._view_size().y - TOOLBAR_MARGIN


func _layout_toolbar() -> void:
	_setup_toolbar_buttons()
	var s: Vector2 = g._view_size()
	if g.toolbar_host != null:
		g.toolbar_host.position = Vector2.ZERO
		g.toolbar_host.size = s
	var specs := _buttons()
	for i in range(mini(g.tool_buttons.size(), specs.size())):
		var r: Rect2 = specs[i]["rect"]
		g.tool_buttons[i].position = r.position
		g.tool_buttons[i].custom_minimum_size = r.size
		g.tool_buttons[i].size = r.size


func _setup_toolbar_buttons() -> void:
	if g.tool_buttons.size() != _buttons().size():
		for b in g.tool_buttons:
			if is_instance_valid(b):
				b.queue_free()
		g.tool_buttons.clear()
		if g.toolbar_host != null:
			var layer_node: Node = g.toolbar_host.get_parent()
			g.toolbar_host.queue_free()
			g.toolbar_host = null
			if layer_node != null:
				layer_node.queue_free()
	if not g.tool_buttons.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.name = "ToolbarLayer"
	g.add_child(layer)
	var host := Control.new()
	host.name = "ToolbarHost"
	g.toolbar_host = host
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_preset(Control.PRESET_TOP_LEFT)
	host.position = Vector2.ZERO
	host.size = g._view_size()
	layer.add_child(host)
	for spec in _buttons():
		var r: Rect2 = spec["rect"]
		var btn := Button.new()
		btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		btn.position = r.position
		btn.custom_minimum_size = r.size
		btn.size = r.size
		btn.clip_text = true
		btn.clip_contents = true
		btn.autowrap_mode = TextServer.AUTOWRAP_OFF
		btn.text = "%s\n%s" % [spec["label"], spec["cost"]]
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var tool := int(spec["tool"])
		btn.pressed.connect(_on_toolbar_button.bind(tool))
		host.add_child(btn)
		g.tool_buttons.append(btn)


func _on_toolbar_button(tool: int) -> void:
	g.debug_clicks += 1
	if g.raid_active:
		return
	_apply_toolbar_tool(tool)
	_refresh_toolbar_buttons()
	g.queue_redraw()


func _refresh_toolbar_buttons() -> void:
	var specs := _buttons()
	for i in range(mini(g.tool_buttons.size(), specs.size())):
		var spec: Dictionary = specs[i]
		var tool := int(spec["tool"])
		var label := String(spec["label"])
		if tool == Tool.RESET and g.reset_armed:
			label = "Confirm?"
		if tool == g.selected_tool:
			g.tool_buttons[i].modulate = Color(1.15, 1.05, 1.3)
		else:
			g.tool_buttons[i].modulate = Color.WHITE
		g.tool_buttons[i].text = "%s\n%s" % [label, spec["cost"]]


func _buttons() -> Array:
	var defs := GameTypes.toolbar_defs()
	var n: int = defs.size()
	var view: Vector2 = g._view_size()
	var usable: float = maxf(view.x - BTN_X * 2.0, 200.0)
	var w: float = (usable - BTN_GAP * float(n - 1)) / float(n)
	var out := []
	for i in range(n):
		var d: Dictionary = defs[i]
		d["rect"] = Rect2(Vector2(BTN_X + float(i) * (w + BTN_GAP), _btn_y()), Vector2(w, BTN_H))
		out.append(d)
	return out


func _toolbar_hit(mp: Vector2) -> bool:
	for b in _buttons():
		var rect: Rect2 = b["rect"]
		if rect.has_point(mp):
			return true
	return false


func _handle_toolbar(mp: Vector2) -> void:
	for b in _buttons():
		var rect: Rect2 = b["rect"]
		if not rect.has_point(mp):
			continue
		_apply_toolbar_tool(int(b["tool"]))
		return


func _apply_toolbar_tool(tool: int) -> void:
	if tool == Tool.RESET:
		if g.reset_armed or g.game_over:
			g._new_map()
		else:
			g.reset_armed = true
			g.message = "Reset: click a second time to wipe everything."
		return
	g.reset_armed = false
	if g.game_over:
		return
	if tool == Tool.REPAIR:
		g._repair_structures()
		return
	g.selected_tool = tool
