extends Node2D
## Procedural ritual light, entirely driven by the introduction's explicit clock.
const LIGHT = preload("res://assets/dungeon/mobile-kit/light-falloff.png")
const CENTER := Vector2(-6,7)
const MANIFESTATION_CENTER := CENTER+Vector2(0,-100)
const VIOLET := Color(.60,.19,1.0)
const PALE := Color(.88,.70,1.0)
# Clockwise stone indices, alternating distant impacts around the sanctuary.
const STRIKE_TIMES := [13.12, 14.74, 13.70, 15.24, 14.23, 15.72]
const SKY_OFFSETS := [-205., 160., 155., -120., -145., -180.]
var sky_top := -800.0
var crystal_lights := PackedVector3Array()
var aerial := false
var seconds := 0.0
var energy := 0.0
var flash_strength := 0.0
var lightning_strength := 0.0
var stones: Array[Vector2] = []
var ribbons: Array[ArrayMesh] = []

func _ready() -> void:
	var additive := ShaderMaterial.new()
	additive.shader=preload("res://shaders/invocation_light.gdshader")
	material=additive
	hide()

func present(time: float) -> void:
	seconds=time
	material.set_shader_parameter("effect_time",time)
	var rising := smoothstep(10.0,19.8,time)
	energy=rising*lerpf(1.0,.16,smoothstep(21.0,23.0,time))
	flash_strength=0.0
	if time>=20.0 and time<21.0:
		flash_strength=sin(PI*(time-20.0)) * (1.0-smoothstep(20.4,21.0,time))
	lightning_strength=smoothstep(18.3,19.8,time)*(1.0-smoothstep(20.0,20.45,time))
	if aerial:
		crystal_lights.resize(stones.size())
		for i in stones.size():
			var age := time-float(STRIKE_TIMES[i])
			var wake := smoothstep(.055,.11,age)*(1.-smoothstep(20.35,22.5,time))
			var light := wake*(.46+.54*(1.-smoothstep(.15,.64,age)))
			crystal_lights[i] = Vector3(stones[i].x,stones[i].y,light)
	visible=time>10.0
	queue_redraw()

func _pulse(time: float,onset: float,duration: float) -> float:
	var f := (time-onset)/duration
	return sin(f*PI) if f>0.0 and f<1.0 else 0.0

func _glow(point: Vector2,extent: Vector2,color: Color,alpha: float) -> void:
	if alpha<=.001: return
	draw_texture_rect(LIGHT,Rect2(point-extent*.5,extent),false,Color(color,alpha))

func _line(points: PackedVector2Array,alpha: float,width: float=1.7,bolt: bool=false) -> void:
	if alpha<=.001 or points.size()<2: return
	# A continuous ribbon with a smooth transverse falloff replaces hard strokes.
	var samples := PackedVector2Array([points[0]])
	var distances := PackedFloat32Array([0.0])
	var total := 0.0
	for i in range(1,points.size()):
		var length := points[i-1].distance_to(points[i])
		if length<.001: continue
		var steps := 1 if bolt else maxi(1,ceili(length/4.0))
		for j in range(1,steps+1):
			samples.append(points[i-1].lerp(points[i],float(j)/steps))
			distances.append(total+length*float(j)/steps)
		total+=length
	if samples.size()<2: return
	var closed := samples[0].distance_to(samples[-1])<.01
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var phase := points[0].x*.013+points[0].y*.019
	for i in samples.size():
		var before: Vector2=samples[maxi(0,i-1)]
		var after: Vector2=samples[mini(samples.size()-1,i+1)]
		if closed and (i==0 or i==samples.size()-1):
			before=samples[samples.size()-2]
			after=samples[1]
		var normal := (after-before).normalized().orthogonal()
		var taper := 1.0 if closed else smoothstep(0.0,4.0,minf(distances[i],total-distances[i]))
		for side in 2:
			var p := samples[i]+normal*width*4.5*(-1.0 if side==0 else 1.0)
			vertices.append(Vector3(p.x,p.y,0))
			uv.append(Vector2(distances[i]*.055+phase,(4.0 if bolt else 2.0)+side))
			colors.append(Color(1,1,1,alpha*taper))
		if i>0:
			var a := (i-1)*2
			indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_INDEX]=indices
	var ribbon := ArrayMesh.new()
	ribbon.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	ribbons.append(ribbon)
	draw_mesh(ribbon,null)

