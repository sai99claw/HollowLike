extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Art=preload("res://scripts/weapon_art_v24.gd")
const Arsenal=preload("res://scripts/arsenal_v24.gd")
const Station=preload("res://scripts/station_view_v26.gd")
const Fire=preload("res://scripts/ground_fire_v27.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func settle() -> void:
	for i in 5:await process_frame
func button(ui,key:String) -> Button:
	for control:Node in ui.panel_rows.find_children("*","Button",true,false):
		if str(control.get_meta("station_key",""))==key:return control
	return null
func reset(game) -> void:
	game._close_panel();game._clear_keys();game.p_attack.cancel();game.enemies.clear();game.hazards.clear();game.projectiles.clear();game.props.clear();game.solids.clear();game.platforms.clear();game.rune_slots.clear();game.strong_slots.clear();game._reset_player(Vector2(400,500));game.p["grounded"]=false;game.p["invul"]=0;game.life_event={}
func run() -> void:
	root.size=Vector2i(1280,720)
	var base:=Transform2D(0,Vector2.ONE*1.3,0,Vector2(-800,-600));var at:=Vector2(950,700)
	check(Art.draw_transform(base,at,Vector2.RIGHT,.2).origin.is_equal_approx(base*at),"Weapon draw transform composes camera translation and zoom, fixing offscreen sprites")
	for id:String in Arsenal.IDS:check(Art.texture(id,true)!=null,"Every active weapon projectile texture remains loaded: "+id)
	check(Art.texture("fire_flask",true)==preload("res://scripts/projectile_animation_v31.gd").texture("fire_flask") and Art.texture("fire_flask",true)!=Art.texture("fire_flask",false),"Airborne fire flask shows a bottle; flame belongs to grounded hazard")
	check(Fire.image()!=null,"New grounded fire animation imports")
	for i in 4:
		var rect:Rect2=Fire.source_rect(i*.1,Fire.image().get_size());check(Rect2(Vector2.ZERO,Fire.image().get_size()).encloses(rect),"Each flame frame uses valid imported source coordinates")
	var effects:Array=[];var fire:Dictionary={"pos":Vector2(500,900),"size":140.0,"elapsed":.2}
	for i in 100:Fire.emit(fire,effects,.05,false,12)
	check(effects.size()==12 and effects[0]["fire_ember"] and effects[0]["vel"].y<0,"Ground flame emits upward embers within global effect budget")
	var inset:Transform2D=preload("res://scripts/world_placement_v27.gd").prop_base(base)
	check((inset*at).is_equal_approx(base*(at+Vector2(0,10))),"Interactive prop base embeds ten world pixels under the tile surface at any zoom")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await settle();game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",270027)
	game.meta["blueprints"]=["needle"];game.meta["coins"]=90;game.run_coins=0;game.bag_weapons.clear();check(game._craft_weapon("needle"),"Crafting succeeds")
	game._show_forge();await settle();var card:Control=game.ui.panel_rows.find_child("CraftResultCard",true,false)
	check(card!=null and card.find_child("CraftResultArt",true,false).texture!=null,"Forge result remains below controls with item art")
	button(game.ui,"forge:chain_staff").grab_focus();await settle();check(game.forge_result["id"]=="needle","Browsing another blueprint does not change completed result")
	check(card.get_global_rect().end.y<=game.ui.panel_rows.get_parent().get_global_rect().end.y+1,"Forge result is visible below controls without leaving viewport")
	game.meta["runes"]={};game.bag_runes={"gale":3};game.rune_slots.clear();game.strong_slots.clear();game.reforge_selection.assign(["gale","gale","gale"]);check(game._reforge_runes(),"Reforge succeeds")
	game._show_reforge(false);await settle();check(game.ui.panel_rows.find_child("CraftResultArt",true,false).texture!=null,"Reforged rune appears in a persistent illustrated result card");check(game.ui.panel_rows.find_child("CraftResultCard",true,false).get_global_rect().end.y<=game.ui.panel_rows.get_parent().get_global_rect().end.y+1,"Reforge result fits below controls inside viewport")
	game._close_panel();game.bag_runes={"gale":2,"reflect":1};var seed_before:int=int(game.tower["seed"]);game._death();game._restart_after_death()
	check(game.life_event.is_empty() and game.bag_runes.is_empty() and int(game.tower["seed"])!=seed_before,"Death now discards carried runes and starts a new map without legacy choice UI")
	game.life_event={};game._close_panel();game._show_settings();await settle();game._ui_action("menu_category","controls");await settle()
	var slider:Control=null
	for control:Control in preload("res://scripts/station_navigation_v26.gd").controls(game.ui):
		if control.get_meta("station_key")=="settings:speed":slider=control
	check(slider is HSlider,"Grouped two-pane controls category contains actual speed slider")
	var previous:float=game.world_speed;slider.grab_focus();game.ui.navigate("right");check(game.world_speed>previous,"Grouped menu keyboard navigation adjusts settings slider")
	game._close_panel();game.bag_weapons.assign([Data.secondary_attack(0),Data.secondary_attack(Arsenal.index_of("moonblade"))]);game._show_equipment(1);await settle();var preview:Node=game.ui.panel_rows.find_child("WeaponFiringPreview",true,false);check(preview!=null,"Home equipment has firing animation preview")
	var list:Array[Control]=game.ui.equipment_navigation.controls(game.ui,"list");list[1].grab_focus();await settle();check(preview.weapon_id=="moonblade" and game.ui.panel_rows.find_child("EquipmentHeroName",true,false).text=="月翎刀","Equipment selection updates large art and preview together")
	game._close_panel();game.room["type"]="merchant";game.room["stock"]=[{"kind":"weapon","value":Arsenal.index_of("fire_flask"),"price":10,"sold":false,"pos":Vector2(500,500)}];game._show_merchant(0);await settle();check(game.ui.panel_rows.find_child("WeaponFiringPreview",true,false).weapon_id=="fire_flask","Merchant previews selected weapon firing with grounded fire")
	game._close_panel();game.room["type"]="reward";game.room["reward_choices"]=[{"kind":"weapon","value":Arsenal.index_of("homing_missile")}];game._show_reward();await settle();check(game.ui.panel_rows.find_child("WeaponFiringPreview",true,false).weapon_id=="homing_missile" and not game.room.get("reward_claimed",false),"Reward opens animation before committing selection")
	reset(game);game._dash_pressed();game._update_player(.08);check(is_equal_approx(game.p["pos"].x-400,650*.08*1.2),"Single C travel distance uses current1.2x base (20% shorter than v27)")
	reset(game);game.p_attack.begin({"kind":"pierce","dir":Vector2.RIGHT,"windup":0.0,"active":.24,"recovery":.16});game.p_attack.phase="active";game.p["dash_dir"]=Vector2.RIGHT;game.p["dash_t"]=.24;game._update_player(.08);check(is_equal_approx(game.p["pos"].x-400,940*.08*1.2),"Double C horizontal travel distance uses current1.2x base (20% shorter than v27)")
	for mode:String in ["rogue","musou"]:
		reset(game);game.mode=mode;game.p["hp"]=5;game._hurt_player(1,Vector2(300,500));check(is_equal_approx(game.p["invul"],.55*1.5 if mode=="rogue" else 2.0),"Damage protection preserves Roguelike and uses two-second dream protection: "+mode)
	reset(game);game.p["jumps"]=1;game._set_action("jump",true);game._update_player(.01);check(game.p["jumps"]==2 and game.p["flap_left"]>.25,"Actual double jump starts one wing flap")
	game._set_action("jump",false);game._update_player(.4);check(game.p["flap_left"]==0,"Wing flap stops after one0.32second cycle")
	check(preload("res://scripts/double_jump_v27.gd").texture()!=null,"New four-frame pigeon wing animation imports")
	reset(game);game.platforms.assign([Rect2(0,900,2000,80)]);game._projectile_explosion({"ground_fire":true,"pos":Vector2(500,700),"radius":8,"damage":2,"fire_size":140,"color":Color.ORANGE,"vel":Vector2.DOWN});check(game.hazards.size()==1 and game.hazards[0]["pos"].y==900,"Flask impact creates flame on actual support below, never a floating projectile")
	var enemy:Dictionary=game.Arms.enemy("walk",game.rng);enemy.merge({"uid":888,"hp":30.0,"max_hp":30.0,"pos":Vector2(500,900),"vel":Vector2.ZERO,"face":-1.0,"attack":game.Attack.new(),"stun":0.0,"hurt":0.0,"cooldown":9.0},true);game.enemies.assign([enemy])
	game.effects.clear();game._update_hazards(.2);check(enemy["hp"]==28,"Ground flame damages enemy standing on its actual surface");check(game.effects.any(func(effect:Dictionary)->bool:return effect.get("fire_ember",false)),"Actual hazard update emits grounded-fire particles")
	game._close_panel();game.mode="rogue";game.life_event={};game.new_run("rogue",270027)
	var elite_room:int=-1
	for room:Dictionary in game.tower["rooms"]:
		if room["type"]=="elite":elite_room=int(room["id"]);break
	if elite_room>=0:
		game._enter_room(elite_room);var alive:Array=game.enemies.filter(func(en:Dictionary)->bool:return en.get("elite",false));check(not alive.is_empty(),"Actual elite room spawns elites")
		for en:Dictionary in alive:check(is_equal_approx(en["max_hp"],(10+int(game.room["map_index"])*.5)*3*game.Tuning.value("enemy_hp")),"Actual elite HP triples including map scaling")
	else:check(false,"Elite room exists")
	game.queue_free();await process_frame;print("v27 checks: %d failures"%failures.size());quit(0 if failures.is_empty() else 1)
