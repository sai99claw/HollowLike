extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Coins=preload("res://scripts/coin_physics.gd")
const Field=preload("res://scripts/coin_field_v16.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
const Explode=preload("res://scripts/explosion_v16.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	var world:Dictionary=Tower.generate(16016);var ledges:int=0
	for room:Dictionary in world["rooms"]:
		var result:Dictionary=Layout.generate(room,16016)
		check(Layout.validate(result).is_empty(),"Clear entries "+str(room["id"]))
		check(result["door_width"]==3,"Three-cell door contract")
		for direction in result["maze_doors"]:
			var at:Vector2i=result["maze_doors"][direction];var tangent:=Vector2i(1,0) if direction in ["up","down"] else Vector2i(0,1)
			for offset in [-1,0,1]:
				var cell:Vector2i=at+tangent*offset;check(result["maze_grid"][cell.y][cell.x]==1,"Every door really carves three boundary cells")
		check(result["random_one_way"].size()<=9,"Bounded sparse pass-through platforms")
		check(result["random_one_way"].size()==result["platform_voids"].size(),"Every ledge records its source void")
		for i in result["random_one_way"].size():
			var area:Rect2=result["platform_voids"][i];var ledge:Rect2=result["random_one_way"][i]
			check(area.size.x>5*result["tile_size"] and area.size.y>5*result["tile_size"] and area.encloses(ledge),"Ledges only occupy voids greater than5x5")
			ledges+=1
		if result["single_screen"]:check(result["size"]==Vector2(1632,1056),"Functional rooms have compact authored scale")
	for i in Data.SECONDARY.size():
		if Data.SECONDARY[i]["kind"]=="throw":check(Data.secondary_attack(i)["windup"]==0.0,"Throw has zero windup "+str(i))
	var coin:Dictionary={"pos":Vector2(300,493),"vel":Vector2.ZERO};Coins.initialize(coin)
	for i in 30:Coins.step(coin,1.0/60,[Rect2(0,500,1000,40)])
	check(coin.get("sleeping",false),"Resting coin sleeps")
	var resting:Vector2=coin["pos"];Coins.step(coin,1.0/60,[]);check(coin["pos"]==resting,"Sleeping coin needs no support query")
	coin["vel"]=Vector2(60,0);Coins.step(coin,1.0/60,[Rect2(0,500,1000,40)]);check(not coin["sleeping"] and coin["pos"].x>resting.x,"Coin wakes and rolls")
	var pair:Array=[{"kind":"coin","pos":Vector2(200,493),"vel":Vector2(100,0),"grounded":true},{"kind":"coin","pos":Vector2(210,493),"vel":Vector2.ZERO,"grounded":true}]
	Field.collide(pair);check(pair[0]["pos"].distance_to(pair[1]["pos"])>=13.99 and pair[1]["vel"].x>0,"Separate coins collide and transfer momentum")
	var hit:Dictionary=Explode.contact(Vector2(250,491),Vector2(0,300),[Rect2(0,500,1000,60)],10)
	check(hit.get("normal",Vector2.ZERO)==Vector2.UP and hit["point"].y==500,"Surface explosion uses exact contact plane")
	for surface in [false,true]:
		for index in 8:check(Explode.texture(surface,index)!=null,"All sixteen explosion frames imported")
	Catalog.clear_cache();var catalog:Array=Catalog.all_entries();check(catalog.size()>=490 and Catalog.cache_size()==0,"All art indexed without eager texture decode")
	for entry:Dictionary in catalog:
		check(entry["frame_count"]==entry["frames"].size() and not Catalog.sequence(entry).is_empty(),"Catalog sequence remains valid: "+str(entry["id"]))
		if entry.get("kind","")!="procedural":check(Catalog.frame(entry,0)!=null,"RD real texture loads: "+str(entry["id"]))
	Catalog.clear_cache()
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame;scene.set_process(false);scene.set_physics_process(false)
	var original:Dictionary=scene.meta.duplicate(true);scene.meta["rd_tuning"]={"fountain_chance":1.0};scene.new_run("rogue",16016);scene._close_panel()
	scene.drops.clear();scene._drop("coin",Vector2(650,400),30);scene._drop("coin",Vector2(650,400),1)
	check(scene.drops.size()==31 and scene.drops.all(func(d):return d["value"]==1),"Thirty gold creates thirty bodies; nearby gold never merges")
	var positions:Dictionary={}
	for d in scene.drops:positions[d["pos"]]=true
	check(positions.size()>=30,"Gold launches with separated starting positions")
	var reward:int=-1;var bath_room:int=-1
	for room in scene.tower["rooms"]:
		if room["type"]=="reward":reward=room["id"]
		if room.get("fountain",false):bath_room=room["id"]
	check(reward>=0 and bath_room>=0,"Reward and spring fixtures exist")
	if reward>=0:
		scene._enter_room(reward);var choices:Array=scene._reward_choices().duplicate(true);var before:int=scene.bag_weapons.size();scene._claim_reward(1);scene._claim_reward(1)
		check(scene.bag_weapons.size()==before+1 and scene.room["reward_selected"]==1,"Reward table grants exactly one choice")
		scene._enter_room(reward);check(scene._reward_choices()==choices and scene.room["reward_claimed"],"Re-entry preserves choices and claim")
		var urns:int=0
		for prop:Dictionary in scene.props:
			if prop["kind"]=="coin_urn":
				urns+=1;var before_coins:int=scene.drops.size();scene._hit_props(Rect2(prop["pos"]-Vector2(40,80),Vector2(80,81)),1,999)
				check(prop["used"] and scene.drops.size()==before_coins+prop["coins"],"Coin urn breaks into exact gold count")
		check(urns==3,"Three breakable gold urns decorate reward room")
	if bath_room>=0:
		scene._enter_room(bath_room);scene._process(.016)
		check(not scene.atmosphere.quiet_room and scene.props.any(func(p:Dictionary)->bool:return p["kind"]=="fountain"),"Fountain retains combat-room ecology rather than becoming an indoor bath")
	scene._ui_action("hub",null);var saved:Dictionary=scene.meta.duplicate(true);scene._enter_practice();scene._close_panel()
	check(scene.lab_mode=="practice" and scene.bag_weapons.size()==preload("res://scripts/arsenal_v24.gd").IDS.size(),"Home practice room exposes all nine current secondary weapons")
	for rune in Data.all_runes():check(scene.bag_runes.get(rune["id"],0)>0,"Every rune available in practice")
	for i in 17:scene._summon_monster(i)
	check(scene.enemies.size()==19,"All17monster variants plus two dummies can be summoned")
	var active_boss:Dictionary=scene.enemies[-1];active_boss["combat_engaged"]=true;var boss_at:Vector2=active_boss["pos"];active_boss["pos"]=Vector2(10000,-5000)
	check(scene._in_aggro(active_boss),"Engaged boss cannot freeze permanently after leaving camera")
	active_boss["pos"]=boss_at
	for i in 20:scene._physics_process(.016)
	check(scene.p["energy"]==scene.p["max_energy"] and scene.p["invul"]>0,"Practice supplies energy and prevents accidental death")
	scene._leave_lab();check(scene.screen=="hub" and scene.meta==saved and scene.lab_mode.is_empty(),"Leaving practice restores real profile exactly")
	scene._open_rd();await process_frame
	check(scene.rd_view!=null and scene.lab_mode=="rd","Home RD entry opens inspector")
	var viewer=scene.rd_view
	check(viewer._notes.get_global_rect().end.y<=720,"RD controls and description fit the viewport")
	viewer.select_entry("explosion:surface");viewer.pause();viewer.set_fps(27);viewer.seek_frame(6)
	check(viewer.frame_index==6 and viewer.fps==27 and viewer.current_entry["frame_count"]==8,"RD FPS and manual frame selection control full atlas")
	viewer.select_entry("home:nest")
	check(viewer.current_entry["frame_count"]==1 and viewer._play_button.disabled,"Single-image asset starts with one preview slot")
	var original_texture:Texture2D=viewer._preview.texture
	viewer._insert_blank.pressed.emit()
	check(viewer.frame_index==1 and viewer._preview.texture==null and not viewer._play_button.disabled,"Inserting a blank enables playback for a still image")
	viewer.set_fps(10.5);viewer.play();viewer._process(.10)
	check(viewer.frame_index==0 and viewer._preview.texture==original_texture,"The FPS control loops from a blank back to the image")
	viewer.toggle_frame_visibility()
	check(not viewer.playing and viewer._preview.texture==null and viewer._timeline.size()==2,"A hidden frame keeps its slot and pauses preview")
	viewer.toggle_frame_visibility()
	check(viewer._preview.texture==original_texture,"A hidden frame can be restored")
	viewer.seek_frame(1);viewer.remove_blank_frame()
	check(viewer.frame_index==0 and viewer._play_button.disabled and viewer._preview.texture==original_texture,"Removing the blank restores the single-frame timeline")
	viewer.insert_blank_frame();viewer.reset_preview()
	check(viewer._timeline.size()==1 and viewer.fps==float(viewer.current_entry["fps"]),"Reset restores original timing and slots")
	check(Catalog.sequence(viewer.current_entry)==[0],"Temporary edits leave the asset catalog untouched")
	viewer.select_entry("procedural:water");viewer.seek_frame(35);check(viewer.frame_index==35 and viewer._procedural.visible,"Procedural water also supports frame inspection")
	viewer.toggle_frame_visibility()
	check(not viewer._procedural.visible,"Hiding a procedural frame also clears the preview")
	viewer.toggle_frame_visibility()
	check(viewer._procedural.visible,"Showing a procedural frame restores the preview")
	viewer._close();await process_frame;check(scene.lab_mode.is_empty() and Catalog.cache_size()==0,"Closing RD releases cache and resumes home")
	scene.meta=original;scene._save_meta();scene.queue_free();await process_frame
	print("v16: ",ledges," sparse ledges, ",catalog.size()," art entries; ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
