class_name ArtCatalogV16
extends RefCounted
## RD asset metadata is cheap. Texture decoding happens only for selected frames.
## No call into the gameplay art helpers' unbounded texture caches is needed.
const CACHE_LIMIT:int=24
const ROOT:String="res://assets/"
const BIOME_NAMES:Dictionary={"sky":"天空","trunk":"樹幹","underground":"地底","canopy":"樹梢（舊區）","branches":"樹枝（舊區）","grass":"草地（舊區）"}
const OBJECT_NAMES:Dictionary={"sky":["藍風草","白絨雲花","青晶蘆","藍羽薊","藍釉天甕","浮空浮石"],"trunk":["翡翠蕨","三葉幼苗","樹皮層菇","苔種莢","捲藤芽","橡果燈"],"underground":["琥珀晶簇","象牙洞菇","捲根叢","赤陶甕","發光根球","頁岩石堆"]}
const HOME_SLEEP:Array[Array]=[[43,339,500,238],[543,301,531,274],[1122,132,495,458],[1657,178,477,406]]
const ACTION_REGIONS:Array[Array]=[[[20,105,259,211],[346,87,251,230],[656,63,258,254],[969,69,240,248]],[[25,423,266,220],[335,417,274,218],[648,426,289,212],[967,421,279,217]],[[19,715,297,178],[312,714,317,144],[625,736,317,118],[938,713,303,168]],[[69,922,196,250],[408,921,143,279],[720,914,222,302],[938,1026,299,165]]]
const IMPACT_BASELINES:Array[int]=[300,300,300,300,647,647,647,647,972,972,972,972]
static var _entries:Array[Dictionary]=[]
static var _by_id:Dictionary={}
static var _covered:Dictionary={}
static var _cache:Dictionary={}
static var _lru:Array[String]=[]

static func entries() -> Array[Dictionary]:return all_entries()
static func all_entries() -> Array[Dictionary]:
	if not _entries.is_empty():return _entries
	for library:String in ["combat_v05","illustrated","bosses","walk_v2"]:_animation_manifest(library)
	_inventory();_sanctuary();_monster();_ecology();_curated_sheets();_motion_v18();_idle_v19();_biomes_v21();_v22();_v23();_v24();_procedural()
	# PCK directories expose remapped source names. Discover future image assets
	# as well, so a newly generated v16 effect is never invisible in the RD room.
	_monsters_v36();_art_v37();_art_v38();_art_v39()
	_remaining_images(ROOT)
	var audit:Dictionary=_json(ROOT+("v24/asset-audit.json" if FileAccess.file_exists(ROOT+"v24/asset-audit.json") else "v23/asset-audit.json" if FileAccess.file_exists(ROOT+"v23/asset-audit.json") else "v22/asset-audit.json")).get("entries",{})
	for item:Dictionary in _entries:
		if str(item["id"]).begins_with("v36:") or str(item["id"]).begins_with("v37:") or str(item["id"]).begins_with("v38:") or str(item["id"]).begins_with("v39:"):item.merge({"runtime_usage":"used","usage_note":"目前生態怪物、攻擊前搖或投射物。"},true)
		else:item.merge(audit.get(item["id"],{"runtime_usage":"un-used","usage_note":"保留於素材庫，未接入目前遊戲畫面。"}),true)
	_entries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a["category"])+str(a["label"])<str(b["category"])+str(b["label"]))
	return _entries

static func entry(id:String) -> Dictionary:
	all_entries();return _by_id.get(id,{})

static func _art_v37() -> void:
	var data:Dictionary=_json(ROOT+"v37/effects/feather-crescent.json")
	for kind:String in ["feathers"]:
		var frames:Array=[]
		for f:Dictionary in data.get("animations",{}).get(kind,[]):frames.append(_descriptor(ROOT+"v37/effects/"+data["path"],f["source_rect"]))
		_add("v37:"+kind,"命中碎羽" if kind=="feathers" else "大型月牙","戰鬥特效",frames,16,"三張獨立貼圖，命中點噴出碎羽與亮色月牙。")
	data=_json(ROOT+"v37/player/ledge-mantle.json");var frames:Array=[]
	for f:Dictionary in data.get("frames",[]):frames.append(_descriptor(ROOT+"v37/player/"+data["path"],f["source_rect"]))
	_add("v37:mantle","攀上平台","主角",frames,12.5,"牆邊接觸不足51%時，四張關鍵姿勢攀上平台。")

