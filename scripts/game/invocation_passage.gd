extends "res://scripts/game/invocation_magic.gd"
## Physical rock fracture and stairwell, sampled only from the film clock.
const STAIR=preload("res://assets/game/introduction/stairwell-v2/stairs.png")
const FOREGROUND=preload("res://assets/game/introduction/stairwell-v2/foreground.png")
const APERTURE=preload("res://assets/game/introduction/stairwell-v2/aperture.png")
const ARCH=preload("res://assets/game/introduction/stairwell-v2/arch.png")
const GATE_CENTER:=Vector2(64,-352) # Top step, ground level: grid (.5,2,0).
var opening:=0.0
var charge:=0.0
var source:=Vector2.ZERO
var impact:=Vector2.ZERO
var wall: Sprite2D
var wall_shadow: Sprite2D
var stairs:=Sprite2D.new()
var rubble:=Node2D.new()
var fragments: Array[Polygon2D]=[]
var fragment_origins: Array[Vector2]=[]
var geometry: Dictionary
var reveal_material:=ShaderMaterial.new()
var occlusion_material:=ShaderMaterial.new()
var invoker_occlusion: ShaderMaterial

func bind_wall(rock: Sprite2D) -> void:
	wall=rock
	var scenery:=wall.get_parent()
	geometry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/game/introduction/stairwell-v2/geometry.json"))
	for stone_name in geometry.sceneryOffsets:
		var shift: Array=geometry.sceneryOffsets[stone_name]
		for suffix in ["","Ombre"]:
			var stone:=scenery.get_node_or_null(stone_name+suffix)
			if stone: stone.position+=Vector2(shift[0],shift[1])
	wall_shadow=scenery.get_node_or_null("Paroi4Ombre")
	var ink:=wall.texture.get_image().get_used_rect()
	impact=wall.position+wall.offset+Vector2(ink.position)+Vector2(ink.size)*Vector2(.5,.55)
	stairs.name="PhysicalStairwell"
	stairs.texture=STAIR
	stairs.centered=false
	stairs.position=Vector2(geometry.mouth[0],geometry.mouth[1])
	stairs.offset=Vector2(geometry.frame[0],geometry.frame[1])
	reveal_material.shader=preload("res://shaders/invocation_stair_reveal.gdshader")
	stairs.material=reveal_material
	scenery.add_child(stairs)
	scenery.move_child(stairs,wall.get_index())
	rubble.name="BreakingRock"
	rubble.position=wall.position+wall.offset
	scenery.add_child(rubble)
	scenery.move_child(rubble,wall.get_index()+1)
	_make_fragments()
	occlusion_material.shader=preload("res://shaders/invocation_stair_occlusion.gdshader")
	occlusion_material.set_shader_parameter("masonry",FOREGROUND)
	occlusion_material.set_shader_parameter("aperture",APERTURE)
	occlusion_material.set_shader_parameter("arch",ARCH)
	occlusion_material.set_shader_parameter("stair_origin",stairs.position+stairs.offset)
	occlusion_material.set_shader_parameter("stair_extent",Vector2(STAIR.get_size()))
	invoker_occlusion=occlusion_material.duplicate()
	present(0.)

func _make_fragments() -> void:
	# A shared jittered grid partitions the original rock without missing pixels.
	var extent:=Vector2(wall.texture.get_size())
	var points: Array[Vector2]=[]
	for y in 7:
		for x in 7:
			var jitter:=Vector2(sin(x*17.1+y*13.7),cos(x*11.9-y*9.2))*.24
			if x==0 or x==6: jitter.x=0.
			if y==0 or y==6: jitter.y=0.
			points.append((Vector2(x,y)+jitter)*extent/6.)
	for y in 6:
		for x in 6:
			var uv:=PackedVector2Array([points[y*7+x],points[y*7+x+1],points[(y+1)*7+x+1],points[(y+1)*7+x]])
			var center: Vector2=(uv[0]+uv[1]+uv[2]+uv[3])*.25
			var shape:=PackedVector2Array()
			for p in uv: shape.append(p-center)
			var piece:=Polygon2D.new()
			piece.texture=wall.texture
			piece.uv=uv
			piece.polygon=shape
			var thickness:=Polygon2D.new()
			thickness.texture=wall.texture
			thickness.uv=uv
			thickness.polygon=shape
			thickness.position=Vector2(3.,5.)
			thickness.color=Color(.43,.4,.47)
			thickness.show_behind_parent=true
			piece.add_child(thickness)
			rubble.add_child(piece)
			fragments.append(piece)
			fragment_origins.append(center)

