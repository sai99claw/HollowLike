extends SceneTree
const Burst=preload("res://scripts/pigeon_burst_v72.gd")
const Hit=preload("res://scripts/hit_art_v37.gd")
const Mantle=preload("res://scripts/mantle_art_v37.gd")
const Feedback=preload("res://scripts/combat_feedback.gd")
const Monster=preload("res://scripts/monster_art_v36.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func run() -> void:
	check(Burst.IMPACT.get_size()==Burst.CELL*2,"Four feather frames ship in the packed atlas")
	check(Mantle.info()["frames"].size()==4 and ResourceLoader.exists(Mantle.ROOT+Mantle.info()["path"]),"Four-pose mantle artwork is exported")
	for i in 4:
		check(Burst.frame_at((i+.5)*.05,Burst.IMPACT_DURATION)==i,"Feathers visit all four authored spray poses")
	check(Burst.frame_at(.20,Burst.IMPACT_DURATION)==-1,"The feather spray expires after 200 ms")
	var crescent=preload("res://scripts/clean_crescent_v39.gd")
	var scale:Vector2=crescent.pose(Vector2.ZERO,0,1475).get_scale().abs()
	check(scale.is_equal_approx(Vector2(.85,1.20)) and Hit.CRESCENT_DURATION_USEC==125000,"Crescent is narrower, longer and lasts 1/8 second")
	var feedback:=Feedback.new();root.add_child(feedback)
	for i in 10:feedback.hit({},Vector2(500,300),Vector2.RIGHT,"quick",false)
	var angles:Dictionary={}
	for f:Dictionary in feedback.flashes:
		angles[snappedf(f["angle"],.001)]=true
		check(Vector2(f["dir"]).is_equal_approx(Vector2.RIGHT),"Feathers spray through the target in the strike direction")
		check(is_equal_approx(f["length"],1280.0/3),"Crescent long axis is one-third screen width")
		check(absf(angle_difference(f["angle"],0))<=.241,"Crescent angle jitter stays restrained")
	check(angles.size()>1 and feedback.bursts.is_empty(),"Hits vary angle without emitting old enemy-body ghost copies")
	feedback.step(.26);check(feedback.flashes.is_empty(),"Transient VFX expire rather than accumulating")
	for biome:String in ["underground","trunk","sky"]:
		for row in 5:
			var actor:Dictionary={"roster_id":"test","roster_row":row,"roster_elite":false,"roster_biome":biome,"vel":Vector2(50,0),"pos":Vector2(500,500),"face":1.0,"attack":Attack.new()};var seen:Dictionary={}
			var body:Dictionary=preload("res://scripts/corpse_field_v21.gd").create(actor)
			check(Vector2(body["visual_size"]).is_equal_approx(Monster.corpse_extent(actor)),"Corpse contact size derives from the unscaled authored silhouette")
			for i in 6:seen[Monster.actor_sample(actor,(float(i)+.1)/12)["column"]]=true
			check(seen.size()==6,"Every regular has six distinct movement poses")
			actor["attack"].begin({"windup":.6,"active":.2,"recovery":.6});actor["attack"].tick(.15);var early:int=Monster.actor_sample(actor,0)["column"];actor["attack"].tick(.4)
			check(early==7 and Monster.actor_sample(actor,0)["column"]==early,"Strong final windup silhouette is held for readability")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false)
	game.effects.clear();game.combat_feedback.clear();game._hit_enemy({"hp":100.0,"training":true,"pos":Vector2(500,500)},1,Color.WHITE)
	check(game.effects.is_empty() and game.combat_feedback.flashes.size()==1 and game.combat_feedback.flashes[0]["feathers"],"Training targets use the same new impact with no old body-centered animation")
	game.effects.clear();game.combat_feedback.clear();game.props.assign([{"kind":"dummy","pos":Vector2(500,500),"used":false,"hurt":0.0}]);game._hit_props(Rect2(450,420,100,100),1,99)
	check(game.effects.is_empty() and game.combat_feedback.flashes.size()==1 and game.combat_feedback.flashes[0]["feathers"],"Station dummies also show the feather impact")
	game._enter_practice(true)
	game._begin_primary({"dir":"right","charged":false})
	game.p_attack.tick(float(game.p_attack.attack["windup"])+.001)
	check(game.p_attack.is_active(),"Primary attack reaches the active strike")
	var target:Dictionary=game.enemies[0]
	var hitbox:Rect2=game._player_strike_box(game.p_attack.attack)
	game.p["pos"]+=Vector2(200,0)
	var moved_box:Rect2=game._player_strike_box(game.p_attack.attack)
	var visual_definition:Dictionary=game.player_slashes.back()["definition"]
	check(moved_box.position==hitbox.position+Vector2(200,0) and game._player_strike_box(visual_definition)==moved_box,"Both the hitbox and slash follow the player through an active strike")
	target["pos"]+=hitbox.get_center()-game._enemy_body_box(target).get_center()
	game.combat_feedback.clear()
	game._process_player_attack()
	check(game.combat_feedback.flashes.is_empty(),"The old swing position no longer hits")
	target["pos"]+=moved_box.get_center()-game._enemy_body_box(target).get_center()
	game.combat_feedback.clear()
	game._process_player_attack()
	check(game.combat_feedback.flashes.size()==1 and game.combat_feedback.flashes[0]["straight"] and not game.combat_feedback.flashes[0]["crescent"],"An ordinary strike ejects feathers without layering the old crescent")
	var flash:Dictionary=game.combat_feedback.flashes[0]
	check(flash["at"].is_equal_approx(Feedback.impact_center(target,Vector2.ZERO)),"Straight strike is centered on the target sprite")
	var variations:Dictionary={}
	for i in 12:
		feedback.hit({},Vector2(90,40),Vector2.RIGHT,"quick",false,false,true)
		var angle:float=feedback.flashes.back()["straight_angle"]
		variations[snappedf(angle,.005)]=true
		check(absf(angle)<=.561,"Impact rotates around the hit direction within its intended arc")
	check(variations.size()>1,"Repeated hits vary the angle")
	var frozen_pose:float=game._enemy_pose_clock(target)
	game.draw_clock+=.1
	game._update_enemies_profiled_body(.05)
	check(is_equal_approx(target["impact_freeze_left"],.02) and game._enemy_pose_clock(target)==frozen_pose and game.hitstop==0,"Only the struck enemy pose freezes")
	game._update_enemies_profiled_body(.021)
	check(is_zero_approx(target["impact_freeze_left"]),"Enemy resumes after roughly 70 ms of local hitstop")
	game.queue_free();feedback.queue_free();await process_frame;print("v37 hit and animation checks: ",failures);quit(0 if failures.is_empty() else 1)
