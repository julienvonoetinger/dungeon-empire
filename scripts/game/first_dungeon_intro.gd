extends CanvasLayer
## Each introduction uses the live map. Only the three playable lessons are saved.
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Types = preload("res://scripts/game/game_types.gd")
const Film = preload("res://scripts/game/invocation_sanctuary.gd")
const Dialogue = preload("res://scripts/game/invocation_dialogue.gd")
enum Shot { CLOSED, PROLOGUE, RITUAL, ENTRANCE, LESSON }
const ENTRY_DURATION := 9.0
const Stairs = preload("res://scripts/game/stair_traversal.gd")
const PROLOGUE := [
	["À l’écart du monde", "Au cœur des montagnes, les Oculins vivaient dans un village dissimulé entre les falaises. Ils avaient aménagé les pentes pour leurs cultures et bâti leurs maisons dans la pierre. Depuis des générations, ils vivaient ainsi, sans contact avec les autres peuples. Leur village ne figurait sur aucune carte. Aucun royaume ne connaissait leur existence.", "res://assets/game/introduction/prologue-basalt.webp", "res://assets/game/introduction/prologue-basalt-portrait.webp"],
	["La découverte", "Au pied des montagnes s’étendait le royaume de Valdorne. Son souverain, le roi Aldren, voulait ouvrir une route vers les terres de l’autre versant. Il envoya un cartographe et deux éclaireurs reconnaître les cols. Depuis une crête, ils découvrirent le village des Oculins. Le cartographe dessina les maisons, les sentiers et le passage qu’elles dominaient.", "res://assets/game/introduction/prologue-lookout.webp", "res://assets/game/introduction/prologue-lookout-portrait.webp"],
	["L’audience", "À la cour, le cartographe présenta son dessin à Aldren. Le roi l’interrogea sur les habitants et les chemins menant au col. Les trois voyageurs n’avaient observé le village que de loin. Ils ignoraient qui étaient ces êtres et s’ils accepteraient des visiteurs. Aldren envoya un émissaire et quelques gardes demander l’ouverture d’une route à travers leurs terres.", "res://assets/game/introduction/prologue-audience.webp", "res://assets/game/introduction/prologue-audience-portrait.webp"],
	["Les étrangers", "À l’approche des envoyés, les Oculins barrèrent l’entrée du village. Jamais ils n’avaient rencontré de tels êtres. L’émissaire leur parla de Valdorne, de son roi et de la route qu’il souhaitait ouvrir. Les anciens refusèrent de le laisser poursuivre. « Ces montagnes sont notre foyer. Nous ne céderons aucune terre. Vos gens ne passeront pas. » Les envoyés repartirent sous leur surveillance.", "res://assets/game/introduction/prologue-envoy.webp", "res://assets/game/introduction/prologue-envoy-portrait.webp"],
	["Le passage fermé", "À leur retour, les envoyés rapportèrent le refus des Oculins. Ceux-ci avaient fermé les sentiers et montaient désormais la garde aux abords du col. Aldren voulait cette route pour étendre son royaume de l’autre côté des montagnes. Il décida de l’ouvrir par la force. Son capitaine reçut l’ordre de prendre le passage et d’y établir une garnison.", "res://assets/game/introduction/prologue-decree.webp", "res://assets/game/introduction/prologue-decree-portrait.webp"],
	["L’attaque", "Lorsque les bannières de Valdorne apparurent dans la vallée, les Oculins transportèrent des provisions vers les grottes et renforcèrent leurs barricades. Les soldats forcèrent le passage. Le combat gagna les ruelles, où ils incendièrent les maisons pour en déloger les défenseurs. Les Oculins durent abandonner le village. Les survivants se replièrent dans les hauteurs en emportant leurs blessés.", "res://assets/game/introduction/prologue-assault.webp", "res://assets/game/introduction/prologue-assault-portrait.webp"],
	["Les survivants", "Les rescapés se regroupèrent dans les grottes. On pansa les blessés et partagea les provisions mises à l’abri. Jusqu’à la nuit, des survivants continuèrent d’arriver. Puis les sentiers restèrent vides. À l’entrée du refuge, les Oculins veillèrent longtemps, espérant encore voir apparaître ceux qui manquaient. En contrebas, leurs maisons brûlaient.", "res://assets/game/introduction/prologue-pass.webp", "res://assets/game/introduction/prologue-pass-portrait.webp"],
	["Les terres occupées", "Quelques jours plus tard, des Oculins redescendirent observer les ruines. Les soldats avaient dressé une palissade autour du village. Des ouvriers démolissaient les maisons encore debout pour en réemployer les pierres. La forteresse d’Aldren commençait à s’élever sur leurs terres. Les éclaireurs regagnèrent les grottes avec cette nouvelle. Là-haut, les provisions diminuaient et le froid s’installait.", "res://assets/game/introduction/prologue-occupation.webp", "res://assets/game/introduction/prologue-occupation-portrait.webp"],
	["Le sanctuaire interdit", "Au refuge, un ancien révéla l’existence d’un sanctuaire caché dans les hauteurs. Les ancêtres des Oculins en avaient interdit l’accès : un dieu du mal pouvait y être invoqué. L’ancien connaissait encore le rite. « Il peut nous donner la force de vaincre. Mais nous devrons le servir. » Après une nuit de débats, les survivants décidèrent de s’y rendre.", "res://assets/game/introduction/prologue-council.webp", "res://assets/game/introduction/prologue-council-portrait.webp"],
	["Votre royaume", "L’ancien les guida jusqu’à une gorge étroite. Là, à l’abri des regards, des pierres dressées entouraient une dalle gravée. Il s’avança au centre du sanctuaire et prononça votre nom. « Nous vous offrons notre fidélité. Donnez-nous la force de renverser Aldren. Sous la montagne, nous bâtirons votre royaume. » Autour de lui, les Oculins s’agenouillèrent. Leur appel venait de vous atteindre.", "res://assets/game/introduction/prologue-oath.webp", "res://assets/game/introduction/prologue-oath-portrait.webp"],
]
const TITLES := ["", "Fermez le passage", "Creusez une alcôve", "Installez votre trésor"]
const LINES := ["", "« Maître… depuis l’escalier, on voit votre Cœur. »", "« Nos richesses méritent mieux que la poussière du couloir. »", "« Ici, votre or sera à sa place. »"]
const ACTIONS := ["", "Poser la porte · %d or" % Types.COST_DOOR, "Creuser la roche · %d or" % Types.COST_DIG, "Poser un coffre"]
const TOOLS := [Types.Tool.NONE, Types.Tool.BUILD_DOOR, Types.Tool.DIG, Types.Tool.STORE]

