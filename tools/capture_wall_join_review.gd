extends SceneTree

## Human review capture of prepared PNGs. No assertions or generated geometry.
const FOLDER := "res://docs/reference/wall-join-review/"
const STUDIES := {
	"horizontal": [["w01_p00_e08", 0, 0], ["w01_p00_e02", 1, 0]],
	"vertical-corner": [["w08_p00_e01", 0, 0], ["w12_p00_e00", 0, 1], ["w04_p00_e02", 1, 1]],
}

func _initialize() -> void:
	_capture.call_deferred()

func _capture() -> void:
	RenderingServer.set_default_clear_color(Color("#080d16"))
	for study in STUDIES:
		for zoom in [1, 2]:
			var viewport := SubViewport.new()
			viewport.size = Vector2i(560, 352 if study == "horizontal" else 608) * zoom
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			for cell in STUDIES[study]:
				var image := Image.load_from_file(FOLDER + study + "/" + cell[0] + ".png")
				image.generate_mipmaps()
				var sprite := Sprite2D.new()
				sprite.texture = ImageTexture.create_from_image(image)
				sprite.centered = false
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				sprite.scale = Vector2.ONE * float(zoom) / 4.0
				sprite.position = Vector2(cell[1], cell[2]) * 256.0 * zoom
				viewport.add_child(sprite)
			await process_frame
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(FOLDER + study + "-godot-" + str(zoom) + "x.png")
			root.remove_child(viewport)
			viewport.free()
		print("Captured prepared join sprites: ", study)
	quit()
