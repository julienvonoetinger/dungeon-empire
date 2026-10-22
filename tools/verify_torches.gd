extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var dungeon = scene.get_node("Dungeon")
	var torches := find_torches(dungeon)
	check(torches.size() == 2,"Two actual torch sprites replace the atlas cutouts")
	for part: Sprite2D in dungeon.get_surface_pieces():
		check(not str(part.name).begins_with("Entry_Torch"),"The old polygon torch is removed")
	if torches.size() == 2:
		for i in range(2):
			var torch := torches[i]
			check(torch.material == null,"No shader or polygon mask on the torch")
			check(torch.position == Vector2(430+232*i,454),"Fixed foot anchor on the entrance wall")
			check(torch.scale == Vector2(0.48,0.48),"Uniform scale preserves generated proportions")
			check(torch.offset == Vector2(-128,-321) and not torch.centered,"Sprite origin is the foot")
			check(torch.z_index == 4 and torch.light_mask == 1,"Sprite sits above facade and keeps painted colors")
			check(torch.texture.resource_path == "res://assets/dungeon/torches/torch-violet-v1.png","Approved generated PNG is used")
			check(torch.texture.get_size() == Vector2(256,384),"Runtime import is bounded to 256 x 384")
		check(torches[0].texture == torches[1].texture,"Both torches share one texture")
		var pixels: Image = torches[0].texture.get_image()
		check(pixels.get_pixel(0,0).a == 0.0,"PNG background is truly transparent")
		check(pixels.get_pixel(128,260).a > 0.95,"Torch support remains opaque")
		var old_ids := torches.map(func(t: Sprite2D): return t.get_instance_id())
		dungeon.refresh_preview()
		await process_frame
		await process_frame
		torches = find_torches(dungeon)
		check(torches.size() == 2,"Rebuild does not duplicate sprites")
		check(torches.all(func(t: Sprite2D): return t.get_instance_id() not in old_ids),"Rebuild replaces generated sprites")
		var local_layout: Resource = dungeon.layout.duplicate()
		dungeon.layout = local_layout
		local_layout.entrance_enabled = false
		dungeon._rebuild()
		check(find_torches(dungeon).is_empty(),"Disabling entrance removes torch sprites")
		local_layout.entrance_enabled = true
		dungeon._rebuild()
		check(find_torches(dungeon).size() == 2,"Restoring entrance creates exactly two sprites")
	scene.queue_free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("Torch sprite regression: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)

func find_torches(dungeon: Node) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for child in dungeon.get_children():
		if child is Sprite2D and str(child.name).begins_with("EntryTorch"):
			result.append(child)
	return result

func check(condition: bool,message: String) -> void:
	if not condition:
		failures.append(message)
