extends SceneTree

var m: Control
var failures: Array[String] = []

func _initialize() -> void:
    var script: GDScript = load("res://scripts/Main.gd")
    m = script.new()
    root.add_child(m)
    if m.grid.is_empty():
        m._new_map()   # _ready is not triggered inside this SceneTree harness.
    seed(4242)
    print("grid: ", m.grid.size(), "x", (m.grid[0] as Array).size())

    _test_sprite_pack()
    _test_isometric()
    _test_camera()
    _test_dungeon_input_not_stolen()
    _test_sealed_core_start()
    _test_build_rules()
    _test_door_facing()
    _test_trap_wear_and_repair()
    _test_death_and_theft()
    _test_personalities()
    _test_report_fields()
    _test_raids()
    _test_loot_and_corpses()
    _test_trapped_corridor()

    print("--- result ---")
    if failures.is_empty():
        print("OK: all checks pass.")
    else:
        for f in failures:
            print("FAIL: ", f)
    quit(0 if failures.is_empty() else 1)

func click_named(tool: int) -> void:
    var specs: Array = m._buttons()
    for i in range(specs.size()):
        if int(specs[i]["tool"]) == tool:
            click_tool(i)
            return
    check(false, "toolbar is missing tool %d" % tool)

func core_cell() -> Vector2i:
    return m._find_tile(m.Tile.CORE)

func ensure_entrance() -> void:
    if m._has_entrance():
        return
    var c: Vector2i = core_cell()
    var p := Vector2i(c.x - 1, c.y)
    click_named(m.Tool.BUILD_ENTRANCE)
    click_cell(p)

func core_east_floor() -> Vector2i:
    var c: Vector2i = core_cell()
    return Vector2i(c.x + m.CORE_W, c.y)

func core_se_floor() -> Vector2i:
    var c: Vector2i = core_cell()
    return Vector2i(c.x + m.CORE_W, c.y + 1)

func corridor_south() -> Vector2i:
    var c: Vector2i = core_cell()
    var p := Vector2i(c.x, c.y + m.CORE_H + 1)
    if int(m.grid[p.y][p.x]) == m.Tile.ROCK:
        click_named(m.Tool.DIG)
        click_cell(p)
    return p

func corridor_east() -> Vector2i:
    var c: Vector2i = core_cell()
    var p := Vector2i(c.x + m.CORE_W + 1, c.y)
    if int(m.grid[p.y][p.x]) == m.Tile.ROCK:
        click_named(m.Tool.DIG)
        click_cell(p)
    return p

func _test_sealed_core_start() -> void:
    print("== sealed core start ==")
    m._new_map()
    var c: Vector2i = core_cell()
    check(c.x >= 0, "Core missing at start")
    check(m._find_tile(m.Tile.ENTRANCE).x < 0, "entrance already present at start")
    var floors := 0
    var cores := 0
    for y in range(m.ROWS):
        for x in range(m.COLS):
            var t: int = int(m.grid[y][x])
            if t == m.Tile.CORE:
                cores += 1
            elif t == m.Tile.FLOOR:
                floors += 1
    check(cores == m.CORE_W * m.CORE_H, "Core is not 2x2 (got %d cells)" % cores)
    check(floors == 9, "Core ring is not 9 floors + starter vaults (got %d floors)" % floors)
    var vaults := 0
    for y in range(m.ROWS):
        for x in range(m.COLS):
            if int(m.grid[y][x]) == m.Tile.VAULT:
                vaults += 1
    check(vaults == ceili(float(m.START_GOLD) / float(m.VAULT_CAPACITY)), "starter storage missing (got %d vaults)" % vaults)
    check(int(m._storage_state()["unstored"]) == 0, "starting gold is not fully in storage")
    check(m.gold == m.START_GOLD, "starting gold changed")
    check(m.gold <= int(m._storage_state()["capacity"]), "treasury exceeds storage capacity")
    var gold_before: int = m.gold
    var timer_before: float = m.raid_timer
    for i in range(40):
        m._process(0.5)
    check(not m.raid_active, "a raid started before any entrance existed")
    check(is_equal_approx(m.raid_timer, timer_before), "raid countdown ran with no entrance")
    var west: Vector2i = c + Vector2i.LEFT
    click_named(m.Tool.BUILD_ENTRANCE)
    check(m.selected_tool == m.Tool.BUILD_ENTRANCE, "Entrance tool did not stay selected")
    click_cell(west)
    check(tile(west) == m.Tile.ENTRANCE, "free entrance not placed on a ring floor")
    check(m.gold == gold_before, "entrance was not free")
    click_cell(core_east_floor())
    check(tile(core_east_floor()) == m.Tile.FLOOR, "second entrance placed (must be permanent / unique)")
    click_named(m.Tool.DIG)
    click_cell(west)
    check(tile(west) == m.Tile.ENTRANCE, "placed entrance was modified")
    m._process(0.5)
    check(m.raid_timer < timer_before - 0.2 or m.raid_timer <= m.RAID_DELAY - 0.2, "placing the entrance did not start the raid delay")
    m._new_map()