func _ellipse(center: Vector2,radius: Vector2,alpha: float,span: float=1.0) -> void:
	var points := PackedVector2Array()
	for i in range(65):
		var angle := TAU*float(i)/64.0*span
		points.append(center+Vector2(cos(angle),sin(angle))*radius)
	_line(points,alpha)

func _glyph(center: Vector2,index: int,alpha: float,size: float=9.0) -> void:
	var shape := PackedVector2Array()
	match index%3:
		0: shape=PackedVector2Array([Vector2(0,-1),Vector2(.65,0),Vector2(0,1),Vector2(-.65,0),Vector2(0,-1)])
		1: shape=PackedVector2Array([Vector2(-.7,.8),Vector2(0,-1),Vector2(.7,.8),Vector2(-.7,.8)])
		2: shape=PackedVector2Array([Vector2(-.65,-.8),Vector2(.65,.8),Vector2(0,0),Vector2(.65,-.8),Vector2(-.65,.8)])
	for i in shape.size(): shape[i]=center+shape[i]*size
	_line(shape,alpha,1.4)
	_line(PackedVector2Array([center+Vector2(0,-1.4)*size,center+Vector2(0,1.4)*size]),alpha*.75,1.0)
	_glow(center,Vector2.ONE*size*5,VIOLET,alpha*.22)

func _bolt(start: Vector2,finish: Vector2,seed: float,alpha: float,width: float) -> void:
	if alpha<=.005 or start.distance_squared_to(finish)<1.0: return
	var points := PackedVector2Array([start])
	var side := (finish-start).orthogonal().normalized()
	var amplitude := clampf(start.distance_to(finish)*.095,5.0,44.0)
	var tick := floorf(seconds*10.0)
	for i in range(1,29):
		var f := i/29.0
		var jag := sin(i*78.233+seed*31.13+tick*.003)*4375.54
		var displacement := (sin(seed*7.3+f*16.0)*.52+(fposmod(jag,1.0)*2.-1.)*.48)*amplitude*sin(PI*f)
		points.append(start.lerp(finish,f)+side*displacement)
	points.append(finish)
	_line(points,alpha,width,true)
	for branch_index in [9,20]:
		var root := points[branch_index]
		var tip := root+(finish-start)*.15+side*amplitude*(1.3 if branch_index==9 else -1.6)
		_line(PackedVector2Array([root,root.lerp(tip,.45)+side*6.0,tip]),alpha*.60,width*.5,true)

func _draw_discharge(index: int, settled: float) -> void:
	var stone := stones[index]
	var age := seconds-float(STRIKE_TIMES[index])
	if age < 0.0: return
	var hit := 1.0-smoothstep(.10,.55,age)
	if hit > 0.0:
		var source := Vector2(stone.x+SKY_OFFSETS[index],sky_top)
		var tip := source.lerp(stone,smoothstep(0.0,.08,age))
		_bolt(source,tip,index+1,hit,4.8)

	# Each struck facet holds a charge until the complete circuit discharges.
	var charge := smoothstep(.06,.13,age)*settled
	_glow(stone,Vector2(120,135),VIOLET,charge*(.60+.4*hit))
	_glow(stone,Vector2(34,43),PALE,charge*(.84+.16*cos(seconds*4+index)))
	var link := smoothstep(16.42+index*.18,16.75+index*.18,seconds)
	var rim := link*(1.0-smoothstep(18.28,19.5,seconds))
	if rim > 0.0:
		var neighbor := stones[(index+1)%stones.size()]
		_bolt(stone,stone.lerp(neighbor,link),index+12,rim*.9,2.8)
	var reach := smoothstep(18.42+index*.065,19.30+index*.065,seconds)
	if reach > 0.0:
		_bolt(stone,stone.lerp(MANIFESTATION_CENTER,reach),index+26,lightning_strength,3.6)

