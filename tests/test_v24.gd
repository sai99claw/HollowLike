extends SceneTree
const Arsenal=preload("res://scripts/arsenal_v24.gd")
const Data=preload("res://scripts/game_data.gd")
const Tower=preload("res://scripts/tower.gd")
const Edge=preload("res://scripts/edge_decor_v23.gd")
const Terrain=preload("res://scripts/terrain_art_v24.gd")
const WeaponArt=preload("res://scripts/weapon_art_v24.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func run() -> void:
	var bag:Array=[]
	for id:String in Arsenal.IDS:
		check(Arsenal.index_of(id)>=0,"Every declared weapon exists: "+id)
		check(WeaponArt.texture(id)!=null and WeaponArt.texture(id,true)!=null,"Weapon and projectile art exported: "+id)
	var needle:Dictionary=Data.secondary_attack(0)
	for i in 14:Arsenal.acquire(bag,needle,"rogue")
	check(bag.size()==1 and bag[0]["duplicate_bonus"]==8,"Rogue duplicate pickups cap at +8 and do not create duplicate inventory entries")
	bag.clear()
	for i in 20:Arsenal.acquire(bag,needle,"musou")
	check(bag.size()==16,"Musou accepts distinct instances up to16")
	for seed_value in 40:
		var tower:Dictionary=Tower.generate(seed_value)
		check(Tower.validate(tower).is_empty(),"Elite classification preserves tower topology")
		var combat:Array=tower["rooms"].filter(func(room:Dictionary)->bool:return room["type"] in ["combat","elite"] and not room.get("spring",false))
		for first in range(0,combat.size()-4,5):
			var count:int=0
			for i in range(first,first+5):
				if combat[i]["type"]=="elite":count+=1
			check(count==1,"Exactly one elite room per complete five combat rooms")
	for biome:String in ["sky","trunk","underground"]:
		var definition:Dictionary=Terrain.data(biome)
		check(definition.get("middle",[]).size()==2,"Two complete midground objects per biome")
		for count in range(1,5):
			var platform:Dictionary=definition["platforms"][str(count)]
			check(platform["source_pixels_per_world"]==2 and Terrain.texture(platform["path"])!=null,"Platform fixed2px/world and native artwork")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",240024)
	game._close_panel();game.bag_weapons.clear();game.meta["blueprints"]=[];game._acquire_weapon(needle)
	for i in 8:game._acquire_weapon(needle)
	check(game.meta["blueprints"].has("needle") and game._secondary()["count"]==9,"First acquisition unlocks blueprint; duplicate bonus affects actual attack")
	game._show_equipment(0);check(game.ui.is_panel_open() and game.equipment_page==0,"Equipment opens main weapon page")
	game._set_action("left",true);check(game.equipment_page==1,"Left from main opens secondary page")
	game._set_action("left",true);check(game.equipment_page==2,"Second left opens consumables")
	game._set_action("left",true);check(game.equipment_page==3,"Third left opens rune board")
	game._close_panel();game.run_coins=50;var size:int=game.bag_weapons.size()
	check(not game._craft_weapon("homing_missile") and game.run_coins==50,"Locked blueprints cannot consume coins")
	game.bag_weapons.clear();check(game._craft_weapon("needle") and game.run_coins==20 and game.bag_weapons.size()==1,"Unlocked blueprint crafting spends exactly30")
	game.meta["runes"]={};game.bag_runes={"gale":3};game.rune_slots.assign(["gale","gale","gale"]);game.strong_slots.clear();game.reforge_selection.assign(["gale","gale","gale"])
	check(game._reforge_runes(),"Three carried runes can be reforged")
	check(game.bag_runes.size()==1 and not game.bag_runes.has("gale") and not game.rune_slots.has("gale"),"Reforge atomically consumes3 equipped materials and grants one different rune")
	game.injured=true;game.p["hp"]=1;game.p["energy"]=0;game._first_aid()
	check(not game.injured and game.p["hp"]==game.p["max_hp"] and game.p["energy"]==game.p["max_energy"] and not game.ui.is_panel_open(),"Aid immediately heals without opening panel")
	game.rune_slots.assign(["swarm","swarm","","swarm"]);game.strong_slots.clear()
	check(game._rune_effect("orbit_bee")==4,"Three bee runes plus one connection summon four bees")
	game._clear_keys();game.p_attack.cancel();game.enemies.clear();game.props.clear();game.hazards.clear();game.projectiles.clear();game.bag_weapons.clear();game.mode="musou"
	for i in 16:game._acquire_weapon(needle)
	game.p["energy"]=6;game._begin_secondary();game.p_attack.tick(1.0);game._process_player_attack()
	# Start attack directly through its active callback to test the saved salvo snapshot.
	if game.projectiles.is_empty():game._player_active_started()
	check(game.projectiles.size()==16 and game.p["energy"]==5,"One energy triggers all sixteen musou weapons simultaneously")
	game.p_attack.cancel();game.projectiles.clear();game.mode="rogue";game.bag_weapons.clear();game._acquire_weapon(Data.secondary_attack(Arsenal.index_of("homing_missile")))
	game._emit_weapon(Vector2(400,400),Vector2.RIGHT,game._secondary(),true)
	check(game.projectiles.size()==1 and game.projectiles[0]["homing"] and is_equal_approx(float(game.projectiles[0]["radius"]),game.ProjectileReadability.BASE_RADIUS),"Homing projectile uses one-fifth player baseline and dedicated behavior")
	game.projectiles.clear();game._emit_weapon(Vector2(400,400),Vector2.RIGHT,Data.secondary_attack(Arsenal.index_of("trap_pod")),true)
	check(game.projectiles.size()==1 and game.projectiles[0].get("trap_carrier",false),"Trap weapon actually throws an arming carrier")
	game.hazards.clear();game.projectiles.clear();game.solids.assign([Rect2(0,1050,2000,70)]);game.platforms.assign([Rect2(0,1050,2000,70)]);game.layout={"size":Vector2(2000,1120),"floor_y":1050.0}
	var trap_def:Dictionary=Data.secondary_attack(Arsenal.index_of("trap_pod"));trap_def["from_player"]=true;trap_def["hazard_visual_id"]="moss_thorns";trap_def["group"]="biological"
	game._settle_trap({"pos":Vector2(700,1040),"radius":16,"definition":trap_def,"from_player":true})
	check(game.hazards.size()==1 and not preload("res://scripts/trap_visual_v22.gd").armed(game.hazards[0]),"Player trap starts with authored arming animation")
	if not game.hazards.is_empty():
		game._update_hazards(.7);check(preload("res://scripts/trap_visual_v22.gd").armed(game.hazards[0]),"Player trap becomes damaging only after arming completes")
	game.hazards.clear();game._projectile_explosion({"pos":Vector2(700,1040),"ground_fire":true,"fire_size":140,"damage":2.0,"from_player":true,"color":Color.ORANGE})
	check(game.hazards.size()==1 and game.hazards[0].get("fire",false) and is_equal_approx(game.hazards[0]["pos"].y,1050),"Fire flask places a persistent damaging patch on actual ground")
	# Wall hold is physics-owned and expires without restarting while contact continues.
	game._clear_keys();game.p_attack.cancel();game.props.clear();game.enemies.clear();game.hazards.clear();game.projectiles.clear();game.solids.assign([Rect2(800,0,96,1800)]);game.platforms.clear();game.layout={"size":Vector2(2000,1800),"floor_y":1700.0};game._reset_player(Vector2(783,600));game.p["grounded"]=false;game.p["vel"]=Vector2(0,100);game.keys["right"]=true
	game._step_player(1.0/120);var held_y:float=game.p["pos"].y
	check(game.p["wall"]==1 and game.p["wall_hold_left"]>.99,"New wall contact starts one second hold")
	for i in 108:game._step_player(1.0/120)
	check(absf(game.p["pos"].y-held_y)<.05,"Wall contact stays fixed during first0.9seconds")
	for i in 60:game._step_player(1.0/120)
	check(game.p["pos"].y>held_y+10 and absf(game.p["vel"].y-36)<.01,"After hold expires physical slide resumes at36px/s")
	# Verify actual encounter instantiation and clear rewards for every stage.
	game.new_run("rogue",240024)
	for stage:Dictionary in game.tower["maps"]:
		game._enter_room(int(stage["boss_id"]))
		check(game.enemies.filter(func(en:Dictionary)->bool:return en.get("elite",false)).size()==3,"Boss room contains exactly3elite guards")
		check(game.enemies.filter(func(en:Dictionary)->bool:return en["model"]==4).size()==1,"Boss room also contains its own boss")
		var boss:Dictionary=game.enemies.filter(func(en:Dictionary)->bool:return en["model"]==4)[0];boss["hp"]=0;game._enemy_defeated(boss)
		check(not game.room["cleared"],"Boss death alone does not unlock side exit while guards remain")
		for en:Dictionary in game.enemies:
			if en["hp"]>0:en["hp"]=0;game._enemy_defeated(en)
		check(game.room["cleared"],"Defeating all boss room enemies unlocks next stage")
	var elite:Array=game.tower["rooms"].filter(func(rm:Dictionary)->bool:return rm["type"]=="elite")
	if not elite.is_empty():
		game._enter_room(elite[0]["id"])
		check(not game.enemies.is_empty() and game.enemies.all(func(en:Dictionary)->bool:return en.get("elite",false)),"Elite room spawns exclusively elite enemies")
		for en:Dictionary in game.enemies:en["hp"]=0;game._enemy_defeated(en)
		var chests:Array=game.props.filter(func(prop:Dictionary)->bool:return prop.get("guaranteed_strong",false))
		check(chests.size()==1,"Elite clear creates exactly one guaranteed-strong-rune chest")
		if not chests.is_empty():
			game.drops.clear();game._open_chest(chests[0]);check(game.drops.any(func(drop:Dictionary)->bool:return drop["kind"]=="rune" and int(drop["value"])>=Data.RUNES.size()),"Elite chest actually drops a large rune")
	game.queue_free();await process_frame
	print("v24 behavior/art checks: ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
