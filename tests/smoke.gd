extends SceneTree

var m: Control
var failures: Array[String] = []

func _initialize() -> void:
    var script: GDScript = load("res://scripts/Main.gd")
    m = script.new()
    root.add_child(m)
    if m.grid.is_empty():
        m._new_map()   # _ready is not triggered inside this SceneTree harness.
    m.PORTAL_HOLD = 0.0
    seed(4242)
    print("grid: ", m.grid.size(), "x", (m.grid[0] as Array).size())

    _test_rendering_method()
    _test_sprite_pack()
    _test_isometric()
    _test_camera()
    _test_dungeon_input_not_stolen()
    _test_sealed_core_start()
    _test_build_rules()
    _test_door_facing()
    _test_trap_wear_and_repair()
    _test_void_trap_banish()
    _test_death_and_theft()
    _test_personalities()
    _test_report_fields()
    _test_paladin_core_attack_hold()
    _test_vulpin_never_attacks_core()
    _test_paladin_door_attack_hold()
    _test_paladin_unknown_door_commitment()
    _test_vulpin_lockpicking_hold()
    _test_magic_door_rules()
    _test_ranger_trap_jump()
    _test_raids()
    _test_loot_and_corpses()
    _test_trapped_corridor()

    print("--- result ---")
    if failures.is_empty():
        print("OK: all checks pass.")
    else:
        for f in failures:
            print("FAIL: ", f)
    m.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)

