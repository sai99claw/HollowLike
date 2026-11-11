extends RefCounted

const FACETS:Array[String]=["歸屬","用途","生態系","版本","格式","使用狀態","自訂"]
const BIOMES:Dictionary={"underground":"地底","trunk":"樹幹","sky":"天空","canopy":"樹梢","branches":"樹枝","grass":"草地"}

static func for_asset(item:Dictionary) -> PackedStringArray:
	var id:String=item["id"]
	var path:String=item["frames"][0].get("path","")
	var category:String=item["category"]
	var subject:String=item.get("clip",id.get_slice(":",id.get_slice_count(":")-1))
	var words:PackedStringArray=(id+" "+path).to_lower().replace(":", " ").replace("/", " ").replace("_", " ").replace("-", " ").replace(".", " ").split(" ",false)
	var tags:=PackedStringArray([
		"歸屬/"+str(item["group"]),
		"格式/"+("動畫" if int(item["frame_count"])>1 else "靜態"),
		"使用狀態/"+("已使用" if item.get("runtime_usage")=="used" else "未使用"),
	])
	if item.get("kind")=="procedural":tags.append("格式/即時繪製")
	if "特效" in category or "/effects/" in path or "命中" in category:tags.append("用途/特效")
	if "投射物" in category and (not "武器與" in category or subject.begins_with("projectile_") or subject.begins_with("flying_slash") or subject.begins_with("trap_") or subject.begins_with("beam_")):
		tags.append("用途/投射物")
	if "武器" in category or subject.begins_with("weapon_") or subject.begins_with("secondary_"):
		if category!="符文與道具圖示" or subject.begins_with("secondary_"):tags.append("用途/武器")
	if id.begins_with("inventory:runes:") or "/runes/" in path or subject.begins_with("runes_") or subject.begins_with("strong_") or category=="小符文":tags.append("用途/符文")
	if id.begins_with("inventory:items:") or subject.begins_with("items_"):tags.append("用途/道具")
	if subject.begins_with("skills_"):tags.append("用途/技能")
	if subject.begins_with("growth_"):tags.append("用途/強化")
	if category=="主角姿態" or category.begins_with("小怪動作") or category.begins_with("怪物移動") or (category.begins_with("怪物 /") and "move" in words):tags.append("用途/角色動作")
	if "背景" in category or "中景" in category or "裝飾" in category or "地形" in category or "跳台" in category:tags.append("用途/場景")
	if "互動物件" in category or "可砍物件" in category or "生態物件" in category:tags.append("用途/互動物件")
	if not Array(tags).any(func(tag:String)->bool:return tag.begins_with("用途/")):tags.append("用途/"+category)
	for biome:String in BIOMES:
		if biome in words:tags.append("生態系/"+BIOMES[biome])
	for word:String in words:
		if word.begins_with("v") and word.substr(1).is_valid_int():
			var version:String="版本/v%d"%int(word.substr(1))
			if not version in tags:tags.append(version)
	return tags

static func matches(tags:PackedStringArray,included:Dictionary,excluded:Dictionary) -> bool:
	for tag:String in excluded:
		if tag in tags:return false
	var facets:Dictionary={}
	for tag:String in included:
		var facet:String=tag.get_slice("/",0)
		facets[facet]=bool(facets.get(facet,false)) or tag in tags
	return not facets.values().has(false)
