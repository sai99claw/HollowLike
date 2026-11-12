extends SceneTree
const Rules=preload("res://scripts/musou_dream_v41.gd")
const Data=preload("res://scripts/game_data.gd")
const Roster=preload("res://scripts/monster_roster_v36.gd")
const FX=preload("res://scripts/combat_visual.gd")
var failures:Array[String]=[]
var g
var serial:int=41000
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func target(at:Vector2) -> Dictionary:
	serial+=1;var en:Dictionary=Roster.regular("underground",0)
	en.merge({"uid":serial,"pos":at,"vel":Vector2.ZERO,"face":-1.0,"hp":10000.0,"max_hp":10000.0,"hurt":0.0,"stun":0.0,"flash_left":0.0,"cooldown":999.0,"attack":g.Attack.new()},true)
	return en
func clean() -> void:
	g._close_panel();g._clear_keys();g.p_attack.cancel();g.hitstop=0;g.enemies.clear();g.props.clear();g.projectiles.clear();g.hazards.clear();g.doors.clear();g.effects.clear();g.solids.clear();g.platforms.clear();g.dream.clear();g.dream_visual.clear_waves()
	g._reset_player(Vector2(600,900));g.p["invul"]=0;g.p["grounded"]=true;g.revive_used=false;g.injured=false;g.life_event.clear();g.view_rect=Rect2(0,0,1280,1080);g.camera_pos=Vector2(300,400)
