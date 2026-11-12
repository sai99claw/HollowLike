extends SceneTree

const Slash=preload("res://scripts/slash_art_v18.gd")
const Pose=preload("res://scripts/adventure_visual.gd")
const Wall=preload("res://scripts/pigeon_motion_v22.gd")
const Wind=preload("res://scripts/wind_art.gd")
const Collision=preload("res://scripts/world_collision.gd")
const Stones=preload("res://scripts/throwable_stones.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
const Viewer=preload("res://scripts/rd_room_v16.gd")
const Data=preload("res://scripts/game_data.gd")
const FX=preload("res://scripts/combat_visual.gd")

var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")

func check(ok:bool,message:String) -> void:
	if ok:return
	failures.append(message)
	push_error(message)

func test_motion() -> void:
	check(Pose.jump_frame(0)==1 and Pose.jump_frame(2.0)==2,"Takeoff uses original frames two and three")
	check(is_equal_approx(Wind.OVERLAY_TINT.a,.9),"Both double C overlays use ninety percent opacity")
	check(is_equal_approx(preload("res://scripts/explosion_v16.gd").OPACITY,.9),"Explosion art uses ninety percent opacity")
	var idle=preload("res://scripts/pigeon_idle_v19.gd")
	for i in 20:
		check(idle.frame_index((i+.5)/5.0)==int("12356765321235676532"[i])-1,"Idle follows the authored sequence at 5 FPS")
	check(idle.frame_index(5.0)==1,"Rest skips its first frame")
	for i in 9:
		check(Pose.slam_frame((i+.5)/24.0)==mini(i,2),"Dive advances through poses one and two, then holds three")
	var expected:Array=[0,1,3,5,6,7]
	for i in 6:
		check(Wind.form_index((i+.5)*.04,.24,false)==expected[i],"Horizontal wind plays the six visible frames")
		check(Wind.form_index((i+6.5)/24.0,.24,true)==expected[i],"Vertical wind loops the same six frames")
	for i in 9:
		check(Wall.wall_frame(false,(i+.5)/8.0)==[0,2,3,2,0,2,3,2,0][i],"Sliding uses the specified 8 FPS sequence")
	check(Wall.wall_frame(true,5.0)==0,"Holding uses the first wall frame")
	for i in 6:
		var attack:Dictionary=Data.action_attack("right",false,false,i)
		check(attack["combo"]==i%2,"Horizontal primary attacks alternate two regular strikes")
		check(FX.player_clip(attack["style"],attack,"active")==["pigeon_feather_left","pigeon_feather_right"][i%2],"Ordinary strikes restore the old A1 and A2 art")
	for direction:String in ["up","down"]:
		var attack:Dictionary=Data.action_attack(direction,false,false)
		check(FX.player_clip(attack["style"],attack,"active")=="pigeon_featherblade_"+direction,"Vertical strikes restore the old featherblade poses")
	var charged:Dictionary=Data.action_attack("right",true,false,0)
	check(charged["great_spin_release"] and not charged.has("body_clip"),"Charged releases keep their separate pose")

func test_collision() -> void:
	var target:=Rect2(100,100,20,20)
	check(not Collision.circle_overlaps_rect(Vector2(92,92),10,target),"Circle rejects AABB corner overlap")
	check(Collision.swept_circle_rect(Vector2(88,91),Vector2(95,91),10,target)==INF,"Moving stone misses a diagonal corner outside its radius")
	check(Collision.swept_circle_rect(Vector2(60,94),Vector2(105,94),10,target)<1.0,"Moving stone detects contact with a round corner")
	var floor_box:=Rect2(0,150,300,30)
	var stone:Dictionary={"pos":Vector2(100,90),"large":false,"vel":Vector2(0,540),"damage":1.0,"asleep":false}
	var path:PackedVector2Array=Stones.step(stone,.2,[floor_box])
	check(path.size()>2 and stone["pos"].y<=150 and stone["vel"].y<0,"Stone sweeps to the floor and bounces at its circular contact")
	var near_circle:Array[Vector3]=[Vector3(100,100,10)]
	var slide:Dictionary=Collision.move_body(Vector2(87,91),Vector2.RIGHT*150,.02,Vector2(4,4),[],0,false,near_circle)
	check(slide["pos"].x>88,"Player can pass inside the stone's bounding box but outside the circular edge")

func test_viewer() -> void:
	var viewer:=Viewer.new()
	root.add_child(viewer)
	viewer.set_process(false)
	for group:String in Catalog.GROUPS:
		check(not Catalog.categories(group).is_empty(),"Each of the five groups has child categories")
	for item:Dictionary in Catalog.all_entries():
		check(item["group"] in Catalog.GROUPS and not str(item["usage_note"]).is_empty(),"Every item has a group and usage note")
	check(Catalog.entry("pigeon_action:1")["frame_count"]==10,"Limping atlas exposes ten frames")
	check(Catalog.sequence(Catalog.entry("v68:pigeon:jump_rise"))==[1,2],"RD takeoff skips the first and fourth frames")
	check(Catalog.sequence(Catalog.entry("walk_v2:pigeon_walk_master"))==[6,2,7,8,9],"RD walk order matches gameplay")
	for i in 4:
		var clip:Dictionary=Catalog.entry("v70:pigeon:attack:"+str(i))
		check(clip["frame_count"]==2 and Catalog.frame(clip,0)!=null and Catalog.frame(clip,1)!=null,"Each of the four attacks exposes two exported sprites")
	var slash:Dictionary=Catalog.entry("slash:v18")
	check(slash["fps"]==20 and Catalog.sequence(slash)==[0,1,2,4] and slash["group"]=="主角" and "用途/特效" in slash["tags"],"RD catalogs the slash under the protagonist with the specified four-frame order")
	viewer._include_menu.get_popup().id_pressed.emit(viewer.tag_options.find("歸屬/主角"))
	viewer._include_menu.get_popup().id_pressed.emit(viewer.tag_options.find("用途/特效"))
	viewer._exclude_menu.get_popup().id_pressed.emit(viewer.tag_options.find("使用狀態/未使用"))
	check(slash in viewer.filtered_entries and not Catalog.entry("v70:pigeon:attack:0") in viewer.filtered_entries,"The menus combine multiple inclusions with an exclusion")
	viewer.select_entry("slash:v18")
	viewer.set_custom_tag("動作驗收",true)
	var custom_index:int=viewer.tag_options.find("自訂/動作驗收")
	check(custom_index>=0,"Custom tags are available as filters")
	viewer._include_menu.get_popup().id_pressed.emit(custom_index)
	check(viewer.filtered_entries==[slash],"A custom tag combines with the existing filters")
	var saved:=ConfigFile.new()
	check(saved.load(viewer.TAG_FILE)==OK and "動作驗收" in saved.get_value("art","tags",{}).get("slash:v18",[]),"The custom tag persists on this device")
	viewer.set_custom_tag("動作驗收",false)
	viewer.clear_filters()
	viewer.select_entry("wind:form")
	viewer.pause();viewer.set_fps(10);viewer.seek_frame(1);viewer.play()
	viewer._process(.101)
	check(viewer.frame_index==3,"Hidden frame occupies zero seconds")
	viewer.pause();viewer.seek_frame(0)
	for code:int in [KEY_C,KEY_V]:
		var event:=InputEventKey.new()
		event.keycode=code
		event.ctrl_pressed=true
		event.pressed=true
		viewer._input(event)
	check(viewer._timeline.size()==9 and viewer._timeline[1]["source"]==0,"Ctrl+C and Ctrl+V insert an independent copy")
	viewer.move_frame(1,viewer._timeline.size())
	check(viewer.frame_index==8 and viewer._timeline[8]["source"]==0,"Moving a frame after the last item preserves its source")
	viewer.seek_frame(2);viewer.play()
	check(viewer._preview.texture!=null and viewer._thumb_buttons[viewer.frame_index].modulate==Color.WHITE,"Current playback frame is highlighted")
	viewer.queue_free()

func test_game() -> void:
	var game=load("res://main.tscn").instantiate()
	game.audio_enabled=false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.practice_mode=true
	game.new_run("rogue",68068)
	game._close_panel()
	game.solids.assign([Rect2(500,200,90,700)])
	game.platforms.clear()
	game.props.clear()
	game._reset_player(Vector2(483,450))
	game.p["grounded"]=false
	game.p["vel"]=Vector2(0,120)
	game._step_player(1.0/120)
	check(game.p["wall"]==1 and is_equal_approx(game.p["wall_hold_left"],.5) and is_zero_approx(game.p["vel"].y),"Wall latches and holds for half a second")
	for i in 61:game._step_player(1.0/120)
	check(is_equal_approx(game.p["vel"].y,43.2),"Wall slide velocity is 20% faster")
	game._reset_player(Vector2(700,450))
	game.p["grounded"]=false
	game.p["energy"]=6
	game._begin_dash_followup(Vector2.DOWN)
	game._step_player(1.0/120)
	check(is_equal_approx(game.p["vel"].y,(520.0+2100.0/120)*1.5),"Live down-dive applies the 1.5 speed multiplier")
	game.p_attack.cancel()
	game._reset_player(Vector2(700,850))
	game.jump_request=true
	game._step_player(1.0/120)
	check(game.p["jump_rise_age"]==0.0 and game.p["vel"].y<0,"Ground jump starts the rising animation immediately")
	game._reset_player(Vector2(700,430))
	game.p["grounded"]=false
	game.p["vel"]=Vector2(0,240)
	game.keys["jump"]=true
	game._step_player(1.0/120)
	check(game.p["gliding"] and is_equal_approx(game.p["vel"].y,120),"Holding Space while falling starts ordinary glide")
	game.keys["jump"]=false
	game._step_player(1.0/120)
	check(not game.p["gliding"] and game.p["vel"].y>120,"Releasing Space resumes falling")
	game._reset_player(Vector2(700,430))
	for i in 6:
		game._begin_primary({"dir":"right","charged":false})
		check(game.p_attack.attack["body_clip"]==["pigeon_feather_left","pigeon_feather_right"][i%2],"Live controller alternates legacy body poses")
		game.p_attack.cancel()
	var slash_canvas:=Node2D.new()
	root.add_child(slash_canvas)
	slash_canvas.draw.connect(game._paint_player_slash.bind(slash_canvas))
	for direction in ["right","up","down"]:
		game._begin_primary({"dir":direction,"charged":false})
		game.p_attack.tick(float(game.p_attack.attack["windup"])+.001)
		check(game.p_attack.is_active(),"Ordinary attack is in its visible strike phase")
		Slash.texture=null
		game.p_attack.cancel()
		slash_canvas.queue_redraw()
		await process_frame
		await process_frame
		check(Slash.texture!=null,"Ordinary "+direction+" attack draws the retained slash even after its hit phase ends")
		game.p_attack.cancel()
	for i in 4:
		check(Slash.frame_at((i+.5)/20.0)==[0,1,2,4][i],"Slash draws source frames 1, 2, 3, and 5 at 20 FPS")
	check(Slash.frame_at(.2)==-1,"Slash expires after four frames")
	check(Catalog.entry("v72:wing_impulse").get("frame_count",0)==4 and Catalog.entry("v72:impact_feathers").get("frame_count",0)==4,"RD shows both four-frame feather effects")
	slash_canvas.queue_free()
	game._leave_lab()
	if game.screen!="hub":game._ui_action("hub",null)
	game._enter_practice(true)
	game.view_rect=Rect2(-100,-100,3000,2000)
	var target:Dictionary=game.enemies[0]
	target["frost_left"]=2.0
	target["frost_pose_clock"]=0.0
	game._hit_enemy(target,9999,Color.WHITE)
	game._sync_enemy_canvases()
	check(game.enemy_canvases.has(target["uid"]) and game.enemy_canvases[target["uid"]].material!=null,"Frozen target still turns white on lethal damage")
	game._update_hit_white(1.0/60.0)
	check(target["flash_left"]>0,"First elapsed tick preserves the second white frame")
	game._update_hit_white(1.0/60.0)
	game._sync_enemy_canvases()
	check(not game.enemy_canvases.has(target["uid"]),"Lethal target is removed from the flash canvas after two ticks")
	game.queue_free()
	await process_frame

func run() -> void:
	test_motion()
	test_collision()
	test_viewer()
	await test_game()
	print("v68 motion, circles, flash and RD: ",failures)
	quit(0 if failures.is_empty() else 1)
