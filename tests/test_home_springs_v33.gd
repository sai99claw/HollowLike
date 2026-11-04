extends SceneTree
const Tower=preload("res://scripts/tower.gd")
const Art=preload("res://scripts/scene_art_v33.gd")
var failures:Array[String]=[]
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var shops:int=0;var chapters:int=0;var wet:int=0;var fights:int=0
	for seed_value in 200:
		var tower:Dictionary=Tower.generate(seed_value)
		check(Tower.validate(tower).is_empty(),"Probabilistic rooms preserve tower topology")
		for chapter:Dictionary in tower["maps"]:chapters+=1;shops+=int(chapter["merchant_id"]>=0)
		for room:Dictionary in tower["rooms"]:
			check(not room.get("spring",false),"No dedicated spring room is generated")
			if room["type"] in ["combat","elite"]:fights+=1;wet+=int(room.get("fountain",false))
	check(absf(float(shops)/chapters-.3)<.05,"Merchant roll is thirty percent per chapter")
	check(absf(float(wet)/fights-.1)<.02,"Each hostile room independently rolls ten percent fountain chance")
	for biome:String in ["sky","trunk","underground"]:
		check(Art.texture("res://assets/v33/safehouses/"+biome+"-background.png")!=null,"Each ecology has an independent safehouse background")
		for id:String in ["aid","forge","reforge","mail","energy_infinite","wardrobe"]:check(Art.region("res://assets/v33/safehouses/"+biome+"-stations.json",id)!=null,"Every station has all three ecology skins")
	var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false)
	check(g.weapon_index==1 and not g.props.any(func(p:Dictionary)->bool:return p["kind"]=="wardrobe"),"Home starts with feather knife and no cloak station")
	g.home_sleeping=false;g.home_wake_left=0;g._set_action("jump",true);g._physics_process(.02)
	check(not g.p["grounded"] and g.p["vel"].y<0,"Home uses real jumping physics")
	g._set_action("jump",false);g._set_action("jump",true);g._physics_process(.02)
	check(g.p["jumps"]==2 and g.p["flap_left"]>0,"Home allows double jump before exploration unlocks")
	g._set_action("dash",true);g._physics_process(.06);g._set_action("dash",false);g._set_action("dash",true);g._physics_process(.06)
	check(g.p_attack.attack.get("kind","")=="pierce","Home allows double-C wind movement")
	g._configure_home();g._clear_keys();g._reset_player(Vector2(455,600));g._physics_process(.01)
	check(is_equal_approx(g.p["vel"].y,-530.0) and not g.p["grounded"],"Home contact uses the same normal launcher impulse as game objects")
	g._configure_home();g._clear_keys();g._reset_player(Vector2(790,600));g._interact();check(g.ui.is_panel_open(),"Adventure records are an actual nearby station")
	g._close_panel();g._reset_player(Vector2(1080,600))
	var saved_meta:Dictionary=g.meta.duplicate(true)
	check(g._home_interact() and g.lab_mode=="tutorial" and not g.ui.is_panel_open(),"Tutorial entrance opens directly into the practice room")
	check(g.enemies.size()==3 and g.layout["one_way"].size()==3,"One harmless target per platform")
	for i in g.enemies.size():
		var target:Dictionary=g.enemies[i]
		var platform:Rect2=g.layout["one_way"][i]
		check(target["contact_damage"]==0.0 and target["pos"].y==platform.position.y,"Target starts on its platform")
		g._hit_enemy(target,target["hp"],Color.WHITE)
		g._update_enemies_profiled_body(2.99)
		check(target["hp"]<=0.0,"Target stays defeated for nearly three seconds")
		g._update_enemies_profiled_body(.011)
		check(target["hp"]==target["max_hp"] and target["pos"]==target["anchor"],"Target respawns in place after three seconds")
	check(g.bag_weapons.size()>=3 and not g._hurt_player(100,Vector2.ZERO),"Tutorial supplies weapon examples and prevents all damage")
	g.room_cooldown=0
	g.p["pos"]=g._tutorial_station_position(1);g._interact()
	check(g.ui.is_panel_open(),"Rune station opens when interacted with nearby")
	var rune_id:String=g.Data.all_runes()[0]["id"]
	g._ui_action("tutorial_rune",rune_id);g._ui_action("tutorial_rune",rune_id)
	check(g.bag_runes.get(rune_id,0)==2,"Rune station supports repeat pickups")
	g._close_panel()
	g.p["pos"]=g._tutorial_station_position(0);g._interact()
	check(g.ui.is_panel_open(),"Weapon station opens when interacted with nearby")
	g._ui_action("lab_secondary",2);g._begin_secondary()
	check(g.secondary_index==2 and g.p_attack.attack.get("kind","")=="secondary","A station weapon can be selected and fired")
	g.p["pos"]=g._tutorial_station_position(2);g._interact()
	check(g.ui.is_panel_open(),"Effect station opens when interacted with nearby")
	g._ui_action("tutorial_demo","pierce")
	check(not g.ui.is_panel_open() and g.p_attack.attack.get("kind","")=="pierce","Effect station plays the real piercing action")
	g._leave_lab()
	check(g.screen=="hub" and g.meta==saved_meta,"Tutorial exit restores permanent progress")
	g.home_sleeping=false;g._reset_player(Vector2(330,600))
	g._set_action("right",true);g._set_action("jump",true)
	var launched:bool=false
	var double_jumped:bool=false
	var reached:bool=false
	var apex:float=600
	for tick in 180:
		if not launched:
			if g.p["pos"].x>=454:g._set_action("right",false)
			if tick==23:g._set_action("down",true);g._set_action("attack",true)
		var previous_y_speed:float=g.p["vel"].y
		g._update_home(1.0/60)
		if not launched and g.props[1].get("launch_hit_cooldown",0)>0:
			launched=true
			g._set_action("down",false);g._set_action("attack",false);g._set_action("jump",false)
			g._set_action("right",true)
		if launched and not double_jumped and previous_y_speed<0 and g.p["vel"].y>=0:
			g._set_action("jump",true);double_jumped=true
		if g.p["pos"].x>=625:g._set_action("right",false)
		if double_jumped:apex=minf(apex,g.p["pos"].y)
		if g._at_rogue_gate():reached=true;break
	check(launched and double_jumped and reached,"A grounded jump, aerial down strike and air jump reach the Rogue platform")
	check(absf(g.HomeArt.ROGUE_PLATFORM_Y-apex-50.0)<1.0,"Rogue platform is 50 px below the measured combo apex")
	if reached:
		g._home_interact()
		check(g.screen=="game" and g.mode=="rogue" and g.lab_mode.is_empty(),"Upper gate enters the real Rogue expedition")

	g.meta["rd_tuning"]={"merchant_chance":1.0,"fountain_chance":1.0};g.new_run("rogue",33033);g._close_panel();await process_frame
	check(g.weapon_index==1,"A new run starts with feather knife")
	var display:Dictionary=g.drops.filter(func(d:Dictionary)->bool:return d.get("gift",false))[0];var at:Vector2=display["pos"]
	g.p["pos"]=at;g._update_drops(2)
	check(display["pos"]==at and not display["taken"] and display["vel"]==Vector2.ZERO,"Display weapon remains anchored and cannot auto-pickup")
	for room:Dictionary in g.tower["rooms"]:
		if not room.get("fountain",false):continue
		g._enter_room(room["id"]);g._close_panel();await process_frame;var spring:Dictionary=g.props.filter(func(p:Dictionary)->bool:return p["kind"]=="fountain")[0]
		check(g.room["type"] in ["combat","elite"] and not g.enemies.is_empty(),"Fountain leaves the battle encounter active")
		g.p["pos"]=spring["pos"];g.p["hp"]=1;g.p["energy"]=0;g._update_props(1)
		check(g.p["hp"]==2 and g.p["energy"]==2,"Fountain heals from its grounded interaction range")
		g._hit_props(preload("res://scripts/spring_v33.gd").body(spring["pos"]),1,99)
		check(not g.spring_particles.bursts.is_empty() and g.spring_particles.bursts[0].texture is GradientTexture2D,"Hitting spring emits native water droplets")
		check(not spring["used"] and g.effects.filter(func(e:Dictionary)->bool:return e.has("water_attack")).is_empty(),"Spring survives hits without a splash sprite effect")
		break
	g.queue_free();await process_frame
	print("v33 rates: merchant=",float(shops)/chapters," fountains=",float(wet)/fights,"; ",failures)
	quit(0 if failures.is_empty() else 1)
