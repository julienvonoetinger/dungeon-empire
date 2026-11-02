extends "res://docs/reference/treasury-review/v6-textures/renderer.gd"

func module_image(id: String) -> Image:
	if id.begins_with("sol-"):
		return Image.load_from_file("res://docs/reference/treasury-review/v8-coffre-et-cuir/sprites/"+id+".png")
	return super.module_image(id)
