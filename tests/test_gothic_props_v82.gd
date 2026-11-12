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
	game.new_run("rogue",82082)
	game.enemies.clear()
	game.props.clear()
	game.effects.clear()
	game._reset_player(Vector2(550,700))
	var biome:String=game._ecology()["id"]
	for region:String in ["trunk","underground","sky"]:
		for kind:String in ["ecology_object","coin_urn","launcher","energy","health","stone","chest","fountain","dummy","wardrobe","aid","forge","reforge","mail","gift_pedestal","merchant_table","home_projector","adventure_records","trophy_case"]:
			var art:Array=game.GothicProps.entry({"kind":kind},region)
			check(art.size()==3 and art[0].get_size()==Vector2(480,960),"Object has intact, damaged, and fragment atlas cells")
	var plant:Dictionary={"kind":"ecology_object","variant":4,"pos":Vector2(620,700),"hp":1.0,"hurt":0.0}
	game.props.assign([plant])
	game._hit_props(Rect2(590,610,90,100),1,1,Vector2(570,650))
	check(plant.get("gothic_broken",false) and plant["pos"]==Vector2(620,700),"Damaged base stays at the original position")
	check(game.effects.any(func(fx:Dictionary)->bool:return fx.has("prop_flash")),"Strike adds the straight flash")
	var fragments:Array=game.effects.filter(func(fx:Dictionary)->bool:return fx.has("prop_fragment"))
	check(fragments.size()==1 and fragments[0]["vel"].x>0 and fragments[0]["vel"].y<0,"The separate shard is launched away from the strike")
	var origin:Vector2=fragments[0]["pos"]
	game._update_visual_effects(.1)
	check(fragments[0]["pos"]!=origin and plant["pos"]==Vector2(620,700),"Flying shard moves independently of the remnant")
	game._hit_props(Rect2(590,610,90,100),1,1,Vector2(570,650))
	check(game.effects.filter(func(fx:Dictionary)->bool:return fx.has("prop_fragment")).size()==1,"A shattered object cannot produce duplicate shards")
	var mushroom:Dictionary={"kind":"launcher","pos":Vector2(620,700),"hurt":0.0,"navigation":true}
	game._launch_from_object(mushroom,Vector2.ZERO)
	var light:float=game.p["vel"].y
	game._launch_from_object(mushroom,Vector2.RIGHT)
	check(game.p["vel"].x<0 and game.p["vel"].y==light and game.p["recoil_left"]>0,"Side slash creates sustained lateral rebound away from the mushroom")
	game._launch_from_object(mushroom,Vector2.LEFT)
	check(game.p["vel"].x>0 and game.p["vel"].y==light,"Opposite side slash reverses the rebound")
	game._launch_from_object(mushroom,Vector2.DOWN)
	check(game.p["vel"].y<light*3.0,"Only the down slash launches high")
	game.props.clear()
	game.queue_free()
	await process_frame
	print("Gothic object and mushroom checks: ",failures)
	quit(0 if failures.is_empty() else 1)