func _test_sprite_pack() -> void:
    print("== art-bible sprite pack ==")
    for path in [
        "res://assets/sprites/wrap_rock.png",
        "res://assets/sprites/wrap_outer_a.jpg",
        "res://assets/sprites/wrap_outer_b.jpg",
        "res://assets/sprites/wrap_floor.png",
        "res://assets/sprites/tile_entrance.png",
        "res://assets/sprites/tile_core.png",
        "res://assets/sprites/tile_vault.png",
        "res://assets/sprites/tile_spike.png",
        "res://assets/sprites/tile_snare.png",
        "res://assets/sprites/tile_door.png",
        "res://assets/sprites/prop_corpse.png",
        "res://assets/sprites/prop_loot.png",
        "res://assets/sprites/hero_thief.png",
        "res://assets/sprites/hero_paladin.png",
        "res://assets/sprites/hero_ranger.png",
    ]:
        check(ResourceLoader.exists(path) or FileAccess.file_exists(path), "missing sprite %s" % path)
    for key in ["rock", "floor", "entrance", "core", "vault", "spike", "snare", "door", "corpse", "loot", "thief", "paladin", "ranger"]:
        check(m._sprite(key) != null, "Main did not load sprite '%s'" % key)
    check(m._sprite("rock").get_width() >= 256, "rock wrap texture too small")
    check(m._sprite("floor").get_width() >= 256, "floor wrap texture too small")

func check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)

func click(pos: Vector2) -> void:
    var ev := InputEventMouseButton.new()
    ev.button_index = MOUSE_BUTTON_LEFT
    ev.pressed = true
    ev.position = pos
    m._input(ev)

func click_tool(index: int) -> void:
    var r: Rect2 = m._buttons()[index]["rect"]
    click(r.get_center())

func click_cell(p: Vector2i) -> void:
    # Live picking is a 3D ray against cell volumes. Tests place on a known
    # cell without depending on whether a taller neighbour occludes it.
    m._build_at(p)
    m._sync_world()

func _test_dungeon_input_not_stolen() -> void:
    print("== dungeon clicks vs toolbar ==")
    m._reset_camera()
    m.selected_tool = m.Tool.DIG
    var far := Vector2i(19, 11)
    var screen: Vector2 = m._board_to_screen(m._cell_pos(far))
    check(m._screen_to_grid(screen) == far, "south-east cell does not pick under the camera")
    click(screen)
    check(m.selected_tool == m.Tool.DIG, "a dungeon click was treated as a toolbar click")
    var wheel := InputEventMouseButton.new()
    wheel.button_index = MOUSE_BUTTON_WHEEL_UP
    wheel.pressed = false
    wheel.position = m._board_to_screen(m._cell_pos(Vector2i(4, 5)))
    var z_before: float = m.cam_zoom
    m._input(wheel)
    check(m.cam_zoom > z_before + 0.01, "wheel zoom ignored unless pressed=true (got %s -> %s)" % [z_before, m.cam_zoom])
    m._reset_camera()

func _test_isometric() -> void:
    print("== 3D ortho picking ==")
    var a: Vector2 = m._cell_pos(Vector2i(3, 5))
    var east: Vector2 = m._cell_pos(Vector2i(4, 5))
    var south: Vector2 = m._cell_pos(Vector2i(3, 6))
    check(east.x > a.x, "X+ should move right on the 45° ortho view")
    check(south.y > a.y or south.x != a.x, "Y+ should move on screen vs X+")
    check(not is_equal_approx(a.x, east.x) or not is_equal_approx(a.y, east.y), "neighbours collapsed to one screen point")
    for p in [Vector2i(0, 0), Vector2i(2, 2), Vector2i(18, 1), Vector2i(19, 11)]:
        var picked: Vector2i = m._screen_to_grid(m._board_to_screen(m._cell_pos(p)))
        check(picked == p, "3D picking missed %s (got %s)" % [p, picked])