static func _art_v38() -> void:
	var data:Dictionary=_json(ROOT+"v38/effects/clean-crescent.json")
	_add("v38:crescent","細長月牙","戰鬥特效",[_descriptor(ROOT+"v38/effects/"+data["path"],data["source_rect"])],8,"單一道細長月牙，角度隨機。")
	data=_json(ROOT+"v38/effects/laser-beam.json");var frames:Array=[]
	for f:Dictionary in data.get("frames",[]):frames.append(_descriptor(ROOT+"v38/effects/"+data["path"],f["source_rect"]))
	_add("v38:laser","連續雷射","戰鬥特效",frames,24,"八張連續光束貼圖，寬度與命中範圍相同。")

static func _art_v39() -> void:
	var d:Dictionary=_json(ROOT+"v39/effects/fine-crescent.json")
	_add("v39:crescent","細長月牙","戰鬥特效",[_descriptor(ROOT+"v39/effects/"+d["path"],d["source_rect"])],8,"月牙中段對準敵人中心。")
	for biome:String in ["underground","trunk","sky"]:
		d=_json(ROOT+"v39/monsters/"+biome+"-death.json")
		for i in 7:
			_add("v39:"+biome+":death:"+str(i),BIOME_NAMES[biome]+" · 死亡姿勢 "+str(i+1),"怪物",[_descriptor(ROOT+"v39/monsters/"+d["path"],d["frames"][i]["source_rect"])],1,"專用倒地姿勢，固定面向、尺寸與接地線。")

static func _monsters_v36() -> void:
	for biome:String in ["underground","trunk","sky"]:
		var data:Dictionary=_json(ROOT+"v36/monsters/"+biome+"-runtime.json");var brief:Dictionary=_json(ROOT+"v36/monsters/"+biome+"-brief.json")
		if data.is_empty():continue
		for sheet:String in ["regular","elite"]:
			var spec:Dictionary=data["sheets"][sheet]
			for row:int in int(spec["rows"]):
				var actor:Array=brief["elite" if sheet=="elite" else "regular"][row/2 if sheet=="elite" else row]
				for phase:String in ["move","windup","active","recovery"]:
					var art=preload("res://scripts/monster_art_v36.gd");var start:int=int(art.phase_columns(sheet=="elite")[phase]);var frames:Array=[]
					for index:int in int(art.phase_counts(sheet=="elite")[phase]):frames.append(_descriptor(ROOT+"v36/monsters/"+spec["path"],spec["frames"][row*12+start+index]["rect"]))
					_add("v36:"+biome+":"+sheet+":"+str(row)+":"+phase,str(actor[1])+" · "+("第%d招 · "%[row%2+1] if sheet=="elite" else "")+{"move":"移動","windup":"前搖","active":"攻擊","recovery":"收招"}[phase],"怪物 / "+BIOME_NAMES[biome],frames,8,"依行為設定先設計，再由圖片模型繪製；固定腳底。")
		for id:String in data["projectiles"]:
			var spec:Dictionary=data["sheets"]["projectiles"];var row:int=int(data["projectiles"][id]["row"]);var frames:Array=[]
			for index:int in 8:frames.append(_descriptor(ROOT+"v36/monsters/"+spec["path"],spec["frames"][row*8+index]["rect"]))
			_add("v36:"+biome+":"+id,BIOME_NAMES[biome]+" · "+id,"怪物投射物",frames,14,"八幀獨立旋轉貼圖與繪製拖尾。")
static func categories() -> Array[String]:
	var result:Array[String]=[]
	for item:Dictionary in all_entries():
		if not result.has(item["category"]):result.append(item["category"])
	return result
static func search(query:String="",category:String="",kind:String="all") -> Array[Dictionary]:
	var result:Array[Dictionary]=[];var terms:PackedStringArray=_search_text(query).split(" ",false)
	for item:Dictionary in all_entries():
		if not category.is_empty() and item["category"]!=category:continue
		if kind=="animated" and int(item["frame_count"])<=1:continue
		if kind=="still" and int(item["frame_count"])!=1:continue
		var text:String=_search_text(str(item["id"])+" "+str(item["label"])+" "+str(item.get("notes",""))+" "+str(item["category"])+" "+str(item.get("runtime_usage","")))
		var matches:bool=true
		for term in terms:
			if not text.contains(term):matches=false;break
		if matches:result.append(item)
	return result
static func _search_text(value:String) -> String:
	return value.to_lower().replace("鴿子","主角").replace("走路","行走").replace("附武器","副武器").replace("boss","首領").replace("／","").replace("　"," ").replace("\t"," ").strip_edges()

static func _json(path:String) -> Dictionary:
	if not FileAccess.file_exists(path):return {}
	var value:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func _add(id:String,label:String,category:String,frames:Array,fps:float=12,notes:String="",extra:Dictionary={}) -> void:
	if frames.is_empty() or _by_id.has(id):return
	var sequence_indices:Array[int]=[]
	for i in frames.size():
		sequence_indices.append(i)
		if frames[i].has("path"):_covered[str(frames[i]["path"])]=true
	var item:Dictionary={"id":id,"label":label,"category":category,"frame_count":frames.size(),"fps":fps,"frames":frames,"sequence":sequence_indices,"phases":{},"loop":[],"notes":notes,"kind":"texture"}
	item.merge(extra,true);_entries.append(item);_by_id[id]=item
