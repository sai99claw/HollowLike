class_name ArtCatalogV16
extends RefCounted
## RD asset metadata is cheap. Texture decoding happens only for selected frames.
## No call into the gameplay art helpers' unbounded texture caches is needed.
const Tags=preload("res://scripts/art_tags_v73.gd")
const Slash=preload("res://scripts/slash_art_v18.gd")
const GROUPS:Array[String]=["主角","小怪","Boss","地圖","物件","NPC","戰鬥共用"]
const IDLE_MOTION=preload("res://scripts/pigeon_idle_v19.gd")
const WALK_MOTION=preload("res://scripts/walk_animation.gd")
const ACTOR_MOTION=preload("res://scripts/adventure_visual.gd")
const WALL_MOTION=preload("res://scripts/pigeon_motion_v22.gd")
const WIND_MOTION=preload("res://scripts/wind_art.gd")
const CACHE_LIMIT:int=24
const ROOT:String="res://assets/"
const BIOME_NAMES:Dictionary={"sky":"天空","trunk":"樹幹","underground":"地底","canopy":"樹梢（舊區）","branches":"樹枝（舊區）","grass":"草地（舊區）"}
const OBJECT_NAMES:Dictionary={"sky":["藍風草","白絨雲花","青晶蘆","藍羽薊","藍釉天甕","浮空浮石"],"trunk":["翡翠蕨","三葉幼苗","樹皮層菇","苔種莢","捲藤芽","橡果燈"],"underground":["琥珀晶簇","象牙洞菇","捲根叢","赤陶甕","發光根球","頁岩石堆"]}
const HOME_SLEEP:Array[Array]=[[43,339,500,238],[543,301,531,274],[1122,132,495,458],[1657,178,477,406]]
const ACTION_REGIONS=ACTOR_MOTION.ACTION_REGIONS
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
	_recent_art()
	_remaining_images(ROOT)
	var audit:Dictionary=_json(ROOT+("v24/asset-audit.json" if FileAccess.file_exists(ROOT+"v24/asset-audit.json") else "v23/asset-audit.json" if FileAccess.file_exists(ROOT+"v23/asset-audit.json") else "v22/asset-audit.json")).get("entries",{})
	for item:Dictionary in _entries:
		item["group"]=_group_for(item)
		item.merge(audit.get(item["id"],{}))
		var usage:Dictionary=_current_usage(item)
		item.merge(usage,true)
		var context:String=str(item.get("notes","")).get_slice("。",0)
		if not item.has("runtime_usage"):item["runtime_usage"]="un-used"
		if not item.has("usage_note"):
			item["usage_note"]=str(item["label"])+" · "+(context+"。" if not context.is_empty() else "")+"素材庫原圖，未查到遊戲呼叫。"
		item["tags"]=Tags.for_asset(item)
	_entries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return str(a["category"])+str(a["label"])<str(b["category"])+str(b["label"]))
	return _entries

static func entry(id:String) -> Dictionary:
	all_entries();return _by_id.get(id,{})

static func _art_v37() -> void:
	var data:Dictionary=_json(ROOT+"v37/effects/feather-crescent.json")
	var feathers:Array=[]
	var source_frames:Array=data.get("animations",{}).get("feathers",[])
	for i in mini(source_frames.size(),2):
		feathers.append(_descriptor(ROOT+"v37/effects/"+data["path"],source_frames[i]["source_rect"]))
	_add("v37:feathers","命中碎羽","戰鬥特效",feathers,16,"兩張命中碎羽，每幀 1/16 秒。")
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
	var d:Dictionary
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
static func categories(group:String="") -> Array[String]:
	var result:Array[String]=[]
	for item:Dictionary in all_entries():
		if (group.is_empty() or item["group"]==group) and not result.has(item["category"]):result.append(item["category"])
	return result
