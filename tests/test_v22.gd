extends SceneTree
const Atlas=preload("res://scripts/atlas_v22.gd")
const Corpse=preload("res://scripts/corpse_field_v21.gd")
const Trap=preload("res://scripts/trap_visual_v22.gd")
const Surface=preload("res://scripts/surface_art_v22.gd")
const Motion=preload("res://scripts/monster_motion_v18.gd")
const Pigeon=preload("res://scripts/pigeon_motion_v22.gd")
const Arms=preload("res://scripts/armament.gd")
const Combat=preload("res://scripts/combat_library.gd")
const Data=preload("res://scripts/game_data.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
const TowerMap=preload("res://scripts/tower_map_view.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok and failures.size()<35:failures.append(message);push_error(message)
func reset(game,at:Vector2=Vector2(700,1050)) -> void:
	game._clear_keys();game._close_panel();game.p_attack.cancel();game._reset_player(at);game.hitstop=0;game.room_cooldown=999;game.lab_mode="";game.injured=false;game.life_event.clear()
	game.enemies.clear();game.props.clear();game.doors.clear();game.effects.clear();game.projectiles.clear();game.hazards.clear();game.solids.clear();game.corpses.clear()
	game.layout={"size":Vector2(1500,1120),"floor_y":1050.0};game.platforms.assign([Rect2(0,1050,1500,70)]);game.world_speed=1;game.p["invul"]=0
func run() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=220022
	var actors:Array[Dictionary]=[]
	for species:String in ["walk","jump","hover","drift","dash","pillbug"]:
		actors.append(Arms.cute_wanderer(rng) if species=="pillbug" else Arms.enemy(species,rng))
	for biome:String in Combat.BOSS_BIOMES:actors.append(Combat.boss(biome))
	for en:Dictionary in actors:
		en.merge({"pos":Vector2(700,600),"face":1.0,"death_direction":Vector2.RIGHT,"death_knockback":90.0},true)
		var id:String=Motion.identity(en);var clip:Dictionary=Atlas.clip("death",id);var hashes:Dictionary={}
		check(clip.get("frames",[]).size()==8,"Each species owns eight death poses: "+id)
		for index in 8:
			hashes[clip["frames"][index]["sha256"]]=true
			check(Atlas.frame("death",id,index)!=null,"Export includes every death frame: "+id)
		check(hashes.size()==8,"Death is authored, not a scaled/rotated repeated image: "+id)
		var body:Dictionary=Corpse.create(en);check(body["vel"].x>0 and body["vel"].y<0,"Death launches in actual attack direction")
		var observed:Dictionary={}
		for tick in 180:Corpse.step(body,1.0/60,[],[Rect2(0,800,1500,60)],Vector2(1500,1120));observed[body["frame"]]=true
		check(body["settled"] and body["frame"]==7 and is_equal_approx(body["pos"].y,800),"Corpse physically lands, plays collapse and holds prone final art: "+id)
		check(observed.has(4) and observed.has(5) and observed.has(6),"Landing does not skip its authored collapse poses")
		var at:Vector2=body["pos"];Corpse.step(body,100,[],[],Vector2(1500,1120));check(body["pos"]==at,"Resting corpse sleeps permanently")
		en["death_direction"]=Vector2.LEFT;check(Corpse.create(en)["vel"].x<0,"Left attack produces leftward death, independent of enemy facing")
		var size:Vector2=Motion.body_size(en);var visible:Array=Motion.definition(id)["frames"][0]["visible_bounds"]
		check(size.is_equal_approx(Vector2(visible[2],visible[3])*Motion.factor_for(en)*.9),"Enemy collider is ten percent smaller than its own resting art")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",220022)
	for side in [-1,1]:
		for vy in [-300.0,0.0,30.0]:
			reset(game,Vector2(700-side*17,600));game.solids.assign([Rect2(700 if side>0 else 604,0,96,1050)]);game.p["grounded"]=false;game.p["vel"]=Vector2(0,vy);game._update_player(.01)
			if vy<0:check(game.p["wall"]==0,"A rising jump does not attach to walls")
			else:check(game.p["wall"]==side and game.p["wall_hold_left"]>0,"Wall contact attaches at the apex or on descent")
		reset(game,Vector2(700-side*17,600));game.solids.assign([Rect2(700 if side>0 else 604,0,96,1050)]);game.p["grounded"]=false;game.p["vel"]=Vector2(0,250);game._update_player(.01)
		check(game.p["wall"]==side and game.p["vel"].y==0 and game.p["wall_hold_left"]>0,"Falling wall contact begins the one-second hold before36px/sec slide")
		reset(game,Vector2(700-side*40,600));game.solids.assign([Rect2(700 if side>0 else 604,0,96,1050)]);game.p["grounded"]=false;game.p["face"]=side;game.clock+=2;game._dash_pressed();game._update_player(.08)
		check(game.p["wall"]==side and game.p["dash_t"]==0,"Single C into an actual wall latches without visual compensation")
	reset(game);game.solids.assign([Rect2(0,1050,1500,70)]);game.p["pos"]=Vector2(700,1050)
	var definition:Dictionary=Combat.attack("trap",{"hazard_visual_id":"pollen_flower","size":60,"damage":1,"max_hits":3,"arming_time":.8,"hit_interval":1.0})
	game._settle_trap({"pos":Vector2(700,1042),"radius":8,"definition":definition});check(game.hazards.size()==1,"Thrown trap plants on a real support")
	var trap:Dictionary=game.hazards[0];var planted:Vector2=trap["pos"]
	game._update_hazards(.79);check(game.p["hp"]==5 and Trap.frame_index(trap)==4,"Installation completes through five visible poses before any damage")
	game._update_hazards(.02);check(game.p["hp"]==4 and Trap.armed(trap),"Only fully installed trap deals damage")
	check(Trap.body_box(trap).end.y<=planted.y+.1 and Trap.body_box(trap).size.x<70,"Trap damage occupies its compact solid artwork, not a diffuse expanding aura")
	game._damage_traps(Trap.body_box(trap),1);game._update_hazards(.01);check(game.hazards.is_empty(),"A oneHP planted trap can be destroyed through the same bodybox")
	reset(game);game.bag_runes.clear();game.rune_slots.clear();game.strong_slots.clear();game._give_drop("rune",0)
	check(game.rune_slots.size()==1 and game.rune_slots[0]==Data.RUNES[0]["id"],"Rune pickup automatically fills an empty small slot")
	game.rune_slots.resize(16);game.rune_slots.fill(Data.RUNES[0]["id"]);game._give_drop("rune",1)
	check(game.rune_slots.count(Data.RUNES[1]["id"])==0 and int(game.bag_runes[Data.RUNES[1]["id"]])==1,"Full small board stores the pickup instead of replacing a rune")
	game._give_drop("rune",Data.RUNES.size());check(game.strong_slots.size()==1,"Strong rune pickup independently fills its large slot")
	game._cycle_map();game._cycle_map();game._cycle_map();check(game.minimap_page==2,"Third map press switches to full tower")
	var overview:Array=TowerMap.full_tower_layout(game.tower,Rect2(180,155,915,422));var rooms:int=0
	for chapter:Dictionary in overview:rooms+=chapter["graph"]["points"].size()
	check(overview.size()==6 and rooms==game.tower["rooms"].size(),"Full tower overview includes every chapter and room")
	game._set_action("left",true);check(game.minimap_page==1,"Left switches back without moving the player");game._set_map_held(false)
	reset(game,Vector2(700,1040));game.layout["pool"]=Rect2(400,1000,600,100);game.room["spring"]=true;game._set_action("attack",true)
	check(game.spring_particles.bursts.size()==1 and game.effects.filter(func(e:Dictionary)->bool:return e.has("water_attack")).is_empty(),"Water attack uses native droplets without authored splash sprites")
	check(game.spring_particles.bursts[0].texture is GradientTexture2D and game.spring_particles.bursts[0].position.y==1000,"Droplets originate on the actual waterline")
	var cycle:Dictionary={}
	for index in 16:cycle[Pigeon.drowsy_index(6.001+float(index)/8)]=true
	check(cycle.size()==8 and Pigeon.drowsy_index(7.001)==0,"After settling, drowsy head nod continues in an eightFPS loop")
	for library:String in ["monster-actions","boss-actions","pigeon-motion"]:
		var data:Dictionary=Atlas.metadata(library)
		check(not data.is_empty(),"Every rebuilt actor library is exported: "+library)
		for clip:Dictionary in data.get("clips",data.get("animations",{})).values():check(float(clip["reference_height"])/float(clip["world_height"])>(1.5 if library=="boss-actions" else 1.8),"New actor art has enough native density at its fixed world scale")
	game._ui_action("hub",null);game._enter_practice();game._open_practice_rd();await process_frame
	check(game.practice_rd_panel!=null and game.practice_rd_panel.editors.has("biome"),"Practice exposes a real RD room-generation form")
	var weapons:int=game.bag_weapons.size();game.practice_rd_panel.set_value("biome","sky");game.practice_rd_panel.set_value("seed",2222);game.practice_rd_panel.set_value("width",23);game.practice_rd_panel.set_value("height",15);game.practice_rd_panel.set_value("enemy_density",0);game.practice_rd_panel.apply();await process_frame
	check(game._ecology()["id"]=="sky" and game.layout["size"]==Vector2(23*96,15*96) and game.enemies.is_empty() and game.bag_weapons.size()==weapons,"Regeneration applies biome/seed/dimensions and zero monsters, preserving equipment")
	var geometry:Array=game.layout["solids"].duplicate();game._regenerate_practice(game.practice_rd_settings)
	check(game.layout["solids"]==geometry,"Practice room seed is reproducible")
	# Room ecology must not rewrite the identity of a specifically summoned Boss.
	game._regenerate_practice({"biome":"sky","arena":true,"seed":2223,"width":25,"height":15,"enemy_density":0})
	var identities:Array[String]=["underground","grass","trunk","branches","canopy","sky"]
	for index in 6:
		var before:int=game.enemies.size();game._summon_monster(11+index)
		check(game.enemies.size()==before+1 and game.enemies[-1]["biome"]==identities[index],"Practice Boss keeps its own identity in a different biome")
		if game.enemies.size()>before:check(not game.solids.any(func(rock:Rect2)->bool:return game._enemy_body_box(game.enemies[-1]).grow(-.1).intersects(rock)),"Summoned body fits actual terrain")
	for ledge:Rect2 in game.layout["one_way"]:check(roundi(ledge.size.x) in [96,192,288,384],"Only four exact fixed platform lengths exist")
	for biome:String in ["sky","trunk","underground"]:
		var data:Dictionary=Surface.definition(biome);check(data["platforms"].size()==4,"Each biome has four separately authored platform images")
		for count in range(1,5):check(data["platforms"][str(count)]["cells"]==count,"Platform metadata matches actual collision length")
	game._leave_lab();game._open_rd();await process_frame
	var rd=game.rd_view;rd.set_view("gallery");await process_frame
	check(rd._gallery.visible and rd.gallery_cards.size()==mini(12,rd.filtered_entries.size()),"RD matrix is paged and shows first-frame cards")
	rd._usage.select(2);rd._filter();check(not rd.filtered_entries.is_empty() and rd.filtered_entries.all(func(e:Dictionary)->bool:return e["runtime_usage"]=="un-used"),"Unused filter marks archived textures explicitly")
	rd._search.text="v22:death:walk";rd._usage.select(0);rd._filter();check(rd.filtered_entries.size()==1 and rd.filtered_entries[0]["runtime_usage"]=="used","ID search finds the implemented own-species death animation")
	rd.select_entry(rd.filtered_entries[0]);rd.set_view("inspector");check(rd._asset_id.text=="v22:death:walk" and not rd._asset_id.editable,"Inspector exposes a selectable, copyable stable asset ID")
	rd._close();game.queue_free();await process_frame
	print("v22: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
