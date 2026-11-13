extends SceneTree
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/maze_room_layout.gd")
const Pool=preload("res://scripts/recessed_pool.gd")
var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")

func check(value:bool,message:String) -> void:
	if not value:failures.append(message)

func run() -> void:
	var placed:=0
	var requested:=0
	for seed_value:int in [0,33,171,953]:
		var tower:Dictionary=Tower.generate(seed_value,6,10,{"fountain_chance":1.0})
		for room:Dictionary in tower["rooms"]:
			if not room.get("fountain",false):continue
			requested+=1
			var layout:Dictionary=Layout.generate(room,seed_value)
			if not Pool.prepare(layout):
				continue
			var water:Rect2=layout["pool"]
			var label:=str([seed_value,room["id"]])
			check(layout["recessed_pool"] and water.position.y>float(layout["floor_y"]),"Waterline above its bank: "+label)
			var center:=Rect2(water.position+Vector2(50,0),water.size-Vector2(100,0))
			check(not layout["solids"].any(func(r:Rect2)->bool:return r.intersects(center)),"Rock fills the water basin: "+label)
			for x:float in [water.position.x+10,water.get_center().x,water.end.x-10]:
				check(layout["platforms"].any(func(r:Rect2)->bool:return r.position.y>water.position.y and r.position.y<=water.end.y and x>=r.position.x and x<r.end.x),"No support under water: "+label)
			check(Layout.validate(layout).is_empty(),"Basin blocks existing room navigation: "+label)
			placed+=1
	check(placed>=requested*.95,"Water placement removed too many rolled rooms")
	for failure:String in failures:push_error(failure)
	print("Recessed water basins ",placed,"/",requested," rooms; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
