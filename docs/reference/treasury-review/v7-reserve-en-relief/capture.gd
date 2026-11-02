extends "res://docs/reference/treasury-review/v6-textures/capture.gd"
const VOLUME := "res://docs/reference/treasury-review/v7-reserve-en-relief/"
var pieces: Dictionary
func review_directory() -> String:
	return VOLUME
func capture() -> void:
	pieces = JSON.parse_string(FileAccess.get_file_as_string(review_directory()+"reserve.json"))
	await super.capture()
func save(title: String) -> void:
	if title.ends_with("-kit"):
		# The V6 review already contains this identical ordinary-kit baseline.
		await process_frame
		return
	var frame: Array = pieces[title].frame
	var sprite := Sprite2D.new()
	var img := Image.load_from_file(review_directory()+"sprites/"+title+".webp")
	check(img != null and img.get_size()==Vector2i(frame[2],frame[3]),title+" registered reserve image")
	img.generate_mipmaps()
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = view.grid_to_local(view.START)+Vector2(frame[0],frame[1])
	# The shot uses the same static walls as the offline depth pass. The
	# visible contents and received shadows are already masked for this slot.
	sprite.z_index = 2
	view._world.add_child(sprite)
	await super.save(title)
	sprite.queue_free()
