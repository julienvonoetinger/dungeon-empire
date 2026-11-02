extends SceneTree

const Game = preload("res://scenes/game/DungeonGame.tscn")
const Save = preload("res://scripts/game/gameplay_save.gd")
const T := GameTypes.Tile
const ORIGIN := Vector2i(3, 7)
var checks := 0
var failures := 0

func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", what)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: IsometricGameSession = Game.instantiate()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	var sim := game.sim
	var view = game.get_node("PlayArea/World/Dungeon")
	sim._place_core(Vector2i(8,8))
	for y in 2:
		for x in 2: sim.grid[ORIGIN.y+y][ORIGIN.x+x] = T.VAULT
	var ring := [Vector2i(0,-1),Vector2i(1,-1),Vector2i(2,0),Vector2i(2,1),
		Vector2i(0,2),Vector2i(1,2),Vector2i(-1,0),Vector2i(-1,1)]
	for i in ring.size():
		var p: Vector2i = ORIGIN + ring[i]
		sim.grid[p.y][p.x] = T.FLOOR
		game.changed.emit(true)
		var hoards := 0
		for group: Dictionary in view.solid_groups:
			if group.get("id") == "treasury-hoard":
				hoards += 1
				check(group.room.side == ["N","E","S","W"][i/2] and group.room.slot == i%2, "correct side and slot")
				var sprites: Array = group.node.find_children("*","Sprite2D",true,false)
				check(sprites.size() == 1 and sprites[0].texture.resource_path.ends_with("reserve-"+group.room.side+".png"), "one complete game texture")
			check(not str(group.get("id","")).begins_with("prop-chest"), "individual chest hidden")
		check(hoards == 1, "one treasury for entrance " + str(i))
		check(view._markers.size() == 1 and view._markers[0].node.badge.capacity == 900, "bonus capacity on the pooled fill ring")
		sim.grid[p.y][p.x] = T.ROCK
	var p := ORIGIN + Vector2i(2,1)
	sim.grid[p.y][p.x] = T.DOOR
	var outside := Vector2i(10,10)
	sim.grid[outside.y][outside.x] = T.VAULT
	sim.gold = 350
	sim.vault_gold = {ORIGIN:150, ORIGIN+Vector2i.DOWN:150, outside:50}
	for tier in [1,2]:
		sim.vault_locks[ORIGIN] = tier
		sim.vault_opened[ORIGIN] = true
		check(sim.treasure_rooms().is_empty(), "picked tier %d still disqualifies" % tier)
	sim.vault_locks.clear()
	sim.vault_opened.clear()
	var empty_member := ORIGIN + Vector2i.ONE
	check(sim.transfer_gold(empty_member,outside,70) == 70, "transfer from whole room")
	check(sim.transfer_gold(outside,empty_member,120) == 120, "transfer into whole room")
	check(sim.transfer_gold(ORIGIN,empty_member,20) == 0, "no transfer to self")
	check(sim.withdraw_vault_gold(empty_member,200) == 200 and sim.gold == 150, "raid withdrawal across members")
	var data := Save.capture(sim, game.raid, game.progression)
	game.restart(false)
	check(Save.apply(data, sim, game.raid, game.progression), "save reload")
	check(sim.treasure_rooms().size() == 1 and sim.stored_gold(sim.storage_cells(ORIGIN)) == 150, "room and contents restored")
	game.changed.emit(true)
	game.select_cell(empty_member)
	var panel = game.get_node("HUD").selection
	check(panel.title.text == "Treasure room" and panel.detail.text == "150 / 900 gold", "selection shows the bonus capacity")
	panel._open_transfer()
	check(panel._destinations == [outside], "members are not offered as separate transfer targets")
	game.cancel_selection()
	var raid := game.raid
	raid.hero = {"kind":"thief","display":"Vulpin","pos":empty_member,"hp":30,"ignored":{},"steal_capacity":25}
	raid.raid_stats = {"stolen":0}
	raid._try_rob_vault(empty_member)
	check(raid.hero.get("collecting_gold",false) and raid.hero.collect_gold == 25, "thief finds shared gold at an empty member")
	raid._finish_vulpin_collect()
	check(sim.gold == 125 and raid.raid_stats.stolen == 25, "theft debits the reserve once")
	game.frame_updated.emit()
	for marker in view._markers:
		if marker.kind == "treasury":
			check(marker.node.badge.amount == 125, "fill indicator updates after theft")
	test_bonus(game, outside)
	game.free()
	print("Treasury integration: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func test_bonus(game: IsometricGameSession, outside: Vector2i) -> void:
	var sim := game.sim
	check(sim._storage_capacity() == 1050, "one treasury plus one ordinary chest")
	sim.gold = 900
	sim.vault_gold = {outside:150}
	check(sim.transfer_gold(outside, ORIGIN, 150) == 150, "transfer can fill the bonus space")
	check(sim.stored_gold(sim.storage_cells(ORIGIN)) == 900, "all 900 coins are assigned to the room")
	check(sim._deposit_gold(200) == 150 and sim.vault_gold[outside] == 150, "deposit is immediately assigned to the remaining space")
	check(sim._deposit_gold(1) == 0, "full treasury and chest reject more deposits")
	var full := Save.capture(sim,game.raid,game.progression)
	check(Save.apply(full,sim,game.raid,game.progression), "full bonus survives saved-game validation")
	var corrupt := full.duplicate(true)
	corrupt.vault_gold[outside] = 151
	corrupt.gold += 1
	check(not Save.apply(corrupt,sim,game.raid,game.progression), "ordinary chest cannot hold a room-only balance")
	var second := ORIGIN + Vector2i.UP
	for item in [[second,GameTypes.Tool.DIG,5,750], [ORIGIN,GameTypes.Tool.STORE_LOCKED,40,750], [ORIGIN,GameTypes.Tool.DIG,0,600]]:
		var cell: Vector2i = item[0]
		var tool: int = item[1]
		var price: int = item[2]
		var capacity: int = item[3]
		var expected_drop := 1050 - price - capacity
		var preview := game.check_action(cell,tool)
		check(preview.valid and preview.cost == price, "preview excludes coins spilled as loot")
		game.selected = cell
		game.confirm_action(tool)
		check(sim.gold == capacity and sim._storage_capacity() == capacity, "storage shrinks to surviving chests")
		check(sim.loot_bags.size() == 1 and sim.loot_bags[0].pos == cell and sim.loot_bags[0].gold == expected_drop, "only the exact surplus drops at the edit")
		check(Save._valid(Save.capture(sim,game.raid,game.progression)), "dissolved room saves")
		game.undo_build()
		check(sim.gold == 1050 and sim.loot_bags.is_empty() and sim.vault_gold == full.vault_gold, "undo restores bonus balance without duplicating loot")
	# Rebuilding the removed fourth chest restores space to collect the loose coins.
	game.selected = ORIGIN
	game.confirm_action(GameTypes.Tool.DIG)
	game.selected = ORIGIN
	game.confirm_action(GameTypes.Tool.STORE)
	game.selected = ORIGIN
	game.collect_selected()
	check(sim.gold == 1050 and sim.loot_bags.is_empty(), "recovered overflow exactly once after rebuilding")
	# A legacy Core access repair can open a second passage during loading.
	var legacy := full.duplicate(true)
	legacy.grid[8][8] = T.FLOOR
	legacy.grid[6][2] = T.CORE
	check(Save.apply(legacy,sim,game.raid,game.progression), "old-layout migration succeeds")
	check(sim._storage_capacity() == 750 and sim.gold == 750 and sim._unsecured_loot_total() == 300, "bonus lost during migration remains collectible")
