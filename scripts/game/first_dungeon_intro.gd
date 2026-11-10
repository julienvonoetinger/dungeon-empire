extends CanvasLayer
## Each introduction uses the live map and resumes at the current lesson.
const UI = preload("res://scripts/game/ui/hud_theme.gd")
const Types = preload("res://scripts/game/game_types.gd")
const Film = preload("res://scripts/game/invocation_sanctuary.gd")
const Dialogue = preload("res://scripts/game/invocation_dialogue.gd")
const LevelUp = preload("res://scripts/game/artisan_level_up.gd")
const BuildSite = preload("res://scripts/game/ui/tutorial_build_site.gd")
const FloatingMarker = preload("res://scripts/game/ui/floating_site_marker.gd")
const StoneBand = preload("res://scripts/game/ui/intro_stone_band.gd")
const PageTurn = preload("res://scripts/game/ui/prologue_page_turn.gd")
const TutorialRaid = preload("res://scripts/game/tutorial_raid.gd")
enum Shot { CLOSED, PROLOGUE, RITUAL, ENTRANCE, ARTISAN, LESSON, GIFT, ARTISAN_EXIT, PRACTICE_OFFER, PRACTICE_RUN, PRACTICE_REPORT }
const PRACTICE_SHOTS := [Shot.ARTISAN_EXIT, Shot.PRACTICE_OFFER, Shot.PRACTICE_RUN, Shot.PRACTICE_REPORT]
const EXIT_SPEED := 1.35
const ARTISAN_START := 35.0
const ENTRY_DURATION := ARTISAN_START + 15.5
const ARTISAN_OFFER_DURATION := 6.
const ARTISAN_BEAT_DURATION := ARTISAN_OFFER_DURATION + LevelUp.DURATION
const OFFERS := {
	Types.Lesson.MEET_MINER: ["The Miner", "Master, I can help you expand your dungeon. Tell me where to dig and I’ll get to work.", 1, "Digging unlocked"],
	Types.Lesson.MEET_CARPENTER: ["The Carpenter", "Master, I can make doors for your dungeon. Choose a passage between two walls and I’ll fit it with a wooden door.", 2, "Wooden doors unlocked"],
	Types.Lesson.MEET_SCIENTIST: ["The Scientist", "Master, I can build traps to defend the dungeon. Choose a tile and my spikes will spring up beneath an intruder’s feet.", 3, "Spike traps unlocked"],
}
const ARTISAN_SPACING := 1.65
const ARTISAN_SPEED := .56
const ARTISAN_FRAMES := [
	"res://assets/previews/oculin-mineur-walk/frames.tres",
	"res://assets/previews/oculin-menuisier-walk/frames.tres",
	"res://assets/previews/oculin-scientifique-walk/frames.tres",
]
# Travel per second of the original equipped, 20 fps walk cycles (model units).
const ARTISAN_GAITS := [.77, .725, .69]
const Stairs = preload("res://scripts/game/stair_traversal.gd")
const PROLOGUE := [
	["Far from the World", "Deep in the mountains, the Oculins lived in a village hidden between the cliffs. They had terraced the slopes for their crops and built their homes of stone. For generations they had lived this way, cut off from the rest of the world. Their village appeared on no map. No kingdom knew they existed.", "res://assets/game/introduction/prologue-basalt.webp", "res://assets/game/introduction/prologue-basalt-portrait.webp"],
	["The Discovery", "At the foot of the mountains lay the kingdom of Valdorne. Its ruler, King Aldren, wanted to open a road to the lands on the other side. He sent a mapmaker and two scouts to survey the passes. From a ridge, they spotted the Oculin village. The mapmaker sketched the houses, the paths and the pass they overlooked.", "res://assets/game/introduction/prologue-lookout.webp", "res://assets/game/introduction/prologue-lookout-portrait.webp"],
	["An Audience with the King", "At court, the mapmaker showed Aldren his sketch. The king asked about the villagers and the paths leading to the pass. The three travelers had seen the village only from a distance. They knew nothing of its people or whether they would welcome visitors. Aldren sent an envoy with a few guards to ask for a road through their lands.", "res://assets/game/introduction/prologue-audience.webp", "res://assets/game/introduction/prologue-audience-portrait.webp"],
	["The Strangers", "As the envoys approached, the Oculins barred the village entrance. They had never seen anyone like these strangers. The envoy told them of Valdorne, its king and the road he wished to open. The elders refused to let him go any farther.\n“These mountains are our home. We will give up no land. Your people shall not pass.”\nThe Oculins watched the envoys leave.", "res://assets/game/introduction/prologue-envoy.webp", "res://assets/game/introduction/prologue-envoy-portrait.webp"],
	["The Closed Pass", "The envoys returned with word of the Oculins’ refusal. The villagers had closed the paths and now stood guard on the approaches to the pass. Aldren wanted the road so he could extend his kingdom beyond the mountains. He decided to open it by force. He ordered his captain to seize the pass and establish a garrison there.", "res://assets/game/introduction/prologue-decree.webp", "res://assets/game/introduction/prologue-decree-portrait.webp"],
	["The Attack", "When Valdorne’s banners appeared in the valley, the Oculins carried provisions to the caves and reinforced their barricades. The soldiers forced their way through. The fighting spread into the narrow streets, where the soldiers set fire to houses to drive out the defenders. The Oculins had to abandon their village. The survivors retreated higher into the mountains, carrying their wounded.", "res://assets/game/introduction/prologue-assault.webp", "res://assets/game/introduction/prologue-assault-portrait.webp"],
	["The Survivors", "The survivors gathered in the caves. They tended the wounded and shared the food they had brought to safety. People kept arriving until nightfall. Then the paths fell silent. The Oculins kept watch at the cave mouth long into the night, still hoping to see those who were missing. Below them, their homes were burning.", "res://assets/game/introduction/prologue-pass.webp", "res://assets/game/introduction/prologue-pass-portrait.webp"],
	["Occupied Lands", "A few days later, some Oculins went back down to look at the ruins. The soldiers had built a palisade around the village. Workers were pulling down the houses that still stood to reuse the stone. Aldren’s fortress was beginning to rise on their land. The scouts brought the news back to the caves. Up there, supplies were dwindling and the cold was setting in.", "res://assets/game/introduction/prologue-occupation.webp", "res://assets/game/introduction/prologue-occupation-portrait.webp"],
	["The Forbidden Sanctuary", "At the refuge, an elder told the survivors of a sanctuary hidden high in the mountains. The Oculins’ ancestors had forbidden anyone to enter. An evil god could be summoned there, and the elder still knew the rite.", "res://assets/game/introduction/prologue-council.webp", "res://assets/game/introduction/prologue-council-portrait.webp", ["The Invoker", "He can give us the strength to prevail. But we will have to serve him.", "After a night of debate, the survivors decided to go."]],
	["Your Kingdom", "The elder led them to a narrow gorge. There, hidden from view, standing stones encircled an engraved slab. He stepped into the center of the sanctuary and spoke your name.", "res://assets/game/introduction/prologue-oath.webp", "res://assets/game/introduction/prologue-oath-portrait.webp", ["The Invoker", "We pledge our loyalty to you. Give us the strength to overthrow Aldren. Beneath the mountain, we will build your kingdom.", "Around him, the Oculins knelt. Their call had reached you."]],
]