static func search(query:String="",category:String="",kind:String="all",group:String="") -> Array[Dictionary]:
	var result:Array[Dictionary]=[];var terms:PackedStringArray=_search_text(query).split(" ",false)
	for item:Dictionary in all_entries():
		if not group.is_empty() and item["group"]!=group:continue
		if not category.is_empty() and item["category"]!=category:continue
		if kind=="animated" and int(item["frame_count"])<=1:continue
		if kind=="still" and int(item["frame_count"])!=1:continue
		var text:String=_search_text(str(item["id"])+" "+str(item["label"])+" "+str(item.get("notes",""))+" "+str(item["category"])+" "+str(item.get("runtime_usage",""))+" "+str(item.get("usage_note",""))+" "+str(item["group"])+" "+" ".join(item["tags"]))
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
		if library=="walk_v2" and id=="pigeon_walk_master":
			extra["sequence"]=WALK_MOTION.WALK_SEQUENCE
			extra["phases"]={"原始圖集":range(frames.size())}
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
	_sheet("wind:form","雙C · 化身為風","衝刺與爆炸特效",ROOT+"v75/wind-form.webp",4,2,8,WIND_MOTION.FORM_FPS,{"hidden_frames":[2,4]})
	_sheet("wind:impact","下衝 · 接地衝擊","衝刺與爆炸特效",ROOT+"v76/wind-impact.webp",2,2,4,8,{"baseline":1.0})
	_sheet("merchant:owl","貓頭鷹商人 · 待機","角色與NPC",ROOT+"adventure_v08/owl_merchant.png",2,2,4,1.5)
	for row in ACTION_REGIONS.size():
		var frames:Array=[]
		for region_data:Array in ACTION_REGIONS[row]:frames.append(_descriptor(ROOT+"adventure_v08/pigeon_actions.png",region_data))
		if row==1:
			_add("pigeon_action:1:legacy","鴿子 · 舊四格跛行","主角姿態",frames,5)
			continue
		var extra:Dictionary={}
		if row==2:extra={"phases":{"橫向穿刺":[1]},"hidden_frames":[0,2,3]}
		if row==3:extra={"sequence":ACTOR_MOTION.SLAM_FRAMES+[3],"phases":{"下衝":ACTOR_MOTION.SLAM_FRAMES,"落地":[3]}}
		_add("pigeon_action:"+str(row),["鴿子 · 回血","","鴿子 · 橫向雙C","鴿子 · 下衝與落地"][row],"主角姿態",frames,5 if row==0 else ACTOR_MOTION.SLAM_FPS,"",extra)
	var sleeping:Array=[]
	for region_data:Array in HOME_SLEEP:sleeping.append(_descriptor(ROOT+"home_v13/sleep.png",region_data))
	_add("home:sleep","鳥巢 · 睡眠與起身","主角姿態",sleeping,6)
	for id:String in ["background","musou","rogue","nest"]:
		_add("home:"+id,"鳥巢 · "+{"background":"樹梢背景","musou":"無雙夢境大門","rogue":"冒險大門","nest":"鳥巢"}[id],"首頁與大門",[_descriptor(ROOT+"v33/home/background.png") if id=="background" else _descriptor(ROOT+"v33/home/props.png",[],[2,2],[0 if id=="musou" else 1,0]) if id in ["musou","rogue"] else _descriptor(ROOT+"v34/home/nest.png")],1)
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
		if directory.contains("/projectiles/"):category="投射物"
		elif directory.contains("/bosses/"):category="首領圖集"
		elif directory.contains("/monsters/"):category="小怪圖集"
		elif directory.contains("/midground/") or directory.contains("ecology") or original.contains("background"):category="地形與背景"
		elif directory.contains("/cloaks/") or directory.contains("/player/") or original.begins_with("pigeon"):category="主角姿態"
		elif directory.contains("explosion") or directory.contains("motion") or directory.contains("/effects/"):category="特效原圖"
		elif directory.contains("/stations/") or directory.contains("/chests/"):category="場景互動物件"
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
	_sheet("slash:v18","普攻 · 白色羽刃月牙","攻擊與命中特效",ROOT+"v18/slash-smear.png",4,2,Slash.FRAME_COUNT,Slash.FPS,{"sequence":Slash.SEQUENCE,"hidden_frames":[3,5,6,7],"phases":{"active":Slash.SEQUENCE}})
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
		var idle:bool=id=="idle"
		var sequence:Array=IDLE_MOTION.IDLE_SEQUENCE if idle else IDLE_MOTION.REST_SEQUENCE
		_add("idle:v19:"+id,"鴿子 · "+("待機呼吸" if idle else "趴地休息"),"主角姿態",frames,IDLE_MOTION.IDLE_FPS if idle else IDLE_MOTION.REST_FPS,
			"閒置五秒開始趴地，移動時立即起身。",{"sequence":sequence,"hidden_frames":[3,7] if idle else [0],"phases":{"原始圖集":range(frames.size())}})

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
			var extra:Dictionary={}
			if library=="pigeon-motion" and id=="wall":
				extra={"sequence":WALL_MOTION.WALL_SLIDE_FRAMES,"phases":{"貼牆靜止":[0],"貼牆下滑":WALL_MOTION.WALL_SLIDE_FRAMES,"原始四格":[0,1,2,3]}}
			_add("v23:"+library+":"+id,label,"主角姿態" if library=="pigeon-motion" else "彈射互動物件",frames,8,"固定比例，使用實際接觸點。",extra)
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

