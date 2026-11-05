extends SceneTree

const Motion=preload("res://scripts/enemy_motion.gd")
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Data=preload("res://scripts/game_data.gd")
var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")

func check(value:bool,message:String) -> void:
	if not value:failures.append(message)

func available_gifts(game:Node) -> int:
	return game.drops.filter(func(drop:Dictionary)->bool:return drop.get("gift",false) and not drop.get("taken",false)).size()

func rune_drops(game:Node,kind:String,enemy:Dictionary) -> int:
	game.layout["hazard_room"]=kind
	game.rng.seed=58058
	var count:int=0
	for i in 800:
		game.drops.clear()
		game.corpses.clear()
		enemy["corpse_created"]=false
		game._enemy_defeated(enemy)
		if game.drops.any(func(drop:Dictionary)->bool:return drop["kind"]=="rune" and int(drop["value"])>=Data.RUNES.size()):count+=1
	return count

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.audio_enabled=false
	game.new_run("rogue",58058)
	var first:int=game.current_room
	game._claim_gift()
	game._enter_room(first)
	check(available_gifts(game)==0,"Ordinary reentry cannot duplicate a claimed weapon")
	var checkpoint:int=game.tower["maps"][1]["start_id"]
	game._enter_room(checkpoint)
	check(available_gifts(game)==0,"Entering a later checkpoint ordinarily does not grant a weapon")
	var combat:Dictionary=game.tower["rooms"].filter(func(candidate:Dictionary)->bool:return candidate["type"]=="combat" and not candidate.get("spring",false))[0]
	combat["practice_hazard"]="spike_islands"
	game._enter_room(combat["id"])
	check(game.enemies.size()>0,"Spike islands spawn enemies")
	for enemy:Dictionary in game.enemies:
		check(Motion.airborne(enemy) and enemy["roster_biome"]=="sky" and enemy["elite"],"Island spawns have flight AI and authored winged art")
	var sample:Dictionary=game.enemies[0].duplicate()
	var regular:int=rune_drops(game,"",sample)
	var spike:int=rune_drops(game,"spike_islands",sample)
	check(regular>12 and regular<48 and spike>105 and spike<185 and spike>regular*3,"Spike-island kills roll substantially more major runes")
	var chest:Dictionary={"kind":"chest","pos":game.p["pos"],"used":false}
	game.props.append(chest)
	combat["props"]=game.props
	game._open_chest(chest)
	check(chest["used"],"Opening consumes the chest before death")
	var elite:Dictionary=game.tower["rooms"].filter(func(candidate:Dictionary)->bool:return candidate["type"]=="elite")[0]
	elite["cleared"]=true
	elite["props"]=[{"kind":"chest","guaranteed_strong":true,"used":true}]
	game.revive_used=true
	game._death()
	game.life_event["kind"]="await_choice"
	game._choose_soul_rune("")
	game._respawn_from_soul()
	check(game.current_room==checkpoint and available_gifts(game)==1,"Death replenishes exactly one weapon at the latest checkpoint")
	check(not game.feather.is_empty() and game.feather["room"]==combat["id"],"Death still preserves the recovery feather")
	check(not chest["used"] and combat["drops"].is_empty() and not combat["initialized"],"Opened combat chest resets and stale loot is discarded")
	check(not elite.get("cleared",false) and elite["props"].is_empty(),"Elite clear reward will be earned again without duplicating the old chest")
	game._claim_gift()
	game._enter_room(checkpoint)
	check(available_gifts(game)==0,"Claiming the replenished weapon consumes it for the current life")
	game._enter_room(combat["id"])
	game._open_chest(chest)
	check(chest["used"] and not game.drops.is_empty(),"The refreshed chest grants fresh loot")
	game.doors.clear()
	game.platforms.assign([Rect2(250,500,160,12)])
	game.solids.assign([Rect2(510,510,120,96)])
	game.layout["spike_rects"]=[Rect2(510,490,120,20)]
	var walker:Dictionary=Roster.regular("underground",0)
	walker["pos"]=Vector2(505,440)
	var grounded:Vector2=game._fit_enemy_ground(walker)
	check(grounded.is_finite() and grounded.y==500 and grounded.x<410,"Ground actors use the safe support, never a spike top or the air")
	game.platforms.clear()
	check(not game._fit_enemy_ground(walker).is_finite(),"No valid support means no ground spawn")
	var wall_actor:Dictionary=preload("res://scripts/monster_roster_v55.gd").create("trunk",2,2)
	wall_actor["pos"]=Vector2(700,480)
	game.solids.assign([Rect2(580,300,96,250)])
	var attached:Vector2=game._enemy_spawn(wall_actor)
	check(attached.is_finite() and wall_actor.has("wall_spawn_face"),"Wall actor is attached to a solid vertical face")
	game.solids.clear()
	check(not game._enemy_spawn(wall_actor).is_finite(),"Wall actor does not spawn when no wall is present")
	var flyer:Dictionary=Roster.regular("trunk",2)
	flyer["pos"]=Vector2(700,480)
	check(game._enemy_spawn(flyer).is_finite(),"An aerial actor can spawn without a platform")
	game.platforms.assign([Rect2(600,550,200,12)])
	game.enemies.clear()
	walker.merge({"pos":Vector2(700,420),"vel":Vector2.ZERO,"face":-1.0,"attack":preload("res://scripts/attack_state.gd").new(),"uid":192023},true)
	game.enemies.append(walker)
	game.p["pos"]=Vector2(30,30)
	game.camera_pos=Vector2(1900,1200)
	game.view_rect=Rect2(1900,1200,100,100)
	var before:float=walker["pos"].y
	game._update_enemies(.05,.05)
	check(walker["pos"].y>before,"Unengaged ground actors continue falling")
	game.queue_free()
	await process_frame
	print("v58 respawn and islands: ",failures)
	quit(0 if failures.is_empty() else 1)
