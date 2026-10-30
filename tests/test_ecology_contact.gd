extends SceneTree
const Layout=preload("res://scripts/room_layout.gd")
const Ecology=preload("res://scripts/ecology.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func run() -> void:
	check(Ecology.describe(3)["id"]=="sky","Sky ecology uses global altitude")
	check(Ecology.describe(2)["id"]=="trunk","Altitude maps to one of three ecologies")
	check(Ecology.describe(-3)["id"]=="underground","Deep rooms are underground")
	var room={"id":1,"coord":Vector2i(0,0),"type":"combat","neighbors":{"up":0,"down":1,"left":2,"right":3}}
	var layout:Dictionary=Layout.generate(room,194)
	var covered:Dictionary={}
	for seed_value in 120:
		var plan:Array[Dictionary]=Ecology.spawn_plan(layout,Ecology.describe(seed_value%9-4),"rogue",seed_value,0)
		var roles:Dictionary={}
		for entry in plan:
			covered[entry["platform"]]=true;roles[entry["model"]]=true
		check(roles.has(0) and roles.has(1) and roles.has(2),"Every first-chapter combat room has melee, ranged and airborne roles")
	for i in layout["platforms"].size():
		var has_slot:bool=false
		for at in layout["enemy_spawns"]:
			if absf(at.y-layout["platforms"][i].position.y)<.1:has_slot=true
		if has_slot:check(covered.has(i),"Every eligible platform can spawn enemies")
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene)
	await process_frame
	scene.audio_enabled=false;scene.set_physics_process(false);scene.practice_mode=true;scene.new_run("rogue",194)
	var tiers:Dictionary={}
	for surface in scene.platforms:tiers[surface.position.y]=true
	check(tiers.has(scene._room_floor()-200) and tiers.has(scene._room_floor()) and scene.layout["ceiling_y"]==0,"Start room has a full-height ceiling and a second-floor station deck")
	scene.p["pos"]=Vector2(740,1050);scene.room_cooldown=0
	scene._set_action("up",true)
	check(not scene.ui.is_panel_open(),"Upward combat input does not accidentally open prep")
	scene._set_action("up",false);scene.p["pos"]=scene._furniture_offset()+Vector2(680,850);scene._set_action("interact",true)
	check(scene.ui.is_panel_open(),"Explicit E still opens prep")
	scene._close_panel()
	for r in scene.tower["rooms"]:
		if r["type"]=="combat" and not r.get("spring",false):scene._enter_room(r["id"]);break
	var en:Dictionary=scene.enemies.filter(func(value:Dictionary)->bool:return value.get("contact_damage",0)>0)[0]
	scene.layout["size"]=Vector2(1500,1120);scene.layout["floor_y"]=1050;scene.solids.clear();scene.platforms.assign([Rect2(0,1050,1500,70)])
	scene.enemies.assign([en]);en["pos"]=Vector2(510,1050);en["vel"]=Vector2.ZERO;en["attack"].cancel()
	scene.p["pos"]=Vector2(500,1050);scene.p["vel"]=Vector2.ZERO;scene.p["invul"]=0;scene.p["shield"]=0
	scene.camera_pos=Vector2(0,566);scene.view_rect=Rect2(0,566,1500,720)
	scene.p["hp"]=5;scene.freeze_timer=2
	scene._update_enemies(0)
	check(scene.p["hp"]==4,"Enemy body contact damages even if its attack is idle / frozen")
	check(scene.p["hurt"]>0 and scene.shake>0 and not scene.effects.is_empty(),"Contact has visible hit feedback")
	scene._update_enemies(0)
	check(scene.p["hp"]==4,"Invulnerability prevents repeated overlap damage")
	var x:float=scene.p["pos"].x
	scene._clear_keys();scene.p["dash_t"]=0;scene.p["slam"]=false
	for i in 8:scene._update_player(.015)
	check(absf(absf(scene.p["pos"].x-x)-27.2)<.1,"Knockback travels 0.8 body widths without being eaten by movement friction")
	scene.p["invul"]=1;scene._hurt_player(1,en["pos"])
	check(scene.p["hp"]==4,"Pierce / entry invulnerability protects from contact")
	# A ground enemy pursues across a ledge for several seconds without falling off.
	scene.freeze_timer=0;scene.platforms.assign([Rect2(0,1050,1500,70),Rect2(300,700,200,21)])
	en["movements"]=["walk"];en["motion_index"]=0;en["move"]="walk";en["pos"]=Vector2(470,700);en["vel"]=Vector2.ZERO;en["cooldown"]=100;en["attack"].cancel()
	scene.p["pos"]=Vector2(800,700);scene.p["invul"]=100
	for i in 180:scene._update_enemies(1.0/60)
	check(absf(en["pos"].y-700)<1 and en["pos"].x<500,"Ground enemies retain their upper platform during pursuit")
	scene._show_bag();await process_frame
	check(scene.ui.is_panel_open(),"Redesigned inventory opens")
	scene.bag_runes["gale"]=2;scene.rune_slots.assign(["gale"]);scene._show_runes(false)
	await process_frame
	var board:GridContainer=scene.ui.panel_rows.find_child("RuneBoard",true,false)
	check(board!=null and board.get_child_count()==16 and board.columns==4,"Rune UI renders all 16 cells in 4x4 grid")
	check(scene.ui.header.size.x<650,"HUD is compact instead of a full-width white strip")
	scene.queue_free();await process_frame
	print("Ecology/contact/UI regression: ","passed" if failures.is_empty() else failures)
	call_deferred("quit",0 if failures.is_empty() else 1)
