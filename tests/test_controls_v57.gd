extends SceneTree

const MapView=preload("res://scripts/tower_map_view.gd")
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Armory=preload("res://scripts/armament.gd")
const Walk=preload("res://scripts/walk_animation.gd")
var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")

func check(value:bool,message:String) -> void:
	if not value:failures.append(message)

func key(game:Node,code:Key,pressed:bool,echo:bool=false) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=pressed
	event.echo=echo
	game._input(event)

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.audio_enabled=false
	game._enter_practice()
	key(game,KEY_TAB,true)
	check(game.minimap_open and game.minimap_page==0,"Tab opens the terrain map")
	key(game,KEY_RIGHT,true)
	check(game.minimap_page==1,"Right moves to chapter")
	key(game,KEY_TAB,false)
	check(not game.minimap_open,"Tab release dismisses the map")
	key(game,KEY_M,true)
	key(game,KEY_LEFT,true)
	check(game.minimap_open and game.minimap_page==2,"M pins and Left wraps to the tower")
	key(game,KEY_TAB,true)
	key(game,KEY_TAB,false)
	check(game.minimap_open,"Tab release preserves an M-pinned map")
	key(game,KEY_ESCAPE,true)
	check(not game.minimap_open and not game.ui.is_panel_open(),"Esc dismisses the map without opening settings")
	key(game,KEY_M,true)
	key(game,KEY_M,true)
	check(not game.minimap_open,"M toggles the pinned map off")
	for i in range(5):
		game.bag_items[str(i)]=3
		key(game,KEY_1+i,true)
		key(game,KEY_1+i,true,true)
		key(game,KEY_1+i,false)
		key(game,KEY_KP_1+i,true)
		check(game.bag_items[str(i)]==1,"Physical number and keypad each consume one item")
	check(not game.ui.is_panel_open(),"Hotkeys leave gameplay open")
	var rooms:Array=[
		{"id":0,"map_index":0,"visited":true,"neighbors":{"right":1}},
		{"id":1,"map_index":0,"neighbors":{"left":0,"right":2}},
		{"id":2,"map_index":0,"neighbors":{"left":1}},
	]
	check(MapView.neighboring_rooms(rooms,MapView.known_rooms(rooms,0))=={1:true},"Only directly adjacent unvisited rooms are hinted")
	for safe:Rect2 in [Rect2(220,0,840,720),Rect2(0,100,1280,520)]:
		game.ui.set_safe_rect(safe)
		var ui_root:Control=game.ui.ui_root
		for control:Control in [game.ui.header,game.ui.edge_tools,game.ui.quickbar]:
			var transformed:=Rect2(ui_root.position+control.position*ui_root.scale,control.size*ui_root.scale)
			check(safe.grow(.01).encloses(transformed),"Interactive HUD stays inside the visible area")
	check(float(Roster.elite(2)["scale"])==2.0 and float(Armory.enemy("walk",RandomNumberGenerator.new(),true)["scale"])==2.0,"Both elite creation paths use 2x scale")
	var frames:Array=Walk.clip()["frames"]
	check(frames.size()==10,"Walk contains ten visible frames")
	check(not frames.any(func(frame:Dictionary) -> bool:return frame["path"].ends_with("walk_06.png") or frame["path"].ends_with("walk_11.png")),"Walk omits source poses seven and twelve")
	game.queue_free()
	await process_frame
	print("v57 controls: ",failures)
	quit(0 if failures.is_empty() else 1)