static func _descriptor(path:String,region:Array=[],grid:Array=[],cell:Array=[]) -> Dictionary:
	var result:Dictionary={"path":path}
	if not region.is_empty():result["region"]=region
	if not grid.is_empty():result["grid"]=grid;result["cell"]=cell
	return result
static func _sheet(id:String,label:String,category:String,path:String,columns:int,rows:int,count:int,fps:float=12,extra:Dictionary={}) -> void:
	if not ResourceLoader.exists(path):return
	var frames:Array=[]
	for i in count:frames.append(_descriptor(path,[],[columns,rows],[i%columns,i/columns]))
	_add(id,label,category,frames,fps,"透明圖集按格播放；固定同一畫布尺寸。",extra)
static func _animation_manifest(library:String) -> void:
	var root:String=ROOT+library+"/";var data:Dictionary=_json(root+"manifest.json")
	for raw_id in data.get("animations",{}):
		var id:String=str(raw_id);var clip:Dictionary=data["animations"][id];var frames:Array=[]
		for original:Dictionary in clip.get("frames",[]):
			# These PNGs are already cropped from their original source sheet.
			# source_rect is provenance, not a second runtime crop.
			var frame_data:Dictionary=_descriptor(root+str(original["path"]))
			for field:String in ["pivot","size","visible_bounds"]:
				if original.has(field):frame_data[field]=original[field]
			frames.append(frame_data)
		var extra:Dictionary={"library":library,"clip":id,"phases":clip.get("phases",{}).duplicate(true),"complete_release":clip.get("complete_release",false)}
		if clip.has("loop_start"):extra["loop"]=[int(clip["loop_start"]),int(clip["loop_end"])]
		_add(library+":"+id,_label(id),_category(id,library),frames,float(clip.get("fps",12)),str(clip.get("description","")),extra)
	for raw_id in data.get("modules",{}):
		var module:Dictionary=data["modules"][raw_id]
		_add(library+":module:"+str(raw_id),"地景模組 · "+str(raw_id),"地形與背景",[_descriptor(root+str(module["path"]))],1)
	for raw_id in data.get("backgrounds",{}):_add(library+":background:"+str(raw_id),"舊區背景 · "+str(raw_id),"地形與背景",[_descriptor(root+str(data["backgrounds"][raw_id]))],1)
static func _inventory() -> void:
	var root:String=ROOT+"inventory_v11/";var data:Dictionary=_json(root+"manifest.json")
	for group:String in ["runes","items"]:
		for raw_id in data.get(group,{}):
			var id:String=str(raw_id);_add("inventory:"+group+":"+id,_label(("runes_" if group=="runes" else "")+id),"符文與道具圖示",[_descriptor(root+group+".png",data[group][id])],1)
static func _sanctuary() -> void:
	var root:String=ROOT+"sanctuary_v12/";var data:Dictionary=_json(root+"manifest.json")
	for raw_id in data.get("parts",{}):
		var item:Dictionary=data["parts"][raw_id];_add("sanctuary:"+str(raw_id),"商店／溫泉 · "+_label(str(raw_id)),"場景互動物件",[_descriptor(root+str(item["file"]),item["region"])],1)
static func _monster() -> void:
	var root:String=ROOT+"monster_v10/";var data:Dictionary=_json(root+"manifest.json")
	for raw_id in data.get("regions",{}):_add("monster_projectile:"+str(raw_id),"生態投射物 · "+str(raw_id),"怪物投射物與陷阱",[_descriptor(root+str(data.get("file","projectile-atlas.png")),data["regions"][raw_id])],1)
static func _ecology() -> void:
	for biome:String in ["underground","trunk","sky"]:
		var root:String=ROOT+"ecology_v15/";var name:String=BIOME_NAMES[biome]
		for depth:String in ["far","mid","near"]:
			var role:String={"far":"背景","mid":"中景","near":"前景"}[depth]
			_add("ecology:"+biome+":"+depth,name+" · "+role,"地形與背景",[_descriptor(root+biome+"_"+depth+".png")],1)
		for row in 6:
			var frames:Array=[]
			for column in 5:frames.append(_descriptor(root+biome+"_objects.png",[],[5,6],[column,row]))
			_add("ecology:"+biome+":object:"+str(row),name+" · "+str(OBJECT_NAMES[biome][row]),"生態可砍物件",frames,6.666667,"0完整／1受砍／2碎裂／3落屑／4殘屑；破壞四格共0.6秒。",{"phases":{"idle":[0],"break":[1,2,3,4]},"baseline":.875})
		for i in 4:
			_add("ecology:"+biome+":terrain:"+str(i),name+" · "+["實心材質","上緣材質","單向跳台","方塊"][i],"地形與背景",[_descriptor(root+biome+"_terrain.png",[],[2,2],[i%2,i/2])],1)
	for depth:String in ["far","mid"]:
		var path:String=ROOT+"ecology_v15/merchant_"+depth+".png"
		if ResourceLoader.exists(path):_add("merchant:"+depth,"商店獨立 · "+("背景" if depth=="far" else "中景"),"地形與背景",[_descriptor(path)],1)
