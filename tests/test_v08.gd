extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const FX=preload("res://scripts/combat_visual.gd")
const Arms=preload("res://scripts/armament.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Combat=preload("res://scripts/combat_library.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func target(at:Vector2,uid:int) -> Dictionary:
	var random:=RandomNumberGenerator.new();random.seed=uid
	var en:Dictionary=Arms.enemy("walk",random)
	en.merge({"uid":uid,"pos":at,"hp":2000.0,"max_hp":2000.0,"vel":Vector2.ZERO,"face":-1.0,"hurt":0.0,"stun":0.0,"cooldown":100.0,"attack":Attack.new()},true)
	return en
func settle(scene) -> void:
	for i in 600:
		if scene.life_event.get("kind","") not in ["injury","death"]:return
		scene._update_life_event(1.0/60)
func run() -> void:
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	scene.set_process(false);scene.set_physics_process(false)
	var saved:Dictionary=scene.meta.duplicate(true)
	scene.practice_mode=true;scene.world_speed=1;scene.new_run("rogue",80815);scene._close_panel();scene.room_cooldown=0
	check(scene.material==null,"Default font shader is restored instead of applying sprite alpha to glyph atlases")
	for character in "枝間鴿行生命能量寶箱貓頭鷹商人紀錄版雷射":check(scene.font.has_char(character.unicode_at(0)),"Font contains required Chinese glyph: "+character)
	# Free gift can be acquired explicitly from the rack, once only.
	scene._claim_gift();var gifts:int=scene.bag_weapons.size();scene._claim_gift()
	check(gifts==1 and scene.bag_weapons.size()==1,"Starter weapon claim is explicit and cannot duplicate")
	scene._show_prep("rack");await process_frame;scene.ui.focus_first()
	check(root.gui_get_focus_owner()!=null,"Keyboard focus starts on a visible panel control")
	scene.ui.navigate("down");scene._close_panel()
	scene.solids.clear();scene.platforms.assign([Rect2(0,1050,1500,70)]);scene.props.clear();scene.enemies.clear();scene._reset_player(Vector2(700,1050))
	scene.keys={"right":true};scene._update_player(.25);var walk:float=scene.p["vel"].x
	scene.keys["dash"]=true;scene._update_player(.25)
	check(scene.p["vel"].x>walk*1.5,"Holding C and direction runs faster after the initial dash")
	scene._clear_keys();scene.p["hp"]=2;scene.p["energy"]=6;scene.keys["heal"]=true
	check(is_equal_approx(scene._movement_factor(),.4),"Healing reduces movement by sixty percent")
	scene.injured=true;check(is_equal_approx(scene._movement_factor(),.32),"Injury and healing penalties stack")
	scene.keys.erase("heal");check(is_equal_approx(scene._movement_factor(),.8),"Injury slows movement by twenty percent")
	scene.injured=false;scene._clear_keys();scene._reset_player(Vector2(700,800));scene.keys["down"]=true;scene.clock=10
	scene._dash_pressed();check(scene.p["dash_t"]==0 and scene.p["vel"]==Vector2.ZERO and not scene.p_attack.is_busy(),"Down+C has no forward dash or attack")
	scene.clock=10.2;scene._dash_pressed();check(scene.p_attack.attack.get("kind","")=="slam","Down+CC starts downslam directly")
	scene.p_attack.tick(.04);check(scene.p["slam"] and scene.p["dash_dir"]==Vector2.DOWN,"Downslam active motion is vertical")
	check(scene._wind_form_active(),"Downslam transforms the player into the dedicated wind form")
	scene._slam_impact(Vector2(700,1050));check(not scene.p["slam"] and scene.effects.any(func(e):return e.get("ground_wind",false)),"Landing produces delivered ground shock art")
	for weapon in 3:
		scene.weapon_index=weapon
		check(is_equal_approx(Data.primary_attack(weapon,"right",true)["active"],1.0),"Every charged active phase is exactly one second")
		for charged in [true,false]:
			for phase in ["windup","recovery"]:
				scene._clear_keys();scene._reset_player(Vector2(700,1050));scene._begin_primary({"dir":"right","charged":charged})
				if phase=="windup" and float(scene.p_attack.attack["windup"])==0:continue
				if phase=="recovery":scene.p_attack.tick(float(scene.p_attack.attack["windup"])+float(scene.p_attack.attack["active"])+.001)
				scene._dash_pressed();check(not scene.p_attack.is_busy() and scene.p["dash_t"]>0,"All weapon outer phases can dash-cancel")
	scene._clear_keys();scene._reset_player(Vector2(700,1050));scene.weapon_index=2;scene.keys["right"]=true;scene.p["vel"].x=330;scene._begin_primary({"dir":"right","charged":false});scene._update_player(.05)
	check(scene.p["vel"].x==0 and scene.p["pos"].x==700,"Heavy attacks stop horizontal movement immediately")
	scene.strong_slots.clear();scene.rune_slots.clear();scene.weapon_index=1
	var plain:Dictionary=scene._primary_definition({"dir":"right","charged":false})
	scene.rune_slots.assign(["gale"]);var fast:Dictionary=scene._primary_definition({"dir":"right","charged":false})
	check(fast["windup"]==0 and plain["windup"]==0 and fast["recovery"]<plain["recovery"] and fast["active"]==plain["active"],"With zero startup, haste reduces recovery and leaves active time intact")
	for id in ["enemy_walk_move","enemy_jump_move","enemy_hover_move","pigeon_talons_charge","pigeon_great_charge"]:
		var clip:Dictionary=FX.definition(id);var bounds:Array=clip["frames"][0]["visible_bounds"]
		if id.begins_with("pigeon_"):check(is_equal_approx(FX.actor_factor(id)*FX.actor_factor(id)*80,4),"Player uses a fixed anatomical reference, independent of pose bounds")
		else:check(is_equal_approx(float(bounds[3])*FX.actor_factor(id),57),"Enemies keep normalized resting height")
	# Traps are destructible before arming and never damage after destruction.
	scene.hazards.clear();scene.p_attack.cancel();scene._clear_keys();scene.projectiles.clear()
	var hazard:Dictionary=Combat.attack("trap",{"size":30,"damage":1,"from_player":false,"arming_time":1.0})
	scene._settle_trap({"pos":Vector2(700,1050),"definition":hazard});check(scene.hazards[0]["hp"]==1,"Traps have exactly one HP")
	scene._damage_traps(Rect2(650,980,100,80),1);scene._update_hazards(.1);check(scene.hazards.is_empty(),"One hit destroys an unarmed trap")
	# Consumable hotkeys work without opening a menu or changing primary weapon.
	scene.bag_items={"0":2};scene.p["hp"]=1;scene.p_attack.cancel();scene.weapon_index=2
	var key:=InputEventKey.new();key.physical_keycode=KEY_1;key.pressed=true;key.shift_pressed=true;scene._unhandled_input(key)
	check(scene.bag_items["0"]==1 and scene.p["hp"]==3 and scene.weapon_index==2 and not scene.ui.is_panel_open(),"Shift+1 uses its consumable in place without selecting a primary")
	scene._close_panel();scene._set_map_held(true);check(scene.minimap_open,"Minimap shows while map key is held");scene._set_map_held(false);check(not scene.minimap_open,"Releasing map key hides minimap")
	# Procedural rooms, guarded entrances, chest probability and persistent stock.
	var merchant:int=-1;var combat:int=-1
	for room in scene.tower["rooms"]:
		if room["type"]=="merchant":merchant=room["id"]
		elif room["type"]=="combat" and not room.get("spring",false):combat=room["id"]
	check(merchant>=0,"Tower contains owl merchant rooms")
	scene._enter_room(merchant);scene.run_coins=200;scene._show_merchant();var price:int=scene.room["stock"][0]["price"]
	scene._merchant_buy(0);var spent:int=scene.run_coins;scene._merchant_buy(0)
	check(spent==200-price and scene.run_coins==spent and scene.room["stock"][0]["sold"],"Shop charges once, records sold stock, prevents duplicate purchase")
	scene._close_panel();scene._enter_room(combat)
	for en in scene.enemies:
		check(int(en["contact_damage"]) in [0,1],"Small monster contact is one damage")
		for attack in en["attacks"]:check(attack["damage"]==1,"Small monster attacks are one damage")
		for door in scene.doors:check(en["pos"].distance_to(door["pos"])>=150,"Monsters do not spawn beside portals")
	var chest:Dictionary={"kind":"chest","pos":Vector2(600,1050),"used":false};scene._open_chest(chest);var loot:int=scene.drops.size();scene._open_chest(chest)
	check(chest["used"] and scene.drops.size()==loot,"Chest gives randomized loot once")
	# Boss gains exactly one or two behaviors once, guaranteed major drops.
	var boss:Dictionary=Combat.boss("sky");boss.merge({"pos":Vector2(700,1050),"uid":7001,"attack":Attack.new(),"face":-1.0,"max_hp":72.0},true)
	var behaviors:int=boss["movements"].size()+boss["attacks"].size();scene._adapt_boss(boss)
	check(boss["adaptations"].size() in [1,2] and boss["movements"].size()+boss["attacks"].size()==behaviors+boss["adaptations"].size(),"Boss adds one or two extra behaviors")
	scene.drops.clear();scene._enemy_defeated(boss)
	check(scene.drops.any(func(d):return d["kind"]=="rune" and int(d["value"])>=Data.RUNES.size()) and scene.drops.any(func(d):return d["kind"]=="weapon"),"Boss guarantees a strong rune and secondary weapon")
	# New weapons exercise real projectiles, explosions, beam intersections and chains.
	scene.solids.clear();scene.platforms.clear();scene.props.clear();scene.projectiles.clear();scene.enemies.assign([target(Vector2(650,1021),1),target(Vector2(780,1021),2)]);scene.camera_pos=Vector2(200,500)
	for i in range(6,Data.SECONDARY.size()):
		var def:Dictionary=Data.secondary_attack(i)
		scene._emit_weapon(Vector2(500,1000),Vector2.RIGHT,def,true)
		if def["weapon_kind"]=="bounce":check(scene.projectiles.size()==5 and scene.projectiles[0]["bounces"]==5,"New ricochet emits five bouncing shots")
		elif def["id"]=="impact_bomb":check(scene.projectiles[-1]["explode_on_hit"],"Impact bomb carries explosion behavior")
		elif def["id"]=="fire_flask":check(scene.projectiles[-1]["ground_fire"],"Fire flask carries floor-burning behavior")
		elif def["weapon_kind"]=="laser":check(scene.enemies[0]["hp"]<2000 and scene.enemies[1]["hp"]<2000,"Instant laser penetrates both enemies")
		elif def["weapon_kind"]=="wave":check(scene.projectiles[-1]["pierce"] and scene.projectiles[-1]["vel"].x<0,"Shockwave emits opposite piercing waves")
		elif def["weapon_kind"]=="chain":check(scene.effects.any(func(e):return e.has("lightning")),"Staff jumps lightning across live targets")
		scene.projectiles.clear()
	scene._update_visual_effects(.01)
	scene.rune_slots.assign(["multishot"]);scene.bag_weapons.assign([Data.secondary_attack(0)]);scene.secondary_index=0
	check(scene._secondary()["count"]==2,"Projectile rune adds one real projectile")
	scene.rune_slots.assign(["dewflow"]);scene.p["energy"]=1;scene.passive_energy=0;scene.last_motion_pos=scene.p["pos"];scene._update_passives(8.01)
	check(scene.p["energy"]==2,"Energy rune restores a whole cell on schedule")
	# Death lands, holds, offers a rune, then returns to checkpoint with a recoverable cache.
	var old_seed:int=int(scene.tower["seed"]);var vault:Dictionary=scene.meta["runes"].duplicate()
	scene._close_panel();scene.enemies.clear();scene.solids.clear();scene.platforms.assign([Rect2(0,1050,1500,70)]);scene._reset_player(Vector2(700,200));scene.injured=false;scene.revive_used=true;scene._death()
	for i in 20:scene._update_life_event(.02)
	check(not scene.life_event.is_empty() and not scene.life_event.get("landed",false),"Death flight does not end in midair")
	for i in 400:
		if scene.life_event.get("landed",false):break
		scene._update_life_event(.01)
	check(scene.life_event.get("landed",false),"Death reaches supporting floor before restart")
	scene._update_life_event(1.11)
	check(scene.life_event.get("kind")=="await_choice" and scene.ui.is_panel_open(),"Landed death offers the rune choice")
	scene._choose_soul_rune("");scene._update_life_event(1.41)
	check(scene.life_event.is_empty() and int(scene.tower["seed"])==old_seed and not scene.feather.is_empty(),"Death returns to checkpoint and preserves recoverable cache")
	check(scene.meta["runes"]==vault and scene.bag_runes.is_empty(),"Stored runes survive while carried runes remain in the feather")
	# Record and victory return preserve rewards and exact weapon / kill / death data.
	scene.bag_weapons.assign([Data.secondary_attack(8)]);scene.kills=42;scene.deaths=3;scene.run_coins=17;scene._complete_run()
	check(scene.meta["records"][0]["kills"]==42 and scene.meta["records"][0]["deaths"]==3 and scene.meta["records"][0]["secondary"][0]=="穿星雷射","Completion records the actual loadout and counters")
	scene._update_life_event(2.5);check(scene.screen=="hub" and scene.ui.is_panel_open(),"Victory flight ends at the nest record board")
	scene.meta=saved;scene._save_meta();scene.combat_feedback.clear();scene.queue_free();await process_frame
	print("v0.8: ","passed: movement/cancel, glyphs, keyboard, hazards, shop, loot, special weapons, rune energy, injury, checkpoint and victory records" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
