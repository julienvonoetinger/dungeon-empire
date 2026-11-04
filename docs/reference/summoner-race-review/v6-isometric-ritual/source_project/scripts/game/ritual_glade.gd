extends Node3D
## All lengths are in the same 3D space as the imported skinned Oculin.
const Glade = preload("res://assets/game/introduction/ritual-glade.glb")
const Presence = preload("res://shaders/ritual_presence.gdshader")
const Inscription = preload("res://shaders/ritual_inscription.gdshader")
var camera := Camera3D.new()
var rift := Node3D.new()
var entity := Node3D.new()
var aperture := MeshInstance3D.new()
var broken_halo := Node3D.new()
var magic := OmniLight3D.new()
var stone_ink := ShaderMaterial.new()
var shadow_skin := ShaderMaterial.new()
var player: AnimationPlayer
var dust: MultiMeshInstance3D
var aspect := 1.6
var invocation: StringName

func _ready() -> void:
	var glade := Glade.instantiate()
	add_child(glade)
	var weathered := ShaderMaterial.new()
	weathered.shader = preload("res://shaders/ritual_weathering.gdshader")
	glade.get_node("Stone").material_override = weathered
	for label in ["Etching","Glow"]:
		var prop: MeshInstance3D = glade.get_node(label)
		var painted: StandardMaterial3D = prop.mesh.surface_get_material(0).duplicate()
		painted.vertex_color_use_as_albedo = true
		prop.material_override = painted
	player = glade.find_children("*","AnimationPlayer",true,false)[0]
	for clip in player.get_animation_list():
		if "Invocation" in clip: invocation = clip
	player.play(invocation)
	player.pause()
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("#273641")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#c1bbd0")
	world.environment.ambient_light_energy = .46
	world.environment.ambient_light_sky_contribution = 0.0
	world.environment.fog_enabled = true
	world.environment.fog_light_color = Color("#53536b")
	world.environment.fog_density = .009
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color("#c8d5f6")
	moon.light_energy = .77
	moon.shadow_enabled = true
	moon.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	moon.directional_shadow_max_distance = 30
	add_child(moon)
	moon.look_at_from_position(Vector3(-5,8,2),Vector3.ZERO)
	for pos in [Vector3(-1.8,.8,1.5),Vector3(1.7,.8,-1.7)]:
		var fire := OmniLight3D.new()
		fire.position = pos
		fire.light_color = Color("#ffae58")
		fire.light_energy = 1.3
		fire.omni_range = 4.5
		add_child(fire)
	magic.light_color = Color("#b979ff")
	magic.omni_range = 4.0
	magic.position.y = 1.1
	add_child(magic)
	camera.name = "RitualCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	add_child(camera)
	_create_ritual()
	set_moment(0.)

func _mesh(parent: Node3D, shape: Mesh, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape
	item.material_override = material
	parent.add_child(item)
	return item

func _glow(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	return mat

func _create_ritual() -> void:
	stone_ink.shader = Inscription
	var disc := PlaneMesh.new()
	disc.size = Vector2.ONE*4.36
	var inlay := _mesh(self,disc,stone_ink)
	inlay.position.y = .178
	inlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rift)
	add_child(entity)
	shadow_skin.shader = Presence
	var skin := SphereMesh.new()
	skin.radial_segments = 40
	skin.rings = 24
	_mesh(entity,skin,shadow_skin).scale = Vector3(.75,.96,.72)
	# The slit and its pupil are raised geometry on the entity's front.
	entity.rotation.y = PI*.25
	var eye := _mesh(entity,skin,_glow(Color("#ffceeb")))
	eye.position = Vector3(0,.072,.337)
	eye.scale = Vector3(.33,.098,.077)
	var iris := _mesh(entity,skin,_glow(Color("#5b154b")))
	iris.position = Vector3(0,.073,.376)
	iris.scale = Vector3(.033,.083,.019)
	rift.add_child(broken_halo)
	aperture.mesh = skin
	aperture.material_override = shadow_skin
	broken_halo.add_child(aperture)
	aperture.scale = Vector3(1.14,1.78,.15)
	var crystal := PrismMesh.new()
	crystal.size = Vector3(.13,.32,.15)
	var shard := StandardMaterial3D.new()
	shard.albedo_color = Color("#9771ab")
	shard.metallic = .50
	shard.roughness = .27
	shard.emission_enabled = true
	shard.emission = Color("#361241")
	for i in 13:
		var piece := _mesh(broken_halo,crystal,shard)
		var a := TAU*i/13.
		piece.position = Vector3(cos(a)*.63,sin(a)*.89,0)
		piece.rotation.z = a-PI*.5
	broken_halo.rotation.y = PI*.29
	# Sparks are drawn in one submission and orbit at different heights.
	dust = MultiMeshInstance3D.new()
	dust.multimesh = MultiMesh.new()
	dust.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var spark := SphereMesh.new()
	spark.radial_segments = 6
	spark.rings = 3
	dust.multimesh.mesh = spark
	dust.multimesh.instance_count = 40
	dust.material_override = _glow(Color("#ffcf96"))
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)

func set_moment(t: float, descent := 0.0) -> void:
	var charge := smoothstep(.0,1.5,t)
	var born := smoothstep(1.0,2.5,t)
	var fade := 1.-descent
	player.seek(minf(t,player.current_animation_length),true)
	var focus := Vector3(.35,-.08,.35)
	camera.look_at_from_position(focus+Vector3(8,6.532,8),focus)
	camera.size = maxf(5.85,5.55/maxf(.25,aspect))*(1.025-.045*charge-.13*descent)
	stone_ink.set_shader_parameter("power",(.18+.82*charge)*fade)
	stone_ink.set_shader_parameter("clock_time",t)
	shadow_skin.set_shader_parameter("clock_time",t)
	var emerge := smoothstep(1.62,3.1,t)
	rift.position = Vector3(-.36,1.10,-.36)
	rift.scale = Vector3.ONE*maxf(.002,charge*fade*(1.-.93*emerge))
	broken_halo.rotation.z = .13*sin(t*.83)
	entity.position.x = lerpf(-.30,.30,emerge)
	entity.position.z = entity.position.x
	entity.position.y = (.99+.11*sin(t*1.7))*fade+.14
	entity.scale = Vector3.ONE*maxf(.002,born*(1.-descent*.94))
	magic.light_energy = (.1+.94*charge+.11*sin(t*5.))*fade
	for i in dust.multimesh.instance_count:
		var f := fposmod(i*.618+t*.23,1.)
		var a := i*2.40+t*.62+f*1.3
		var radius := (1.7-.97*f)*fade
		var pos := Vector3(cos(a)*radius,.18+f*(1.4+.24*sin(i)),sin(a)*radius)
		var size := .025*sin(f*PI)*charge*fade+.001
		dust.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*size),pos))
