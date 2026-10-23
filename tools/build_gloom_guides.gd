extends SceneTree
## Geometry input for ImageGen, never rendered as game art.
const OUT := "res://docs/reference/"
const V := Vector2(16,96)
const S := 1.5
const TOP := "#3d4b69"
const FRONT := "#27334d"
const SIDE := "#1d273b"
var items: Array[Dictionary] = []

func _initialize() -> void:
	var h := [Vector2(-59.5,-32),Vector2(59.5,-32),Vector2(59.5,32),Vector2(-59.5,32)]
	var v := [Vector2(-32,-64),Vector2(32,-64),Vector2(32,64),Vector2(-32,64)]
	for i in 4:
		items.append({"id":"h%d" % i,"top":h,"ports":[0,2]})
	for i in 4:
		items.append({"id":"v%d" % i,"top":v,"ports":[1,3]})
	items.append({"id":"es","top":[Vector2(-32,-32),Vector2(59.5,-32),Vector2(59.5,32),Vector2(32,32),Vector2(32,64),Vector2(-32,64)],"ports":[0,1]})
	items.append({"id":"ws","top":[Vector2(-59.5,-32),Vector2(32,-32),Vector2(32,64),Vector2(-32,64),Vector2(-32,32),Vector2(-59.5,32)],"ports":[2,1]})
	items.append({"id":"en","top":[Vector2(-32,-64),Vector2(32,-64),Vector2(32,-32),Vector2(59.5,-32),Vector2(59.5,32),Vector2(-32,32)],"ports":[0,3]})
	items.append({"id":"wn","top":[Vector2(-32,-64),Vector2(32,-64),Vector2(32,32),Vector2(-59.5,32),Vector2(-59.5,-32),Vector2(-32,-32)],"ports":[2,3]})
	# Ends attach to an east/south/west/north run respectively.
	items.append({"id":"end_e","top":h,"ports":[0]})
	items.append({"id":"end_s","top":v,"ports":[1]})
	items.append({"id":"end_w","top":h,"ports":[2]})
	items.append({"id":"end_n","top":v,"ports":[3]})
	var svg := _start()
	var metadata := {"contract":"dungeon-parallel-v1","canvas":[1536,1536],"source_scale":S,"slots":{}}
	for index in items.size():
		var entry: Dictionary = items[index]
		var offset := Vector2(index % 4 * 384 + 192, index / 4 * 384 + 128)
		svg += _volume(entry.top,entry.ports,offset)
		metadata.slots[entry.id] = {"region":[index%4*384,index/4*384,384,384],"anchor":[offset.x,offset.y]}
	_save("gloom-walls-guide",svg)
	var json_file := FileAccess.open("res://assets/dungeon/gloom-kit/geometry.json",FileAccess.WRITE)
	json_file.store_string(JSON.stringify(metadata,"  "))
	var floor_svg := _start()
	for index in 12:
		var column: int = index % 3
		var offset := Vector2(column*512+256,index/3*384+192)
		var half := Vector2([119.0,178.5,238.0][column],128.0)*0.7
		floor_svg += _poly([offset-half,offset+Vector2(half.x,-half.y),offset+half,offset+Vector2(-half.x,half.y)],"#414f6a")
	_save("gloom-floors-guide",floor_svg)
	quit()

func _start() -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" width="1536" height="1536" viewBox="0 0 1536 1536">\n'

func _poly(points: Array, color: String) -> String:
	var text := PackedStringArray()
	for point: Vector2 in points:
		text.append("%.2f,%.2f" % [point.x,point.y])
	return '<polygon points="%s" fill="%s" stroke="#090e18" stroke-width="3" stroke-linejoin="round"/>\n' % [" ".join(text),color]

func _port(a: Vector2,b: Vector2,ports: Array) -> bool:
	return (0 in ports and a.x == 59.5 and b.x == 59.5) or (2 in ports and a.x == -59.5 and b.x == -59.5) or (1 in ports and a.y == 64 and b.y == 64) or (3 in ports and a.y == -64 and b.y == -64)

func _volume(top: Array,ports: Array,offset: Vector2) -> String:
	var faces: Array[Dictionary] = []
	for index in top.size():
		var a: Vector2 = top[index]
		var b: Vector2 = top[(index+1)%top.size()]
		var edge := b-a
		if edge.cross(V)<0 and not _port(a,b,ports):
			faces.append({"y":maxf(a.y,b.y),"svg":_poly([offset+a*S,offset+b*S,offset+(b+V)*S,offset+(a+V)*S],SIDE if edge.y>0 else FRONT)})
	faces.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.y<b.y)
	var result := ""
	for face in faces:
		result += face.svg
	var points: Array[Vector2] = []
	for point: Vector2 in top:
		points.append(offset+point*S)
	return result+_poly(points,TOP)

func _save(stem:String,svg:String)->void:
	svg += "</svg>"
	var file:=FileAccess.open(OUT+stem+".svg",FileAccess.WRITE)
	file.store_string(svg)
	var rendered:=Image.new()
	rendered.load_svg_from_string(svg)
	rendered.save_png(OUT+stem+".png")
