extends SceneTree
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Feedback=preload("res://scripts/combat_feedback.gd")
const Laser=preload("res://scripts/laser_art_v38.gd")
const Crescent=preload("res://scripts/clean_crescent_v38.gd")
const MonsterArt=preload("res://scripts/monster_art_v36.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func reset(g) -> void:
	g._close_panel();g.life_event={};g.hitstop=0;g.shake=0;g._clear_keys();g.p_attack.cancel();g._reset_player(Vector2(700,1000))
	g.enemies.clear();g.props.clear();g.doors.clear();g.projectiles.clear();g.hazards.clear();g.effects.clear();g.drops.clear();g.solids.clear();g.platforms.clear();g.combat_feedback.clear()
	g.layout={"size":Vector2(2000,1500),"floor_y":1200.0,"tile_size":96};g.room_cooldown=999;g.world_speed=1;g.freeze_timer=0;g.camera_pos=g._camera_target(g.p["pos"])
func enemy(g,biome:String,index:int,elite:bool=false) -> Dictionary:
	var en:Dictionary=Roster.elite(index) if elite else Roster.regular(biome,index)
	en.merge({"uid":123,"pos":Vector2(g.p["pos"]),"vel":Vector2.ZERO,"face":1.0,"hp":100.0,"max_hp":100.0,"hurt":0.0,"stun":0.0,"cooldown":100.0,"attack":Attack.new(),"combat_engaged":true},true)
	return en
func run() -> void:
	var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.practice_mode=true;g.new_run("rogue",380038)
	for elite:bool in [false,true]:
		for frozen:bool in [false,true]:
			reset(g);var en:Dictionary=enemy(g,"sky",2,elite);g.enemies.assign([en]);g.freeze_timer=2 if frozen else 0;var hp:int=g.p["hp"]
			g._update_enemies(.001,0);check(g.p["hp"]==hp-1,"Hostile contact hurts even while frozen, elite="+str(elite))
			g._update_enemies(.001,0);check(g.p["hp"]==hp-1,"Contact respects player invulnerability")
	reset(g);g.enemies.assign([enemy(g,"underground",0)]);g._dash_pressed();g._update_enemies(.001,0);check(g.p["hp"]==4,"C contact remains vulnerable")
	reset(g);g.enemies.assign([enemy(g,"underground",0)]);g.p_attack.begin({"kind":"pierce","windup":.1,"active":.3,"recovery":.2});g._update_enemies(.001,0);check(g.p["hp"]==5,"CC contact is protected during windup")
	reset(g);var harmless:Dictionary=enemy(g,"underground",0);harmless.merge({"training":true,"contact_damage":0.0},true);g.enemies.assign([harmless]);g._update_enemies(.001,0);check(g.p["hp"]==5,"Training target stays harmless")
	reset(g);g.p["grounded"]=true;g.p["jump_buffer_left"]=.1;g._step_player(.001)
	check(g.combat_feedback.bursts.is_empty(),"First jump does not emit the second-jump burst")
	g.p["coyote_left"]=0;g.p["jump_buffer_left"]=.1;g._step_player(.001)
	check(g.p["jumps"]==2 and g.combat_feedback.bursts.size()==1,"Actual double jump emits feathers")
	if not g.combat_feedback.bursts.is_empty():
		var burst:CPUParticles2D=g.combat_feedback.bursts[0]
		check(burst.texture!=null and burst.direction==Vector2.DOWN and burst.initial_velocity_min>=145 and burst.amount>=18,"Double jump uses visible textured downward feathers")
		g.combat_feedback.set_frozen(true);check(burst.speed_scale==0,"Feathers respect hitstop")
	for biome:String in Roster.BIOMES:
		for row in 5:
			for face:float in [-1,1]:
				var en:Dictionary=Roster.regular(biome,row);en["pos"]=Vector2(500,500);en["face"]=face;en["vel"]=Vector2.ZERO
				var at:=Vector2(500,475)
				for dir:Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
					var origin:Vector2=Feedback.spray_origin(en,at,dir)
					check(origin.is_equal_approx(at),"Spray starts at the supplied sprite center in every direction")
	check(Crescent.info()["frames"]==1 and Crescent.texture()!=null,"Single clean crescent ships as a real texture")
	check(Laser.info()["frames"].size()==8 and Laser.texture()!=null,"Eight separate continuous beam frames ship")
	var indices:Dictionary={}
	for i in 8:indices[Laser.frame_index((float(i)+.1)/24)]=true
	check(indices.size()==8,"Laser animation visits all eight pulse frames")
	reset(g);g.solids.assign([Rect2(1100,0,80,1500)])
	var target:Dictionary=enemy(g,"underground",0);target["pos"]=Vector2(900,1024);g.enemies.assign([target])
	g._cast_special(Vector2(700,1000),Vector2.RIGHT,{"weapon_kind":"laser","count":1,"range":900.0,"size":20.0,"damage":2.0,"color":Color.WHITE})
	check(g.effects.size()==1 and g.effects[0].get("beam",false) and g.effects[0]["width"]==40,"One shot creates one coherent width-aware beam")
	check(g.effects[0]["end"].x<=1080.01 and target["hp"]<100,"Laser stops before walls and hits within visible width")
	# First lethal hit preserves the previous cache; second snapshots the new one.
	reset(g);g.run_coins=57;g.bag_runes={"gale":3,"reach":2};g.bag_items={"0":4};g.bag_weapons.assign([g.Data.secondary_attack(0)]);g.sub_growth={"power":3};g.rune_slots.assign(["gale"]);g.injured=false;g.revive_used=false
	g.feather={"room":-1,"pos":Vector2.ZERO,"payload":{}};var vault:Dictionary=g.meta.duplicate(true);var seed_value:int=g.tower["seed"];var death_room:int=g.current_room
	g._death();check(g.life_event["kind"]=="injury" and g.feather["room"]==-1,"First down preserves previous feather")
	g.life_event["landed"]=true;g.life_event["land_time"]=0;g._update_life_event(1.01);check(g.injured and g.revive_used,"First down revives injured")
	g._death();check(g.life_event["kind"]=="death" and g.feather["payload"]["coins"]==57 and g.feather["room"]==death_room,"Second down replaces cache with a deep inventory snapshot")
	g.bag_runes["gale"]=9;check(g.feather["payload"]["runes"]["gale"]==3,"Feather snapshot is detached from carried counts")
	g.life_event["landed"]=true;g.life_event["land_time"]=0;g._update_life_event(1.11);check(g.life_event["kind"]=="await_choice" and g.ui.is_panel_open(),"Death opens the rune grid after transforming into feather")
	g._choose_soul_rune("gale");check(g.bag_runes=={"gale":1} and g.feather["payload"]["runes"]["gale"]==2,"Chosen rune is carried exactly once and removed from cache")
	g._update_life_event(1.41);check(g.life_event.is_empty() and g.room["type"]=="start" and g.tower["seed"]==seed_value and not g.revive_used,"Soul returns to safety in same adventure with fresh injury chance")
	check(g.meta==vault and g.bag_items.is_empty() and g.bag_weapons.is_empty() and g.run_coins==0,"Warehouse unchanged and unchosen belongings remain in feather")
	g._enter_room(death_room);g._recover_feather();check(g.bag_runes=={"gale":3,"reach":2} and g.bag_items=={"0":4} and g.run_coins==57 and g.sub_growth=={"power":3} and g.feather.is_empty(),"Cache recovery restores exact counts, money and growth")
	g._recover_feather();check(g.run_coins==57 and g.bag_runes["gale"]==3,"Empty recovery cannot duplicate items")
	g.mode="musou";g.bag_weapons.clear()
	for i in 16:g.bag_weapons.append(g.Data.secondary_attack(0))
	g.feather={"room":g.current_room,"pos":Vector2.ZERO,"payload":{"coins":10,"runes":{"reach":1},"items":{},"weapons":[g.Data.secondary_attack(1)],"growth":{"power":1}}}
	g._recover_feather();check(g.bag_weapons.size()==16 and g.feather["payload"]["weapons"].size()==1,"Musou overflow stays in feather instead of losing the seventeenth weapon")
	var money:int=g.run_coins;var power:int=g.sub_growth["power"];g._recover_feather();check(g.run_coins==money and g.sub_growth["power"]==power,"Repeated overflow recovery does not duplicate other payload")
	g.bag_weapons.pop_back();g._recover_feather();check(g.feather.is_empty() and g.bag_weapons.size()==16,"A free slot recovers the remaining weapon")
	g.mode="rogue";g.bag_weapons.assign([g.Data.secondary_attack(0)]);g.bag_weapons[0]["duplicate_bonus"]=6
	var duplicate:Dictionary=g.Data.secondary_attack(0);duplicate["duplicate_bonus"]=4
	g.feather={"room":g.current_room,"pos":Vector2.ZERO,"payload":{"coins":0,"runes":{},"items":{},"weapons":[duplicate],"growth":{}}};g._recover_feather();check(g.bag_weapons.size()==1 and g.bag_weapons[0]["duplicate_bonus"]==8,"Rogue recovery merges duplicate strengthening up to eight")
	g.queue_free();await process_frame;print("v38 combat checks: ",failures);quit(0 if failures.is_empty() else 1)
