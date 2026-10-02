extends RefCounted

static var _libraries: Dictionary = {}

static func prepare(model: Node3D) -> void:
	for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
		for library_name in player.get_animation_library_list():
			var source := player.get_animation_library(library_name)
			var key := "%s:%s" % [model.scene_file_path, library_name]
			if not _libraries.has(key):
				var library := source.duplicate(true) as AnimationLibrary
				for clip in library.get_animation_list():
					var animation := library.get_animation(clip)
					animation.loop_mode = Animation.LOOP_NONE
					for track in animation.get_track_count():
						var path := animation.track_get_path(track)
						if animation.track_get_type(track) != Animation.TYPE_POSITION_3D or path.get_subname_count() == 0 or path.get_subname(0) != &"Hips":
							continue
						if animation.track_get_key_count(track) == 0:
							continue
						var start: Vector3 = animation.track_get_key_value(track, 0)
						for frame in animation.track_get_key_count(track):
							var position: Vector3 = animation.track_get_key_value(track, frame)
							# Grid motion owns horizontal travel; retain the imported jump height.
							position.x = start.x
							position.z = start.z
							animation.track_set_key_value(track, frame, position)
				_libraries[key] = library
			player.remove_animation_library(library_name)
			player.add_animation_library(library_name, _libraries[key])
		var clips := player.get_animation_list()
		if not clips.is_empty():
			player.speed_scale = player.get_animation(clips[0]).length / GameTypes.TRAP_JUMP_TIME
