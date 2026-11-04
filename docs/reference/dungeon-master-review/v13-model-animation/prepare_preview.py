"""Derive isolated playback UI from the established preview; leave it intact."""
from pathlib import Path
root=Path(__file__).parents[4]
source=(root/'scripts/previews/energy_master_preview.gd').read_text(encoding='utf8')
source=source.replace('res://scripts/previews/energy_master.gd','res://scripts/previews/meshy_master.gd')
source=source.replace('const DURATION := 24.0','const DURATION := 18.0')
source=source.replace('var paused := false','var paused := false\nvar speed := 1.0')
source=source.replace('gaze_button','speed_button')
source=source.replace('Maître du donjon · Prototype d’énergie','Maître du donjon · Animation Meshy 3D')
source=source.replace('Noyau noir · vortex · regard','Modèles Meshy · Animation 3D')
source=source.replace('camera.size = 5.2','camera.size = 8.8')
source=source.replace('camera.near = 0.05','camera.near = 0.05')
source=source.replace('speed_button.text = "Regard"\n\tspeed_button.toggle_mode = true\n\tspeed_button.toggled.connect(func(_value): _present())',
    'speed_button.text = "1×"\n\tspeed_button.pressed.connect(func(): set_speed(0.5 if speed >= 2.0 else speed + 0.5))')
source=source.replace('set_time(fposmod(clock+delta,DURATION))',
    'set_time(minf(clock+delta*speed,DURATION))\n\t\tif clock >= DURATION: set_paused(true)')
source=source[:source.index('func _present() -> void:')]+'''func set_speed(value: float) -> void:
	speed = clampf(value,0.5,2.0)
	speed_button.text = "%s×" % str(speed)

func _present() -> void:
	if not is_instance_valid(entity): return
	entity.present(clock)
	var angle := deg_to_rad(view_angle)
	if orbit_button.button_pressed: angle += sin(clock*0.22)*0.48
	camera.position = Vector3(sin(angle)*9.0,0.4,cos(angle)*9.0)
	camera.look_at(Vector3.ZERO)
	var phase := "Présence"
	if clock < 3.0: phase = "La volute se déploie"
	elif clock < 8.0: phase = "L’œil grandit"
	status.text = "%s · %.1f / 18 s" % [phase,clock]
'''
source=source.replace('viewport.add_child(world_environment)','''viewport.add_child(world_environment)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b8acd0")
	environment.ambient_light_energy = 0.7
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(-0.35,-0.4,0.0)
	key.light_energy = 1.4
	viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(0.2,2.6,0.0)
	fill.light_energy = 0.6
	viewport.add_child(fill)''')
(root/'scripts/previews/meshy_master_preview.gd').write_text(source,encoding='utf8')
print('MESHY_PREVIEW_WRITTEN')
