@tool
extends Node2D
## Organic spore ritual, drawn on the caster's physical layer. No independent clock.
const FLOW := preload("res://shaders/mycean_arcane_flow.gdshader")
const SOFT := preload("res://assets/dungeon/mobile-kit/light-falloff.png")
const STEPS := 48
var origin := Vector2.ZERO
var target := Vector2.ZERO
var seconds := 0.0
var channel := false
var charge := 0.0
var release := 0.0
var releasing := false
var seal_axis := Vector2(1,.5)
var _ribbons: Array[MeshInstance2D] = []

func _ready() -> void:
	_build_ribbons()
	refresh()

func _build_ribbons() -> void:
	if not _ribbons.is_empty(): return
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in STEPS+1:
		for side in 2:
			vertices.append(Vector2(float(i)/STEPS,side))
			uv.append(vertices[-1])
		if i<STEPS:
			var k := i*2
			indices.append_array(PackedInt32Array([k,k+1,k+2,k+1,k+3,k+2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	for i in 2:
		var ribbon := MeshInstance2D.new()
		ribbon.name = "ArcaneFilament"+str(i)
		ribbon.mesh = mesh
		var ink := ShaderMaterial.new()
		ink.shader = FLOW
		ink.set_shader_parameter("strand",float(i))
		ribbon.material = ink
		# Mist underneath the drawn spores and rune marks on this same layer.
		ribbon.show_behind_parent = true
		add_child(ribbon)
		_ribbons.append(ribbon)

func refresh() -> void:
	if not _ribbons.is_empty():
		# Vertex-shader displacement is invisible to the canvas culler. Register
		# its real local support, including the curling/mist envelope.
		var support := Rect2(origin,Vector2.ZERO).expand(target).grow(28)
		_ribbons[0].mesh.custom_aabb = AABB(Vector3(support.position.x,support.position.y,-1),Vector3(support.size.x,support.size.y,2))
	for ribbon in _ribbons:
		ribbon.visible = channel
		var ink: ShaderMaterial = ribbon.material
		ink.set_shader_parameter("source_point",origin)
		ink.set_shader_parameter("seal_point",target)
		ink.set_shader_parameter("phase",seconds)
		ink.set_shader_parameter("strength",smoothstep(.42,.63,seconds))
	queue_redraw()

func _soft(point: Vector2, radius: float, tint: Color) -> void:
	if radius>.01 and tint.a>.001:
		draw_texture_rect(SOFT,Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2),false,tint)

func _flow_at(t: float, strand: float) -> Vector2:
	var delta := target-origin
	var normal := Vector2(-delta.y,delta.x).normalized()
	var envelope := sin(PI*t)
	return origin.lerp(target,t)+Vector2(0,-6*envelope)+normal*sin(t*PI*3-seconds*8+strand*PI)*9*envelope

func _plane(point: Vector2) -> Vector2:
	return seal_axis*point.x+Vector2.UP*point.y

func _rune(centre: Vector2, size: float, angle: float, variant: int, tint: Color) -> void:
	var glyph: PackedVector2Array
	match variant%3:
		0: glyph = PackedVector2Array([Vector2(-.6,-.7),Vector2(0,.9),Vector2(.6,-.7),Vector2(0,-.2)])
		1: glyph = PackedVector2Array([Vector2(-.5,0),Vector2(0,.8),Vector2(.5,0),Vector2(0,-.8),Vector2(-.5,0)])
		_: glyph = PackedVector2Array([Vector2(-.7,-.5),Vector2(.6,-.5),Vector2(-.4,.6),Vector2(.7,.6)])
	var points := PackedVector2Array()
	for point in glyph: points.append(centre+_plane((point*size).rotated(angle)))
	draw_polyline(points,Color(tint, tint.a*.16),3.4,true)
	draw_polyline(points,tint,1.0,true)

func _draw() -> void:
	var pulse := .9+.1*sin(seconds*11)
	if charge>0:
		_soft(origin,19*charge,Color(.49,.16,1,.65*charge))
		_soft(origin,8*charge,Color(.59,1,.84,.8*charge))
		for i in 9:
			var a := seconds*2.8+float(i)*TAU/9
			var radius := (6.0+float(i%3)*3.0)*(1.5-.65*charge)
			var point := origin+Vector2(cos(a)*radius,sin(a)*radius*.7)
			var tint := Color(.65,.93,1,.65*charge)
			_soft(point,3.8,tint)
			draw_circle(point,.7+float(i%2)*.4,tint)
	if channel:
		# Uneven spore clusters travel in the twisted stream, never a solid core.
		for i in 19:
			var u := fposmod(seconds*(.73+float(i%3)*.06)+float(i)*.618034,1)
			var point := _flow_at(u,float(i%2))
			var life := pow(sin(PI*u),.4)
			var tint := Color(.72,.50,1,.85*life) if i%3 else Color(.52,1,.84,.85*life)
			_soft(point,4.5,tint)
			draw_circle(point,.7+float(i%3)*.3,tint)
			if i%4==0:
				var tail := _flow_at(maxf(0,u-.035),float(i%2))
				draw_line(tail,point,Color(tint,tint.a*.55),1,true)
	if channel or releasing:
		var progress := clampf((seconds-.45)/1.05,0,1)
		var fading := 1-release
		_soft(target,21+release*8,Color(.64,.19,1,.5*fading*pulse))
		for ring in 2:
			var radius := 13.0+ring*7.0+release*13.0
			var turn := seconds*(.7 if ring==0 else -.45)
			for arc in 5:
				var points := PackedVector2Array()
				for j in 9:
					var a := turn+float(arc)*TAU/5+float(j)*.07
					points.append(target+_plane(Vector2(cos(a),sin(a))*radius))
				draw_polyline(points,Color(.64,.33,1,.55*fading),1,true)
		for i in 6:
			var a := float(i)*TAU/6+seconds*.12
			var radius := 19.0+release*(14.0+float(i%2)*4)
			var centre := target+_plane(Vector2(cos(a),sin(a))*radius)
			var lit := .35+.65*smoothstep(float(i)/6-.08,float(i)/6+.08,progress)
			_rune(centre,2.4+release*.8,a+release*1.8,i,Color(.84,.63,1,lit*fading))
		if releasing:
			for i in 8:
				var a := float(i)*TAU/8+.25
				var point := target+_plane(Vector2(cos(a),sin(a)))*(7+release*24)
				_soft(point,4,Color(.68,.93,1,fading*.75))
