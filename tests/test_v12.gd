extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Sanctuary=preload("res://scripts/sanctuary_room.gd")
const Bath=preload("res://scripts/bath_water.gd")
const Art=preload("res://scripts/sanctuary_art.gd")
const Items=preload("res://scripts/world_item_art.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Arms=preload("res://scripts/armament.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func target(at:Vector2,uid:int) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=uid;var en:Dictionary=Arms.enemy("walk",rng)
	en.merge({"uid":uid,"pos":at,"hp":99999.0,"max_hp":99999.0,"vel":Vector2.ZERO,"face":-1.0,"hurt":0.0,"stun":0.0,"cooldown":1000.0,"attack":Attack.new()},true);return en
func run() -> void:
	for spring in [false,true]:
		for mask in 16:
			var neighbors:Dictionary={}
			for i in 4:
				if mask&(1<<i):neighbors[["left","right","up","down"][i]]=i
			var fixture:Dictionary={"id":17,"coord":Vector2i.ZERO,"type":"combat" if spring else "merchant","spring":spring,"neighbors":neighbors}
			var result:Dictionary=Layout.generate(fixture,112)
			check(result["single_screen"] and result["size"]==Vector2(1500,1120),"Safe room retains full ordinary-room height")
			check(Layout.validate(result).is_empty(),"All passage combinations retain ordinary-jump access: "+str([spring,mask]))
			check(result["platforms"]==Layout.generate(fixture,9999)["platforms"],"Shop and bath geometry does not randomize")
	for map_index in 6:
		var stock:Array=Sanctuary.stock(map_index);check(stock.size()==6 and stock==Sanctuary.stock(map_index),"Each region has six curated stable goods")
		for i in stock.size():check(stock[i]["table"]==i/2 and Items.Icons.texture(Items.stock_icon(stock[i]))!=null,"Every table good uses its real weapon or rune illustration")
	for id in ["table","awning","sign","dummy","pool_back","pool_front","water","steam"]:check(Art.texture(id) is AtlasTexture,"Layered room art is exported: "+id)
	# Stable HUD updates reuse controls. Nine blur samples replace forty-nine.
	var ui=load("res://scripts/game_ui.gd").new();root.add_child(ui);await process_frame
	ui.update_quickbar({"0":2},Data.ITEMS);var first:int=ui.quickbar.get_child(0).get_instance_id();var rebuilds:int=ui.quickbar_rebuilds
	for i in 200:ui.update_quickbar({"0":2},Data.ITEMS)
	check(ui.quickbar_rebuilds==rebuilds and ui.quickbar.get_child(0).get_instance_id()==first,"Unchanged shortcut counts cause zero button rebuilds")
	ui.update_quickbar({"0":1},Data.ITEMS);check(ui.quickbar_rebuilds==rebuilds+1,"Real inventory change refreshes shortcut labels once")
	check(load("res://shaders/wildlife_blur.gdshader").code.count("texture(")==9,"Wildlife blur has a bounded nine-sample GPU cost")
	ui.queue_free();await process_frame
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame;scene.set_process(false);scene.set_physics_process(false)
	var saved:Dictionary=scene.meta.duplicate(true);scene.meta["rd_tuning"]={"merchant_chance":1.0,"fountain_chance":1.0};scene.new_run("rogue",12023);scene._close_panel();scene._process(.01)
	check(scene.atmosphere.middle.material==null and scene.atmosphere.near_layer.material==null,"Default reduced effects skip full-screen blur passes")
	var merchant:int=-1;var spring_room:int=-1;var combat:int=-1
	for room in scene.tower["rooms"]:
		if room["type"]=="merchant" and merchant<0:merchant=int(room["id"])
		if room.get("fountain",false) and spring_room<0:spring_room=int(room["id"])
		if room["type"]=="combat" and not room.get("spring",false):combat=int(room["id"])
	check(merchant>=0 and spring_room>=0,"Generated tower includes merchant and hot-spring fixtures")
	if merchant<0 or spring_room<0:scene.queue_free();await process_frame;quit(1);return
	scene._enter_room(merchant);scene.room_cooldown=0;scene._close_panel();scene.camera_zoom=2
	check(is_equal_approx(scene._view_zoom(),scene.camera_zoom),"Safe rooms use the same player scale as ordinary rooms")
	check(scene._room_size().y*scene._view_zoom()>=720,"Safe room is at least a display tall")
	check(scene.enemies.size()==1 and scene.enemies[0].get("training",false),"Merchant has one non-hostile immortal training target")
	scene.bag_weapons.assign([Data.secondary_attack(2)]);scene.secondary_index=0;scene.rune_slots.assign(["gale","","reach"]);scene.strong_slots.assign(["longblade","swiftblade","bloodblade"]);scene._sync_vitals();scene.p["energy"]=2;scene.p["hp"]=2
	var before_weapons:Array=scene.bag_weapons.duplicate(true);var before_runes:Array=scene.rune_slots.duplicate();var before_strong:Array=scene.strong_slots.duplicate();scene.run_coins=0
	scene._start_trial(0)
	check(not scene.ui.is_panel_open() and not scene.merchant_trial.is_empty() and scene.bag_weapons.size()==2 and scene.run_coins==0,"Taking a table weapon is free and returns immediately to play")
	check(scene.p["energy"]==scene.p["max_energy"] and scene.ui.trial_panel.visible,"Trial supplies energy and exposes buy/return controls")
	scene.p["pos"]=scene.room["stock"][0]["pos"]+Vector2(0,124);scene.room_cooldown=0
	check(not scene._world_confirm(),"Attacking while testing does not reopen the table menu")
	scene._set_action("up",true);check(not scene.ui.is_panel_open(),"Aiming upward during a trial cannot open the product menu");scene._set_action("up",false)
	scene._merchant_buy(0);check(not scene.room["stock"][0]["sold"] and not scene.merchant_trial.is_empty(),"Insufficient funds cannot buy or end the free trial")
	scene._return_trial(false)
	check(scene.bag_weapons==before_weapons and scene.rune_slots==before_runes and scene.strong_slots==before_strong and scene.p["energy"]==2 and scene.p["hp"]==2,"Returning trial restores exact gear, sockets and vital resources")
	scene._start_trial(5);check(scene.strong_slots!=before_strong,"A greater rune can be tried even when all three slots are occupied")
	scene._show_bag();check(scene.merchant_trial.is_empty() and scene.strong_slots==before_strong,"Opening inventory returns borrowed runes before showing owned items");scene._close_panel()
	scene.run_coins=100;scene._start_trial(1);var price:int=scene.room["stock"][1]["price"];scene._merchant_buy(1)
	check(scene.room["stock"][1]["sold"] and scene.run_coins==100-price and scene.bag_weapons.size()==before_weapons.size()+1,"Buying restores the loan then grants exactly one owned weapon")
	var paid:int=scene.run_coins;scene._merchant_buy(1);check(scene.run_coins==paid,"Sold table goods cannot be charged twice")
	# All eleven secondary types can actually hit the immortal training dummy.
	scene.camera_zoom=1.3;scene.camera_pos=scene._camera_target((scene._furniture_offset()+Vector2(1250,Sanctuary.FLOOR)));scene._process(.01)
	var dummy:Dictionary=scene.enemies[0]
	for i in Data.SECONDARY.size():
		scene._clear_keys();scene._reset_player((scene._furniture_offset()+Vector2(1240 if Data.SECONDARY[i]["kind"]=="throw" else 1140,Sanctuary.FLOOR)));scene.bag_weapons.assign([Data.secondary_attack(i)]);scene.secondary_index=0;scene.projectiles.clear();scene.effects.clear()
		var total:float=dummy["training_total"];scene._begin_secondary();scene.p_attack.tick(float(scene.p_attack.attack["windup"])+.001)
		if Data.SECONDARY[i]["kind"]=="sword":scene.p["pos"]=(scene._furniture_offset()+Vector2(1310,Sanctuary.FLOOR));scene._process_player_attack()
		else:
			for step in 240:scene._update_projectiles(.01);scene._update_hazards(.01)
		check(dummy["training_total"]>total,"Trial target can measure the actual secondary: "+str(i))
	check(dummy["hp"]==999999.0,"Training target takes measurable hits without dying")
	scene._start_trial(2);scene._enter_room(spring_room);check(scene.merchant_trial.is_empty(),"Crossing a passage returns all unsold trial goods")
	# Springs now remain inside hostile rooms and do not cut a room-sized bath.
	scene._close_panel();scene._clear_keys();var fountain:Dictionary={}
	for prop:Dictionary in scene.props:
		if prop["kind"]=="fountain":fountain=prop;break
	check(not fountain.is_empty() and scene.layout["pool"].size==Vector2.ZERO,"Combat fountain replaces the retired dedicated bath room")
	scene.p["pos"]=fountain["pos"];scene.p["hp"]=1;scene.p["energy"]=0;scene._update_props(1)
	check(scene.p["hp"]==2 and scene.p["energy"]==2,"Standing at the fountain heals and restores energy")
	scene.p["pos"]-=Vector2(0,100);scene.p["hp"]=1;scene._update_props(1);check(scene.p["hp"]==1,"Hovering far above the fountain does not heal")
	# Normal rooms never expose an outside strip even at the widest zoom preference.
	scene._enter_room(combat);scene.camera_zoom=.8;var view:Vector2=Vector2(1280,720)/scene._view_zoom();check(scene._room_size().x>=view.x and scene._room_size().y>=view.y,"Every room is at least one viewport")
	# Three strikes per target, at least 0.5 active seconds apart, across all primaries.
	scene.props.clear();scene.rune_slots.clear();scene.strong_slots.clear()
	for weapon in 3:
		scene._clear_keys();scene._reset_player(Vector2(700,1050));scene.weapon_index=weapon;scene.combo_index=0;var en:Dictionary=target(Vector2(750,1050),weapon+1);scene.enemies.assign([en]);scene._begin_primary({"dir":"right","charged":true});scene.p_attack.tick(float(scene.p_attack.attack["windup"]))
		var hits:Array[float]=[];var previous:float=en["hp"]
		for step in 181:
			scene._process_player_attack()
			if en["hp"]<previous:hits.append(scene.p_attack.elapsed);previous=en["hp"]
			scene.p_attack.tick(1.0/120)
		check(hits.size()==2,"Charged primary has exactly two half-second strikes over one second: "+str(weapon))
		if hits.size()==2:check(hits[1]-hits[0]>=.499,"Charged damage is never more frequent than once per half second")
	var clock=Attack.new();clock.begin({"windup":0,"active":1.5,"recovery":0});clock.tick(.49);check(clock.mark_timed_hit(8),"Late entry can take its first strike");clock.tick(.01);check(not clock.mark_timed_hit(8),"A half-second window boundary cannot double-hit a late entrant");clock.tick(.49);check(clock.mark_timed_hit(8),"Late target takes next strike only after its own half-second cooldown")
	scene._enter_room(merchant);scene._start_trial(0);scene.new_run("rogue",12024);check(scene.merchant_trial.is_empty() and scene.bag_weapons.is_empty(),"Restart cannot transfer a loan or previous run inventory")
	scene.meta=saved;scene._save_meta();scene.combat_feedback.clear();scene.queue_free();await process_frame
	print("v0.12: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
