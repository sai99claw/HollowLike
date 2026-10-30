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
	print("Projectile readability: ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
