extends SceneTree

const PROBES := preload("res://tests/probes/node_probes.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for script in ["res://scripts/world/vulpin_hero.gd", "res://scripts/world/batrafian_hero.gd"]:
		var hero = load(script).new()
		root.add_child(hero)
		hero.set_jumping(true)
		var model := PROBES.child(hero, "JumpTrap") as Node3D
		var player := PROBES.first_animation_player(model)
		var animation := player.get_animation(player.current_animation)
		print(script, " clip=", player.current_animation, " duration=", animation.length)
		for track in animation.get_track_count():
			if animation.track_get_type(track) != Animation.TYPE_POSITION_3D:
				continue
			var low := Vector3(INF, INF, INF)
			var high := Vector3(-INF, -INF, -INF)
			for key in animation.track_get_key_count(track):
				var value: Vector3 = animation.track_get_key_value(track, key)
				low = low.min(value)
				high = high.max(value)
			if (high - low).length() > 0.05:
				print("position ", animation.track_get_path(track), " low=", low, " high=", high)
		var skeleton := PROBES.first_skeleton(model)
		var hips := skeleton.find_bone("Hips")
		var first_position := Vector3.ZERO
		for step in 5:
			player.seek(animation.length * step / 4.0, true)
			var position: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(hips).origin
			if step == 0:
				first_position = position
			print("sample=", step, " hips_world=", position)
			if "--verify" in OS.get_cmdline_user_args():
				assert(Vector2(position.x - first_position.x, position.z - first_position.z).length() < 0.01, "Jump animation must not add horizontal travel to the grid movement")
		hero.free()
	quit()
