extends SceneTree
const Combat=preload("res://scripts/combat_library.gd")
const Motion=preload("res://scripts/enemy_motion.gd")
const Bindings=preload("res://scripts/input_settings.gd")
const Visual=preload("res://scripts/boss_art.gd")
const Data=preload("res://scripts/game_data.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func fixture() -> Dictionary:
	return {"pos":Vector2(650,1050),"vel":Vector2.ZERO,"face":1.0,"attack":Attack.new(),"uid":999,"scale":1.0,"hp":100.0,"max_hp":100.0,"hurt":0.0,"stun":0.0,"cooldown":100.0,"model":0,"speed":100.0,"movements":["walk"],"movement_logic":"approach"}
func run() -> void:
	check(Visual._ensure(),"Boss manifest loads")
	var frames:int=0
	for clip in Visual.manifest["animations"].values():
		for f in clip["frames"]:
			check(Visual._texture(f["path"])!=null,"Boss frame texture loads: "+f["path"]);frames+=1
	check(frames==144 and Visual.manifest["animations"].size()==36,"All six Boss and six VFX sheets imported")
	var names:Dictionary={}
	for biome in Combat.BOSS_BIOMES:
		var boss:Dictionary=Combat.boss(biome);names[boss["id"]]=true
		check(boss["movements"].size()>=2 and boss["movements"][0]!=boss["movements"][1],"Boss has two movement primitives: "+biome)
		var kinds:Dictionary={}
		for def in boss["attacks"]:kinds[def["library_kind"]]=true
		check(kinds.size()>=2,"Boss has two attack types: "+biome)
		check(is_equal_approx(boss["body_size"].x*boss["body_size"].y,34.0*42.0*8),"Boss collision area is eight standard bodies: "+biome)
		for role in ["move","melee","ranged","slash_fx","projectile","impact"]:check(Visual.manifest["animations"].has(biome+"_"+role),"Boss art role present: "+biome+role)
	check(names.size()==6,"All six Boss IDs distinct")
	var bindings:Dictionary=Bindings.load_bindings({})
	check(bindings["heal"]==KEY_A and bindings["left"]==KEY_LEFT,"A heals; arrows move")
	for key in [KEY_W,KEY_S,KEY_D]:check(Bindings.action_for(bindings,key)=="","W/S/D have no default movement")
	check(Bindings.assign(bindings,"attack",KEY_A) and bindings["heal"]==KEY_X,"Duplicate key assignment swaps bindings")
	check(not Bindings.assign(bindings,"attack",KEY_ESCAPE),"Escape remains reserved")
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	scene.audio_enabled=false;scene.set_physics_process(false);scene.set_process(false);scene.practice_mode=true
	var saved_meta:Dictionary=scene.meta.duplicate(true)
	scene.new_run("rogue",9012)
	scene.meta["settings"]={};scene._load_settings();check(is_equal_approx(scene.camera_zoom,1.3),"New settings default zoom is 1.3")
	scene.key_bindings=bindings;scene.camera_zoom=1.55;scene._save_settings();scene.key_bindings={};scene.camera_zoom=1;scene._load_settings()
	check(is_equal_approx(scene.camera_zoom,1.55) and scene.key_bindings["attack"]==KEY_A,"Zoom and keybindings round-trip through persisted settings")
	scene._load_meta();scene._load_settings();check(is_equal_approx(scene.camera_zoom,1.55) and scene.key_bindings["heal"]==KEY_X,"Settings survive reading the save file")
	scene.capturing_key="jump"
	var capture:=InputEventKey.new();capture.physical_keycode=KEY_TAB;capture.pressed=true;scene._input(capture)
	check(scene.key_bindings["jump"]==KEY_TAB and scene.capturing_key.is_empty(),"Key capture accepts GUI navigation keys before GUI consumes them")
	scene._close_panel()
	var point:Vector2=Vector2(720,850);scene.camera_pos=Vector2(200,500);scene.shake=0;scene._process(0)
	check((scene.world_transform*point).is_equal_approx((point-scene.camera_pos)*1.55),"Terrain and actors use the zoom transform")
	check((scene.world_transform.affine_inverse()*(scene.world_transform*point)).is_equal_approx(point),"Zoom leaves world coordinates invertible")
	check(Data.primary_attack(2,"right",false)["windup"]==0 and is_equal_approx(Data.primary_attack(2,"right",false)["recovery"],1.876),"V18 heavy attack is immediate, preserving old total cadence in recovery")
	var target:Dictionary=fixture();scene.enemies.assign([target]);scene.p["pos"]=Vector2(620,1050);scene.p["face"]=1
	for game_mode in ["rogue","musou"]:
		scene.mode=game_mode;scene.upgrades["power"]=3
		for weapon in 3:
			scene.weapon_index=weapon;scene.p["impact_root"]=0;scene.p_attack.cancel();target["hp"]=100.0
			scene._begin_primary({"dir":"right","charged":false});scene.p_attack.tick(float(scene.p_attack.attack["windup"])+.001);scene._process_player_attack()
			var damage:float=100.0-float(target["hp"])
			scene._process_player_attack();check(is_equal_approx(100.0-float(target["hp"]),damage),"Normal attack hits target once")
			scene.p_attack.cancel();scene.p["impact_root"]=0;scene._clear_keys();scene.p["knockback_t"]=0;scene.p["energy"]=6;scene.dash_chain_open=true;scene.clock=10;scene.last_dash_time=9.8;scene._dash_pressed()
			check(is_equal_approx(float(scene.p_attack.attack["damage"]),2.0),"Pierce equals actual normal damage for mode/weapon")
			scene.p_attack.tick(.036);target["hp"]=100;scene._process_player_attack();scene._process_player_attack()
			check(is_equal_approx(100.0-float(target["hp"]),2.0),"Pierce deals equal damage exactly once")
			scene.p_attack.cancel();scene.keys["down"]=true;scene.p["energy"]=6;scene.dash_chain_open=true;scene._dash_pressed();scene.p_attack.tick(.036)
			target["hp"]=100;scene._slam_impact(Vector2(620,1050));scene._slam_impact(Vector2(620,1050))
			check(is_equal_approx(100.0-float(target["hp"]),2.0),"Down slam shares damage and deduplicates hits")
	# Force each chapter index; boss identity is stable within its ecology pair.
	scene.mode="rogue" # Windup checks need the mode with authored windup.
	var boss_id:int=int(scene.tower["maps"][0]["boss_id"])
	for i in 6:
		var r:Dictionary=scene.tower["rooms"][boss_id];r.erase("initialized");r["map_index"]=i;r.erase("layout")
		scene._enter_room(boss_id);var boss:Dictionary=scene.enemies[0]
		check(boss["id"]==Combat.boss(["underground","grass","trunk","branches","canopy","sky"][i])["id"] and r["boss_id"]==boss["id"],"Boss selected by stage without ecology replacing its visual identity")
		var seen:Dictionary={};scene.p["invul"]=100;scene.p["pos"]=Vector2(500,1050)
		for tick in 900:
			scene.camera_pos=scene._camera_target(boss["pos"]);scene._update_enemies(1.0/60);seen[Motion.current(boss)]=true
		check(seen.size()>=2,"Boss actually switches movement during combat: "+str(boss["id"]))
		for guard:Dictionary in scene.enemies.slice(1):
			guard["attack"].cancel();guard["cooldown"]=100.0
		for definition in boss["attacks"]:
			boss["attack"].cancel();scene.projectiles.clear();scene.hazards.clear();scene.freeze_timer=0
			scene.p["pos"]=boss["pos"]+Vector2(100,0);scene.p["invul"]=100
			scene._start_enemy_attack(boss,definition)
			scene.camera_pos=scene._camera_target(boss["pos"]);boss["attack"].tick(float(boss["attack"].attack["windup"])-.001);scene._update_enemies(0)
			check(scene.projectiles.is_empty() and scene.hazards.is_empty(),"Boss does not emit attacks during windup")
			scene._update_enemies(.002)
			if definition["library_kind"]=="trap":check(scene.projectiles.size()==int(definition["count"]),"Boss trap carriers emitted during active phase")
			elif not definition["primary"] and definition["library_kind"]!="explosion":check(scene.projectiles.size()==int(definition["count"]),"Boss ranged count emitted during active phase")
			else:check(boss["attack"].is_active(),"Boss melee enters damaging phase")
		boss["attack"].cancel()
		scene._enter_room(boss_id);check(scene.enemies[0]["uid"]==boss["uid"],"Boss room return preserves instance")
	# Runtime library parameters, range cap and high-speed swept target collision.
	scene.solids.clear();scene.platforms.clear();scene.enemies.clear();scene.p["pos"]=Vector2(1300,1050);scene.projectiles.clear()
	var shot:Dictionary=Combat.attack("linear",{"size":12,"range":100,"speed":500,"count":3,"spread":0,"piercing":true})
	scene._emit_weapon(Vector2(500,500),Vector2.RIGHT,shot,true)
	check(scene.projectiles.size()==3 and scene.projectiles[0]["radius"]==12 and scene.projectiles[0]["pierce"],"Bullet size/count/pierce applied")
	check(is_equal_approx(scene.projectiles[0]["vel"].length(),500),"Bullet speed applied")
	scene._update_projectiles(.5);check(scene.projectiles.is_empty(),"Projectiles expire at configured travel range")
	var arc:Dictionary=Combat.attack("arc",{"curve":{"gravity":400,"launch_y":-200},"speed":100,"range":1000})
	scene._emit_weapon(Vector2(500,500),Vector2.RIGHT,arc,true);scene._update_projectiles(.25)
	check(is_equal_approx(scene.projectiles[0]["vel"].y,-100),"Arc curvature uses launch velocity and gravity")
	scene.projectiles.clear();target=fixture();target["pos"]=Vector2(700,500);scene.enemies.assign([target])
	scene._emit_weapon(Vector2(500,475),Vector2.RIGHT,Combat.attack("linear",{"speed":2500,"range":1000}),true);scene._update_projectiles(.16)
	check(target["hp"]==99 and scene.projectiles.is_empty(),"Fast nonpiercing shot hits crossed body instead of tunneling")
	# Locked trap placement, arm delay, effective-hit counting and expiry.
	scene.p_attack.cancel();scene.platforms.assign([Rect2(0,1050,1500,70)]);scene.hazards.clear();scene.p["pos"]=Vector2(500,1050);scene.p["hp"]=100;scene.p["invul"]=0;scene.p["shield"]=0
	var trap:Dictionary=Combat.attack("trap",{"target":Vector2(500,1050),"size":50,"max_hits":2,"hit_interval":.7,"arming_time":.5,"damage":2,"lifetime":5})
	scene._emit_traps(target,trap);scene._update_projectiles(.4)
	var actual_arming:float=float(scene.hazards[0]["arming_time"])
	scene._update_hazards(actual_arming-.01);check(scene.p["hp"]==100,"Trap arming causes no early damage")
	scene._update_hazards(.02);check(scene.p["hp"]==98,"Armed trap hits")
	scene.p["invul"]=0;scene._update_hazards(.3);check(scene.p["hp"]==98,"Trap respects per-target interval")
	scene._update_hazards(.41);check(scene.p["hp"]==96 and scene.hazards.is_empty(),"Trap removed after two effective hits")
	# Dash movement must get through bracing into locked travel, not restart bracing forever.
	var moving:Dictionary=fixture();moving["movements"]=["dash"];var random:=RandomNumberGenerator.new();random.seed=1
	var fastest:float=0
	for tick in 80:
		moving["vel"]=Motion.velocity(moving,Vector2(900,1050),1.0/60,random,true);fastest=maxf(fastest,absf(moving["vel"].x))
	check(fastest>=370,"Dash movement exits bracing and travels")
	# Coin integration preserves value, delays pickup and produces impact feedback.
	scene.drops.clear();scene.effects.clear();scene.p["pos"]=Vector2(100,1050);scene._drop("coin",Vector2(700,1000),7)
	for tick in 90:scene._update_drops(1.0/60)
	check(scene.drops.size()==7 and scene.drops.all(func(d):return d["value"]==1) and scene.drops.any(func(d):return d["rotation"]!=0),"Coins roll physically without losing value")
	scene.drops.clear();var gold:int=int(scene.meta["coins"]);scene._drop("coin",scene.p["pos"]-Vector2(0,20),5);scene._update_drops(0)
	check(int(scene.meta["coins"])==gold,"New coins do not immediately bypass their launch animation")
	scene.meta=saved_meta;scene._save_meta();scene.queue_free();await process_frame
	print("Boss/combat/settings regression: ","passed" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
