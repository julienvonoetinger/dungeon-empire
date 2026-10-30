@tool
extends "res://scripts/mobile_dungeon_renderer.gd"
## Static catalogue of the actual prepared trap layers; no game session or save.
signal rebuilt

const KINDS := ["spike", "snare", "void"]
const NAMES := ["Spikes", "Snare", "Void"]
const STATES := ["ready", "triggered", "spent"]
const TITLES := ["READY", "TRIGGERED", "SPENT"]
const NOTES := [
	["Spikes retracted", "Spikes raised", "Mechanism inactive"],
	["Jaws open", "Jaws closed", "Energy depleted"],
	["Seal charged", "Rift open", "Seal depleted"],
]

@export_tool_button("Refresh traps", "Reload") var refresh_action: Callable:
	get:
		return Callable(self, "refresh_preview")

var _plan: Dictionary = {}
var _annotations: Node2D
var _font: FontFile

func _ready() -> void:
	refresh_preview()

func refresh_preview() -> void:
	var cells := {}
	var openings := {}
	var floors := {}
	var mechanisms := {}
	for row in KINDS.size():
		for column in STATES.size():
			# Opposite grid steps make screen-aligned columns without rotating art.
			var cell:=Vector2i(2*column+2*row, -2*column+2*row)
			var prefix: String="trap-"+KINDS[row]+"-"+STATES[column]
			cells[cell]=true
			openings[cell]=15 # All four edges open: no wall hides the mechanism.
			floors[cell]=prefix+"-floor"
			if KINDS[row]!="void": mechanisms[cell]=prefix+"-mechanism"
	_plan={"cells":cells,"openings":openings,"floor_replacements":floors,"mechanisms":mechanisms}
	render_plan(_plan,{},false)
	_build_annotations()
	rebuilt.emit()

func _build_annotations() -> void:
	if is_instance_valid(_annotations):
		remove_child(_annotations)
		_annotations.queue_free()
	_annotations=Node2D.new(); _annotations.name="StateLabels"; _annotations.z_index=5
	add_child(_annotations)
	_font=ThemeDB.fallback_font.duplicate() as FontFile
	_font.multichannel_signed_distance_field=true
	_caption("DUNGEON TRAPS",Rect2(0,-130,1024,44),32,Color("dfc5f3"))
	for column in STATES.size():
		var at:=grid_to_local(Vector2(2*column,-2*column))
		_caption(TITLES[column],Rect2(at+Vector2(-170,-50),Vector2(340,32)),24,Color("d9b45c"))
	for row in KINDS.size():
		var origin:=grid_to_local(Vector2(2*row,2*row))
		_caption(NAMES[row],Rect2(origin+Vector2(-330,42),Vector2(180,40)),28,Color("e8dcc8"))
		for column in STATES.size():
			var at:=grid_to_local(Vector2(2*column+2*row,-2*column+2*row))
			_caption(NOTES[row][column],Rect2(at+Vector2(-190,154),Vector2(380,30)),20,Color("b8b2c8"))
	_caption("Fixed states for comparison · Drag to pan",Rect2(-150,720,1324,30),18,Color("9994aa"))
	_frame=_frame.merge(Rect2(-340,-140,1570,900))

func _caption(text: String, rect: Rect2, font_size: int, color: Color) -> void:
	var label:=Label.new()
	label.text=text; label.position=rect.position; label.size=rect.size
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",_font)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	_annotations.add_child(label)

func get_connection_plan() -> Dictionary:
	return _plan