static func _curated_sheets() -> void:
	_sheet("explosion:surface","爆炸 · 貼面受限擴散","衝刺與爆炸特效",ROOT+"v16/explosion_surface.png",4,2,8,16,{"baseline":.875,"effect_plane":"surface"})
	_sheet("explosion:air","爆炸 · 空中全向擴散","衝刺與爆炸特效",ROOT+"v16/explosion_air.png",4,2,8,16,{"effect_plane":"air"})
	_sheet("wind:jet","單C · 小噴射","衝刺與爆炸特效",ROOT+"motion_v14/dash-jet.png",3,2,6,37.5)
	_sheet("wind:form","雙C · 化身為風","衝刺與爆炸特效",ROOT+"motion_v14/wind-form.png",4,2,8,24)
	_sheet("wind:impact","下衝 · 接地衝擊","衝刺與爆炸特效",ROOT+"motion_v14/ground-impact.png",4,3,12,24,{"clip_baselines":IMPACT_BASELINES})
	_sheet("merchant:owl","貓頭鷹商人 · 待機","角色與NPC",ROOT+"adventure_v08/owl_merchant.png",2,2,4,1.5)
	for row in ACTION_REGIONS.size():
		var frames:Array=[]
		for region_data:Array in ACTION_REGIONS[row]:frames.append(_descriptor(ROOT+"adventure_v08/pigeon_actions.png",region_data))
		_add("pigeon_action:"+str(row),["鴿子 · 回血","鴿子 · 重傷跛行","舊衝刺姿態","舊下衝姿態"][row],"主角姿態",frames,5)
	var sleeping:Array=[]
	for region_data:Array in HOME_SLEEP:sleeping.append(_descriptor(ROOT+"home_v13/sleep.png",region_data))
	_add("home:sleep","鳥巢 · 睡眠與起身","主角姿態",sleeping,6)
	for id:String in ["background","musou","rogue","nest"]:
		_add("home:"+id,"鳥巢 · "+{"background":"樹梢背景","musou":"無雙夢境大門","rogue":"冒險大門","nest":"鳥巢"}[id],"首頁與大門",[_descriptor(ROOT+"v33/home/background.png") if id=="background" else _descriptor(ROOT+"v33/home/props.png",[],[2,2],[0 if id=="musou" else 1,0]) if id in ["musou","rogue"] else _descriptor(ROOT+"v34/home/nest.png")],1)
	for id:String in ["background","musou","rogue","nest"]:_covered[ROOT+"home_v13/"+id+".png"]=true
	_sheet("ambient:bird","遠景飛鳥 · 四格","環境生物",ROOT+"atmosphere_v09/bird.png",4,1,4,7)
	_sheet("ambient:dragonfly","近景蜻蜓 · 四格","環境生物",ROOT+"atmosphere_v09/dragonfly.png",4,1,4,22)
	_sheet("spring:legacy","舊溫泉 · 四格水氣","場景互動物件",ROOT+"atmosphere_v10/spring.png",2,2,4,3)
static func _remaining_images(directory:String) -> void:
	var dir:DirAccess=DirAccess.open(directory)
	if dir==null:return
	var subdirectories:PackedStringArray=dir.get_directories();subdirectories.sort()
	for folder:String in subdirectories:
		if not folder.begins_with("."):_remaining_images(directory+folder+"/")
	var names:PackedStringArray=dir.get_files();names.sort()
	for filename:String in names:
		var original:String=filename.trim_suffix(".remap")
		if original.get_extension().to_lower() not in ["png","webp","jpg","jpeg","svg"]:continue
		var path:String=directory+original
		if _covered.has(path) or not ResourceLoader.exists(path):continue
		var category:String="原圖與其他素材"
		if directory.contains("ecology"):category="地形與背景"
		elif directory.contains("explosion") or directory.contains("motion"):category="衝刺與爆炸特效"
		_add("raw:"+path.trim_prefix(ROOT),original.get_basename(),category,[_descriptor(path)],1,"原始圖檔；若為新圖集且尚未登記切片，會先顯示完整圖集。")

