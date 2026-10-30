extends SceneTree
const FX=preload("res://scripts/combat_visual.gd")
const Walk=preload("res://scripts/walk_animation.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Atmosphere=preload("res://scripts/atmosphere.gd")
const Adventure=preload("res://scripts/adventure_visual.gd")
const Wildlife=preload("res://scripts/ambient_wildlife.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	# Pose bounding boxes must no longer decide player scale.
	check(FX.ensure(),"Runtime actor manifest loads")
	for id in FX.manifest["animations"]:
		var clip:Dictionary=FX.definition(id)
		if not id.begins_with("pigeon_") or not clip.has("reference_calibration"):continue
		var reference:float=float(clip["reference_calibration"]["target_area"])
		check(is_equal_approx(reference*pow(FX.actor_factor(id),2),4),"Head size matches walking reference in every player clip: "+id)
	var clip:Dictionary=FX.definition("pigeon_feather_charge")
	var previous:Array=clip["frames"][0]["visible_bounds"].duplicate();var scale_before:float=FX.actor_factor("pigeon_feather_charge")
	clip["frames"][0]["visible_bounds"]=[0,0,510,500]
	check(FX.actor_factor("pigeon_feather_charge")==scale_before,"Extended wings and crouching do not resize the player")
	clip["frames"][0]["visible_bounds"]=previous
	check(FX.player_clip("quick",{"kind":"slam"},"charge")=="pigeon_feather_charge","Charging after a slam uses the calibrated charge artwork")
	check(absf(330*Walk.TURN_FACTOR-57)<.001,"Standing turn body matches the walking height without pose-dependent scaling")
	var walker=Walk.new();root.add_child(walker);walker.reset_turn(1);walker.step_turn(-1,.001,true)
	check(Walk.turn_elapsed<Walk.TURN_DURATION and Walk.turn_index()==0,"Facing change begins at the old profile, without mirror snapping")
	var seen:Dictionary={}
	for i in 24:seen[Walk.turn_index()]=true;walker.step_turn(-1,.01,true)
	check(seen.size()==8 and Walk.turn_to==-1,"Turn traverses all eight frames and reaches the new profile")
	walker.reset_turn(1);walker.step_turn(-1,.08,true);var index:int=Walk.turn_index();walker.step_turn(1,0,true)
	check(absi(Walk.turn_index()-index)<=1,"Reversing direction mid-turn reverses the animation smoothly")
	walker.step_turn(1,.01,false);check(Walk.turn_elapsed==Walk.TURN_DURATION,"Attack/air interruption clears a queued turn")
	for row in Walk.TURN_REGIONS:check(row.size()==6 and row[2]>0 and row[3]>0,"Turn sprite has an explicit source rectangle and foot pivot")
	check(load("res://assets/atmosphere_v09/turn.png") is Texture2D,"Turn art is exported")
	var l_shapes:int=0;var squares:int=0
	for seed_value in 30:
		var layout:Dictionary=Layout.generate({"id":seed_value,"coord":Vector2i.ZERO,"type":"combat","neighbors":{"up":1,"down":2,"left":3,"right":4}},seed_value)
		check(Layout.validate(layout).is_empty(),"New solid shapes retain ordinary-jump routes")
		for shape in layout["shapes"]:
			if shape["kind"]=="L":l_shapes+=1
			elif shape["kind"]=="square":squares+=1
	check(l_shapes>=30 and squares>=60,"Playable rooms include L silhouettes and more square terrain")
	var middle:Array[Dictionary]=Atmosphere.make_middle_structures(42)
	check(middle.size()==12 and middle==Atmosphere.make_middle_structures(42),"Middle ground has deterministic platforms, L parts and blocks")
	for part in middle:check(not part["collision"],"Middle-ground scenery does not add invisible collision")
	for kind in ["bird","dragonfly"]:
		var wildlife=Wildlife.new();wildlife.kind=kind;root.add_child(wildlife);wildlife.configure(22,true);wildlife.update_view(Vector2.ZERO,1.3,0)
		wildlife.spawn_flight();var first:Vector2=wildlife.point(wildlife.flights[0]);wildlife.flights[0]["age"]=float(wildlife.flights[0]["duration"])*.5
		var middle_at:Vector2=wildlife.point(wildlife.flights[0])
		check(first.distance_to(middle_at)>100,"Ambient animals actually travel across depth layers")
		if kind=="dragonfly":check(middle_at.y<first.y-100,"Foreground dragonfly lifts off from below")
		check(load("res://assets/atmosphere_v09/"+kind+".png") is Texture2D,"Ambient flight atlas loads")
		wildlife.configure(22,false);check(not wildlife.visible and wildlife.flights.is_empty(),"Hub/room transition clears ambient flights")
		wildlife.queue_free()
	var at:=Vector2(740,1050)
	var a:Dictionary=Adventure.portal_mote(at,.3,0);var b:Dictionary=Adventure.portal_mote(at,.8,0)
	check(b["radius"]<a["radius"] and a["radius"]>20,"Portal motes converge densely near the doorway")
	for fixture in [{"type":"boss"},{"type":"start"},{"type":"merchant"},{"type":"reward"},{"type":"combat","spring":true}]:
		var color:Color=Adventure.door_color(fixture)
		if fixture["type"]=="boss":check(color.r>color.g*2,"Boss portal glows red")
		elif fixture["type"]=="reward":check(color.r>.9 and color.g>.7 and color.b<.5,"Reward portal glows gold")
		else:check(color.g>color.r*2,"Safe portal glows green")
	check(Adventure.FEATHER_SIZE==Vector2(120,80) and Adventure.FEATHER_BOB==6,"Death cache keeps large footprint and now gently bobs by6 pixels")
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame;scene.set_process(false);scene.set_physics_process(false)
	var saved:Dictionary=scene.meta.duplicate(true)
	scene.new_run("rogue",9124);scene.feather={"room":scene.current_room,"pos":Vector2(620,1050)};scene._process(.01)
	var motes:CPUParticles2D=scene.combat_feedback.cache_motes
	check(motes.visible and motes.emitting and motes.amount>=24 and motes.direction.y>0,"Cache continuously emits downward native white feather particles")
	scene.feather={};scene._process(.01);check(not motes.visible and not motes.emitting,"Recovered cache stops its particle emitter")
	scene.meta=saved;scene._save_meta();scene.combat_feedback.clear();scene.queue_free();walker.queue_free();await process_frame
	print("v0.9: ","passed: anatomical player scale, eight-frame turns, L/square solids, depth scenery, wildlife, inward white motes and large glowing death cache" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
