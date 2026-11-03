extends SceneTree
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/maze_room_layout.gd")
const Depth=preload("res://scripts/depth_style_v32.gd")
const Readability=preload("res://scripts/projectile_readability_v25.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func run() -> void:
	check(is_equal_approx(Readability.BASE_RADIUS*2,Readability.PLAYER_HEIGHT/4*1.5),"Canonical projectile diameter is one quarter times1.5 of player height")
	var input:Array[Rect2]=[Rect2(0,96,288,9),Rect2(96,96,288,9),Rect2(96,96,288,9),Rect2(384,96,96,9)]
	var merged:Array[Rect2]=Layout._merge_platforms(input)
	check(merged==[Rect2(0,96,480,9)],"Overlapping, duplicate and touching ledges form one exact support run")
	var rooms_checked:int=0
	for count:int in [6,7,10,12]:
		for seed_value:int in [32,772]:
			var tower:Dictionary=Tower.generate(seed_value,6,count)
			check(Tower.validate(tower).is_empty(),"Six-stage topology remains reciprocal, unique-farthest and connected")
			if count>6:
				for chapter:Dictionary in tower["maps"]:
					var entrance:Vector2i=tower["rooms"][chapter["start_id"]]["coord"]
					check(chapter["room_ids"].any(func(id:int)->bool:return tower["rooms"][id]["coord"].y>entrance.y),"Every chapter with a spare branch slot descends below its entrance")
			for room:Dictionary in tower["rooms"]:
				var safe:bool=room["type"] in ["start","merchant","reward"]
				if safe:
					for side:String in room["neighbors"]:check(side in ["left","right"],"Functional-room entrances are genuinely horizontal in world topology")
				var layout:Dictionary=Layout.generate(room,seed_value)
				check(Layout.validate(layout).is_empty(),"Portal spawns remain clear of rock")
				var ledges:Array=layout["one_way"]
				for i in ledges.size():
					for j in range(i+1,ledges.size()):check(not Rect2(ledges[i]).intersects(ledges[j]),"No duplicate or overlapping platform collision modules: "+str([seed_value,room["id"],ledges[i],ledges[j]]))
				for side:String in layout["doors"]:
					if safe:check(side in ["left","right"] and layout["doors"][side].y<layout["size"].y,"Functional-room door has an in-bounds side landing")
				rooms_checked+=1
	for biome:String in ["sky","trunk","underground"]:
		var far:ShaderMaterial=Depth.material(biome,"far");var mid:ShaderMaterial=Depth.material(biome,"middle");var low:ShaderMaterial=Depth.material(biome,"middle",true)
		check(float(far.get_shader_parameter("contrast"))<float(mid.get_shader_parameter("contrast")),"Depth planes preserve separate contrast groups")
		check(float(far.get_shader_parameter("blur_radius"))>float(mid.get_shader_parameter("blur_radius")) and float(low.get_shader_parameter("blur_radius"))==0,"Farther is softer; reduced mode skips blur offsets")
	check(is_equal_approx(Depth.backdrop_rect().size.aspect(),1.5),"Far art retains original three-to-two aspect ratio")
	print("v32 checked ",rooms_checked," layouts; ",failures)
	quit(0 if failures.is_empty() else 1)
