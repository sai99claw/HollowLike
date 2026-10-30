extends SceneTree
const Coll=preload("res://scripts/world_collision.gd")
const Flight=preload("res://scripts/flight_navigation.gd")
const Terrain=preload("res://scripts/terrain_art_v24.gd")
var game
class CornerProbe extends Node2D:
	var times:Array=[]
	var scene:Dictionary={"art_corners_v21":[]}
	func _draw() -> void:
		var start:int=Time.get_ticks_usec();preload("res://scripts/terrain_art_v24.gd").draw_corners(self,"trunk",scene);times.append(Time.get_ticks_usec()-start)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",280028);game._close_panel();game.enemies.clear();game.props.clear();game.projectiles.clear();game.hazards.clear();game.solids.clear();game.platforms.clear();game.camera_zoom=1;game.camera_pos=Vector2.ZERO;game.layout={"size":Vector2(6000,4000),"floor_y":3800.0};game.p["pos"]=Vector2(600,500);game.p["invul"]=1000;game.freeze_timer=0
	var obstacles:Array=[]
	for i in 400:obstacles.append(Rect2(1500+(i%20)*96,100+int(i/20)*96,80,80))
	obstacles.append(Rect2(0,900,6000,80))
	game.solids.assign(obstacles);game.platforms.assign([Rect2(0,900,6000,80)])
	var random:=RandomNumberGenerator.new();random.seed=28
	for i in 80:
		var enemy:Dictionary=game.Arms.enemy("hover",random);enemy.merge({"uid":i+1,"pos":Vector2(150+(i%16)*60,150+int(i/16)*80),"vel":Vector2.ZERO,"face":-1.0,"stun":0.0,"hurt":0.0,"cooldown":999.0,"attack":game.Attack.new(),"max_hp":enemy["hp"],"movement_logic":"approach","contact_damage":0.0},true);game.enemies.append(enemy)
	var start:int=Time.get_ticks_usec()
	for i in 300:Coll.move_body(Vector2(300,500),Vector2(90,40),1.0/60,Vector2(34,42),obstacles)
	var collision:float=(Time.get_ticks_usec()-start)/300.0
	start=Time.get_ticks_usec()
	for i in 40:Flight.steer(game.enemies[0],Vector2(600,500),Vector2(40,0),Vector2(34,42),obstacles,1.0/60)
	var steering:float=(Time.get_ticks_usec()-start)/40.0
	var near:Array=obstacles.duplicate();near.append(Rect2(130,50,30,700));var bird:Dictionary=game.enemies[1];bird["pos"]=Vector2(175,450)
	start=Time.get_ticks_usec()
	for i in 12:Flight.steer(bird,Vector2(600,500),Vector2(40,0),Vector2(34,42),near,1.0/60)
	var near_steering:float=(Time.get_ticks_usec()-start)/12.0
	for i in 3:game._update_enemies(1.0/60,1.0/60)
	var samples:Array=[]
	for batch in 5:
		start=Time.get_ticks_usec()
		for i in 6:game._update_enemies(1.0/60,1.0/60)
		samples.append((Time.get_ticks_usec()-start)/6000.0)
	samples.sort()
	var probe:=CornerProbe.new()
	for i in 80:probe.scene["art_corners_v21"].append({"pos":Vector2((i%10)*100,100+int(i/10)*100),"angle":float(i%4)*PI*.5,"inner":i%2==0})
	root.add_child(probe)
	for i in 5:probe.queue_redraw();await process_frame
	var corner_times:Array=probe.times.slice(1);corner_times.sort()
	print(JSON.stringify({"actors":80,"surfaces":obstacles.size(),"collision_usec_per_body":collision,"flight_usec_per_body":steering,"near_wall_flight_usec_per_body":near_steering,"enemy_update_ms_median":samples[2],"enemy_update_ms_samples":samples,"corner80_rebuild_ms":float(corner_times[int(corner_times.size()/2)])/1000.0,"note":"headless CPU timings; not WebGL FPS"}))
	probe.queue_free();game.queue_free();await process_frame;quit()
