extends SceneTree
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Tuning=preload("res://scripts/rd_tuning_v19.gd")
const Idle=preload("res://scripts/pigeon_idle_v19.gd")
const Data=preload("res://scripts/game_data.gd")
const Combat=preload("res://scripts/combat_library.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Ecology=preload("res://scripts/ecology.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok and failures.size()<35:failures.append(label);push_error(label)
func clear(game) -> void:
	game._clear_keys();game._close_panel();game.p_attack.cancel();game._reset_player(Vector2(700,1050));game.hitstop=0;game.room_cooldown=999
	game.enemies.clear();game.props.clear();game.doors.clear();game.effects.clear();game.projectiles.clear();game.hazards.clear();game.solids.clear()
	game.layout={"size":Vector2(1500,1120),"floor_y":1050.0};game.platforms.assign([Rect2(0,1050,1500,70)]);game.world_speed=1;game.p["invul"]=0
func run() -> void:
	var profiles:Dictionary={};var geometry:Dictionary={};var minimum:float=1;var maximum:float=0;var layouts:int=0
	for seed_value in 50:
		var tower:Dictionary=Tower.generate(seed_value)
		check(Tower.validate(tower).is_empty(),"Six-stage topology remains connected")
		for chapter:Dictionary in tower["maps"]:
			var boss:Dictionary=tower["rooms"][chapter["boss_id"]];var entries:int=0
			for direction:String in boss["neighbors"]:
				var other:Dictionary=tower["rooms"][boss["neighbors"][direction]]
				if other["map_index"]==boss["map_index"]:entries+=1;check(direction in ["left","right"],"Boss battle entrance is lateral")
			check(entries==1,"Boss has one local approach")
		for room:Dictionary in tower["rooms"]:
			if not room.has("layout_profile"):continue
			var layout:Dictionary=Layout.generate(room,seed_value);check(Layout.validate(layout).is_empty(),"Profile entries do not overlap solid terrain")
			profiles[room["layout_profile"]]=true;var signature:String="";var solid:int=0;var total:int=0
			for y in range(2,room["height"]-2):
				for x in range(3,room["width"]-3):
					var cell:int=layout["maze_grid"][y][x];signature+=str(cell);total+=1
					if cell==0:solid+=1
			geometry[signature]=true;var density:float=float(solid)/maxi(1,total)
			minimum=minf(minimum,density);maximum=maxf(maximum,density);layouts+=1
	check(profiles.size()==6 and geometry.size()>100 and maximum-minimum>.15,"Room variety comes from six distinct solid layouts, not only random ledges")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false)
	game.practice_mode=true;game.new_run("rogue",191919);clear(game)
	check(is_equal_approx(game._charge_threshold(),1.4),"Charge time reduced by exactly thirty percent")
	game._set_action("attack",true);game.p_attack.tick(.5);game.charge_timer=.7;game.keys["right"]=true;game._update_player(.02);game._set_action("jump",true);game._update_player(.02)
	check(game.charge_timer==.7,"Moving and jumping do not interrupt charge")
	game.clock=10;game._dash_pressed();check(game.charge_timer==.7 and game._key("attack"),"Single C preserves charge and held input")
	game.p["invul"]=0;game._hurt_player(1,Vector2(800,1050));check(game.charge_timer==0 and not game._key("attack"),"Actual damage interrupts charge")
	clear(game);game.charge_timer=.8;game.bag_weapons.assign([Data.secondary_attack(0)]);game._begin_secondary();check(game.charge_timer==0,"Casting a sidearm interrupts charge")
	clear(game);for i in 300:game._update_idle(1.0/60)
	check(game.idle_time>4.99,"Five seconds standing accumulates the resting timer")
	game.keys["right"]=true;game._update_player(.01);game._update_idle(.01);check(game.idle_time==0,"Movement instantly wakes the loaf pose")
	Idle.ensure();check(Idle.IDLE_FPS==5 and Idle.REST_FPS==8 and Idle.frame_index(4.99)<8 and Idle.frame_index(5)==1 and Idle.frame_index(5.875)==7,"Idle plays at five FPS and rest starts at its second frame")
	for id in ["idle","rest"]:
		var hashes:Dictionary={}
		for frame:Dictionary in Idle.manifest["animations"][id]["frames"]:hashes[frame["sha256"]]=true
		check(hashes.size()==8 and Catalog.entry("idle:v19:"+id)["fps"]==(5 if id=="idle" else 8),"RD plays the authored sheets at the current idle and rest rates")
	game.atmosphere.configure("sky",123,true);check(not game.atmosphere.far_birds.enabled and not game.atmosphere.far_birds.visible,"Background birds are disabled")
	# Exercise every sidearm through real selection and input, including third+ slots.
	game.bag_weapons.clear();for i in Data.SECONDARY.size():game.bag_weapons.append(Data.SECONDARY[i].duplicate(true))
	for i in game.bag_weapons.size():
		clear(game);game._select_secondary(i);game.p["energy"]=6;game._set_action("sub",true)
		check(game.p_attack.is_busy() and game.p["energy"]==5 and game.p_attack.attack["weapon_kind"]==Data.SECONDARY[i]["kind"],"Every slot starts its own weapon: "+str(i))
		game.p_attack.tick(float(game.p_attack.attack["windup"])+.001)
		check(game.p_attack.is_active(),"Every sidearm becomes active: "+str(i))
		if Data.SECONDARY[i]["kind"] not in ["sword","chain"]:check(not game.projectiles.is_empty() or not game.effects.is_empty(),"Every ranged sidearm actually emits a shot or effect")
		game.p_attack.tick(float(game.p_attack.attack["active"])+.001);game._select_secondary((i+1)%game.bag_weapons.size())
		check(not game.p_attack.is_busy(),"Switching cancels the previous sidearm recovery")
	clear(game);game.p["invul"]=999
	for biome:String in Combat.BOSS_BIOMES:
		var boss:Dictionary=Combat.boss(biome);boss.merge({"uid":99,"pos":Vector2(700,1050),"vel":Vector2.ZERO,"face":1.0,"hp":1000.0,"max_hp":1000.0,"hurt":0.0,"stun":0.0,"cooldown":99.0,"attack":Attack.new(),"contact_damage":0,"combat_engaged":true},true)
		game.enemies.assign([boss])
		for at in [Vector2(-2000,500),Vector2(9000,500),Vector2(700,-3000),Vector2(700,9000)]:
			boss["pos"]=at;boss["vel"]=Vector2(20000,20000);game._update_enemies(.016,.016)
			var body:Rect2=game._enemy_body_box(boss)
			check(body.position.x>=0 and body.end.x<=1500 and body.position.y>=0 and body.end.y<=1050,"Boss cannot escape any arena edge: "+biome)
	# Actual density comparison uses identical seeds and supports.
	var density_tower:Dictionary=Tower.generate(9191)
	var density_rooms:Array=density_tower["rooms"].filter(func(r:Dictionary)->bool:return r["type"] in ["combat","elite"] and not r.get("spring",false))
	var layout:Dictionary=Layout.generate(density_rooms[0],9191);var normal:int=0;var denser:int=0
	for seed_value in 200:
		normal+=Ecology.spawn_plan(layout,Ecology.from_stage(0),"rogue",seed_value,2,1.0).size();denser+=Ecology.spawn_plan(layout,Ecology.from_stage(0),"rogue",seed_value,2,1.2).size()
	check(denser>normal,"Twenty percent spawn rate increase produces more actual enemies")
	game._ui_action("hub",null);game._open_tuning();await process_frame
	var editor=game.tuning_view;check(editor!=null and editor.editors.has("seed"),"Home opens the dedicated parameter editor")
	editor.set_value("charge_seconds",.9);editor.set_value("player_damage",1.5);editor.set_value("rooms_per_stage",8);editor.set_value("seed",777)
	editor._save();await process_frame;game.new_run("rogue");game._close_panel()
	check(game.tower["seed"]==777 and game.tower["rooms"].size()==48 and is_equal_approx(game._charge_threshold(),.9),"Saved editor values affect the next actual adventure")
	check(is_equal_approx(game._primary_definition({"dir":"right","charged":false})["damage"],Data.primary_attack(game.weapon_index,"right",false)["damage"]*1.5),"Saved combat values affect live attacks")
	game._load_meta();check(is_equal_approx(float(game.meta["rd_tuning"]["charge_seconds"]),.9),"Tuning survives persisted profile reload")
	var fresh=load("res://main.tscn").instantiate();fresh.audio_enabled=false;root.add_child(fresh);await process_frame;fresh.set_process(false);fresh.set_physics_process(false)
	check(is_equal_approx(float(fresh.meta["rd_tuning"]["charge_seconds"]),.9),"A fresh application process loads the saved RD settings")
	fresh.queue_free();Tuning.activate({});print("v19: ",layouts," combat layouts, ",geometry.size()," central geometries, solidity ",[minimum,maximum],"; spawns ",[normal,denser],"; ","passed" if failures.is_empty() else failures)
	game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
