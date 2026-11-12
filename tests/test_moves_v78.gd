extends SceneTree

var failures:Array[String]=[]

func _initialize() -> void:
	call_deferred("run")

func check(ok:bool,message:String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.audio_enabled=false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.new_run("rogue",78)
	game._close_panel()
	game._reset_player(Vector2(550,700))
	game.enemies.clear()
	game.props.clear()
	game.solids.assign([Rect2(410,280,300,30),Rect2(0,700,1200,80)])
	game.platforms.assign([Rect2(0,700,1200,8)])
	game.p["energy"]=game.p["max_energy"]-1
	check(game.Bindings.action_for(game.key_bindings,KEY_S)=="ultimate","S is the default full-energy action")
	game._set_action("ultimate",true)
	game._set_action("ultimate",false)
	check(not game.p_attack.is_busy(),"Partial energy cannot cast")
	var near:Dictionary={"pos":Vector2(660,700),"hp":100.0,"vel":Vector2.ZERO}
	var far:Dictionary={"pos":Vector2(1100,700),"hp":100.0,"vel":Vector2.ZERO}
	game.enemies.assign([near,far])
	game.p["energy"]=game.p["max_energy"]
	game._set_action("ultimate",true)
	game._set_action("ultimate",false)
	check(game.p["energy"]==0 and near["hp"]==88.0 and far["hp"]==100.0,"Full energy buys one radial hit on enemies in range")
	check(near["push_velocity"].x>1000 and game.effects.any(func(e:Dictionary)->bool:return e.get("combat_fx","")=="feather_charge"),"Ultimate hits outward and uses the dedicated atlas")
	game.p_attack.cancel()
	game.enemies.clear()
	game.p["pos"]=Vector2(550,500)
	game.p["grounded"]=false
	game.p["jumps"]=1
	game.practice_mode=true
	game._set_action("up",true)
	game._set_action("jump",true)
	game._step_player(1.0/120.0)
	check(not game.p.has("lift_charge") and game.p["jumps"]==2,"An airborne chord does not charge and preserves the ordinary double jump")
	game._set_action("jump",false)
	game._set_action("up",false)
	game._reset_player(Vector2(550,700))
	game._set_action("up",true)
	game._set_action("jump",true)
	for i in 30:game._step_player(1.0/120.0)
	game._set_action("jump",false)
	check(not game.p.get("lift_flying",false),"Early release does not launch")
	game._set_action("jump",true)
	for i in 122:game._step_player(1.0/120.0)
	check(is_equal_approx(game.p["pos"].y,700.0) and is_equal_approx(game.p["lift_charge"],game._lift_threshold()),"Held chord charges at the floor")
	game._set_action("jump",false)
	game._set_action("up",false)
	check(game.p.get("lift_flying",false),"Releasing the original Up input does not cancel flight")
	for i in 60:
		if not game.p.get("lift_flying",false):break
		game._step_player(1.0/120.0)
	check(not game.p.get("lift_flying",false) and is_equal_approx(game.p["pos"].x,550.0),"Uninterrupted lift continues vertically to the ceiling")
	check(game.p["pos"].y>=352.0,"Swept lift never crosses the ceiling")
	check(game.effects.any(func(e:Dictionary)->bool:return e.get("combat_fx","")=="vertical_launch"),"Lift launches the authored exhaust")
	for action:String in ["left","right","jump","dash","attack"]:
		game._clear_keys()
		game._reset_player(Vector2(550,700))
		game.keys["up"]=true
		game.p["lift_charge"]=game._lift_threshold()
		game._release_lift()
		check(game.p.get("lift_flying",false),"Fixture reaches the launch state")
		game._set_action(action,true)
		check(not game.p.get("lift_flying",false) and game.keys[action],"Fresh "+action+" cancels flight and is accepted")
		if action=="attack":check(game.p_attack.is_active(),"The cancel press immediately executes the attack")
		if action=="dash":check(game.p["dash_t"]>0,"The cancel press immediately starts the dash")
		game._set_action(action,false)
	var speed:float=game._movement_factor()
	var charge:float=game._charge_threshold()
	var attack:Dictionary=game._primary_definition({"dir":"right","charged":false})
	game.rune_slots.assign(["rapid_slash","quick_charge","fleet_foot"])
	check(game._movement_factor()>speed and game._charge_threshold()<charge and game._lift_threshold()<1.0,"Small runes affect movement and both charge actions")
	check(game._primary_definition({"dir":"right","charged":false})["active"]<attack["active"],"Attack-speed rune changes ordinary strike timing")
	game.queue_free()
	await process_frame
	print("v78 checks: ",failures)
	quit(0 if failures.is_empty() else 1)