static func _group_for(item:Dictionary) -> String:
	var id:String=item["id"]
	var category:String=item["category"]
	var path:String=item["frames"][0].get("path","")
	if category in ["首領圖集","Boss動作與特效"] or path.begins_with(ROOT+"v59/monsters/") or path.begins_with(ROOT+"v59/effects/") or id.begins_with("v22:boss-actions:") or id in ["v22:death:underground","v22:death:trunk","v22:death:sky"]:return "Boss"
	if id.begins_with("monster_projectile:") or category.begins_with("怪物") or category in ["小怪動作","小怪圖集","高解析怪物動作","死亡與屍體","陷阱安置動畫","環境生物"]:return "小怪"
	if id in ["v72:straight_slash","v72:impact_feathers"]:return "戰鬥共用"
	if id in ["slash:v18","v72:wing_impulse"] or (category in ["主角","主角姿態","衝刺與爆炸特效"] and not id.begins_with("explosion:")):return "主角"
	if category=="角色與NPC":return "NPC"
	if id.begins_with("v24:projectile:") or id.begins_with("v24:weapon:") or id.begins_with("v31:") or id=="v38:laser" or path.contains("/v31/projectiles/"):return "主角"
	if category.contains("地形") or category.contains("中景") or category.contains("裝飾") or category=="首頁與大門" or path.contains("/maps/") or id.begins_with("procedural:door_"):return "地圖"
	return "物件"

static func _recent_art() -> void:
	for biome:String in ["underground","trunk","sky"]:
		_gothic_prop_atlas(biome+"-props",["金幣甕","彈跳菇","能量花","生命花","寶箱","岩石"])
		_gothic_prop_atlas(biome+"-flora",["植被一","植被二","植被三","植被四","植被五","植被六"])
	_gothic_prop_atlas("stations",["鍛造","重鑄","披風","急救","倉庫","武器展台"])
	_gothic_prop_atlas("facilities",["泉水","試打假人","投影燈","商人展台","冒險紀錄","戰利品櫃"])
	for icon:Array in [["heart-empty","血量空格"],["heart-full","血量滿格"],["shield-empty","護盾空格"],["shield-full","護盾滿格"]]:
		_add("v80:"+icon[0],icon[1],"介面",[_descriptor(ROOT+"v80/"+icon[0]+".webp")],1,"左上資源格使用的圖標，畫布 64 × 64 px。")
	_add("v79:energy-feather-empty","羽毛能量 · 空格","介面",[_descriptor(ROOT+"v79/energy-feather-empty.webp")],1)
	_add("v79:energy-feather-full","羽毛能量 · 滿格","介面",[_descriptor(ROOT+"v79/energy-feather-full.webp")],1)
	_add("v75:canopy-left","血量列 · 垂枝底圖","介面",[_descriptor(ROOT+"v75/canopy-left.webp")],1)
	for art:Array in [["near-roots","垂根"],["near-vine","垂藤"],["near-stone","角石"],["near-thorns","荊枝"]]:
		_add("v76:"+str(art[0]),"樹幹 · "+str(art[1]),"地形與背景",[_descriptor(ROOT+"v76/"+str(art[0])+".webp")],1)
		for biome:String in ["underground","sky"]:
			var id:String=biome+"-"+str(art[0])
			_add("v77:"+id,BIOME_NAMES[biome]+" · "+str(art[1]),"地形與背景",[_descriptor(ROOT+"v77/"+id+".webp")],1)
	for art:Array in [["root-cluster","盤根草叢"],["thorn-branch","荊刺枝葉"]]:
		var category:String="前景"
		_add("v75:"+str(art[0]),category+" · "+str(art[1]),"地形與背景",[_descriptor(ROOT+"v75/"+str(art[0])+".webp")],1)

	_sheet("v72:wing_impulse","單 C／二段跳 · 拍翅噴流","動作與特效",ROOT+"v76/wing-impulse.webp",2,2,4,4.0/.24)
	_sheet("v72:impact_feathers","命中 · 身體向外噴出碎羽","攻擊與命中特效",ROOT+"v75/impact-feathers.webp",2,2,4,20)
	_sheet("v72:straight_slash","命中 · 直線閃光","攻擊與命中特效",ROOT+"v75/straight-slash.webp",2,2,4,24)
	var motion:String=ROOT+"v68/pigeon_motion.webp"
	_sheet("v68:pigeon:jump_rise","鴿子 · 起跳上升","主角姿態",motion,4,3,4,ACTOR_MOTION.JUMP_FPS,
		{"sequence":ACTOR_MOTION.JUMP_SEQUENCE,"hidden_frames":[0,3],"phases":{"原始圖集":[0,1,2,3]}})
	var old_limp:Array=[]
	for i in 8:old_limp.append(_descriptor(motion,[],[4,3],[i%4,1+i/4]))
	_add("pigeon_action:1:v68","鴿子 · 舊八格跛行","主角姿態",old_limp,8)
	_sheet("pigeon_action:1","鴿子 · 重傷跛行","主角姿態",ROOT+"v70/pigeon_limp.webp",5,2,10,8)
	for row:int in 4:
		var labels:Array=["右翅由右往左","左翅由左往右","右翅上揮","右腳向後抓踢"]
		var frames:Array=[]
		for col:int in 2:frames.append(_descriptor(ROOT+"v70/pigeon_attack.webp",[],[2,4],[col,row]))
		_add("v70:pigeon:attack:"+str(row),labels[row],"主角姿態",frames,12,"預備、打擊動態模糊。")
	_add("v70:pigeon:glide","鴿子 · 展翅滑翔","主角姿態",[_descriptor(ROOT+"v70/pigeon_glide.webp")],1)
	for biome:String in ["underground","trunk","sky"]:
		for size_id:String in ["large","small"]:
			var label:String=BIOME_NAMES[biome]+" · "+("大圓石" if size_id=="large" else "小圓石")
			_add("v67:stone:"+biome+":"+size_id,label,"場景互動物件",[_descriptor(ROOT+"v67/stones/"+biome+"_"+size_id+".webp")],1)
		_sheet("v59:chest:"+biome,BIOME_NAMES[biome]+" · 寶箱開啟","場景互動物件",ROOT+"v59/chests/"+biome+".webp",4,2,8,12.5)
	_sheet("v48:pigeon:quickdraw_walk","鴿子 · 蓄氣步行","主角姿態",ROOT+"v48/pigeon_quickdraw_walk.webp",3,2,6,8)

