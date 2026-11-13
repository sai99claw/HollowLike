extends SceneTree

var game: Node2D
var output := "/tmp/pigeon-vfx-frames"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("VFX capture requires a rendering display.")
		quit(2)
		return
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.new_run("rogue",171)
	var target: Dictionary = {}
	for candidate: Dictionary in game.tower["rooms"]:
		if candidate.get("fountain",false) and int(candidate["map_index"])==2:
			target = candidate
			break
	if target.is_empty():
		for candidate: Dictionary in game.tower["rooms"]:
			if candidate["type"]=="combat":
				target = candidate
				target["fountain"]=true
				break
	game._enter_room(int(target["id"]))
	game._close_panel()
	var pool: Rect2 = game._active_pool()
	if not pool.has_area():
		push_error("No water basin in selected test room.")
		quit(2)
		return
	game.enemies.clear()
	game.p["pos"] = Vector2(pool.get_center().x,pool.end.y)
	game.camera_pos = game._camera_target(game.p["pos"])
	game.p["invul"] = 0
	game.shake = 0
	game._invalidate_scene()
	for i in 3:
		game.draw_clock=2.0+float(i)*.2
		game._process(0)
		await RenderingServer.frame_post_draw
	game.bath.attack(pool,game.p["pos"])
	game.bath.step(pool,game.p["pos"],Vector2.ZERO,.11)
	await _capture("01-water")
	game.p["pos"]=Vector2(pool.position.x-55,game.layout["floor_y"])
	game.keys["attack"]=true
	game.charge_timer=1.7
	await _capture("02-charge")
	game.keys["attack"]=false
	game.charge_timer=0
	var center:=pool.get_center()-Vector2(0,126)
	game._explode(center+Vector2(125,15),119,0,0,true)
	game.poison_clouds.append({"pos":center-Vector2(122,-30),"left":2.5,"hostile":true})
	var shot:Dictionary={"pos":center+Vector2(78,-51),"vel":Vector2(440,40),"color":Color("83e4f3"),"elapsed":.31,"kind":"shot","radius":8.5,"from_player":true,"life":1.0,"weapon_id":"", "trail_clock":.27}
	var read:=preload("res://scripts/projectile_readability_v25.gd")
	for i in 13:
		var previous:Vector2=Vector2(shot["pos"])-Vector2((13-i)*10,8*sin(i*.2))
		var next:Vector2=Vector2(shot["pos"])-Vector2((12-i)*10,8*sin((i+1)*.2))
		read.record(shot,previous,next,.018)
	game.projectiles.append(shot)
	for i in 8:
		game._update_visual_effects(.041)
		game.draw_clock+=.041
		await _capture("03-effects-%02d"%i)
	quit(0)

func _capture(label:String) -> void:
	game.shake=0
	game._process(0)
	await RenderingServer.frame_post_draw
	var frame:=root.get_texture().get_image()
	if frame.is_empty() or frame.save_png(output.path_join(label+".png"))!=OK:
		push_error("Unable to save rendered frame "+label)
