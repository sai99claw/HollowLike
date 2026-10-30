extends SceneTree
const Data=preload("res://scripts/game_data.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func settle() -> void:
	for i in 3:await process_frame
func press(game,action:String) -> void:
	game._set_action(action,true);game._set_action(action,false);await settle()
func key(code:Key) -> InputEventKey:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;return event
func focus_key() -> String:
	var control:Control=root.gui_get_focus_owner();return str(control.get_meta("equipment_key","")) if control!=null else ""
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await settle();game.set_process(false);game.set_physics_process(false);game.new_run("rogue",250025);game.weapon_index=0 # Explicit navigation fixture; the default knife is covered byv33 tests.
	game._show_equipment(0);await settle()
	check(focus_key()=="tab:0","E starts focused on the main weapon tab")
	var bar:Node=game.ui.panel_rows.find_child("EquipmentTabsV24",true,false)
	var order:Array=[]
	for child:Node in bar.get_children():order.append(child.get_meta("equipment_page"))
	check(order==[2,1,0,3],"Visible tab order agrees with left-secondary, left-left-items, right-runes")
	for expected:int in [1,2,3,0]:
		await press(game,"left");check(game.equipment_page==expected and focus_key()=="tab:"+str(expected),"Left pages in deterministic visual order")
		check(game.ui.panel_rows.find_child("InventoryTabs",true,false)==null,"Equipment never includes legacy duplicate tabs")
	await press(game,"right");check(game.equipment_page==3,"Right from main opens runes")
	await press(game,"left");check(game.equipment_page==0,"Left from runes header returns main")
	await press(game,"down");check(focus_key()=="primary_inventory|0","Down enters actual weapon list, not another tab or Close")
	await press(game,"down");check(focus_key()=="primary_inventory|1","Down selects next weapon")
	await press(game,"down");check(focus_key()=="primary_inventory|2","Down selects third weapon")
	await press(game,"down");check(focus_key()=="primary_inventory|2","Bottom of list never jumps to Close")
	await press(game,"attack");check(game.weapon_index==2 and focus_key()=="primary_inventory|2","Confirm equips intended weapon and preserves list cursor")
	game._unhandled_input(key(KEY_1));check(game.weapon_index==2,"Gameplay weapon shortcuts cannot change equipment behind an open panel")
	await press(game,"up");await press(game,"up");await press(game,"up");check(focus_key()=="tab:0","Up from first item returns header")
	game.bag_weapons.clear();game._show_equipment(1);await settle()
	var name_label:Label=game.ui.panel_rows.find_child("EquipmentHeroName",true,false)
	check(name_label.text=="尚無附武器","Empty secondary page does not display primary weapon as a phantom secondary")
	await press(game,"down");check(focus_key()=="tab:1","An empty inventory cannot focus a phantom choice")
	game.bag_items.clear();game._show_equipment(2);await settle();name_label=game.ui.panel_rows.find_child("EquipmentHeroName",true,false)
	check(name_label.text=="沒有消耗品","Empty supplies page does not advertise a nonexistent heal item")
	game.bag_runes={"gale":1};game.rune_slots.clear();game.strong_slots.clear();game._show_equipment(3);await settle()
	await press(game,"down");check(focus_key()=="rune_auto","Rune content starts at random auto equip")
	await press(game,"down");await press(game,"down");check(focus_key()=="grid:0","Down through large sockets enters top-left small socket")
	await press(game,"right");check(focus_key()=="grid:1" and game.equipment_page==3,"Right inside rune board moves one socket without unexpectedly paging")
	await press(game,"down");check(focus_key()=="grid:5","Down moves exactly four sockets")
	await press(game,"attack");check(game.rune_target_slot==5 and focus_key()=="grid:5","Selecting empty rune socket preserves cursor")
	await press(game,"right");await press(game,"right");await press(game,"right")
	check(focus_key()=="rune_equip|gale","Right edge of rune board enters the actual rune list")
	await press(game,"attack");check(game.rune_slots[5]=="gale" and focus_key()=="rune_equip|gale","Confirm equips exactly selected socket and keeps list focus")
	await press(game,"up");check(focus_key()=="tab:3","Top of rune inventory returns tabs")
	var before:int=game.weapon_index;game._input(key(KEY_E));await settle()
	check(not game.ui.is_panel_open() and not game.equipment_open and game.weapon_index==before,"E closes the equipment menu instead of activating a random focused option")
	game.queue_free();await settle();print("Equipment navigation: ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
