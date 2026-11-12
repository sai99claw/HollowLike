extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Wind=preload("res://scripts/wind_art.gd")
const Home=preload("res://scripts/home_art.gd")
const Boss=preload("res://scripts/boss_art.gd")
const Sprites=preload("res://scripts/sprite_art.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	for id in ["background","nest","musou","rogue","sleep"]:check(Home.texture(id)!=null,"Dedicated home art is imported: "+id)
	check(Home.texture("musou")!=Home.texture("rogue"),"Mode gates have independent painted images")
	for progress in [0.0,.1,.5,.99]:check(Wind.impact_rect(Vector2(600,700),progress).end.y<=700.001,"Ground-impact bounds never extend below the contacted platform")
	Boss.textures.clear();Sprites.textures.clear()
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	check(Boss.textures.is_empty() and Sprites.textures.is_empty(),"Home startup does not eagerly decode every biome and every boss frame")
	scene.set_process(false);scene.set_physics_process(false);var saved:Dictionary=scene.meta.duplicate(true)
	check(scene.screen=="hub" and scene.home_sleeping and scene.p["pos"]==Vector2(640,600),"A fresh launch starts asleep inside the central home nest")
	scene.keys["left"]=true;scene._physics_process(.01)
	check(not scene.home_sleeping and scene.home_wake_left>0 and scene.p["pos"].x==640,"Movement wakes the pigeon before it starts walking")
	scene.home_wake_left=0;scene.p["pos"].x=235;scene._physics_process(.05)
	check(scene.screen=="game" and scene.mode=="musou","Walking through the left gilded gate starts Musou")
	scene._ui_action("hub",null);scene.home_sleeping=false;scene.home_wake_left=0;scene.p["pos"].x=1045;scene.keys["right"]=true;scene._physics_process(.05)
	check(scene.screen=="game" and scene.mode=="rogue","Walking through the right dark gate starts Roguelike")
	scene.practice_mode=true;scene.meta["rd_tuning"]={"merchant_chance":1.0};scene.new_run("rogue",131310);scene._close_panel();scene.room_cooldown=0
	var start:int=scene.current_room;var merchant:int=-1;var spring:int=-1;var combat:int=-1
	for room in scene.tower["rooms"]:
		if room["type"]=="merchant":merchant=int(room["id"])
		elif room.get("spring",false):spring=int(room["id"])
		elif room["type"]=="combat":combat=int(room["id"])
	for zoom in [.8,1.3,2.0]:
		scene.camera_zoom=zoom;scene._enter_room(combat);var expected:float=scene._view_zoom()
		for id in [start,merchant]:
			scene._enter_room(id);check(is_equal_approx(scene._view_zoom(),expected),"Entering any safe room preserves the same character scale")
			check(scene._room_floor()*scene._view_zoom()>=720,"Safe room interior height covers a full viewport")
	scene._enter_room(start);scene._close_panel();scene.camera_zoom=1.3;scene.room_cooldown=0
	for prop in scene.props:
		if prop["kind"] in ["rack","mail","aid","energy_infinite"]:check(is_equal_approx(prop["pos"].y,scene._room_floor()-200),"All prep interaction stations stand on the second floor")
	scene.p["pos"]=Vector2(420,1050);check(not scene._world_confirm(),"First-floor attacks do not trigger the rack above")
	var targets:Array=scene.enemies.filter(func(en):return en.get("training",false))
	check(targets.size()==1,"Prep has one ground target using the enemy body")
	for target in targets:
		var before:float=target["hp"];var total:float=target["training_total"];var box:Rect2=scene._enemy_body_box(target)
		check(target["contact_damage"]==0 and box.size==Vector2(34,45),"Training targets have zero contact damage and shared enemy hitboxes")
		scene._clear_keys();scene.p_attack.cancel();scene.weapon_index=0;scene._reset_player(target["pos"]-Vector2(0,50));scene.p["vel"]=Vector2(0,100);scene.p["grounded"]=false;scene._begin_primary({"dir":"down","charged":false});scene._process_player_attack()
		check(target["hp"]==before and target["training_total"]>total,"Actual downward attacks register damage without killing the dummy")
		check(scene.p["vel"].y<0 and target["push_left"]>0,"The target uses normal pogo and knockback")
	# Release input must distinguish 1.39 seconds from the exact 1.4 second threshold.
	scene._enter_room(combat);scene.props.clear();scene.enemies.clear();scene._close_panel();scene.room_cooldown=0
	for weapon in 3:
		scene.weapon_index=weapon
		for hold in [1.39,1.4]:
			scene._clear_keys();scene.p_attack.cancel();scene._reset_player(Vector2(700,1050));scene._set_action("attack",true);scene.p_attack.tick(hold);scene.charge_timer=hold;scene._set_action("attack",false)
			check(scene.pending_attack.get("charged",false)==(hold>=1.4),"Charge input threshold is exactly 1.4 seconds for every primary")
		check(Data.primary_attack(weapon,"right",true)["active"]==1.0,"Charged release active duration is exactly one second")
	var clock=Attack.new();clock.begin({"windup":0,"active":1.0,"recovery":0});var hits:int=0
	for step in 121:
		if clock.mark_timed_hit(9):hits+=1
		clock.tick(1.0/120)
	check(hits==2,"Floating-point rounding cannot add a strike on the one-second end boundary")
	# Dive accelerates under a bounded terminal speed and stops on an upper platform.
	scene._clear_keys();scene.p_attack.cancel();scene.solids.clear();scene.platforms.assign([Rect2(500,700,400,20),Rect2(0,1050,1500,70)]);scene._reset_player(Vector2(700,150));scene.keys["down"]=true;scene.clock=10;scene._dash_pressed();scene.clock=10.2;scene._dash_pressed();scene.p_attack.tick(.04)
	scene._update_player(.01);var first:float=scene.p["vel"].y;scene._update_player(.05);check(scene.p["vel"].y>first,"Downward double C accelerates while airborne")
	var max_speed:float=0
	for step in 240:
		scene._update_player(1.0/120);max_speed=maxf(max_speed,scene.p["vel"].y)
		if not scene.p["slam"]:break
	check(max_speed<=1480.001 and not scene.p["slam"] and is_equal_approx(scene.p["pos"].y,700),"Dive stops exactly on the first platform and cannot accelerate without limit")
	scene._update_visual_effects(.1)
	check(scene.effects.any(func(e):return e.get("ground_wind",false)),"Landing creates a ground-anchored wind impact")
	for e in scene.effects:
		if e.has("ground_y"):check(e["pos"].y<=e["ground_y"],"Every impact fragment stays above its own contacted surface")
	# A normal dash creates no per-physics-step particles. Projectile emitters have a hard budget.
	scene.effects.clear();scene.p_attack.cancel();scene._clear_keys();scene._reset_player(Vector2(700,100));scene.p["dash_t"]=.16;scene.p["dash_dir"]=Vector2.RIGHT
	for step in 12:scene._update_player(1.0/120)
	check(scene.effects.is_empty(),"Dash rendering allocates no per-substep particle dictionaries")
	scene.combat_feedback.clear();scene.combat_feedback.reduced=true
	for i in 100:scene.combat_feedback.projectile_trail({"pos":Vector2(700,400),"vel":Vector2.RIGHT,"radius":8},1)
	check(scene.combat_feedback.trails.size()==24,"Reduced effects cap trails at 24 emitters under a 100-projectile load")
	for record in scene.combat_feedback.trails.values():check(record["emitter"].amount==5,"Reduced projectile emitters use five particles")
	scene.low_effects=true;scene._process(.01)
	for particle in scene.atmosphere.ambient+scene.atmosphere.rain_layers:check(particle.material==null,"Reduced ambient particles skip repeated blur texture sampling")
	scene._enter_room(merchant);check(scene.atmosphere.merchant_room and not scene.atmosphere.rainy,"Merchant has dedicated indoor scenery without outdoor rain")
	for character in "樹梢上的家金羽奔流":check(scene.font.has_char(character.unicode_at(0)),"Home font covers new Chinese text")
	scene.meta=saved;scene._save_meta();scene.combat_feedback.clear();scene.queue_free();await process_frame
	print("v0.13: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
