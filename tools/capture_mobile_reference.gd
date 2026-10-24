extends "res://tools/capture_mobile_kit.gd"
## Compatibility entry point; current output is docs/reference/mobile-kit/captures.
func _scene_names() -> PackedStringArray:
	var names := OS.get_cmdline_user_args()
	return names if not names.is_empty() else PackedStringArray(["MobileReference"])