static func _category(id:String,library:String) -> String:
	if library=="bosses":return "Boss動作與特效"
	if library=="walk_v2" or id.begins_with("pigeon_"):return "主角姿態"
	if id.begins_with("enemy_") or id.begins_with("elite_"):return "小怪動作"
	if id.begins_with("runes_") or id.begins_with("strong_") or id.begins_with("items_") or id.begins_with("skills_") or id.begins_with("growth_") or id.begins_with("secondary_"):return "符文與道具圖示"
	if id.begins_with("weapon_") or id.begins_with("projectile_") or id.begins_with("trap_") or id.begins_with("beam_") or id.begins_with("flying_slash"):return "武器與投射物"
	for biome:String in BIOME_NAMES:
		if id.begins_with(biome+"_"):return "地形與背景"
	if id.begins_with("rack_") or id.begins_with("delivery_") or id.begins_with("first_aid_") or id.begins_with("dummy_") or id.begins_with("energy_flower_"):return "場景互動物件"
	return "攻擊與命中特效"
static func _label(id:String) -> String:
	var exact:Dictionary={"pigeon_walk":"鴿子行走","pigeon_walk_master":"鴿子行走 · 原解析度","coin":"金幣","coin_spin":"金幣旋轉","table":"展示桌","awning":"商店布幔","sign":"木招牌","dummy":"試打假人","water":"溫泉水面","steam":"水氣","pool_back":"溫泉後緣","pool_front":"溫泉前緣","pigeon_talons_kick":"腳爪踢","weapon_feather":"羽毛刀","weapon_heavy":"大刀","death_feather_glow":"死亡發光羽毛"}
	if exact.has(id):return exact[id]+" · "+id
	var words:Dictionary={"pigeon":"主角","enemy":"小怪","elite":"菁英","walk":"行走","jump":"跳躍","hover":"懸停","drift":"遊盪","dash":"衝刺","pillbug":"鼠婦","move":"移動","attack":"攻擊","hurt":"受傷","death":"死亡","turn":"轉身","prepare":"蓄勢","brake":"煞停","charge":"蓄氣","feather":"羽毛","great":"重刀","talons":"腳爪","runes":"符文","strong":"強力符文","items":"消耗品","skills":"技能","secondary":"附武器","windup":"前搖","active":"出擊","recovery":"後搖","projectile":"投射物","trap":"陷阱","heal":"回血","energy":"能量","sky":"天空","canopy":"樹梢","branches":"樹枝","trunk":"樹幹","grass":"草地","underground":"地底"}
	var translated:Array[String]=[]
	for word:String in id.split("_"):
		if words.has(word):translated.append(words[word])
	return ("／".join(translated)+" · " if not translated.is_empty() else "")+id

static func sequence(item:Dictionary,phase:String="all") -> Array[int]:
	var result:Array[int]=[]
	var selected:Array=item.get("phases",{}).get(phase,[]) if phase!="all" else item.get("sequence",[])
	for value in selected:result.append(int(value))
	if result.is_empty():
		for i in int(item.get("frame_count",0)):result.append(i)
	return result
static func frame(item:Dictionary,index:int=0) -> Texture2D:
	if item.get("kind","")=="procedural":return null
	var frames:Array=item.get("frames",[])
	if frames.is_empty():return null
	index=clampi(index,0,frames.size()-1)
	var key:String="frame:"+str(item.get("id",""))+":"+str(index)
	if _cache.has(key):return _touch(key)
	var source:Dictionary=frames[index];var image:Texture2D=_texture(str(source.get("path","")))
	if image==null:return null
	var bounds:Rect2=Rect2(Vector2.ZERO,image.get_size());var crop:bool=false
	if source.has("region"):
		var raw:Array=source["region"];bounds=Rect2(raw[0],raw[1],raw[2],raw[3]);crop=true
	elif source.has("grid"):
		var grid:Array=source["grid"];var cell:Array=source["cell"];var extent:Vector2=image.get_size()/Vector2(grid[0],grid[1]);bounds=Rect2(Vector2(cell[0],cell[1])*extent,extent);crop=true
		if item.get("effect_plane","")=="surface":bounds.size.y*=.875
		var baselines:Array=item.get("clip_baselines",[])
		if index<baselines.size():bounds.size.y=maxf(1,float(baselines[index])-bounds.position.y)
	if not crop:return image
	var atlas:=AtlasTexture.new();atlas.atlas=image;atlas.region=bounds;atlas.filter_clip=true
	_put(key,atlas);return atlas
