extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const Feedback=preload("res://scripts/combat_feedback.gd")
const Monster=preload("res://scripts/monster_art_v36.gd")
const Roster=preload("res://scripts/monster_roster_v36.gd")
const Corpses=preload("res://scripts/corpse_field_v21.gd")
const Death=preload("res://scripts/death_art_v39.gd")
const HitArt=preload("res://scripts/hit_art_v37.gd")
const FX=preload("res://scripts/combat_visual.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func run() -> void:
	for direction:String in ["left","right","up","down"]:
		for combo in 3:
			var dash:Dictionary=Data.action_attack(direction,false,true,combo);var original:Dictionary=Data.primary_attack(2,direction,false,false,combo%2)
			for field:String in ["range","width","shape","fx_clip","style"]:check(dash[field]==original[field],"Dash attack retains the selected one of the two heavy profiles for "+field)
			check(Data.action_attack(direction,false,false,combo)["style"]=="quick","Ordinary attacks always use the knife")
		var charged:Dictionary=Data.action_attack(direction,true,false);var spin:Dictionary=Data.primary_attack(2,direction,false,false,2)
		for field:String in ["range","width","shape","fx_clip"]:check(charged[field]==spin[field],"Charge matches the third heavy ordinary attack "+field)
		check(charged["active"]==1 and charged["charged"] and charged["great_spin_release"],"Charge retains one-second super-armored release")
		check(FX.player_clip("heavy",charged,"active")=="pigeon_great_spin","Charge body uses third heavy ordinary animation in every direction")
	var feedback:=Feedback.new();root.add_child(feedback)
	for biome:String in ["underground","trunk","sky"]:
		check(Death.info(biome)["frames"].size()==7,"Each ecology has five regular and two elite death poses")
		for index in 7:
			var en:Dictionary=Roster.regular(biome,index) if index<5 else Roster.elite(["underground","trunk","sky"].find(biome)*2+index-5)
			en["pos"]=Vector2(600,500);en["face"]=-1.0;en["vel"]=Vector2.ZERO
			var center:Vector2=Monster.actor_bounds(en).get_center()
			feedback.hit(en,Vector2.ZERO,Vector2.RIGHT);var hit:Dictionary=feedback.flashes.back()
			check(Vector2(hit["at"]).is_equal_approx(center),"Straight slash uses actual sprite center rather than feet or old hit contact")
			check(hit["dir"]==Vector2.RIGHT and Vector2(hit["spray_at"]).is_equal_approx(center),"Attack from left sprays right from the sprite center")
			feedback.hit(en,Vector2.ZERO,Vector2.LEFT);hit=feedback.flashes.back()
			check(hit["dir"]==Vector2.LEFT and Vector2(hit["spray_at"]).is_equal_approx(center),"Attack from right sprays left from the sprite center")
			en["death_direction"]=Vector2.RIGHT;en["death_knockback"]=80
			var body:Dictionary=Corpses.create(en);check(body["face"]==-1 and body["vel"].x==120,"Death preserves facing and the 1.5x knockback")
			check(Monster.corpse_angle([0,0,100,30])==0 and Monster.corpse_angle([0,0,20,100])==0,"Neither wide nor tall corpses are artificially rotated")
			var extent:Vector2=body["visual_size"];body["age"]=3;check(extent==Death.extent(en),"Death pose size does not depend on age or landing phase")
	check(HitArt.STRAIGHT.get_size()==HitArt.STRAIGHT_CELL*2,"The replacement impact animation ships as four textured frames")
	var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.practice_mode=true;g.new_run("rogue",390039);g._close_panel();g.p_attack.cancel();g.p["grounded"]=true
	for i in [0,2,1]:g._select_primary(i);check(g.weapon_index==1,"Removed standalone weapons cannot be selected")
	g._dash_pressed();g._begin_primary({"dir":"right","charged":false});check(g.p_attack.attack.get("dash_attack",false) and g.p_attack.attack["style"]=="heavy","Real single-C input followed by attack starts heavy ordinary slash")
	g.p_attack.cancel();g.p["dash_t"]=0;g._begin_primary({"dir":"right","charged":true});check(g.p_attack.attack.get("great_spin_release",false),"Real charged release selects heavy third slash")
	g.p_attack.cancel();var target:Dictionary=Roster.regular("underground",0);target.merge({"pos":Vector2(700,700),"hp":100.0,"vel":Vector2.ZERO,"face":1.0,"stun":0.0,"uid":999},true);g._hit_enemy(target,1,Color.WHITE)
	check(is_equal_approx(target["flash_left"],.03),"Hit flash uses the current thirty-millisecond duration")
	g.queue_free();feedback.queue_free();await process_frame;print("v39 combat checks: ",failures);quit(0 if failures.is_empty() else 1)
