extends SceneTree
const FX=preload("res://scripts/combat_visual.gd")
const Data=preload("res://scripts/game_data.gd")
const Arms=preload("res://scripts/armament.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Atmosphere=preload("res://scripts/atmosphere.gd")
const Feedback=preload("res://scripts/combat_feedback.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func fixture(at:Vector2) -> Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=12
	var en:Dictionary=Arms.enemy("walk",rng)
	en.merge({"uid":801,"pos":at,"vel":Vector2.ZERO,"face":-1.0,"hp":100.0,"max_hp":100.0,"stun":0.0,"hurt":0.0,"cooldown":10.0,"attack":Attack.new()},true)
	return en
func run() -> void:
	check(FX.ensure() and FX.manifest["animations"].size()==277,"All fifteen delivered batches are merged without overwriting earlier clips")
	var frames:int=0
	for id in FX.manifest["animations"]:
		var clip:Dictionary=FX.definition(id)
		for i in clip["frames"].size():
			var texture:Texture2D=FX.texture_for(id,i)
			check(texture!=null and texture.get_width()<=(1024 if "parallax" in id else 256) and texture.get_height()<=(1024 if "parallax" in id else 256),"Delivered image loads with bounded GPU memory")
			frames+=1
	check(frames==1193,"All 1193 delivered frames are available")
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame
	scene.set_physics_process(false);scene.set_process(false)
	var saved:Dictionary=scene.meta.duplicate(true)
	scene.practice_mode=true;scene.new_run("rogue",71059);scene._close_panel()
	# Alpha-space bounds map to the collision rectangle in every direction and combo.
	var mappings:int=0
	for weapon in 3:
		for direction in ["left","right","up","down"]:
			for charged in [false,true]:
				for combo in 3:
					var def:Dictionary=Data.primary_attack(weapon,direction,charged,false,combo)
					var target:Rect2=scene._attack_box(Vector2(650,700),def,-1 if direction=="left" else 1)
					var mapping:Dictionary=FX.attack_mapping(def["fx_clip"],target,direction)
					var basis:=Transform2D(mapping["angle"],Vector2(mapping["face"],1),0,target.get_center())
					var local:Rect2=Rect2(-mapping["local_size"]*.5,mapping["local_size"])
					var actual:Rect2=basis*local
					check(actual.position.distance_to(target.position)<.001 and actual.size.distance_to(target.size)<.001,"Visible attack bounds coincide with actual hitbox, including vertical and mirrored swings")
					check(mapping["source"].position!=Vector2.ZERO,"Transparent canvas padding is excluded from attack positioning")
					mappings+=1
	# Charge is now one complete mobile second; other actions cannot replace it.
	for weapon in 3:
		scene.p_attack.cancel();scene._clear_keys();scene._reset_player(Vector2(700,1050));scene.weapon_index=weapon;scene.p["energy"]=6
		scene._begin_primary({"dir":"right","charged":true});var id:int=scene.p_attack.attack_id
		check(scene.p_attack.is_active(),"Released charge starts immediately")
		scene._set_action("right",true);scene._set_action("jump",true);scene._set_action("dash",true);scene._set_action("sub",true)
		scene.bag_items["2"]=1;scene._use_item(2);scene._select_primary((weapon+1)%3);scene._update_player(.02)
		check(scene.p_attack.attack_id==id and scene.p_attack.is_active() and scene.p["pos"].x>700,"Active charge permits movement while keeping the original action")
		scene.p["invul"]=0;scene.p["shield"]=0;scene.p["hp"]=5;scene._hurt_player(2,Vector2(650,1050))
		check(scene.p_attack.is_active() and scene.p["hp"]==3,"Active armor takes damage without flinching")
		scene.p_attack.tick(1);check(not scene.p_attack.is_busy(),"The complete release finishes at one second without extra recovery")
	# Isolate enemy feedback from the newly introduced cuttable room grass.
	scene.props.clear()
	# Ordinary hits keep directional feedback; v21 kills retain an intact falling body.
	for weapon in 3:
		scene.p_attack.cancel();scene._reset_player(Vector2(700,1050));scene._clear_keys();scene.weapon_index=weapon;scene.hitstop=0
		scene.combat_feedback.clear()
		var en:Dictionary=fixture(Vector2(730,1050));scene.enemies.assign([en])
		scene._begin_primary({"dir":"right","charged":false});scene.p_attack.tick(float(scene.p_attack.attack["windup"])+.001);scene._process_player_attack()
		check(scene.combat_feedback.flashes.size()==1 and scene.combat_feedback.flashes[0]["style"]==Data.PRIMARY[weapon]["style"],"Each weapon uses its own hit-light pattern")
		check(is_equal_approx(scene.combat_feedback.flashes[0]["length"],1280.0/3*1.2),"Hit flash spans v0.7 length plus twenty percent independently of zoom")
		check(scene.combat_feedback.bursts.size()==2 and scene.combat_feedback.bursts[0] is CPUParticles2D and scene.combat_feedback.bursts[0].direction.x>0,"Normal hit throws a native particle soul trail backward from the enemy")
		if weapon==2:check(is_equal_approx(scene.hitstop,5.0/60) and scene.p["impact_root"]==0,"Heavy impact freezes five frames without an extra post-hit movement root")
		var old_corpses:int=scene.corpses.size();en["hp"]=1;scene._hit_enemy(en,5,Color.WHITE,120,Vector2.INF,Vector2.RIGHT)
		check(scene.corpses.size()==old_corpses+1 and scene.combat_feedback.corpses.is_empty() and not str(scene.corpses[-1]["identity"]).is_empty(),"Killing blow retains its own falling body without fading soul fragments")
	# Parallax, depth blur, wind, black/white feathers and underground spores.
	var sky:Transform2D=Atmosphere.parallax(Vector2(100,80),1.3,Atmosphere.FAR_FACTOR)
	var middle:Transform2D=Atmosphere.parallax(Vector2(100,80),1.3,Atmosphere.MID_FACTOR)
	var front:Transform2D=Atmosphere.parallax(Vector2(100,80),1.3,1)
	check(absf(sky.origin.x)<absf(middle.origin.x) and absf(middle.origin.x)<absf(front.origin.x),"Foreground pans faster than middle and far layers")
	scene.atmosphere.configure("underground",23)
	check(scene.atmosphere.spores.visible and scene.atmosphere.spores.emitting,"Lower ecologies emit native bioluminescent mushroom particles")
	check(scene.atmosphere.mid_particles.size()==2 and scene.atmosphere.foreground.size()==4,"Native feathers exist in middle, foreground and out-of-focus near-foreground layers")
	check(scene.atmosphere.mid_particles[0].modulate.r>.8 and scene.atmosphere.mid_particles[1].modulate.r<.1,"Translucent white and black feathers coexist")
	check(scene.atmosphere.foreground[-1].material.get_shader_parameter("blur_radius")>scene.atmosphere.middle.material.get_shader_parameter("blur_radius"),"Closest feathers have stronger focus blur than the middle layer")
	scene.atmosphere.configure("sky",24);check(not scene.atmosphere.spores.emitting,"Upper ecology does not emit underground mushroom spores")
	scene._process(.016)
	var focus:Vector2=scene.atmosphere.focus.material.get_shader_parameter("focus")
	check(focus.distance_to((scene.world_transform*(scene.p["pos"]-Vector2(0,22)))/Vector2(1280,720))<.001,"Light stays centered on the player through the camera transform")
	scene.meta=saved;scene._save_meta();scene.combat_feedback.clear();scene.queue_free();await process_frame
	print("v0.7: ","passed: fifteen batches / 277 clips / 1193 frames, %d hitbox mappings, release armor/action locks, impact souls and kill bursts, native feather/spore particles, three depth layers and player light"%mappings if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