func _test_rendering_method() -> void:
    check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus", "desktop renderer uses Forward+")
    check(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile") == "gl_compatibility", "mobile renderer keeps Compatibility")

func _test_paladin_core_attack_hold() -> void:
    print("== paladin Core attack ==")
    m._new_map()
    var core := core_cell()
    m.raid_active = true
    m.core_hp = m.CORE_MAX
    m.hero = {
        "kind": "paladin",
        "display": "Lithide Paladin",
        "pos": core,
        "hp": 100,
        "max_hp": 100,
        "carried_gold": 0,
        "fleeing": false,
        "portaling": false
    }
    m.raid_stats = {"core_lost": 0, "escaped": 0, "carried_out": 0}
    m._resolve_cell(core)
    check(bool(m.hero.get("core_striking", false)), "paladin must enter a Core-strike hold before leaving")
    check(not bool(m.hero.get("portaling", false)), "paladin must not portal before its Core strike is shown")
    check(m.core_hp == m.CORE_MAX, "paladin must not damage the Core before the attack animation impact")
    m._update_hero(2.5)
    check(m.core_hp == m.CORE_MAX, "paladin must not damage the Core before the 2.533-second axe spin finishes")
    m._update_hero(0.04)
    check(m.core_hp == m.CORE_MAX - 42, "paladin must damage the Core when the axe spin reaches its impact")
    check(bool(m.hero.get("portaling", false)), "paladin must portal after completing its Core strike")
    m._new_map()


func _test_vulpin_never_attacks_core() -> void:
    print("== Vulpin Core restraint ==")
    m._new_map()
    var core := core_cell()
    m.raid_active = true
    m.core_hp = m.CORE_MAX
    m.hero = {
        "kind": "thief",
        "display": "Vulpin Thief",
        "pos": core,
        "hp": 68,
        "max_hp": 68,
        "carried_gold": 0,
        "fleeing": false,
        "portaling": false,
        "known": {},
        "bias": {},
        "ignored": {}
    }
    m.raid_stats = {"core_lost": 0, "escaped": 0, "carried_out": 0}
    m._resolve_cell(core)
    check(m.core_hp == m.CORE_MAX, "a Vulpin must never damage the Core")
    check(not bool(m.hero.get("core_striking", false)), "a Vulpin must never enter the Core attack state")
    check(not bool(m.hero.get("portaling", false)), "finding the Core must not make a Vulpin teleport away")
    m._new_map()


func _test_paladin_door_attack_hold() -> void:
    print("== paladin door attack ==")
    m._new_map()
    var door := corridor_south()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(door)
    ensure_entrance()
    m._start_raid()
    m.hero["kind"] = "paladin"
    m.hero["display"] = "Lithide Paladin"
    m.hero["door_damage"] = 20
    var hp_before: int = int(m.door_hp[door])
    m._attack_door(door)
    check(bool(m.hero.get("door_striking", false)), "a Paladin must enter a door-strike state")
    check(int(m.door_hp[door]) == hp_before, "a Paladin must not damage a door before the attack impact")
    m._update_hero(2.5)
    check(int(m.door_hp[door]) == hp_before, "a Paladin must not damage a door before the 2.533-second attack finishes")
    m._update_hero(0.04)
    check(int(m.door_hp[door]) == hp_before - 20, "a Paladin must damage the door at the attack impact")
    m._new_map()


func _test_paladin_unknown_door_commitment() -> void:
    print("== paladin unknown door commitment ==")
    m._new_map()
    var door := corridor_south()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(door)
    ensure_entrance()
    m._start_raid()
    m.hero["kind"] = "paladin"
    m.hero["door_damage"] = 20
    m.hero["known"] = {}
    m._attack_door(door)
    m._update_hero(2.54)
    check(bool(m.hero.get("door_striking", false)), "a Paladin may make a second attempt at an unknown entry door")
    m._update_hero(2.54)
    check(not bool(m.hero.get("door_striking", false)), "a Paladin must stop after two attempts at an unknown door")
    m._new_map()


func _test_vulpin_lockpicking_hold() -> void:
    print("== Vulpin lockpicking ==")
    m._new_map()
    var door := corridor_south()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(door)
    ensure_entrance()
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["display"] = "Vulpin Thief"
    m.hero["door_damage"] = 20
    m.hero["lockpick_success_chance"] = 1.0
    var hp_before: int = int(m.door_hp[door])
    m._attack_door(door)
    check(bool(m.hero.get("lockpicking", false)), "a Vulpin must enter a lockpicking state at a door")
    check(int(m.door_hp[door]) == hp_before, "a Vulpin must not open the door before the lockpicking animation impact")
    m._update_hero(3.0)
    check(int(m.door_hp[door]) == hp_before, "a Vulpin must hold its lockpicking animation before opening the door")
    m._update_hero(0.04)
    check(int(m.door_hp[door]) == 0, "a successful Vulpin lockpick must open the door without breaking it")
    check(bool(m.sim.door_opened.get(door, false)), "a successful Vulpin lockpick must mark the door as opened, not destroyed")
    check(not bool(m.hero.get("lockpicking", false)), "a Vulpin must stop lockpicking after opening the door")

    m._new_map()
    door = corridor_south()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(door)
    ensure_entrance()
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["display"] = "Vulpin Thief"
    m.hero["lockpick_success_chance"] = 0.0
    m._attack_door(door)
    m._update_hero(3.04)
    check(bool(m.hero.get("lockpicking", false)), "a Vulpin gets one final lockpicking attempt after a failure")
    m._update_hero(3.04)
    check(int(m.door_hp[door]) == m.DOOR_MAX_HP, "failed lockpicking must not damage a door")
    check(bool(m.hero.get("avoided_doors", {}).get(door, false)), "a Vulpin must abandon a door after two failed lockpicks")
    m._new_map()


func _test_magic_door_rules() -> void:
    print("== magic door rules ==")
    var magic_tool: int = int(GameTypes.Tool.get("BUILD_MAGIC_DOOR", -1))
    var magic_tile: int = int(GameTypes.Tile.get("MAGIC_DOOR", -1))
    check(magic_tool >= 0, "Magic Door tool missing")
    check(magic_tile >= 0, "Magic Door tile missing")
    if magic_tool < 0 or magic_tile < 0:
        return
    m._new_map()
    var door := corridor_south()
    m.toolbar.open_at(door, Vector2(400, 300))
    check(m.toolbar._tool_enabled(magic_tool), "Magic Door disabled in the radial menu on a valid wall gap")
    m.toolbar.close()
    click_named(magic_tool)
    click_cell(door)
    check(tile(door) == magic_tile, "magic door not placed between walls")
    check(m._door_intact(door), "magic door not treated as an intact door")

    ensure_entrance()
    m._start_raid()
    m.hero["kind"] = "paladin"
    m.hero["display"] = "Lithide Paladin"
    m.hero["door_damage"] = 200
    m._attack_door(door)
    m._update_hero(3.0)
    check(int(m.door_hp[door]) == m.DOOR_MAX_HP, "Paladin damaged an invulnerable magic door")
    check(not bool(m.door_opened.get(door, false)), "Paladin opened a magic door")
    check(bool(m.hero.get("saw_magic_door_blocker", false)), "Paladin did not remember that the raid needs a mage")
    m.raid._open_town_portal("test exit")
    m.raid._finish_town_portal()
    check(int(m.raid.mage_pressure) == 1, "first non-mage magic-door escape did not increase mage pressure")

    m.raid_active = true
    m.hero["kind"] = "thief"
    m.hero["display"] = "Vulpin Thief"
    m.hero["portaling"] = false
    m.hero["lockpick_success_chance"] = 1.0
    m._attack_door(door)
    check(int(m.door_hp[door]) == m.DOOR_MAX_HP, "Vulpin damaged a magic door")
    check(not bool(m.door_opened.get(door, false)), "Vulpin lockpicked a magic door")
    check(bool(m.hero.get("avoided_doors", {}).get(door, false)), "Vulpin did not mark a magic door as impossible")
    m.raid._open_town_portal("test exit")
    m.raid._finish_town_portal()
    check(int(m.raid.mage_pressure) == 2, "mage pressure is not cumulative after repeated non-mage escapes")
    m.raid.mage_pressure = 999
    check(String(m.raid._random_hero_template()["kind"]) == "mage", "high magic-door pressure did not force the next mage")
    check(int(m.raid.mage_pressure) == 0, "mage pressure was not consumed when a mage was chosen")

    m.hero = {
        "kind": "mage",
        "display": "Sable Mage",
        "pos": door + Vector2i(0, -1),
        "hp": 74,
        "max_hp": 74,
        "carried_gold": 0,
        "fleeing": false,
        "portaling": false,
        "known": {},
        "visited": {},
        "bias": {},
        "ignored": {},
        "facing": Vector2i.DOWN,
        "trait": "Arcane",
    }
    m.raid_active = true
    m.hero["kind"] = "mage"
    m.hero["display"] = "Sable Mage"
    m.dungeon.sync(m)
    var mycean: Node3D = m.dungeon._mycean
    var proxy: Node3D = m.dungeon._hero_proxy
    check(mycean != null, "Mage placeholder node missing")
    check(mycean != null and mycean.visible, "Mage placeholder not visible for mage heroes")
    check(proxy != null and not proxy.visible, "Mage still uses the generic hero proxy")
    m._attack_door(door)
    check(bool(m.hero.get("arcane_opening", false)), "Mage must start an arcane opening state at a magic door")
    m._update_hero(1.6)
    check(int(m.door_hp[door]) == 0, "Mage did not open the magic door")
    check(bool(m.door_opened.get(door, false)), "Mage opening must mark the magic door as opened")
    m._new_map()


func _test_ranger_trap_jump() -> void:
    print("== ranger trap jump ==")
    m._new_map()
    var from := core_east_floor()
    var trap := from + Vector2i.RIGHT
    var landing := trap + Vector2i.RIGHT
    ensure_floor(trap)
    ensure_floor(landing)
    click_named(m.Tool.TRAP_SPIKE)
    click_cell(trap)
    var known := {}
    known[trap] = m.Tile.SPIKE
    var visited := {}
    visited[from] = 1
    m.raid_active = true
    m.hero = {
        "kind": "ranger",
        "display": "Batrafian Ranger",
        "pos": from,
        "hp": 82,
        "max_hp": 82,
        "carried_gold": 0,
        "fleeing": false,
        "portaling": false,
        "known": known,
        "visited": visited,
        "ignored": {},
        "bias": {},
        "facing": Vector2i.RIGHT,
    }
    m.raid_stats = {"escaped": 0, "carried_out": 0, "traps_spent": 0}
    check(m.raid._try_trap_jump(from, trap), "ranger did not jump a known active trap")
    check(m.hero["pos"] == landing, "ranger landed at %s instead of %s" % [m.hero["pos"], landing])
    check(bool(m.hero.get("jumping_trap", false)), "ranger jump did not expose the jump animation state")
    check(int(m.trap_charges.get(trap, 0)) == m.TRAP_MAX_CHARGES,
        "ranger jump consumed the trap charge instead of clearing it")
    m._new_map()


func click_named(tool: int) -> void:
    if tool == m.Tool.RESET:
        m._apply_toolbar_tool(tool)
        return
    var specs: Array = m._buttons()
    for i in range(specs.size()):
        if int(specs[i]["tool"]) == tool:
            m._apply_toolbar_tool(tool)
            return
    check(false, "toolbar is missing tool %d" % tool)

func core_cell() -> Vector2i:
    if not m._has_core():
        check(m._place_core(GameTypes.core_origin_cell()), "default Core placement failed")
        sync_test_world()
    return m._find_tile(m.Tile.CORE)

func ensure_floor(p: Vector2i) -> void:
    if m._inside(p) and int(m.grid[p.y][p.x]) == m.Tile.ROCK:
        m.grid[p.y][p.x] = m.Tile.FLOOR
        m._sync_world()
        sync_test_world()

func ensure_entrance() -> void:
    if m._has_entrance():
        return
    var c: Vector2i = core_cell()
    var p := Vector2i(c.x - 1, c.y - 1)
    ensure_floor(p + Vector2i.DOWN)
    ensure_floor(p)
    click_named(m.Tool.BUILD_ENTRANCE)
    click_cell(p)

func ensure_storage_capacity(required: int) -> void:
    var c: Vector2i = core_cell()
    for p in [
        c + Vector2i(1, -1),
        c + Vector2i(2, 0),
        c + Vector2i(2, 1),
        c + Vector2i(0, -1),
        c + Vector2i(-1, 1),
    ]:
        if int(m._storage_state()["capacity"]) >= required:
            return
        ensure_floor(p)
        m.selected_tool = m.Tool.STORE
        m._build_at(p)
    check(int(m._storage_state()["capacity"]) >= required, "could not build enough test storage")

func core_east_floor() -> Vector2i:
    var c: Vector2i = core_cell()
    var p := Vector2i(c.x + m.CORE_W, c.y)
    ensure_floor(p)
    return p

func core_se_floor() -> Vector2i:
    var c: Vector2i = core_cell()
    var p := Vector2i(c.x + m.CORE_W, c.y + 1)
    ensure_floor(p)
    return p

func corridor_south() -> Vector2i:
    var c: Vector2i = core_cell()
    var p := Vector2i(c.x, c.y + m.CORE_H + 1)
    ensure_floor(Vector2i(c.x, c.y + m.CORE_H))
    ensure_floor(p)
    ensure_floor(p + Vector2i.DOWN)
    return p

func corridor_east() -> Vector2i:
    var c: Vector2i = core_cell()
    var p := Vector2i(c.x + m.CORE_W + 1, c.y)
    ensure_floor(Vector2i(c.x + m.CORE_W, c.y))
    ensure_floor(p)
    ensure_floor(p + Vector2i.RIGHT)
    return p

func _test_sealed_core_start() -> void:
    print("== sealed core start ==")
    m._new_map()
    var default_core := GameTypes.core_origin_cell()
    check(not m._has_core(), "Core already present before the anchoring ritual")
    check(m.gold == m.START_GOLD, "starting gold changed before Core placement")
    check(int(m._storage_state()["capacity"]) == 0, "storage exists before Core placement")
    check(not m._place_core(Vector2i(1, 1)), "Core placed outside the 2x2 anchoring grid")
    check(m._can_place_core(Vector2i(14, 14)), "Core cannot anchor flush with the south-east influence boundary")
    var corner_core := Vector2i(0, 0)
    var corner_screen: Vector2 = m._to_world_screen(m.dungeon._world_to_screen(m.dungeon.cell_center(corner_core, m.dungeon.FLOOR_Y + 0.05), m._play_view(), m.cam_zoom))
    click(corner_screen)
    check(m._core_origin() == corner_core, "clicking Core marker %s placed the Core at %s" % [corner_core, m._core_origin()])
    m._new_map()
    var grid_core := Vector2i(6, 6)
    var grid_core_center: Vector3 = m.dungeon.cell_center(grid_core, m.dungeon.FLOOR_Y + 0.05) + Vector3(0.5, 0.0, 0.5)
    var pad_center_screen: Vector2 = m._to_world_screen(m.dungeon._world_to_screen(grid_core_center, m._play_view(), m.cam_zoom))
    var click_cell: Vector2i = m._screen_to_grid(pad_center_screen)
    check(click_cell == grid_core, "Core anchoring pad click resolves to %s instead of %s" % [click_cell, grid_core])
    var pad_edge_screen: Vector2 = m._to_world_screen(m.dungeon._world_to_screen(grid_core_center + Vector3(0.38, 0.0, 0.0), m._play_view(), m.cam_zoom))
    click_cell = m._screen_to_grid(pad_edge_screen)
    check(click_cell == grid_core, "Core anchoring pad edge click resolves to %s instead of %s" % [click_cell, grid_core])
    var grid_core_label_center: Vector3 = m.dungeon.cell_center(grid_core, m.dungeon.FLOOR_Y + 0.12) + Vector3(0.5, 0.0, 0.5)
    var pad_label_edge_screen: Vector2 = m._to_world_screen(m.dungeon._world_to_screen(grid_core_label_center + Vector3(-0.38, 0.0, -0.38), m._play_view(), m.cam_zoom))
    click_cell = m._screen_to_grid(pad_label_edge_screen)
    check(click_cell == grid_core, "Core anchoring visible marker click resolves to %s instead of %s" % [click_cell, grid_core])
    var all_core_pads_pick := true
    for y in range(0, 16, 2):
        for x in range(0, 16, 2):
            var pad := Vector2i(x, y)
            for marker_h in [m.dungeon.FLOOR_Y + 0.05, m.dungeon.FLOOR_Y + 0.12]:
                var marker_center: Vector3 = m.dungeon.cell_center(pad, marker_h) + Vector3(0.5, 0.0, 0.5)
                var screen: Vector2 = m._to_world_screen(m.dungeon._world_to_screen(marker_center, m._play_view(), m.cam_zoom))
                var resolved: Vector2i = m._screen_to_grid(screen)
                if resolved != pad:
                    all_core_pads_pick = false
                    check(false, "Core anchoring marker %s at height %.2f resolves to %s" % [pad, marker_h, resolved])
                    break
            if not all_core_pads_pick:
                break
        if not all_core_pads_pick:
            break
    click(pad_center_screen)
    check(m._has_core(), "clicking a Core anchoring pad did not place the Core")
    if not m._has_core():
        check(m._place_core(default_core), "Core not placed on a valid anchoring site")
    check(m._has_core(), "Core missing after anchoring")
    var c: Vector2i = core_cell()
    check(m.COLS == m.ROWS, "diggable area is not square")
    check(c == grid_core, "Core was not placed on the selected 2x2 grid site")
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
    check(floors == 0, "Core placement must not dig automatic corridors or a starter room (got %d floors)" % floors)
    m._new_map()
    check(m._place_core(Vector2i(14, 14)), "Core cannot be placed against the influence boundary")
    check(tile(Vector2i(14, 14)) == m.Tile.CORE and tile(Vector2i(15, 15)) == m.Tile.CORE, "boundary Core placement is not a 2x2 footprint")
    m._new_map()
    check(m._place_core(default_core), "Core not restored after boundary placement check")
    c = core_cell()
    var vaults := 0
    for y in range(m.ROWS):
        for x in range(m.COLS):
            if int(m.grid[y][x]) == m.Tile.VAULT:
                vaults += 1
    check(vaults == 0, "starter storage should not be placed automatically (got %d vaults)" % vaults)
    check(m.gold == m.START_GOLD, "starting gold changed")
    check(m.gold > int(m._storage_state()["capacity"]), "treasury should require player-built storage")
    var gold_before: int = m.gold
    var timer_before: float = m.raid_timer
    for i in range(40):
        m._process(0.5)
    check(not m.raid_active, "a raid started before any entrance existed")
    check(is_equal_approx(m.raid_timer, timer_before), "raid countdown ran with no entrance")
    var west: Vector2i = c + Vector2i(-1, -1)
    ensure_floor(west + Vector2i.DOWN)
    ensure_floor(west)
    m.toolbar.open_at(west, Vector2(400, 300))
    check(m.toolbar._tool_enabled(m.Tool.BUILD_ENTRANCE), "Entrance disabled before it is placed")
    m.toolbar.close()
    click_named(m.Tool.BUILD_ENTRANCE)
    check(m.selected_tool == m.Tool.BUILD_ENTRANCE, "Entrance tool did not stay selected")
    click_cell(west)
    check(tile(west) == m.Tile.ENTRANCE, "free entrance not placed on a ring floor")
    check(m.gold == gold_before, "entrance was not free")
    m.toolbar.open_at(core_east_floor(), Vector2(400, 300))
    check(not m.toolbar._tool_enabled(m.Tool.BUILD_ENTRANCE), "Entrance still enabled after it is placed")
    m.toolbar.close()
    click_cell(core_east_floor())
    check(tile(core_east_floor()) == m.Tile.FLOOR, "second entrance placed (must be permanent / unique)")
    click_cell(west)
    check(tile(west) == m.Tile.ENTRANCE, "placed entrance was modified")
    m._process(0.5)
    check(is_equal_approx(m.raid_timer, timer_before), "raid countdown ran without enough storage")
    check(m.message.contains("storage") or m.message.contains("Storage"), "missing storage prerequisite feedback")
    for p in [c + Vector2i(-1, -1), c + Vector2i(0, -1), c + Vector2i(1, -1)]:
        ensure_floor(p)
        m.selected_tool = m.Tool.STORE
        m._build_at(p)
    ensure_storage_capacity(m.gold)
    check(m.gold <= int(m._storage_state()["capacity"]), "player-built storage still cannot hold the treasury")
    m._process(0.5)
    check(m.raid_timer < timer_before - 0.2 or m.raid_timer <= m.RAID_DELAY - 0.2, "placing enough storage did not start the raid delay")
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

func wait_town_portal() -> void:
    for i in range(100):
        if not m.raid_active:
            return
        m._process(0.1)

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
    sync_test_world()

func sync_test_world() -> void:
    if m.dungeon != null:
        m.dungeon.sync(m)

func _test_dungeon_input_not_stolen() -> void:
    print("== dungeon clicks vs toolbar ==")
    m._new_map()
    check(m._place_core(GameTypes.core_origin_cell()), "Core setup failed before input picking test")
    m._reset_camera()
    if m._world_host != null:
        check(m._world_host.stretch, "3D viewport is not stretched to the playable area; mouse picking will not match rendered Core pads")
    m.selected_tool = m.Tool.STORE
    var far := Vector2i(m.COLS - 1, m.ROWS - 1)
    var screen: Vector2 = m._board_to_screen(m._cell_pos(far))
    check(m._screen_to_grid(screen) == far, "south-east cell does not pick under the camera")
    click(screen)
    check(m.selected_tool == m.Tool.STORE, "a dungeon click was treated as a toolbar click")
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
    m._new_map()
    check(m._place_core(GameTypes.core_origin_cell()), "Core setup failed before isometric picking test")
    var a: Vector2 = m._cell_pos(Vector2i(3, 5))
    var east: Vector2 = m._cell_pos(Vector2i(4, 5))
    var south: Vector2 = m._cell_pos(Vector2i(3, 6))
    check(east.x > a.x, "X+ should move right on the 45° ortho view")
    check(south.y > a.y or south.x != a.x, "Y+ should move on screen vs X+")
    check(not is_equal_approx(a.x, east.x) or not is_equal_approx(a.y, east.y), "neighbours collapsed to one screen point")
    for p in [Vector2i(0, 0), Vector2i(2, 2), Vector2i(m.COLS - 2, 1), Vector2i(m.COLS - 1, m.ROWS - 1)]:
        var picked: Vector2i = m._screen_to_grid(m._board_to_screen(m._cell_pos(p)))
        check(picked == p, "3D picking missed %s (got %s)" % [p, picked])

func _test_camera() -> void:
    print("== dungeon camera ==")
    m._new_map()
    check(m._place_core(GameTypes.core_origin_cell()), "Core setup failed before camera test")
    m._reset_camera()
    check(m.cam_zoom >= m.ZOOM_MIN, "fitted zoom is below the minimum")
    var home := Vector2i(3, 3)
    var screen: Vector2 = m._board_to_screen(m._cell_pos(home))
    check(m._screen_to_grid(screen) == home, "screen-to-grid misses the cell at default zoom")
    var z_before: float = m.cam_zoom
    m._zoom_at(screen, 1.25)
    check(m.cam_zoom > z_before + 0.01, "wheel zoom did not increase")
    check(m._screen_to_grid(screen) == home, "zoom-at-cursor moved the cell under the pointer")
    # Asset placement needs a close inspection view, beyond the old 6x cap.
    m._zoom_at(screen, 100.0)
    check(m.cam_zoom >= 32.0, "camera does not allow close asset inspection")
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
    for spec in m._buttons():
        check(int(spec["tool"]) != m.Tool.DIG, "Dig is still in the toolbar")
    check(m.selected_tool == m.Tool.NONE, "a tool is selected by default")
    var gold_before: int = m.gold
    var idle_floor := core_east_floor()
    click_cell(idle_floor)
    check(tile(idle_floor) == m.Tile.FLOOR, "clicking a dug cell placed something without a tool")
    check(m.gold == gold_before, "gold spent without a selected tool")
    m._reset_camera()
    var idle_screen: Vector2 = m._to_world_screen(m.dungeon._world_to_screen(m.dungeon.cell_center(idle_floor, m.dungeon.FLOOR_Y + 0.05), m._play_view(), m.cam_zoom))
    m.toolbar.open_at(idle_floor, idle_screen)
    check(m.toolbar.open, "dug cell did not open the pie menu")
    for spec in m.toolbar._wheel_defs():
        check(int(spec["tool"]) != m.Tool.REPAIR, "Repair shown on a tile without a trap")
    m.toolbar.close()
    check(tile(idle_floor) == m.Tile.FLOOR, "opening the pie menu changed the tile")
    click_cell(Vector2i(15, 1))
    check(tile(Vector2i(15, 1)) == m.Tile.ROCK, "isolated rock dug without an adjacent passage")
    check(m.gold == gold_before, "gold spent on a rejected dig")
    check(not m._is_diggable_rock(Vector2i(15, 1)), "far rock marked diggable")
    check(m._is_excavated(c), "core is not part of the excavated area")
    var north := c + Vector2i.UP
    check(m._is_diggable_rock(north), "rock on the core ring is not marked diggable")
    check(not m._is_excavated(north), "undug rock counted as excavated")
    m._reset_camera()
    check(m._screen_to_grid(m._board_to_screen(m._cell_pos(north))) == north, "dig expand pad is not picked")
    m.grid[0][0] = m.Tile.FLOOR
    check(m._faces_map_limit(Vector2i(0, 0)), "border floor is not treated as a map limit")
    m.grid[0][0] = m.Tile.ROCK

    click_cell(north)
    check(tile(north) == m.Tile.FLOOR, "adjacent dig rejected")
    var branch1 := north + Vector2i.LEFT
    var branch2 := north + Vector2i.LEFT * 2
    var branch3 := north + Vector2i.LEFT * 3
    click_cell(branch1)
    click_cell(branch2)
    click_cell(branch3)
    check(tile(branch3) == m.Tile.FLOOR, "branch not dug")
    m.toolbar.open_at(branch3, Vector2(400, 300))
    m.toolbar.pick_index(0)
    check(tile(branch3) == m.Tile.VAULT, "pie menu storage not placed")
    click_cell(c)
    check(tile(c) == m.Tile.CORE, "Core modified")
    click_named(m.Tool.TRAP_SPIKE)
    click_cell(core_east_floor())
    m.toolbar.open_at(core_east_floor(), Vector2(400, 300))
    var saw_repair := false
    for spec in m.toolbar._wheel_defs():
        if int(spec["tool"]) == m.Tool.REPAIR:
            saw_repair = true
    check(saw_repair, "Repair missing on a trap tile")
    check(not m.toolbar._tool_enabled(m.Tool.REPAIR), "Repair enabled on an undamaged trap")
    m.trap_charges[core_east_floor()] = 1
    check(m.toolbar._tool_enabled(m.Tool.REPAIR), "Repair disabled on a damaged trap")
    m.trap_charges[core_east_floor()] = m.TRAP_MAX_CHARGES
    m.toolbar.close()
    click_named(m.Tool.TRAP_SNARE)
    click_cell(core_se_floor())
    var open_room := c + Vector2i.LEFT
    ensure_floor(open_room)
    ensure_floor(open_room + Vector2i.UP)
    ensure_floor(open_room + Vector2i.LEFT)
    m.toolbar.open_at(open_room, Vector2(400, 300))
    check(not m.toolbar._tool_enabled(m.Tool.BUILD_DOOR), "Door enabled in the radial menu on an open room tile")
    m.toolbar.close()
    click_named(m.Tool.BUILD_DOOR)
    click_cell(open_room)
    check(tile(open_room) != m.Tile.DOOR, "door placed in the open room")
    check(m.message.contains("between two walls"), "misplaced door was not rejected")
    var slot := corridor_south()
    m.toolbar.open_at(slot, Vector2(400, 300))
    check(m.toolbar._tool_enabled(m.Tool.BUILD_DOOR), "Door disabled in the radial menu on a valid wall gap")
    m.toolbar.close()
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
    var vault_p := branch3
    check(int(vaults.get(vault_p, -1)) == mini(m.gold, m.VAULT_CAPACITY), "storage filled incorrectly")
    check(int(storage["unstored"]) == maxi(0, m.gold - int(storage["capacity"])), "storage overflow does not match remaining treasury")

    var gold_now: int = m.gold
    click_named(m.Tool.RESET)
    check(m.reset_armed, "Reset not armed on the first click")
    check(m.gold == gold_now, "Reset applied on the very first click")
    click_named(m.Tool.STORE)
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
    m.hero["kind"] = "paladin"
    # This test exercises charge depletion, not whether a standard hero survives three hits.
    m.hero["hp"] = 300
    m.hero["max_hp"] = 300
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
	# A thief now spends one second visibly picking the lock before it opens.
    m._update_hero(3.04)
    check(int(m.door_hp[door]) == m.DOOR_MAX_HP - 18, "door HP not decremented")
    for i in range(5):
        if tile(door) == m.Tile.DOOR:
            m._attack_door(door)
            m._update_hero(3.04)
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

func _test_void_trap_banish() -> void:
    print("== void trap banish ==")
    m._new_map()
    var rift: Vector2i = core_east_floor()
    click_named(m.Tool.TRAP_VOID)
    click_cell(rift)
    check(tile(rift) == m.Tile.VOID, "void trap not placed")
    check(int(m.trap_charges.get(rift, 0)) == 1, "void trap should start with one charge")
    ensure_entrance()
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["hp"] = 80
    m.hero["carried_gold"] = 40
    m.hero["pos"] = rift
    var hp := int(m.hero["hp"])
    m._resolve_cell(rift)
    check(bool(m.hero.get("void_absorbing", false)), "void trap did not start an absorption")
    check(int(m.hero["hp"]) == hp, "void trap wounded the hero")
    wait_town_portal()
    check(not m.raid_active, "raid continues after a void banish")
    check(m.corpses.is_empty(), "void trap left a corpse")
    check(m.loot_bags.is_empty(), "void trap dropped loot")
    check(int(m.raid_stats.get("escaped", 0)) >= 1, "void banish not counted as escape")
    check(int(m.trap_charges[rift]) == 0, "void charge not consumed")
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
    check(bool(m.hero.get("dying", false)), "a defeated Vulpin must enter a dying state before the raid ends")
    check(m.raid_active, "the raid must remain active while the Vulpin death animation plays")
    m._update_hero(1.5)
    check(not m.raid_active, "the raid continues after the Vulpin death animation completed")
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
    ensure_floor(vault)
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
    check(int(m.hero.get("stolen_gold", 0)) == 40, "the thief must track gold stolen toward bag capacity")
    check(bool(m.hero.get("collecting_gold", false)), "a thief must collect gold before opening the town portal")
    check(not bool(m.hero.get("portaling", false)), "a thief must not portal before the collect animation finishes")
    m._update_hero(6.0)
    check(bool(m.hero.get("collecting_gold", false)), "the thief must still collect before the 6.033-second clip ends")
    m._update_hero(0.04)
    check(bool(m.hero.get("portaling", false)), "the thief must portal after the collect animation finishes")
    wait_town_portal()
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

    # No virtual gold beside the Core: a thief can discover it but never attacks it.
    m.gold = mini(m.gold, m._storage_capacity())
    var treasury_at_core: int = m.gold
    var core: Vector2i = m._find_tile(m.Tile.CORE)
    m._start_raid()
    m.hero["kind"] = "thief"
    m.hero["steal_capacity"] = 500
    m.hero["pos"] = core
    m._resolve_cell(core)
    check(m.gold == treasury_at_core, "Core contact stole dungeon gold without a storage tile (%d -> %d)" % [treasury_at_core, m.gold])
    check(m.core_hp == m.CORE_MAX, "a thief reaching the Core must not damage it")
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
    var north := c + Vector2i.UP
    for p in [north, north + Vector2i.LEFT, north + Vector2i.LEFT * 2, north + Vector2i.LEFT * 3]:
        click_cell(p)
    click_named(m.Tool.STORE)
    click_cell(north + Vector2i.LEFT * 3)
    ensure_storage_capacity(m.gold)
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
        if raids_seen >= 15 and kinds.size() == 4:
            break
        if raids_seen >= 40:
            break
        if m.game_over:
            wait_town_portal()
            campaigns += 1
            if not defeat_checked:
                defeat_checked = true
                _check_defeat_is_locked()
            else:
                m._new_map()
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
    check(kinds.size() == 4, "the four archetypes were not all encountered")
    check(defeat_checked, "no defeat encountered: end state not verified")

# After defeat: no raid, no countdown, no building — Reset aside.
func _check_defeat_is_locked() -> void:
    wait_town_portal()
    var timer_before: float = m.raid_timer
    for i in range(2000):
        m._process(0.1)
    check(not m.raid_active, "a raid starts after the defeat")
    check(m.raid_timer == timer_before, "the countdown keeps running after the defeat")
    var gold_before: int = m.gold
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
    check(seen_kinds.size() == 4, "the four archetypes were not all tested on the spike line")
    check(deepest >= 4, "heroes never get past the first cells of a trapped corridor (deepest column %d)" % deepest)
    check(pointless_returns == 0, "hero walks back into the dead-end entrance while exploring (%d times)" % pointless_returns)

func _test_loot_and_corpses() -> void:
    print("== loot and corpses ==")
    m._new_map()   # The previous loop stops in the middle of a raid.
    ensure_entrance()
    var c: Vector2i = core_cell()
    ensure_storage_capacity(m.gold + 77)
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
    m.selected_tool = m.Tool.STORE
    click(m._board_to_screen(m._corpse_pos(m.corpses[0])))
    check(m.corpses.size() == 1, "corpse absorbed by accident without Absorb")

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
    click_cell(Vector2i(4, 7))
    check(m.gold == gold_locked, "gold changed during a raid")
    check(m.corpses.size() == 1 and m.loot_bags.size() == 1, "loot/corpses manipulated during a raid")
    check(tile(Vector2i(4, 7)) == m.Tile.ROCK, "digging possible during a raid")
