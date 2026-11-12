extends SceneTree
const PlayerMotion=preload("res://scripts/player_motion_v18.gd")
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Coll=preload("res://scripts/world_collision.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok and failures.size()<35:failures.append(label);push_error(label)
func run() -> void:
	var room_count:int=0
	var door_count:int=0
	for seed_value in [91451,192]:
		var tower:Dictionary=Tower.generate(seed_value)
		for room:Dictionary in tower["rooms"]:
			var result:Dictionary=Layout.generate(room,seed_value)
			var platforms:Array=result["platforms"]
			var center:Vector2=result["spawn_positions"]["center"]
			check(platforms.any(func(surface:Rect2)->bool:return absf(center.y-surface.position.y)<2.0 and center.x>=surface.position.x+15 and center.x<=surface.end.x-15),"Spawn is on real support")
			for direction:String in room["neighbors"]:
				var at:Vector2=result["doors"][direction]
				var box:=Rect2(at-Vector2(17,42),Vector2(34,41.9))
				check(not result["solids"].any(func(rock:Rect2)->bool:return rock.intersects(box)),"The actual portal has clearance for the player")
				door_count+=1
			room_count+=1
	print("Platformer: ",room_count," rooms, ",door_count," clear portals; ",failures)
	quit(0 if failures.is_empty() else 1)
