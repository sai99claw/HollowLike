class_name BossDirectorV35
extends RefCounted
## Boss-only posture and encounter pacing. Small hits still hurt and flash, but
## cannot refresh a stun forever. Parries retain their deliberate interrupt.
const PHASE_TWO_HP:float=.65
const PHASE_THREE_HP:float=.30
const STAGGER_TIME:float=.65
const STAGGER_IMMUNITY:float=5.5

static func prepare(en:Dictionary) -> void:
	if en.has("boss_phase"):return
	en["boss_phase"]=1;en["boss_phase_events"]=0
	en["boss_posture"]=0.0;en["boss_posture_delay"]=0.0
	en["boss_stagger_immunity"]=0.0;en["boss_phase_left"]=0.0
	en["boss_history"]=[];en["boss_staggers"]=0

static func enrage(en:Dictionary) -> void:
	if en.get("boss_enraged",false) or float(en["hp"])>float(en.get("max_hp",en["hp"]))*0.5:return
	en["boss_enraged"]=true
	for key in ["speed","dash_speed"]:
		if en.has(key):en[key]=float(en[key])*2.0
	en["attack_speed"]=float(en.get("attack_speed",1.0))*2.0
	en["cooldown"]=float(en.get("cooldown",0.0))*0.5

static func posture_limit(en:Dictionary) -> float:
	return clampf(float(en.get("max_hp",en.get("hp",80)))*.12,4,12)

static func hit(en:Dictionary,damage:float) -> bool:
	prepare(en)
	if damage<=0 or float(en["hp"])<=0 or float(en["boss_stagger_immunity"])>0:return false
	en["boss_posture"]+=damage;en["boss_posture_delay"]=1.25
	if float(en["boss_posture"])<posture_limit(en):return false
	en["boss_posture"]=0.0;en["boss_stagger_immunity"]=STAGGER_IMMUNITY
	en["boss_staggers"]+=1;en["stun"]=maxf(float(en.get("stun",0)),STAGGER_TIME)
	en["attack"].cancel();en["cooldown"]=maxf(float(en.get("cooldown",0)),STAGGER_TIME+.25)
	# A stagger also interrupts a telegraphed charge, giving a real punish window.
	en["charge_phase"]="idle";en["charge_left"]=0.0;en["motion_dash_left"]=0.0
	en["motion_dash_wait"]=0.0;en["charge_cooldown"]=1.25
	return true

static func tick(en:Dictionary,delta:float,engaged:bool) -> int:
	prepare(en)
	for key in ["boss_stagger_immunity","boss_posture_delay","boss_phase_left"]:
		en[key]=maxf(0,float(en[key])-delta)
	if float(en["boss_posture_delay"])<=0:
		en["boss_posture"]=move_toward(float(en["boss_posture"]),0,posture_limit(en)*.25*delta)
	if not engaged or float(en["hp"])<=0:return 0
	# Finish the current readable attack/charge before announcing a new phase.
	if en["attack"].is_busy() or str(en.get("charge_phase","idle"))!="idle" or float(en["stun"])>0 or float(en["boss_phase_left"])>0:return 0
	var ratio:float=float(en["hp"])/maxf(1,float(en.get("max_hp",en["hp"])))
	var next:int=int(en["boss_phase"])+1
	if next>3 or ratio>(PHASE_TWO_HP if next==2 else PHASE_THREE_HP):return 0
	en["boss_phase"]=next;en["boss_phase_events"]+=1;en["boss_phase_left"]=.9
	en["cooldown"]=maxf(float(en.get("cooldown",0)),.9)
	return next

static func choose(en:Dictionary,toward:Vector2,candidates:Array[int]) -> int:
	prepare(en)
	var best:int=-1;var score:float=-INF
	var history:Array=en["boss_history"]
	for index:int in candidates:
		var definition:Dictionary=en["attacks"][index]
		var kind:String=str(definition["library_kind"])
		var melee:bool=kind in ["slash","explosion"]
		var value:float=4.0 if melee and absf(toward.x)<210 and absf(toward.y)<90 else 2.0
		if not melee and absf(toward.y)>80:value+=2
		if kind=="trap":value+=1 if absf(toward.y)<65 else -2
		if history.size()>0:
			if index==int(history[-1]):value-=8
			if str(en["biome"])=="underground" and int(en["boss_phase"])>=2 and str(en["attacks"][int(history[-1])]["library_kind"])=="trap" and kind=="flying_slash":value+=6
		if history.size()>1 and index==int(history[-2]):value-=2.5
		# A stable tie break preserves reproducibility without a fixed round robin.
		value+=float(posmod(index-int(en.get("attack_cursor",0)),en["attacks"].size()))*.03
		if value>score:score=value;best=index
	return best

static func started(en:Dictionary,index:int) -> void:
	prepare(en)
	var history:Array=en["boss_history"];history.append(index)
	while history.size()>3:history.pop_front()

static func attack_definition(en:Dictionary,definition:Dictionary) -> Dictionary:
	var result:Dictionary=definition.duplicate(true)
	# Faster decisions in later phases, while preserving authored windup/recovery.
	var phase:int=int(en.get("boss_phase",1))
	if phase>=2:result["attack_cooldown"]=minf(float(result.get("attack_cooldown",1.1)),.7 if phase==2 else .5)
	if str(en.get("biome",""))=="underground" and phase>=2:
		if result["library_kind"]=="trap":
			result["count"]=2 if phase==2 else 3;result["arming_time"]=maxf(.85,float(result.get("arming_time",.75)))
		elif result["library_kind"]=="flying_slash":
			result["spread"]=.24 if phase==2 else .38
	return result
