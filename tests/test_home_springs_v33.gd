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
	check(absf(float(shops)/chapters-.5)<.05,"Merchant roll is fifty percent per chapter")
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
