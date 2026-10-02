extends SceneTree

func _initialize() -> void:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(7, 20, 16, 24), Color.WHITE)
	var source := ImageTexture.create_from_image(image)
	var centered = preload("res://scripts/mobile/menu_icon.gd").centered(source)
	assert(centered.region == Rect2(7, 20, 16, 24))
	assert(centered.atlas == source)
	var nested := AtlasTexture.new()
	nested.atlas = source
	nested.region = Rect2(0, 16, 32, 32)
	var cropped = preload("res://scripts/mobile/menu_icon.gd").centered(nested)
	assert(cropped.region == Rect2(7, 20, 16, 24))
	assert(cropped.atlas == source)
	var atlas := load("res://assets/mobile/command-atlas-v1.png") as Texture2D
	for index in [0, 11]:
		var item := AtlasTexture.new()
		item.atlas = atlas
		item.region = Rect2(Vector2(index % 4, index / 4) * Vector2(atlas.get_width() / 4.0, atlas.get_height() / 3.0), Vector2(atlas.get_width() / 4.0, atlas.get_height() / 3.0))
		var icon = preload("res://scripts/mobile/menu_icon.gd").centered(item)
		print(index, " bounds ", icon.region, " size ", icon.get_size())
	print("OK: visible icon bounds, including atlas regions")
	quit()
