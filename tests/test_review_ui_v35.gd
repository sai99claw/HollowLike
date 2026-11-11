extends SceneTree
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false)
	check(game.font.has_char("肉".unicode_at(0)),"Roguelike mode label has its missing Chinese glyph")
	game._update_hud();await process_frame
	check(not game.ui.health_art.visible and not game.ui.secondary_art.get_parent().visible,"Home header omits combat-only vitals and equipment")
	check(game.ui.coins_label.visible,"Home retains permanent coin balance")
	check(game.ui.header.find_children("*","Label",true,false).filter(func(label:Label)->bool:return label.is_visible_in_tree()).size()==1,"Home does not display invalid run/map diagnostics")
	check(game.lab_buttons.get_child_count()==2 and game.lab_buttons.get_child(0).text=="練習房" and game.lab_buttons.get_child(1).text=="RD 美術室","Home exposes practice and the requested direct art-room entry")
	game.menu_category="practice";game._show_settings();await process_frame
	var tools:Node=null
	for node:Control in preload("res://scripts/station_navigation_v26.gd").controls(game.ui):
		if str(node.get_meta("station_key",""))=="settings:developer_tools":tools=node
	check(tools!=null,"Developer tools remain reachable from settings")
	game._ui_action("developer_tools",null);await process_frame
	check(game.ui.panel_title.text=="開發工具","Developer tool action opens its dedicated panel")
	var texts:Array[String]=[]
	for button:Button in game.ui.panel_rows.find_children("*","Button",true,false):texts.append(button.text)
	check(texts.has("RD 美術室") and texts.has("RD 參數調教"),"Both developer tools remain available")
	game.new_run("rogue",35035);game._close_panel();game._update_hud();await process_frame
	check(game.ui.health_art.is_visible_in_tree() and game.ui.primary_art.is_visible_in_tree(),"Combat UI returns when entering an adventure")
	check(game.ui.prep_button.is_visible_in_tree(),"Safehouse still offers its equipment button")
	game.queue_free();await process_frame
	print("Review UI checks: ",failures)
	quit(0 if failures.is_empty() else 1)
