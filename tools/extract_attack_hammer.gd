extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var model: Node3D = load("res://assets/models/characters/lithide/hero_lithide_paladin_attack_forward.glb").instantiate()
	root.add_child(model)
	var hammer := model.find_child("AttackHammer", true, false) as MeshInstance3D
	var skeleton := hammer.get_node(hammer.skeleton) as Skeleton3D
	var hand := skeleton.find_bone("LeftHand")
	var bind := -1
	for i in hammer.skin.get_bind_count():
		if hammer.skin.get_bind_name(i) == &"LeftHand" or hammer.skin.get_bind_bone(i) == hand:
			bind = i
			break
	assert(bind >= 0, "Missing left hand bind")
	var item := Node3D.new()
	item.name = "GildedStonehammer"
	var mesh := MeshInstance3D.new()
	mesh.name = "HammerMesh"
	mesh.mesh = hammer.mesh.duplicate(true)
	mesh.transform = hammer.skin.get_bind_pose(bind)
	item.add_child(mesh)
	mesh.owner = item
	var mesh_path := "res://assets/models/characters/lithide/attack_hammer_mesh.res"
	assert(ResourceSaver.save(mesh.mesh, mesh_path) == OK)
	mesh.mesh = load(mesh_path)
	var packed := PackedScene.new()
	assert(packed.pack(item) == OK)
	assert(ResourceSaver.save(packed, "res://assets/models/characters/lithide/attack_hammer.tscn") == OK)
	print("Extracted rigid hammer; bind ", bind, " transform ", mesh.transform)
	item.free()
	model.queue_free()
	quit()
