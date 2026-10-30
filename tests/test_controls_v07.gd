extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Bindings=preload("res://scripts/input_settings.gd")
const Walk=preload("res://scripts/walk_animation.gd")
const Map=preload("res://scripts/tower_map_view.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func jump_height(scene,release_at:int) -> float:
	scene._reset_player(Vector2(700,1050));scene._clear_keys();scene.p_attack.cancel();scene.solids.clear();scene.platforms.assign([Rect2(0,1050,1500,70)])
	scene._set_action("jump",true)
	var apex:float=1050
	for i in 100:
		if i==release_at:scene._set_action("jump",false)
		scene._update_player(1.0/120);apex=minf(apex,scene.p["pos"].y)
	scene._set_action("jump",false)
	return 1050-apex
func run() -> void:
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	scene.set_physics_process(false);scene.set_process(false);scene.practice_mode=true
	var saved:Dictionary=scene.meta.duplicate(true)
	scene.new_run("rogue",71059);scene._close_panel();scene.enemies.clear()
	var short_jump:float=jump_height(scene,3);var medium:float=jump_height(scene,15);var full:float=jump_height(scene,1000)
	check(short_jump<medium and medium<full and full>114 and full<115,"Variable jump grows with hold time and preserves previous full 530 impulse height")
	scene._set_action("jump",true);scene._set_action("jump",false);scene._reset_player(Vector2(700,1050));scene._set_action("jump",true);scene._set_action("jump",false);scene._update_player(.01)
	check(scene.p["vel"].y>=-190,"A tap released before the next physics tick still makes a small jump")
	for weapon in 3:
		for combo in 3:
			for direction in ["right","left","up","down"]:
				var def:Dictionary=Data.primary_attack(weapon,direction,false,false,combo)
				var active:float=[.09,.12,.16][weapon]
				check(is_equal_approx(def["active"],active) and is_equal_approx(def["hitbox_scale"],1.2),"V18 primary has a short active window and retains 20% larger geometry")
		check(is_equal_approx(Data.primary_attack(weapon,"right",true)["active"],1.0),"Charged active period has the v0.13 fixed one second override")
	check(Bindings.DEFAULTS["sub"]==KEY_Z,"New users start with Z secondary")
	scene.meta["settings"]={"keys":{"sub":KEY_U}};scene._load_settings();check(scene.key_bindings["sub"]==KEY_Z,"Old built-in U binding migrates to Z")
	scene.meta["settings"]={"keys":{"sub":KEY_U,"attack":KEY_Z}};scene._load_settings();check(scene.key_bindings["sub"]==KEY_U and scene.key_bindings["attack"]==KEY_Z,"User's custom Z binding remains intact")
	scene._reset_player(Vector2(700,1050));scene.p["hp"]=2;scene.p["energy"]=0
	for i in 4:scene._restore_vital("hp",.2);scene._restore_vital("energy",.4)
	check(scene.p["hp"]==2 and scene.p["energy"]==1 and is_equal_approx(scene.p["hp_recovery"],.8),"Partial healing accumulates separately while displayed resources stay whole")
	scene._update_hud();check(scene.ui.health_cells.value==2 and scene.ui.health_cells.recovering_index==2 and scene.ui.energy_cells.recovering_index==1,"Only the currently recovering cell flashes")
	scene._restore_vital("hp",.2);check(scene.p["hp"]==3 and is_zero_approx(scene.p["hp_recovery"]),"Completed fractional recovery becomes exactly one whole cell")
	scene._enter_room(int(scene.tower["maps"][0]["start_id"]));scene.room_cooldown=0;scene._close_panel()
	for kind in ["forge","reforge","aid","mail","energy_infinite"]:
		for prop in scene.props:
			if prop["kind"]==kind:scene.p["pos"]=prop["pos"]
		scene._set_action("up",true);scene._set_action("up",false)
		if kind=="aid":
			check(not scene.ui.is_panel_open() and scene.p["hp"]==scene.p["max_hp"],"Up at aid heals immediately without a panel");continue
		check(scene.prep_station==kind and scene.ui.is_panel_open(),"Up opens the nearby station: "+kind)
		var buttons:Array[String]=[]
		collect_buttons(scene.ui.panel_rows,buttons)
		if kind=="forge":check(scene.ui.panel_rows.find_child("BlueprintGrid",true,false)!=null and not buttons.has("接受急救"),"Forge opens its dedicated blueprint grid")
		if kind=="aid":check(buttons.has("接受急救") and not buttons.has("全部寄送") and not buttons.has("合成－30金幣"),"Aid menu is isolated")
		if kind=="reforge":check(scene.ui.panel_rows.find_child("ReforgeSockets",true,false)!=null,"Reforge opens its three sockets")
		if kind=="mail":check(scene.ui.panel_rows.find_child("WarehouseGrid",true,false)!=null and not buttons.has("接受急救"),"Warehouse opens its storage grid")
		scene._close_panel()
	check(Map.coordinate({"coord":Vector2i(0,-3)}).y<Map.coordinate({"coord":Vector2i(0,2)}).y,"Upper rooms are above lower rooms on both tower maps")
	scene._show_map();check(scene.ui.is_panel_open(),"Expanded map renders the connected full-tower diagram");scene._close_panel()
	check(not scene.show_hitboxes,"All debug geometry and projectile aim guides default to hidden")
	scene.combat_feedback.clear();scene.projectiles.clear();scene.enemies.clear();scene.solids.clear();scene.platforms.clear()
	scene._emit_weapon(Vector2(600,500),Vector2.RIGHT,load("res://scripts/combat_library.gd").attack("arc",{"speed":150,"range":1000}),true)
	scene._update_projectiles(.05);var pr:Dictionary=scene.projectiles[0];var key:int=pr["trail_id"];var emitter:CPUParticles2D=scene.combat_feedback.trails[key]["emitter"]
	check(emitter.local_coords and emitter.position==Vector2.ZERO and emitter.texture is GradientTexture2D,"Native projectile trail stays in world coordinates and has a soft transparent particle texture")
	var before:Vector2=emitter.emission_points[0];scene._update_projectiles(.05)
	check(emitter.emission_points[0]!=before and emitter.position==Vector2.ZERO,"Emission follows the real curved path without dragging previous particles")
	scene.combat_feedback.finish_trail(pr);check(not emitter.emitting,"Finished projectile stops adding trail particles")
	check(Walk.clip()["frames"].size()==12 and Walk.clip()["fps"]==20,"New 12-frame walk manifest replaces old four-frame cycle")
	for f in Walk.clip()["frames"]:check(Vector2(f["pivot"][0],f["pivot"][1]).is_equal_approx(Vector2(164,224)) and ResourceLoader.exists(Walk.ROOT+f["path"]),"Walk uses a shared authored foot pivot and all delivered PNGs")
	var walk=scene.walker;walk.reset();walk.emitted_events=0
	walk.advance(16.5*5,true,"wood",false);check(Walk.frame_index==5 and walk.emitted_events==1,"Walking starts at frame zero and advances by distance")
	walk.advance(16.5*14,true,"wood",false);check(Walk.frame_index==7 and walk.emitted_events==4,"Low frame rate crossing multiple footfalls does not miss or duplicate events")
	walk.advance(20,false,"stone",false);check(Walk.frame_index==0 and walk.emitted_events==4,"Stopping, jumping or being hurt resets phase without footsteps")
	for ground in ["wood","stone","grass"]:
		var last:int=0
		for i in 12:
			walk._footstep(ground,false);var current:int=walk.last_variants[ground];check(current!=last,"Footstep variations never repeat consecutively");last=current
		for variant in range(1,5):check(ResourceLoader.exists("res://assets/audio/footsteps/footstep_%s_%02d.wav"%[ground,variant]),"Delivered footstep WAV is available")
	scene.meta=saved;scene._save_meta();scene.queue_free();await process_frame
	print("Controls v0.7: ","passed: variable jump, 20% primary geometry/time, Z migration, integer vital cells, separated E stations, tower map orientation, particle trails, 12-frame walking and synchronized footsteps" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
func collect_buttons(node:Node,result:Array[String]) -> void:
	if node is Button:result.append(node.text)
	for child in node.get_children():collect_buttons(child,result)
