extends Node2D
## Each frame is a complete render of the original equipped model.
var is_invoker := false
var sprite := Sprite2D.new()
var shadow := Sprite2D.new()
var textures := {}
var directional_textures := {}
static var walk_data: Dictionary={}
const COUNTS := {"idle":1,"walk":24,"chant":48,"bow":32,"kneel":32}

func _ready() -> void:
	shadow.texture = preload("res://assets/dungeon/mobile-kit/light-falloff.png")
	shadow.scale = Vector2(98,32)/Vector2(shadow.texture.get_size())
	shadow.modulate = Color(.025,.015,.04,.7)
	add_child(shadow)
	add_child(sprite)
	sprite.centered = false
	sprite.offset = Vector2(-128,-187.1207)
	sprite.region_enabled = true
	var kind := "invoker" if is_invoker else "oculin"
	var modes := ["idle","walk","chant","bow"] if is_invoker else ["idle","walk","chant","kneel"]
	for mode in modes:
		textures[mode] = load("res://assets/game/introduction/procession/%s-%s.png" % [kind,mode])
	present("idle",0)

func present(mode: String, frame: int) -> void:
	var columns := mini(8,int(COUNTS[mode]))
	sprite.texture = textures.get(mode)
	sprite.region_rect = Rect2((frame%columns)*256,floori(float(frame)/columns)*256,256,256)

func present_direction(mode: String, frame: int, direction: String) -> void:
	if direction=="n" or not is_invoker:
		present(mode,frame)
		return
	var key:=direction+"-"+mode
	if not directional_textures.has(key):
		directional_textures[key]=load("res://assets/game/introduction/invoker-follow/%s.png" % key)
	sprite.texture=directional_textures[key]
	var columns:=mini(8,int(COUNTS[mode]))
	sprite.region_rect=Rect2((frame%columns)*256,floori(float(frame)/columns)*256,256,256)

static func direction_for(delta: Vector2) -> String:
	# Undo the ground plane's vertical squash before choosing an eight-way heading.
	var direction: Vector2=(delta*Vector2(1,2)).normalized()
	var headings: Array[Vector2]=[Vector2(0,-1),Vector2(1,-1),Vector2(1,0),Vector2(1,1),Vector2(0,1),Vector2(-1,1),Vector2(-1,0),Vector2(-1,-1)]
	var names: Array[String]=["n","ne","e","se","s","sw","w","nw"]
	var best:=0
	var score:=-INF
	for i in headings.size():
		var dot:=direction.dot(headings[i].normalized())
		if dot>score:
			score=dot
			best=i
	return names[best]

static func stride_pixels(direction: String) -> float:
	if walk_data.is_empty():
		walk_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/game/introduction/invoker-follow/directions.json")).directions
	# Preserve the approved diagonal cadence (90px/cycle), accounting for each
	# camera's foreshortening. Raw ankle excursion is not a planted-foot stride;
	# using it directly makes this existing short-step gait cycle five times/sec.
	return float(walk_data[direction].stride_pixels)/float(walk_data.ne.stride_pixels)*90.

static func walk_cycles(path: PackedVector2Array,progress: float,actor_scale: float) -> float:
	var length:=0.
	for i in range(1,path.size()): length+=path[i-1].distance_to(path[i])
	var remaining:=length*clampf(progress,0.,1.)
	var cycles:=0.
	for i in range(1,path.size()):
		var delta:=path[i]-path[i-1]
		var used:=minf(remaining,delta.length())
		cycles+=used/(stride_pixels(direction_for(delta))*actor_scale)
		remaining-=used
		if remaining<=0.: break
	return cycles
