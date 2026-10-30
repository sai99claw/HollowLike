extends SceneTree
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func run() -> void:
	check(ProjectSettings.get_setting("display/window/stretch/mode")=="canvas_items","2D content renders at the actual output resolution")
	check(ProjectSettings.get_setting("display/window/size/window_width_override")==1920 and ProjectSettings.get_setting("display/window/size/window_height_override")==1080,"Default native window is 1080p")
	root.size=Vector2i(1920,1080)
	await process_frame
	check(root.get_visible_rect().size.is_equal_approx(Vector2(1280,720)),"Gameplay and interface retain the1280x720 logical coordinate system")
	var stretch:Transform2D=root.get_stretch_transform()
	check(stretch.get_scale().is_equal_approx(Vector2(1.5,1.5)),"Native1080 canvas scale is1.5 rather than a720p render target")
	check((stretch.affine_inverse()*Vector2(960,540)).is_equal_approx(Vector2(640,360)),"Physical input maps back to the same logical center")
	for path:String in ["res://assets/v33/home/background.png","res://assets/v33/home/framing.png","res://assets/v33/safehouses/trunk-background.png","res://assets/v33/safehouses/underground-stations.png"]:
		var tex:Texture2D=load(path)
		check(tex.get_image().get_width()==1536,"Full-size painted scene survives import: "+path)
	# These authored atlas rectangles are already imported without shrink. Guard
	# the real issue rather than rescaling metadata that already matches pixels.
	var atlas:Texture2D=load("res://assets/v22/action-walk.png")
	check(atlas.get_size().is_equal_approx(Vector2(1448,1086)),"Character atlas retains original sampling coordinates")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game)
	await process_frame;game.set_process(false);game.set_physics_process(false)
	check(game.ui.ui_root.size.is_equal_approx(Vector2(1280,720)),"HD does not expand or displace interface anchors")
	check(game.lab_buttons.get_child_count()==2,"Home retains practice and restores direct RD access")
	check(game.lab_buttons.get_child(1).text=="RD 美術室","Home RD button is clearly labelled")
	game.lab_buttons.get_child(1).pressed.emit();await process_frame
	check(game.lab_mode=="rd" and game.rd_view!=null,"Restored home shortcut opens the actual art room")
	game.rd_view._close();await process_frame
	if DisplayServer.get_name()!="headless":
		game._process(0);game._invalidate_scene();game.queue_redraw()
		for frame:int in 3:await process_frame
		await RenderingServer.frame_post_draw
		var image:Image=root.get_texture().get_image()
		check(image.get_size()==Vector2i(1920,1080),"Actual rendered framebuffer is1920x1080")
		if OS.get_cmdline_user_args().has("--capture"):
			DirAccess.make_dir_recursive_absolute("/tmp/pigeon-display-qa")
			image.save_png("/tmp/pigeon-display-qa/home-hd.png")
	game.queue_free();await process_frame
	print("HD display checks: ",failures)
	quit(0 if failures.is_empty() else 1)
