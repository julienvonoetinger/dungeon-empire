extends SceneTree
const HEADER=preload("res://scripts/game/ui/hud_master_header.gd")
const SESSION=preload("res://scripts/game/game_session.gd")
const OUT="res://artifacts/master-eye/"
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(value:bool,message:String) -> void:
	checks+=1
	if not value: failures.append(message); print("FAIL: ",message)
func finish() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var file:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("Eye checks: ",checks," failures: ",failures.size()); quit(0 if failures.is_empty() else 1)
func run() -> void:
	var header=HEADER.new(); root.add_child(header); header.size=Vector2(760,96)
	check(header.get("behavior")!=null,"eye has an expressive tracking controller")
	if not failures.is_empty(): finish(); return
	var session=SESSION.new(); session.persistence_enabled=false; root.add_child(session); session.set_process(false); session.restart(true); session.selected=Vector2i(-1,-1)
	header.refresh(session)
	var b=header.behavior
	check(b.mode=="veille","baseline starts neutral, no synthetic damage")
	session.start_raid(); header.world_target=Vector2(900,400)
	header.refresh(session,.1)
	check(b.mode=="traque" and b.look.x>0 and b.look.y>0,"raid follows world target")
	var old:Vector2=b.look
	session.paused=true; header.world_target=Vector2.ZERO; header.refresh(session,.2)
	check(b.look.is_equal_approx(old),"pause freezes gaze")
	session.paused=false; session.sim.core_hp=62; header.refresh(session,.01)
	check(b.mode=="blesse","actual heart loss triggers injury")
	session.raid.raid_stats.stolen=5; header.refresh(session,.01)
	check(b.mode=="blesse","theft does not override damage")
	for i in 25: header.refresh(session,.1)
	check(b.mode=="traque","reaction expires without repeated damage")
	session.raid.raid_stats.stolen=12; header.refresh(session,.01)
	check(b.mode=="colere","new actual theft triggers anger")
	for i in 25: header.refresh(session,.1)
	session.raid.raid_stats.killed=1; session.raid.raid_active=false; session.result_open=true; header.refresh(session,.01)
	check(b.mode=="jubile","kill reaction survives immediate result")
	for i in 25: header.refresh(session,.1)
	check(b.mode!="jubile","result reaction completes and does not loop")
	session.restart(true); header.refresh(session)
	check(b.reaction.is_empty(),"restart clears previous reaction")
	session.selected=Vector2i(-1,-1); session.sim.gold=0
	session.choose_tool(SESSION.Types.Tool.TRAP_SPIKE); session.activate_cell(Vector2i(4,8)); header.refresh(session,.01)
	check(b.mode=="fauche","real unaffordable placement triggers poor")
	for i in 25: header.refresh(session,.1)
	session.activate_cell(Vector2i(0,0)); header.refresh(session,.01)
	check(b.mode!="fauche","invalid rock geometry is not mistaken for poverty")
	session.sim.gold=100; session.activate_cell(Vector2i(4,8)); header.refresh(session,.01)
	check(b.blink_remaining>0,"successful placement causes short blink")
	check(b.mode!="colere","normal spending never triggers theft anger")
	# Drive actual raid action functions: observing counters is not itself an
	# integration test of the producers, especially when death clears the hero.
	session.restart(true); session.selected=Vector2i(-1,-1); session.start_raid(); header.refresh(session)
	session.raid.hero.collect_gold=5; session.raid.hero.collect_vault=Vector2i(7,7)
	session.raid._finish_vulpin_collect(); header.refresh(session,.01)
	check(b.mode=="colere","real vault withdrawal feeds anger")
	session.raid._apply_core_damage(12); header.refresh(session,.01)
	check(b.mode=="blesse","real core damage overrides anger")
	for i in 20: header.refresh(session,.1)
	session.raid._kill_hero(); header.refresh(session,.01)
	check(session.result_open and session.raid.hero.is_empty() and b.mode=="jubile","real kill and immediate end-of-raid still jubilate")
	session.restart(true); header.refresh(session)
	var first=header.EyeBehavior.new()
	var blink_starts:Array[float]=[]; var previous:=false
	seed(1729); var expected:=randi(); seed(1729)
	for i in 1000:
		first.step(.05,"veille",Vector2.ZERO)
		var blinking:bool=first.blink_remaining>0
		if blinking and not previous: blink_starts.append((i+1)*.05)
		previous=blinking
	check(randi()==expected,"cosmetic blink clock never consumes gameplay RNG")
	check(blink_starts.size()>=5,"idle blinks repeatedly")
	for i in range(1,blink_starts.size()): check(blink_starts[i]-blink_starts[i-1]>=6 and blink_starts[i]-blink_starts[i-1]<=10,"idle blink interval remains 6-10s")
	session.restart(true); header.refresh(session); session.sim.gold=0
	check(session.check_action(Vector2i(5,8),SESSION.Types.Tool.DIG).valid,"fixture clearing existing door is free")
	session.choose_tool(SESSION.Types.Tool.DIG); header.refresh(session,.01)
	check(b.mode!="fauche","choosing free clearing tool does not falsely report poverty")
	session.restart(true); header.refresh(session); session.progression.testing_unlock_defenses=true
	session.sim.vault_locks[Vector2i(7,7)]=1; session.sim.gold=50
	check(session.check_action(Vector2i(7,7),SESSION.Types.Tool.STORE_MAGIC).cost==40,"fixture discounted vault upgrade costs 40")
	session.choose_tool(SESSION.Types.Tool.STORE_MAGIC); header.refresh(session,.01)
	check(b.mode!="fauche","affordable contextual upgrade does not falsely report poverty")
	finish()
