extends SceneTree
const Layout=preload("res://scripts/room_layout.gd")
const Tower=preload("res://scripts/tower.gd")
const Motion=preload("res://scripts/enemy_motion.gd")
const Flight=preload("res://scripts/flight_navigation.gd")
const Coll=preload("res://scripts/world_collision.gd")
const Data=preload("res://scripts/game_data.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Music=preload("res://scripts/room_music.gd")
const FX=preload("res://scripts/combat_visual.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func actor(at:Vector2) -> Dictionary:
	return {"uid":9001,"pos":at,"vel":Vector2.ZERO,"face":1,"hp":100,"max_hp":100,"scale":1,"body_size":Vector2(34,42),"model":2,"speed":120,"stun":0,"hurt":0,"cooldown":100,"movements":["drift"],"movement_logic":"approach","hover_height":0,"attack":Attack.new(),"attacks":[],"contact_damage":0}
func run() -> void:
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	scene.set_physics_process(false);scene.set_process(false)
	var old_meta:Dictionary=scene.meta.duplicate(true)
	scene.new_run("rogue",6341);scene._close_panel()
	# Actual player solver and exit transition, not just the layout's graph.
	var exit_count:int=0;var types:Dictionary={}
	for seed_value in 12:
		scene.tower=Tower.generate(7340+seed_value)
		for r in scene.tower["rooms"]:
			if not r["neighbors"].has("up"):continue
			r["cleared"]=true;scene._enter_room(int(r["id"]));scene._close_panel();scene.room_cooldown=0
			var exit_x:float=scene.layout["doors"]["up"].x
			var support_y:float=INF
			for surface:Rect2 in scene.platforms:
				if surface.position.x+18<exit_x and surface.end.x-18>exit_x:support_y=minf(support_y,surface.position.y)
			var current:int=scene.current_room
			scene._clear_keys();scene._reset_player(Vector2(exit_x,support_y));scene.jump_request=true
			var speed:float=[.4,.8,1.5][seed_value%3]
			for frame in 150:
				scene._update_player(speed/60);scene._check_portals()
				if scene.current_room!=current:break
			check(scene.current_room==int(r["neighbors"]["up"]),"Upper exit traversable with one basic jump: seed %s room %s"%[seed_value,r["id"]])
			exit_count+=1;types[r["type"]]=true
	# Regression guard: old geometry with the final approach deleted is rejected.
	var old_layout:Dictionary=Layout.generate({"id":1,"type":"combat","neighbors":{"up":2}},42)
	old_layout["platforms"]=old_layout["platforms"].filter(func(rect:Rect2)->bool:return rect.position.y>111)
	check(not Layout.validate(old_layout).is_empty(),"Passability validator catches the original inaccessible opening")
	var random:=RandomNumberGenerator.new();random.seed=21
	# Pursue around a tall obstacle; collision solver remains authoritative.
	for movement in ["hover","drift"]:
		var en:Dictionary=actor(Vector2(500,700));en["movements"]=[movement]
		en["attack"].begin({"windup":100.0,"active":1.0,"recovery":1.0})
		var obstacles:Array=[Rect2(650,350,80,500)]
		var collisions:int=0
		for frame in 1500:
			var vel:Vector2=Motion.velocity(en,Vector2(950,700),.02,random,false,obstacles,Vector2(34,42))
			var result:Dictionary=Coll.move_body(en["pos"],vel,.02,Vector2(34,42),obstacles)
			en["pos"]=result["pos"];en["vel"]=result["vel"]
			if Rect2(en["pos"]-Vector2(17,42),Vector2(34,42)).intersects(obstacles[0]):collisions+=1
		check(en["pos"].x>900 and collisions==0,"%s finds clear route around a wall during an uninterrupted attack"%movement)
		check(en["attack"].is_busy(),"Avoiding terrain does not cancel enemy attacks")
	# Immediate escape from a nearby wall, retaining the attack clock.
	var en:Dictionary=actor(Vector2(620,680));en["attack"].begin({"windup":10.0,"active":1.0,"recovery":1.0})
	var escape:Vector2=Motion.velocity(en,Vector2(950,680),.02,random,false,[Rect2(650,350,80,500)],Vector2(34,42))
	check(escape.x<0,"Nearby wall takes priority over pursuit toward it")
	# Vector knockback must affect the actor's real position, not just metadata.
	scene.solids.clear();scene.platforms.clear();scene.camera_pos=Vector2(200,200);scene.world_speed=1;scene.screen="game"
	for direction in ["up","down"]:
		scene._reset_player(Vector2(700,500));scene.p["grounded"]=false;scene.p["invul"]=10;scene.weapon_index=1
		en=actor(Vector2(700,445 if direction=="up" else 555));en["movements"]=["walk"];scene.enemies.assign([en])
		var def:Dictionary=Data.primary_attack(1,direction,false)
		scene.p_attack.begin(def);scene.p_attack.tick(float(def["windup"])+.01)
		scene._process_player_attack()
		check(en["hp"]==97,"Vertical primary attack actually hits its target")
		check(absf(en["push_velocity"].x)<.001 and signf(en["push_velocity"].y)==(-1 if direction=="up" else 1),"Target knockback follows vertical aim")
		check(absf(scene.p["recoil_velocity"].x)<.001,"Vertical attack never recoils the player sideways")
		var before:Vector2=en["pos"];scene._update_enemies(.02,.02)
		check(absf(en["pos"].x-before.x)<.001 and (en["pos"].y-before.y)*(-1 if direction=="up" else 1)>0,"Target moves vertically through real physics")
		if direction=="up":
			check(scene.p["recoil_velocity"].y>0,"Upward attack recoils player downward")
		else:check(scene.p["vel"].y<0 and scene.p["recoil_left"]==0,"Downslash keeps its enhanced upward bounce")
	for i in 3:
		check(Data.primary_attack(i,"right",false)["recoil"]==[60,30,0][i],"Normal self recoil reduced by fifty percent")
		check(Data.primary_attack(i,"right",true)["recoil"]==0,"Released charge has no movement-blocking recoil")
	check(not scene.show_hitboxes,"Hitboxes and enemy trajectory guidance start hidden")
	# All delivered clips and all nine named tracks are available in export too.
	check(FX.ensure() and FX.manifest["animations"].size()==277,"Delivered combat manifest is connected")
	var frame_count:int=0
	for clip in FX.manifest["animations"].values():
		for f in clip["frames"]:
			check(load(FX.ROOT+f["path"]) is Texture2D,"Delivered frame resolves through Godot import")
			frame_count+=1
	check(frame_count==1193,"All 1193 delivered animation frames load")
	var selected:Dictionary={}
	for biome in ["sky","canopy","branches","trunk","grass","underground"]:
		for room_type in ["combat","boss","start"]:
			var title:String=Music.title_for(room_type,biome)
			selected[title]=true
			var audio=load(Music.ROOT+title+".ogg")
			check(audio is AudioStreamOggVorbis,"Filename-mapped room music is playable")
			check(Music.title_for("combat",biome,true)==Music.title_for("start",biome),"Spring overrides combat music with ecological relaxation track")
	check(selected.size()==9,"Room mapping uses every supplied music title")
	var player=Music.new();root.add_child(player);player.select("combat","sky")
	await create_timer(.06).timeout
	check(player.stream.loop and player.playing,"Music plays and loops")
	var same=player.stream;player.select("combat","sky");check(player.stream==same,"Same song is retained across adjacent rooms")
	player.set_enabled(false);check(AudioServer.is_bus_mute(0),"Sound setting mutes the complete sound bus")
	player.set_enabled(true);check(not AudioServer.is_bus_mute(0) and not player.stream_paused,"Music is audible and playback remains live after unmuting")
	await create_timer(.06).timeout
	player.stop();player.stream=null;player.queue_free()
	await create_timer(.1).timeout
	scene.meta=old_meta;scene._save_meta();scene.queue_free()
	if failures.is_empty():print("v0.6 passed: %d actual upper-door transitions (%s), flying routes while attacking, vertical hit physics, half recoil, 277 clips/1193 frames, nine looping room tracks"%[exit_count,str(types.keys())])
	else:print("v0.6 failures: ",failures)
	quit(0 if failures.is_empty() else 1)
