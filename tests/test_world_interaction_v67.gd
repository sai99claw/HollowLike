extends SceneTree

const Rooms=preload("res://scripts/hazard_room_v54.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Stones=preload("res://scripts/throwable_stones.gd")
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Motion=preload("res://scripts/enemy_motion.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
var failures:Array[String]=[]

func _initialize() -> void:
	call_deferred("run")

func check(ok:bool,message:String) -> void:
	if not ok and message not in failures:failures.append(message)

func run() -> void:
	check(Icons.texture("items_shock")!=null,"Shock fruit has a real icon")
	for seed_value:int in range(30):
		var room:Dictionary={"id":4,"type":"combat","map_index":2,"width":25,"height":15,"neighbors":{"left":0,"right":1,"up":2,"down":3},"coord":Vector2i.ZERO,"doors_config":{"left":7,"right":9,"up":11,"down":15}}
		var layout:Dictionary=Layout.generate(room,seed_value)
		Rooms.prepare(layout,4,"mushroom_air")
		var points:Array=layout["launcher_spawns"]
		check(points.size()==11 and points.filter(func(point:Vector2)->bool:return point.y==layout["floor_y"]).size()==4,"Four ground mushrooms and seven airborne mushrooms")
		for i:int in points.size():
			for j:int in range(i+1,points.size()):
				check(points[i].distance_to(points[j])>Rooms.MUSHROOM_SPACING,"Mushrooms are spaced beyond a full C + CC")
	var floor:=Rect2(0,600,1600,100)
	var rocks:Array[Dictionary]=Stones.spawn({"size":Vector2(1600,700),"floor_y":600,"seed":67},[floor],[floor],[])
	check(rocks.size()==7 and rocks.filter(func(rock:Dictionary)->bool:return rock["large"]).size()==1,"One large stone and a six-stone pile")
	var random:=RandomNumberGenerator.new()
	random.seed=67
	for variant:int in [0,Roster.REGULAR_COUNT-1]:
		var actor:Dictionary=Roster.regular("trunk",variant)
		actor["pos"]=Vector2(500,400) if actor["move"]=="fly" else Vector2(500,600)
		actor["vel"]=Vector2.ZERO
		var velocity:Vector2=Motion.velocity(actor,Vector2(530,400),.1,random,actor["move"]!="fly",[],Vector2(34,45),false,floor)
		check(absf(velocity.x)>0 and actor["charge_phase"]=="idle","Off-screen creatures roam without starting an attack")
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.audio_enabled=false
	game.new_run("rogue",67)
	var dummy:Dictionary=game.enemies.filter(func(actor:Dictionary)->bool:return actor.get("training",false))[0]
	check(game.enemies.filter(func(actor:Dictionary)->bool:return actor.get("training",false)).size()==1,"Only the grounded training dummy remains")
	check(game._enemy_body_box(dummy).size==Roster.regular("underground",0)["body_size"],"Dummy collision uses the regular monster body")
	game._hit_enemy(dummy,2,Color.WHITE,76,Vector2.INF,Vector2.RIGHT)
	check(dummy["training_total"]==2 and dummy["hp"]==dummy["max_hp"] and dummy["push_left"]>0,"Dummy receives normal knockback and records damage without dying")
	var stone:Dictionary=rocks.back()
	stone["pos"]=Vector2(500,600)
	game.props.assign([stone])
	game.solids.assign([floor])
	game.platforms.assign([floor])
	dummy["pos"]=Vector2(575,600)
	var before:float=dummy["training_total"]
	game.p_attack.cancel()
	game.p["face"]=1
	game._hit_props(Stones.body(stone),3)
	check(not stone["asleep"] and Vector2(stone["vel"]).x>0,"Player attack launches the stone")
	for i:int in 16:game._step_stone(stone,1.0/120.0)
	check(dummy["training_total"]>before,"A swept stone collision uses the same enemy damage path")
	game.queue_free()
	await process_frame
	print("v67 interaction verification: ",failures)
	quit(0 if failures.is_empty() else 1)
