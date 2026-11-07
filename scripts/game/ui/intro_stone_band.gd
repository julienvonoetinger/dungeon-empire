extends Control
## The narration and speaker strips share one continuous painted stone surface.
const STONE = preload("res://assets/ui/master/stone-menu/dialogue-stone.webp")
const STONE_OPACITY := .68

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var paint: Vector2 = STONE.get_size()
	var zoom := maxf(1.5, maxf(size.x / paint.x, size.y / paint.y))
	var sample := size / zoom
	draw_texture_rect_region(STONE, Rect2(Vector2.ZERO, size), Rect2((paint-sample)*.5, sample), Color(1,1,1,STONE_OPACITY))
	draw_rect(Rect2(0,0,size.x,2.), Color("4c72a1"))
