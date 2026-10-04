extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	if not ResourceLoader.exists("res://scripts/game/hero_roster.gd"):
		check(false, "Persistent HeroRoster is missing")
		quit(1)
		return
	var api = load("res://scripts/game/hero_roster.gd")
	for pair in [[0, 1], [49, 1], [50, 2], [149, 2], [150, 3], [750, 6], [2147483647, 9268]]:
		check(api.level_for_xp(pair[0]) == pair[1], "XP boundary %s" % [pair])
	var roster = api.new()
	var base := {"name": "Vulpin Thief", "kind": "thief", "trait": "Greedy", "max_hp": 68,
		"greed": 1.4, "steal_capacity": 140, "fear_weight": 0.9, "trap_weight": 0.8,
		"objective": "vault", "door_damage": 18, "flee_ratio": 0.37, "patience": 105}
	var first: Dictionary = roster.recruit(base)
	var second: Dictionary = roster.recruit(base)
	check(first.id != second.id and first.name != second.name, "individual identity and name")
	check(first.xp == 0 and first.class_name == "Vulpin Thief", "new recruit baseline")
	first.stats.max_hp = 1
	check(roster.profiles[first.id].stats.max_hp == 68, "recruit returns detached data")
	var snapshot: Dictionary = roster.snapshot()
	check(api.valid_snapshot(snapshot), "generated profiles validate")
	var other = api.new()
	check(other.restore(snapshot) and other.snapshot() == snapshot, "profile round trip")
	snapshot.profiles[first.id].stats.max_hp = 1
	check(other.profiles[first.id].stats.max_hp == 68, "restore deep copies")
	for field in ["xp", "id", "kind", "trait", "discovered", "stats"]:
		var bad: Dictionary = roster.snapshot()
		bad.profiles[first.id][field] = null
		var before: Dictionary = other.snapshot()
		check(not other.restore(bad) and before == other.snapshot(), "reject %s atomically" % field)
	var bad: Dictionary = roster.snapshot()
	bad.profiles[first.id].stats.greed = NAN
	check(not api.valid_snapshot(bad), "reject NaN")
	bad = roster.snapshot()
	bad.profiles[first.id].discovered[Vector2i(-1, 0)] = true
	check(not api.valid_snapshot(bad), "reject invalid discovery")
	bad = roster.snapshot()
	bad.next_id = second.id
	check(not api.valid_snapshot(bad), "never reuse allocated IDs")
	roster.reset()
	check(roster.profiles.is_empty() and roster.previous_id == 0 and roster.next_id == 1, "new dungeon resets roster")
	print("Hero roster failures: ", failures)
	quit(1 if failures else 0)
