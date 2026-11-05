extends SceneTree

const Practice=preload("res://scripts/practice_rd_v22.gd")
var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")

func check(ok:bool,message:String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func labels(node:Node) -> Array[String]:
	var result:Array[String]=[]
	if node is Button or node is Label:result.append(node.text)
	for child:Node in node.get_children():result.append_array(labels(child))
	return result

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false);game.set_physics_process(false);game.audio_enabled=false
	var original_meta:Dictionary=game.meta.duplicate(true)
	game._enter_practice()
	game._show_practice()
	var tabs:Array[String]=labels(game.ui.panel_rows)
	check(tabs.has("◆ 房型生成") and tabs.has("怪物召喚") and tabs.has("武器與符文") and tabs.has("測試控制"),"Practice tools show four separate tabs")
	check(tabs.has("漂浮香菇房") and not tabs.has("清空怪物與彈體"),"Room generation does not mix in combat controls")
	game._ui_action("lab_page","monsters")
	var monsters:Array[String]=labels(game.ui.panel_rows)
	check(monsters.has("小怪") and monsters.has("菁英怪") and monsters.has("首領") and not monsters.has("漂浮香菇房"),"Summoning has its own page and enemy groups")
	check(game._lab_monsters().size()==46,"The practice catalog includes the three new air lancers")
	game._ui_action("lab_page","equipment")
	check(labels(game.ui.panel_rows).has("符文配置"),"Equipment has a separate page")
	game._ui_action("lab_page","controls")
	check(labels(game.ui.panel_rows).has("清空怪物與彈體"),"Testing controls have a separate page")
	game._close_panel()
	var initial_weapons:Array=game.bag_weapons.duplicate(true)
	game.bag_items["0"]=17
	for item:Array in Practice.ROOM_TYPES:
		var kind:String=item[1]
		game._regenerate_practice({"room_kind":kind,"seed":56056})
		var expected:String=kind if kind in ["elite","boss","start","merchant","reward"] else "combat"
		check(game.room["type"]==expected,"Practice enters the requested room: "+kind)
		check(game.bag_weapons==initial_weapons and game.bag_items["0"]==17,"Room generation preserves equipment and supplies")
		if kind in ["spike_islands","mushroom_air"]:
			check(game.layout.get("hazard_room","")==kind,"Special geometry is selected directly")
		else:check(not game.layout.has("hazard_room"),"Ordinary practice rooms never randomly become special rooms")
		if kind=="boss":check(game.enemies.any(func(enemy:Dictionary)->bool:return int(enemy["model"])==4),"Boss room spawns its boss")
	game._leave_lab()
	check(game.meta==original_meta,"Practice rooms do not write to permanent progress")
	game.queue_free()
	await process_frame
	print("v56 practice rooms: ",failures)
	quit(0 if failures.is_empty() else 1)
