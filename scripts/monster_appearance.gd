class_name MonsterAppearance
extends RefCounted
## Appearance belongs to a species, independently of its current AI movement.
const SPECIES=["walk","jump","hover","drift","dash","pillbug"]
const BOSSES=["sky","canopy","branches","trunk","grass","underground"]
const PILLBUG_SOURCE="res://assets/monster_v10/projectile-atlas.png"
const PILLBUG_REGION=Rect2(1138,572,260,206)
static var pillbug_texture:AtlasTexture
static func species(en:Dictionary) -> String:
	if en.get("cute",false) or en.get("species","")=="cute_pillbug":return "pillbug"
	var selected:String=str(en.get("species",en.get("visual_movement","")))
	if selected.is_empty():
		var movements:Array=en.get("movements",[])
		if not movements.is_empty():selected=str(movements[0])
	return selected if selected in SPECIES else ""
static func is_boss(en:Dictionary) -> bool:return en.get("is_boss",false) or int(en.get("model",0))==4
static func biome(en:Dictionary) -> String:
	var selected:String=str(en.get("biome",""))
	return selected if selected in BOSSES else ""
static func is_pillbug_clip(id:String) -> bool:
	return id in ["enemy_pillbug_move","enemy_pillbug_attack","enemy_pillbug_hurt","enemy_pillbug_death","enemy_pillbug_turn","enemy_pillbug_prepare","enemy_pillbug_brake"]
static func pillbug_definition(id:String) -> Dictionary:
	if not is_pillbug_clip(id):return {}
	return {"species":"pillbug","fps":1,"frames":[{"path":"../monster_v10/projectile-atlas.png","source_rect":[1138,572,260,206],"pivot":[130,206],"size":[260,206],"visible_bounds":[0,0,260,206]}]}
static func pillbug() -> Texture2D:
	if pillbug_texture==null:
		if not ResourceLoader.exists(PILLBUG_SOURCE):return null
		pillbug_texture=AtlasTexture.new();pillbug_texture.atlas=load(PILLBUG_SOURCE);pillbug_texture.region=PILLBUG_REGION
	return pillbug_texture

static var boss_manifest:Dictionary={}
static func boss_definition(id:String) -> Dictionary:
	var selected:String=""
	for candidate in BOSSES:
		if id==candidate+"_move":selected=candidate;break
	if selected.is_empty():return {}
	if boss_manifest.is_empty():
		var path:String="res://assets/bosses/manifest.json"
		if not FileAccess.file_exists(path):return {}
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:boss_manifest=parsed
	if not boss_manifest.get("animations",{}).has(id):return {}
	var result:Dictionary=boss_manifest["animations"][id].duplicate(true)
	for frame:Dictionary in result["frames"]:
		frame["path"]="../bosses/"+str(frame["path"])
		frame["visible_bounds"]=[0,0,frame["size"][0],frame["size"][1]]
	return result
