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
	check(game._room_size().y<=1100,"Safe room stays compact instead of stretching to the combat grid scale")
	var encounter:Dictionary={}
	for candidate:Dictionary in game.tower["rooms"]:
		if candidate["type"]=="combat" and not candidate.get("spring",false):
			encounter=candidate
			break
	game._enter_room(encounter["id"])
	check(is_equal_approx(float(game.layout["tile_height"]),Scale.TILE_HEIGHT),"Live map uses tall cells")
	check(game.layout.has("maze_grid") and not game.layout.has("hazard_room"),"Adventure keeps the generated maze geometry")
	var middle:Vector2=game._room_size()*.5
	var camera_offset:Vector2=game._camera_target(middle)
	check(is_equal_approx((middle.y-camera_offset.y)*game._view_zoom(),480.0),"Player sits at the start of the bottom third when the camera is away from room edges")
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
	check(not game.room.get("cleared",false) and game.room_clear_slow_left==0.0 and game.drops.size()==11,"Drops stay put with a living enemy")
	game.enemies[0]["hp"]=0
	game.enemies.append({"hp":100,"training":true})
	game._check_room_clear()
	check(game.room.get("cleared",false),"Training targets do not block combat room clear")
	check(game.room_clear_slow_left==2.0 and game._clear_world_rate()<1.0,"Last enemy starts exactly two seconds of world slowdown")
	game.enemies.clear()
	game._close_panel()
	game.hitstop=.05
	game._physics_process(.05)
	check(is_equal_approx(game.room_clear_slow_left,1.95),"Slowdown clock runs at real speed through hitstop")
	var visual_time:float=game.draw_clock
	game._physics_process(.05)
	check(is_equal_approx(game.draw_clock-visual_time,.05*game.world_speed*game.ROOM_CLEAR_WORLD_RATE),"World pose time advances at the slowed rate")
	var gold:int=game.run_coins
	var item_count:int=int(game.bag_items.get("0",0))
	var hp:float=maxf(1,game.p["hp"]-2)
	game.p["hp"]=hp
	var center:Vector2=game.p["pos"]-Vector2(0,20)
	var orbit:Dictionary={"pos":center,"seed":0.0}
	check(not game._step_clear_loot_vortex(orbit,center,.15) and orbit.has("orbit_angle"),"Even loot at the player's feet moves out to the orbit before being collected")
	var entered:Vector2=orbit["pos"]
	var moved_center:Vector2=center+Vector2(90,-30)
	check(not game._step_clear_loot_vortex(orbit,moved_center,.22) and not entered.is_equal_approx(orbit["pos"]),"Orbit advances around the moving player before any reward is granted")
	check(absf(Vector2(orbit["pos"]).distance_to(moved_center)-52.0)<.01,"Orbit keeps its radius relative to the moved player")
	check(game._step_clear_loot_vortex(orbit,moved_center,.40) and moved_center.is_equal_approx(orbit["pos"]),"A full revolution ends in a pull into the player's center")
	game._drop("coin",at,2)
	game._update_drops(.016)
	check(not game.drops.is_empty(),"Clear animates loot flying across the room")
	for i in 120:game._update_drops(1.0/60.0)
	check(game.drops.is_empty() and game.room["drops"].is_empty(),"Distant coins and non-coin drops all reach the player")
	check(game.run_coins==gold+9 and int(game.bag_items.get("0",0))==item_count+1 and game.p["hp"]==hp+1,"Normal reward handlers apply every collected drop once")
	game.enemies.assign([{"pos":Vector2(1200,480),"hp":5.0},{"pos":Vector2(340,500),"hp":0.0}])
	check(game._minimap_enemy_markers().size()==1,"Minimap shows living enemies even outside the camera and omits corpses")
	game.enemies.clear()
	for candidate:Dictionary in game.tower["rooms"]:
		if candidate["type"]!="boss":continue
		game._enter_room(candidate["id"])
		break
	check(is_equal_approx(game._room_size().y,1080.0) and is_equal_approx(game._view_zoom(),game.camera_zoom),"Boss uses the same player camera scale as other rooms")
	# Exercise a real generated downward hatch from its low traversal ledge.
	var found_low_ledge:bool=false
	for candidate:Dictionary in game.tower["rooms"]:
		if candidate["type"]!="combat" or not candidate["neighbors"].has("down"):continue
		game._enter_room(candidate["id"])
		var down:Vector2=game.layout["doors"]["down"]
		for ledge:Rect2 in game.layout["one_way"]:
			if ledge.position.y<game._room_floor() or down.x<=ledge.position.x or down.x>=ledge.end.x:continue
			var perch:=Vector2(down.x,ledge.position.y)
			if not game._can_drop_through(perch):continue
			found_low_ledge=true
			game.room["cleared"]=true
			game.enemies.clear()
			game.room_cooldown=0.0
			game._reset_player(perch)
			game._set_action("down",true)
			game._set_action("jump",true)
			game._update_player(1.0/120.0)
			check(game.p["pos"].y>perch.y and not game.p["grounded"],"Down + Jump drops through the low hatch ledge instead of jumping upward")
			for tick in 150:
				game._update_player(1.0/120.0)
				game._check_portals()
				if game.current_room!=candidate["id"]:break
			check(game.current_room==candidate["neighbors"]["down"],"The drop reaches the connected room below")
			break
		if found_low_ledge:break
	check(found_low_ledge,"The seeded tower supplies a ledge below the room floor")
	var solid_floor:=Rect2(0,800,1200,40)
	game.platforms.assign([Rect2(0,800,1200,9)])
	game.solids.assign([solid_floor])
	game.layout["floor_y"]=900.0
	check(not game._can_drop_through(Vector2(500,800)),"Down + Jump cannot pass through a solid surface")
	game.queue_free()
	await process_frame
	print("v75 clear and terrain checks: ",failures)
	quit(0 if failures.is_empty() else 1)
