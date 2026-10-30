extends SceneTree
const Motion=preload("res://scripts/monster_motion_v18.gd")
const Arms=preload("res://scripts/armament.gd")
const Combat=preload("res://scripts/combat_library.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func run() -> void:
	check(Motion.ensure(),"Movement atlas metadata exists")
	var rng:=RandomNumberGenerator.new();rng.seed=18008
	var actors:Array[Dictionary]=[]
	for species in Arms.MODES:
		actors.append(Arms.enemy(species,rng,false));actors.append(Arms.enemy(species,rng,true))
	actors.append(Arms.cute_wanderer(rng))
	for biome in Combat.BOSS_BIOMES:actors.append(Combat.boss(biome))
	for en:Dictionary in actors:
		var id:String=Motion.identity(en);var clip:Dictionary=Motion.definition(id)
		check(clip.get("frame_count",0)==8 and clip.get("frames",[]).size()==8,"Exactly eight authored movement poses: "+id)
		var hashes:Dictionary={}
		for i in 8:
			var f:Dictionary=clip["frames"][i];hashes[f["sha256"]]=true
			var tex:Texture2D=Motion.texture_for(id,i)
			check(tex is AtlasTexture and tex.get_size().x>0,"Imported movement atlas cell: "+id+"/"+str(i))
			if tex is AtlasTexture:
				check(str(tex.atlas.resource_path).ends_with("monster-motion-"+id+".png"),"Every normal / elite / Boss frame keeps its own identity")
		check(hashes.size()==8,"Movement uses eight distinct PNG regions, never duplicated old poses: "+id)
		en["vel"]=Vector2(45,0)
		var visited:Dictionary={}
		for i in 8:visited[Motion.sample_index(en,float(i)/float(clip["fps"])+.001)]=true
		check(visited.size()==8,"Moving actor actually visits all eight authored poses: "+id)
		en["vel"]=Vector2.ZERO
		if not clip.get("flying",false):check(Motion.sample_index(en,.63)==0,"Grounded idle holds its resting pose: "+id)
		if id=="jump":
			en["vel"]=Vector2(40,-150);check(Motion.sample_index(en,.3)==3,"Airborne ascent holds a readable extension")
			en["vel"]=Vector2(40,150);check(Motion.sample_index(en,.3)==4,"Airborne descent holds a readable landing pose")
	check(Motion.definition("unknown").is_empty(),"Unknown actors never borrow a different monster's atlas")
	print("Monster motion v0.18: ","passed (12 identities, 96 unique authored poses, 17 normal/elite/cute/Boss runtime cases)" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
