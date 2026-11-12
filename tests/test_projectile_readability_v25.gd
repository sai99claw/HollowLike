extends SceneTree
const Readability=preload("res://scripts/projectile_readability_v25.gd")
const WeaponArt=preload("res://scripts/weapon_art_v24.gd")
const Arsenal=preload("res://scripts/arsenal_v24.gd")
var failures:Array[String]=[]
class Preview:
	extends Node2D
	var projectile:Dictionary={}
	var painted:bool=false
	func _draw() -> void:
		Readability.draw_trail(self,projectile,Transform2D.IDENTITY)
		Readability.draw_cue(self,projectile,Transform2D.IDENTITY);painted=true
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func run() -> void:
	for id:String in Arsenal.IDS:
		var image:Texture2D=WeaponArt.texture(id,true);var extent:Vector2=Readability.sprite_extent(image.get_size(),Readability.BASE_RADIUS)
		check(is_equal_approx(maxf(extent.x,extent.y),Readability.PLAYER_HEIGHT/4.0*1.5),"Every weapon projectile has a readable long axis: "+id)
		check(minf(extent.x,extent.y)>0,"Long projectiles retain a visible body thickness: "+id)
	var pr:Dictionary={"pos":Vector2(100,100),"radius":8.0,"damage":2.0,"from_player":true,"color":Color.CYAN}
	for i in 120:
		var old:Vector2=pr["pos"];pr["pos"]+=Vector2(8,sin(i*.1)*3);Readability.record(pr,old,pr["pos"],1.0/120)
	check(pr["radius"]==8 and pr["damage"]==2,"Readability does not enlarge damage or collision volume")
	check(Readability.visual_radius(pr)==8,"Small player projectiles receive a visible body minimum")
	check(pr["trail_points"].size()<=32 and pr["trail_points"].size()>10,"Trajectory has bounded but continuous multi-point geometry")
	check(pr["trail_points"][-1]==pr["pos"],"Trail ends at actual projectile position")
	check(pr["trail_clock"]-pr["trail_times"][0]<=Readability.TRAIL_SECONDS+.02,"Old trajectory samples expire within the fixed window")
	var view:=Preview.new();view.projectile=pr;root.add_child(view)
	for i in 3:await process_frame
	check(view.painted,"Actual CanvasItem exercises the gradient trajectory draw path")
	view.queue_free();await process_frame
	var game=load("res://main.tscn").instantiate()
	game.audio_enabled=false
	root.add_child(game)
	await process_frame
	game.set_process(false);game.set_physics_process(false)
	game.new_run("rogue",75079)
	game.enemies.clear();game.platforms.clear();game.solids.clear()
	game._rebuild_projectile_surfaces()
	game.view_rect=Rect2(0,0,1280,720)
	game.p["pos"]=Vector2(700,600)
	game.low_effects=true
	game._emit_weapon(Vector2(180,220),Vector2.RIGHT,{"id":"needle"},true)
	game._emit_weapon(Vector2(180,280),Vector2.RIGHT,{"visual_id":"v36:underground:test"},false)
	game._emit_weapon(Vector2(180,340),Vector2.RIGHT,{"style_id":"flying_slash"},true)
	game._emit_traps({"pos":Vector2(180,420),"uid":-2},{"color":Color.CYAN,"size":16,"target":Vector2(430,520)})
	for i in 3:game._update_projectiles(1.0/60.0)
	check(game.projectiles.size()==4,"Player shot, enemy shot, flying slash and trap carrier are in flight")
	for projectile:Dictionary in game.projectiles:
		var points:PackedVector2Array=projectile.get("trail_points",PackedVector2Array())
		check(points.size()>1 and points[-1]==projectile["pos"],"All flying projectile families record a trail in reduced mode")
	var stones=preload("res://scripts/throwable_stones.gd")
	var stone:Dictionary={"pos":Vector2(300,320),"large":false}
	stones.launch(stone,Vector2.RIGHT,2)
	game._step_stone(stone,1.0/60.0)
	check(stone["trail_points"].size()>1 and stone["trail_points"][-1]==stones.center(stone),"Airborne attackable stones also carry a trajectory trail")
	game.queue_free()
	await process_frame
	print("Projectile readability: ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
