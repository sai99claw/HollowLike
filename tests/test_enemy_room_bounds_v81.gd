extends SceneTree

var failures:Array[String]=[]

func _initialize() -> void:
	call_deferred("run")

func check(condition:bool,message:String) -> void:
	if not condition:
		failures.append(message)
		if failures.size()<=8:push_error(message)

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.audio_enabled=false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	var spawned:int=0
	for seed_value in [81081,2197,350]:
		game.new_run("rogue",seed_value)
		for room:Dictionary in game.tower["rooms"]:
			game._enter_room(room["id"])
			var bounds:=Rect2(Vector2.ZERO,game._room_size())
			for enemy:Dictionary in game.enemies:
				spawned+=1
				check(bounds.encloses(game._enemy_body_box(enemy)),"Complete enemy body is inside the room at spawn")
			if room["type"]=="boss":
				var reinforcements:Array=[]
				var random:=RandomNumberGenerator.new()
				random.seed=seed_value
				game._spawn_boss_reinforcements(reinforcements,4,true,random)
				for enemy:Dictionary in reinforcements:
					check(bounds.encloses(game._enemy_body_box(enemy)),"Reinforcement uses the full-body room bounds")
	check(spawned>100,"Three seeded towers exercise live spawns")
	game.layout={"size":Vector2(1200,900),"floor_y":800.0}
	game.platforms.clear()
	game.solids.clear()
	game.doors.clear()
	check(not game._spawn_space_clear(Vector2(5,450),Vector2(44,42)),"Anchor inside is insufficient when half the body is outside")
	check(not game._spawn_space_clear(Vector2(500,905),Vector2(44,42)),"Feet below the room cannot spawn")
	var monster:Dictionary={"pos":Vector2(500,925),"vel":Vector2(0,800),"spawn_home":Vector2(400,800),"hp":3.0}
	game._keep_enemy_in_room(monster,Vector2(500,890))
	check(monster["pos"]==Vector2(400,800) and monster["vel"]==Vector2.ZERO,"An enemy that falls through a bottom opening returns to its safe spawn")
	game.enemies.clear()
	game.queue_free()
	await process_frame
	print("Live spawns checked: ",spawned,"  failures: ",failures.size())
	quit(0 if failures.is_empty() else 1)
