extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const FX=preload("res://scripts/combat_visual.gd")
const Walk=preload("res://scripts/walk_animation.gd")
const Atmosphere=preload("res://scripts/atmosphere.gd")
const Adventure=preload("res://scripts/adventure_visual.gd")
const Wildlife=preload("res://scripts/ambient_wildlife.gd")
const Design=preload("res://scripts/monster_design.gd")
const Combat=preload("res://scripts/combat_library.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame;scene.set_process(false);scene.set_physics_process(false)
	var saved:Dictionary=scene.meta.duplicate(true)
	scene.new_run("rogue",1063);scene._close_panel();scene.room_cooldown=0;scene.props.clear();scene.drops.clear();scene.p["pos"]=Vector2(600,1050)
	# Each direction/combo gets vertical-only geometry growth, including charged spins.
	for charged in [false,true]:
		for combo in 3:
			for direction in ["up","down","left","right"]:
				var def:Dictionary=Data.primary_attack(1,direction,charged,false,combo)
				var prior:Dictionary=def.duplicate(true);prior.erase("hitbox_height_mult")
				var now:Rect2=scene._attack_box(Vector2(600,700),def,1);var old:Rect2=scene._attack_box(Vector2(600,700),prior,1)
				check(is_equal_approx(now.size.y,old.size.y*1.2) and is_equal_approx(now.size.x,old.size.x) and now.get_center().is_equal_approx(old.get_center()),"Featherblade grows only hitbox height by 1.2 in every direction")
				check(def["animation_speed"]==1.5 and (charged and def["active"]==1.0 or not charged and is_equal_approx(def["active"],.12)),"Faster featherblade preserves fixed one-second charged attack")
	# Presses made during each unavailable phase do not arm a later release.
	for phase in ["windup","active","recovery"]:
		scene.p_attack.cancel();scene._clear_keys();scene.p_attack.begin(Data.primary_attack(0,"right",false));scene.p_attack.phase=phase
		scene._set_action("attack",true);scene.p_attack.cancel();scene._set_action("attack",false)
		check(scene.pending_attack.is_empty() and not scene._key("attack"),"Unavailable attack press is discarded: "+phase)
	scene.p["hurt"]=.2;scene._set_action("attack",true);scene.p["hurt"]=0;scene._set_action("attack",false)
	check(scene.pending_attack.is_empty(),"Press while hurt is discarded even if released after recovery")
	scene._set_action("attack",true);scene.charge_timer=.5;scene._process(.01)
	await process_frame
	check(not scene.gameplay_vfx.commands[scene.VFX.VORTEX].is_empty(),"Holding valid attack draws the shared inward charge vortex")
	var clip:Dictionary=FX.definition("pigeon_feather_charge")
	check(FX.sample_index(clip,0,"idle",.1)!=FX.sample_index(clip,0,"idle",.3),"Charge artwork changes frames while holding")
	scene._set_action("attack",false);check(scene.pending_attack.is_empty() and scene.p_attack.is_active(),"Available click starts immediately and release does not queue a second attack")
	scene.pending_attack.clear();scene._process(.01);await process_frame
	check(scene.gameplay_vfx.commands[scene.VFX.VORTEX].is_empty(),"Release clears the charge vortex")
	check(Vector2(Walk.clip()["frames"][0]["size"][0],Walk.clip()["frames"][0]["size"][1])==Vector2(256,256) and load(Walk.ROOT+Walk.clip()["frames"][0]["path"]).get_width()==256,"Walk uses high resolution source, matching combat texture density")
	# Cut grass emits the same sharp attack flash and cannot be farmed repeatedly.
	scene.props.assign([{"kind":"grass","pos":Vector2(650,1050),"seed":.1,"used":false,"hurt":0.0}]);scene.p_attack.cancel();scene.p_attack.begin(Data.primary_attack(1,"right",false));scene.p_attack.phase="active"
	var flashes:int=scene.combat_feedback.flashes.size();scene._hit_props(Rect2(620,990,80,70),3)
	check(scene.props[0]["used"] and scene.combat_feedback.flashes.size()==flashes+1,"Cutting grass triggers a real attack light flash")
	scene._hit_props(Rect2(620,990,80,70),3);check(scene.combat_feedback.flashes.size()==flashes+1,"A cut tuft produces only one impact")
	# Carrier radius is removed at contact; top surfaces include solid columns.
	scene.platforms.assign([Rect2(400,700,300,20),Rect2(0,1050,1500,70)]);scene.solids.assign([Rect2(800,550,100,300)])
	check(scene._trap_surface({"pos":Vector2(500,692),"radius":8})==Vector2(500,700),"Trap lands on platform surface, not eight pixels above it")
	check(scene._trap_surface({"pos":Vector2(850,542),"radius":8})==Vector2(850,550),"Trap follows solid-column top")
	check(scene._trap_surface({"pos":Vector2(790,620),"radius":8}).y==1050,"Side collision cannot leave a floating mine")
	var attack:Dictionary=Combat.attack("trap",Design.regular_attack("drift"));scene.hazards.clear();scene._settle_trap({"pos":Vector2(500,692),"radius":8,"definition":attack})
	check(scene.hazards[0]["pos"].y==700 and scene.hazards[0]["hp"]==1 and scene.hazards[0]["hazard_visual_id"]=="pollen_flower","Settled trap keeps species texture, one HP and grounded anchor")
	# Room interaction keys no longer teleport; crossing the passage does.
	scene.p_attack.cancel();scene._clear_keys();scene.props.clear();scene.drops.clear();scene.room_cooldown=0
	var door:Dictionary={}
	for candidate in scene.doors:
		if candidate["dir"] in ["left","right","down"]:door=candidate;break
	check(not door.is_empty(),"Door transition fixture exists")
	if not door.is_empty():
		var previous:int=scene.current_room;scene.p["pos"]=door["pos"]
		scene._interact();check(scene.current_room==previous and not scene._world_confirm(),"E and attack near an open door do not enter it")
		var crossed:Vector2=door["pos"]
		if door["dir"]=="down":crossed.y=scene._room_size().y-20
		scene.p["pos"]=crossed;scene._check_portals();check(scene.current_room==int(door["target"]),"Walking through portal transitions automatically")
	for direction in ["left","right","down"]:
		var fixture:Dictionary={}
		for candidate:Dictionary in scene.tower["rooms"]:
			if not candidate["neighbors"].has(direction):continue
			var neighbor:Dictionary=scene.tower["rooms"][int(candidate["neighbors"][direction])]
			if candidate["map_index"]==neighbor["map_index"]:fixture=candidate;break
		check(not fixture.is_empty(),"Physical passage fixture exists: "+direction)
		if fixture.is_empty():continue
		scene._enter_room(int(fixture["id"]));scene._close_panel();scene._clear_keys();scene.room_cooldown=0
		var previous:int=scene.current_room
		var opening:Vector2=scene.layout["doors"][direction]
		scene._reset_player(Vector2(100 if direction=="left" else scene._room_size().x-100,opening.y) if direction!="down" else Vector2(opening.x,scene._room_size().y-75))
		if direction!="down":scene._set_action(direction,true)
		for step in 180:
			scene._update_player(1.0/120);scene._check_portals()
			if scene.current_room!=previous:break
		check(scene.current_room==int(fixture["neighbors"][direction]),"Actual movement crosses the physical "+direction+" passage without a button")
		scene._clear_keys()
	# Rain is room-seeded, only outdoors, honors mute, has two separate depth planes.
	check(Atmosphere.is_rainy("branches",12) and not Atmosphere.is_rainy("branches",13) and not Atmosphere.is_rainy("underground",12),"Selected outdoor rooms have stable rain conditions")
	scene.atmosphere.configure("branches",12,true);scene.atmosphere.set_audio_enabled(false)
	check(scene.atmosphere.rain_layers.size()==2 and scene.atmosphere.rain_layers[0].emitting and not scene.atmosphere.rain_audio.playing,"Rain layers work while audio mute is respected")
	check(scene.atmosphere.rain_layers[0].z_index<scene.atmosphere.rain_layers[1].z_index and scene.atmosphere.rain_audio.stream.loop_mode!=0,"Rain sound loops and far/middle rain use distinct depth planes")
	scene.atmosphere.configure("branches",13,true);check(not scene.atmosphere.rain_layers[0].visible,"Clear room hides rain")
	check(Wildlife.depth_size(.8)<Wildlife.depth_size(.2)*.6 and Wildlife.depth_alpha(.95)<.02,"Bird travels from middle distance to a small fading silhouette")
	var a:Dictionary=Adventure.portal_mote(Vector2(740,1050),.3,0);var b:Dictionary=Adventure.portal_mote(Vector2(740,1050),1.3,0)
	check(b["radius"]<a["radius"] and a["alpha"]>0 and a["alpha"]<=.85,"Dense colored particles converge toward the door")
	check(load("res://assets/atmosphere_v10/spring.png") is Texture2D,"New illustrated spring atlas is included in export")
	scene.meta=saved;scene._save_meta();scene.combat_feedback.clear();scene.queue_free();await process_frame
	print("v0.10 integration: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
