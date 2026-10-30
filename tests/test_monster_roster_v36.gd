extends SceneTree
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Motion=preload("res://scripts/monster_motion_v18.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
## Isolate deliberate ram timing; actual contact damage has its own v38 tests.
func fixture() -> Dictionary:
	var enemy:Dictionary=Roster.regular("underground",4)
	enemy.merge({"contact_damage":0.0,"uid":777,"pos":Vector2(700,1050),"vel":Vector2.ZERO,"face":1.0,"hp":100.0,"max_hp":100.0,"hurt":0.0,"stun":0.0,"cooldown":100.0,"attack":Attack.new(),"combat_engaged":true},true)
	return enemy
func run() -> void:
	var ids:Dictionary={};var elite_ids:Dictionary={}
	for biome:String in Roster.BIOMES:
		for index:int in 5:
			var en:Dictionary=Roster.regular(biome,index);ids[en["id"]]=true
			check(en["attacks"].size()==1 and en["movements"].size()==1,"Each regular species has one attack and one movement")
			check(en["contact_damage"]==1 and en["attacks"][0]["windup"]>=.4 and en["attacks"][0]["windup"]<=.7,"Hostile contact damage and readable deliberate attack tells coexist")
			check(Motion.body_size(en)==Vector2(34,45),"Collision stays in canonical actor size")
			check(en==Roster.regular(biome,index),"Species behavior is deterministic")
	for stage:int in 6:
		var en:Dictionary=Roster.elite(stage);elite_ids[en["id"]]=true
		check(en["attacks"].size()==2 and en["attacks"][0]["roster_attack"]==0 and en["attacks"][1]["roster_attack"]==1,"Elite anatomy has two distinct attack animation rows")
		check(en["attacks"][0]["windup"]>=.85 and en["attacks"][1]["windup"]>=.85,"Both elite attacks have readable tells")
	check(ids.size()==15 and elite_ids.size()==6,"Fifteen regular species and six map elites are unique")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",171);game._close_panel()
	var actual:Dictionary={};var elite_maps:Dictionary={};var boss_count:int=0
	for room:Dictionary in game.tower["rooms"]:
		game._enter_room(room["id"])
		for en:Dictionary in game.enemies:
			if en.get("training",false):continue
			if en["model"]==4:boss_count+=1;continue
			if not en.has("roster_id"):continue
			if en["roster_elite"]:
				elite_maps[int(room["map_index"])]=en["id"]
				check(en["id"]==Roster.elite(int(room["map_index"]))["id"],"Actual stage spawns only its defined elite")
				check(en["hp"]>=30,"Elite health retains the three-times multiplier")
			else:actual[en["id"]]=true
			if en["move"]!="fly":check(game.platforms.any(func(p:Rect2)->bool:return absf(p.position.y-en["pos"].y)<1 and en["pos"].x>=p.position.x and en["pos"].x<=p.end.x),"Ground species spawn on a supported surface")
	check(actual.size()==15 and elite_maps.size()==6 and boss_count==6,"Seeded full tower actually includes all authored families and all Bosses")
	check(game._lab_monsters().size()==28,"Practice exposes every regular, elite, cute animal and Boss")
	game.layout={"size":Vector2(1500,1120),"floor_y":1050.0};game.solids.assign([Rect2(0,1050,1500,70)]);game.platforms.assign([Rect2(0,1050,1500,8)]);game.freeze_timer=0
	var ram:Dictionary=fixture();game.enemies.assign([ram]);game._reset_player(Vector2(705,1050));game.camera_pos=game._camera_target(ram["pos"])
	var hp:float=game.p["hp"];game._start_enemy_attack(ram,ram["attacks"][0]);game._update_enemies(.05,.04)
	check(game.p["hp"]==hp and ram["attack"].phase=="windup","Touching a ram during its tell causes no damage")
	game.p["pos"]=Vector2(650,1050);game._update_enemies(.05,.04)
	check(ram["attack"].attack["ram_direction"]==1,"Ram locks its direction before launch")
	game.p["pos"]=Vector2(710,1050);ram["attack"].tick(2);ram["attack"].cancel();game._start_enemy_attack(ram,ram["attacks"][0]);ram["attack"].tick(float(ram["attack"].attack["windup"])+.001)
	game._update_enemies(.01,.008);check(game.p["hp"]<hp,"Ram deals its body hit only during the active lunge")
	game._reset_player(Vector2(950,1050));ram=fixture();ram["pos"]=Vector2(700,1050);game.enemies.assign([ram]);game.solids.append(Rect2(735,900,30,150))
	game._start_enemy_attack(ram,ram["attacks"][0]);ram["attack"].tick(float(ram["attack"].attack["windup"])+.001)
	for tick:int in 12:game._update_enemies(1.0/60,.8/60)
	check(ram.get("ram_hit_wall",false) and ram["attack"].phase=="recovery","Ram stops at a solid wall and plays recovery")
	game.queue_free();await process_frame
	print("Monster roster V36: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
