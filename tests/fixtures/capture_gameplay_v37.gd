extends SceneTree
const OUT:String="/tmp/pigeon37-qa"
const Spring=preload("res://scripts/spring_v33.gd")
const Art=preload("res://scripts/art.gd")
const Mantle=preload("res://scripts/mantle_art_v37.gd")
const Hit=preload("res://scripts/hit_art_v37.gd")
const Ledge=preload("res://scripts/ledge_mantle_v37.gd")
class Plate extends Node2D:
	var mode:String="pools"
	var font:Font=load("res://assets/Chinese.otf")
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,720),Color("19332d"));draw_string(font,Vector2(30,45),"v37 · "+mode,HORIZONTAL_ALIGNMENT_LEFT,-1,22)
		if mode=="pools":
			for i in 3:
				var at:=Vector2(230+i*410,440);var biome:String=["underground","trunk","sky"][i]
				Spring.draw(self,at,biome,Transform2D(0,Vector2(0,10)))
				Art.draw_pigeon(self,at,1,0,"idle",Color.WHITE,1,0,Transform2D.IDENTITY,"quick",{})
				var bath=preload("res://scripts/bath_water.gd").new();bath.attack(Spring.pool(at,biome),at)
				Spring.draw_water(self,at,biome,Transform2D.IDENTITY,bath,.4)
		elif mode=="mantle":
			for i in 4:
				var at:=Vector2(130+i*310,400);var p:Dictionary={"pos":at,"face":1};Ledge.begin(p,at+Vector2(37,-15));Ledge.step(p,i*.08+.01)
				draw_rect(Rect2(at+Vector2(17,-15),Vector2(130,200)),Color("485f4d"));Mantle.draw(self,p,Transform2D.IDENTITY,Color.WHITE)
		elif mode=="corpses":
			for row in 3:
				for col in 2:
					var en:Dictionary={"roster_id":"qa","roster_biome":["underground","trunk","sky"][row],"roster_row":0 if col==0 else 2,"roster_elite":false,"pos":Vector2(220+col*600,240+row*180),"face":1.0,"vel":Vector2.ZERO}
					preload("res://scripts/monster_art_v36.gd").draw_actor(self,en,0)
					en["pos"]+=Vector2(170,0);var body:Dictionary=preload("res://scripts/corpse_field_v21.gd").create(en);body["age"]=1.0
					draw_line(body["pos"]-Vector2(80,0),body["pos"]+Vector2(80,0),Color("718670"),1)
					preload("res://scripts/corpse_field_v21.gd").draw(self,body)
		elif mode=="hit":
			for i in 3:
				var at:=Vector2(240+i*410,390);Hit.draw(self,{"at":at,"dir":Vector2.RIGHT,"angle":-.22+float(i)*.22,"max":.18,"life":.18-(float(i)*.055+.01),"length":1280.0/3,"feathers":true},Transform2D.IDENTITY)
func _initialize() -> void:call_deferred("run")
func snap(label:String) -> void:
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+label+".png");print("CAPTURE ",label)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT);var plate:=Plate.new();root.add_child(plate)
	for mode:String in ["pools","mantle","hit","corpses"]:plate.mode=mode;plate.queue_redraw();await snap(mode)
	plate.queue_free();await process_frame
	var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false)
	g.meta["rd_tuning"]={"fountain_chance":1.0};g.new_run("rogue",171);g._close_panel()
	for stage:int in [0,2,4]:
		var target:Dictionary=g.tower["rooms"].filter(func(r:Dictionary)->bool:return r["type"]=="combat" and int(r["map_index"])==stage)[0]
		g._enter_room(target["id"]);g._close_panel();g.p["pos"]=g.layout["fountain_pos"];g.camera_pos=g._camera_target(g.p["pos"]);g.shake=0;g.p["invul"]=0;g._process(0);g._invalidate_scene();await snap("pool-stage"+str(stage))
	g._enter_room(g.tower["maps"][2]["start_id"]);g._close_panel();g.shake=0
	for i in 2:g.camera_pos+=Vector2(200,0)*i;g._process(0);g._invalidate_scene();await snap("parallax"+str(i))
	g.queue_free();await process_frame;quit()
