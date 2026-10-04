class_name HeroRoster
extends RefCounted

const MAX_VALUE := 2147483647
const MAX_RECORDS := 16384
const STATS := ["max_hp", "greed", "steal_capacity", "fear_weight", "trap_weight", "objective", "door_damage", "flee_ratio", "patience"]
const CLASSES := {"thief": "Vulpin Thief", "paladin": "Lithide Paladin", "ranger": "Batrafian Ranger", "mage": "Sable Mage"}
const NAMES := {"thief": ["Rusk", "Neris", "Varek"], "paladin": ["Borin", "Thoren", "Garran"], "ranger": ["Syll", "Oren", "Tarek"], "mage": ["Maelis", "Sorel", "Ilyr"]}
const OBJECTIVES := {"thief": "vault", "paladin": "core", "ranger": "explore", "mage": "core"}
var profiles: Dictionary = {}
var next_id := 1
var previous_id := 0

static func level_for_xp(xp: int) -> int:
	var level := 1
	while xp >= 25 * level * (level + 1):
		level += 1
	return level

static func display_name(hero: Dictionary) -> String:
	var stored := str(hero.get("name", "Heros"))
	var id := int(hero.get("id", 0))
	for personal_name in NAMES.get(str(hero.get("kind", "")), []):
		if stored == "%s %d" % [personal_name, id]:
			return personal_name
	return stored

func recruit(base: Dictionary) -> Dictionary:
	var stats := {}
	for key in STATS:
		stats[key] = base[key]
	var id := next_id
	next_id += 1
	var names: Array = NAMES[base.kind]
	var profile := {"id": id, "name": "%s %d" % [names[(id - 1) % names.size()], id],
		"class_name": CLASSES[base.kind], "kind": base.kind, "trait": base.trait,
		"xp": 0, "discovered": {}, "stats": stats}
	profiles[id] = profile
	return profile.duplicate(true)

func reset() -> void:
	profiles.clear()
	next_id = 1
	previous_id = 0

func select_return(pressure: int, vulpin_only: bool, rng: RandomNumberGenerator) -> Dictionary:
	var groups := {}
	for id in profiles:
		var p: Dictionary = profiles[id]
		if id == previous_id or (vulpin_only and p.kind != "thief"):
			continue
		if not groups.has(p.kind):
			groups[p.kind] = []
		groups[p.kind].append(id)
	if groups.is_empty() or rng.randf() >= 0.5:
		return {}
	var total := 0
	for kind in groups:
		total += 1 + maxi(0, pressure) if kind == "mage" else 1
	var roll := rng.randi_range(0, total - 1)
	for kind in groups:
		roll -= 1 + maxi(0, pressure) if kind == "mage" else 1
		if roll < 0:
			var ids: Array = groups[kind]
			return profiles[ids[rng.randi_range(0, ids.size() - 1)]].duplicate(true)
	return {}

func snapshot() -> Dictionary:
	return {"profiles": profiles, "next_id": next_id, "previous_id": previous_id}.duplicate(true)

static func experience_breakdown(ledger: Dictionary) -> Dictionary:
	var locks: Dictionary = ledger.get("locks", {})
	var obstacles: Dictionary = ledger.get("obstacles", {}).duplicate()
	for cell in locks:
		obstacles.erase(cell)
	var result := {"survival": 10, "gold": maxi(0, int(ledger.get("acquired_gold", 0))) / 5,
		"locks": locks.size() * 15, "obstacles": obstacles.size() * 15,
		"core": maxi(0, int(ledger.get("core_damage", 0))),
		"discovery": mini(20, ledger.get("discoveries", {}).size())}
	var total := 0
	for amount in result.values():
		total += int(amount)
	result["total"] = total
	return result

func finish(id: int, survived: bool, ledger: Dictionary) -> Dictionary:
	if not profiles.has(id):
		return {}
	var profile: Dictionary = profiles[id]
	var before := level_for_xp(profile.xp)
	var breakdown := experience_breakdown(ledger) if survived else {}
	var gained := int(breakdown.get("total", 0))
	if survived:
		profile.xp = mini(MAX_VALUE, int(profile.xp) + gained)
		profile.discovered.merge(ledger.get("discoveries", {}), true)
	else:
		profiles.erase(id)
	return {"hero_id": id, "hero_xp_breakdown": breakdown, "hero_xp_gained": gained,
		"hero_xp_total": int(profile.xp), "hero_level_before": before,
		"hero_level_after": level_for_xp(profile.xp)}

