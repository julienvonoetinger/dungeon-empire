class_name GameToolbar
extends RefCounted

## Pie menu on excavated cells. Replaces the old bottom action bar.

const Tool := GameTypes.Tool
const INNER := 42.0
const OUTER := 128.0
const GAP := 0.028

var g: DungeonGame
var open := false
var cell := Vector2i(-1, -1)
var center := Vector2.ZERO
var hover := -1


func _btn_y() -> float:
	return g._view_size().y - 8.0


func _layout_toolbar() -> void:
	_setup_toolbar_buttons()


func _setup_toolbar_buttons() -> void:
	for b in g.tool_buttons:
		if is_instance_valid(b):
			b.queue_free()
	g.tool_buttons.clear()
	if g.toolbar_host != null and is_instance_valid(g.toolbar_host):
		return
	var layer := CanvasLayer.new()
	layer.layer = 200
	layer.name = "RadialLayer"
	g.add_child(layer)
	var host := Control.new()
	host.set_script(load("res://scripts/hud/radial_overlay.gd"))
	host.name = "RadialHost"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(host)
	host.set("menu", self)
	g.toolbar_host = host


func _on_toolbar_button(tool: int) -> void:
	g.debug_clicks += 1
	if g.raid_active:
		return
	_apply_toolbar_tool(tool)
	g.queue_redraw()


func _refresh_toolbar_buttons() -> void:
	pass


func _buttons() -> Array:
	return GameTypes.toolbar_defs().duplicate(true)


func _wheel_defs() -> Array:
	var defs: Array = _buttons()
	if not _cell_has_trap():
		var kept: Array = []
		for d in defs:
			if int(d["tool"]) != Tool.REPAIR:
				kept.append(d)
		return kept
	return defs


func _cell_has_trap() -> bool:
	if not g._inside(cell):
		return false
	return g._is_trap_tile(int(g.grid[cell.y][cell.x]))


func _cell_trap_damaged() -> bool:
	if not _cell_has_trap():
		return false
	var t := int(g.grid[cell.y][cell.x])
	var cap := g._trap_max_charges(t)
	return int(g.trap_charges.get(cell, cap)) < cap


func _tool_enabled(tool: int) -> bool:
	if tool == Tool.REPAIR:
		return _cell_trap_damaged()
	if tool == Tool.BUILD_ENTRANCE:
		return not g._has_entrance()
	return true


func _toolbar_hit(mp: Vector2) -> bool:
	if not open:
		return false
	return mp.distance_to(center) <= OUTER + 8.0


func _handle_toolbar(mp: Vector2) -> void:
	if not open:
		return
	var i := slice_at(mp)
	if i >= 0:
		pick_index(i)
		return
	close()


func close() -> void:
	open = false
	hover = -1
	cell = Vector2i(-1, -1)
	_redraw_wheel()


func open_at(p: Vector2i, screen: Vector2) -> void:
	open = true
	cell = p
	var s: Vector2 = g._view_size()
	center = Vector2(
		clampf(screen.x, OUTER + 8.0, maxf(OUTER + 8.0, s.x - OUTER - 8.0)),
		clampf(screen.y, OUTER + 8.0, maxf(OUTER + 8.0, s.y - OUTER - 8.0))
	)
	hover = slice_at(screen)
	_redraw_wheel()


func hover_at(mp: Vector2) -> void:
	if not open:
		return
	var next := slice_at(mp)
	if next != hover:
		hover = next
		_redraw_wheel()


func _redraw_wheel() -> void:
	if g.toolbar_host != null:
		g.toolbar_host.queue_redraw()
	g.queue_redraw()


func slice_at(mp: Vector2) -> int:
	var d := mp - center
	var dist := d.length()
	if dist < INNER or dist > OUTER:
		return -1
	var defs := _wheel_defs()
	var n: int = defs.size()
	if n <= 0:
		return -1
	var step := TAU / float(n)
	var ang := atan2(d.y, d.x)
	var start := -PI * 0.5 - step * 0.5
	var rel := ang - start
	while rel < 0.0:
		rel += TAU
	while rel >= TAU:
		rel -= TAU
	return clampi(int(rel / step), 0, n - 1)


func pick_index(i: int) -> void:
	var defs := _wheel_defs()
	if i < 0 or i >= defs.size():
		return
	var tool := int(defs[i]["tool"])
	if not _tool_enabled(tool):
		return
	var at := cell
	close()
	_apply_toolbar_tool(tool)
	if tool == Tool.REPAIR or tool == Tool.RESET:
		g.selected_tool = Tool.NONE
		g._sync_world()
		g.queue_redraw()
		return
	if tool == Tool.ABSORB:
		g._absorb_at_cell(at)
		g.selected_tool = Tool.NONE
		g._sync_world()
		g.queue_redraw()
		return
	g._build_at(at)
	g.selected_tool = Tool.NONE
	g._sync_world()
	g.queue_redraw()


func _apply_toolbar_tool(tool: int) -> void:
	close()
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


func draw_wheel(c: CanvasItem) -> void:
	if not open:
		return
	var defs := _wheel_defs()
	var n: int = defs.size()
	if n <= 0:
		return
	var step := TAU / float(n)
	var start := -PI * 0.5 - step * 0.5
	c.draw_circle(center, OUTER + 6.0, Color(0, 0, 0, 0.28))
	for i in n:
		var a0: float = start + float(i) * step + GAP
		var a1: float = start + float(i + 1) * step - GAP
		var spec: Dictionary = defs[i]
		var tool := int(spec["tool"])
		var enabled := _tool_enabled(tool)
		var active: bool = i == hover and enabled
		var fill := Color(0.12, 0.12, 0.14, 0.88)
		if not enabled:
			fill = Color(0.08, 0.08, 0.09, 0.55)
		elif active:
			fill = Color(0.42, 0.78, 0.82, 0.95)
		c.draw_colored_polygon(_slice_poly(center, INNER, OUTER, a0, a1), fill)
		var mid: float = (a0 + a1) * 0.5
		var pos: Vector2 = center + Vector2(cos(mid), sin(mid)) * ((INNER + OUTER) * 0.5)
		var label := String(spec["label"])
		var cost := String(spec["cost"])
		var ink := Color(0.45, 0.45, 0.48) if not enabled else (Color.WHITE if active else GameTypes.C_TEXT)
		var gold := Color(0.35, 0.32, 0.28) if not enabled else (Color(0.08, 0.08, 0.1) if active else GameTypes.C_WARM_GOLD)
		c.draw_string(g.font, pos + Vector2(-36, -6), label, HORIZONTAL_ALIGNMENT_CENTER, 72, 13, ink)
		c.draw_string(g.font, pos + Vector2(-36, 12), cost, HORIZONTAL_ALIGNMENT_CENTER, 72, 11, gold)
	c.draw_circle(center, INNER - 4.0, Color(0.07, 0.07, 0.09, 0.55))
	c.draw_arc(center, INNER, 0.0, TAU, 48, Color(0.2, 0.2, 0.22, 0.9), 2.0)
	c.draw_arc(center, OUTER, 0.0, TAU, 64, Color(0.28, 0.28, 0.3, 0.9), 2.0)


func _slice_poly(cen: Vector2, r0: float, r1: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var segs := 10
	for i in range(segs + 1):
		var a: float = lerpf(a0, a1, float(i) / float(segs))
		pts.append(cen + Vector2(cos(a), sin(a)) * r1)
	for i in range(segs + 1):
		var a: float = lerpf(a1, a0, float(i) / float(segs))
		pts.append(cen + Vector2(cos(a), sin(a)) * r0)
	return pts
