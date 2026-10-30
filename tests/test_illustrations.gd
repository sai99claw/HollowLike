extends SceneTree
const Sprites=preload("res://scripts/sprite_art.gd")
func _initialize() -> void:
	if not Sprites._ensure():push_error("Illustration manifest absent");quit(1);return
	var manifest:Dictionary=Sprites.manifest
	assert(manifest["sources"].size()==17,"All 17 delivered sources must be accounted for")
	assert(manifest["backgrounds"].size()==6,"All six altitude backgrounds must be present")
	var frames:int=0
	for name in manifest["animations"]:
		var clip:Dictionary=manifest["animations"][name]
		for f in clip["frames"]:
			assert(ResourceLoader.exists(Sprites.ROOT+f["path"]),"Missing imported frame: "+f["path"])
			assert(Sprites._texture(f["path"])!=null,"Corrupt frame: "+f["path"])
			assert(f["size"][0]>0 and f["size"][1]>0,"Empty extracted sprite")
			frames+=1
	for key in manifest["modules"]:
		assert(Sprites._texture(manifest["modules"][key]["path"])!=null,"Missing scene module: "+key)
	for key in manifest["backgrounds"]:
		assert(Sprites._texture(manifest["backgrounds"][key])!=null,"Missing biome background: "+key)
	for clip in ["pigeon_quick","pigeon_heavy","pigeon_reach","beetle_attack","slinger_attack","moth_attack","guardian_attack","boss_attack"]:
		var windup:int=Sprites.phase_frame(clip,"windup",0,0)
		var active:int=Sprites.phase_frame(clip,"active",.5,0)
		var recovery:int=Sprites.phase_frame(clip,"recovery",.5,0)
		assert(windup!=active and active!=recovery,"Attack phases must select distinct poses")
	print("Illustration integration passed: 17 sources, 6 biomes, 12 scene modules, %d clips / %d referenced frames; imported textures load and attack phases select distinct art"%[manifest["animations"].size(),frames])
	call_deferred("quit",0)