static func _texture(path:String) -> Texture2D:
	var key:String="source:"+path
	if _cache.has(key):return _touch(key)
	if path.is_empty() or not ResourceLoader.exists(path):return null
	var image:Texture2D=load(path) as Texture2D
	if image!=null:_put(key,image)
	return image
static func _touch(key:String) -> Texture2D:
	_lru.erase(key);_lru.append(key);return _cache[key]
static func _put(key:String,value:Texture2D) -> void:
	_cache[key]=value;_lru.erase(key);_lru.append(key)
	while _lru.size()>CACHE_LIMIT:_cache.erase(_lru.pop_front())
static func cache_size() -> int:return _cache.size()
static func clear_cache() -> void:_cache.clear();_lru.clear()

static func _procedural() -> void:
	for pair in [["door_boss","Boss門 · 紅光吸入"],["door_safe","安全門 · 綠光吸入"],["door_reward","獎勵門 · 金光吸入"],["water","溫泉 · 水面與水花"],["grass","草叢 · 風中搖曳"]]:
		var frames:Array=[]
		for i in 96:frames.append({"path":"res://scripts/rd_procedural_v16.gd","sample":i})
		_add("procedural:"+pair[0],pair[1],"即時程式特效",frames,12,"直接執行遊戲的繪圖函式；時間樣本可逐格播放。",{"kind":"procedural"})

static func _motion_v18() -> void:
	_sheet("slash:v18","普攻 · 白色羽刃月牙","攻擊與命中特效",ROOT+"v18/slash-smear.png",4,2,8,60,{"phases":{"active":[0,1,2,3,4,5,6,7]}})
	var data:Dictionary=_json(ROOT+"v18/monster-motion-manifest.json")
	for id:String in data.get("animations",{}):
		var clip:Dictionary=data["animations"][id];var frames:Array=[]
		for f:Dictionary in clip["frames"]:
			var descriptor:Dictionary=_descriptor(ROOT+"v18/"+str(clip["path"]),f["source_rect"])
			descriptor["pivot"]=f["pivot"];frames.append(descriptor)
		_add("motion:v18:"+id,str(clip.get("label",id)),"怪物移動",frames,float(clip.get("fps",12)),"獨立繪製八個姿勢；依物種固定身高與落腳點。",{"phases":{"move":[0,1,2,3,4,5,6,7]}})

static func _idle_v19() -> void:
	var root:String=ROOT+"v19/";var data:Dictionary=_json(root+"idle-manifest.json")
	for id:String in data.get("animations",{}):
		var clip:Dictionary=data["animations"][id];var frames:Array=[]
		for f:Dictionary in clip["frames"]:frames.append(_descriptor(root+clip["path"],f["source_rect"]))
		_add("idle:v19:"+id,"鴿子 · "+("待機呼吸" if id=="idle" else "趴地休息"),"主角姿態",frames,8,"8 fps；閒置五秒開始趴地，移動時立即起身。")

static func _biomes_v21() -> void:
	var atlas:Dictionary=_json(ROOT+"v21/atlas-metadata.json")
	var labels:Array[String]=["連續內部材質","上緣草苔","下緣垂根","垂直側牆","外側 L 角","內側凹角","獨立單格","直柱端點","一格跳台","兩格跳台","三格跳台","路面小石","底邊懸草","側牆突起","第二種內部材質","第二種上緣"]
	for biome:String in ["underground","trunk","sky"]:
		var name:String=BIOME_NAMES[biome]
		for i in 16:
			var cell:Dictionary=atlas.get("terrain-"+biome,{}).get("cells",{}).get("%d,%d"%[i%4,i/4],{})
			if cell.is_empty():continue
			_add("v21:terrain:"+biome+":"+str(i),name+" · "+labels[i],"地形連接模組",[_descriptor(ROOT+"v21/terrain-"+biome+".png",cell["region"])],1,"依地形暴露邊組合。連續材質按六格區段取樣，沒有逐格或兩格交替鏡像。")
		for i in 6:
			var cells:Dictionary=atlas.get("props-"+biome,{}).get("cells",{})
			if cells.is_empty():continue
			var frames:Array=[]
			for row in range(1,5):frames.append(_descriptor(ROOT+"v21/props-"+biome+".png",cells["%d,%d"%[i,row]]["region"]))
			_add("v21:object:"+biome+":"+str(i),name+" · 新可砍物件 %d"%(i+1),"新生態物件與破壞",frames,8,"完整、受砍、碎裂、殘骸；實際腳點與固定縮放由圖集 metadata 校準。",{"phases":{"idle":[0],"break":[1,2,3]}})
			_add("v21:middle:"+biome+":"+str(i),name+" · "+("大型" if i<3 else "中型")+"景物 %d"%(i%3+1),"新生態中景與裝飾",[_descriptor(ROOT+"v21/props-"+biome+".png",cells["%d,0"%i]["region"])],1,"中景獨立模糊材質，半透明，不含碰撞。")
			_add("v21:detail:"+biome+":"+str(i),name+" · 前前景裝飾 %d"%(i+1),"新生態中景與裝飾",[_descriptor(ROOT+"v21/props-"+biome+".png",cells["%d,5"%i]["region"])],1,"岩石、草叢與表面起伏，在互動角色上方繪製。")

