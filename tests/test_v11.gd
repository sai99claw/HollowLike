extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Links=preload("res://scripts/rune_links.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
const InventoryArt=preload("res://scripts/inventory_art.gd")
const Bag=preload("res://scripts/expedition_bag.gd")
const Arms=preload("res://scripts/armament.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func key(code:Key,pressed:bool) -> InputEventKey:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;return event
func enemy(at:Vector2) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=11;var en:Dictionary=Arms.enemy("walk",rng)
	en.merge({"pos":at,"uid":5,"hp":2000.0,"max_hp":2000.0,"vel":Vector2.ZERO,"face":-1.0,"hurt":0.0,"stun":0.0,"cooldown":100.0,"attack":Attack.new()},true);return en
func frames() -> void:
	for i in 4:await process_frame
func run() -> void:
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame;scene.set_process(false);scene.set_physics_process(false)
	var saved:Dictionary=scene.meta.duplicate(true);scene.new_run("rogue",11023);scene._close_panel();scene.enemies.clear();scene.p_attack.cancel()
	# Map key press/release is handled before focused GUI controls can consume it.
	check(not scene.minimap_open,"Minimap starts hidden")
	scene._input(key(KEY_TAB,true));check(scene.minimap_open and not scene.ui.is_panel_open(),"Holding Tab shows minimap without pausing or opening a panel")
	scene._input(key(KEY_TAB,false));check(not scene.minimap_open,"Releasing Tab hides minimap")
	scene._input(key(KEY_TAB,true));scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);check(not scene.minimap_open,"Losing window focus cannot leave map stuck open")
	scene._show_bag();scene._input(key(KEY_TAB,true));check(not scene.minimap_open,"Tab in inventory does not leak an overlay into gameplay");scene._input(key(KEY_TAB,false));scene._close_panel()
	# Top mute acts directly and persists, and equipment HUD updates with Q.
	# Native Ogg playback is covered in test_v06; isolate this setting/UI check.
	scene.room_music.stop();scene.room_music.stream=null
	scene.ui.mute_button.pressed.emit();check(scene.audio_enabled and not scene.ui.is_panel_open(),"Top mute button toggles sound without opening settings")
	scene.ui.mute_button.pressed.emit();check(not scene.audio_enabled and not scene.meta["settings"]["audio_enabled"] and AudioServer.is_bus_mute(0),"Mute setting is saved and immediately mutes all sound")
	scene.bag_weapons.assign([Data.secondary_attack(0),Data.secondary_attack(10)]);scene.secondary_index=0;scene._unhandled_input(key(KEY_Q,true))
	check(scene.secondary_index==1 and scene.ui.secondary_label.text.contains("連鎖雷擊法杖") and scene.ui.secondary_label.text.contains("Q"),"Q changes equipped secondary and visible HUD immediately")
	check(scene.ui.secondary_art.texture==Icons.texture("secondary_chain_staff"),"HUD shows equipped secondary's illustration")
	# Every aerial weapon starts active synchronously on the input event.
	for i in Data.SECONDARY.size():
		scene._clear_keys();scene._reset_player(Vector2(600,700));scene.p["grounded"]=false;scene.p["energy"]=6;scene.bag_weapons.assign([Data.secondary_attack(i)]);scene.secondary_index=0;scene.enemies.assign([enemy(Vector2(660,700))]);scene.projectiles.clear();scene.effects.clear();scene.hitstop=0
		scene._set_action("sub",true)
		check(scene.p_attack.is_active() and scene.p_attack.attack["windup"]==0 and scene.p["energy"]==5,"Air secondary is instant and spends one energy: "+str(i))
		if Data.SECONDARY[i]["kind"]=="sword":scene._process_player_attack();check(scene.enemies[0]["hp"]<2000,"Air melee secondary has immediate attack volume")
		elif Data.SECONDARY[i]["kind"] in ["laser","chain"]:check(not scene.effects.is_empty(),"Air beam/chain emits on press")
		else:check(not scene.projectiles.is_empty(),"Air projectile emits on press")
	scene._clear_keys();scene._reset_player(Vector2(700,1050));scene.bag_weapons.assign([Data.secondary_attack(0)]);scene._begin_secondary();check(scene.p_attack.is_active(),"Ground secondary now has zero startup")
	# Orthogonal identity edges, no diagonal or row wrap.
	check(Links.edges(["a","a","","a","a","a"]).size()==4,"2x2 same runes produce four edges, row boundary does not wrap")
	check(Links.edges(["a","","","","","a"]).is_empty(),"Diagonal runes do not connect")
	scene.p_attack.cancel();scene.rune_slots.assign(["gale","gale","","","gale","gale"]);scene.strong_slots.clear()
	check(is_equal_approx(scene._rune_effect("haste"),.06*4*1.04),"Each same-rune edge adds one percent to that rune type's total effect")
	scene.bag_runes={"gale":8,"reach":2,"reflect":1};scene.rune_target_slot=14;scene._equip_rune("reach")
	check(scene.rune_slots.size()==15 and scene.rune_slots[14]=="reach" and scene.rune_slots[10]=="","Chosen empty slot preserves positional holes")
	var old_size:int=scene.rune_slots.size();scene._ui_action("rune_remove",0)
	check(scene.rune_slots.size()==old_size and scene.rune_slots[0]=="" and scene.rune_slots[1]=="gale","Removing a rune preserves all other slot positions")
	scene._ui_action("rune_slot",0);scene._ui_action("rune_equip","gale");check(scene.rune_slots[0]=="gale","Selected empty socket accepts a carried rune")
	# Layout, actual keyboard focus and the fixed bottom inspector.
	scene.strong_slots.assign(["reflect"]);scene._show_runes(false);await frames()
	var board:GridContainer=scene.ui.panel_rows.find_child("RuneBoard",true,false);var strong:HBoxContainer=scene.ui.panel_rows.find_child("StrongRuneBoard",true,false)
	check(board.get_child_count()==16 and strong.get_child_count()==3,"Two tiers display exactly sixteen small and three large sockets")
	check(strong.get_child(0).size.x>board.get_child(0).size.x*1.8,"Greater sockets are visually larger than small sockets")
	check(board.get_global_rect().end.y<scene.ui.inspector.get_global_rect().position.y,"All sixteen sockets fit above fixed item description")
	board.get_child(0).grab_focus();check(scene.ui.inspect_title.text=="風羽" and scene.ui.inspect_body.text.contains("相鄰"),"Focused rune describes its effect and adjacency bonus below")
	scene.ui.navigate("right");check(root.gui_get_focus_owner()==board.get_child(1),"Right arrow moves to adjacent socket")
	scene.ui.navigate("down");check(root.gui_get_focus_owner()==board.get_child(5),"Down arrow moves one grid row")
	board.get_child(14).mouse_entered.emit();check(scene.ui.inspect_title.text=="長翎","Mouse hover shares the same bottom inspector")
	var tabs:HBoxContainer=scene.ui.panel_rows.find_child("InventoryTabs",true,false);check(tabs.get_child_count()==2,"Inventory has exactly weapons and runes pages")
	# All runes and each weapon/consumable resolve to distinct new authored regions.
	var regions:Dictionary={}
	for rune in Data.all_runes():
		var art:AtlasTexture=Icons.texture(Icons.rune(rune["id"],rune.get("strong",false)));check(art!=null and (art.atlas.resource_path.ends_with("inventory_v11/runes.png") or art.atlas.resource_path.contains("v24/runes/")),"New illustration exists for every rune: "+str(rune["id"]));regions[art.atlas.resource_path+str(art.region)]=true
	check(regions.size()==Data.all_runes().size(),"Every rune has its own unique delivered illustration")
	for weapon in Data.SECONDARY:
		var illustration:Texture2D=Icons.texture("secondary_"+str(weapon["id"]))
		check(illustration!=null,"Each secondary resolves to authored art")
		if preload("res://scripts/arsenal_v24.gd").IDS.has(weapon["id"]):check(illustration.atlas.resource_path.contains("v24/weapons/"),"Current nine weapons use new individual art")
	for item in Data.ITEMS:check(Icons.texture("items_"+str(item["id"])).atlas.resource_path.ends_with("inventory_v11/items.png"),"Each supply uses new illustration")
	# Preparation-room stock can be used directly and retains source values through JSON.
	scene._close_panel();scene._enter_room(int(scene.tower["maps"][0]["start_id"]));scene.room_cooldown=0;scene.p_attack.cancel();scene.meta["runes"]={"reach":2};scene.rune_slots.clear();scene.bag_runes.clear();scene._ui_action("rune_take","reach")
	check(scene.meta["runes"]["reach"]==1 and scene.bag_runes["reach"]==1 and scene.rune_slots[0]=="reach","One home rune is withdrawn and equipped in one action")
	scene._close_panel();scene.meta["items"]={"0":2};scene.bag_items.clear();scene.p["hp"]=1;scene._ui_action("stash_item",0)
	check(scene.meta["items"]["0"]==1 and scene.p["hp"]==3 and scene.bag_items["0"]==0,"Home consumable withdraws exactly one and applies its effect")
	scene._close_panel();scene.bag_weapons.assign([Data.secondary_attack(9)]);scene.meta["weapons"]=[];scene._send_parcel("weapons")
	check(scene.bag_weapons.is_empty() and scene.meta["weapons"].size()==1,"Weapons can be sent home")
	var stored:Dictionary=JSON.parse_string(JSON.stringify(scene.meta["weapons"][0]));var restored:Dictionary=Bag.restore_weapon(stored)
	check(restored["color"] is Color and restored["name"]=="裂枝衝擊波" and restored["damage"]==3,"Home weapon survives JSON without losing stats or color")
	scene._ui_action("stash_weapon",0);check(scene.meta["weapons"].is_empty() and scene._secondary()["name"]=="裂枝衝擊波","Taking a home weapon equips it immediately")
	scene.meta=saved;scene._save_meta();scene.audio_enabled=false;scene.combat_feedback.clear();scene.queue_free();await process_frame
	# AudioServer disposes playbacks on its next mixer block after the mute toggle.
	AudioServer.set_bus_mute(0,false)
	await create_timer(.12).timeout
	print("v0.11 inventory/controls: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