func _test_camera() -> void:
    print("== dungeon camera ==")
    m._reset_camera()
    check(m.cam_zoom >= m.ZOOM_MIN, "fitted zoom is below the minimum")
    var home := Vector2i(3, 3)
    var screen: Vector2 = m._board_to_screen(m._cell_pos(home))
    check(m._screen_to_grid(screen) == home, "screen-to-grid misses the cell at default zoom")
    var z_before: float = m.cam_zoom
    m._zoom_at(screen, 1.25)
    check(m.cam_zoom > z_before + 0.01, "wheel zoom did not increase")
    check(m._screen_to_grid(screen) == home, "zoom-at-cursor moved the cell under the pointer")
    m.cam_pan += Vector2(40, -15)
    var moved: Vector2 = m._board_to_screen(m._cell_pos(home))
    check(m._screen_to_grid(moved) == home, "pan broke cell picking")
    m._reset_camera()
    check(not m._cam_custom, "camera reset did not return to a fitted view")
    check(m._screen_to_grid(m._board_to_screen(m._cell_pos(home))) == home, "fitted camera broke cell picking")
    m._orbit_yaw(90.0)
    check(not is_equal_approx(m.cam_yaw, m.YAW_DEFAULT), "orbit did not change yaw")
    check(m._screen_to_grid(m._board_to_screen(m._cell_pos(home))) == home, "orbit broke cell picking")
    m._reset_camera()
    check(is_equal_approx(m.cam_yaw, m.YAW_DEFAULT), "camera reset did not restore yaw")

func tile(p: Vector2i) -> int:
    return int(m.grid[p.y][p.x])

func _test_build_rules() -> void:
    print("== build rules ==")
    m._new_map()
    var c: Vector2i = core_cell()
    click_named(m.Tool.DIG)
    var gold_before: int = m.gold
    click_cell(Vector2i(15, 1))
    check(tile(Vector2i(15, 1)) == m.Tile.ROCK, "isolated rock dug without an adjacent passage")
    check(m.gold == gold_before, "gold spent on a rejected dig")

    var north := Vector2i(c.x, c.y - 2)
    click_cell(north)
    check(tile(north) == m.Tile.FLOOR, "adjacent dig rejected")
    click_cell(Vector2i(c.x - 1, c.y - 2))
    click_cell(Vector2i(c.x - 2, c.y - 2))
    click_cell(Vector2i(c.x - 3, c.y - 2))
    check(tile(Vector2i(c.x - 3, c.y - 2)) == m.Tile.FLOOR, "branch not dug")

    click_cell(c)
    check(tile(c) == m.Tile.CORE, "Core modified")

    click_named(m.Tool.STORE)
    click_cell(Vector2i(c.x - 3, c.y - 2))
    check(tile(Vector2i(c.x - 3, c.y - 2)) == m.Tile.VAULT, "storage not placed")
    click_named(m.Tool.TRAP_SPIKE)
    click_cell(core_east_floor())
    click_named(m.Tool.TRAP_SNARE)
    click_cell(core_se_floor())
    click_named(m.Tool.BUILD_DOOR)
    click_cell(c + Vector2i(-1, 0))
    check(tile(c + Vector2i(-1, 0)) != m.Tile.DOOR, "door placed in the open room")
    check(m.message.contains("between two walls"), "misplaced door was not rejected")
    var slot := corridor_south()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(slot)
    check(tile(slot) == m.Tile.DOOR, "door not placed between walls")
    check(int(m.door_hp.get(slot, 0)) == m.DOOR_MAX_HP, "door HP not initialised")
    check(int(m.trap_charges.get(core_east_floor(), 0)) == m.TRAP_MAX_CHARGES, "trap charges not initialised")

    click_named(m.Tool.BUILD_DOOR)
    click_cell(north)
    check(tile(north) != m.Tile.DOOR, "door placed on an open branch")
    click_named(m.Tool.TRAP_SPIKE)
    click_cell(north)
    check(not m.door_hp.has(north), "ghost door_hp entry after replacement")

    var storage: Dictionary = m._storage_state()
    var vaults: Dictionary = storage["vaults"]
    var vault_p := Vector2i(c.x - 3, c.y - 2)
    check(int(vaults.get(vault_p, -1)) == mini(m.gold, m.VAULT_CAPACITY), "storage filled incorrectly")
    check(int(storage["unstored"]) == 0, "treasury is not fully inside storage")

    var gold_now: int = m.gold
    click_named(m.Tool.RESET)
    check(m.reset_armed, "Reset not armed on the first click")
    check(m.gold == gold_now, "Reset applied on the very first click")
    click_named(m.Tool.DIG)
    check(not m.reset_armed, "Reset still armed after another click")