static func _gothic_prop_atlas(id:String,labels:Array) -> void:
	for row in labels.size():
		var frames:Array=[]
		for state in 3:frames.append(_descriptor(ROOT+"v82/"+id+".webp",[],[3,6],[state,row]))
		_add("v82:"+id+":"+str(row),labels[row],"場景互動物件",frames,4,"正常、破損、擊飛碎片。")

static func _current_usage(item:Dictionary) -> Dictionary:
	var id:String=item["id"]
	var label:String=item["label"]
	var path:String=item["frames"][0].get("path","").trim_prefix(ROOT)
	var used:bool=true
	var note:String=""
	match id:
		"v79:energy-feather-empty","v79:energy-feather-full":note="左上普通能量的空格和滿格。畫布 52 × 60 px。"
		"v75:canopy-left":note="左上血量列的垂枝底圖，固定於介面。"
		"v76:near-roots","v76:near-vine","v77:underground-near-roots","v77:underground-near-vine","v77:sky-near-roots","v77:sky-near-vine":note="附著在地形下緣，部分繪在主角前方。"
		"v76:near-stone","v76:near-thorns","v77:underground-near-stone","v77:underground-near-thorns","v77:sky-near-stone","v77:sky-near-thorns":note="平台的角石與荊枝，部分繪在主角前方。"
		"v75:root-cluster","v75:thorn-branch":used=false;note="舊版前景根系與葉片。"
		"pigeon_action:0":note="按住回血時的四張角色姿態。"
		"pigeon_action:1:legacy":used=false;note="舊四幀跛行，已由新十幀步態取代。"
		"pigeon_action:2":note="橫向雙 C 穿刺全程使用第 2 張，其他三張留在 RD。"
		"pigeon_action:3":note="向下雙 C 用第 1、2、3 張接續，第 3 張持續到觸地，第 4 張落地。"
		"v68:pigeon:jump_rise":note="地面起跳上升，只播原第 2、3 張，第 3 張維持至上升結束。"
		"v23:pigeon-motion:wall":note="貼牆靜止用第 1 張；下滑以 8 FPS 播 1→3→4→3→1→3→4→3→1。"
		"v23:pigeon-motion:air":note="牆跳等其他上升、跳躍頂點、下降和普通落地姿勢。"
		"v48:pigeon:quickdraw_walk":note="按住集氣且在地面移動時，按步態切換六張拔刀預備姿勢。"
		"wind:form":note="雙 C 疊在鴿子中心，90% 不透明度；第 3、5 張停用，橫向播一次，垂直循環這六張。"
		"wind:impact":note="向下雙 C 觸地時從羽毛堆向兩側炸出羽毛，共四幀。"
		"wind:jet":used=false;note="舊單 C 噴射；目前採用二段跳式拍翅與風尾。"
		"pigeon_action:1":note="重傷移動時循環十幀，每五幀交替支撐腳。角色造型取自走路第 10 幀。"
		"pigeon_action:1:v68":used=false;note="v0.68 舊八幀跛行，已由十幀步態取代。"
		"v70:pigeon:glide":note="空中長按跳躍鍵或由浮翼符文提供升力時展翅。角色造型取自走路第 10 幀。"
		"idle:v19:idle":note="待機 5 FPS，依指定順序往返播放，第 4、8 張停用。"
		"idle:v19:rest":note="閒置五秒後從第 2 張進入趴地休息。"
		"walk_v2:pigeon_walk_master":note="正常走路依距離播第 7、3、8、9、10 張。"
		"slash:v18":note="主角 A1、A2、上斬、下斬及手動集氣釋放的獨立攻擊特效。跟隨主角，以 20 FPS 播原始第 1、2、3、5 幀。"
		"combat_v05:pigeon_featherblade_up":note="普通上斬的角色動畫，沿用羽毛刀朝上姿勢。"
		"combat_v05:pigeon_featherblade_down":note="普通下斬的角色動畫，沿用羽毛刀朝下姿勢。"
		"combat_v05:pigeon_greatblade_up":used=false;note="舊衝刺上斬姿勢，已由右翅上揮取代。"
		"combat_v05:pigeon_greatblade_down":used=false;note="舊衝刺下斬姿勢，已由右腳抓踢取代。"
		"combat_v05:pigeon_feather_left":note="橫向普攻 A1 的角色動畫。"
		"combat_v05:pigeon_feather_right":note="橫向普攻 A2 的角色動畫。"
		"combat_v05:pigeon_feather_thrust":used=false;note="停用的第三下普攻。"
		"combat_v05:pigeon_great_front","combat_v05:pigeon_great_side":used=false;note="舊單 C 衝刺攻擊姿勢，已換成雙翅輪流攻擊。"
		"combat_v05:pigeon_great_spin":note="手動集氣釋放保留的原大刀迴旋斬。"
		"combat_v05:feather_charge":note="兩種模式按大招鍵後播放的羽刃環斬。"
		"combat_v05:vertical_launch":note="集氣時從雙翅向下向外吹，起飛時朝下噴出的羽毛氣流。"
		"combat_v05:motion_energy":used=false;note="已停用移動回能的光效。"
		"combat_v05:dream_feather_charge":used=false;note="舊版夢境擴散斬圖，已停用。"
		"combat_v05:pigeon_feather_charge":note="無雙夢境滿能量後按大招鍵施放擴散斬；手動集氣釋放使用大刀第三刀。"
		"v37:feathers":used=false;note="舊兩幀命中碎羽，已由 v72 四幀替換。"
		"v72:wing_impulse":note="單 C 朝衝刺反方向噴出；二段跳朝腳下噴出。四幀固定在發力位置。"
		"v72:impact_feathers":note="受擊中心沿攻擊方向噴出碎羽，象牙白與淡紫碎羽由集中至飛散，共四幀。"
		"v72:straight_slash":note="各類攻擊命中時從受擊者中心繪製，沿攻擊方向隨機偏轉，長度為一個畫面寬，24 FPS。"
		"v37:mantle":note="向牆移動且接觸平台上緣時，攀上牆頂的四格動作。"
		"v38:laser":note="雷射副武器與使用連續光束的攻擊；貼圖寬度依命中範圍。"
		"v38:crescent":used=false;note="舊版命中月牙，由 v39 細長月牙取代。"
	if id.begins_with("v70:pigeon:attack:"):used=false;note=label+"；舊版翅膀／腳爪普攻角色動畫。"
	elif id.begins_with("v67:stone:"):note=label+"，隨機生成，主角可穿過，擊飛後可撞傷怪物。"+("六顆小石排成 1／2／3 層，近戰擊中其中一顆會打散整堆。" if id.ends_with(":small") else "")
	elif id.begins_with("v59:chest:"):note=label+"，戰鬥房或獎勵房互動後播放。"
	elif id.begins_with("v36:"):note=label+"，三生態戰鬥房的怪物姿勢或投射物。"
	elif id.begins_with("v39:") and ":death:" in id:note=label+"，敵人血量歸零時的倒地姿勢。"
	if note.is_empty() and id.begins_with("raw:"):
		var file:Dictionary=_raw_usage(path)
		if not file.is_empty():return file
	if not note.is_empty():return {"runtime_usage":"used" if used else "un-used","usage_note":note}
	if item.get("runtime_usage","")=="used":
		var detail:String=str(item.get("notes",""))
		if detail.begins_with("透明圖集"):detail=""
		return {"usage_note":label+" · "+(detail if not detail.is_empty() else str(item.get("usage_note","遊戲內繪製。")))}
	return {}

