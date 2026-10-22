extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var scene = load("res://scenes/SixRoomPreview.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var snapshot = load("res://scripts/dungeon_probes.gd").inspect(scene.get_node("Dungeon"))
	print("Elements ",snapshot.elements.size()," probes ",snapshot.probes.size()," failures ",snapshot.failures.size())
	for p in snapshot.failures:
		print(p.id," ",p.position," ",p.actual_id," ",p.message)
	quit()
