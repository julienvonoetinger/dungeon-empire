extends Node2D
## Presentation of the approved whole-character sheets. The raid owns all
## actions, movement, damage and timing; this node never advances the simulation.
const Types = preload("res://scripts/game/game_types.gd")
const Stairs = preload("res://scripts/game/stair_traversal.gd")
const REGISTRATION = preload("res://assets/heroes/vulpin/registration.tres")
const FRAMES := {
	"idle": preload("res://assets/previews/vulpin-idle/frames.tres"),
	"walk": preload("res://assets/previews/vulpin-walk/frames.tres"),
	"run": preload("res://assets/previews/vulpin-run/frames.tres"),
	"hurt": preload("res://assets/previews/vulpin-hurt/frames.tres"),
	"lockpick": preload("res://assets/previews/vulpin-lockpick/frames.tres"),
	"chest_lockpick": preload("res://assets/previews/vulpin-chest-lockpick/frames.tres"),
	"chest_open": preload("res://assets/previews/vulpin-chest-open/frames.tres"),
	"death": preload("res://assets/previews/vulpin-death/frames.tres"),
}
const CONTACT = preload("res://assets/dungeon/mobile-kit/light-falloff.png")
const HERO_SCALE := .85
const ANCHOR := Vector2(128,195.92598)
const FACINGS := {Vector2i.RIGHT:"se", Vector2i.DOWN:"sw", Vector2i.LEFT:"nw", Vector2i.UP:"ne"}
const CHEST_FACINGS := {"west":"se", "north":"sw", "east":"nw", "south":"ne"}
const NORMALS := {"se":Vector2.LEFT, "sw":Vector2.UP, "nw":Vector2.RIGHT, "ne":Vector2.DOWN}
var sprite: AnimatedSprite2D
var shadow: Sprite2D
var label: Label
var state := "idle"
var facing := "se"
var grid_position := Vector2.ZERO
var elevation := 0.0
var stair_cell := Vector2i(-1,-1)
var _was_exiting := false
var _stair_exit_from := Vector2.ZERO
var contact_target := Vector2.ZERO
var contact_offset := Vector2.ZERO
var health := 1.0
var _identity := ""
var _last_hp := -1
var _last_time := -1.0
var _hurt_at := -100.0
var _step := ""
var _step_from := Vector2.ZERO
var _action := ""
var _action_at := 0.0
var _action_from := Vector2.ZERO
var _interaction_position := Vector2.ZERO
var _holding_interaction := false
var _corpse := false

