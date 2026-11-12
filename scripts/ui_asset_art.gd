class_name UIAssetArt
extends RefCounted
## Menu art comes from the same delivered sprites as the world. Atlas regions
## remove transparent padding without rewriting any source PNG.
const InventoryArt=preload("res://scripts/inventory_art.gd")
const FX=preload("res://scripts/combat_visual.gd")
const Data=preload("res://scripts/game_data.gd")
const Arms=preload("res://scripts/armament.gd")
static var icons:Dictionary={}

static func texture(clip:String) -> Texture2D:
	if icons.has(clip):return icons[clip]
	if clip=="items_shock":return preload("res://assets/v54/items_shock.svg")
	if clip=="items_power":
		var icon:Texture2D=load("res://assets/v54/"+clip+".svg")
		icons[clip]=icon
		return icon
	clip={"strong_single_pierce":"strong_swiftblade","strong_held_flight":"strong_heartplus","strong_poison_trail":"runes_pierce","strong_steady_energy":"strong_motion_energy"}.get(clip,clip)
	if clip.begins_with("runes_sub_"):
		var path:String="res://assets/v24/runes/rune_"+clip.trim_prefix("runes_")+".png"
		if ResourceLoader.exists(path):
			var image:Texture2D=load(path);var atlas:=AtlasTexture.new();atlas.atlas=image;atlas.region=Rect2(Vector2.ZERO,image.get_size());icons[clip]=atlas;return atlas
	if clip.begins_with("secondary_"):
		var weapon:Texture2D=preload("res://scripts/weapon_art_v24.gd").texture(clip.trim_prefix("secondary_"))
		if weapon!=null:
			var atlas:=AtlasTexture.new();atlas.atlas=weapon;atlas.region=Rect2(Vector2.ZERO,weapon.get_size());icons[clip]=atlas;return atlas
	clip={"runes_rapid_slash":"runes_gale","runes_quick_charge":"runes_soul","runes_fleet_foot":"runes_wing","runes_sub_velocity":"runes_gale","runes_sub_reach":"runes_reach","runes_sub_power":"runes_pierce","runes_sub_volume":"runes_multishot"}.get(clip,clip)
	var new_art:Texture2D=InventoryArt.texture(clip)
	if new_art!=null:return new_art
	clip={"runes_dewflow":"runes_soul","runes_swarm":"strong_orbit_bee","runes_multishot":"growth_shots","secondary_multibounce":"secondary_ricochet","secondary_impact_bomb":"weapon_bomb","secondary_piercing_laser":"beam_body","secondary_shockwave":"flying_slash_weapon","secondary_chain_staff":"weapon_spear"}.get(clip,clip)
	if clip.is_empty():return null
	if icons.has(clip):return icons[clip]
	var definition:Dictionary=FX.definition(clip)
	if definition.is_empty():return null
	var raw:Texture2D=FX.texture_for(clip)
	if raw==null:return null
	var frame:Dictionary=definition["frames"][0]
	var size:Vector2=Vector2(frame["size"][0],frame["size"][1])
	var bounds:Array=frame.get("visible_bounds",definition.get("visual_bounds",[0,0,size.x,size.y]))
	var ratio:Vector2=raw.get_size()/size
	var atlas:=AtlasTexture.new();atlas.atlas=raw
	atlas.region=Rect2(Vector2(bounds[0],bounds[1])*ratio,Vector2(bounds[2],bounds[3])*ratio)
	icons[clip]=atlas
	return atlas

static func rune(id:String,strong:bool=false) -> String:
	return ("strong_" if strong or Data.is_strong(id) else "runes_")+id

static func primary(weapon:Dictionary) -> String:
	return {"foot":"pigeon_talons_kick","quick":"weapon_feather","heavy":"weapon_heavy"}.get(str(weapon.get("style","")),"")

static func secondary(weapon:Dictionary) -> String:
	var id:String=str(weapon.get("id",""))
	if preload("res://scripts/weapon_art_v24.gd").texture(id)!=null:return "secondary_"+id
	if InventoryArt.texture("secondary_"+id)!=null or FX.has_clip("secondary_"+id):return "secondary_"+id
	return str(weapon.get("weapon_visual",{"sword":"weapon_feather","throw":"weapon_bomb","beam":"beam_body","bounce":"projectile_marble","fan":"projectile_needle"}.get(str(weapon.get("weapon_kind",weapon.get("kind","shot"))),"weapon_launcher")))

static func by_text(text:String) -> String:
	for s in Data.SKILLS:
		if text.contains(str(s["name"])):return "skills_"+str(s["id"])
	for r in Data.all_runes():
		if text.contains(str(r["name"])):return rune(str(r["id"]),bool(r.get("strong",false)))
	for item in Data.ITEMS:
		if text.contains(str(item["name"])):return "items_"+str(item["id"])
	for weapon in Data.SECONDARY:
		if text.contains(str(weapon["name"])):return "secondary_"+str(weapon["id"])
	return ""

static func held_growth(summary:String) -> Array[String]:
	var result:Array[String]=[]
	for id in Arms.GROWTH:
		if summary.contains(str(Arms.GROWTH_NAMES[id])):result.append(str(id))
	return result