func _draw() -> void:
	ribbons.clear()
	if energy<=0.0: return
	if aerial: _draw_air()
	else: _draw_seal()

func _draw_seal() -> void:
	var reveal := smoothstep(10.0,13.5,seconds)
	var breathing := .8+.2*sin((seconds-10.0)*PI)
	_glow(CENTER,Vector2(320,155),VIOLET,.30*energy)
	# Trace the inlay in the orthographic Meshy bake.
	_ellipse(CENTER,Vector2(104,48),.65*energy*breathing,reveal)
	var diamond := PackedVector2Array([CENTER+Vector2(0,-32),CENTER+Vector2(47,0),CENTER+Vector2(0,32),CENTER+Vector2(-47,0),CENTER+Vector2(0,-32)])
	_line(diamond,.85*energy*reveal)
	for sign_y in [-1.0,1.0]:
		var eye := PackedVector2Array()
		for i in range(25):
			var f := i/24.0
			eye.append(CENTER+Vector2(lerpf(-27,27,f),sin(PI*f)*9*sign_y))
		_line(eye,energy*reveal)
	_ellipse(CENTER,Vector2(4,9),energy*reveal)
	for i in 8:
		var angle := TAU*i/8.0
		var point := CENTER+Vector2(cos(angle)*92,sin(angle)*43)
		_glow(point,Vector2(25,16),PALE,energy*(.25+.12*sin(seconds*3+i)))
	if seconds>=20.0 and seconds<22.0:
		var f := (seconds-20.0)/2.0
		_ellipse(CENTER,Vector2(104,48)*(1+2*f),pow(1-f,2)*.9)

func _draw_air() -> void:
	var settled := 1.0-smoothstep(20.8,23.0,seconds)
	# Six symbols rise above the ring while the stones gather light.
	for i in 6:
		var angle := TAU*i/6.0+.08*sin(seconds*.6)
		var reveal := smoothstep(11.5+i*.28,13.2+i*.28,seconds)
		var point := CENTER+Vector2(cos(angle)*167,sin(angle)*70-22-8*sin(seconds*1.4+i))
		_glyph(point,i,energy*reveal*settled,9.0)
	for i in stones.size():
		_draw_discharge(i,settled)
	# Stable analytic particles, no frame-dependent randomness or wall-clock time.
	for i in 36:
		var f := fposmod((seconds-10.0)*(.22+i*.001)+i*.618034,1.0)
		var angle := i*2.39996+seconds*.55
		var radius := lerpf(160,16,f)
		var point := CENTER+Vector2(cos(angle)*radius,sin(angle)*radius*.4-f*160*energy)
		var alpha := sin(PI*f)*energy*settled
		_glow(point,Vector2.ONE*(9+i%3*3),VIOLET,alpha*.7)
		draw_circle(point,1.2+f,Color(PALE,alpha),true,-1,true)
	var gathering := smoothstep(18.65,20.0,seconds)*(1.0-smoothstep(20.2,21.4,seconds))
	for strand in 3:
		var points := PackedVector2Array()
		for i in range(33):
			var f := i/32.0
			points.append(CENTER+Vector2(sin(f*TAU+seconds*2+strand*TAU/3)*28*sin(PI*f),-f*200))
		_line(points,gathering*.45,1.3)
	_glow(MANIFESTATION_CENTER,Vector2(160,290),VIOLET,gathering*.32)
	_glow(MANIFESTATION_CENTER,Vector2.ONE*140,VIOLET,lightning_strength*.95)
	_glow(MANIFESTATION_CENTER,Vector2.ONE*48,PALE,lightning_strength)
	if flash_strength>0.0:
		var epicenter := MANIFESTATION_CENTER
		_glow(epicenter,Vector2(480,440),VIOLET,flash_strength*.85)
		_glow(epicenter,Vector2(190,280),PALE,flash_strength*.9)
		for i in 12:
			var angle := TAU*i/12.0
			var direction := Vector2(cos(angle),sin(angle)*.8)
			_line(PackedVector2Array([epicenter+direction*24,epicenter+direction*(100+70*(seconds-20.0))]),flash_strength*.55,1.5)