static func _raw_usage(path:String) -> Dictionary:
	var role:String=""
	var used:bool=true
	if path=="v30/effects/wing-puff.png":
		role="舊拍翅風團，由 v72:wing_impulse 取代。"
		used=false
	elif path.begins_with("v63/monsters/"):
		role="怪物高解析原稿，供切圖與審圖。"
		used=false
	elif path.begins_with("v55/bosses/"):
		role="首領舊圖集；已由 v57 首領與 v59 移動圖取代。"
		used=false
	elif path.begins_with("v57/bosses/"):
		role="各生態首領的出招、移動或倒地貼圖。"
	elif path.begins_with("v59/monsters/"):
		role="樹幹與天空首領移動時使用的高解析重繪。"
	elif path.begins_with("v55/monsters/"):
		role="三生態新增怪物的移動、攻擊與倒地圖集。"
	elif path.begins_with("v51/midground/"):
		role="依房間種子選擇的生態視差中景。"
	elif path.begins_with("v30/cloaks/"):
		role="選用該外觀後，依主角當前姿勢疊在身上的斗篷。"
	elif path.begins_with("v31/projectiles/"):
		role="副武器發射後的飛行、命中或爆炸動畫。"
	elif path.begins_with("v33/safehouses/"):
		role="三生態整備房的背景、供應台或工作站。"
	elif path.begins_with("v33/springs/"):
		role="溫泉房水面與池岸，入水時和角色互動。"
	elif path.begins_with("v54/items_"):
		role="消耗品在背包、快捷欄和掉落物上的圖示。"
	else:
		role={
			"v65/home/projection_bottom.png":"首頁鳥巢投影幕下緣。",
			"v63/home/stations.webp":"鳥巢的投影燈、門框、紀錄與戰利品站。",
			"v62/tutorial/stations.webp":"新手教學的附武器、符文與動作示範站。",
			"v59/effects/release.webp":"首領技能釋放序列。",
			"v59/effects/ring.webp":"首領技能命中的環狀特效。",
			"v57/maps/paper.svg":"章節與全塔地圖面板的紙張底圖。",
			"v47/pigeon_quickdraw.webp":"主角站定蓄氣時的拔刀準備姿勢。",
			"v55/effects/aura.svg":"重傷強化或護盾啟動時的環形特效。",
			"v55/effects/frost.svg":"敵人被凍結時覆在本體上的冰層。",
			"v55/effects/spark.svg":"投射物拖尾與場景火花粒子。",
			"v55/ui/etched_slot.svg":"裝備卡片與鳥巢展示欄的雕紋底框。",
			"v29/effects/refined-feather.png":"死亡地點或取回物品的發光羽毛。",
			"v29/stations/cloak-wardrobe.png":"整備房試穿外觀的衣櫃。",
			"v29/stations/free-weapon-pedestal.png":"免費副武器領取台。",
			"v28/player/heavy-landing.png":"主角從高處跌落時的重落地姿勢。",
			"v27/player/double-jump-flap.png":"二段跳及單 C 短衝時的拍翅姿勢。",
			"v27/fire/ground-flame.png":"火系攻擊留在地面上的火焰。",
		}.get(path,"")
	return {} if role.is_empty() else {"runtime_usage":"used" if used else "un-used","usage_note":role}