@onready var session: IsometricGameSession = get_parent()
@onready var hud: CanvasLayer = session.get_node("HUD")
@onready var view: Node2D = session.get_node("PlayArea/World/Dungeon")
@onready var camera: Camera2D = session.get_node("PlayArea/World/Camera2D")
var shot := Shot.CLOSED
var artisan_lesson := Types.Lesson.MEET_MINER
var site_buttons := Control.new()
var site_ink := Node2D.new()
var placement_sites: Array[Vector2i] = []
var elapsed := 0.0
var root := ColorRect.new()
var story := TextureRect.new()
var page := 0
var film := Film.new()
var veil := ColorRect.new()
var dialogue := Dialogue.new()
var level_up := LevelUp.new()
var story_band := StoneBand.new()
var page_turn := PageTurn.new()
var panel := PanelContainer.new()
var story_padding := StyleBoxEmpty.new()
var lesson_surface := UI.surface("panel",12)
var panel_box := VBoxContainer.new()
var heading := HBoxContainer.new()
var skip: Button
var title: Label
var reading_area := ScrollContainer.new()
var reading_column := VBoxContainer.new()
var story_quote := RichTextLabel.new()
var after_line: Label
var line: Label
var action: Button
var invoker: Node2D
var volunteer: Film.Actor
var practice: TutorialRaid
var invoker_at:=Vector2.ZERO
var artisans: Array[AnimatedSprite2D] = []
var dungeon_master: Sprite2D
var arrival_light: Sprite2D
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
	level_up.locate_core = _core_on_screen
	root.add_child(level_up)
	root.add_child(site_buttons)
	site_buttons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	site_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(site_ink)
	site_ink.draw.connect(_draw_build_sites)
	site_ink.hide()
	root.add_child(story_band)
	story_band.hide()
	story_padding.set_content_margin(SIDE_LEFT,16)
	story_padding.set_content_margin(SIDE_RIGHT,16)
	story_padding.set_content_margin(SIDE_TOP,8)
	story_padding.set_content_margin(SIDE_BOTTOM,6)
	root.add_child(panel)
	panel.add_child(panel_box)
	panel_box.add_child(heading)
	title = UI.label(heading,"",24,UI.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_box.add_child(reading_area)
	reading_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.slim_scrollbar(reading_area)
	reading_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading_area.add_child(reading_column)
	line = UI.label(reading_column,"",20)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reading_column.add_child(story_quote)
	story_quote.fit_content = true
	story_quote.scroll_active = false
	story_quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_quote.focus_mode = Control.FOCUS_NONE
	story_quote.add_theme_font_size_override("normal_font_size", line.get_theme_font_size("font_size"))
	story_quote.add_theme_color_override("default_color", UI.TEXT)
	story_quote.add_theme_color_override("font_shadow_color", line.get_theme_color("font_shadow_color"))
	story_quote.add_theme_constant_override("shadow_offset_x", 0)
	story_quote.add_theme_constant_override("shadow_offset_y", 1)
	story_quote.hide()
	after_line = UI.label(reading_column,"",20)
	after_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	after_line.hide()
	reading_column.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	action = UI.intro_button(panel_box,"",_act)
	page_turn.reading_panel = panel
	page_turn.reading_area = reading_area
	heading.add_child(page_turn)
	page_turn.hide()
	page_turn.pressed.connect(_act)
	skip = UI.intro_button(root,tr("Skip"),_skip,true)
	root.resized.connect(_layout)
	panel.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	skip.minimum_size_changed.connect(_layout, CONNECT_DEFERRED)
	session.introduction_started.connect(func(): _set_shot(Shot.PROLOGUE))
	session.changed.connect(_sync)
	set_process(false)

func _sync(structure: bool) -> void:
	if session.sim.lesson == Types.Lesson.FREE:
		if shot != Shot.CLOSED: _set_shot(Shot.CLOSED)
		if session.sim.invoker_resident and (structure or not is_instance_valid(invoker)):
			_station_invoker()
		return
	var new_offer := shot == Shot.LESSON and OFFERS.has(session.sim.lesson)
	var gift_accepted := shot == Shot.GIFT and session.sim.lesson != Types.Lesson.INVOKER_OFFER
	if session.sim.lesson == Types.Lesson.PRACTICE_RAID:
		if shot not in PRACTICE_SHOTS: _set_shot(Shot.ARTISAN_EXIT)
	elif shot == Shot.CLOSED or new_offer or gift_accepted: _set_shot(Shot.LESSON)
	elif shot == Shot.LESSON: _show_lesson()
	visible = not session.paused and not session.confirmation_open
	hud.visible = not visible
	site_ink.visible = visible and not placement_sites.is_empty()

func _set_shot(next: int) -> void:
	if shot == Shot.PRACTICE_RUN: session.get_node("Input")._apply_presentation()
	_set_dig_controls(false)
	_clear_build_sites()
	reading_area.show()
	title.add_theme_font_size_override("font_size",24)
	if next == Shot.LESSON and OFFERS.has(session.sim.lesson):
		artisan_lesson = session.sim.lesson
		next = Shot.ARTISAN
	elif next == Shot.LESSON and session.sim.lesson == Types.Lesson.INVOKER_OFFER:
		next = Shot.GIFT
	_clear_master_arrival()
	view.set_procession_doors_open(next == Shot.ARTISAN_EXIT)
	if next not in [Shot.LESSON, Shot.ARTISAN, Shot.GIFT, Shot.ARTISAN_EXIT]:
		for artisan in artisans:
			if is_instance_valid(artisan): artisan.queue_free()
		artisans.clear()
	if is_instance_valid(volunteer):
		volunteer.queue_free()
		volunteer = null
	if next not in [Shot.PRACTICE_RUN, Shot.PRACTICE_REPORT]: practice = null
	shot = next
	dialogue.clear_line()
	level_up.hide()
	story_quote.hide()
	after_line.hide()
	var cinematic := shot in [Shot.PROLOGUE, Shot.RITUAL, Shot.ENTRANCE]
	view.set_core_awakening(0.0 if cinematic else 1.0)
	view.set_core_cinematic_time(0.0 if cinematic or shot == Shot.ARTISAN else -1.0)
	elapsed = 0
	visible = shot != Shot.CLOSED and not session.paused
	hud.visible = not visible
	set_process(shot != Shot.CLOSED)
	var dismiss_invoker := cinematic or (next == Shot.CLOSED and not session.sim.invoker_resident)
	if dismiss_invoker and is_instance_valid(invoker):
		invoker.queue_free()
		invoker = null
	panel.visible = shot in [Shot.PROLOGUE, Shot.LESSON]
	story_band.visible = shot == Shot.PROLOGUE
	panel.add_theme_stylebox_override("panel", story_padding if story_band.visible else lesson_surface)
	if shot != Shot.RITUAL: film.release()
	story.visible = shot == Shot.PROLOGUE
	# Keep the same text width when a taller quote makes the scrollbar appear.
	reading_area.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	root.color = UI.INK if story.visible else Color.TRANSPARENT
	if not story.visible: story.texture = null
	veil.color = Color.TRANSPARENT
	action.visible = shot == Shot.PROLOGUE
	page_turn.hide()
	skip.show()
	UI.set_intro_advance(skip, shot in [Shot.GIFT, Shot.PRACTICE_OFFER, Shot.PRACTICE_REPORT])
	skip.text = tr("Free play") if shot == Shot.LESSON else tr("Skip")
	match shot:
		Shot.CLOSED:
			session.get_node("Input").center_core()
		Shot.PROLOGUE:
			skip.text = tr("Skip story")
			_show_page(0)
		Shot.RITUAL:
			film.modulate.a = 1.
			film.present(0.)
		Shot.ENTRANCE:
			_ensure_master_arrival()
			_walk_in(0.)
		Shot.ARTISAN:
			_assemble_artisans()
			present_artisan_offer(0.)
		Shot.GIFT:
			_assemble_artisans()
			_focus(Vector2(Types.core_origin_cell()) + Vector2(.5,1.05))
			dialogue.show_line("The Invoker", "Master, the villagers have gathered all their gold for you. These two bags hold fifty coins each. Where shall we put them?")
			skip.text = tr("Choose tiles")
		Shot.LESSON: _show_lesson()
		Shot.ARTISAN_EXIT:
			_assemble_artisans()
			_focus(_invoker_destination())
		Shot.PRACTICE_OFFER:
			_station_invoker()
			_focus(invoker_at)
			dialogue.show_line("The Invoker", "I’ll ask one of our people to play the intruder. Let’s see how far he gets. He’ll leave your gold alone and won’t strike the Core.")
			skip.text = tr("Start practice")
		Shot.PRACTICE_RUN:
			practice = TutorialRaid.new(session.sim,session.raid)
			volunteer = Film.Actor.new()
			volunteer.scale = Vector2.ONE * .82
			volunteer.z_index = 1
			_follow_volunteer(0.)
			skip.hide()
		Shot.PRACTICE_REPORT:
			_focus(invoker_at)
			dialogue.show_line("The Invoker",practice.report())
			skip.text = tr("Free play")
	_layout()

func _show_page(index: int) -> void:
	page = index
	elapsed = 0
	var entry: Array = PROLOGUE[page]
	title.text = tr("%d / %d   ·   %s") % [page+1, PROLOGUE.size(), tr(entry[0])]
	line.text = tr(entry[1])
	line.show()
	story_quote.clear()
	story_quote.visible = entry.size() > 4
	after_line.visible = story_quote.visible
	if story_quote.visible:
		var quote: Array = entry[4]
		story_quote.add_image(Dialogue.PORTRAITS[quote[0]], 0, 38, Color.WHITE, INLINE_ALIGNMENT_CENTER)
		story_quote.add_text("  ")
		story_quote.push_color(UI.GOLD)
		story_quote.add_text(tr(quote[0]))
		story_quote.pop()
		story_quote.add_text(tr("  “%s”") % tr(quote[1]))
		after_line.text = tr(quote[2])
	reading_area.scroll_vertical = 0
	var turning_page := page < PROLOGUE.size()-1
	var transfer_focus := page_turn.has_focus() and not turning_page
	page_turn.reset_gesture()
	page_turn.visible = turning_page
	action.visible = not turning_page
	action.text = tr("Answer the call")
	action.disabled = false
	veil.color = Color(.028,.013,.045,.85)
	_layout()
	if transfer_focus: action.grab_focus()

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

func _station_invoker() -> void:
	_ensure_invoker()
	invoker.modulate.a = 1
	invoker_at=_invoker_destination()
	view.position_invoker(invoker,invoker_at)
	invoker.present_direction("idle",0,"se")

func _assemble_artisans() -> void:
	_station_invoker()
	_present_artisans(ENTRY_DURATION, _entrance_top())

func present_artisan_offer(time: float) -> void:
	var core := Vector2(Types.core_origin_cell()) + Vector2(.5,.5)
	_focus(core + Vector2(0.,.55))
	view.set_core_cinematic_time(ENTRY_DURATION + time)
	var offer: Array = OFFERS[artisan_lesson]
	if time < ARTISAN_OFFER_DURATION:
		dialogue.show_line(offer[0], offer[1])
	else:
		dialogue.clear_line()
	level_up.present(time-ARTISAN_OFFER_DURATION,unit,dialogue.area,offer[2],offer[3])

func _core_on_screen() -> Vector2:
	var heart: Dictionary = view.DEFINITION.get("entries")["heart"]
	var center: Vector2 = view.grid_to_local(Vector2(Types.core_origin_cell())+Vector2(.5,.5))
	center += Vector2(heart.offset[0], heart.offset[1]) + Vector2(heart.vortex.center[0], heart.vortex.center[1])
	var play: SubViewportContainer = session.get_node("PlayArea")
	var in_world: Vector2 = view.get_global_transform_with_canvas() * center
	return play.get_global_transform_with_canvas() * (in_world * play.size / Vector2(view.get_viewport().size))

func _show_lesson() -> void:
	var step := session.sim.lesson
	var gift := step == Types.Lesson.VILLAGE_GIFT
	var digging := step == Types.Lesson.ALCOVE
	_set_dig_controls(digging)
	_clear_build_sites()
	_assemble_artisans()
	reading_area.visible = not session.save_error.is_empty()
	title.add_theme_font_size_override("font_size",18)
	line.text = session.save_error
	line.visible = not session.save_error.is_empty()
	skip.visible = not gift
	if digging:
		title.text = tr("Tap the tile or the pickaxe · %d gold") % Types.COST_DIG
	else:
		_show_build_sites(step)
	_layout()

func _set_dig_controls(enabled: bool) -> void:
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE if enabled else Control.MOUSE_FILTER_STOP
	if view.lesson_digging == enabled: return
	view.set_lesson_digging(enabled)
	hud.dig_targets.refresh()
	if not enabled: session.get_node("Input")._apply_presentation()

func _frame_dig_cells(area: Rect2) -> void:
	if hud.dig_targets.blocks.is_empty(): return
	var bounds: Rect2 = hud.dig_targets.blocks[0].support.rect
	for block in hud.dig_targets.blocks:
		bounds = bounds.merge(block.framing_bounds())
	_frame_sites(bounds,area)

func _frame_sites(bounds: Rect2, area: Rect2) -> void:
	var top := skip.get_global_rect().end.y + 6.*unit
	var bottom := panel.position.y - 8.*unit
	var space := Vector2(area.size.x*unit-20.*unit,maxf(1.,bottom-top))
	var input = session.get_node("Input")
	var zoom := minf(input.FIXED_ZOOM * input.presentation_scale(), minf(space.x/bounds.size.x,space.y/bounds.size.y))
	camera.zoom = Vector2.ONE * zoom
	var screen_center := Vector2(area.get_center().x*unit,(top+bottom)*.5)
	camera.position = bounds.get_center() + (root.size*.5-screen_center)/zoom
	camera.force_update_scroll()

func _clear_build_sites() -> void:
	if not placement_sites.is_empty(): session.get_node("Input")._apply_presentation()
	placement_sites.clear()
	site_ink.hide()
	for button in site_buttons.get_children():
		site_buttons.remove_child(button)
		button.queue_free()

func _show_build_sites(step: int) -> void:
	var gift := step == Types.Lesson.VILLAGE_GIFT
	var door := step == Types.Lesson.DOOR
	var tool := Types.Tool.BUILD_DOOR if door else Types.Tool.TRAP_SPIKE
	var placement_label := tr("Place the door") if door else tr("Place the trap")
	if gift:
		var prompt := tr("Choose a tile for the first gold bag · %d gold") if session.sim.floor_gold.is_empty() else tr("Choose a tile for the second gold bag · %d gold")
		title.text = prompt % Types.GOLD_BAG_CAPACITY
		placement_label = tr("Place the bag")
		for y in Types.ROWS:
			for x in Types.COLS:
				var cell := Vector2i(x,y)
				if session.sim.can_place_gift(cell): placement_sites.append(cell)
	else:
		placement_sites = session.available_build_sites(tool)
		var count := placement_sites.size()
		var sites := tr("1 available tile") if count == 1 else tr("%d available tiles") % count
		var instruction := tr("Place a door between two walls") if door else tr("Place a spike trap")
		title.text = tr("%s · %s · %d gold") % [instruction,sites,Types.fixed_tool_cost(tool)]
	for cell in placement_sites:
		var button := BuildSite.new()
		button.view = view
		if gift:
			button.pressed.connect(session.place_village_bag.bind(cell))
		else:
			button.icon = UI.build_site_icon(tool)
			button.preview.flip_h = view.should_flip_build_icon(button.icon,cell)
			button.pressed.connect(_build_at.bind(cell,tool))
		for signal_name in ["mouse_entered","mouse_exited","focus_entered","focus_exited","button_down","button_up"]:
			button.connect(signal_name,site_ink.queue_redraw)
		button.accessibility_name = tr("%s (%d, %d)") % [placement_label,cell.x,cell.y]
		site_buttons.add_child(button)
	# Paint after the floor but beneath the level-1 scenery and actors.
	view.move_child(site_ink,-1)
	site_ink.visible = visible
	site_ink.queue_redraw()

func _draw_build_sites() -> void:
	var extent := FloatingMarker.tile_extent(view)
	for i in placement_sites.size():
		var center: Vector2 = view.grid_to_local(Vector2(placement_sites[i])+Vector2(.5,.5))
		site_buttons.get_child(i).paint_on_floor(site_ink,center,extent,unit/camera.zoom.x)

func _build_at(cell: Vector2i, tool: int) -> void:
	if not visible or shot != Shot.LESSON or not session.can_edit(): return
	session.selected = cell
	session.confirm_action(tool)

func _frame_build_sites(area: Rect2) -> void:
	var points := PackedVector2Array()
	for cell in placement_sites:
		points.append(view.grid_to_local(Vector2(cell)+Vector2(.5,.5)))
	var bounds := Rect2(points[0],Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	if session.sim.lesson == Types.Lesson.VILLAGE_GIFT:
		for cell: Vector2i in session.sim.floor_gold:
			bounds = bounds.expand(view.grid_to_local(Vector2(cell)+Vector2(.5,.5)))
	_frame_sites(bounds.grow(88.),area)
	var extent := FloatingMarker.tile_extent(view)
	for i in points.size():
		var button: BuildSite = site_buttons.get_child(i)
		button.fit(view.get_global_transform_with_canvas()*points[i], extent, camera.zoom.x, unit)
	site_ink.queue_redraw()

func _act() -> void:
	if not visible or session.paused: return
	if shot == Shot.PROLOGUE:
		if page+1 < PROLOGUE.size(): _show_page(page+1)
		else: _set_shot(Shot.RITUAL)

func _skip() -> void:
	if not visible or session.paused: return
	match shot:
		Shot.PROLOGUE: _set_shot(Shot.RITUAL)
		Shot.RITUAL, Shot.ENTRANCE: _set_shot(Shot.LESSON)
		Shot.GIFT: session.accept_village_gift()
		Shot.ARTISAN:
			if elapsed < ARTISAN_OFFER_DURATION:
				elapsed = ARTISAN_OFFER_DURATION
				_process(0.)
			else:
				_set_shot(Shot.LESSON)
		Shot.LESSON: session.leave_tutorial()
		Shot.ARTISAN_EXIT: _set_shot(Shot.PRACTICE_OFFER)
		Shot.PRACTICE_OFFER: _set_shot(Shot.PRACTICE_RUN)
		Shot.PRACTICE_REPORT: session.finish_practice_raid()

func _entrance_top() -> Vector2:
	return Vector2(Types.FIRST_STAIR) + Vector2(.5,.5) - Vector2(session.sim._entrance_mouth(Types.FIRST_STAIR)) * Stairs.TOP_TRAVEL

func _invoker_destination() -> Vector2:
	return Vector2(Types.core_origin_cell()) + Types.COUNCIL_INVOKER

func _present_artisans(time: float, start: Vector2, departing := false) -> Vector2:
	var core := Vector2(Types.core_origin_cell())
	var group_center := core + Vector2(.35,.8)
	if time < ARTISAN_START:
		for actor in artisans: actor.hide()
		return group_center
	artisans.resize(ARTISAN_FRAMES.size())
	var leader := start
	for i in artisans.size():
		var actor := artisans[i]
		if not is_instance_valid(actor) or actor.is_queued_for_deletion():
			actor = AnimatedSprite2D.new()
			actor.sprite_frames = load(ARTISAN_FRAMES[i])
			actor.centered = false
			actor.offset = Vector2(-128,-194.076)
			actor.scale = Vector2.ONE * .82
			actor.self_modulate = Color("d9dbea")
			actor.z_index = 1
			var shadow := Sprite2D.new()
			shadow.texture = Film.LIGHT
			shadow.scale = Vector2(90,30)/Vector2(Film.LIGHT.get_size())
			shadow.modulate = Color(.025,.015,.04,.7)
			shadow.show_behind_parent = true
			actor.add_child(shadow)
			artisans[i] = actor
		var travel := maxf(0.,time-ARTISAN_START-i*ARTISAN_SPACING)*ARTISAN_SPEED
		# Keep to the open corridor, then fan out along the front of the Core.
		var corner := core + Vector2(-.65,.75)
		var front := core + Types.COUNCIL_ARTISANS[-1]
		var stop := core + Types.COUNCIL_ARTISANS[i]
		var at := start
		var remaining := travel
		var facing: StringName = &"ne"
		for waypoint: Vector2 in [corner,front,stop]:
			var length := at.distance_to(waypoint)
			if remaining < length:
				facing = &"sw" if waypoint == front else &"se"
				if departing: facing = &"ne" if waypoint == front else &"nw"
				at = at.move_toward(waypoint,remaining)
				break
			remaining -= length
			at = waypoint
		view.position_invoker(actor,at)
		actor.visible = travel > 0.
		actor.modulate.a = smoothstep(0.,.15,travel)
		actor.animation = facing
		var gait_speed := float(ARTISAN_GAITS[i]) * (256./2.55) * .70710678 / 128. * actor.scale.x
		var frame := int(travel/gait_speed*20.)
		actor.frame = 0 if at == stop else posmod(-frame if departing else frame,actor.sprite_frames.get_frame_count(facing))
		if i == 0: leader = at
	return leader.lerp(group_center,smoothstep(7.0,11.5,time-ARTISAN_START))

func _walk_in(progress: float) -> void:
	_ensure_master_arrival()
	var time := progress*ENTRY_DURATION
	dialogue.present("entrance", time)
	view.set_core_cinematic_time(time)
	var start := _entrance_top()
	var travel := smoothstep(.5,6.5,time)
	var at := start.lerp(Vector2(Types.core_origin_cell())+Vector2(.5,.5),travel)
	film.master.rotation.y=PI*.25
	if time < 9.:
		film.master.present(fposmod(time,6.))
	film.master_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS if time < 9. else SubViewport.UPDATE_DISABLED
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
	var assembly := _present_artisans(time,start)
	var entrance_focus := start if time < ARTISAN_START else assembly
	_focus(at.lerp(entrance_focus,smoothstep(-1.4,.7,time-ARTISAN_START)))

func _focus(cell: Vector2) -> void:
	camera.position = view.grid_to_local(cell)
	camera.force_update_scroll()

func _follow_volunteer(time: float) -> void:
	var input = session.get_node("Input")
	camera.zoom = Vector2.ONE * input.FIXED_ZOOM * input.presentation_scale() * 1.55
	_focus(practice.present(volunteer,view,time))

func _process(delta: float) -> void:
	if not visible or session.paused: return
	match shot:
		Shot.ARTISAN_EXIT:
			elapsed += delta
			var time := ENTRY_DURATION - elapsed * EXIT_SPEED
			if time <= ARTISAN_START:
				_set_shot(Shot.PRACTICE_OFFER)
			else:
				_focus(_present_artisans(time,_entrance_top(),true))
		Shot.PRACTICE_RUN:
			var previous := elapsed
			elapsed += delta
			_follow_volunteer(elapsed)
			if previous < practice.travel_time and elapsed >= practice.travel_time and practice.outcome == TutorialRaid.Outcome.TRAP:
				view._on_trap_activated(practice.contact, session.sim.grid[practice.contact.y][practice.contact.x])
			if elapsed >= practice.duration(): _set_shot(Shot.PRACTICE_REPORT)
		Shot.PROLOGUE:
			elapsed += delta
			veil.color.a = .85*(1.-smoothstep(0.,.55,elapsed))
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
				_focus(_entrance_top())
		Shot.ENTRANCE:
			elapsed += delta
			if elapsed >= ENTRY_DURATION:
				_set_shot(Shot.LESSON)
			else:
				_walk_in(elapsed / ENTRY_DURATION)
		Shot.ARTISAN:
			elapsed += delta
			if elapsed >= ARTISAN_OFFER_DURATION:
				session.learn_from_artisan(artisan_lesson)
			if elapsed >= ARTISAN_BEAT_DURATION:
				_set_shot(Shot.LESSON)
			else:
				present_artisan_offer(elapsed)

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
	if shot == Shot.ARTISAN: present_artisan_offer(elapsed)
	for control in [skip,panel]: control.scale=Vector2.ONE*unit
	var margin := 12.
	skip.reset_size()
	skip.position = Vector2(area.end.x-skip.size.x-margin,area.position.y+margin)*unit
	var prologue := shot == Shot.PROLOGUE
	var panel_width := area.size.x if prologue else minf(680,area.size.x-margin*2)
	var action_in_heading := prologue and area.size.x >= 520.
	var action_parent: Container = heading if action_in_heading else panel_box
	if action.get_parent() != action_parent:
		var keep_focus := action.has_focus()
		action.reparent(action_parent, false)
		if keep_focus and action.is_visible_in_tree(): action.grab_focus()
	if shot in [Shot.PROLOGUE, Shot.LESSON]:
		# Reserve room for the illustration, heading and fixed navigation.
		var panel_budget := area.size.y * (.60 if prologue else .73)
		var separation := panel_box.get_theme_constant("separation")
		var chrome := panel.get_theme_stylebox("panel").get_minimum_size().y + heading.get_combined_minimum_size().y + separation
		if not action_in_heading and action.visible: chrome += action.get_combined_minimum_size().y + separation
		reading_area.custom_minimum_size.y = minf(reading_column.get_combined_minimum_size().y,maxf(32,panel_budget-chrome))
	else:
		reading_area.custom_minimum_size.y = 0
	panel.size = Vector2(panel_width,panel.get_combined_minimum_size().y)
	panel.position = Vector2(area.get_center().x-panel.size.x/2,area.end.y-panel.size.y-(0. if prologue else margin))*unit
	if prologue:
		story_band.scale = Vector2.ONE * unit
		story_band.position = Vector2(0,panel.position.y)
		story_band.size = Vector2(root.size.x,root.size.y-panel.position.y) / unit
		var image_path: String = PROLOGUE[page][3 if window_size.y > window_size.x else 2]
		if not story.texture or story.texture.resource_path != image_path:
			story.texture = _load_story_art(image_path)
	if shot == Shot.LESSON:
		if view.lesson_digging: _frame_dig_cells(area)
		elif not placement_sites.is_empty(): _frame_build_sites(area)

func _load_story_art(image_path: String) -> Texture2D:
	if ResourceLoader.exists(image_path):
		return load(image_path)
	# The Android export keeps the original WebP for each orientation.
	var image := Image.new()
	if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(image_path)) != OK:
		push_error("Cannot decode prologue art: " + image_path)
		return null
	var texture := ImageTexture.create_from_image(image)
	texture.resource_path = image_path
	return texture
