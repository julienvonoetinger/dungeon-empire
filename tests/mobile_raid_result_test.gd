extends SceneTree

var failures: Array[String] = []
var received: Array[Dictionary] = []
var rewards: Array[Dictionary] = []
var sim: DungeonSim
var raid: RaidDirector
var progression: CoreProgression


func _initialize() -> void:
	sim = DungeonSim.new()
	raid = RaidDirector.new()
	progression = CoreProgression.new()
	raid.sim = sim
	sim.raid = raid
	sim.new_map()
	sim.grid[6][6] = GameTypes.Tile.ENTRANCE
	raid.raid_finished.connect(_on_raid_finished)
	seed(4242)
	_test_death_result()
	_test_portal_result()
	sim.raid = null
	raid.sim = null
	if failures.is_empty():
		print("OK: raid result signals, pre-clear snapshots, preservation and exactly-once claims")
	else:
		for failure in failures:
			printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _on_raid_finished(result: Dictionary) -> void:
	received.append(result)
	_check(raid.hero.is_empty(), "completion listener sees cleared hero")
	_check(not raid.raid_active, "completion listener sees preparation state")
	_check(raid.last_result == result, "stored and emitted snapshots agree at completion")
	rewards.append(progression.claim(result))
	# A synchronous listener may try to finish again while handling the result.
	if received.size() <= 2:
		raid._end_raid("duplicate completion from listener")


func _test_death_result() -> void:
	raid._start_raid()
	_check(raid.raid_active and raid.raid_index == 1, "first raid starts")
	sim.core_hp = 80
	raid.hero["kind"] = "paladin"
	raid.hero["name"] = "Test Paladin"
	raid.hero["display"] = "Test Paladin (Brave)"
	raid.hero["carried_gold"] = 37
	raid.raid_stats["traps_spent"] = 2
	raid.raid_stats["core_lost"] = 20
	raid._kill_hero()
	_check(received.size() == 1, "death emits exactly one result, including reentrant completion")
	if received.is_empty():
		return
	var result: Dictionary = received[0]
	_check(result.get("raid_id") == 1, "death snapshot includes raid ID")
	_check(result.get("hero_kind") == "paladin", "hero kind survives clearing")
	_check(result.get("hero_name") == "Test Paladin (Brave)", "hero display name survives clearing")
	_check(result.get("killed") == 1 and result.get("escaped") == 0, "death outcome is structured")
	_check(result.get("core_hp") == 85, "snapshot includes final Core healing")
	_check(result.get("core_lost") == 20 and result.get("traps_spent") == 2, "snapshot includes raid counters")
	_check(result.get("loot_remaining") == 37, "snapshot includes dropped hero loot")
	_check(result.get("structures_damaged") == 0, "snapshot includes structure damage count")
	_check("Test Paladin (Brave) dies" in str(result.get("text", "")), "snapshot preserves outcome text")
	_check(rewards[0].get("xp") == 65 and rewards[0].get("gold") == 70, "death result awards expected XP and gold")
	_check(progression.xp == 65 and progression.last_raid_id == 1, "first reward is recorded")

	var preserved := raid.last_result.duplicate(true)
	raid._end_raid("duplicate completion after return")
	_check(received.size() == 1 and raid.last_result == preserved, "repeated completion preserves original result")
	_check(progression.claim(preserved).is_empty(), "reopening result cannot claim twice")
	_check(progression.xp == 65, "duplicate claim leaves XP unchanged")
	raid.raid_stats["killed"] = 99
	sim.core_hp = 1
	sim.loot_bags.clear()
	_check(raid.last_result == preserved, "live statistics and world changes cannot alter stored result")
	result["hero_name"] = "listener edit"
	result["killed"] = 99
	_check(raid.last_result == preserved, "listener mutation cannot alter stored result")
	_check(progression.claim(result).is_empty(), "modified payload with same ID cannot claim twice")
	_check(progression.xp == 65, "modified duplicate leaves XP unchanged")


func _test_portal_result() -> void:
	var previous := raid.last_result.duplicate(true)
	raid._start_raid()
	_check(raid.raid_index == 2 and raid.raid_active, "next raid starts with a new ID")
	_check(raid.last_result == previous, "last result remains available during next raid")
	sim.core_hp = 60
	raid.hero["kind"] = "thief"
	raid.hero["display"] = "Test Thief (Cautious)"
	raid.hero["carried_gold"] = 18
	raid.raid_stats["stolen"] = 18
	raid.raid_stats["core_lost"] = 25
	raid.raid_stats["traps_spent"] = 1
	raid._hero_escapes()
	_check(received.size() == 1, "portal opening does not emit completion early")
	_check(not raid.hero.is_empty(), "hero remains available during portal animation")
	raid._update_hero(raid.portal_hold + 0.1)
	_check(received.size() == 2, "portal completion emits exactly once for the next raid")
	if received.size() < 2:
		return
	var result: Dictionary = received[1]
	_check(result.get("raid_id") == 2, "portal snapshot includes new raid ID")
	_check(result.get("hero_kind") == "thief" and result.get("hero_name") == "Test Thief (Cautious)", "portal preserves hero identity before clearing")
	_check(result.get("escaped") == 1 and result.get("killed") == 0, "portal outcome uses fresh counters")
	_check(result.get("carried_out") == 18 and result.get("stolen") == 18, "portal snapshot preserves escaped gold")
	_check(result.get("core_hp") == 60 and result.get("core_lost") == 25, "portal snapshot preserves Core state")
	_check(rewards[1].get("xp") == 25 and rewards[1].get("gold") == 30, "second raid can award a distinct reward")
	_check(progression.xp == 90 and progression.last_raid_id == 2, "two distinct raids award exactly once each")
	var preserved := raid.last_result.duplicate(true)
	raid._update_hero(10.0)
	raid._end_raid("late duplicate")
	_check(received.size() == 2 and raid.last_result == preserved, "post-completion updates preserve result and signal count")
	_check(progression.claim(result).is_empty(), "latest result cannot be claimed again")
	_check(progression.claim(previous).is_empty(), "older result cannot be reclaimed after a newer raid")
	_check(progression.xp == 90, "all duplicate claims preserve total XP")
	var restored := CoreProgression.new()
	_check(restored.restore(progression.snapshot()), "progression snapshot restores")
	_check(restored.claim(preserved).is_empty() and restored.xp == 90, "saved claim history prevents replay after restore")


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
