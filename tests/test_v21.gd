extends SceneTree
const Tower=preload("res://scripts/tower.gd")
const Map=preload("res://scripts/tower_map_view.gd")
const Collision=preload("res://scripts/world_collision.gd")
const Biome=preload("res://scripts/biome_art_v21.gd")
const Arms=preload("res://scripts/armament.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok and failures.size()<30:failures.append(label);push_error(label)
func reset(game,at:Vector2=Vector2(700,1050)) -> void:
	game.life_event.clear();game._close_panel();game._clear_keys();game.p_attack.cancel();game._reset_player(at);game.hitstop=0;game.room_cooldown=999;game.lab_mode="";game.screen="game"
	game.enemies.clear();game.props.clear();game.doors.clear();game.effects.clear();game.projectiles.clear();game.hazards.clear();game.solids.clear();game.drops.clear();game.corpses.clear()
	game.layout={"size":Vector2(1500,1120),"floor_y":1050.0};game.platforms.assign([Rect2(0,1050,1500,70)]);game.coin_field.rebuild(game.platforms,game.solids);game.world_speed=1;game.p["invul"]=0
func run() -> void:
	var total_rooms:int=0
	for seed_value in 100:
		var tower:Dictionary=Tower.generate(seed_value);check(Tower.validate(tower).is_empty(),"Whole tower, farthest Boss and side doors validate: "+str(seed_value))
		for room:Dictionary in tower["rooms"]:
			if room["type"] in ["start","merchant","reward"] or room.get("spring",false):check(room["width"]==17 and room["height"]==11,"Functional-room dimensions agree with the stitched world grid")
		for stage:Dictionary in tower["maps"]:
			check(stage["room_ids"].size()>=9 and stage["room_ids"].size()<=11,"Default chapter has about ten rooms")
			var boss:Dictionary=tower["rooms"][stage["boss_id"]];var distances:Dictionary=Tower._distances(tower["rooms"],stage["start_id"],stage["index"])
			for rid:int in stage["room_ids"]:
				if rid!=boss["id"]:check(distances[rid]<distances[boss["id"]],"Boss is uniquely farthest by traversable doors")
			var directions:Array=boss["neighbors"].keys()
			check(not directions.has("up") and not directions.has("down"),"Boss entrance AND next-stage exit are on left/right")
			if stage["index"]<5:check(directions.size()==2 and directions.has("left") and directions.has("right"),"Enter one side, continue through the opposite side")
			var graph:Dictionary=Map.chapter_layout(tower,stage["start_id"],Rect2(180,155,700,422))
			check(graph["points"].size()==stage["room_ids"].size() and graph["stride"]>=60 and graph["stride_y"]>=42,"Player map has a full readable chapter with separated room cards")
			total_rooms+=stage["room_ids"].size()
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",212121)
	# Walk off a real support, then jump during the grace period.
	reset(game,Vector2(710,1050));game.platforms.assign([Rect2(0,1050,720,70)]);game.keys["right"]=true
	for step in 8:game._update_player(1.0/120)
	check(not game.p["grounded"] and float(game.p["coyote_left"])>0,"Walking off retains a short ground-jump grace")
	game.keys["right"]=false;game._set_action("jump",true);game._update_player(1.0/120)
	check(game.p["vel"].y< -500 and game.p["jumps"]==1,"Coyote jump uses the ground jump, preserving the air jump")
	reset(game,Vector2(700,800));game.p["grounded"]=false;game.p["jumps"]=2;game._update_player(.14);game._set_action("jump",true);game._update_player(.01)
	check(game.p["vel"].y>0,"Expired coyote time grants no extra jump")
	reset(game,Vector2(700,1042));game.p["grounded"]=false;game.p["jumps"]=2;game.p["vel"]=Vector2(0,200);game._set_action("jump",true);game._set_action("jump",false);game._update_player(.065)
	check(game.p["vel"].y<0 and game.p["jumps"]==1 and float(game.p["jump_buffer_left"])==0,"Pre-landing tap buffers once and still performs a short variable-height jump")
	reset(game,Vector2(700,700));game.p["grounded"]=false;game.p["jumps"]=2;game._set_action("jump",true);game._update_player(.8)
	check(game.p["grounded"] and game.p["vel"].y==0 and float(game.p["jump_buffer_left"])==0,"Expired jump buffer never fires on a later landing")
	var rocks:Array[Rect2]=[Rect2(100,0,100,100)]
	var corrected:Dictionary=Collision.move_body(Vector2(84,145),Vector2(0,-300),.02,Vector2(34,42),rocks,4)
	check(corrected["vel"].y<0 and absf(corrected["pos"].x-84)<=4 and corrected["pos"].x<84,"A shallow head corner shifts only within four pixels and preserves ascent")
	var blocked:Dictionary=Collision.move_body(Vector2(120,145),Vector2(0,-300),.02,Vector2(34,42),rocks,4)
	check(blocked["vel"].y==0,"Full ceiling obstruction cannot be bypassed by corner assistance")
	# All loot now launches and falls; none is snapped to a floor.
	reset(game,Vector2(100,100))
	for kind:String in ["coin","rune","weapon","item","heal","growth","upgrade"]:game._drop(kind,Vector2(700,600),1 if kind=="coin" else 0)
	check(game.drops.size()==7,"One actual loot entity per requested object")
	var horizontal:Dictionary={}
	for drop:Dictionary in game.drops:
		check(drop["vel"].y<0,"Every kind has an upward launch")
		check(float(drop["radius"])<(8 if drop["kind"]=="coin" else 22),"Loot collision radius is smaller than its visible icon")
		horizontal[drop["vel"].x]=true
	check(horizontal.size()>3,"Drop directions and distances have randomized launch velocities")
	for frame in 8:game._update_drops(1.0/60)
	check(game.drops.all(func(d:Dictionary)->bool:return d["pos"].y<600),"Every kind visibly rises before falling")
	for frame in 300:game._update_drops(1.0/60)
	check(game.drops.all(func(d:Dictionary)->bool:return d.get("grounded",false)),"Every loot kind lands on the real support")
	reset(game,Vector2(700,620));game._drop("item",Vector2(700,600),0);game._update_drops(.01)
	check(game.drops.size()==1,"New nearby non-coin loot survives launch pickup grace")
	# Stable species-specific corpses fall and persist across room revisits and death.
	game.new_run("rogue",212122);game._clear_keys();game.p["pos"]=Vector2(100,150);game.enemies.clear();game.props.clear();game.drops.clear()
	var rng:=RandomNumberGenerator.new();rng.seed=2121
	var en:Dictionary=Arms.enemy("hover",rng);en.merge({"uid":99,"pos":Vector2(700,500),"vel":Vector2.ZERO,"face":1.0,"hp":0.0,"max_hp":10.0,"attack":Attack.new()},true)
	game._enemy_defeated(en);var original:int=game.current_room;var body:Dictionary=game.corpses[0]
	for frame in 240:game._update_corpses(1.0/60)
	check(body["settled"] and body["pos"].y>500,"Flying enemy corpse falls to an actual floor and sleeps")
	var position:Vector2=body["pos"];game._update_corpses(300)
	check(game.corpses.size()==1 and body["pos"]==position and game.combat_feedback.corpses.is_empty(),"Corpse has no dissolve, TTL or transient ghost substitute")
	var adjacent:int=game.room["neighbors"].values()[0];game._enter_room(adjacent);game._enter_room(original)
	check(game.corpses.size()==1 and game.corpses[0]["identity"]==body["identity"],"Returning to a room retains its own-species corpse")
	game._respawn_from_soul();check(game.corpses.size()==1,"Player respawn does not erase retained corpses")
	reset(game);game._hurt_player(1,Vector2(800,1050));game._process(.001)
	check(float(game.p["flash_left"])>0 and game.player_flash_layer.material!=null,"Player now has an isolated whole-body white flash as well as hitstop")
	game.hitstop=0;game._set_map_held(true);var at:Vector2=game.p["pos"];var time:float=game.clock;game._physics_process(.2)
	check(game.p["pos"]==at and game.clock==time and not game.ui.header.visible,"Holding Tab pauses gameplay and clears overlapping HUD")
	game._set_map_held(false);check(game.ui.header.visible,"Releasing Tab restores the HUD")
	# Geometry rendering contracts cover all exposed combinations and seam phases.
	var ell:Array[Rect2]=[Rect2(0,0,192,96),Rect2(0,96,96,96)]
	var layout:Dictionary={"solids":ell,"reserved_regions":[]};Biome.prepare(layout,21)
	check(layout["art_corners_v21"].any(func(c:Dictionary)->bool:return c["inner"]),"L union identifies a concave inner corner")
	check(Biome.edges([Rect2(0,0,96,96),Rect2(96,0,96,96)]).size()==4,"Neighbour blocks share material; internal edges have no extra rim")
	check(Biome.REPEAT>=Biome.TILE*4,"Mirror changes span large sections, never one or two alternating cells")
	for biome:String in ["underground","trunk","sky"]:
		for i in 16:check(Biome.region(biome,"terrain",i%4,i/4)!=null,"Every terrain patch is imported")
		for i in 6:
			var hashes:Dictionary={}
			for row in range(1,5):
				var cell:Dictionary=Biome.cell_info(biome,"props",i,row);hashes[cell.get("sha256","")]=true
				check(cell.has("anchor") and cell.has("region"),"Each cut frame has authored region and floor anchor")
			check(hashes.size()==4,"Every breakable has four distinct authored poses")
	game.queue_free();await process_frame;print("v21: ",total_rooms," rooms /100seeds; ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
