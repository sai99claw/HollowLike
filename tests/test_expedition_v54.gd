extends SceneTree

const HazardRoom=preload("res://scripts/hazard_room_v54.gd")
const Data=preload("res://scripts/game_data.gd")
var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")

func check(ok:bool,message:String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var counts:Dictionary={"spike_islands":0,"mushroom_air":0}
	for i in 1000:
		var sample:Dictionary={"seed":i*313,"size":Vector2(2016,1152),"spawn_positions":{"center":Vector2(1008,1056),"right":Vector2(168,768)}}
		HazardRoom.prepare(sample,i)
		var variant:String=sample.get("hazard_room","")
		if variant.is_empty():continue
		counts[variant]+=1
		if variant=="spike_islands":
			check(not sample["spike_rects"].is_empty(),"Spike islands contain spike tops")
			check(sample["solids"].all(func(rect:Rect2)->bool:return rect.size in [Vector2(96,96),Vector2(192,96)]),"Islands are one or two tiles wide")
		else:check(sample["solids"].is_empty() and not sample["launcher_spawns"].is_empty(),"Floating room has mushrooms and no solid tiles")
	for count:int in counts.values():check(count>=75 and count<=130,"Each hazard room rolls roughly 10 percent")
	var g=load("res://main.tscn").instantiate()
	g.audio_enabled=false
	root.add_child(g)
	await process_frame
	g.set_process(false);g.set_physics_process(false)
	g.new_run("rogue",54054);g._close_panel()
	g._acquire_weapon(Data.secondary_attack(0))
	g._acquire_weapon(Data.secondary_attack(1))
	check(g.bag_weapons.size()==1 and g.bag_weapons[0]["duplicate_bonus"]==1,"Rogue loot upgrades the equipped weapon")
	g._cycle_map();check(g.minimap_open and g.minimap_page==0,"Tab opens room terrain")
	g._cycle_map();check(g.minimap_page==1,"Tab switches to chapter")
	g._cycle_map();check(g.minimap_page==2,"Tab switches to tower")
	g._cycle_map();check(not g.minimap_open,"Tab closes the tower")
	var normal:float=g._primary_definition({"dir":"right"})["damage"]
	g._use_item(5,false)
	check(is_equal_approx(g._primary_definition({"dir":"right"})["damage"],normal*1.2) and g.p["power_item_left"]==120.0,"Power item adds 20 percent damage for two minutes")
	g._use_item(3,false)
	check(g.p["shield_item_left"]==60.0,"Shield item grants a minute of orbital shields")
	check(g.UI.Icons.texture("items_shock")!=null and g.UI.Icons.texture("items_power")!=null,"New supplies have icons")
	var inspected:Dictionary={}
	for candidate:Dictionary in g.tower["rooms"]:
		if candidate["type"]!="combat":continue
		var geometry:Dictionary=g.Layout.generate(candidate,g.tower["seed"])
		HazardRoom.prepare(geometry,candidate["id"])
		var variant:String=geometry.get("hazard_room","")
		if variant.is_empty() or inspected.has(variant):continue
		g._enter_room(candidate["id"])
		check(g.layout.get("hazard_room","")==variant,"Actual room entry keeps its deterministic variant")
		check(g.enemies.size()==3 and g.enemies.all(func(enemy:Dictionary)->bool:return enemy.get("elite",false) and enemy["move"]=="fly"),"Special rooms spawn three flying elites")
		for direction in candidate["neighbors"]:check(g.layout["doors"].has(direction),"Special rooms preserve door anchors")
		inspected[variant]=true
	check(inspected.size()==2,"Fixed expedition seed exercises both room types")
	g.queue_free()
	await process_frame
	print("v54 expedition checks: ",failures)
	quit(0 if failures.is_empty() else 1)
