extends SceneTree
const OUT:String="/tmp/pigeon38-qa"
const Hit=preload("res://scripts/hit_art_v37.gd")
const Feedback=preload("res://scripts/combat_feedback.gd")
const Monster=preload("res://scripts/monster_art_v36.gd")
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Laser=preload("res://scripts/laser_art_v38.gd")
const Adventure=preload("res://scripts/adventure_visual.gd")
class Plate extends Node2D:
	var mode:String="hit";var phase:int=0;var clock:float=2
	var font:Font=load("res://assets/Chinese.otf")
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,720),Color("19332d"));draw_string(font,Vector2(30,45),"v38 · "+mode,HORIZONTAL_ALIGNMENT_LEFT,-1,22)
		if mode=="hit":
			for i in 2:
				var en:Dictionary=Roster.regular("underground",0);en["pos"]=Vector2(350+i*600,440);en["face"]=1 if i==0 else -1;en["vel"]=Vector2.ZERO
				Monster.draw_actor(self,en,0);var at:Vector2=en["pos"]-Vector2(0,25);var spray:Vector2=Vector2.LEFT if i==0 else Vector2.RIGHT
				Hit.draw(self,{"at":at,"spray_at":Feedback.spray_origin(en,at,spray),"dir":spray,"angle":spray.angle()+.15,"max":.18,"life":.18-(float(phase)*.055+.01),"length":1280.0/3,"feathers":true},Transform2D.IDENTITY)
		elif mode=="double-jump":
			preload("res://scripts/double_jump_v27.gd").draw(self,Vector2(640,320),1,.12,Transform2D.IDENTITY,Color.WHITE)
		elif mode=="portals":
			for i in 3:
				var at:=Vector2(220+i*410,440);Adventure.portal(self,at,[Color("ddb46e"),Color("8edca4"),Color("9cdbff")][i],clock,Transform2D.IDENTITY,"underground","left",64,false)
				draw_rect(Rect2(at-Vector2(3,80),Vector2(6,100)),Color("66766b"))
		elif mode=="laser":
			var starts:Array[Vector2]=[Vector2(120,140),Vector2(1160,260),Vector2(180,640),Vector2(900,650)]
			var ends:Array[Vector2]=[Vector2(1150,140),Vector2(130,260),Vector2(800,360),Vector2(900,350)]
			for i in 4:Laser.draw(self,{"pos":starts[i],"end":ends[i],"width":19.1,"max":.34,"life":.34-float(phase)/24},Transform2D.IDENTITY)
func _initialize() -> void:call_deferred("run")
func snap(label:String) -> void:
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+label+".png");print("CAPTURE ",label)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT);var plate:=Plate.new();root.add_child(plate)
	for i in 3:plate.phase=i;plate.queue_redraw();await snap("hit"+str(i))
	plate.mode="laser"
	for i in 8:plate.phase=i;plate.queue_redraw();await snap("laser"+str(i))
	plate.mode="portals"
	for i in 2:plate.clock=2+i;plate.queue_redraw();await snap("portal"+str(i))
	var feedback:=Feedback.new();plate.add_child(feedback);plate.mode="double-jump";plate.queue_redraw();feedback.double_jump(Vector2(640,320))
	await create_timer(.16).timeout;await snap("downward-feathers");plate.queue_free();await process_frame
	var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.practice_mode=true;g.new_run("rogue",380038);g._close_panel();g.p["invul"]=0;g.shake=0;g._process(0);g._invalidate_scene();await snap("primary-idle")
	g.bag_runes={"gale":3,"reach":2,"guard":1};g.revive_used=true;g._death();g.life_event["landed"]=true;g.life_event["land_time"]=0;g._update_life_event(.4);g.queue_redraw();await snap("death-feather")
	g._update_life_event(.72);g.queue_redraw();await snap("death-rune-grid")
	g._choose_soul_rune("gale");g._update_life_event(1.41);g._process(0);g._invalidate_scene();await snap("soul-safehouse")
	g.queue_free();await process_frame;quit()
