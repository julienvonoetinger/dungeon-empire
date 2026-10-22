extends RefCounted

## Shared deterministic tint/variant selection for the complete alpha sprites.
const FLOOR_TONES: Array[Color] = [
	Color.WHITE,Color.WHITE,Color(0.94,0.96,1.0),Color(0.84,0.86,0.90),
	Color(1.10,1.08,1.05),Color(0.98,0.95,1.0),Color(0.94,0.98,1.0),
	Color(1.02,1.02,1.04)
]
const WALL_TONES: Array[Color] = [
	Color.WHITE,Color.WHITE,Color.WHITE,Color(0.94,0.96,1.0),
	Color(0.92,0.94,0.97),Color(1.03,1.02,1.0),Color(0.98,0.96,1.0)
]

static func sample(x: int,y: int,seed_value: int,salt: int) -> int:
	# Integer-only local sampling: no global RNG state, time or traversal order.
	var value: int = (posmod(seed_value,104729)+x*92821+y*68917+salt*31337)&0x7fffffff
	value = ((value^(value>>13))*1274126177)&0x7fffffff
	return value^(value>>16)

static func choose(x: int,y: int,seed_value: int,salt: int,count: int,previous: int = -1) -> int:
	if count <= 1:
		return 0
	var choice := sample(x,y,seed_value,salt)%count
	if choice == previous:
		choice = (choice+1+sample(x,y,seed_value,salt+101)%(count-1))%count
	return choice

static func floor_tint(column: int,row: int,seed_value: int) -> Color:
	return FLOOR_TONES[sample(column,row,seed_value,47)%FLOOR_TONES.size()]

static func wall_tint(position: Vector2,seed_value: int) -> Color:
	return WALL_TONES[sample(int(position.x),int(position.y),seed_value,83)%WALL_TONES.size()]
