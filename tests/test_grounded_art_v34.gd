extends SceneTree
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/maze_room_layout.gd")
const Biome=preload("res://scripts/biome_art_v21.gd")
const Art=preload("res://scripts/scene_art_v33.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func run() -> void:
	var count:int=0
	for seed_value:int in [34,772,953,3333]:
		var tower:Dictionary=Tower.generate(seed_value,6,10,{"merchant_chance":1.0})
		for room:Dictionary in tower["rooms"]:
			var layout:Dictionary=Layout.generate(room,seed_value);var biome:String=preload("res://scripts/ecology.gd").from_stage(int(room["map_index"]))["id"];var quiet:bool=room["type"] in ["start","merchant","reward"]
			var plan:Array[Dictionary]=Biome.middle_plan(seed_value,layout["size"],layout,biome,quiet)
			check(not plan.is_empty(),"Every room has large middle objects")
			for item:Dictionary in plan:
				var at:Vector2=item["pos"];var body:Rect2=item["bounds"]
				if item.get("rear_plane",false):
					check(Rect2(Vector2.ZERO,layout["size"]).encloses(body),"Rear plane fallback fits inside the room")
					continue
				var support:Rect2=item["support"]
				check(is_equal_approx(at.y,support.position.y+10),"Middle contact plane follows terrain with ten-pixel inset")
				check(body.position.x>=support.position.x and body.end.x<=support.end.x,"Entire middle prop footprint is supported")
				check(not layout["solids"].any(func(rock:Rect2)->bool:return rock.intersects(body)),"Complete middle prop silhouette is not cut by rock")
				count+=1
	for biome:String in ["sky","trunk","underground"]:
		var rect:Rect2=Art.safehouse_rect(biome,Vector2(1632,1056),960);var d:Dictionary=Art.info("res://assets/v33/safehouses/"+biome+"-background.json");var factor:float=rect.size.x/float(d["original_size"][0])
		check(is_equal_approx(rect.position.y+float(d["floor_y_source"])*factor,960),"Safehouse painting and collision floor have the same contact plane")
		check(rect.position.y<=0 and rect.position.x<=0 and rect.end.x>=1632,"Corrected background still covers the room without holes")
	var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false)
	g.home_sleeping=false;g.home_wake_left=0;g._clear_keys();g.p_attack.cancel();g._reset_player(Vector2(455,600));g._update_props(.01)
	var launcher:Dictionary=g.props.filter(func(prop:Dictionary)->bool:return prop["kind"]=="launcher")[0]
	var touch_speed:float=g.p["vel"].y;check(is_equal_approx(touch_speed,-530),"Home uses gameplay launcher on contact")
	g.p_attack.begin({"kind":"melee","primary":true,"windup":0.0,"active":.1,"recovery":.1,"damage":1,"direction":"right"});g._hit_props(preload("res://scripts/launch_object_v23.gd").body_box(launcher,"trunk"),1)
	check(is_equal_approx(g.p["vel"].y,touch_speed*sqrt(3.0)),"Hitting home launcher produces the same triple-height impulse")
	check(Art.texture("res://assets/v34/home/nest.png")!=null,"Redrawn home nest survives export")
	g.meta["rd_tuning"]={"merchant_chance":1.0};g.new_run("rogue",34034);g._close_panel();await process_frame
	check(g.atmosphere.middle_objects.visible and not g.atmosphere.middle_structures.is_empty(),"Safehouse middle layer is visible")
	for prop:Dictionary in g.props:
		if prop["kind"] in ["wardrobe","aid","forge","reforge","mail","energy_infinite"]:
			check(g.layout["platform_art_runs"].any(func(platform:Rect2)->bool:return is_equal_approx(platform.position.y,prop["pos"].y) and platform.position.x<=prop["pos"].x-72 and platform.end.x>=prop["pos"].x+72),"Every station fits fully on its physical gallery")
	var display:Dictionary=g.drops.filter(func(drop:Dictionary)->bool:return drop.get("gift",false))[0]
	var icon_box:=Rect2(Vector2(display["pos"])-Vector2(24,24),Vector2(48,48))
	check(not g.layout["one_way"].any(func(platform:Rect2)->bool:return platform.intersects(icon_box)),"Free weapon display no longer intersects a stair platform")
	check(preload("res://scripts/art_catalog_v16.gd").entry("home:nest")["frames"][0]["path"]=="res://assets/v34/home/nest.png","Art gallery uses the new nest rather than excluded old resource")
	var background:Rect2=g._background_rect()
	for item:Dictionary in g.atmosphere.middle_structures:
		var bounds:Rect2=item["bounds"]
		check(is_equal_approx(bounds.end.y,background.end.y) and bounds.size.y<=background.size.y*2/3.0+.001,"Middle objects sit on the background bottom within the height limit")
	for camera:Vector2 in [Vector2(200,100),Vector2(200,20)]:
		var far_transform:Transform2D=g.atmosphere.depth_transform(camera,.8,g.Atmosphere.FAR_FACTOR)
		g.atmosphere.backdrop_transform=far_transform
		g.atmosphere.update_view(camera,.8,Transform2D.IDENTITY,Vector2(800,800),1,1,false)
		var edge:=Vector2(0,background.end.y)
		check(is_equal_approx((g.atmosphere.middle_objects.transform*edge).y,(far_transform*edge).y),"Jump camera keeps middle and far bottom edges aligned")
	for room:Dictionary in g.tower["rooms"]:
		if room["type"]!="merchant":continue
		g._enter_room(room["id"]);await process_frame;check(g.atmosphere.middle_objects.visible and not g.atmosphere.middle_structures.is_empty(),"Merchant middle layer remains visible");break
	g.queue_free();await process_frame
	print("v34 grounded objects checked: ",count,"; ",failures)
	quit(0 if failures.is_empty() else 1)