func _test_door_facing() -> void:
    print("== door facing ==")
    m._new_map()
    var c: Vector2i = core_cell()
    var ns := corridor_south()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(ns)
    check(is_equal_approx(m.dungeon._door_yaw(ns, m), 0.0), "north-south corridor door faces the wrong way")
    var ew := corridor_east()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(ew)
    check(is_equal_approx(m.dungeon._door_yaw(ew, m), PI * 0.5), "east-west corridor door faces the wrong way")
    m._new_map()

func _test_trap_wear_and_repair() -> void:
    print("== defense wear and repairs ==")
    m._new_map()
    var c: Vector2i = core_cell()
    var spike: Vector2i = core_east_floor()
    var door: Vector2i = corridor_south()
    click_named(m.Tool.TRAP_SPIKE)
    click_cell(spike)
    click_named(m.Tool.BUILD_DOOR)
    click_cell(door)
    ensure_entrance()

    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["door_damage"] = 18

    # Every trigger consumes one charge and wounds the hero.
    for i in range(m.TRAP_MAX_CHARGES):
        var hp_before: int = int(m.hero["hp"])
        m.hero["pos"] = spike
        m._resolve_cell(spike)
        check(int(m.hero["hp"]) < hp_before, "the spikes did not wound the hero (charge %d)" % i)
    check(int(m.trap_charges[spike]) == 0, "spike charges not consumed")

    # Spent defense: no effect at all until repaired.
    var hp_worn: int = int(m.hero["hp"])
    m._resolve_cell(spike)
    check(int(m.hero["hp"]) == hp_worn, "a spike without charges still wounds")

    # The door takes damage, then gives way, and stays broken.
    m._attack_door(door)
    check(int(m.door_hp[door]) == m.DOOR_MAX_HP - 18, "door HP not decremented")
    for i in range(5):
        if tile(door) == m.Tile.DOOR:
            m._attack_door(door)
    check(tile(door) == m.Tile.DOOR, "indestructible door")
    check(int(m.door_hp.get(door, -1)) == 0, "forced door did not stay as wreckage")

    # Repairs outside a raid: the spike regains charges, the destroyed door stays destroyed.
    m._end_raid("end of test")
    var repair_door: Vector2i = corridor_east()
    m.selected_tool = m.Tool.BUILD_DOOR
    click_cell(repair_door)
    m.door_hp[repair_door] = 20
    var gold_before: int = m.gold
    click_named(m.Tool.REPAIR)
    check(int(m.trap_charges[spike]) == m.TRAP_MAX_CHARGES, "spike charges not restored")
    check(int(m.door_hp.get(repair_door, 0)) == m.DOOR_MAX_HP, "door not repaired")
    check(tile(door) == m.Tile.DOOR and int(m.door_hp.get(door, -1)) == 0, "destroyed door resurrected by the repair")
    var expected: int = m.COST_REPAIR_DOOR + m.TRAP_MAX_CHARGES * m.COST_REPAIR_TRAP
    check(m.gold == gold_before - expected, "unexpected repair cost (%d instead of %d)" % [gold_before - m.gold, expected])
    m._new_map()