func present(time: float) -> void:
	seconds=time
	opening=smoothstep(27.0,29.0,time)
	charge=smoothstep(24.5,26.0,time)*(1.0-smoothstep(27.5,29.0,time))
	visible=time>24.5 and time<30.5
	if material: material.set_shader_parameter("effect_time",time)
	if is_instance_valid(wall):
		wall.visible=time<=26.
		stairs.visible=time>27.
		reveal_material.set_shader_parameter("reveal",opening)
		rubble.visible=time>26. and time<28.8
		if wall_shadow:
			wall_shadow.visible=time<28.
			wall_shadow.modulate.a=1.-smoothstep(26.,28.,time)
		for i in fragments.size():
			var age:=maxf(0.,time-26.-float(i%6)*.025)
			var origin:=fragment_origins[i]
			var outward: Vector2=(origin-Vector2(wall.texture.get_size())*.5).normalized()
			var velocity:=outward*Vector2(74,24)+Vector2(sin(i*5.2)*24,-38-24*fposmod(i*.618,1.))
			fragments[i].position=origin+velocity*age+Vector2(0,96*age*age)
			fragments[i].rotation=sin(i*3.8)*age*.58
			fragments[i].scale=Vector2.ONE*(1.-.24*smoothstep(0.,2.4,age))
			fragments[i].modulate=Color(1.,1.,1.,1.-smoothstep(1.35,2.6,age))
	queue_redraw()

static func project_stair(point: Vector3) -> Vector2:
	return Vector2(256,-512)+Vector2((point.x-point.y)*128.,(point.x+point.y)*64.-point.z*156.767343538)

func master_ground(time: float) -> Vector2:
	if time<=31.:
		var progress:=smoothstep(28.8,31.,time)
		var path:=PackedVector2Array([Vector2(-6,54),Vector2(-6,-170),GATE_CENTER])
		return preload("res://scripts/game/invocation_paths.gd").sample(path,progress)
	var progress:=smoothstep(31.,33.2,time)
	var y:=lerpf(2.,.34,progress)
	var z: float=-clampf((1.94-y)/1.60,0.,1.)*.5
	if time>33.2:
		y=lerpf(.34,-.25,smoothstep(33.2,34.,time))
		z=-.5
	return project_stair(Vector3(.5,y,z))

func mask_master(sprite: Sprite2D,root_position: Vector2,time: float) -> void:
	sprite.material=occlusion_material
	var extent:=Vector2(sprite.texture.get_size())*sprite.scale
	occlusion_material.set_shader_parameter("sprite_origin",root_position+sprite.position-extent*.5)
	occlusion_material.set_shader_parameter("sprite_extent",extent)
	occlusion_material.set_shader_parameter("descending",smoothstep(30.8,31.2,time))
	occlusion_material.set_shader_parameter("behind_arch",smoothstep(33.26,33.4,time))
	occlusion_material.set_shader_parameter("tunnel",smoothstep(33.26,33.5,time))

func mask_invoker(actor: Node2D,time: float) -> void:
	var sprite: Sprite2D=actor.sprite
	sprite.material=invoker_occlusion
	invoker_occlusion.set_shader_parameter("sprite_origin",actor.position+sprite.offset*actor.scale)
	invoker_occlusion.set_shader_parameter("sprite_extent",Vector2(256,256)*actor.scale)
	invoker_occlusion.set_shader_parameter("region_origin",sprite.region_rect.position/Vector2(sprite.texture.get_size()))
	invoker_occlusion.set_shader_parameter("region_extent",Vector2(256,256)/Vector2(sprite.texture.get_size()))
	invoker_occlusion.set_shader_parameter("descending",smoothstep(30.8,31.2,time))
	invoker_occlusion.set_shader_parameter("behind_arch",smoothstep(33.26,33.4,time))
	invoker_occlusion.set_shader_parameter("tunnel",smoothstep(33.26,33.5,time))

func _draw() -> void:
	ribbons.clear()
	if charge>0.:
		_glow(impact,Vector2(220,240),VIOLET,charge*.17)
		var casting:=smoothstep(24.5,25.7,seconds)*(1.-smoothstep(26.,27.4,seconds))
		for strand in 3:
			var points:=PackedVector2Array()
			for i in 41:
				var f:=i/40.
				var p:=source.lerp(impact,f)
				p+=Vector2(sin(f*9.-seconds*2.2+strand*2.1)*18.,sin(f*6.+seconds+strand)*7.)*sin(PI*f)
				points.append(p)
			_line(points,casting*.44,2.1)
		_glow(impact,Vector2(310,250),PALE,_pulse(seconds,25.9,.4)*.55)
	var gathering:=sin(PI*smoothstep(26.8,28.8,seconds))
	_glow(source,Vector2(130,160),VIOLET,gathering*.28)
	var dust:=smoothstep(26.,26.4,seconds)*(1.-smoothstep(28.,30.2,seconds))
	for i in 18:
		var drift:=maxf(0.,seconds-26.)
		var angle:=i*2.4
		var p:=impact+Vector2(cos(angle)*75.,sin(angle)*44.)+Vector2(cos(angle)*drift*27.,drift*20.)
		_glow(p,Vector2(70,54)*(1.+drift*.25),Color(.48,.43,.44),dust*.16)
