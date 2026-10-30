extends SceneTree
const Env=preload("res://scripts/environment_art.gd")
const FX=preload("res://scripts/combat_visual.gd")
var failures:Array[String]=[]
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
	for biome in Env.BIOMES:
		for type in ["trunk","block"]:
			for clip in Env.terrain_clips(biome,type):check(FX.has_clip(clip),"Every ecology has its own solid terrain parts: "+clip)
		for kind in ["energy","health"]:
			for used in [false,true]:
				var clip:String=Env.prop_clip({"kind":kind,"used":used},biome)
				check(FX.has_clip(clip),"Ecological destructible has both idle and break animation: "+clip)
		for role in ["base","water","steam"]:check(FX.has_clip(biome+"_spring_"+role),"Ecological pool has all independently animated layers")
	for fixture in [{"kind":"dummy","hurt":.3},{"kind":"energy_infinite","hurt":.3},{"kind":"aid","event":"heal","event_left":.8},{"kind":"mail","event":"send","event_left":.8},{"kind":"rack","empty":true}]:
		check(FX.has_clip(Env.prop_clip(fixture,"branches")),"Delivered prep-room event image is routed")
	for weapon in 3:check(FX.has_clip(Env.prop_clip({"kind":"rack"},"branches",weapon)),"Rack reflects each equipped main weapon")
	var at:=Vector2(700,1050)
	for id in ["dummy_idle","energy_flower_idle","first_aid_idle","delivery_idle","rack_feather","branches_energy_idle","sky_fullheal_idle"]:
		var rect:Rect2=Env.ground_rect(id,at,Vector2(90,90))
		check(not rect.size.is_zero_approx() and absf(rect.end.y-at.y)<.001 and absf(rect.get_center().x-at.x)<.001,"Visible prop is grounded at its interaction position: "+id)
		check(rect.size.x<=90.001 and rect.size.y<=90.001,"Prop remains inside its requested visual size")
		var b:Array=FX.definition(id)["visual_bounds"]
		check(absf(rect.size.x/rect.size.y-float(b[2])/float(b[3]))<.001,"Prop image aspect ratio survives transparent padding removal")
	print("Environment art: ","passed: six ecological solid sets, pools, destructible and prep-room event clips, grounded art bounds" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
