extends SceneTree
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func ram_fixture(elite:bool,attack_speed:float) -> Dictionary:
	var en:Dictionary=Roster.elite(1) if elite else Roster.regular("underground",4)
	en.merge({"uid":9001,"pos":Vector2(750,1050),"vel":Vector2.ZERO,"face":1.0,"hp":100.0,"max_hp":100.0,"hurt":0.0,"stun":0.0,"cooldown":0.0,"attack_speed":attack_speed,"attack":Attack.new()},true)
	return en
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",36136);game._close_panel()
	game.layout={"size":Vector2(1800,1120),"floor_y":1050.0};game.solids.assign([Rect2(0,1050,1800,70)]);game.platforms.assign([Rect2(0,1050,1800,8)])
	game.camera_pos=Vector2(250,550);game.freeze_timer=0;game.life_event={};game.p_attack.cancel()
	var cases:int=0
	for elite:bool in [false,true]:
		for speed:float in [.4,.8,1.5]:
			for timing:float in [1.0,1.6]:
				for attack_speed:float in [1.0,1.4]:
					for direction:float in [-1.0,1.0]:
						game.world_speed=speed;game.phase_multiplier=timing
						var en:Dictionary=ram_fixture(elite,attack_speed);game.enemies.assign([en])
						var definition:Dictionary=en["attacks"][0]
						var reach:float=game._ram_trigger_distance(en,definition)
						var label:String="elite=%s speed=%.1f timing=%.1f attack_speed=%.1f dir=%.0f reach=%.1f"%[elite,speed,timing,attack_speed,direction,reach]
						game._reset_player(en["pos"]+Vector2(direction*(reach+1),0));game._try_enemy_attack(en,game.p["pos"]-en["pos"])
						check(not en["attack"].is_busy() or not en["attack"].attack.get("ram",false),"No unreachable ram starts outside the real stride: "+label)
						en["attack"].cancel();en["cooldown"]=0;en["attack_cursor"]=0
						game._reset_player(en["pos"]+Vector2(direction*(reach-1),0));var hp:float=game.p["hp"]
						game._update_enemies(1.0/120,speed/120)
						check(en["attack"].phase=="windup","Actual AI starts at the reachable boundary: "+label)
						var cycle:float=float(en["attack"].attack["windup"])+float(en["attack"].attack["active"])
						for tick:int in ceili(cycle*120)+4:
							var before:String=en["attack"].phase
							game._update_enemies(1.0/120,speed/120)
							if before=="windup" and en["attack"].phase=="windup":check(game.p["hp"]==hp,"Windup remains harmless at the trigger edge: "+label)
							if en["attack"].phase=="recovery":break
						check(game.p["hp"]<hp,"Complete windup and lunge hit a stationary boundary target: "+label)
						check(en["attack"].attack["ram_direction"]==direction,"The reachable ram retains locked direction: "+label)
						cases+=1
	game.queue_free();await process_frame
	print("Ram reach V36: ",cases," full attacks; ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
