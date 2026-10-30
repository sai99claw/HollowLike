extends SceneTree
const FX=preload("res://scripts/combat_visual.gd")
const Design=preload("res://scripts/monster_design.gd")
const Appearance=preload("res://scripts/monster_appearance.gd")
const Arms=preload("res://scripts/armament.gd")
const Combat=preload("res://scripts/combat_library.gd")
const Boss=preload("res://scripts/boss_art.gd")
const Attack=preload("res://scripts/attack_state.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func run() -> void:
	FX.ensure();Boss._ensure()
	var rng:=RandomNumberGenerator.new();rng.seed=13001
	var phases:Array=["idle","move","windup","active","recovery","hurt","death","prepare","brake","turn"]
	for species in Arms.MODES:
		for elite in [false,true]:
			var en:Dictionary=Arms.enemy(species,rng,elite);en["attack"]=Attack.new()
			for group in ["biological","weapon"]:
				en["attack"].begin({"group":group,"windup":1.0,"active":1.0,"recovery":1.0})
				for phase in phases:
					# Movement/adaptation must never alter its immutable body identity.
					en["movements"]=["dash","walk"];en["visual_movement"]="dash" if species!="dash" else "walk"
					var clip:String=FX.enemy_clip(en,phase)
					check(clip.begins_with("enemy_"+species+"_"),"Every normal/elite pose retains species despite movement and weapon changes: "+species+"/"+phase)
					for f:Dictionary in FX.definition(clip)["frames"]:check(str(f["path"]).begins_with("common/enemy_"+species+"/"),"All sampled frame paths belong to the same creature")
				en["attack"].cancel()
		# Deliberately remove a pose: only this same creature's move art may fill in.
		var missing:String="enemy_"+species+"_attack";var saved:Dictionary=FX.manifest["animations"][missing]
		FX.manifest["animations"].erase(missing)
		var en:Dictionary=Arms.enemy(species,rng,true)
		check(FX.enemy_clip(en,"active")=="enemy_"+species+"_move","Missing attack cannot fall back to another species")
		FX.manifest["animations"][missing]=saved
		# If all its art disappears, refuse unrelated guardian/beetle replacement.
		var saved_move:Dictionary=FX.manifest["animations"]["enemy_"+species+"_move"]
		FX.manifest["animations"].erase(missing);FX.manifest["animations"].erase("enemy_"+species+"_move")
		check(FX.enemy_clip(en,"active").is_empty(),"Missing species fails closed rather than changing identity")
		FX.manifest["animations"][missing]=saved;FX.manifest["animations"]["enemy_"+species+"_move"]=saved_move
	var cute:Dictionary=Arms.cute_wanderer(rng)
	for phase in phases:
		var clip:String=FX.enemy_clip(cute,phase)
		check(clip.begins_with("enemy_pillbug_") and FX.texture_for(clip) is AtlasTexture,"Cute walking/hurt/death particles all use pillbug, never beetle")
		var tex:AtlasTexture=FX.texture_for(clip)
		check(tex.region==Appearance.PILLBUG_REGION,"Pillbug uses its exact authored source region")
	for biome in Combat.BOSS_BIOMES:
		var boss:Dictionary=Combat.boss(biome)
		for phase in ["move","hurt","death"]:
			check(FX.enemy_clip(boss,phase).begins_with(biome+"_"),"Boss feedback uses own biome art: "+biome)
		for role in ["move","melee","ranged"]:
			for f:Dictionary in Boss.manifest["animations"][biome+"_"+role]["frames"]:check(str(f["path"]).begins_with(biome+"_"),"Boss states remain within their own atlas")
		for role in ["hurt","death"]:
			for f:Dictionary in FX.definition(biome+"_"+role)["frames"]:check(str(f["path"]).begins_with(biome+"/boss/"),"Boss injury/death shares its own creature identity")
	check(FX.enemy_clip({"species":"unknown","movements":["walk"]},"active").is_empty(),"Unknown species is never silently replaced by beetle")
	# Bind the visually reviewed real PNG bytes, not just their misleading names.
	var audit:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/monster-art-identity-v13.json"))
	for path in audit["sha256"]:check(FileAccess.get_sha256(path)==audit["sha256"][path],"Reviewed image bytes retain their audited identity: "+path)
	print("Monster identity v0.13: ","passed (all normal/elite/cute/Boss phases + missing-pose fallbacks + %d audited images)"%audit["sha256"].size() if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
