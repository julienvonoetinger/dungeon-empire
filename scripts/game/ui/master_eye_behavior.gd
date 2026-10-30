extends RefCounted
## Cosmetic clock only. Never advances simulation or consumes gameplay RNG.
const REACTIONS={"blesse":Vector2(4,1.25),"jubile":Vector2(3,1.6),"colere":Vector2(2,1.35),"fauche":Vector2(1,1.25)}
var mode:="veille"
var reaction:=""
var remaining:=0.0
var look:=Vector2.ZERO
var phase:=0.0
var blink_remaining:=0.0
var _blink_duration:=.42
var _until_blink:=8.0
var _blink_index:=0
var _hp:=-1
var _raid:=-1
var _kills:=0
var _stolen:=0
var _tint:=Color.WHITE
var _tone:=0.0
var _pupil:=1.0
var _aperture:=1.0
var _glow:=0.0
var _shake:=0.0

func reset() -> void:
	mode="veille"; reaction=""; remaining=0; look=Vector2.ZERO; phase=0
	blink_remaining=0; _until_blink=8; _blink_index=0; _hp=-1; _raid=-1
	_kills=0; _stolen=0; _tint=Color.WHITE; _tone=0; _pupil=1; _aperture=1; _glow=0; _shake=0

func react(kind:String) -> void:
	if kind=="placed":
		_blink_duration=.22; blink_remaining=_blink_duration; return
	if not REACTIONS.has(kind): return
	if not reaction.is_empty() and remaining>0 and REACTIONS[reaction].x>REACTIONS[kind].x: return
	reaction=kind; remaining=REACTIONS[kind].y

func observe(session:IsometricGameSession) -> void:
	var raid_id:=session.raid.raid_index
	var kills:=int(session.raid.raid_stats.get("killed",0))
	var stolen:=int(session.raid.raid_stats.get("stolen",0))
	if _hp>=0:
		if session.sim.core_hp<_hp: react("blesse")
		if raid_id==_raid:
			if kills>_kills: react("jubile")
			if stolen>_stolen: react("colere")
	_hp=session.sim.core_hp; _raid=raid_id; _kills=kills; _stolen=stolen

func step(delta:float,base:String,target:Vector2,frozen:bool=false,dead:bool=false) -> void:
	if frozen: return
	var dt:=clampf(delta,0,.1)
	remaining=maxf(0,remaining-dt)
	if remaining<=0: reaction=""
	mode=reaction if not reaction.is_empty() else base
	var blend:=1.0-exp(-dt*10.0)
	look=look.lerp(target.limit_length(1),blend)
	var tone:=0.0; var tint:=Color.WHITE; var pupil:=1.0; var aperture:=1.0; var speed:=.5
	var pulse:=0.0; var shake:=0.0
	match mode:
		"observe": aperture=.88
		"traque": aperture=.64; tone=.38; tint=Color("b04680"); speed=.9
		"jubile":
			tone=.92; tint=Color("ffcd6c"); pupil=1.35; speed=2.3
			pulse=sin(PI*clampf(1-remaining/1.6,0,1))*.28
		"blesse": tone=.9; tint=Color("e85168"); aperture=.45; shake=minf(1,remaining*2); speed=2.7
		"colere": tone=.75; tint=Color("fc428e"); pupil=.68; aperture=.68; speed=2.4; shake=minf(.65,remaining)
		"fauche": tone=.95; tint=Color("817a96"); pupil=.64; aperture=.8; speed=.2
	if dead: aperture=0; tone=1; tint=Color("51455d"); target=Vector2.ZERO
	phase=fmod(phase+dt*speed,TAU*100)
	_until_blink-=dt; blink_remaining=maxf(0,blink_remaining-dt)
	if _until_blink<=0 and reaction.is_empty() and not dead:
		_blink_duration=.42; blink_remaining=_blink_duration
		_blink_index+=1; _until_blink=[8.0,6.8,9.2][_blink_index%3]
	if blink_remaining>0:
		aperture*=1.0-sin(PI*(1.0-blink_remaining/_blink_duration))
	_tint=_tint.lerp(tint,blend); _tone=lerpf(_tone,tone,blend)
	_pupil=lerpf(_pupil,pupil,blend); _aperture=lerpf(_aperture,aperture,1-exp(-dt*25))
	_glow=lerpf(_glow,pulse,blend); _shake=lerpf(_shake,shake,blend)

func apply(material:ShaderMaterial) -> void:
	material.set_shader_parameter("phase",phase)
	material.set_shader_parameter("gaze",look)
	material.set_shader_parameter("iris_tint",_tint)
	material.set_shader_parameter("tone",_tone)
	material.set_shader_parameter("pupil_scale",_pupil)
	material.set_shader_parameter("aperture",_aperture)
	material.set_shader_parameter("glow",_glow)
	material.set_shader_parameter("shudder",_shake)
