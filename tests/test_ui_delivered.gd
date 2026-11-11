extends SceneTree
const UI=preload("res://scripts/game_ui.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
const Data=preload("res://scripts/game_data.gd")
const Arms=preload("res://scripts/armament.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	var ui=UI.new();root.add_child(ui);await process_frame
	for rune in Data.all_runes():check(Icons.texture(Icons.rune(rune["id"],rune.get("strong",false))) is AtlasTexture,"Every normal/strong rune resolves to a cropped delivered UI image")
	for skill in Data.SKILLS:check(Icons.texture(Icons.by_text("已解鎖　"+skill["name"])) is AtlasTexture,"Skill sections display the matching delivered icon")
	for item in Data.ITEMS:check(Icons.texture("items_"+item["id"])!=null,"Every consumable uses delivered art")
	for weapon in Data.SECONDARY:check(Icons.texture("secondary_"+weapon["id"]) is AtlasTexture,"Every secondary uses delivered art")
	ui.update_hud({"hp":4,"max_hp":6,"energy":2,"max_energy":6,"hp_recovery":.25,"energy_recovery":.6,"hp_recovering":true,"energy_recovering":true,"weapon":"大刀","coins":9,"mode":"rogue"})
	check(ui.health_art.texture!=null and ui.energy_art.texture!=null and ui.health_art.tooltip_text=="生命 4 / 6" and ui.energy_art.tooltip_text=="能量 2 / 6","HUD displays resource art with exact integer values available on hover")
	check(ui.health_cells.get_child_count()==6 and ui.energy_cells.get_child_count()==6,"Health and energy each display their exact number of discrete cells")
	check(ui.health_cells.recovering_index==4 and ui.energy_cells.recovering_index==2,"Only the next unfinished resource cell is marked recovering")
	check(ui.header.get_theme_stylebox("panel") is StyleBoxEmpty and ui.coins_label.text=="9","HUD uses a transparent background and a numeric coin balance")
	var before:float=ui.health_cells.get_child(4).modulate.a
	ui.health_cells._process(.07)
	check(not is_equal_approx(before,ui.health_cells.get_child(4).modulate.a),"Recovering cell visibly blinks")
	check(ui.health_cells.get_child(0).modulate.a==1 and ui.health_cells.get_child(5).modulate.a==1,"Full cells and later empty cells do not blink")
	ui.update_hud({"hp":5,"max_hp":6,"energy":6,"max_energy":6,"hp_recovering":true,"energy_recovering":true})
	check(ui.health_cells.recovering_index==5 and ui.health_cells.get_child(4).modulate.a==1,"Completing recovery moves the blink to the next whole cell")
	check(ui.energy_cells.recovering_index==-1,"A full resource does not blink or add an extra cell")
	var items:Dictionary={};var bag:Dictionary={};var growth:Array[String]=[]
	for i in Data.ITEMS.size():items[str(i)]=1
	for r in Data.all_runes():bag[r["id"]]=2
	for id in Arms.GROWTH:growth.append(str(Arms.GROWTH_NAMES[id])+" ×1")
	var weapons:Array[Dictionary]=[]
	for i in Data.SECONDARY.size():weapons.append(Data.secondary_attack(i))
	ui.show_inventory({"primary":Data.PRIMARY[2],"weapons":weapons,"selected":0,"items":items,"item_defs":Data.ITEMS,"rune_count":17,"coins":9,"mode":"musou","upgrades":"\n".join(growth)})
	var art=ui.panel_rows.find_child("GrowthArt",true,false)
	check(art!=null and art.get_child_count()==7,"All seven acquired growth types display their distinct icons")
	ui.show_rune_board({"slots":["gale","reach"],"strong_slots":["reflect","orbit_bee","heartplus"],"bag":bag,"stash":bag,"defs":Data.all_runes(),"in_start":true})
	var board=ui.panel_rows.find_child("RuneBoard",true,false)
	check(board!=null and board.get_child_count()==16 and board.columns==4,"Delivered rune art preserves the sixteen-slot board")
	check(board.get_child(0).find_child("DeliveredRuneArt",true,false)!=null,"Equipped rune slots use PNG art instead of letter placeholders")
	var events:Array=[]
	ui.action_requested.connect(func(action:String,payload:Variant)->void:events.append([action,payload]))
	board.get_child(0).pressed.emit()
	check(events==[["rune_remove",0]],"Art overlays preserve the existing rune click action")
	await process_frame
	check(ui.header.size.x<650,"Illustrated discrete HUD stays compact")
	ui.queue_free();await process_frame
	print("Delivered UI: ","passed: rune/item/weapon/skill/growth art, clickable rune grid, integer resource cells, one blinking recovery cell and compact HUD" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
