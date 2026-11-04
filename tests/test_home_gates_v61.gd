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
	game._activate_home_gate("rogue")
	check(game.screen=="hub","Rogue still requires reaching the elevated gate")
	game.home_sleeping=false
	game.p["pos"]=feet
	check(game._home_interact() and game.screen=="game" and game.mode=="musou","Walking to the gate and interacting starts Musou")
	game.queue_free()
	await process_frame
	print("v61 home gates: ",failures)
	quit(0 if failures.is_empty() else 1)
