extends SceneTree

var failures:Array[String]=[]

func _initialize() -> void:
	call_deferred("run")

func check(value:bool,message:String) -> void:
	if not value: failures.append(message);push_error(message)

func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	scene.audio_enabled=false;root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	var original_meta:Dictionary=scene.meta.duplicate(true)
	scene.meta["runes"]["gale"]=1
	scene.practice_mode=true
	scene.new_run("rogue",74123)
	check(scene.tower["maps"].size()==6,"Six sequential maps")
	check(scene.bag_weapons.is_empty(),"No duplicate pre-gift weapon")
	var gifts:int=0
	for drop in scene.drops: if drop["kind"]=="weapon":gifts+=1
	check(gifts==1,"Exactly one random gift in1-1")
	scene._give_drop("weapon",0)
	check(scene.bag_weapons.size()==1,"Weapon picked into bag")
	scene.clock=10.0
	scene._dash_pressed()
	check(float(scene.p["dash_t"])>0,"First C moves immediately")
	scene.clock=10.49
	scene._dash_pressed()
	check(scene.p_attack.attack.get("kind","")=="pierce","Second C within500ms starts piercing")
	check(scene.p_attack.phase=="windup","Piercing has windup")
	scene.p_attack.tick(.04)
	check(scene.p_attack.phase=="active","Piercing has active phase")
	check(float(scene.p["invul"])>0,"Piercing grants invulnerability")
	scene.p_attack.tick(.25)
	check(scene.p_attack.phase=="recovery","Piercing has recovery")
	scene.p_attack.cancel()
	scene.p["dash_t"]=0;scene.p["air_dash"]=false
	scene.clock=20;scene.dash_chain_open=false;scene._dash_pressed()
	scene.clock=20.51;scene.p["grounded"]=true;scene._dash_pressed()
	check(scene.p_attack.attack.get("kind","")!="pierce" or not scene.p_attack.is_busy(),"Late second C not piercing")
	scene._clear_keys();scene.p["dash_t"]=0;scene.solids.assign([Rect2(0,0,96,1120)]);scene.p["pos"]=Vector2(113,500);scene.p["vel"]=Vector2(0,160);scene.p["grounded"]=false
	scene.p["jumps"]=2;scene.p["air_dash"]=true;scene.p["wall_lock"]=0
	scene._update_player(.016)
	check(scene.p["wall"]==-1,"Wall attaches")
	check(scene.p["jumps"]==0 and not scene.p["air_dash"],"Wall restores landed movement rights")
	check(scene.p["vel"].y==0 and scene.p["wall_hold_left"]>0,"New wall contact freezes for one second before sliding")
	var first_start:int=scene.current_room
	var gift_before:int=scene.drops.size()
	scene._enter_room(first_start,"center")
	check(scene.drops.size()==gift_before,"Room reentry does not duplicate gift")
	var geometry:Array=scene.platforms.duplicate()
	scene._enter_room(first_start,"center")
	check(scene.platforms==geometry,"Room geometry remains identical on reentry")
	check(scene.layout["archetype"]!="","Seeded room has a layout archetype")
	check(scene.layout.has("maze_grid") and scene.platforms.size()<200,"Maze platforms use merged support geometry")
	for at in scene.layout["enemy_spawns"]:
		check(scene._support_y(at,at+Vector2(0,1),1)<INF,"Enemy spawn rests on real platform")
	# Swept feet pick the earliest surface even if floor appears first in array.
	var collision_platforms:Array[Rect2]=[Rect2(0,1050,1500,70),Rect2(200,400,250,20),Rect2(200,500,250,20)]
	scene.platforms=collision_platforms
	check(scene._support_y(Vector2(300,390),Vector2(300,550),800)==400,"Fast fall lands on first crossed platform")
	check(scene._support_y(Vector2(300,500),Vector2(300,390),-500)==INF,"One-way platform does not catch ascent")
	scene._clear_keys();scene.p["pos"]=Vector2(300,400);scene.p["vel"]=Vector2.ZERO;scene.p["grounded"]=true;scene.p["dash_t"]=0
	scene.keys["down"]=true;scene.jump_request=true
	scene._update_player(.016)
	check(scene.p["pos"].y>400 and not scene.p["grounded"],"Down+jump passes through support instead of landing on it again")
	scene._clear_keys();scene.drop_through_timer=0;scene._enter_room(first_start,"center")
	for i in 4:await process_frame
	var bg_rebuilds:int=scene.backdrop.rebuilds
	var platform_rebuilds:int=scene.terrain.rebuilds
	for i in 5:await process_frame
	check(scene.backdrop.rebuilds==bg_rebuilds and scene.terrain.rebuilds==platform_rebuilds,"Static background/platform commands stay cached while actors redraw")
	# Loot must be visibly separated and preserve currency totals.
	scene.drops.clear()
	scene._drop("rune",Vector2(480,1030),0);scene._drop("weapon",Vector2(480,1030),0)
	check(scene.drops[0]["pos"].distance_to(scene.drops[1]["pos"])>=30,"Different loot types do not spawn coincident")
	scene._drop("coin",Vector2(480,1030),3);scene._drop("coin",Vector2(480,1030),4)
	var pile_count:int=0;var total_gold:int=0
	for d in scene.drops:
		if d["kind"]=="coin":pile_count+=1;total_gold+=int(d["value"])
	check(pile_count==7 and total_gold==7,"Nearby gold stays in seven separate physical coins")
	var combat_id:int=-1
	for room in scene.tower["rooms"]:
		if room["type"]=="combat":combat_id=room["id"];break
	scene._enter_room(combat_id)
	var en:Dictionary=scene.enemies[0]
	var one_enemy:Array[Dictionary]=[en]
	scene.enemies=one_enemy
	en["pos"]=Vector2(550,1050);en["hp"]=20;en["max_hp"]=20;en["attack"].cancel()
	scene.p["pos"]=Vector2(500,1050);scene.p["face"]=1;scene.p["energy"]=0
	scene.weapon_index=1;scene.p_attack.cancel();scene._begin_primary({"dir":"right","charged":false,"dash_charge":false})
	scene._process_player_attack()
	check(scene.p_attack.is_active() and en["hp"]==17,"Primary damage starts immediately with no windup")
	scene.p_attack.tick(float(scene.p_attack.attack["windup"])+.001);scene._process_player_attack()
	check(en["hp"]==17,"Damage occurs in active phase")
	scene._process_player_attack()
	check(en["hp"]==17,"One hit per attack per target")
	check(scene.p["energy"]>0,"Main attack restores energy")
	scene.p_attack.cancel();scene._begin_primary({"dir":"right","charged":false,"dash_charge":false});scene.p_attack.tick(float(scene.p_attack.attack["windup"])+.001)
	var test_projectiles:Array[Dictionary]=[{"pos":Vector2(535,1025),"vel":Vector2.ZERO,"from_player":false,"damage":1.0,"life":1.0,"color":Color.WHITE,"kind":"shot","radius":5.0,"pierce":false,"hits":{},"bounces":0}]
	scene.projectiles=test_projectiles
	scene._update_projectiles(0)
	check(scene.projectiles.is_empty(),"Active main attack blocks projectile")
	var held_before:int=int(scene.bag_runes.get("gale",0))
	scene._ui_action("rune_take","gale")
	check(int(scene.bag_runes.get("gale",0))==held_before,"Cannot take old runes outside prep")
	scene._close_panel();scene._enter_room(first_start)
	scene._ui_action("rune_take","gale");scene._close_panel()
	check(int(scene.bag_runes.get("gale",0))>0,"Can take old runes in prep")
	scene.bag_runes["gale"]=20
	for i in 20:scene._ui_action("rune_equip","gale")
	check(scene.rune_slots.size()==16,"Rune board capped at16")
	scene._close_panel();scene._ui_action("hub",null)
	check(scene.tower.is_empty() and scene.room.is_empty(),"Hub return does not leave invalid room data")
	scene._show_map()
	scene.meta=original_meta;scene._save_meta()
	scene.queue_free()
	await process_frame
	if failures.is_empty():print("Game integration: all tests passed")
	else: print("Game integration failures: ",failures)
	quit(0 if failures.is_empty() else 1)
