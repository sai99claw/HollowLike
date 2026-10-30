extends SceneTree
const Motion=preload("res://scripts/player_motion_v18.gd")
const Monster=preload("res://scripts/monster_motion_v18.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
const Arms=preload("res://scripts/armament.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func target(at:Vector2,uid:int=18) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=uid
	var en:Dictionary=Arms.enemy("walk",rng)
	en.merge({"uid":uid,"pos":at,"vel":Vector2.ZERO,"hp":100.0,"max_hp":100.0,"hurt":0.0,"stun":0.0,"cooldown":100.0,"face":-1.0,"contact_damage":1.0,"attack":Attack.new()},true)
	return en
func reset(game,at:Vector2=Vector2(700,1050)) -> void:
	game._close_panel();game._clear_keys();game.p_attack.cancel();game._reset_player(at)
	game.screen="game";game.lab_mode="";game.injured=false;game.life_event.clear();game.hitstop=0;game.freeze_timer=0
	game.enemies.clear();game.props.clear();game.projectiles.clear();game.hazards.clear();game.drops.clear();game.doors.clear();game.effects.clear()
	game.combat_feedback.clear();game.solids.clear();game.platforms.assign([Rect2(0,1050,1500,70)])
	game.layout={"size":Vector2(1500,1120),"floor_y":1050.0};game.room_cooldown=1000;game.world_speed=1;game.practice_mode=true;game.weapon_index=1
func height(game,release_frame:int) -> float:
	reset(game);game._set_action("jump",true);var apex:float=1050
	for frame in 160:
		if frame==release_frame:game._set_action("jump",false)
		game._update_player(1.0/120);apex=minf(apex,game.p["pos"].y)
	return 1050-apex
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false);game.new_run("rogue",181818)
	# These assertions drive the actual controller and input handlers.
	reset(game);game._set_action("right",true);game._update_player(1.0/120)
	check(game.p["vel"].x==330,"Full horizontal speed on first substep")
	game._set_action("right",false);var x:float=game.p["pos"].x;game._update_player(1.0/120)
	check(game.p["vel"].x==0 and game.p["pos"].x==x,"Release has zero horizontal drift")
	game._set_action("left",true);game._update_player(1.0/120)
	check(game.p["vel"].x==-330 and game.p["face"]==-1,"Reverse reaches opposite speed in one substep")
	game.p["grounded"]=false;game.p["pos"].y=600;game._set_action("left",false);game._update_player(1.0/120)
	check(game.p["vel"].x==0,"Air steering has the same zero momentum")
	var short_h:float=height(game,1);var mid_h:float=height(game,15);var full_h:float=height(game,999)
	check(short_h<20 and short_h<mid_h and mid_h<full_h and full_h>110,"Tap, medium and full holds produce distinct jump heights")
	reset(game,Vector2(700,500));game.p["grounded"]=false;game.p["vel"].y=-300;game._step_player(.01);var rising:float=game.p["vel"].y+300
	game.p["vel"].y=300;game._step_player(.01)
	check(is_equal_approx(game.p["vel"].y-300,rising*2),"Actual falling controller applies double rise gravity")
	game.p["vel"].y=-400;game.p["jump_cut_allowed"]=true;game.keys["jump"]=true;game._set_action("jump",false)
	check(game.p["vel"].y==-140,"Jump release cuts velocity in the input frame")
	for weapon in 3:
		reset(game);game.weapon_index=weapon;var en:Dictionary=target(Vector2(730,1050),18+weapon);game.enemies.assign([en])
		game._set_action("attack",true)
		check(game.p_attack.is_active() and en["hp"]<100,"Press activates and hits before a physics tick: "+str(weapon))
		check(game.hitstop>=.05 and game.hitstop<=.1 and en["flash_left"]>0,"Every melee hit stops and flashes: "+str(weapon))
		game._sync_enemy_canvases();check(game.enemy_canvases[int(en["uid"])].material!=null,"Flash uses the enemy alpha silhouette material")
		var hp:float=en["hp"];game._process_player_attack();check(en["hp"]==hp,"Repeated contact cannot repeat normal swing damage")
		var snapshot:Array=[game.clock,game.draw_clock,game.p["pos"],en["pos"],game.p_attack.elapsed,game.effects.size(),game.combat_feedback.flashes[0]["life"]]
		game._physics_process(.016)
		check(snapshot==[game.clock,game.draw_clock,game.p["pos"],en["pos"],game.p_attack.elapsed,game.effects.size(),game.combat_feedback.flashes[0]["life"]],"Hitstop freezes gameplay, animation and VFX together")
		game.combat_feedback.set_frozen(true)
		check(game.combat_feedback.bursts.all(func(b):return b.speed_scale==0),"Native combat particles also freeze")
		game.combat_feedback.set_frozen(false);game.hitstop=0
		game._set_action("attack",false);game._set_action("attack",true);game._set_action("attack",false)
		check(game.pending_attack.is_empty() and not game._key("attack"),"Busy click is discarded instead of buffered")
		game.p_attack.tick(float(game.p_attack.attack["active"])+.001);game.keys["right"]=true;game._update_player(.01)
		if game.p["recoil_left"]<=0:check(game.p["vel"].x==330,"Recovery allows movement")
		game._dash_pressed();check(not game.p_attack.is_busy() and game.p["dash_t"]>0,"Dash cancels every weapon recovery")
		reset(game);game.weapon_index=weapon;game._set_action("attack",true)
		for frame in 85:game._physics_process(1.0/60)
		game._set_action("attack",false);game._physics_process(.001)
		check(game.p_attack.is_active() and game.p_attack.attack.get("charged",false) and game.p_attack.attack["active"]==1,"Real 1.4-second hold releases a one-second charge")
	reset(game,Vector2(700,600));game.p["grounded"]=false;game.p["jumps"]=2;game.p["air_dash"]=true;game.keys["down"]=true
	var enemy:Dictionary=target(Vector2(700,650));game.enemies.assign([enemy]);game._set_action("attack",true)
	check(game.p["vel"].y==-Motion.POGO_SPEED and not game.p["air_dash"] and game.p["jumps"]==1,"Air downslash bounces and restores dash and double jump")
	game.hitstop=0;game._set_action("attack",false);game.p_attack.tick(.121);var previous:int=game.p_attack.attack_id;game._set_action("attack",true)
	check(game.p_attack.attack_id==previous+1 and game.p_attack.is_active(),"New airborne downslash can cancel recovery")
	reset(game,Vector2(700,600));game.p["grounded"]=false;game._begin_primary({"dir":"down","charged":false})
	game.hazards.assign([{"pos":Vector2(700,650),"size":20,"hp":1,"pogoable":true}]);game._damage_traps(Rect2(680,620,40,50),1)
	check(game.p["vel"].y==-Motion.POGO_SPEED,"Explicit pogo mechanism shares the same rebound")
	# Authored movement frames are actually addressable by runtime and RD.
	check(Monster.ensure() and Monster.manifest["animations"].size()==12,"Six species and six bosses have new movement sheets")
	for id:String in Monster.manifest["animations"]:
		var clip:Dictionary=Monster.definition(id);var hashes:Dictionary={};var indices:Dictionary={}
		var en:Dictionary={"species":id,"biome":id,"model":4 if id in ["sky","canopy","branches","trunk","grass","underground"] else 0,"vel":Vector2(80,0)}
		for i in 8:
			var tex:Texture2D=Monster.texture_for(id,i);check(tex!=null,"Exported movement frame loads: "+id)
			hashes[clip["frames"][i]["sha256"]]=true;indices[Monster.sample_index(en,(float(i)+.25)/float(clip["fps"]))]=true
		check(clip["frames"].size()==8 and hashes.size()==8 and indices.size()==8,"Eight distinct authored poses are sampled: "+id)
		check(Catalog.entry("motion:v18:"+id).get("frame_count",0)==8,"RD shows the same eight movement frames: "+id)
	check(Catalog.entry("slash:v18").get("frame_count",0)==8,"New independent slash layer is inspectable in RD")
	check(ResourceLoader.exists("res://assets/metal_hit.wav"),"Metal impact audio is included")
	print("v18: jump heights=",[short_h,mid_h,full_h],"; ","passed" if failures.is_empty() else failures)
	game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
