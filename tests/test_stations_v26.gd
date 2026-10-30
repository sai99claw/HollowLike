extends SceneTree
const Stock=preload("res://scripts/station_inventory_v26.gd")
const Data=preload("res://scripts/game_data.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func button(ui,key:String) -> Button:
	for control:Node in ui.panel_rows.find_children("*","Button",true,false):
		if str(control.get_meta("station_key",""))==key:return control
	return null
func settle() -> void:
	for i in 4:await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await settle();game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",260026);game._close_panel()
	check(not game.props.any(func(prop:Dictionary)->bool:return prop["kind"]=="rack"),"Weapon rack is removed from actual preparation room")
	for kind:String in ["forge","reforge","mail"]:check(preload("res://scripts/station_art_v26.gd").texture(kind)!=null,"Dedicated station art loads: "+kind)
	for def:Dictionary in Data.all_runes():check(Icons.texture(Icons.rune(def["id"]))!=null,"Every usable rune has artwork: "+str(def["id"]))
	game.meta["blueprints"]=["needle"];game.meta["coins"]=12;game.run_coins=18;game.bag_weapons.clear();game._show_forge();await settle()
	check(game.ui.panel_rows.find_child("BlueprintGrid",true,false).get_child_count()==9,"All nine blueprints have selectable tiles, including locked ones")
	var locked:Button=button(game.ui,"forge:chain_staff");locked.grab_focus();await settle()
	check(not locked.disabled and game.ui.panel_rows.find_child("StationHeroArt",true,false).material!=null,"Locked blueprint remains selectable and previews grayscale art")
	check(button(game.ui,"forge:craft").disabled,"Locked blueprint cannot be crafted")
	button(game.ui,"forge:needle").grab_focus();await settle();check(not button(game.ui,"forge:craft").disabled,"Combined carried and vault coins satisfy recipe")
	button(game.ui,"forge:craft").pressed.emit();await settle()
	check(game.run_coins==0 and game.meta["coins"]==0 and game.bag_weapons.size()==1,"Craft button dispatches currently previewed blueprint and spends exactly30")
	check(str(game.ui.get_viewport().gui_get_focus_owner().get_meta("station_key","")).begins_with("forge:"),"Focus remains inside rebuilt forge")
	game.meta["runes"]={"gale":2,"reflect":1};game.bag_runes={"gale":2,"reach":1};game.rune_slots.assign(["gale","reach"]);game.strong_slots.clear();game._show_reforge();await settle()
	var body:HBoxContainer=game.ui.panel_rows.find_child("StationBody",true,false)
	check(body.get_child(0).size.x/body.size.x>.60 and body.get_child(1).size.x/body.size.x<.36,"Reforge layout reserves left two-thirds and right third")
	check(game.ui.panel_rows.find_child("ReforgeSockets",true,false).get_child_count()==3,"Reforge has exactly three physical socket controls")
	check(button(game.ui,"reforge:rune:reflect")!=null,"Reforge includes home large runes")
	button(game.ui,"reforge:rune:gale").pressed.emit();await settle();button(game.ui,"reforge:rune:gale").pressed.emit();await settle();button(game.ui,"reforge:rune:reflect").pressed.emit();await settle()
	check(game.reforge_selection.size()==3 and not button(game.ui,"reforge:confirm").disabled,"Selecting grid runes fills slots and enables combine only at3")
	button(game.ui,"reforge:slot:1").pressed.emit();await settle();check(game.reforge_selection.size()==2 and button(game.ui,"reforge:confirm").disabled,"Removing a socket returns its reserved material")
	button(game.ui,"reforge:rune:gale").pressed.emit();await settle();button(game.ui,"reforge:confirm").pressed.emit();await settle()
	check(game.reforge_selection.is_empty() and game.rune_slots.has("gale") and game.rune_slots.has("reach"),"Reforge consumes unused carried then home copies before equipped copies")
	check(not game.meta["runes"].has("reflect") and game.meta["runes"]["gale"]==1 and not game.reforge_result.is_empty(),"Home materials are consumed and result remains visible")
	var bag:Dictionary={"gale":1};var vault:Dictionary={"runes":{}};var slots:Array=["gale"];var strong:Array=[]
	check(not Stock.consume(["gale","gale","gale"],bag,vault,slots,strong) and bag["gale"]==1 and slots[0]=="gale","Insufficient repeated materials reject atomically")
	game.meta["runes"]={"gale":2};game.meta["items"]={"0":2};game.meta["coins"]=9;game.meta["weapons"]=[game.Bag.store_weapon(Data.secondary_attack(0))];game.bag_runes={"gale":3,"reflect":2,"reach":1};game.rune_slots.assign(["gale","gale","reach"]);game.strong_slots.assign(["reflect"]);game._show_warehouse();await settle()
	check(game.ui.panel_title.text.begins_with("倉庫") and game.ui.panel_rows.find_child("WarehouseFilters",true,false).get_child_count()==6,"Warehouse replaces delivery station with six categories")
	button(game.ui,"warehouse:store_unused").pressed.emit();await settle()
	check(game.bag_runes=={"gale":2,"reflect":1,"reach":1} and game.meta["runes"]["gale"]==3 and game.meta["runes"]["reflect"]==1,"One-click storage preserves every equipped copy, including duplicate and large runes")
	check(game.rune_slots==["gale","gale","reach"] and game.strong_slots==["reflect"],"Storage never changes equipped slots")
	button(game.ui,"warehouse:filter:items").pressed.emit();await settle()
	check(game.ui.panel_rows.find_child("WarehouseGrid",true,false).get_child_count()==1,"Category filter limits grid to actual stored consumables")
	button(game.ui,"warehouse:item:0").grab_focus();await settle();button(game.ui,"warehouse:take").pressed.emit();await settle()
	check(game.meta["items"]["0"]==1 and int(game.bag_items.get("0",0))==1,"Taking consumable transfers one without using it")
	game.mode="musou";game.bag_weapons.clear()
	for i in 16:game.bag_weapons.append(Data.secondary_attack(0))
	check(not game._warehouse_take({"kind":"weapon","payload":"0"}) and game.meta["weapons"].size()==1,"Full musou bag cannot destroy warehouse weapon")
	game.mode="rogue";game.bag_weapons.assign([Data.secondary_attack(0)]);game.bag_weapons[0]["duplicate_bonus"]=8
	check(not game._warehouse_take({"kind":"weapon","payload":"0"}) and game.meta["weapons"].size()==1,"Capped rogue upgrade cannot destroy warehouse weapon")
	game.warehouse_filter="all";game._show_warehouse();await settle()
	for control:Control in preload("res://scripts/station_navigation_v26.gd").controls(game.ui):
		check(control.get_global_rect().end.x<=1180,"Station controls fit the1280px viewport horizontally: "+str(control.get_meta("station_key")))
	var candidates:Array[Control]=preload("res://scripts/station_navigation_v26.gd").controls(game.ui);candidates.sort_custom(func(a:Control,b:Control)->bool:return a.get_global_rect().get_center().y<b.get_global_rect().get_center().y);var first:Control=candidates[0];first.grab_focus();game.ui.navigate("up");check(game.ui.get_viewport().gui_get_focus_owner()==first,"Top boundary does not wrap to an unrelated option")
	game._close_panel();game.screen="hub";check(not game._warehouse_take({"kind":"coins"}),"Warehouse operations are restricted to preparation room")
	game.queue_free();await process_frame;print("v26 station checks: %d failures"%failures.size());quit(0 if failures.is_empty() else 1)
