extends SceneTree
const Coll=preload("res://scripts/world_collision.gd")
var OldColl:GDScript
const Flight=preload("res://scripts/flight_navigation.gd")
var OldFlight:GDScript
const Terrain=preload("res://scripts/terrain_art_v24.gd")
const Canvas=preload("res://scripts/enemy_canvas_v18.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func settle() -> void:
	for i in 3:await process_frame
func reference(name:String) -> GDScript:
	var script:=GDScript.new();script.source_code=FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://tests/fixtures/"+name+".gd")).replace("res://tests/fixtures/world_collision_v27.gd","res://scripts/world_collision.gd");check(script.reload()==OK,"Reference solver compiles: "+name);return script
func run() -> void:
	OldColl=reference("world_collision_v27");OldFlight=reference("flight_navigation_v27")
	var random:=RandomNumberGenerator.new();random.seed=280028
	for sample in 750:
		var world:Array=[Rect2(0,900,1800,80),Rect2(-96,0,96,1000),Rect2(1800,0,96,1000)]
		for i in 18:world.append(Rect2(random.randi_range(0,17)*96,random.randi_range(1,8)*96,random.randi_range(1,3)*96,random.randi_range(1,2)*48))
		var at:=Vector2(random.randf_range(10,1790),random.randf_range(10,920));var velocity:=Vector2(random.randf_range(-1500,1500),random.randf_range(-1300,1500));var delta:float=[1.0/120,1.0/60,.05][sample%3];var body:=Vector2(random.randf_range(20,80),random.randf_range(30,100));var margin:int=4 if sample%2==0 else 0
		var before:Dictionary=OldColl.move_body(at,velocity,delta,body,world,margin);var after:Dictionary=Coll.move_body(at,velocity,delta,body,world,margin)
		check(before["pos"].is_equal_approx(after["pos"]) and before["vel"].is_equal_approx(after["vel"]) and before["wall"]==after["wall"] and before["grounded"]==after["grounded"],"Optimized body collision matches v27 including embedded starts and corner correction: "+str(sample))
		var b:Vector2=at+velocity*.25;var radius:float=random.randf_range(0,40);var old_time:float=OldColl.first_solid(at,b,radius,world);var new_time:float=Coll.first_solid(at,b,radius,world)
		check((old_time==INF and new_time==INF) or is_equal_approx(old_time,new_time),"Swept projectile collision keeps nearest impact: "+str(sample))
	for sample in 50:
		var world:Array=[Rect2(300,150,80,450),Rect2(600,300,250,60),Rect2(0,1050,1500,80)]
		for i in 60:world.append(Rect2(1800+i*96,0,80,800))
		var at:=Vector2(random.randf_range(120,1100),random.randf_range(140,850));var bird:Dictionary={"pos":at,"speed":90.0};var clone:Dictionary=bird.duplicate(true);var target:=Vector2(random.randf_range(120,1100),random.randf_range(140,850));var desired:Vector2=(target-at).normalized()*75
		var expected:Vector2=OldFlight.steer(bird,target,desired,Vector2(34,42),world,1.0/60);var actual:Vector2=Flight.steer(clone,target,desired,Vector2(34,42),world,1.0/60)
		check(expected.is_equal_approx(actual),"Local flight clearance preserves steering and wall escape: "+str(sample))
	var mesh:ArrayMesh=Terrain.corner_mesh("v28-test",Vector2(128,128),Vector2(512,512));var arrays:Array=mesh.surface_get_arrays(0)
	check(mesh.get_surface_count()==1 and arrays[Mesh.ARRAY_VERTEX].size()==256 and arrays[Mesh.ARRAY_INDEX].size()==384,"Corner retains all64quads in one cached draw surface")
	check(Terrain.corner_mesh("v28-test",Vector2(128,128),Vector2(512,512))==mesh,"Repeated corners reuse mesh resource")
	var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR];check(is_zero_approx(colors[0].a) and colors[120].a>.8,"Corner feathering preserves transparent rim and opaque center")
	var actor:Dictionary={"pos":Vector2(100,200),"flash_left":0.0};var painted:Array=[];var sprite=Canvas.new();sprite.local_origin=true;sprite.actor=actor;sprite.paint=func(c:CanvasItem,view:Dictionary)->void:painted.append(view["pos"]);c.draw_circle(view["pos"],10,Color.WHITE)
	root.add_child(sprite)
	var base:=Transform2D(0,Vector2.ONE*1.3,0,Vector2(-70,-90));sprite.refresh(base,true,[1]);await settle();var count:int=sprite.rebuilds
	for i in 6:actor["pos"]+=Vector2(8,0);sprite.refresh(base,true,[1]);await process_frame
	check(sprite.rebuilds==count and sprite.transform.origin.is_equal_approx(base*actor["pos"]),"Actor movement and camera follow without rebuilding unchanged sprite commands")
	check(painted[0]==Vector2.ZERO and actor["pos"]!=Vector2.ZERO,"Local paint preserves original gameplay actor coordinates")
	sprite.refresh(base,true,[2]);await settle();check(sprite.rebuilds==count+1,"Animation pose change triggers one redraw")
	actor["flash_left"]=.01;sprite.refresh(base,true,[2]);check(sprite.material==Canvas.white_ink,"Hit flash still updates immediately with retained commands")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",280028);game._close_panel();game.enemies.clear();game._sync_enemy_canvases();game.view_rect=Rect2(0,0,1280,720)
	for i in 3:
		var enemy:Dictionary=game.Arms.enemy("hover",random);enemy.merge({"uid":800+i,"pos":Vector2(400 if i==0 else 4000,400),"hp":5.0 if i!=2 else 0.0,"vel":Vector2.ZERO,"face":1.0,"attack":game.Attack.new()},true);game.enemies.append(enemy)
	game._sync_enemy_canvases();check(game.enemy_canvases.has(800) and not game.enemy_canvases.has(801) and not game.enemy_canvases.has(802),"Offscreen and dead enemies do not allocate drawing nodes")
	var en:Dictionary=game.enemies[0];var size:Vector2=game.MonsterMotion.body_size(en);en["scale"]=2.0;check(game.MonsterMotion.body_size(en).is_equal_approx(size*2),"Cached actor collision size updates when scale changes")
	game.enemies[0]["hp"]=0;game._sync_enemy_canvases();check(not game.enemy_canvases.has(800),"Dead actor draw node is released")
	sprite.queue_free();game.queue_free();await process_frame;print("v28 performance/collision checks: %d failures"%failures.size());quit(0 if failures.is_empty() else 1)
