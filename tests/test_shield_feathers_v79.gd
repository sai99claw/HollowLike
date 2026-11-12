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
	game.new_run("rogue",79)
	game._close_panel()
	game._reset_player(Vector2(550,700))
	game.enemies.clear()
	game.props.clear()
	check(game.p["shield_cells"]==5 and game.p["max_shield"]==5,"The player starts with five shield pips")
	check(game._hurt_player(3,Vector2.ZERO) and game.p["hp"]==5 and game.p["shield_cells"]==2,"Shield absorbs incoming damage before health")
	game._update_shield(5.99)
	check(game.p["shield_cells"]==2,"Shield stays depleted until six seconds without damage")
	game._update_shield(.01)
	check(game.p["shield_cells"]==3,"First shield pip returns at six seconds")
	game._update_shield(1.0)
	check(game.p["shield_cells"]==4,"Shield regenerates one pip per subsequent second")
	game.p["invul"]=0
	check(game._hurt_player(5,Vector2.ZERO) and game.p["hp"]==4 and game.p["shield_cells"]==0 and game.shake>=26.0,"Shield break shakes hard and overflow reaches health")
	game._update_shield(5.9)
	check(game.p["shield_cells"]==0,"A new hit restarts the full quiet timer")
	game._update_shield(.1)
	game._update_hud()
	check(game.ui.shield_cells.value==1 and "護盾回復" in game.ui.timed_effects_label.text,"HUD shows shield pips and the regeneration timer")

	game.strong_slots.assign(["single_pierce","far_feather","shield_slot"])
	game._reset_player(Vector2(550,700))
	check(game.p["max_shield"]==6 and game.p["shield_cells"]==6,"Shield rune adds a sixth pip")
	game.p["energy"]=0
	game._set_action("dash",true)
	game._set_action("dash",false)
	check(game.p["dash_t"]>0 and not game.p_attack.is_busy() and game.p["energy"]==0,"Single C works at zero energy even with the pierce rune")
	check(not game.combat_feedback.impulses.is_empty(),"Single C emits the second-jump impulse art")
	game.p["energy"]=2
	game._set_action("dash",true)
	game._set_action("dash",false)
	check(game.p_attack.attack["kind"]=="pierce" and game.p["energy"]==1,"Second C consumes exactly one energy pip")
	game._reset_player(Vector2(550,700))
	var doubled:float=game._primary_definition({"dir":"right"})["range"]
	game.strong_slots.clear()
	check(is_equal_approx(doubled,2.0*float(game._primary_definition({"dir":"right"})["range"])),"Reach rune doubles ordinary attack distance")
	game.strong_slots.assign(["instant_strike"])
	var target:Dictionary={"uid":7979,"pos":Vector2(580,700),"hp":100.0,"attack":game.Attack.new(),"face":-1.0}
	game.enemies.assign([target])
	game.keys["right"]=true
	game._set_action("attack",true)
	var first:float=target["hp"]
	game._set_action("attack",true)
	check(target["hp"]==first,"An already-held input does not repeat the attack")
	game._set_action("attack",false)
	game._set_action("attack",true)
	check(first<100.0 and target["hp"]<first and game.player_slashes.size()==2,"Two fresh presses instantly create two hits and effects without waiting for the previous swing")
	check(not game.ui.feather_collection.shards.is_empty(),"A hit emits feather shards toward the HUD")
	game.ui.feather_collection.step(.6,Transform2D.IDENTITY,Vector2(150,30))
	game.enemies.clear()
	check(game.ui.feather_collection.shards.is_empty(),"Collected shards retire after reaching their destination")
	game.p["energy"]=1
	game.p["power_item_left"]=9.2
	game._update_hud()
	check("10 秒" in game.ui.timed_effects_label.text,"Active effects show remaining whole seconds")
	check(game.ui.energy_cells.get_child(0).texture==game.ui.ENERGY_FULL and game.ui.energy_cells.get_child(1).texture==game.ui.ENERGY_EMPTY,"Energy pips use matching full and empty feather textures")
	game.p["hp"]=2
	game.p["shield_cells"]=2
	game.p["energy"]=game.p["max_energy"]
	game._update_hud()
	check(game.ui.health_cells.get_child(0).texture==game.ui.HEART_FULL and game.ui.health_cells.get_child(2).texture==game.ui.HEART_EMPTY,"Health cells show filled and empty hearts")
	check(game.ui.shield_cells.get_child(0).texture==game.ui.SHIELD_FULL and game.ui.shield_cells.get_child(2).texture==game.ui.SHIELD_EMPTY,"Shield cells show filled and empty shields")
	check(game.ui.energy_cells.get_child(0).custom_minimum_size==Vector2(22.5,28.5),"Energy feathers use 1.5x the old size")
	game.ui._process(.1)
	var bright:Color=game.ui.energy_cells.modulate
	game.ui._process(.575)
	check(game.ui.energy_cells.modulate!=bright and game.ui.energy_cells.modulate!=Color.WHITE,"Full energy breathes while the ultimate is ready")
	game.ui._process(1.35)
	check(game.ui.energy_cells.modulate.is_equal_approx(game.ui.ultimate_hint.modulate),"The full row and ultimate prompt pulse together")
	game.p["energy"]-=1
	game._update_hud()
	game.ui._process(.01)
	check(game.ui.energy_cells.modulate==Color.WHITE,"The full-energy pulse stops when a cell is spent")
	game.ui.feather_collection.burst(Vector2.ZERO,Vector2.RIGHT,Transform2D.IDENTITY,false)
	check(game.ui.feather_collection.shards.all(func(shard:Dictionary)->bool:return shard["size"]>=18.0 and shard["size"]<=36.0),"Absorption feathers use twice the previous dimensions")
	check(game.PORTAL_HEIGHT==3.0*96.0,"Transition gate uses three standard cells across room layouts")
	game.queue_free()
	await process_frame
	print("v79 checks: ",failures)
	quit(0 if failures.is_empty() else 1)