@onready var session: IsometricGameSession = get_parent()
@onready var hud: CanvasLayer = session.get_node("HUD")
@onready var view: Node2D = session.get_node("PlayArea/World/Dungeon")
@onready var camera: Camera2D = session.get_node("PlayArea/World/Camera2D")
var shot := Shot.CLOSED
var elapsed := 0.0
var root := ColorRect.new()
var story := TextureRect.new()
var page := 0
var film := Film.new()
var veil := ColorRect.new()
var dialogue := Dialogue.new()
var panel := PanelContainer.new()
var skip: Button
var title: Label
var reading_area := ScrollContainer.new()
var line: Label
var action: Button
var target: Button
var invoker: Node2D
var invoker_at:=Vector2.ZERO
var dungeon_master: Sprite2D
var arrival_light: Sprite2D
var needs_focus := false
var focus_cell := Vector2.ZERO
var unit := 1.0

func _ready() -> void:
	hide()
	add_child(root)
	root.color = Color.TRANSPARENT
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.create()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(story)
	story.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	story.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story.hide()
	root.add_child(film)
	film.hide()
	root.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dialogue)
	target = UI.button(root, "◆", _act, "", true)
	target.accessibility_name = "Agir sur la case indiquée"
	root.add_child(panel)
	panel.add_theme_stylebox_override("panel",UI.surface("panel",12))
	var box := VBoxContainer.new()
	panel.add_child(box)
	title = UI.label(box,"",24,UI.GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(reading_area)
	reading_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.slim_scrollbar(reading_area)
	line = UI.label(reading_area,"",20)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	action = UI.button(box,"",_act,"",true)
	skip = UI.button(root,"Passer",_skip)
	for button in [action, skip]:
		button.add_theme_font_size_override("font_size",18)
	root.resized.connect(_layout)
	panel.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	skip.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	session.introduction_started.connect(func(): _set_shot(Shot.PROLOGUE))
	session.changed.connect(_sync)
	set_process(false)

func _sync(_structure: bool) -> void:
	if session.sim.lesson == Types.Lesson.FREE:
		if shot != Shot.CLOSED: _set_shot(Shot.CLOSED)
		return
	if shot == Shot.CLOSED: _set_shot(Shot.LESSON)
	elif shot == Shot.LESSON: _show_lesson()
	visible = not session.paused and not session.confirmation_open
	hud.visible = not visible

func _set_shot(next: int) -> void:
	_clear_master_arrival()
	shot = next
	dialogue.present("", 0.)
	view.set_core_awakening(1.0 if shot in [Shot.CLOSED,Shot.LESSON] else 0.0)
	view.set_core_cinematic_time(-1.0 if shot in [Shot.CLOSED,Shot.LESSON] else 0.0)
	elapsed = 0
	visible = shot != Shot.CLOSED and not session.paused
	hud.visible = not visible
	set_process(shot != Shot.CLOSED)
	if is_instance_valid(invoker) and next != Shot.LESSON:
		invoker.queue_free()
		invoker = null
	panel.visible = shot in [Shot.PROLOGUE, Shot.LESSON]
	if shot != Shot.RITUAL: film.release()
	story.visible = shot == Shot.PROLOGUE
	reading_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if story.visible else ScrollContainer.SCROLL_MODE_DISABLED
	root.color = UI.INK if story.visible else Color.TRANSPARENT
	if not story.visible: story.texture = null
	veil.color = Color.TRANSPARENT
	target.visible = shot == Shot.LESSON
	action.visible = shot in [Shot.PROLOGUE, Shot.LESSON]
	skip.text = "Jouer librement" if shot == Shot.LESSON else "Passer"
	match shot:
		Shot.CLOSED:
			session.get_node("Input").center_core()
		Shot.PROLOGUE:
			skip.text = "Passer le récit"
			_show_page(0)
		Shot.RITUAL:
			film.modulate.a = 1.
			film.present(0.)
		Shot.ENTRANCE:
			_ensure_master_arrival()
			_walk_in(0.)
		Shot.LESSON: _show_lesson()
	_layout()

func _show_page(index: int) -> void:
	page = index
	elapsed = 0
	var entry: Array = PROLOGUE[page]
	title.text = "%d / %d   ·   %s" % [page+1, PROLOGUE.size(), entry[0]]
	line.text = entry[1]
	reading_area.scroll_vertical = 0
	action.text = "Répondre à l’appel" if page == PROLOGUE.size()-1 else "Poursuivre"
	action.disabled = false
	veil.color = Color(.028,.013,.045,.85)
	_layout()

func _lesson_cell() -> Vector2i:
	return Types.FIRST_DOOR if session.sim.lesson == Types.Lesson.DOOR else Types.FIRST_ALCOVE

func _ensure_invoker() -> void:
	if is_instance_valid(invoker) and not invoker.is_queued_for_deletion(): return
	invoker = Film.Actor.new()
	invoker.is_invoker=true
	invoker.scale = Vector2.ONE*.95
	invoker.z_index=1

func _ensure_master_arrival() -> void:
	if is_instance_valid(dungeon_master): return
	dungeon_master=Sprite2D.new()
	dungeon_master.texture=film.master_view.get_texture()
	dungeon_master.offset=Vector2(0,-235)
	dungeon_master.scale=Vector2.ONE*.38
	dungeon_master.z_index=1
	arrival_light=Sprite2D.new()
	arrival_light.texture=Film.LIGHT
	arrival_light.scale=Vector2(190,95)/Vector2(Film.LIGHT.get_size())
	arrival_light.modulate=Color(.55,.16,1.,0.)
	view.add_child(arrival_light)

func _clear_master_arrival() -> void:
	if is_instance_valid(dungeon_master): dungeon_master.queue_free()
	if is_instance_valid(arrival_light): arrival_light.queue_free()
	dungeon_master=null
	arrival_light=null

func _show_lesson() -> void:
	_ensure_invoker()
	invoker.modulate.a = 1
	view.position_invoker(invoker,_invoker_destination())
	invoker_at=_invoker_destination()
	invoker.present_direction("idle",0,"se")
	var step := session.sim.lesson
	title.text = "%d / 3   ·   %s" % [step, TITLES[step]]
	line.text = LINES[step] if session.save_error.is_empty() else session.save_error
	action.text = ACTIONS[step]
	action.disabled = false
	_focus(Vector2(_lesson_cell()) + Vector2(.5,.5))
	needs_focus = true
	_layout()

func _act() -> void:
	if not visible or session.paused: return
	if shot == Shot.PROLOGUE:
		if page+1 < PROLOGUE.size(): _show_page(page+1)
		else: _set_shot(Shot.RITUAL)
	elif shot == Shot.LESSON:
		session.selected = _lesson_cell()
		session.confirm_action(TOOLS[session.sim.lesson])

func _skip() -> void:
	if not visible or session.paused: return
	match shot:
		Shot.PROLOGUE: _set_shot(Shot.RITUAL)
		Shot.RITUAL, Shot.ENTRANCE: _set_shot(Shot.LESSON)
		Shot.LESSON: session.leave_tutorial()

func _entrance_top() -> Vector2:
	return Vector2(Types.FIRST_STAIR) + Vector2(.5,.5) - Vector2(session.sim._entrance_mouth(Types.FIRST_STAIR)) * Stairs.TOP_TRAVEL

func _invoker_destination() -> Vector2:
	return Vector2(Types.core_origin_cell()) + Vector2(-.5,.5)

func _walk_in(progress: float) -> void:
	_ensure_master_arrival()
	var time := progress*ENTRY_DURATION
	dialogue.present("entrance", time)
	view.set_core_cinematic_time(time)
	var start := _entrance_top()
	var travel := smoothstep(.5,6.5,time)
	var at := start.lerp(Vector2(Types.core_origin_cell())+Vector2(.5,.5),travel)
	film.master.rotation.y=PI*.25
	film.master.present(fposmod(time,6.))
	film.master_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var awakening := smoothstep(6.6,8.6,time)
	view.set_core_awakening(awakening)
	dungeon_master.modulate.a=smoothstep(.2,1.1,time)*(1.-awakening)
	var core_center:=Vector2(Types.core_origin_cell())+Vector2(.5,.5)
	var rise:=1.-smoothstep(.65,1.35,at.distance_to(core_center))
	# Rise before crossing the stone caps, then converge toward the awakening orb.
	dungeon_master.scale=Vector2.ONE*lerpf(.38,.22,awakening)
	view.position_intro_master(dungeon_master,at,lerpf(.38,.31,awakening)*rise)
	arrival_light.position=view.grid_to_local(at)
	arrival_light.modulate.a=.26*dungeon_master.modulate.a+.55*sin(PI*smoothstep(7.,8.8,time))
	veil.color=Color(.025,.009,.045,1.-smoothstep(0.,.75,time))
	_focus(at,0.)
	_ensure_invoker()
	var mouth:=Vector2(session.sim._entrance_mouth(Types.FIRST_STAIR))
	var from:=start-mouth*.3
	var following:=smoothstep(.8,8.4,time)
	invoker_at=from.lerp(_invoker_destination(),following)
	view.position_invoker(invoker,invoker_at)
	# Entry fades only at the hidden remote stair endpoint, never beside the Core.
	invoker.modulate.a=smoothstep(-.03,.12,(invoker_at-start).dot(mouth))
	var moving:=following>0. and following<1.
	var distance: float=view.grid_to_local(from).distance_to(view.grid_to_local(invoker_at))
	invoker.present_direction("walk" if moving else "idle",int(distance/(Film.Actor.stride_pixels("se")*invoker.scale.x)*24.)%24 if moving else 0,"se")

func _focus(cell: Vector2, panel_offset := 1.) -> void:
	focus_cell = cell
	camera.position = view.grid_to_local(cell)
	if panel_offset > 0.:
		var target_center_y := target.position.y + target.size.y * unit * .5
		camera.position.y += panel_offset * (root.size.y * .5 - target_center_y) / camera.zoom.y
	camera.force_update_scroll()

func _process(delta: float) -> void:
	if not visible or session.paused: return
	match shot:
		Shot.PROLOGUE:
			elapsed += delta
			veil.color.a = .85*(1.-smoothstep(0.,.55,elapsed))
		Shot.LESSON:
			if needs_focus:
				_focus(Vector2(_lesson_cell())+Vector2(.5,.5))
				needs_focus = false
		Shot.RITUAL:
			elapsed += delta
			film.present(elapsed)
			dialogue.present("ritual", elapsed)
			film.modulate.a = 1.
			# Cover the cut completely, rather than showing both environments at once.
			veil.color=Color(.025,.009,.045,smoothstep(Film.DURATION-1.0,Film.DURATION,elapsed))
			if elapsed >= Film.DURATION:
				_set_shot(Shot.ENTRANCE)
			elif elapsed >= Film.DURATION - 1.4:
				_focus(_entrance_top(), 0.)
		Shot.ENTRANCE:
			elapsed += delta
			if elapsed >= ENTRY_DURATION:
				_set_shot(Shot.LESSON)
			else:
				_walk_in(elapsed / ENTRY_DURATION)

func _layout() -> void:
	if not is_instance_valid(skip) or root.size.x < 1: return
	var window_size := Vector2(get_window().size)
	var density := clampf(DisplayServer.screen_get_dpi()/160.0,1,4) if OS.has_feature("mobile") else 1.0
	var safe_pixels := Rect2(Vector2.ZERO,window_size)
	if OS.has_feature("mobile"):
		var safe := Rect2(DisplayServer.get_display_safe_area())
		safe.position -= Vector2(get_window().position)
		safe = safe.intersection(safe_pixels)
		if safe.has_area(): safe_pixels = safe
	_fit_controls(window_size, safe_pixels, density)

func _fit_controls(window_size: Vector2, safe_pixels: Rect2, density: float) -> void:
	var pixels_per_unit := density * (.9 if safe_pixels.size.y / density < 360 else 1.)
	unit = root.size.x / window_size.x * pixels_per_unit
	var area := Rect2(safe_pixels.position / pixels_per_unit, safe_pixels.size / pixels_per_unit)
	dialogue.fit(area, unit)
	for control in [skip,panel,target]: control.scale=Vector2.ONE*unit
	var margin := 12.
	skip.reset_size()
	skip.position = Vector2(area.end.x-skip.size.x-margin,area.position.y+margin)*unit
	var panel_width := minf(680,area.size.x-margin*2)
	var beside_story := shot == Shot.PROLOGUE and area.size.y < 460 and area.size.x >= 600
	if beside_story: panel_width = minf(panel_width,area.size.x*.68)
	if shot == Shot.PROLOGUE:
		# Reserve room for the illustration, heading and fixed navigation.
		var panel_budget := area.size.y - margin*2 if beside_story else area.size.y*.60
		var chrome := panel.get_theme_stylebox("panel").get_minimum_size().y + title.get_combined_minimum_size().y + action.get_combined_minimum_size().y
		chrome += 2*title.get_parent().get_theme_constant("separation")
		reading_area.custom_minimum_size.y = minf(line.get_minimum_size().y,maxf(32,panel_budget-chrome))
	else:
		reading_area.custom_minimum_size.y = 0
	panel.size = Vector2(panel_width,panel.get_combined_minimum_size().y)
	panel.position = Vector2(area.get_center().x-panel.size.x/2,area.end.y-panel.size.y-margin)*unit
	if shot == Shot.PROLOGUE:
		story.offset_right = 0
		if beside_story:
			panel.position.x = (area.end.x-panel.size.x-margin)*unit
			story.offset_right = panel.position.x - margin*unit - root.size.x
			skip.position = Vector2(area.position.x+margin,area.end.y-skip.size.y-margin)*unit
		var image_path: String = PROLOGUE[page][3 if story.size.x < story.size.y else 2]
		if not story.texture or story.texture.resource_path != image_path:
			story.texture = load(image_path)
	target.position = root.size*.5-target.size*unit*.5
	if shot in [Shot.LESSON, Shot.ENTRANCE]:
		target.position.y = minf(target.position.y, panel.position.y - (target.size.y + margin) * unit)
		if shot == Shot.LESSON: _focus(focus_cell)
