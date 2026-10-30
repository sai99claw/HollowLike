extends SceneTree
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func reset(game,at:Vector2) -> void:
	game._close_panel();game.life_event={};game.hitstop=0;game.shake=0;game._clear_keys();game._reset_player(at);game.p["grounded"]=false;game.p["invul"]=100;game.enemies.clear();game.props.clear();game.doors.clear();game.projectiles.clear();game.hazards.clear();game.drops.clear();game.solids.clear();game.platforms.assign([Rect2(0,1000,2000,80)]);game.layout={"size":Vector2(2000,1500),"floor_y":1000.0};game.room_cooldown=999;game.world_speed=1
func run() -> void:
	check(preload("res://scripts/heavy_landing_v28.gd").texture()!=null,"Heavy landing crouch artwork is exported")
	check(preload("res://scripts/heavy_landing_v28.gd").frame_index(.2)==1 and preload("res://scripts/heavy_landing_v28.gd").frame_index(.47)==3,"Half-second landing holds crouch before rising")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",280028)
	reset(game,Vector2(600,350))
	for i in 200:
		game._update_player(1.0/120)
		if game.p["grounded"]:break
	check(game.p["grounded"] and is_equal_approx(game.p["heavy_land_left"],.5),"A real650px fall starts half-second crouch recovery")
	check(game.shake>0 and game.shake<=3 and game.hitstop>0,"High landing adds a brief impact pause and subtle camera shake")
	var at:Vector2=game.p["pos"];game._set_action("right",true);game._set_action("jump",true);game._set_action("dash",true);game._set_action("attack",true);game._update_player(.05)
	check(game.p["pos"].is_equal_approx(at) and game.p["dash_t"]==0 and not game.p_attack.is_busy(),"Crouch recovery holds movement and discards jump, dash and attack inputs")
	game.hitstop=0
	for i in 29:game._physics_process(1.0/60)
	check(game.p["heavy_land_left"]>0 and game.p["pos"].x==at.x,"Crouch remains active until the half-second expires")
	for i in 3:game._physics_process(1.0/60)
	check(game.p["heavy_land_left"]==0 and game.p["pos"].x>at.x and not game.p_attack.is_busy(),"Held direction resumes after recovery without a queued attack")
	reset(game,Vector2(600,900))
	for i in 150:
		game._update_player(1.0/120)
		if game.p["grounded"]:break
	check(game.p["heavy_land_left"]==0 and game.shake==0,"Ordinary100px landing stays responsive")
	reset(game,Vector2(600,350));game.p["slam"]=true
	for i in 150:
		game._update_player(1.0/120)
		if game.p["grounded"]:break
	check(game.p["heavy_land_left"]==0,"Downward double C retains its dedicated impact and does not acquire heavy-fall recovery")
	game.queue_free();await process_frame;print("v28 heavy landing checks: %d failures"%failures.size());quit(0 if failures.is_empty() else 1)