func restore(data: Dictionary) -> bool:
	if not valid_snapshot(data):
		return false
	profiles = data.profiles.duplicate(true)
	next_id = data.next_id
	previous_id = data.previous_id
	return true

static func _keys(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size():
		return false
	for key in keys:
		if not value.has(key):
			return false
	return true

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return value is int and value >= minimum and value <= maximum

static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum - 0.000001 and value <= maximum + 0.000001

static func valid_snapshot(data: Variant) -> bool:
	if not _keys(data, ["profiles", "next_id", "previous_id"]):
		return false
	if not _integer(data.next_id, 1, MAX_VALUE) or not _integer(data.previous_id, 0, data.next_id - 1):
		return false
	if not data.profiles is Dictionary or data.profiles.size() > MAX_RECORDS:
		return false
	var names := {}
	for id in data.profiles:
		if not _integer(id, 1, data.next_id - 1):
			return false
		var p: Variant = data.profiles[id]
		if not _keys(p, ["id", "name", "class_name", "kind", "trait", "xp", "discovered", "stats"]):
			return false
		if not p.id is int or p.id != id or not p.kind is String or not CLASSES.has(p.kind):
			return false
		if not p.name is String or p.name.strip_edges().is_empty() or p.name.length() > 100 or names.has(p.name):
			return false
		names[p.name] = true
		if p.class_name != CLASSES[p.kind] or not p.trait is String or not GameTypes.TRAITS.has(p.trait):
			return false
		if not _integer(p.xp, 0, MAX_VALUE) or not _keys(p.stats, STATS):
			return false
		var s: Dictionary = p.stats
		var hp: int = {"thief": 68, "paladin": 115, "ranger": 82, "mage": 74}[p.kind]
		var damage: int = {"thief": 18, "paladin": 34, "ranger": 20, "mage": 8}[p.kind]
		if not _integer(s.max_hp, hp - 6, hp + 6) or not _integer(s.door_damage, damage - 3, damage + 3):
			return false
		var mods: Dictionary = GameTypes.TRAITS[p.trait]
		var base: Array = {"thief": [1.2, 1.0, 0.45, 90], "paladin": [-0.25, 0.55, 0.15, 140], "ranger": [0.75, 1.55, 0.4, 70], "mage": [0.45, 0.85, 0.3, 110]}[p.kind]
		var patience := int(base[3]) + int(mods.patience)
		if s.objective != OBJECTIVES[p.kind] or not _integer(s.patience, maxi(25, patience - 10), maxi(25, patience + 10)):
			return false
		if not _number(s.greed, float(mods.greed) - 0.15, float(mods.greed) + 0.15):
			return false
		var minimum_capacity := int(round(90.0 * float(s.greed))) if p.kind == "thief" else 1
		var maximum_capacity := int(round(160.0 * float(s.greed))) if p.kind == "thief" else 1
		if not _integer(s.steal_capacity, minimum_capacity, maximum_capacity):
			return false
		var fear := float(base[0]) + float(mods.fear)
		var trap := float(base[1]) + float(mods.trap)
		var flee := float(base[2]) + float(mods.flee)
		if not _number(s.fear_weight, fear - 0.20, fear + 0.20) or not _number(s.trap_weight, maxf(0.05, trap - 0.20), maxf(0.05, trap + 0.20)):
			return false
		if not _number(s.flee_ratio, clampf(flee - 0.05, 0.05, 0.8), clampf(flee + 0.05, 0.05, 0.8)):
			return false
		if not p.discovered is Dictionary or p.discovered.size() > GameTypes.COLS * GameTypes.ROWS:
			return false
		for cell in p.discovered:
			if not cell is Vector2i or cell.x < 0 or cell.y < 0 or cell.x >= GameTypes.COLS or cell.y >= GameTypes.ROWS:
				return false
			if not p.discovered[cell] is bool or not p.discovered[cell]:
				return false
	return true