func _ready() -> void:
	shadow = Sprite2D.new()
	shadow.name = "Contact"
	shadow.texture = CONTACT
	shadow.modulate = Color(0,0,0,.5)
	shadow.z_index = -1
	shadow.scale = Vector2(38,19)/CONTACT.get_size()
	add_child(shadow)
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.centered = false
	sprite.scale = Vector2.ONE*HERO_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	label = Label.new()
	label.position = Vector2(-110,-177)
	label.size = Vector2(220,28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",17)
	label.add_theme_color_override("font_color",Color("f4e5bd"))
	label.add_theme_color_override("font_outline_color",Color("101522"))
	label.add_theme_constant_override("outline_size",6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 10
	add_child(label)
	_set_pose("idle","se",0)

static func direction(vector: Vector2i) -> String:
	return FACINGS.get(vector,"se")

func _set_pose(next_state: String, next_facing: String, seconds: float) -> void:
	state = next_state
	facing = next_facing
	sprite.sprite_frames = FRAMES[state]
	sprite.animation = StringName(facing)
	sprite.offset = -Vector2(sprite.sprite_frames.get_meta("ground_anchor", ANCHOR))
	var frames: SpriteFrames = sprite.sprite_frames
	var fps := 15.0 if state == "walk" else frames.get_animation_speed(sprite.animation)
	var duration := 0.0
	for i in frames.get_frame_count(sprite.animation): duration += frames.get_frame_duration(sprite.animation,i)/fps
	var t := fposmod(maxf(0,seconds),duration) if frames.get_animation_loop(sprite.animation) else maxf(0,seconds)
	var frame := frames.get_frame_count(sprite.animation)-1
	for i in frames.get_frame_count(sprite.animation):
		var hold := frames.get_frame_duration(sprite.animation,i)/fps
		if t < hold-.000001:
			frame = i
			break
		t -= hold
	sprite.set_frame_and_progress(frame,0)

func _interaction(view: Node, hero: Dictionary, next_state: String) -> Dictionary:
	var cell: Vector2i = hero.get("collect_vault",hero.pos) if next_state == "chest_open" else hero.lockpick_pos
	var face := direction(hero.get("facing",Vector2i.RIGHT))
	if next_state != "lockpick": face = CHEST_FACINGS[view.chest_facings[cell].facing]
	var data: Dictionary = REGISTRATION.get_meta(next_state)
	var registration: Dictionary = data.directions[face]
	var anchor := Vector2(registration.anchor[0],registration.anchor[1])
	var center := Vector2(cell)+Vector2(.5,.5)
	var target: Vector2
	var offset: Vector2
	if next_state == "chest_open":
		var grip: Dictionary = registration.grips[int(data.contactFrame)]
		offset = (Vector2(grip.R[0]+grip.L[0],grip.R[1]+grip.L[1])*.5-anchor)*HERO_SCALE
		target = view.grid_to_local(center+NORMALS[face]*.16,data.gripHeight)
	else:
		offset = (Vector2(registration.lock[0],registration.lock[1])-anchor)*HERO_SCALE
		if next_state == "lockpick":
			target = view.grid_to_local(center+NORMALS[face]*.025,data.lockHeight)
		else:
			var painted: Array = registration.chestLock.local
			target = view.grid_to_local(center)+Vector2(painted[0],painted[1])
	var at: Vector2 = view.local_to_grid(target-offset)
	if next_state != "lockpick" and not view.chest_facings[cell].accessible:
		# Dense storage is legal even if every adjoining tile contains a chest.
		# Its fallback-facing lock has no reachable standing space: keep the
		# complete pose envelope on this walkable tile instead of crossing a wall.
		# This is a best-effort gesture, not exact hand/lock contact in that layout.
		var low := Vector2.ZERO
		var high := Vector2.ZERO
		for bounds in registration.bounds:
			low = low.min(Vector2(bounds.min[0],bounds.min[1]))
			high = high.max(Vector2(bounds.max[0],bounds.max[1]))
		at = at.clamp(Vector2(cell)-low,Vector2(cell)+Vector2.ONE-high)
	return {"facing":face,"target":target,"offset":offset,"at":at,"key":next_state+str(cell)}

func sync(hero: Dictionary, raid: RaidDirector, view: Node) -> void:
	var now := raid.elapsed_seconds
	var identity := str(raid.raid_index)+":"+str(hero.get("id",hero.get("name","")))
	var fresh := identity != _identity or now < _last_time
	if fresh:
		_identity = identity
		_last_hp = int(hero.hp)
		_hurt_at = float(hero.get("hurt_started_at",-100.0))
		_step = ""
		_action = ""
		_holding_interaction = false
		_was_exiting = false
		_last_time = -1.0
	# At 2x a hit may occur in the first simulation substep. Its recorded time
	# prevents presentation from restarting a late recoil after movement resumes.
	if int(hero.hp) < _last_hp: _hurt_at = float(hero.get("hurt_started_at",now))
	_last_hp = int(hero.hp)
	var face := direction(hero.get("facing",Vector2i.RIGHT))
	var next_state := "idle"
	var animation_time := now
	var at := Vector2(hero.pos)+Vector2(.5,.5)
	var moving := false
	if hero.has("move_from") and hero.has("step_started_at"):
		var progress := clampf((now-float(hero.step_started_at))/Types.TURN_TIME,0,1)
		var step_key := str(hero.step_started_at)+str(hero.move_from)+str(hero.pos)
		if step_key != _step:
			_step = step_key
			_step_from = grid_position if _holding_interaction else Vector2(hero.move_from)+Vector2(.5,.5)
			_holding_interaction = false
		at = _step_from.lerp(at,progress)
		moving = progress < 1
	if _holding_interaction: at = _interaction_position
	var jump := 0.0
	if hero.get("jumping_trap",false):
		var progress := clampf(1-float(hero.jump_t)/Types.TRAP_JUMP_TIME,0,1)
		at = (Vector2(hero.jump_from)+Vector2(.5,.5)).lerp(Vector2(hero.pos)+Vector2(.5,.5),progress)
		jump = sin(progress*PI)*40
		moving = true
	if hero.get("entering",false) or hero.get("exiting",false):
		moving = true
	if moving: next_state = "run" if hero.get("fleeing",false) or hero.get("jumping_trap",false) else "walk"
	if now-_hurt_at < Types.VULPIN_HURT_HOLD: next_state = "hurt"; animation_time = now-_hurt_at
	if hero.get("lockpicking",false):
		var p: Vector2i = hero.lockpick_pos
		next_state = "chest_lockpick" if view.session.sim.grid[p.y][p.x] == Types.Tile.VAULT else "lockpick"
		animation_time = RaidDirector.VULPIN_LOCKPICK_HOLD-float(hero.lockpick_t)
	elif hero.get("collecting_gold",false):
		next_state = "chest_open"
		animation_time = Types.VULPIN_COLLECT_HOLD-float(hero.collect_t)
	var action := ""
	if next_state in ["lockpick","chest_lockpick","chest_open"]:
		var interaction := _interaction(view,hero,next_state)
		action = interaction.key
		if action != _action:
			_action_at = now
			_action_from = at if fresh else grid_position
		contact_target = interaction.target
		contact_offset = interaction.offset
		_interaction_position = interaction.at
		_holding_interaction = true
		at = _action_from.lerp(interaction.at,clampf((now-_action_at)/.18,0,1))
		face = interaction.facing
	_action = action
	if hero.get("dying",false) or int(hero.hp) <= 0:
		next_state = "death"
		animation_time = RaidDirector.VULPIN_DYING_HOLD-float(hero.get("dying_t",RaidDirector.VULPIN_DYING_HOLD))
		jump = 0
	_set_pose(next_state,face,animation_time)
	var exiting: bool = hero.get("exiting",false)
	# A door can directly adjoin the entrance. Preserve the held lockpick contact
	# when retreat starts there, instead of teleporting back to the stair centre.
	if exiting and not _was_exiting: _stair_exit_from = at
	_was_exiting = exiting
	var stairs := Stairs.sample(view.session.sim,hero,at,_stair_exit_from)
	at = stairs.at
	elevation = stairs.elevation
	stair_cell = stairs.stair
	modulate.a = stairs.opacity
	grid_position = at
	position = view.grid_to_local(at,elevation)
	sprite.position.y = -jump
	sprite.modulate.a = clampf(float(hero.get("portal_t",1))/raid.portal_hold,0,1) if hero.get("void_absorbing",false) else 1.0
	shadow.modulate.a = sprite.modulate.a*.5
	health = clampf(float(hero.hp)/maxf(1,float(hero.get("max_hp",hero.hp))),0,1)
	label.text = "%s · Lv. %d" % [hero.get("name","Vulpin"),hero.get("level",1)]
	label.visible = next_state != "death"
	label.position.y = -177-jump
	_update_shadow()
	_last_time = now
	queue_redraw()

func _update_shadow() -> void:
	var blend := clampf((sprite.frame-4.0)/5.0,0,1) if state == "death" else 0.0
	var forward: Vector2 = {"se":Vector2(1,.5),"sw":Vector2(-1,.5),"nw":Vector2(-1,-.5),"ne":Vector2(1,-.5)}[facing]
	shadow.position = forward*blend*18
	shadow.rotation = forward.angle() if blend>0 else 0.0
	shadow.scale = Vector2(lerpf(38,125,blend),lerpf(19,42,blend))/CONTACT.get_size()

func set_corpse(at: Vector2, face: String, view: Node) -> void:
	_corpse = true
	modulate.a = 1
	_set_pose("death",face,100)
	grid_position = at
	position = view.grid_to_local(at)
	label.hide()
	_update_shadow()
	queue_redraw()

func support() -> Dictionary:
	var bounds := {"min":[-.16,-.16,0],"max":[.16,.16,.86]}
	var known: Dictionary = REGISTRATION.get_meta("bounds")
	if known.has(state): bounds = known[state][sprite.frame][facing]
	elif REGISTRATION.has_meta(state): bounds = REGISTRATION.get_meta(state).directions[facing].bounds[sprite.frame]
	elif state == "death": bounds = {"min":[-.35,-.35,0],"max":[.35,.35,.20]}
	var origin := Vector3(grid_position.x,grid_position.y,elevation)
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	return {"node":self,"id":"vulpin","at":grid_position,"stair":stair_cell,
		"min":origin+Vector3(bounds.min[0],bounds.min[1],bounds.min[2]),
		"max":origin+Vector3(bounds.max[0],bounds.max[1],bounds.max[2]),
		"rect":Rect2(position+sprite.position+sprite.offset*HERO_SCALE,texture.get_size()*HERO_SCALE),
		"depth":(grid_position.x+grid_position.y)*.6123724356957945}

func _draw() -> void:
	if _corpse or state == "death": return
	var y := -147.0+sprite.position.y if sprite else -147.0
	draw_line(Vector2(-24,y),Vector2(24,y),Color("161e2a"),6)
	draw_line(Vector2(-24,y),Vector2(-24+48*health,y),Color("80d6a0"),4)