func run() -> void:
	var meter=Rules.new()
	for i in 19:meter.hit()
	check(meter.energy==19 and meter.pending==0,"Nineteen hits do not cast early")
	meter.hit();check(meter.energy==0 and meter.pending==1,"Twentieth hit queues an automatic cast")
	for i in 43:meter.hit()
	check(meter.energy==3 and meter.pending==3,"Multi-target overflow preserves hits and complete charges")
	meter.injure();meter.step(119.9);check(meter.damage_factor()==2,"Rage lasts the full120 active seconds")
	meter.step(.11);check(meter.damage_factor()==1,"Rage expires without a permanent damage increase")
	var layout:Dictionary={"platforms":[Rect2(0,900,4600,20)],"solids":[Rect2(0,900,4600,100)]};var base:Array[Dictionary]=[]
	for i in 10:base.append({"pos":Vector2(100+i*100,900),"platform":0,"model":0})
	for stage in 6:
		var plan:Array[Dictionary]=Rules.expand_plan(base,layout,stage,171,[])
		check(plan.size()==ceili(10*1.4*pow(1.1,stage)),"Population compounds once per stage: "+str(stage))
		check(plan==Rules.expand_plan(base,layout,stage,171,[]),"Population remains reproducible: "+str(stage))
	check(base.size()==10,"Population expansion never changes the base plan")
	var boss:Array[Dictionary]=[{"pos":Vector2(4000,900),"platform":0,"model":4},{"pos":Vector2(100,900),"platform":0,"model":3},{"pos":Vector2(200,900),"platform":0,"model":3},{"pos":Vector2(300,900),"platform":0,"model":3}]
	var expanded:Array[Dictionary]=Rules.expand_plan(boss,layout,5,171,[])
	check(expanded.filter(func(e):return e["model"]==4).size()==1 and expanded.size()==1+ceili(3*Rules.population_factor(5)),"Boss stays unique while its elite guards increase")
	g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.practice_mode=true;g.new_run("musou",410041);clean()
	for charged in [false,true]:
		for dash in [false,true]:
			g.p["dash_t"]=.16 if dash else 0;var def:Dictionary=g._primary_definition({"dir":"right","charged":charged})
			check(def["windup"]==0 and def["recovery"]==0,"All primary action outer phases vanish only in the dream")
	g.p["dash_t"]=0;g.bag_weapons.assign([Data.secondary_attack(0)]);g._begin_secondary()
	check(g.p_attack.is_active() and g.p_attack.attack["recovery"]==0,"Secondary salvo starts immediately and has no recovery")
	clean();var en:Dictionary=target(Vector2(760,900));g.enemies.append(en)
	g._start_enemy_attack(en,en["attacks"][0]);check(en["attack"].is_active() and en["attack"].attack["windup"]==0 and en["attack"].attack["recovery"]==0,"Enemy attack outer phases also vanish in the dream")
	en["attack"].cancel();g._hit_enemy(en,1,Color.WHITE);check(g.dream.energy==1,"Melee-style shared damage registers one charge")
	g._emit_weapon(Vector2(690,877),Vector2.RIGHT,Data.secondary_attack(0),true);g._update_projectiles(.2)
	check(g.dream.energy==2,"Ordinary projectile hits register charge")
	var laser:Dictionary=Data.secondary_attack(g.Arsenal.index_of("piercing_laser"));g._cast_special(Vector2(600,877),Vector2.RIGHT,laser)
	check(g.dream.energy==3,"Laser hits register charge")
	var chain:Dictionary=Data.secondary_attack(g.Arsenal.index_of("chain_staff"));g._cast_special(Vector2(600,877),Vector2.RIGHT,chain)
	check(g.dream.energy==4,"Chain lightning hits register charge")
	g._explode(Vector2(760,877),100,1,0,true);check(g.dream.energy==5,"Explosions register charge")
	g.hazards.append({"from_player":true,"pos":en["pos"],"elapsed":.1,"arming_time":0.0,"lifetime":5.0,"size":100.0,"hp":1,"damage":1.0,"hits":{},"next_hit":{},"max_hits":3,"hit_interval":.6,"color":Color.WHITE});g._update_hazards(.01)
	check(g.dream.energy==6,"Persistent hazard damage registers charge")
	g.dream.energy=19;g.dream.pending=0;g.projectiles.clear();g.hazards.clear();g._hit_enemy(en,1,Color.WHITE)
	check(g.dream.pending==1 and g.projectiles.is_empty(),"Hit callback queues rather than recursively mutating projectile iteration")
	g._update_dream(1.0/60)
	check(g.projectiles.size()==8 and g.dream_visual.waves.size()==1 and g.dream.pending==0,"Full meter automatically creates an expanding slash and eight flying slashes")
	check(FX.has_clip("feather_charge"),"Automatic slash uses the original featherblade charge animation")
	check(FX.has_clip("pigeon_feather_charge") and g.dream_visual.body_progress()>=0,"Automatic slash also plays the original featherblade charge body animation")
	g._process(0);await process_frame;await process_frame
	for pr:Dictionary in g.projectiles:check(pr["dream_slash"] and is_equal_approx(pr["distance_left"]*g._view_zoom(),640),"Flying slash range is half of the logical screen width")
	var before:int=g.dream.energy;g._hit_enemy(en,1,Color.WHITE,0,Vector2.INF,Vector2.ZERO,false);check(g.dream.energy==before,"Ultimate damage cannot recharge itself")
	var hp_before:float=en["hp"]
	for i in g.projectiles.size():
		if i>0:g.projectiles[i]["life"]=0
	var projectile:Dictionary=g.projectiles[0];projectile["pos"]=g._enemy_body_box(en).get_center()-Vector2(30,0);projectile["vel"]=Vector2(500,0);projectile["distance_left"]=100
	g._update_projectiles(.1);check(en["hp"]<hp_before and g.dream.energy==before,"Actual flying-slash collision causes damage without feeding the next ultimate")
	var wave:Dictionary=g.dream_visual.waves[0];en["pos"]=Vector2(wave["pos"])+Vector2(float(wave["radius"])*.8,g._enemy_body_box(en).size.y*.5)
	hp_before=en["hp"];g._update_dream(.6);check(en["hp"]<hp_before and g.dream.energy==before,"Expanding slash reaches its outer radius without self-recharging")
	clean();en=target(Vector2(760,900));var far:Dictionary=target(Vector2(2400,900));g.enemies.assign([en,far]);g.p["hp"]=1;g.p["shield_cells"]=0;g.p["vel"]=Vector2(36,0)
	var origin:Vector2=g.p["pos"];g._hurt_player(1,Vector2(500,900))
	check(g.injured and g.revive_used and g.life_event.is_empty() and g.p["pos"]==origin and g.p["vel"]==Vector2(36,0) and g.p["knockback_t"]==0,"First dream down is an immediate burst without a launch or relocation")
	check(g.p["hp"]==g.p["max_hp"] and g.p["invul"]==2 and g.dream.rage_left==120 and g.shake>=20,"Burst restores injured vitality and activates120-second rage with two-second protection")
	check(en["push_left"]>0 and far["push_left"]>0 and en["push_velocity"].x>0 and far["push_velocity"].x>0,"Burst repels every enemy including those outside the screen")
	var pushed_from:Vector2=en["pos"];g.freeze_timer=1;en["boss_phase_left"]=1;g._update_enemies(.01,.01)
	check(en["pos"].x>pushed_from.x,"Burst displacement wins over frozen AI and phase holds");g.freeze_timer=0
	var hp:float=en["hp"];g._hit_enemy(en,3,Color.WHITE);check(en["hp"]==hp-6,"Rage doubles shared attack damage exactly once")
	g.dream.energy=0;g.dream.pending=0;g._update_hud();check(g.ui.dream_cells.size()==20 and g.ui.dream_row.visible and "×2" in g.ui.timed_effects_label.text,"HUD shows twenty energy cells and the rage countdown")
	g.dream_visual.set_view(true,Transform2D.IDENTITY,g.p["pos"],true)
	check(g.dream_visual.middle_bubbles.emitting and g.dream_visual.front_bubbles.emitting and g.dream_visual.middle_bubbles.direction==Vector2.UP and g.dream_visual.rage.emitting,"Middle and front bubbles rise while the special rage aura emits")
	check(g.dream_visual.vignette.material.get_shader_parameter("darkness")>.22,"Dream has stronger corner shading")
	var remaining:float=g.dream.rage_left;var sections:Array[Dictionary]=[];g._panel("pause",sections);g._physics_process(.5);check(g.dream.rage_left==remaining,"Menu pause does not consume the rage duration");g._close_panel()
	g.hitstop=.2;g._physics_process(.1);check(g.dream.rage_left==remaining,"Hitstop does not consume the rage duration");g.hitstop=0
	g.p["invul"]=0;g.p["hp"]=2;g._hurt_player(1,Vector2.ZERO);check(g.p["invul"]==2,"Every normal dream hit grants exactly two seconds")
	g.p["invul"]=0;g.p["hp"]=1;g._hurt_player(1,Vector2.ZERO);check(g.life_event.get("kind")=="death","Second down still enters the established death/cache flow")
	g.new_run("rogue",410041);clean();g.dream.injure();en=target(Vector2(760,900));g.enemies.append(en);hp=en["hp"];g._hit_enemy(en,3,Color.WHITE)
	check(en["hp"]==hp-3 and g.dream.energy==0,"Roguelike receives neither rage damage nor dream energy")
	check(g._primary_definition({"dir":"right","charged":false})["recovery"]>0,"Roguelike retains ordinary recovery")
	g._start_enemy_attack(en,en["attacks"][0]);check(en["attack"].phase=="windup","Roguelike retains enemy anticipation")
	g.p["shield_cells"]=0;g._hurt_player(1,Vector2.ZERO);check(is_equal_approx(g.p["invul"],.825),"Roguelike keeps its existing invulnerability")
	g._process(0);check(not g.dream_visual.visible,"Dream effects do not leak into Roguelike")
	var font:Font=load("res://assets/Chinese.otf")
	for ch:String in "無雙夢境能量攻擊秒":check(font.has_char(ch.unicode_at(0)),"UI font contains new mode glyph: "+ch)
	g.queue_free();await process_frame;print("v41 dream checks: ",failures);quit(0 if failures.is_empty() else 1)
