extends SceneTree
const Animated=preload("res://scripts/projectile_animation_v31.gd")
const Art=preload("res://scripts/weapon_art_v24.gd")
const Feedback=preload("res://scripts/combat_feedback.gd")
var failures:Array[String]=[]
class Preview:
	extends Node2D
	var painted:bool=false
	func _draw() -> void:
		for i in Animated.IDS.size():
			var id:String=Animated.IDS[i]
			for f in 8:Art.draw(self,id,Vector2(40+f*65,40+i*45),Vector2.RIGHT,10,true,Transform2D(0,Vector2(20,10)),(f+.25)/float(Animated.FPS[id]))
		painted=true
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func run() -> void:
	for id:String in Animated.IDS:
		var data:Dictionary=Animated.definition(id);var tex:Texture2D=Animated.texture(id)
		check(data["frames"].size()==8 and tex!=null,"Eight-frame asset packaged: "+id)
		var original:=Vector2(data["original_size"][0],data["original_size"][1]);var ratio:Vector2=tex.get_size()/original
		var hashes:Array[int]=[];var pixels:Image=tex.get_image()
		for f in 8:
			var frame:Dictionary=data["frames"][f];var r:Array=frame["rect"];var p:Array=frame["pivot"]
			check(r[0]>=0 and r[1]>=0 and r[0]+r[2]<=original.x+1 and r[1]+r[3]<=original.y+1,"Frame stays inside atlas")
			check(p[0]>=0 and p[0]<=r[2] and p[1]>=0 and p[1]<=r[3],"Pivot is local and bounded")
			var region:=Rect2i(Vector2(r[0],r[1])*ratio,Vector2(r[2],r[3])*ratio)
			var sample:Image=pixels.get_region(region);check(sample.get_used_rect().has_area(),"Frame contains visible art")
			hashes.append(hash(sample.get_data()))
			check(Animated.frame_index(id,(f+.25)/float(Animated.FPS[id]))==f,"Animation advances in authored order")
		var unique:Dictionary={}
		for value:int in hashes:unique[value]=true
		check(unique.size()>=7,"Frames are individually drawn, not eight identical static sprites: "+id)
		check(Animated.frame_index(id,0)==Animated.frame_index(id,8.01/float(Animated.FPS[id])),"Full cycle wraps without skipping")
	check(Animated.ROTATION["impact_bomb"]!=Animated.ROTATION["trap_pod"] and Animated.ROTATION["ricochet"]!=Animated.ROTATION["moonblade"],"Thrown families use distinct spin directions")
	check(is_equal_approx(Animated.angle("fire_flask",Vector2.DOWN,.3),.3),"A bottle does not snap to the changing arc tangent")
	check(is_equal_approx(Animated.angle("homing_missile",Vector2.DOWN,0),PI*.5),"Guided projectile nose follows travel")
	check(not Animated.has("chain_staff") and not Animated.has("piercing_laser"),"Instant beams are not treated as rotating bodies")
	var feedback:=Feedback.new();root.add_child(feedback)
	var pr:Dictionary={"pos":Vector2(300,250),"vel":Vector2.RIGHT*400,"radius":5.09375,"weapon_id":"impact_bomb","color":Color.ORANGE}
	var ribbon:=preload("res://scripts/projectile_readability_v25.gd")
	ribbon.record(pr,Vector2(280,240),Vector2(293,243),.04)
	ribbon.record(pr,Vector2(293,243),pr["pos"],.04)
	feedback.finish_trail(pr)
	check(feedback.fading_ribbons[0]["trail_points"][-1]==pr["pos"],"Rotating weapon keeps its own world-space trail")
	feedback.step(.3)
	check(feedback.fading_ribbons.is_empty(),"Impact tail fades without leaving an emitter")
	var view:=Preview.new();root.add_child(view);await process_frame;await process_frame
	check(view.painted,"Actual CanvasItem draws all fifty-six frames through the runtime adapter")
	feedback.clear();feedback.queue_free();view.queue_free();await process_frame
	print("v31 projectile animation: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
