extends SceneTree
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Art=preload("res://scripts/monster_art_v36.gd")
const Attack=preload("res://scripts/attack_state.gd")
const OUT="/tmp/pigeon-monster-qa"
class Plate extends Node2D:
	var biome:String="underground"
	var mode:String="regular"
	var font:Font=load("res://assets/Chinese.otf")
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,720),Color("14272d"));draw_string(font,Vector2(36,46),biome+" / "+mode,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("eee4c6"))
		if mode=="projectiles":
			var data:Dictionary=Art.manifest(biome);var row:int=0
			for id:String in data["projectiles"]:
				var spec:Dictionary=data["projectiles"][id];draw_string(font,Vector2(18,128+row*80),id,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b8cbd0"))
				for i in 8:Art.draw_projectile(self,{"visual_id":"v36:"+biome+":"+id,"pos":Vector2(230+i*135,145+row*80),"vel":Vector2.RIGHT,"radius":17.0,"elapsed":(float(i)+.01)/float(spec["fps"]),"launch_angle":0.0},Transform2D.IDENTITY)
				row+=1
			return
		var elite:bool=mode=="elite"
		for i in 4:draw_string(font,Vector2(180+i*280,96),["移動","前搖","攻擊","收招"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
		for row in (4 if elite else 5):
			var source:Dictionary=Roster.elite(Roster.BIOMES.find(biome)*2+row/2) if elite else Roster.regular(biome,row)
			draw_string(font,Vector2(28,150+row*108),source["name"]+(" · %d"%[row%2+1] if elite else ""),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b8cbd0"))
			for col in 4:
				var actor:Dictionary=source.duplicate(true);actor.merge({"pos":Vector2(230+col*280,195+row*108),"vel":Vector2(30,0),"face":1.0,"hurt":0.0,"attack":Attack.new()},true)
				if col>0:
					var d:Dictionary=source["attacks"][row%2 if elite else 0];actor["attack"].begin(d)
					var elapsed:float=float(d["windup"])*.55
					if col==2:elapsed=float(d["windup"])+float(d["active"])*.5
					if col==3:elapsed=float(d["windup"])+float(d["active"])+float(d["recovery"])*.5
					actor["attack"].tick(elapsed)
				Art.draw_actor(self,actor,.2)
				if col==2:Art.draw_melee(self,actor["pos"],actor["attack"],1,Transform2D.IDENTITY)
func _initialize() -> void:call_deferred("run")
func snap(label:String) -> void:
	for i in 3:await process_frame
	await RenderingServer.frame_post_draw
	var image:Image=root.get_texture().get_image();assert(image.get_size()==Vector2i(1920,1080));image.save_png(OUT+"/"+label+".png");print("CAPTURE ",label)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT);var plate:=Plate.new();root.add_child(plate)
	for biome:String in Roster.BIOMES:
		for mode:String in ["regular","elite","projectiles"]:
			plate.biome=biome;plate.mode=mode;plate.queue_redraw();await snap(biome+"-"+mode)
	plate.queue_free();await process_frame
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false)
	game.home_sleeping=false;game.home_wake_left=0;game._reset_player(Vector2(640,600));game._process(0);game._invalidate_scene();game.queue_redraw();await snap("home1080")
	game.new_run("rogue",171);game._close_panel()
	for stage:int in [0,2,4]:
		var target:Dictionary=game.tower["rooms"].filter(func(r:Dictionary)->bool:return r["type"]=="combat" and int(r["map_index"])==stage)[0]
		game._enter_room(target["id"]);game._close_panel();var live:Array=game.enemies.filter(func(en:Dictionary)->bool:return en.has("roster_id"))
		if not live.is_empty():game._reset_player(live[0]["pos"]+Vector2(-100,0))
		game.camera_pos=game._camera_target(game.p["pos"]);game.shake=0;game._process(0);game._invalidate_scene();game.queue_redraw();await snap("combat-stage"+str(stage))
	game.queue_free();await process_frame;quit()
