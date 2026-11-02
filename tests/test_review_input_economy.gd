extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Arsenal=preload("res://scripts/arsenal_v24.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func key_event(code:int,shift:bool=false) -> InputEventKey:
	var key:=InputEventKey.new();key.physical_keycode=code;key.pressed=true;key.shift_pressed=shift;return key
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game)
	await process_frame
	game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",350171);game._close_panel();game._clear_keys();game.p_attack.cancel()
	var needle:Dictionary=Data.secondary_attack(Arsenal.index_of("needle"))
	var laser:Dictionary=Data.secondary_attack(Arsenal.index_of("piercing_laser"))
	# The same physical key reaches the configured gameplay action first.
	game.bag_items={"0":2};game.p["hp"]=1;game.weapon_index=1
	game._unhandled_input(key_event(KEY_1))
	check(game.weapon_index==1 and game.bag_items["0"]==2,"Bare1 preserves the only independent primary without consuming inventory")
	game._unhandled_input(key_event(KEY_3));check(game.weapon_index==1,"Bare3 cannot restore the removed heavy primary")
	game._unhandled_input(key_event(KEY_1,true))
	check(game.weapon_index==1 and game.bag_items["0"]==1 and game.p["hp"]==3,"Shift1 explicitly consumes slot1 without changing weapon or opening panel")
	game.Bindings.assign(game.key_bindings,"primary_2",KEY_4);game.bag_items["3"]=2
	game._unhandled_input(key_event(KEY_4));check(game.weapon_index==1 and game.bag_items["3"]==2,"A custom binding on4 is not intercepted by consumables")
	# Capped purchases keep the stock and coins, including while trial equipment is present.
	game.room["type"]="merchant";game.room["stock"]=[{"kind":"weapon","value":Arsenal.index_of("needle"),"price":30,"sold":false,"pos":game.p["pos"]}]
	game.run_coins=100;game.bag_weapons.assign([needle.duplicate(true)]);game.bag_weapons[0]["duplicate_bonus"]=8
	game._start_trial(0);game._merchant_buy(0)
	check(game.run_coins==100 and not game.room["stock"][0]["sold"] and game.bag_weapons.size()==1 and game.bag_weapons[0]["duplicate_bonus"]==8,"A capped trial purchase cannot charge or mark stock sold")
	game.bag_weapons[0]["duplicate_bonus"]=7;game._merchant_buy(0)
	check(game.run_coins==70 and game.room["stock"][0]["sold"] and game.bag_weapons[0]["duplicate_bonus"]==8,"Valid duplicate purchase upgrades exactly once and charges exactly30")
	game._merchant_buy(0);check(game.run_coins==70,"Sold stock cannot charge twice")
	game.mode="musou";game.bag_weapons.clear()
	for i in 16:game.bag_weapons.append(needle.duplicate(true))
	game.room["stock"][0]["sold"]=false;game._start_trial(0);game._merchant_buy(0)
	check(game.run_coins==70 and not game.room["stock"][0]["sold"] and game.bag_weapons.size()==16,"Full musou trial purchase cannot consume payment or stock")
	game.bag_weapons.resize(15);game._start_trial(0);game._merchant_buy(0)
	check(game.run_coins==40 and game.room["stock"][0]["sold"] and game.bag_weapons.size()==16,"A temporary sixteenth trial does not reject a valid permanent purchase")
	# Identical loadouts have identical cast timing and preserve all effects.
	game.room["type"]="start";game._close_panel();game._clear_keys();game.rune_slots.clear();game.strong_slots.clear();game.bag_weapons.assign([needle,laser]);game.p["hurt"]=0;game.p["energy"]=6;game.p_attack.cancel();game.secondary_index=0
	game._begin_secondary();var a:Dictionary=game.p_attack.attack.duplicate(true)
	game.p_attack.cancel();game.secondary_index=1;game._begin_secondary();var b:Dictionary=game.p_attack.attack.duplicate(true)
	check(a["windup"]==0 and b["windup"]==0 and is_equal_approx(a["active"]+a["recovery"],.60) and is_equal_approx(a["active"]+a["recovery"],b["active"]+b["recovery"]),"Musou base cycle is0.60s with zero windup regardless of selection")
	check(a["salvo"].size()==2 and b["salvo"].size()==2 and a["salvo"][0]["id"]==b["salvo"][0]["id"] and a["salvo"][1]["id"]==b["salvo"][1]["id"],"Both selected views fire the same complete loadout")
	check(game.p["energy"]==4,"Each whole salvo costs one energy")
	game.p_attack.cancel();game.bag_runes={"gale":1};game.rune_slots.assign(["gale"]);game.p["energy"]=6;game._begin_secondary()
	check(is_equal_approx(game._musou_cycle_seconds(),game.p_attack.attack["active"]+game.p_attack.attack["recovery"]),"Displayed salvo cycle tracks the actual rune-adjusted cast")
	# Up and attack share nearest-station selection, but attacking practice props remains combat.
	game.p_attack.cancel();game._close_panel();game._clear_keys();game.drops.clear();game.room_cooldown=0;game.p["pos"]=Vector2(500,500)
	game.props.assign([{"kind":"forge","pos":Vector2(604,500)},{"kind":"reforge","pos":Vector2(424,500)}])
	check(game._world_confirm() and game.prep_station=="reforge","Attack opens the nearest reforge instead of the first prop in the array")
	game._close_panel();game.prep_station="";game._interact(true)
	check(game.prep_station=="reforge","Up opens the same nearest station")
	game._close_panel();game.props.assign([{"kind":"forge","pos":Vector2(580,500)},{"kind":"dummy","pos":Vector2(510,500)}]);game.prep_station=""
	check(not game._world_confirm() and not game.ui.is_panel_open(),"Nearest dummy lets the attack through without opening a forge behind it")
	game.props.assign([{"kind":"aid","pos":Vector2(510,500)}]);game.p["hp"]=1
	check(game._world_confirm() and game.p["hp"]==game.p["max_hp"] and not game.ui.is_panel_open(),"Attack-confirm on aid heals directly without a menu")
	# Real touch stick events: diagonal travel is not an upward command, but deliberate Up and Down retain their meaning.
	var touch=preload("res://scripts/screen_touch_v29.gd").new();root.add_child(touch);touch.action_changed.connect(game._set_action);await process_frame
	game._close_panel();game._clear_keys();game.p_attack.cancel();game.props.clear();game.p["air_dash"]=false;game.p["grounded"]=true;game.p["dash_t"]=0;game.dash_chain_open=false;game.clock+=2
	var g:Dictionary=touch.geometry();touch.stick_finger=5;touch.drag(5,g["stick"]+Vector2(.8,-.8)*g["radius"])
	check(game._key("right") and not game._key("up"),"Diagonal upper-right touch travel does not accidentally hold Up")
	game._dash_pressed();check(game.p["dash_t"]>0,"Diagonal touch travel can start a horizontal dash")
	touch.drag(5,g["stick"]+Vector2(0,-1)*g["radius"]);check(game._key("up"),"Deliberate upward touch still emits Up for interaction/aim")
	touch.drag(5,g["stick"]+Vector2(0,1)*g["radius"]);game.p_attack.cancel();game.p["dash_t"]=0;game.clock+=2;game.dash_chain_open=false;game._dash_pressed()
	check(game.p["dash_t"]==0 and game.dash_chain_open,"Down+C arms the chain without horizontal movement")
	game.clock+=.1;game._dash_pressed();check(game.p_attack.attack.get("kind","")=="slam","Down+CC still starts the direct slam")
	touch.release_all();touch.queue_free();game.combat_feedback.clear();game.queue_free();await process_frame
	print("Review input/economy: %d failures"%failures.size());quit(0 if failures.is_empty() else 1)
