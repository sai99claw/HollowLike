extends SceneTree

var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")

func check(value:bool,message:String) -> void:
	if value:return
	failures.append(message)
	push_error(message)

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.audio_enabled=false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	var camera_before:float=game.camera_zoom
	game.meta["settings"].erase("display_zoom")
	game._load_settings()
	check(game.display_zoom==1.0,"Existing settings migrate to 1.00 display zoom")

	game.menu_category="display"
	game._ui_action("display_fit","cover")
	await process_frame
	var field:=game.ui.panel_rows.find_child("DisplayZoomInput",true,false) as LineEdit
	check(field!=null,"Cover mode offers a custom numeric field")
	if field==null:
		quit(1)
		return
	field.text_submitted.emit("1.37")
	check(is_equal_approx(game.display_zoom,1.37) and game.meta["settings"]["display_zoom"]==1.37,"An arbitrary decimal is applied and saved")
	field.text_submitted.emit("invalid")
	field.text_submitted.emit("0.9")
	check(is_equal_approx(game.display_zoom,1.37),"Invalid and sub-cover input preserves the active zoom")
	game.display_zoom=1.0
	game._load_settings()
	check(is_equal_approx(game.display_zoom,1.37),"Saved decimal reloads")
	check(game.camera_zoom==camera_before,"Display zoom is independent of the world camera")
	for dimensions:Vector2i in [Vector2i(1024,768),Vector2i(1920,1080),Vector2i(2304,960),Vector2i(720,1280),Vector2i(1111,777)]:
		root.size=dimensions
		await process_frame
		game._update_safe_interface()
		var pixel_from_game:Transform2D=root.get_final_transform()
		var applied:Vector2=pixel_from_game.get_scale()
		var expected:float=maxf(dimensions.x/1280.0,dimensions.y/720.0)*1.37
		check(absf(applied.x-applied.y)<.002 and absf(applied.x-expected)<.003,"Cover scales uniformly at %s"%str(dimensions))
		check((pixel_from_game*Vector2(640,360)).distance_to(Vector2(dimensions)*.5)<=2,"Cover crop stays centered at %s"%str(dimensions))
		var safe:Rect2=game.display_safe
		check((pixel_from_game*safe.position).length()<=2 and (pixel_from_game*safe.end).distance_to(Vector2(dimensions))<=2,"Safe rectangle maps to physical edges at %s"%str(dimensions))
		check(game.ui.ui_root.position==safe.position,"Settings and HUD stay within the visible crop")

	game._ui_action("display_fit","contain")
	game._update_safe_interface()
	check(root.content_scale_factor==1.0 and root.content_scale_aspect==Window.CONTENT_SCALE_ASPECT_KEEP and root.global_canvas_transform==Transform2D.IDENTITY,"Contain restores the default transform")
	check(game.display_safe==Rect2(0,0,1280,720) and game.display_zoom==1.37,"Contain shows the full frame and retains the saved cover zoom")
	game.queue_free()
	await process_frame
	print("Display zoom: ",failures)
	quit(0 if failures.is_empty() else 1)
