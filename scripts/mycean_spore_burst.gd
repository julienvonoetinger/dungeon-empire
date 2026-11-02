@tool
extends Node2D
## Charge, detached spore comet or impact bloom. All phase comes from the action clock.
const SOFT := preload("res://assets/dungeon/mobile-kit/light-falloff.png")
const ORB := preload("res://shaders/mycean_spore_orb.gdshader")
enum Kind { CHARGE, FLIGHT, IMPACT }
var kind := Kind.CHARGE
var seconds := 0.0
var progress := 0.0
var origin := Vector2.ZERO
var target := Vector2.ZERO
var orb: Sprite2D

func _ready() -> void:
	orb = Sprite2D.new()
	orb.texture = SOFT
	var ink := ShaderMaterial.new()
	ink.shader = ORB
	orb.material = ink
	add_child(orb)
	refresh()

func path_at(t: float) -> Vector2:
	return origin.lerp(target,t)+Vector2.UP*sin(PI*t)*12.0

func refresh() -> void:
	if orb == null: return
	var radius := 30.0
	match kind:
		Kind.CHARGE:
			position = origin
			radius *= .15+.85*progress
		Kind.FLIGHT:
			position = path_at(progress)
		Kind.IMPACT:
			position = target
			radius = 30.0+46.0*progress
	orb.scale = Vector2.ONE*radius*2.0/SOFT.get_width()
	orb.modulate.a = minf(progress*4,1) if kind == Kind.CHARGE else 1.0
	orb.material.set_shader_parameter("phase",seconds)
	orb.material.set_shader_parameter("burst",progress if kind == Kind.IMPACT else 0.0)
	queue_redraw()

func _glow(point: Vector2, radius: float, tint: Color) -> void:
	draw_texture_rect(SOFT,Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2),false,tint)

func _mote(point: Vector2, radius: float, alpha: float) -> void:
	_glow(point,radius*3.6,Color(.10,.85,.57,alpha*.55))
	draw_circle(point,radius,Color(.70,1,.72,alpha),true,-1,true)

func _draw() -> void:
	if kind == Kind.CHARGE:
		for i in 13:
			var t := fposmod(seconds*1.7+float(i)/13.0,1.0)
			var angle := float(i)*2.39996+seconds*3.5
			var radius := lerpf(30,7,t)
			var point := Vector2(cos(angle),sin(angle)*.7)*radius
			_mote(point,.6+1.0*t,sin(PI*t)*progress)
		# Two curling, incomplete filaments wrap the growing orb, not a rune ring.
		for strand in 2:
			var points := PackedVector2Array()
			for i in 23:
				var a := seconds*4+float(strand)*PI+float(i)*.09
				points.append(Vector2(cos(a),sin(a)*.65)*(9+5*progress))
			draw_polyline(points,Color(.38,1,.70,.7*progress),1.2,true)
	elif kind == Kind.FLIGHT:
		# Short trailing spores only: never a persistent connection to the staff.
		for i in range(1,17):
			var lag := float(i)*.011
			if progress<lag: continue
			var weight := 1.0-float(i)/17.0
			var point := path_at(progress-lag)-position
			point += Vector2(cos(i*2.4+seconds*11),sin(i*2.4+seconds*11))*4.5*(1-weight)
			_glow(point,3+7*weight,Color(.06,.72,.5,.22*weight))
			_mote(point,.5+1.1*weight,.8*weight)
	elif kind == Kind.IMPACT:
		var fade := pow(1-progress,1.6)
		for i in 21:
			var angle := float(i)*2.39996
			var reach := (18.0+40.0*progress)*(0.6+0.4*sin(i*3.1)*sin(i*3.1))
			var point := Vector2(cos(angle),sin(angle)*.8)*reach
			point.y += 10*progress*progress
			_mote(point,(1.0+float(i%3)*.45)*(1-progress*.6),fade)
		for i in 7:
			var angle := float(i)*TAU/7+.4
			var points := PackedVector2Array()
			for step in 9:
				var t := float(step)/8
				var r := (12+43*progress)*t
				points.append(Vector2(cos(angle+t*.55),sin(angle+t*.55)*.8)*r)
			draw_polyline(points,Color(.45,1,.72,fade*.8),1.1,true)
