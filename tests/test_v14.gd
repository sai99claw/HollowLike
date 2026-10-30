extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const FX=preload("res://scripts/combat_visual.gd")
const Wind=preload("res://scripts/wind_art.gd")
const Arms=preload("res://scripts/armament.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func target(at:Vector2,uid:int) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=uid;var en:Dictionary=Arms.enemy("walk",rng)
	en.merge({"uid":uid,"pos":at,"vel":Vector2.ZERO,"hp":100.0,"max_hp":100.0,"hurt":0.0,"stun":0.0,"cooldown":100.0,"face":-1.0,"contact_damage":1.0,"attack":Attack.new()},true);return en
func clear_combat(scene,at:Vector2) -> void:
	scene._clear_keys();scene._close_panel();scene.p_attack.cancel();scene._reset_player(at);scene.props.clear();scene.enemies.clear();scene.effects.clear();scene.projectiles.clear();scene.hazards.clear();scene.solids.clear();scene.hitstop=0;scene.shake=0;scene.room_cooldown=1000;scene.p["energy"]=6
func down_dash(scene) -> void:
	scene.keys["down"]=true;scene.clock=20;scene._dash_pressed();scene.clock=20.2;scene._dash_pressed()
func run() -> void:
	# Three distinct source sheets with six, eight, twelve independently sampled frames.
	for kind in ["jet","form","impact"]:
		var tex:Texture2D=Wind.texture(kind);check(tex!=null,"Dedicated animation texture exports: "+kind)
		var rects:Dictionary={};var sampled:Dictionary={}
		for i in Wind.frame_count(kind):
			var box:Rect2=Wind.region(kind,i);rects[str(box)]=true
			check(Rect2(Vector2.ZERO,tex.get_size()).encloses(box),"Every animation frame stays inside its source sheet")
		for step in 120:sampled[Wind.frame_index(kind,float(step)/120)]=true
		check(rects.size()==Wind.frame_count(kind) and sampled.size()==Wind.frame_count(kind),"Animation uses every distinct authored frame: "+kind)
	check(Wind.texture("jet")!=Wind.texture("form"),"A short dash and wind transformation never share one image")
	var bounds:Rect2=Wind.impact_rect(Vector2(700,700),0)
	for progress in [0.0,.1,.5,.95]:check(Wind.impact_rect(Vector2(700,700),progress)==bounds and bounds.end.y<=700,"Impact uses fixed scale above the physical floor instead of enlarging one picture")
	# Pigeon pose and detached skill effects both play their entire authored sequence once.
	for id in ["pigeon_talons_charge","pigeon_feather_charge","pigeon_great_charge","claw_charge","feather_charge","heavy_charge"]:
		var clip:Dictionary=FX.definition(id);var seen:Dictionary={};var previous:int=-1
		for step in 120:
			var frame:int=FX.sample_index(clip,float(step)/120,"active",step*7.0)
			seen[frame]=true;check(frame>=previous,"Released animation cannot loop or reverse: "+id);previous=frame
		check(seen.size()==clip["frames"].size() and previous==clip["frames"].size()-1,"All anticipation, strike and finish frames play inside the one-second release: "+id)
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	for character in "小噴射化身為風集氣釋放無敵":check(scene.font.has_char(character.unicode_at(0)),"New skill descriptions have every required Chinese glyph")
	scene.set_process(false);scene.set_physics_process(false);var saved:Dictionary=scene.meta.duplicate(true);scene.practice_mode=true;scene.new_run("rogue",14141);scene._close_panel();scene.world_speed=1
	clear_combat(scene,Vector2(700,200));scene.platforms.assign([Rect2(0,1050,1500,70)]);scene.clock=10;scene._dash_pressed()
	check(scene.p["dash_t"]>0 and not scene._wind_form_active() and not scene.p_attack.is_busy(),"Single C keeps the pigeon and plays only a small rear jet")
	scene.clock=10.2;scene._dash_pressed();scene.p_attack.tick(.04)
	check(scene._wind_form_active() and scene.p_attack.attack["kind"]=="pierce","Double C replaces the normal body with the wind form")
	for speed in [.4,1.0,1.5]:
		clear_combat(scene,Vector2(700,200));scene.world_speed=speed;scene.clock=10;scene._dash_pressed();scene.clock=10.2;scene._dash_pressed();scene.p_attack.tick(.04)
		for step in 15:scene._physics_process(1.0/60)
		check(not scene._wind_form_active() and scene.p["dash_t"]==0,"Special wind exit never falls back to a normal dash jet at another world speed")
	scene.world_speed=1.0
	# Release movement is real physics, including the heavy weapon after it connects.
	for weapon in 3:
		clear_combat(scene,Vector2(700,1050));scene.weapon_index=weapon;scene._begin_primary({"dir":"right","charged":true})
		check(scene.p_attack.is_active() and scene.p_attack.attack["windup"]==0 and scene.p_attack.attack["recovery"]==0,"Release has one second total, with no extra outer phases")
		scene.keys["right"]=true;scene._update_player(.1);var before:float=scene.p["pos"].x
		check(before>700,"Released charge moves under normal steering for weapon "+str(weapon))
		var en:Dictionary=target(scene.p["pos"]+Vector2(40,0),101+weapon);scene.enemies.assign([en]);scene._process_player_attack();scene._update_player(.1)
		check(en["hp"]<100 and scene.p["pos"].x>before and scene.p["impact_root"]==0 and scene.p["recoil_left"]==0,"Hits preserve steering and do not root or recoil the charged caster")
		scene.p_attack.tick(.999);check(scene.p_attack.is_active(),"Release remains active until the full second")
		scene.p_attack.tick(.002);check(not scene.p_attack.is_busy(),"Release fully finishes after one second")
		for hold in [1.39,1.4]:
			clear_combat(scene,Vector2(700,1050));scene._set_action("attack",true);scene.p_attack.tick(hold);scene.charge_timer=hold;scene._set_action("attack",false)
			check(scene.pending_attack.get("charged",false)==(hold>=1.4),"Input changes to a charged cast at exactly 1.4 seconds")
	# Downward CC ignores incoming damage during startup and throughout its descent.
	clear_combat(scene,Vector2(700,150));scene.platforms.assign([Rect2(500,700,400,20),Rect2(0,1050,1500,70)]);down_dash(scene);scene.p["invul"]=0
	check(not scene._hurt_player(1,Vector2(700,100)) and scene.p["hp"]==5,"Downward CC is invulnerable from startup")
	scene.p_attack.tick(.04);var crossed:Dictionary=target(Vector2(700,450),501);var landed:Dictionary=target(Vector2(770,700),502);var below:Dictionary=target(Vector2(700,850),503);scene.enemies.assign([crossed,landed,below])
	var started_damage:bool=false
	for step in 240:
		scene._update_player(1.0/120)
		if crossed["hp"]<100:started_damage=true
		if not scene.p["slam"]:break
		scene.p["invul"]=0
		check(not scene._hurt_player(1,Vector2(700,100)),"Damage cannot break the falling wind form")
	check(started_damage and crossed["hp"]==98,"Swept descent deals exactly one hit to a crossed enemy")
	check(landed["hp"]==98 and below["hp"]==100,"Ground impact hits nearby enemies above the contacted surface without crossing the floor")
	check(not scene.p["slam"] and is_equal_approx(scene.p["pos"].y,700),"Landing terminates descent on the first physical platform")
	check(is_equal_approx(scene.p["invul"],.5) and scene.effects.any(func(e):return e.get("ground_wind",false) and e["max"]==.5),"Landing starts twelve-frame impact animation and half-second protection")
	scene.enemies.clear();scene._clear_keys();scene._physics_process(.49)
	check(not scene._hurt_player(1,Vector2(700,600)),"Landing protection still blocks damage at 0.49 seconds")
	scene._physics_process(.011);check(scene._hurt_player(1,Vector2(700,600)),"Incoming damage resumes after the half-second landing window")
	# World slow motion cannot expire the attack before the player reaches the floor.
	clear_combat(scene,Vector2(700,60));scene.platforms.assign([Rect2(0,1050,1500,70)]);scene.world_speed=.4;down_dash(scene);var long_dive:bool=false
	for step in 240:
		scene.p["invul"]=0;scene._physics_process(1.0/60)
		if step>110 and scene.p["slam"]:long_dive=true;check(scene.p_attack.is_active() and scene._slam_invulnerable(),"Slow-motion dive retains damage, wind body and invulnerability past the old timeout")
		if step>5 and not scene.p["slam"]:break
	check(long_dive and not scene.p["slam"] and is_equal_approx(scene.p["pos"].y,1050),"Extended slow-motion dive still ends on actual ground")
	scene.meta=saved;scene._save_meta();scene.combat_feedback.clear();scene.queue_free();await process_frame
	print("v0.14: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
