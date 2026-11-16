extends SceneTree
## Render the ritual with and without its aerial effects to locate each discharge.
const Film = preload("res://scripts/game/invocation_sanctuary.gd")
const OUTPUT := "res://artifacts/ritual-storm/"
var film := Film.new()
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", label)

func _initialize() -> void:
	run.call_deferred()

func capture() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func brightness(image: Image) -> float:
	var sum := 0.0
	for y in range(0, image.get_height() / 3, 8):
		for x in range(0, image.get_width(), 8):
			sum += image.get_pixel(x, y).get_luminance()
	return sum

func lit_pixels(image: Image, base: Image, area: Rect2) -> int:
	var bounds := Rect2i(film.sanctuary.get_global_transform() * area)
	bounds = bounds.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var count := 0
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			if image.get_pixel(x, y).get_luminance() - base.get_pixel(x, y).get_luminance() > .16:
				count += 1
	return count

func changed_pixels(image: Image, base: Image, area: Rect2) -> int:
	return lit_pixels(image,base,area) + lit_pixels(base,image,area)

func check_mist_covers(sprite: Sprite2D, label: String) -> void:
	var area := sprite.get_rect()
	area.position += sprite.position
	var covered := await capture()
	sprite.hide()
	var leaks := changed_pixels(covered,await capture(),area)
	film.gate.mist.hide()
	var empty := await capture()
	sprite.show()
	var exposed := changed_pixels(await capture(),empty,area)
	film.gate.mist.show()
	check(exposed>100 and leaks<exposed*.03,label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.content_scale_size = Vector2i.ZERO
	root.add_child(film)
	for extent in [Vector2i(1280,720), Vector2i(390,844), Vector2i(844,390)]:
		root.size = extent
		await process_frame
		film.present(9.5)
		var daylight := brightness(await capture())
		film.present(12.6)
		check(brightness(await capture()) < daylight * .76, "Storm darkens the clearing before impact")
		# Each bolt must touch the painted facet on its own menhir.
		for impact in [["Menhir3",13.35],["Menhir5",13.93],["Menhir1",14.46],
				["Menhir4",14.97],["Menhir6",15.47],["Menhir2",15.95]]:
			film.present(impact[1])
			var struck := await capture()
			film.air_magic.hide()
			var stone: Sprite2D = film.sanctuary.get_node(impact[0])
			var facet: Vector2 = stone.position + stone.get_meta("crystal")
			var area := Rect2(facet-Vector2(9,9), Vector2(18,18))
			check(lit_pixels(struck,await capture(),area) >= 5, "Strike reaches " + str(impact[0]))
		var ring_frame: Image
		for moment in [13.35, 17.7, 19.85]:
			film.present(moment)
			var image := await capture()
			image.save_png(OUTPUT + "%d-%.2f.png" % [extent.x, moment])
			film.air_magic.hide()
			var base := await capture()
			var sky := lit_pixels(image, base, Rect2(-600,-395,1200,70))
			var rim := lit_pixels(image, base, Rect2(-55,-262,95,35))
			var center := lit_pixels(image, base, Rect2(99,-97,27,29))
			print("%s %.2f: sky=%d rim=%d inward=%d" % [extent, moment, sky, rim, center])
			if moment == 13.35:
				check(sky >= 8 and rim < 6 and center < 6, "Lightning falls before the circuit or convergence")
			elif moment == 17.7:
				ring_frame = image
				check(sky < 6 and rim >= 8 and center < 6, "The crystals connect before discharging inward")
			else:
				check(sky < 6 and center >= 8, "Lightning crosses from the east crystal to the manifestation")
		film.present(17.7)
		check((await capture()).get_data() == ring_frame.get_data(), "Seeking back restores the circuit frame")
		film.present(26.)
		check(brightness(await capture()) > daylight * .76, "Daylight returns for the departure")
		var fracture: float = film.DISPATCH_BEAT + film.gate.FRACTURE_TIME
		film.present(fracture-1.25)
		var charge := await capture()
		film.gate.hide()
		var before := await capture()
		for hand in ["Bone_015", "Bone_020"]:
			var rig := film.master_rig
			var palm := rig.to_global(rig.get_bone_global_pose(rig.find_bone(hand)).origin)
			var pixel := film.master_view.get_camera_3d().unproject_position(palm)
			var on_sprite := film.master_sprite.get_rect().position + pixel
			var center := film.sanctuary.to_local(film.master_sprite.to_global(on_sprite))
			var area := Rect2(center - Vector2.ONE * 18., Vector2.ONE * 36.)
			check(changed_pixels(charge,before,area)>=3 and film.gate.wall.visible,
				"Smoke leaves palm %s before the fracture at %s" % [hand, extent])
		film.present(fracture-.02)
		await check_mist_covers(film.gate.wall,"The rock disappears inside the mist before it breaks")
		film.present(fracture+1.)
		var stairs = film.gate.stairs
		check(stairs.visible and film.gate.mist.visible,"The stairwell forms under the fog")
		await check_mist_covers(stairs,"Dense mist hides the new steps before they are revealed")
		film.present(fracture+4.)
		check(stairs.visible and not film.gate.mist.visible,"The fog clears before the descent")
		var soil := film.gate.tainted_ground
		check(soil.is_visible_in_tree() and is_equal_approx(soil.modulate.a,1.) and soil.get_index()<stairs.get_index(),
			"The scar stays on the ground beneath the revealed entrance")
		film.present(fracture-2.)
		check(film.gate.wall.visible and not film.gate.mist.visible and not stairs.visible and not soil.visible,
			"Seeking back restores the untouched rock and soil")
	print("INVOCATION_STORM: failures=", failures)
	quit(int(failures > 0))
