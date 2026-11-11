extends SceneTree

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
	for i in 4:check(Pose.jump_frame((i+.5)/Pose.JUMP_FPS)==i,"Every takeoff pose is sampled in order")
	check(Pose.jump_frame(2.0)==3,"Fourth takeoff pose holds through ascent")
	for i in 9:
		check(Pose.slam_frame((i+.5)/24.0)==mini(i,2),"Dive advances through poses one and two, then holds three")
	var expected:Array=[0,1,3,5,6,7]
	for i in 6:
		check(Wind.form_index((i+.5)*.04,.24,false)==expected[i],"Horizontal wind plays the six visible frames")
		check(Wind.form_index((i+6.5)/24.0,.24,true)==expected[i],"Vertical wind loops the same six frames")
	for i in 9:
		check(Wall.wall_frame(false,(i+.5)/8.0)==[0,2,3,2,0,2,3,2,0][i],"Sliding uses the specified 8 FPS sequence")
	check(Wall.wall_frame(true,5.0)==0,"Holding uses the first wall frame")
	for i in 3:
		var attack:Dictionary=Data.action_attack("right",false,false,i)
		check(FX.player_clip(attack["style"],attack,"active")==["pigeon_feather_left","pigeon_feather_right","pigeon_feather_thrust"][i],"Legacy feather sprites are the current horizontal combo")
	for direction:String in ["up","down"]:
		for during_dash:bool in [false,true]:
			var attack:Dictionary=Data.action_attack(direction,false,during_dash)
			var family:String="greatblade" if during_dash else "featherblade"
			check(FX.player_clip(attack["style"],attack,"active")=="pigeon_"+family+"_"+direction,"Directional attack uses the appropriate feather or greatblade clip")

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
	check(Catalog.entry("pigeon_action:1")["frame_count"]==8,"Limping atlas exposes all eight frames")
	check(Catalog.entry("v68:pigeon:jump_rise")["frame_count"]==4,"Jump atlas exposes all four frames")
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
