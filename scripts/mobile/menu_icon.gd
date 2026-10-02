extends RefCounted

static func centered(texture: Texture2D) -> Texture2D:
	var image: Image = texture.atlas.get_image() if texture is AtlasTexture else texture.get_image()
	if image == null:
		return texture
	if image.is_compressed():
		image.decompress()
	if texture is AtlasTexture:
		image = image.get_region(Rect2i(texture.region))
	var low := image.get_size()
	var high := Vector2i(-1, -1)
	# Ignore nearly transparent export fringes when measuring visible artwork.
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.15:
				low = low.min(Vector2i(x, y))
				high = high.max(Vector2i(x, y))
	if high.x < 0:
		return texture
	var result := AtlasTexture.new()
	result.atlas = texture
	result.region = Rect2(low, high - low + Vector2i.ONE)
	if texture is AtlasTexture:
		result.atlas = texture.atlas
		result.region.position += texture.region.position
	result.filter_clip = true
	return result
