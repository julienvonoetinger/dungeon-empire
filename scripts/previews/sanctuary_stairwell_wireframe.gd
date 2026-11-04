extends Control
## Geometry-only review; the approved introduction is not replaced by this preview.
const SCENERY=preload("res://scenes/SanctuaryWireframe.tscn")
const STAIR=preload("res://assets/previews/sanctuary-stairwell-wireframe/stairwell.svg")
@export var scenery_scene: PackedScene=SCENERY
@export var stair_texture: Texture2D=STAIR
@export var painted:=false
var sanctuary: Node2D
var stairs := Sprite2D.new()
var excavated := true
var geometry: Dictionary
var profile: Control
var state_button := Button.new()

class Section extends Control:
	func _draw() -> void:
		var w:=size.x
		draw_style_box(_panel(),Rect2(Vector2.ZERO,size))
		var start:=Vector2(24,52)
		var span:=(w-56)*.69
		var step:=span/10.
		draw_line(Vector2(16,52),Vector2(w-16,52),Color("dfbe80"),2.)
		var points:=PackedVector2Array([start])
		for i in 10:
			points.append(start+Vector2((i+1)*step,i*80./9.))
			if i<9: points.append(start+Vector2((i+1)*step,(i+1)*80./9.))
		points.append(Vector2(w-24,132))
		draw_polyline(points,Color("b3cad5"),2.,true)
		for x in range(int(start.x+span),int(w-24),14):
			draw_line(Vector2(x,52),Vector2(x+7,52),Color("b3cad5"),2.)
		draw_line(Vector2(w-55,109),Vector2(w-25,109),Color("9ccebd"),2.)
		draw_line(Vector2(w-25,109),Vector2(w-33,104),Color("9ccebd"),2.)
		draw_line(Vector2(w-25,109),Vector2(w-33,114),Color("9ccebd"),2.)
	func _panel() -> StyleBoxFlat:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color(.055,.075,.095,.96)
		return style

func _ready() -> void:
	get_window().title="Entrée du donjon · Pierre peinte" if painted else "Entrée du donjon · Wireframe"
	get_window().content_scale_size=Vector2i.ZERO
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	geometry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/previews/sanctuary-stairwell-wireframe/geometry.json"))
	sanctuary=scenery_scene.instantiate()
	sanctuary.set_script(null)
	add_child(sanctuary)
	for stone_name in geometry.sceneryOffsets:
		var offset_data: Array=geometry.sceneryOffsets[stone_name]
		sanctuary.get_node(stone_name).position+=Vector2(offset_data[0],offset_data[1])
	stairs.texture=stair_texture
	stairs.centered=false
	stairs.position=Vector2(geometry.mouth[0],geometry.mouth[1])
	stairs.offset=Vector2(geometry.frame[0],geometry.frame[1])
	sanctuary.add_child(stairs)
	# Same physical slot as the removed rock: neighbouring cliffs keep occluding.
	sanctuary.move_child(stairs,sanctuary.get_node("Paroi4").get_index()+1)
	var title:=Label.new()
	title.text="Entrée · Pierre peinte" if painted else "Entrée · Deux cellules de la grille"
	title.position=Vector2(12,10)
	add_child(title)
	var controls:=HBoxContainer.new()
	add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left=12;controls.offset_top=-46;controls.offset_bottom=-10
	controls.add_child(state_button)
	state_button.pressed.connect(func():set_excavated(not excavated))
	var section_button:=Button.new()
	section_button.text="Vue en coupe"
	section_button.pressed.connect(func():profile.visible=not profile.visible)
	controls.add_child(section_button)
	profile=Section.new()
	add_child(profile)
	profile.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	profile.offset_left=12;profile.offset_right=-12;profile.offset_top=-230;profile.offset_bottom=-62
	profile.mouse_filter=Control.MOUSE_FILTER_IGNORE
	profile.hide()
	var section_title:=Label.new()
	section_title.text="Coupe : sol actuel et descente"
	section_title.position=Vector2(12,9)
	profile.add_child(section_title)
	resized.connect(_fit)
	set_excavated(true)
	_fit()

func set_excavated(value: bool) -> void:
	excavated=value
	sanctuary.get_node("Paroi4").visible=not excavated
	stairs.visible=excavated
	state_button.text="Voir avant destruction" if excavated else "Voir après excavation"

func _fit() -> void:
	if not is_instance_valid(sanctuary): return
	var focus:=Vector2(35,-100)
	var fit:=minf(size.x/1440.,(size.y-52)/980.)
	if size.y>size.x:
		focus=Vector2(70,-100)
		fit=size.x/660.
	sanctuary.scale=Vector2.ONE*fit
	sanctuary.position=Vector2(size.x*.5,(size.y-52)*.5)-focus*fit
	if is_instance_valid(profile): profile.queue_redraw()
