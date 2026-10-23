extends SceneTree

## Offline inventory of reusable local shapes, never a room-sized painted asset.
const GRID = preload("res://scripts/wireframe_cell_layout.gd")
const TERMINALS := {"w14_p00_e00": "north", "w13_p00_e00": "east",
	"w11_p00_e00": "south", "w07_p00_e00": "west"}
const DOOR_VARIANTS := {"north": "w10_p00_e00", "south": "w10_p00_e00",
	"east": "w05_p00_e00", "west": "w05_p00_e00"}
var contexts: Dictionary = {}


func _initialize() -> void:
	_export.call_deferred()


func _export() -> void:
	for file in DirAccess.get_files_at("res://scenes"):
		if not file.ends_with(".tscn") or file in ["DungeonHeart.tscn", "DungeonTorch.tscn"]:
			continue
		var scene: Node = load("res://scenes/" + file).instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		_collect(scene, file)
		root.remove_child(scene)
		scene.free()
	var output := FileAccess.open("res://docs/reference/painted-scene-contexts.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"purpose": "Offline local context inventory", "contexts": contexts}, "\t") + "\n")
	print("Exported ", contexts.size(), " local painted contexts")
	quit()


func _collect(node: Node, scene_name: String) -> void:
	if node.has_method("get_connection_plan"):
		var plan: Dictionary = node.get_connection_plan()
		var cells: Dictionary = plan.cells
		var specials: Dictionary = {}
		var ids: Dictionary = {}
		for cell: Vector2i in cells:
			var variant := GRID.variant(cell, cells, plan.openings)
			ids[cell] = "cells/" + variant
			if node.door_cells.has(cell):
				var direction: String = node.door_cells[cell]
				if DOOR_VARIANTS.get(direction, "") == variant:
					specials[cell] = "doors/" + direction
			if not specials.has(cell) and node.entrance_at_closed_ends and TERMINALS.has(variant):
				specials[cell] = "entrances/" + TERMINALS[variant]
			if specials.has(cell):
				ids[cell] = specials[cell]
		for cell: Vector2i in cells:
			var key := GRID.context_key(cell, cells, plan.openings, specials)
			if contexts.has(key):
				if not contexts[key].scenes.has(scene_name):
					contexts[key].scenes.append(scene_name)
				continue
			var tiles: Array = []
			for offset: Vector2i in [Vector2i.ZERO] + GRID.DIRECTIONS + GRID.DIAGONALS:
				if ids.has(cell + offset):
					tiles.append({"x": offset.x, "y": offset.y, "id": ids[cell + offset]})
			contexts[key] = {"tiles": tiles, "scenes": [scene_name]}
	for child in node.get_children():
		_collect(child, scene_name)