func _test_death_and_theft() -> void:
    print("== death, corpse, theft ==")
    m._new_map()
    var c: Vector2i = core_cell()
    var spike: Vector2i = core_east_floor()
    click_named(m.Tool.TRAP_SPIKE)
    click_cell(spike)
    ensure_entrance()

    # Death on a spike: corpse + loot left in place, essence absorbed by the Core.
    m.core_hp = 90
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["hp"] = 5
    m.hero["carried_gold"] = 120
    m.hero["pos"] = spike
    m._resolve_cell(spike)
    check(not m.raid_active, "the raid continues after the hero died")
    check(m.corpses.size() == 1 and m.corpses[0]["pos"] == spike, "corpse missing or misplaced")
    check(m.loot_bags.size() == 1 and int(m.loot_bags[0]["gold"]) == 120, "dead hero's loot not left in place")
    check(m.core_hp == 92, "Core healed incorrectly by a thief's death (%d)" % m.core_hp)
    check(m._corpse_danger_near(spike) > 0.0, "the corpse does not raise perceived danger")

    # The Core never exceeds 100%.
    m.core_hp = 99
    m._start_raid()
    m.hero["kind"] = "paladin"
    m.hero["hp"] = 0
    m._kill_hero()
    check(m.core_hp == m.CORE_MAX, "Core integrity beyond 100%% (%d)" % m.core_hp)

    # Robbing a storage: the thief carries away only what fits in its bag.
    m._new_map()
    var vault: Vector2i = core_cell() + Vector2i(1, -1)
    click_named(m.Tool.STORE)
    click_cell(vault)
    ensure_entrance()
    var treasury: int = m.gold
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["steal_capacity"] = 40
    m.hero["pos"] = vault
    m._resolve_cell(vault)
    check(m.gold == treasury - 40, "theft not limited by carrying capacity (%d -> %d)" % [treasury, m.gold])
    check(not m.raid_active, "the thief does not teleport out after stealing")

    # What the thief could not carry stays in the storage (single vault, no surplus).
    m.gold = 100
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["steal_capacity"] = 40
    m.hero["pos"] = vault
    m._resolve_cell(vault)
    var left: Dictionary = m._storage_state()
    check(m.gold == 60, "partial theft took the wrong amount (%d left)" % m.gold)
    check(int((left["vaults"] as Dictionary).get(vault, -1)) == 60, "the rest of the hoard did not stay in the storage")

    # A capacity larger than the hoard empties it without going negative.
    m.gold = 90
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["steal_capacity"] = 500
    m.hero["pos"] = vault
    m._resolve_cell(vault)
    check(m.gold == 0, "large capacity did not empty the storage (%d left)" % m.gold)

    # An empty storage does not end the raid: the thief ignores it afterwards.
    m.gold = 0
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["pos"] = vault
    m._resolve_cell(vault)
    check(m.raid_active, "an empty storage ends the raid")
    check(m.hero["ignored"].has(vault), "the empty storage is not remembered as useless")

    # No virtual gold beside the Core: reaching it damages the Core only.
    m.gold = mini(m.gold, m._storage_capacity())
    var treasury_at_core: int = m.gold
    var core: Vector2i = m._find_tile(m.Tile.CORE)
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["steal_capacity"] = 500
    m.hero["pos"] = core
    m._resolve_cell(core)
    check(m.gold == treasury_at_core, "Core contact stole dungeon gold without a storage tile (%d -> %d)" % [treasury_at_core, m.gold])
    check(m.core_hp < m.CORE_MAX, "the Core took no damage")
    m._new_map()

func _test_personalities() -> void:
    print("== personalities and per-hero variation ==")
    m._new_map()
    ensure_entrance()
    var traits := {}
    var fear_by_kind := {}
    for i in range(60):
        m._start_raid()
        var kind := String(m.hero["kind"])
        traits[String(m.hero["trait"])] = true
        if not fear_by_kind.has(kind):
            fear_by_kind[kind] = {}
        (fear_by_kind[kind] as Dictionary)[snappedf(float(m.hero["fear_weight"]), 0.001)] = true
        check(String(m.hero["display"]).contains(String(m.hero["trait"])), "the trait is not part of the displayed name")
        check(float(m.hero["greed"]) > 0.0, "greed not rolled")
        m._end_raid("end of test")
    print("traits seen: ", traits.keys())
    check(traits.size() >= 3, "too few distinct traits rolled (%d)" % traits.size())
    for kind in fear_by_kind.keys():
        var spread: int = (fear_by_kind[kind] as Dictionary).size()
        check(spread > 1, "%s heroes all share the same fear weight: dungeons stay solvable" % kind)
    m._new_map()

