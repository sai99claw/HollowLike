class_name InventoryArt
extends RefCounted
const ROOT="res://assets/inventory_v11/"
static var manifest:Dictionary={}
static var sheets:Dictionary={}
static var icons:Dictionary={}
static func texture(clip:String) -> Texture2D:
	if icons.has(clip):return icons[clip]
	if manifest.is_empty() and FileAccess.file_exists(ROOT+"manifest.json"):manifest=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	var group:String="items";var id:String=clip
	if clip.begins_with("runes_"):group="runes";id=clip.trim_prefix("runes_")
	elif clip.begins_with("strong_"):group="runes";id=clip.trim_prefix("strong_")
	if not manifest.get(group,{}).has(id):return null
	if not sheets.has(group):sheets[group]=load(ROOT+group+".png")
	var raw:Array=manifest[group][id];var atlas:=AtlasTexture.new();atlas.atlas=sheets[group];atlas.region=Rect2(raw[0],raw[1],raw[2],raw[3]);icons[clip]=atlas;return atlas
