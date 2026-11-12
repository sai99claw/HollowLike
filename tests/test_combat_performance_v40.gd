extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Feedback=preload("res://scripts/combat_feedback.gd")
const Budget=preload("res://scripts/render_budget_v40.gd")
const Depth=preload("res://scripts/depth_style_v32.gd")
const Roster=preload("res://scripts/monster_roster_v36.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func run() -> void:
	for direction:String in ["left","right","up","down"]:
		for combo in 3:
			for charge:bool in [false,true]:
				var def:Dictionary=Data.action_attack(direction,charge,true,combo)
				var state=preload("res://scripts/attack_state.gd").new();state.begin(def)
				state.tick(float(def["windup"])+float(def["active"])+.00001)
				check(not state.is_busy(),"Dash/charge can act immediately after their full hit window")
	check(Data.action_attack("right",false,false)["recovery"]>0,"Ordinary featherblade cadence is retained")
	var feedback=Feedback.new();root.add_child(feedback)
	for i in 10:feedback.update_charge(false,Vector2.ZERO,0,2);feedback.update_cache(false,Vector2.ZERO,0)
	check(feedback.get_child_count()==0,"Inactive charge/cache allocate no particle emitters")
	var jump:Dictionary=feedback.double_jump(Vector2(10,20))
	for dir:Vector2 in [Vector2.LEFT,Vector2.RIGHT]:
		var dash:Dictionary=feedback.single_dash(Vector2(30,40),dir)
		check(dash["direction"]==-dir and dash["origin"]==Vector2(30,40),"Single C emits a backward sprite sequence from a fixed world anchor")
	check(jump["direction"]==Vector2.DOWN and jump["origin"]==Vector2(10,20),"Double-jump impulse points downward")
	feedback.step(.25)
	check(feedback.impulses.is_empty(),"Animated impulse sprites expire")
	feedback.update_charge(true,Vector2.ZERO,.4,2);feedback.update_charge(false,Vector2.ZERO,0,2)
	check(not feedback.charge_motes.visible and not feedback.charge_motes.emitting,"Charge shutdown clears particles")
	check(Depth.material("trunk","far",true)==Depth.material("trunk","far",true),"Retained layers share cached grading materials")
	check(Depth.material("trunk","far",true)!=Depth.material("trunk","middle",true),"Distinct depth styles remain independent")
	var window:=Window.new();window.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	Budget.configure(window,false);check(window.content_scale_mode==Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,"Native HD rendering is preserved")
	Budget.configure(window,true);check(window.content_scale_mode==Window.CONTENT_SCALE_MODE_VIEWPORT and window.content_scale_size==Vector2i(1280,720),"Web rendering budget remains 720p even on high-DPI screens")
	window.free()
	var view:=Rect2(220,330,1169,754);var region:Rect2=Budget.region(view)
	check(region.encloses(view.grow(128)),"Retained terrain includes the entire visible area and a camera safety halo")
	check(Budget.region(Rect2(view.position+Vector2(1,1),view.size))==region,"Small camera movement reuses the same terrain commands")
	check(Budget.region(Rect2(view.position+Vector2(768,0),view.size))!=region,"Crossing a camera cell refreshes terrain coverage")
	var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.practice_mode=true;g.new_run("rogue",400040);g._close_panel();g._clear_keys();g.p_attack.cancel();g.p["grounded"]=true
	var count:int=g.combat_feedback.impulses.size();g._dash_pressed()
	check(g.combat_feedback.impulses.size()==count+1,"Actual single-C input creates one feather burst")
	g.clock+=.1;g._dash_pressed();check(g.p_attack.attack["kind"]=="pierce" and g.p_attack.attack["recovery"]==0,"Second C pierce has no recovery")
	check(g.combat_feedback.impulses.size()==count+1,"Double C does not duplicate the single-C burst")
	g.p_attack.cancel();g.p["dash_t"]=0;g.dash_chain_open=false;g.clock+=1;g._clear_keys();g.keys["down"]=true
	g._dash_pressed();check(g.combat_feedback.impulses.size()==count+1,"Down+C only arms the dive without a false dash burst")
	g.clock+=.1;g._dash_pressed();check(g.p_attack.attack["kind"]=="slam" and g.p_attack.attack["recovery"]==0,"Downward double C has no recovery")
	g.enemies.clear();var en:Dictionary=Roster.regular("trunk",0)
	en.merge({"uid":400,"pos":Vector2(500,500),"vel":Vector2.ZERO,"face":1.0,"hp":5.0,"max_hp":5.0,"hurt":0.0,"flash_left":0.0,"attack":g.Attack.new()},true)
	g.enemies.append(en);g.view_rect=Rect2(0,0,1280,720);g._sync_enemy_canvases()
	for i in 3:await process_frame
	var sprite=g.enemy_canvases[400];var builds:int=sprite.rebuilds
	for i in 12:
		g.draw_clock+=1.0/30;en["pos"].x+=1;g._sync_enemy_canvases();await process_frame
	check(sprite.rebuilds==builds,"Stationary roster pose follows movement without rebuilding the same artwork")
	en["face"]=-1;g._sync_enemy_canvases()
	for i in 3:await process_frame
	check(sprite.rebuilds==builds+1,"Facing changes still rebuild the sprite immediately")
	var resting:Dictionary={"kind":"coin","pos":Vector2(250,293),"vel":Vector2.ZERO,"sleeping":true,"grounded":true,"age":1.0,"taken":false,"value":1}
	var moving:Dictionary={"kind":"coin","pos":Vector2(255,293),"vel":Vector2.LEFT*30}
	g.CoinField.collide([resting,moving])
	check(resting["sleeping"] and resting["pos"]==Vector2(250,293),"A settled coin stays asleep even when another coin overlaps it")
	g.drops.assign([resting]);g.p["pos"]=Vector2(250,313)
	var old_gold:int=g.run_coins
	g._update_drops(1.0/60.0)
	check(g.drops.is_empty() and g.run_coins==old_gold+1,"Sleeping coins still collect when approached")
	var bounds:=Rect2(0,0,1000,800)
	var shot:Dictionary={"pos":Vector2(1001,400),"vel":Vector2.RIGHT*500}
	check(g._straight_shot_left_room(shot,bounds),"A straight shot leaving the outer room bounds can be culled")
	shot["vel"]=Vector2.LEFT*500
	check(not g._straight_shot_left_room(shot,bounds),"An incoming shot outside the room still runs")
	shot["vel"]=Vector2.RIGHT*500;shot["return_after"]=.5
	check(not g._straight_shot_left_room(shot,bounds),"Returning shots continue updating outside the room")
	g.queue_free();feedback.queue_free();await process_frame
	print("v40 combat/performance checks: ",failures);quit(0 if failures.is_empty() else 1)