func _test_report_fields() -> void:
    print("== post-raid report ==")
    m._new_map()
    var c: Vector2i = core_cell()
    ensure_entrance()
    var d: Vector2i = corridor_south()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(d)
    m.door_hp[d] = 20
    click_named(m.Tool.TRAP_SPIKE)
    click_cell(core_east_floor())
    m.trap_charges[core_east_floor()] = 1
    m.loot_bags.append({"pos": c + Vector2i.UP, "gold": 77, "taken": false})
    m._start_raid()
    m._end_raid("end of test")
    for field in ["killed:", "escaped:", "gold stolen:", "loot remaining: 77", "doors destroyed:", "structures damaged: 2", "Core:"]:
        check(m.report.contains(field), "report is missing \"%s\" (got: %s)" % [field, m.report])
    m._new_map()

func _build_test_dungeon() -> void:
    ensure_entrance()
    var c: Vector2i = core_cell()
    click_named(m.Tool.DIG)
    for p in [Vector2i(c.x, c.y - 2), Vector2i(c.x - 1, c.y - 2), Vector2i(c.x - 2, c.y - 2), Vector2i(c.x - 3, c.y - 2)]:
        click_cell(p)
    click_named(m.Tool.STORE)
    click_cell(Vector2i(c.x - 3, c.y - 2))
    click_named(m.Tool.TRAP_SPIKE)
    click_cell(core_east_floor())
    click_named(m.Tool.TRAP_SNARE)
    click_cell(core_se_floor())
    click_named(m.Tool.BUILD_DOOR)
    click_cell(corridor_south())

func _test_raids() -> void:
    print("== raid loop ==")
    _build_test_dungeon()

    var raids_seen := 0
    var raid_frames := 0
    var max_raid_frames := 0
    var campaigns := 0
    var defeat_checked := false
    var was_active := false
    var kinds := {}

    for i in range(80000):
        if raids_seen >= 15 and kinds.size() == 3:
            break
        if raids_seen >= 40:
            break
        if m.game_over:
            campaigns += 1
            if not defeat_checked:
                defeat_checked = true
                _check_defeat_is_locked()
            else:
                click_named(m.Tool.RESET)
            _build_test_dungeon()
            was_active = false
            continue
        m._process(0.1)

        if m.raid_active:
            raid_frames += 1
            if not was_active:
                raids_seen += 1
                kinds[String(m.hero["kind"])] = true
            var hp: Vector2i = m.hero["pos"]
            check(m._walkable(hp), "hero standing outside a walkable passage")
            check(not m._door_intact(hp), "hero walks through an intact door")
        else:
            max_raid_frames = maxi(max_raid_frames, raid_frames)
            raid_frames = 0
            # Outside a raid the player is back in control: repair now and then.
            if raids_seen > 0 and raids_seen % 3 == 0:
                click_named(m.Tool.REPAIR)
        was_active = m.raid_active

        check(m.core_hp >= 0 and m.core_hp <= m.CORE_MAX, "Core integrity out of bounds (%d)" % m.core_hp)
        check(m.gold >= 0, "negative gold (%d)" % m.gold)

    print("raids simulated: ", raids_seen, " | campaigns lost: ", campaigns, " | archetypes seen: ", kinds.keys())
    print("longest raid: ", max_raid_frames * 0.1, " s")
    print("Core: ", m.core_hp, " | corpses: ", m.corpses.size(), " | loot bags: ", m.loot_bags.size())
    print("last report: ", m.report)
    check(raids_seen >= 15, "too few raids simulated (%d)" % raids_seen)
    check(max_raid_frames * 0.1 < 240.0, "abnormally long raid (%.1f s): possible lock" % (max_raid_frames * 0.1))
    check(kinds.size() == 3, "the three archetypes were not all encountered")
    check(defeat_checked, "no defeat encountered: end state not verified")

# After defeat: no raid, no countdown, no building — Reset aside.
func _check_defeat_is_locked() -> void:
    var timer_before: float = m.raid_timer
    for i in range(2000):
        m._process(0.1)
    check(not m.raid_active, "a raid starts after the defeat")
    check(m.raid_timer == timer_before, "the countdown keeps running after the defeat")
    var gold_before: int = m.gold
    click_named(m.Tool.DIG)
    click_cell(core_cell() + Vector2i(0, -2))
    check(m.gold == gold_before, "building still possible after the defeat")
    click_named(m.Tool.RESET)
    check(not m.game_over and m.core_hp == m.CORE_MAX, "Reset does not restart the campaign")

