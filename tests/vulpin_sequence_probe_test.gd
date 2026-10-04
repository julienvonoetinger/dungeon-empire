extends SceneTree

const PROBES := preload("res://tests/probes/node_probes.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.mobile_ui.paused = true
	game.dungeon.set_process(false)
	var start := Vector2i(3, 3)
	var trap := Vector2i(4, 3)
	var vault := Vector2i(5, 3)
	game.sim.new_map()
	for x in range(start.x, 8):
		game.grid[3][x] = GameTypes.Tile.FLOOR
	game.grid[start.y][start.x] = GameTypes.Tile.ENTRANCE
	game.grid[trap.y][trap.x] = GameTypes.Tile.SPIKE
	game.trap_charges[trap] = 3
	game.grid[vault.y][vault.x] = GameTypes.Tile.VAULT
	game.sim.vault_gold[vault] = 40
	game.gold = 40
	game.raid._start_raid()
	game.hero.merge({
		"kind": "thief",
		"level": 1,
		"pos": start,
		"objective": "vault",
		"known": {},
		"visited": {},
		"bias": {},
		"move_cd": 0.0,
		"steal_capacity": 40,
		"flee_ratio": 0.01
	}, true)
	for y in game.grid.size():
		for x in game.grid[y].size():
			game.hero.known[Vector2i(x, y)] = game.grid[y][x]
	game.dungeon._hero_cell = Vector2i(-1, -1)
	game.dungeon._sync_hero(game)
	check(not game.raid._try_trap_jump(start, trap), "Vulpin refuses to jump a charged trap")
	check(game.hero.pos == start and not game.hero.get("jumping_trap", false), "refused jump leaves Vulpin at takeoff")
	game.raid._update_hero(0.1)
	game.dungeon._sync_hero(game)
	check(game.hero.pos == trap and game.hero.get("trap_arrival_t", 0.0) > 0.0, "Vulpin walks into the trap's normal arrival timer")
	check(game.trap_charges[trap] == 3 and game.hero.hp == game.hero.max_hp, "trap waits for actual Vulpin arrival")
	var jump_pose := PROBES.child(game.dungeon._vulpin, "JumpTrap") as Node3D
	check(jump_pose != null and not jump_pose.visible, "Vulpin gameplay arrival does not show the unused jump animation")
	game.raid._update_hero(GameTypes.TURN_TIME * 0.5)
	game.dungeon._sync_hero(game)
	check(game.trap_charges[trap] == 3 and game.hero.hp == game.hero.max_hp, "mid-arrival still has no trap effect")
	if "--capture" in OS.get_cmdline_user_args():
		for frame in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/vulpin-sequence-trap-mid.png")
	game.raid._update_hero(GameTypes.TURN_TIME * 0.5)
	game.dungeon._sync_hero(game)
	check(game.hero.pos == trap and game.trap_charges[trap] == 2, "Vulpin triggers the spike only on arrival")
	check(game.hero.hp == game.hero.max_hp - GameTypes.DAMAGE_SPIKE, "Vulpin takes spike damage after landing by walking")
	check(not game.hero.get("jumping_trap", false), "Vulpin never enters the gameplay jump state")
	for i in 16:
		if game.hero.get("collecting_gold", false):
			break
		if game.hero.has("vault_arrival_t"):
			game.raid._update_hero(GameTypes.TURN_TIME)
		else:
			game.raid._update_hero(0.2)
		game.dungeon._sync_hero(game)
	check(game.hero.get("collecting_gold", false), "Vulpin can collect the vault after its walk and trap arrival")
	check(game.sim._storage_state().vaults[vault] == 40, "Gold stays visible during the collection action")
	game.raid._update_hero(GameTypes.VULPIN_COLLECT_HOLD + 0.01)
	check(game.gold == 0 and game.hero.get("fleeing", false) and not game.hero.get("portaling", false), "Gold is removed once, then Vulpin returns on foot")
	for frame in 600:
		if not game.raid.raid_active:
			break
		game.raid._update_hero(1.0 / 60.0)
	check(not game.raid.raid_active and int(game.raid.last_result.get("stolen", 0)) == 40, "Vulpin completes the raid with the collected vault gold")
	game.queue_free()
	await process_frame
	print("Vulpin sequence probe failures: ", failures)
	quit(1 if failures else 0)
