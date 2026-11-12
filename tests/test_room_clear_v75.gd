extends SceneTree

const Scale=preload("res://scripts/world_scale_v17.gd")
const Motion=preload("res://scripts/player_motion_v18.gd")
var failures:Array[String]=[]

func _initialize() -> void:
	call_deferred("run")

func check(condition:bool,message:String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.audio_enabled=false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.new_run("rogue",75075)
	var encounter:Dictionary={}
	for candidate:Dictionary in game.tower["rooms"]:
		if candidate["type"]=="combat" and not candidate.get("spring",false):
			encounter=candidate
			break
	game._enter_room(encounter["id"])
	check(is_equal_approx(float(game.layout["tile_height"]),Scale.TILE_HEIGHT),"Live map uses tall cells")
	check(is_equal_approx(Scale.TILE_HEIGHT,Motion.BASE_JUMP_HEIGHT*2.5),"Cell height is 2.5 times the baseline full jump")
	game.enemies.assign([{"hp":1.0},{"hp":0.0}])
	game.room.erase("cleared")
	game.drops.clear()
	var at:Vector2=game.p["pos"]+Vector2(650,-160)
	game._drop("coin",at,7)
	game._drop("item",at,0)
	game._drop("rune",at,0)
	game._drop("weapon",at,0)
	game._drop("heal",at,1)
	game._check_room_clear()
	game._update_drops(.016)
	check(not game.room.get("cleared",false) and game.drops.size()==11,"Drops stay put with a living enemy")
	game.enemies[0]["hp"]=0
	game.enemies.append({"hp":100,"training":true})
	game._check_room_clear()
	check(game.room.get("cleared",false),"Training targets do not block combat room clear")
	var gold:int=game.run_coins
	var item_count:int=int(game.bag_items.get("0",0))
	var hp:float=maxf(1,game.p["hp"]-2)
	game.p["hp"]=hp
	game._drop("coin",at,2)
	game._update_drops(.016)
	check(not game.drops.is_empty(),"Clear animates loot flying across the room")
	for i in 120:game._update_drops(1.0/60.0)
	check(game.drops.is_empty() and game.room["drops"].is_empty(),"Distant coins and non-coin drops all reach the player")
	check(game.run_coins==gold+9 and int(game.bag_items.get("0",0))==item_count+1 and game.p["hp"]==hp+1,"Normal reward handlers apply every collected drop once")
	game.enemies.clear()
	game.queue_free()
	await process_frame
	print("v75 clear and terrain checks: ",failures)
	quit(0 if failures.is_empty() else 1)