# Regression: a corridor paved with spikes used to pin the hero on the first
# cell, stepping back into the dead-end entrance and forward again forever,
# because a single feared neighbour always outweighed the backtrack penalty.
# A trap must raise the price of a route, never seal the only way on.
func _test_trapped_corridor() -> void:
    print("== trapped corridor ==")
    var deepest := 1
    var pointless_returns := 0
    var seen_kinds := {}

    for attempt in range(60):
        m._new_map()
        var c: Vector2i = core_cell()
        m.grid[c.y][1] = m.Tile.ENTRANCE
        for x in range(2, c.x):
            m.grid[c.y][x] = m.Tile.SPIKE
        m._start_raid()
        seen_kinds[String(m.hero["kind"])] = true
        var previous: Vector2i = m.hero["pos"]

        for i in range(600):
            if not m.raid_active:
                break
            m._process(0.1)
            if not m.raid_active:
                break
            var pos: Vector2i = m.hero["pos"]
            deepest = maxi(deepest, pos.x)
            # The entrance is a dead end here: walking back into it while still
            # exploring is the exact symptom this test guards against.
            if pos != previous and int(m.grid[pos.y][pos.x]) == m.Tile.ENTRANCE and not bool(m.hero["fleeing"]):
                pointless_returns += 1
            previous = pos

    print("deepest column reached: ", deepest, " | pointless returns to the entrance: ", pointless_returns)
    check(seen_kinds.size() == 3, "the three archetypes were not all tested on the spike line")
    check(deepest >= 4, "heroes never get past the first cells of a trapped corridor (deepest column %d)" % deepest)
    check(pointless_returns == 0, "hero walks back into the dead-end entrance while exploring (%d times)" % pointless_returns)

func _test_loot_and_corpses() -> void:
    print("== loot and corpses ==")
    m._new_map()   # The previous loop stops in the middle of a raid.
    ensure_entrance()
    var c: Vector2i = core_cell()
    m.loot_bags.append({"pos": c + Vector2i.UP, "gold": 77, "taken": false})
    m.corpses.append({"pos": c + Vector2i(-1, -1), "name": "test", "fear": 18.0})

    # Clicking the bag where it is actually drawn must secure it.
    var gold_before: int = m.gold
    click(m._board_to_screen(m._bag_pos(m.loot_bags[0])))
    check(m.gold == gold_before + 77, "loot not stored on click (gold %d -> %d)" % [gold_before, m.gold])
    check(m.loot_bags.is_empty(), "loot bag still present")

    # Full storage: loot stays on the body.
    m.gold = m._storage_capacity()
    m.loot_bags.append({"pos": c + Vector2i.UP, "gold": 40, "taken": false})
    click(m._board_to_screen(m._bag_pos(m.loot_bags[0])))
    check(m.gold == m._storage_capacity(), "loot stored past capacity")
    check(m.loot_bags.size() == 1 and int(m.loot_bags[0]["gold"]) == 40, "full-storage loot was consumed")
    m.loot_bags.clear()

    # Without the dedicated tool, clicking a corpse does not absorb it.
    m.core_hp = 90
    m.selected_tool = m.Tool.DIG
    click(m._board_to_screen(m._corpse_pos(m.corpses[0])))
    check(m.corpses.size() == 1, "corpse absorbed by accident with the Dig tool")

    # With the Absorb tool it is consumed and heals the Core.
    click_named(m.Tool.ABSORB)
    click(m._board_to_screen(m._corpse_pos(m.corpses[0])))
    check(m.corpses.is_empty(), "corpse not absorbed with the dedicated tool")
    check(m.core_hp == 92, "Core not healed by the absorption (%d)" % m.core_hp)

    # No interaction at all during a raid.
    m.corpses.append({"pos": c + Vector2i(-1, -1), "name": "test", "fear": 18.0})
    m.loot_bags.append({"pos": c + Vector2i.UP, "gold": 50, "taken": false})
    m._start_raid()
    var gold_locked: int = m.gold
    click(m._board_to_screen(m._bag_pos(m.loot_bags[0])))
    click(m._board_to_screen(m._corpse_pos(m.corpses[0])))
    click_named(m.Tool.DIG)
    click_cell(Vector2i(4, 7))
    check(m.gold == gold_locked, "gold changed during a raid")
    check(m.corpses.size() == 1 and m.loot_bags.size() == 1, "loot/corpses manipulated during a raid")
    check(tile(Vector2i(4, 7)) == m.Tile.ROCK, "digging possible during a raid")