static func _v22() -> void:
	var names:Dictionary={"walk":"苔甲步蟲","jump":"彈枝跳蟲","hover":"守燈懸蛾","drift":"流霧漂蛾","dash":"疾根衝蟲","pillbug":"可愛鼠婦","pollen_flower":"花粉花","moss_thorns":"苔根刺","silk_web":"織絲網","dew_pool":"露環苗床"}
	for library:String in ["death","trap","monster-actions","boss-actions","pigeon-motion"]:
		var data:Dictionary=_json(ROOT+"v22/"+library+"-manifest.json")
		var clips:Dictionary=data.get("clips",data.get("animations",{}))
		for id:String in clips:
			var clip:Dictionary=clips[id];var frames:Array=[]
			for f:Dictionary in clip["frames"]:
				var descriptor:Dictionary=_descriptor(ROOT+"v22/"+str(clip["path"]),f["source_rect"]);descriptor["pivot"]=f["pivot"];frames.append(descriptor)
			var label:String=names.get(id,BIOME_NAMES.get(id,id)+"首領");var category:String="死亡與屍體";var phases:Dictionary={}
			if library=="death":label+=" · 死亡與屍體";phases={"flight":[0,1,2,3],"landing":[4,5,6,7],"rest":[7]}
			elif library=="trap":category="陷阱安置動畫";label+=" · 安置與攻擊";phases={"install":[0,1,2,3,4],"attack":[5,6,7]}
			elif library=="pigeon-motion":category="主角姿態";label="鴿子 · "+{"drowsy":"窩地瞌睡點頭","air":"空中與落地","wall":"貼牆下滑"}.get(id,id)
			else:
				var parts:PackedStringArray=id.split("_");category="高解析怪物動作";label=(names.get(parts[0],BIOME_NAMES.get(parts[0],parts[0])+"首領"))+" · "+{"attack":"攻擊","hurt":"受擊","prepare":"蓄勢","brake":"煞停","melee":"近戰","ranged":"遠攻"}.get(parts[-1],parts[-1])
			_add("v22:"+library+":"+id,label,category,frames,float(clip.get("fps",8)),"獨立原畫、固定角色比例與接地支點。逐格圖形變化，沒有每幀自動縮放。",{"phases":phases})
	var surfaces:Dictionary=_json(ROOT+"v22/surfaces-manifest.json")
	for biome:String in surfaces.get("biomes",{}):
		var data:Dictionary=surfaces["biomes"][biome];var path:String=ROOT+"v22/"+str(data["path"])
		_add("v22:material:"+biome,BIOME_NAMES[biome]+" · 實心地形材質","實心地形與固定跳台",[_descriptor(path,data["material"]["source_rect"])],1,"高密度內部材質，四邊填滿碰撞範圍；外緣裝飾獨立繪製。")
		for count in range(1,5):
			_add("v22:platform:"+biome+":"+str(count),BIOME_NAMES[biome]+" · %d 格跳躍平台"%count,"實心地形與固定跳台",[_descriptor(path,data["platforms"][str(count)]["body_source_rect"])],1,"一、二、三、四格各有獨立原畫；同一種平台固定比例，不隨房間或實例縮放。")
	var splash:Dictionary=_json(ROOT+"v22/water-splash-manifest.json");var frames:Array=[]
	for f:Dictionary in splash.get("frames",[]):frames.append(_descriptor(ROOT+"v22/"+str(splash["path"]),f["source_rect"]))
	if not frames.is_empty() and ResourceLoader.exists(ROOT+"v22/"+str(splash.get("path",""))):_add("v22:water_attack","水中攻擊 · 定向噴濺","攻擊與命中特效",frames,16,"八幀水花原畫；跟隨實際攻擊方向，從水面噴出，半秒播完。")

