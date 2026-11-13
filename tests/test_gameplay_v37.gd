extends SceneTree
const Ledge=preload("res://scripts/ledge_mantle_v37.gd")
const Corpses=preload("res://scripts/corpse_field_v21.gd")
const Atmosphere=preload("res://scripts/atmosphere.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func reset(g,at:Vector2) -> void:
	g._close_panel();g.life_event={};g.hitstop=0;g.shake=0;g._clear_keys();g.p_attack.cancel();g._reset_player(at);g.p["grounded"]=false
	g.enemies.clear();g.props.clear();g.doors.clear();g.projectiles.clear();g.hazards.clear();g.drops.clear();g.solids.clear();g.platforms.clear();g.layout={"size":Vector2(2000,1500),"floor_y":1200.0,"tile_size":64};g.room_cooldown=999;g.world_speed=1
func run() -> void:
	var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.practice_mode=true;g.new_run("rogue",370037)
	var normal_speed:float=g._movement_factor()
	g.keys["attack"]=true;g.charge_timer=.25
	check(is_equal_approx(g._movement_factor(),normal_speed*.8),"Quick-draw charging reduces movement speed by twenty percent")
	g.keys["attack"]=false
	check(is_equal_approx(g._movement_factor(),normal_speed),"Released attack restores normal movement speed")

	reset(g,Vector2(600,1000));g.p["grounded"]=true
	g._dash_pressed();check(g.p["dash_t"]>0 and g.p["invul"]==0,"Single C grants no invulnerability")
	check(g._hurt_player(1,Vector2(550,1000)),"Single C can actually take damage")
	for dir:String in ["right","down"]:
		reset(g,Vector2(600,1000));g.p_attack.begin({"kind":"slam" if dir=="down" else "pierce","windup":.1,"active":.3,"recovery":.2,"dir":Vector2.DOWN if dir=="down" else Vector2.RIGHT})
		check(not g._hurt_player(1,Vector2.ZERO),"Double C protects windup: "+dir)
		g.p_attack.tick(.11);check(not g._hurt_player(1,Vector2.ZERO),"Double C protects active: "+dir)
		g.p_attack.tick(.3);g.p["slam"]=false;check(g._hurt_player(1,Vector2.ZERO),"Double C recovery is vulnerable: "+dir)
	reset(g,Vector2(600,1200));g.platforms.assign([Rect2(0,1200,2000,60)]);g.injured=false;g.revive_used=false;g.p["hp"]=1;g.p["shield_cells"]=0;var seed_value:int=g.tower["seed"]
	g._hurt_player(1,Vector2.ZERO);check(g.life_event.get("kind")=="injury" and g.revive_used,"First lethal hit reserves the single injured revival")
	for i in 300:
		if g.life_event.is_empty():break
		g._update_life_event(1.0/60)
	check(g.injured and g.p["hp"]>0 and g.tower["seed"]==seed_value,"First down revives injured in the same run")
	g.p["hp"]=1;g.p["invul"]=0;g._hurt_player(1,Vector2.ZERO);check(g.life_event.get("kind")=="death","Second lethal hit begins actual death")
	for side:int in [-1,1]:
		for ratio:float in [.20,.509,.51,.75,1.0]:
			var at:=Vector2(500,500);var edge:float=at.x+side*17
			var rock:=Rect2(edge if side>0 else edge-100,500-42*ratio,100,200)
			var result:Dictionary=Ledge.contact(at,side,[rock])
			check(is_equal_approx(result["ratio"],ratio),"Wall contact measures actual vertical overlap")
			check(result.has("target")== (ratio<.51),"Strict51percent threshold chooses mantle below and attachment at/above")
			if result.has("target"):
				reset(g,at);Ledge.begin(g.p,result["target"]);var seen:Dictionary={}
				for i in 32:seen[Ledge.frame_index(g.p["mantle_left"])]=true;g._step_player(.01)
				check(seen.size()==4 and g.p["grounded"] and g.p["pos"].is_equal_approx(result["target"]),"Mantle completes all four frames onto the solid top")
		reset(g,Vector2(500,500));g.p["vel"]=Vector2(side*200,-260)
		g.keys["right" if side>0 else "left"]=true
		g.solids.assign([Rect2(517 if side>0 else 383,390,100,200)])
		g._step_player(1.0/120)
		check(g.p["wall"]==0 and g.p["mantle_left"]==0 and g.p["vel"].y<0 and is_equal_approx(g.p["pos"].x,500),"Rising preserves upward motion and wall collision")
		for ratio:float in [.4,.6]:
			reset(g,Vector2(500,500));g.p["vel"]=Vector2(side*200,80);g.keys["right" if side>0 else "left"]=true
			g.solids.assign([Rect2(517 if side>0 else 383,500-42*ratio,100,200)]);g._step_player(1.0/120)
			check((g.p["mantle_left"]>0)==(ratio<.51),"Live controller uses overlap rule on either side")
			if ratio>.51:check(g.p["wall"]==side and g.p["wall_hold_left"]==1.0,"At least51percent latches and holds for one second")
		for input_direction:int in [0,-side]:
			reset(g,Vector2(500,500));g.p["vel"]=Vector2(side*200,80)
			if input_direction!=0:g.keys["right" if input_direction>0 else "left"]=true
			g.solids.assign([Rect2(517 if side>0 else 383,483,100,200)])
			g._step_player(1.0/120)
			check(g.p["mantle_left"]==0,"No mantle while idle or moving away from a valid ledge")
	var fragmented:Array=[Rect2(517,458,100,10),Rect2(517,468,100,32)]
	check(is_equal_approx(Ledge.contact(Vector2(500,500),1,fragmented)["ratio"],1),"Adjacent collision rectangles do not double count overlap")
	check(not Ledge.contact(Vector2(500,500),1,[Rect2(517,480,100,200),Rect2(510,420,120,35)]).has("target"),"Low ceiling blocks unsafe mantle")
	for distance:float in [383,384,385,550]:
		reset(g,Vector2(600,1200-distance));g.platforms.assign([Rect2(0,1200,2000,60)])
		for i in 300:
			g._update_player(1.0/120)
			if g.p["grounded"]:break
		check((g.p["heavy_land_left"]>0)==(distance>384),"Only falls strictly greater than six64px tiles trigger heavy landing: "+str(distance))
	for biome:String in ["underground","trunk","sky"]:
		reset(g,Vector2(600,1000))
		g.room["ecology"]=g.Ecology.from_stage(["underground","trunk","sky"].find(biome)*2)
		g.layout["pool"]=Rect2(468,955,264,45)
		g.p["hp"]=1;g.p["energy"]=0
		check(g._in_bath(),"Recessed pool contains the player's feet: "+biome)
		g._update_props(1);check(g.p["hp"]==2 and g.p["energy"]==2,"Bathing restores health and energy")
		g._hit_props(Rect2(588,963,24,30),1,99)
		check(not g.spring_particles.bursts.is_empty(),"Striking pool produces droplets")
		g.layout["pool"]=Rect2()
		g.bath.reset()
	var body:Dictionary=Corpses.create({"roster_id":"test","roster_biome":"sky","roster_row":0,"roster_elite":false,"pos":Vector2(500,500),"face":-1,"death_direction":Vector2.RIGHT,"death_knockback":76,"body_size":Vector2(34,45)})
	check(is_equal_approx(body["vel"].x,76*1.5) and body["factor"]==1,"Corpse preserves hit direction with1.5x lethal knockback and no scaling")
	g.atmosphere.configure("trunk",37,true,false,true,g.layout);g.atmosphere.depth_origin=Vector2.ZERO;g.atmosphere.depth_origin_ready=true
	var world:=Transform2D(0,Vector2.ONE*1.3,0,Vector2(-130,-260));g.atmosphere.backdrop_transform=Atmosphere.parallax(Vector2(100,200),1.3,Atmosphere.FAR_FACTOR);g.atmosphere.update_view(Vector2(100,200),1.3,world,Vector2(500,500),1,1,false)
	check(is_equal_approx(g.atmosphere.middle_objects.transform.origin.y,g.atmosphere.backdrop_transform.origin.y),"Quiet-room middle objects share backdrop vertical parallax")
	var before:Vector2=g.atmosphere.middle_objects.transform.origin;g.atmosphere.update_view(Vector2(300,200),1.3,world,Vector2(500,500),1,1,false)
	check(is_equal_approx(g.atmosphere.middle_objects.transform.origin.x-before.x,-200*1.3*.42),"200px camera move displaces middle objects by42percent")
	check(g.atmosphere.middle_objects.transform!=world and Atmosphere.MID_FACTOR>Atmosphere.FAR_FACTOR,"Middle/background/foreground have three different camera speeds")
	g.queue_free();await process_frame;print("v37 gameplay checks: ",failures);quit(0 if failures.is_empty() else 1)
