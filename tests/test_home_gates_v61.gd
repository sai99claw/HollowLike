extends SceneTree

const HomeArt=preload("res://scripts/home_art.gd")
var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")

func check(value:bool,message:String) -> void:
	if not value:failures.append(message)

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio_enabled=false
	check(game.ui.ui_root.get_node_or_null("HomeModeButtons")==null,"Homepage has no separate mode buttons")
	var lab:Button=game.lab_buttons.get_child(0)
	var normal:StyleBoxFlat=lab.get_theme_stylebox("normal")
	var pressed:StyleBoxFlat=lab.get_theme_stylebox("pressed")
	check(normal.shadow_size>0 and pressed.shadow_size==0 and pressed.content_margin_top>normal.content_margin_top,"Remaining utility buttons keep press feedback")
	check(HomeArt.gate_at(HomeArt.LEFT_GATE.get_center())=="musou" and HomeArt.gate_at(HomeArt.RIGHT_GATE.get_center())=="tutorial" and HomeArt.gate_at(HomeArt.ROGUE_GATE.get_center())=="rogue","Painted gates have the correct targets")
	var feet:=Vector2(200,600)
	var size:=Vector2(95,147)
	check(HomeArt.falling_mote(feet,size,.2,0).y>HomeArt.falling_mote(feet,size,.1,0).y,"White motes descend")
	for index in 25:
		for step in 30:
			var at:=HomeArt.falling_mote(feet,size,step*.1,index)
			check(absf(at.x-feet.x)<size.x*.5 and at.y>feet.y-size.y and at.y<feet.y,"Mote stays inside the doorway")
	game.home_sleeping=false
	check(not game._home_interact() and game.screen=="hub","Rogue still requires reaching the elevated gate")
	check(HomeArt.LEFT_GATE.size==HomeArt.ROGUE_GATE.size and HomeArt.RIGHT_GATE.size==HomeArt.ROGUE_GATE.size,"All three portals share dimensions")
	check(game._camera_target(Vector2(640,114)).y<0,"Vertical camera tracks the upper landing")
	var lamp:Vector2=HomeArt.lamp_center(game.home_projector,game.clock)
	game._hit_props(Rect2(lamp-Vector2.ONE*5,Vector2.ONE*10),1)
	check(game.home_projector["used"],"An attack hit knocks down the lamp")
	game.p["pos"]=HomeArt.STATIONS["trophy"]
	check(game._home_interact() and game.trophy_room,"Trophy shrine has an independent entrance")
	check(game._home_interact() and not game.trophy_room and game.home_projector["used"],"Leaving the trophy room keeps the lamp knocked down")
	game.p["pos"]=feet
	game._set_action("left",true)
	game._update_home(.016)
	check(game.screen=="hub" and game._home_station()=="musou","Passing a nearby lit portal does not enter it automatically")
	game._set_action("left",false)
	game._set_action("up",true)
	check(game.screen=="game" and game.mode=="musou","Up enters the nearby Musou gate")
	game.queue_free()
	await process_frame
	print("v61 home gates: ",failures)
	quit(0 if failures.is_empty() else 1)