static func _v23() -> void:
	for library:String in ["pigeon-motion","launcher"]:
		var data:Dictionary=_json(ROOT+"v23/"+library+"-manifest.json")
		for id:String in data.get("clips",data.get("animations",{})):
			var clip:Dictionary=data.get("clips",data.get("animations",{}))[id];var frames:Array=[]
			for f:Dictionary in clip["frames"]:
				var descriptor:Dictionary=_descriptor(ROOT+"v23/"+str(clip["path"]),f["source_rect"]);descriptor["pivot"]=f["pivot"];frames.append(descriptor)
			var label:String="鴿子 · "+("統一比例空中動作" if id=="air" else "雙腳平貼牆面") if library=="pigeon-motion" else BIOME_NAMES[id]+" · 彈射風菇"
			_add("v23:"+library+":"+id,label,"主角姿態" if library=="pigeon-motion" else "彈射互動物件",frames,8,"身體固定比例、獨立接觸點。彈射物件碰觸一倍跳高、砍中三倍跳高。")
	var decor:Dictionary=_json(ROOT+"v23/edge-decor-manifest.json")
	for biome:String in decor.get("biomes",{}):
		for item:Dictionary in decor["biomes"][biome]:
			_add("v23:edge:"+item["id"],BIOME_NAMES[biome]+" · "+str(item["id"]).split(":")[-1]+"（"+{"small":"小","medium":"中","large":"大"}[item["size_class"]]+"）","前前景邊緣裝飾",[_descriptor(ROOT+"v23/"+item["path"],item["source_rect"])],1,"固定原畫尺寸，錨點貼住實際地形邊界，使用保留繪圖快取。")
	var platforms:Dictionary=_json(ROOT+"v23/platform-four-manifest.json")
	for biome:String in platforms.get("biomes",{}):
		var item:Dictionary=platforms["biomes"][biome]
		_add("v23:platform:"+biome+":4",BIOME_NAMES[biome]+" · v21 系四格長跳台","地形連接模組",[_descriptor(ROOT+"v23/"+item["path"],item["source_rect"])],1,"延續v21一至三格根石平台的新四格原畫。原生長圖，沒有重複放大小貼圖。")

static func _v24() -> void:
	var terrain:Dictionary=_json(ROOT+"v24/terrain/terrain-manifest.json")
	for biome:String in terrain.get("biomes",{}):
		var data:Dictionary=terrain["biomes"][biome]
		_add("v24:material:"+biome,BIOME_NAMES[biome]+" · 統一密度地形","實心地形與固定跳台",[_descriptor(ROOT+"v24/terrain/"+data["material"]["path"])],1,"2來源像素／世界像素。所有實心方塊共用世界座標取樣，含1×2窄塊。")
		for count:String in data["platforms"]:
			_add("v24:platform:"+biome+":"+count,BIOME_NAMES[biome]+" · "+count+"格跳台","實心地形與固定跳台",[_descriptor(ROOT+"v24/terrain/"+data["platforms"][count]["path"])],1,"原生四種長度，共用2來源像素／世界像素；自然端帽與中央取樣，不拉伸。")
		for i in data.get("middle",[]).size():
			_add("v24:middle:"+biome+":"+str(i),BIOME_NAMES[biome]+" · 完整中景物件"+str(i+1),"中景完整物件",[_descriptor(ROOT+"v24/terrain/"+data["middle"][i]["path"])],1,"完整輪廓，暗色半透明。共用2來源像素／世界像素。")
	var edges:Dictionary=_json(ROOT+"v24/edges/manifest.json")
	for biome:String in edges.get("biomes",{}):
		for piece:Dictionary in edges["biomes"][biome]:
			_add("v24:edge:"+piece["id"],BIOME_NAMES[biome]+" · "+str(piece["id"]).split(":")[-1],"邊緣裝飾",[_descriptor(ROOT+"v24/edges/"+piece["path"])],1,"共用2來源像素／世界像素，向地形內嵌10px；高於主角者在前景下方。")
	for id:String in preload("res://scripts/arsenal_v24.gd").IDS:
		for role:String in ["weapon","projectile"]:
			_add("v24:"+role+":"+id,id+(" · 武器" if role=="weapon" else " · 投射物"),"附武器" if role=="weapon" else "投射物",[_descriptor(ROOT+"v24/weapons/"+role+"_"+id+".png")],1,"九種武器效果的獨立透明原畫。")

	for id:String in ["sub_velocity","sub_reach","sub_power","sub_volume"]:
		_add("v24:rune:"+id,id,"小符文",[_descriptor(ROOT+"v24/runes/rune_"+id+".png")],1,"附武器彈速、射程、傷害與範圍的四種獨立符文原畫。")
	var corners:Dictionary=_json(ROOT+"v24/terrain/corner-manifest.json")
	for biome:String in corners.get("biomes",{}):
		for kind:String in ["convex","concave"]:
			_add("v24:corner:"+biome+":"+kind,BIOME_NAMES[biome]+" · "+("外凸" if kind=="convex" else "內凹")+"自然轉角","地形連接模組",[_descriptor(ROOT+"v24/terrain/"+corners["biomes"][biome][kind]["path"])],1,"僅真實地形轉角放置，固定2來源像素／世界像素；局部羽化銜接。")
