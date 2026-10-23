# Generated offline by tools/export_wireframe_doors.cjs. Complete connected door textures.
extends RefCounted
const CELL_PIXELS := 256.0
const ANCHOR := Vector2(24, 128)
const TEXTURES := {
	"north": preload("res://assets/dungeon/wireframe-doors/north.svg"),
	"east": preload("res://assets/dungeon/wireframe-doors/east.svg"),
	"south": preload("res://assets/dungeon/wireframe-doors/south.svg"),
	"west": preload("res://assets/dungeon/wireframe-doors/west.svg"),
}
const VARIANTS := {
	"north": "w10_p00_e00",
	"east": "w05_p00_e00",
	"south": "w10_p00_e00",
	"west": "w05_p00_e00",
}
