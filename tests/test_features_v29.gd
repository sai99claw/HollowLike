extends SceneTree
const Touch=preload("res://scripts/screen_touch_v29.gd")
const RandomRunes=preload("res://scripts/rune_random_v29.gd")
const Cloaks=preload("res://scripts/cloak_art_v29.gd")
const NewArt=preload("res://scripts/adventure_art_v29.gd")
var failures:Array[String]=[]
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame
	game.set_process(false);game.set_physics_process(false);game.home_sleeping=false
	for sound:String in ["explosion","ground_slam","dash_wind","double_dash_wind","attack_whoosh"]:
		check(game.sounds.has(sound) and game.sounds[sound].get_length()>.15,"Original combat sound is packaged: "+sound)
	game.effects.clear();game._hit_flash(Vector2.ZERO,2,Color.WHITE)
	check(game.effects.size()==1 and game.effects[0].has("combat_fx"),"Hit feedback retains atlas and creates no procedural ring or circular glow")
	var touch:Control=game.ui.touch_controls;game.ui.close_panel();game.ui.set_touch_visible(true)
	var g:Dictionary=touch.geometry()
	check(g["sub"].x<g["attack"].x and g["sub"].y==g["attack"].y,"Touch top row is secondary then primary")
	check(g["dash"].x<g["jump"].x and g["dash"].y==g["jump"].y and g["dash"].y>g["sub"].y,"Touch bottom row is dash then jump")
	check(g["heal"].y<g["sub"].y and g["stick"].x<300,"Heal upper-right and joystick lower-left")
	touch.press(7,g["stick"]);touch.drag(7,g["stick"]+Vector2(g["radius"],0))
	touch.press(8,g["jump"]);touch.press(9,g["attack"])
	check(touch.held.get("right",false) and touch.held.get("jump",false) and touch.held.get("attack",false),"Three fingers hold movement, jump and attack independently")
	touch.release(8);check(not touch.held.get("jump",false) and touch.held.get("right",false),"Releasing one finger preserves other inputs")
	touch.visible=false;check(not touch.held.values().has(true),"Opening menu releases all virtual controls")
	game.touch_enabled=true;game._save_settings();check(game.meta["settings"].get("touch_enabled",false),"Touch preference persists")
	game.new_run("rogue",2901);game._close_panel();game.p["grounded"]=true;game.p["hurt"]=0;game.p["heavy_land_left"]=0;game.phase_multiplier=1.6
	for id:String in game.Arsenal.IDS:
		var weapon:Dictionary=game.Data.secondary_attack(game.Arsenal.index_of(id));check(float(weapon["windup"])==0,"All nine definitions have zero startup")
		game.bag_weapons.clear();game.bag_weapons.append(weapon);game.p_attack.cancel();game.p["energy"]=6;game.projectiles.clear();game.effects.clear();game._begin_secondary()
		check(game.p_attack.is_active() and (id=="chain_staff" or not game.projectiles.is_empty() or not game.effects.is_empty()),"Grounded "+id+" fires in the same call, including slow-observation mode")
	game.p_attack.cancel();game.mode="musou";game.bag_weapons.clear()
	for id:String in game.Arsenal.IDS:game.bag_weapons.append(game.Data.secondary_attack(game.Arsenal.index_of(id)))
	game.projectiles.clear();game.p["energy"]=6;game._begin_secondary()
	check(game.p_attack.is_active() and game.projectiles.size()>=7 and game.p["energy"]==5,"Musou salvo fires immediately for one energy")
	game.p_attack.cancel();game.room_cooldown=0
	check(game.props.any(func(p:Dictionary)->bool:return p["kind"]=="gift_pedestal"),"Starting gift has a dedicated pedestal")
	var wardrobe:Dictionary={}
	for prop:Dictionary in game.props:
		if prop["kind"]=="wardrobe":wardrobe=prop
	check(not wardrobe.is_empty(),"Preparation room includes cloak station")
	game.p["pos"]=wardrobe["pos"];game._interact();await process_frame
	check(game.ui.station_page=="wardrobe","Up interaction opens cloak station")
	var old_coins:int=int(game.meta["coins"])
	for i in 5:
		game._buy_skin(i);await process_frame
		check(game.meta["skin"]==i and int(game.meta["coins"])==old_coins and game.SKINS[i]["color"]==Color.WHITE,"Cloak selection changes cosmetic only, with no cost or body recolor")
		check(Cloaks.texture(i)!=null and Cloaks.atlas(i)!=null,"Cloak art and frame metadata are packaged")
	game._close_panel();game.meta["skin"]=0
	var rng:=RandomNumberGenerator.new();rng.seed=29
	var bag:Dictionary={"gale":2,"reach":1};var stash:Dictionary={"guard":30}
	var result:Dictionary=RandomRunes.choose(bag,stash,false,rng)
	check(result["small"].size()==3 and result["take"].is_empty(),"Away from preparation room random loadout cannot take home stock")
	result=RandomRunes.choose(bag,stash,true,rng)
	check(result["small"].size()==16 and int(result["take"].get("guard",0))>=13,"At home loadout caps16 and requests only actual required stash copies")
	game.bag_runes=bag.duplicate();game.meta["runes"]=stash.duplicate();game._randomize_rune_loadout()
	for id:String in game.rune_slots:check(game.rune_slots.count(id)<=int(game.bag_runes.get(id,0)),"Random loadout never equips unowned copies")
	game._show_equipment(3);await process_frame;await process_frame
	game.ui.equipment_navigation.navigate(game.ui,"down")
	check(root.gui_get_focus_owner().name=="RandomRuneLoadout","First Down from E rune tab selects random auto-equip")
	game.ui.equipment_navigation.navigate(game.ui,"down");game.ui.equipment_navigation.navigate(game.ui,"up")
	check(root.gui_get_focus_owner().name=="RandomRuneLoadout","Up from large rune board returns to random loadout")
	check(NewArt.feather_texture()!=null and NewArt.halo_texture()!=null,"New feather sprite and white radial halo available")
	var wind:Dictionary=NewArt.info("res://assets/v30/effects/wing-puff.json")
	check(wind["frames"].size()==4 and NewArt.image("res://assets/v30/effects/wing-puff.png")!=null,"Double jump has a real four-frame downward wind texture")
	game.feather={"room":game.current_room,"pos":game.p["pos"]};game._process(.01)
	check(game.combat_feedback.cache_motes.initial_velocity_max<=12 and game.combat_feedback.cache_motes.gravity.y<=2,"Death feathers fall gently with restrained gravity")
	game.combat_feedback.clear();game.queue_free();await process_frame
	print("v29 features: ","passed" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
