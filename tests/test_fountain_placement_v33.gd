extends SceneTree
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/maze_room_layout.gd")
const Spring=preload("res://scripts/spring_v33.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var count:int=0
	for seed_value:int in [0,33,171,953]:
		var tower:Dictionary=Tower.generate(seed_value,6,10,{"fountain_chance":1.0})
		for room:Dictionary in tower["rooms"]:
			if not room.get("fountain",false):continue
			var layout:Dictionary=Layout.generate(room,seed_value);Spring.prepare(layout)
			var at:Vector2=layout["fountain_pos"]
			if layout["solids"].any(func(r:Rect2)->bool:return r.intersects(Spring.body(at).grow(-1))):failures.append("Fountain body intersects rock: "+str([seed_value,room["id"],at]))
			if not layout["platforms"].any(func(r:Rect2)->bool:return absf(r.position.y-at.y)<1 and at.x>=r.position.x and at.x<=r.end.x):failures.append("Fountain lacks ground support")
			count+=1
	for failure:String in failures:push_error(failure)
	print("v33 fountain placement ",count," rooms; ",failures)
	quit(0 if failures.is_empty() else 1)
