class_name StationViewV26
extends RefCounted
const Data=preload("res://scripts/game_data.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
const Arsenal=preload("res://scripts/arsenal_v24.gd")
const Stock=preload("res://scripts/station_inventory_v26.gd")
const FILTERS:Array= [["all","全部"],["runes","小符文"],["strong","大符文"],["weapons","附武器"],["items","消耗品"],["resources","金幣"]]
static var gray:ShaderMaterial
static func grayscale() -> ShaderMaterial:
	if gray==null:
		gray=ShaderMaterial.new();var shader:=Shader.new();shader.code="shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV)*COLOR; float g=dot(c.rgb,vec3(0.299,0.587,0.114)); COLOR=vec4(vec3(g)*0.48,c.a);}";gray.shader=shader
	return gray
static func _text(ui,parent:Node,value:String,size:int=14,color:Color=Color("a7bbb0")) -> Label:
	var label:Label=ui._label(value,size,color);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label
static func _begin(ui,title:String,page:String) -> HBoxContainer:
	var sections:Array[Dictionary]=[];ui.show_panel(title,sections);ui.inventory_page="station_v26";ui.station_page=page
	var body:=HBoxContainer.new();body.name="StationBody";body.add_theme_constant_override("separation",22);body.custom_minimum_size.y=440;ui.panel_rows.add_child(body);return body
static func _pane(ui,parent:Node,width:float) -> VBoxContainer:
	var frame:=PanelContainer.new();frame.custom_minimum_size.x=width;frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.size_flags_stretch_ratio=width;frame.add_theme_stylebox_override("panel",ui._box(Color("0d2423"),Color("35574d"),14,14));parent.add_child(frame)
	var column:VBoxContainer=ui._column(frame);column.add_theme_constant_override("separation",8);return column
static func _button(ui,parent:Node,label:String,action:String,payload:Variant,key:String) -> Button:
	var button:Button=ui._button(label,action,payload);button.set_meta("station_key",key);button.custom_minimum_size.y=38;parent.add_child(button);return button
static func _tile(ui,parent:Node,title:String,icon:String,caption:String,action:String,payload:Variant,key:String,locked:bool=false) -> Button:
	var button:Button=_button(ui,parent,"",action,payload,key);button.custom_minimum_size=Vector2(87,96);button.tooltip_text=title+"\n"+caption
	var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);column.offset_left=4;column.offset_right=-4;column.offset_top=5;column.offset_bottom=-4;column.add_theme_constant_override("separation",1);button.add_child(column)
	var image:TextureRect=ui._icon(icon,49);image.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if locked:image.material=grayscale()
	column.add_child(image)
	var name:Label=_text(ui,column,title,11,ui.INK);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var count:Label=_text(ui,column,caption,10,ui.MUTED);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	return button
static func _grid(ui,parent:Node,height:float=330) -> GridContainer:
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(0,height);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll)
	var grid:=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",7);grid.add_theme_constant_override("v_separation",7);scroll.add_child(grid);return grid
static func _hero(ui,parent:Node) -> Dictionary:
	var art_row:=HBoxContainer.new();art_row.add_theme_constant_override("separation",12);parent.add_child(art_row)
	var image:TextureRect=ui._icon("",160);image.custom_minimum_size=Vector2(128,160);image.size_flags_horizontal=Control.SIZE_EXPAND_FILL;image.name="StationHeroArt";art_row.add_child(image)
	var animation:Control=preload("res://scripts/weapon_preview_v27.gd").new();animation.name="WeaponFiringPreview";animation.visible=false;art_row.add_child(animation)
	var title:Label=_text(ui,parent,"",23,ui.GOLD);title.name="StationHeroName"
	var desc:Label=_text(ui,parent,"",15,ui.INK);desc.name="StationHeroDescription"
	var requirements:Label=_text(ui,parent,"",14,ui.MINT);requirements.name="StationRequirements"
	return {"image":image,"animation":animation,"title":title,"description":desc,"requirements":requirements}
static func forge(ui,data:Dictionary) -> void:
	var body:HBoxContainer=_begin(ui,"藍圖鍛造台  /  羽火工坊","forge")
	var left:VBoxContainer=_pane(ui,body,315);var right:VBoxContainer=_pane(ui,body,590)
	_text(ui,left,"附武器藍圖",20,ui.MINT);_text(ui,left,"灰色代表尚未取得，仍可選擇預覽。",12)
	var grid:GridContainer=_grid(ui,left,330);grid.name="BlueprintGrid"
	var hero:Dictionary=_hero(ui,right)
	var craft:Button=_button(ui,right,"合成","","","forge:craft")
	for id:String in Arsenal.IDS:
		var def:Dictionary=Data.SECONDARY[Arsenal.index_of(id)];var known:bool=data["blueprints"].has(id)
		var tile:Button=_tile(ui,grid,def["name"],"secondary_"+id,"已解鎖" if known else "未解鎖","station_noop",null,"forge:"+id,not known)
		var preview:Callable=func()->void:
			ui.station_selection=id;hero["animation"].set_weapon(id);hero["image"].texture=Icons.texture("secondary_"+id);hero["image"].material=null if known else grayscale();hero["title"].text=def["name"];hero["description"].text=def["description"]
			var capped:bool=data["mode"]=="musou" and data["weapons"].size()>=16
			if data["mode"]=="rogue":capped=data["weapons"].any(func(held:Dictionary)->bool:return held.get("id","")==id and int(held.get("duplicate_bonus",0))>=8)
			hero["requirements"].text="合成需求\n%s\n金幣 %d / %d（隨身 %d ＋ 家中 %d）\n%s"%["藍圖：已解鎖" if known else "藍圖：未解鎖，冒險中取得此武器即可解鎖",int(data["coins"])+int(data["bank"]),Arsenal.CRAFT_COST,int(data["coins"]),int(data["bank"]),"已達持有／強化上限" if capped else "無雙夢境最多16把；Roguelike重複合成增加投射物，最多+8。"]
			craft.disabled=not known or capped or int(data["coins"])+int(data["bank"])<Arsenal.CRAFT_COST;craft.text="合成 · %d 金幣"%Arsenal.CRAFT_COST
			craft.set_meta("craft_id",id)
		tile.focus_entered.connect(preview);tile.mouse_entered.connect(preview);tile.pressed.connect(preview)
		if id==ui.station_selection:preview.call()
	craft.pressed.connect(func()->void:ui._dispatch("craft_weapon",str(craft.get_meta("craft_id",""))))
	_text(ui,right,"取得一次，藍圖永久保存。金幣優先由隨身扣除。",12)
	if not Arsenal.IDS.has(ui.station_selection):ui.station_selection=Arsenal.IDS[0];(grid.get_child(0) as Button).focus_entered.emit()
	_result_card(ui,data.get("result",{}),"鍛造完成")
	ui.call_deferred("focus_first")
static func reforge(ui,data:Dictionary) -> void:
	var body:HBoxContainer=_begin(ui,"符文重鑄台  /  三印歸一","reforge")
	var left:VBoxContainer=_pane(ui,body,600);var right:VBoxContainer=_pane(ui,body,305)
	_text(ui,left,"以三枚舊印，換一枚未知的新印",22,ui.GOLD)
	_text(ui,left,"從右側選擇任意小符文或大符文，填入三個凹槽。點擊槽內符文可退回。",15,ui.INK)
	var slots:=HBoxContainer.new();slots.name="ReforgeSockets";slots.alignment=BoxContainer.ALIGNMENT_CENTER;slots.add_theme_constant_override("separation",16);left.add_child(slots)
	for i in 3:
		var id:String=data["selection"][i] if i<data["selection"].size() else ""
		var button:Button=preload("res://scripts/station_socket_v26.gd").new();button.name="ReforgeSocket"+str(i);button.custom_minimum_size=Vector2(140,142);button.set_meta("station_key","reforge:slot:"+str(i));button.focus_mode=Control.FOCUS_ALL;button.add_theme_stylebox_override("normal",ui._box(Color("102623"),ui.LINE,12,4));button.add_theme_stylebox_override("focus",ui._box(Color.TRANSPARENT,ui.GOLD,12,4));slots.add_child(button)
		var col:=VBoxContainer.new();col.mouse_filter=Control.MOUSE_FILTER_IGNORE;col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);col.offset_top=23;col.offset_left=8;col.offset_right=-8;col.add_theme_constant_override("separation",12);button.add_child(col)
		var image:TextureRect=ui._icon(Icons.rune(id) if not id.is_empty() else "",66);image.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_child(image)
		var name:Label=_text(ui,col,_rune_name(id) if not id.is_empty() else "空槽 %d"%(i+1),13,ui.MINT);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(func()->void:ui._dispatch("reforge_remove",i))
	var line:Label=_text(ui,left,"材料 %d / 3"%data["selection"].size(),18,ui.MINT);line.name="ReforgeProgress"
	var confirm:Button=_button(ui,left,"合成 · 3 → 1","reforge_confirm",null,"reforge:confirm");confirm.disabled=data["selection"].size()!=3
	_button(ui,left,"清空材料","reforge_clear",null,"reforge:clear")
	_text(ui,left,"合成說明：消耗3枚，隨機獲得1枚與材料不同的符文，小／大符文皆可能出現，不需金幣。優先使用未裝備的隨身符文，再用家中庫存；必要時才卸下已裝備材料。新符文放入行囊，有空槽時自動裝備。",13)

	_text(ui,right,"可用符文",20,ui.MINT);_text(ui,right,"隨身 ＋ 家中；括號為已裝備數量。",11)
	var grid:GridContainer=_grid(ui,right,330);grid.name="ReforgeRuneGrid"
	for def:Dictionary in Data.all_runes():
		var id:String=def["id"];var total:int=Stock.available(id,data["bag"],data["vault"]);var available:int=total-data["selection"].count(id)
		if total<=0:continue
		var tile:Button=_tile(ui,grid,def["name"],Icons.rune(id),"剩%d（裝%d）"%[available,Stock.equipped(id,data["slots"],data["strong_slots"])],"reforge_add",id,"reforge:rune:"+id);tile.disabled=available<=0 or data["selection"].size()>=3;tile.tooltip_text=str(def["description"])+"\n隨身%d · 家中%d"%[int(data["bag"].get(id,0)),int(data["vault"]["runes"].get(id,0))]
	if grid.get_child_count()==0:_text(ui,right,"目前沒有符文。冒險取得或從倉庫保存後即可重鑄。",14)
	var result:Dictionary={}
	if not str(data.get("result","")).is_empty():
		for def:Dictionary in Data.all_runes():
			if def["id"]==str(data.get("result_id","")):result=def.duplicate(true);result["icon"]=Icons.rune(def["id"])
	_result_card(ui,result,"重鑄完成")
	ui.call_deferred("focus_first")
static func _rune_name(id:String) -> String:
	for def:Dictionary in Data.all_runes():
		if def["id"]==id:return def["name"]
	return id
static func warehouse(ui,data:Dictionary) -> void:
	var body:HBoxContainer=_begin(ui,"倉庫  /  歸巢收藏","warehouse")
	var left:VBoxContainer=_pane(ui,body,600);var right:VBoxContainer=_pane(ui,body,305)
	var hero:Dictionary=_hero(ui,left)
	var take:Button=_button(ui,left,"取出一件","",{},"warehouse:take")
	var deposit:Button=_button(ui,left,"一鍵儲存未使用符文 · %d 枚"%int(data["unused"]),"warehouse_store_unused",null,"warehouse:store_unused");deposit.disabled=int(data["unused"])<=0
	var bar:=HBoxContainer.new();bar.add_theme_constant_override("separation",8);left.add_child(bar)
	for entry:Array in [["存入金幣","coins"],["存入全部附武器","weapons"],["存入全部消耗品","items"]]:_button(ui,bar,entry[0],"parcel",entry[1],"warehouse:deposit:"+str(entry[1]))
	_text(ui,left,"家中庫存永久保存。取出放入行囊；一鍵儲存只移動未裝備的符文，使用中的符文會保留。附武器取出仍遵循無雙夢境16把與重複強化+8上限。",12)
	_text(ui,right,"家中物品",20,ui.MINT)
	var filters:=GridContainer.new();filters.name="WarehouseFilters";filters.columns=3;filters.add_theme_constant_override("h_separation",5);filters.add_theme_constant_override("v_separation",5);right.add_child(filters)
	for entry:Array in FILTERS:
		var button:Button=_button(ui,filters,str(entry[1]),"warehouse_filter",str(entry[0]),"warehouse:filter:"+str(entry[0]));button.add_theme_font_size_override("font_size",12);button.custom_minimum_size.x=87
		if entry[0]==data["filter"]:button.add_theme_stylebox_override("normal",ui._box(Color("36574b"),ui.GOLD,9,8))
	var grid:GridContainer=_grid(ui,right,290);grid.name="WarehouseGrid"
	var entries:Array[Dictionary]=Stock.entries(data["vault"]).filter(func(entry:Dictionary)->bool:return data["filter"]=="all" or entry["category"]==data["filter"])
	var selected:Dictionary={}
	for entry:Dictionary in entries:
		if entry["key"]==ui.station_selection:selected=entry
	if selected.is_empty() and not entries.is_empty():selected=entries[0]
	var preview:Callable=func(entry:Dictionary)->void:
		ui.station_selection=entry["key"];hero["animation"].set_weapon(str(data["vault"]["weapons"][int(entry["payload"])].get("id","")) if entry["kind"]=="weapon" else "");hero["image"].texture=Icons.texture(entry["icon"]);hero["title"].text=entry["name"];hero["description"].text=entry["description"];hero["requirements"].text="家中庫存 ×%d"%int(entry["count"]);take.disabled=int(entry["count"])<=0;take.text="取出全部金幣" if entry["kind"]=="coins" else "取出一件";take.set_meta("stock_entry",entry)
	for entry:Dictionary in entries:
		var tile:Button=_tile(ui,grid,entry["name"],entry["icon"],"×%d"%int(entry["count"]),"station_noop",null,"warehouse:"+str(entry["key"]));tile.focus_entered.connect(preview.bind(entry));tile.mouse_entered.connect(preview.bind(entry));tile.pressed.connect(preview.bind(entry))
	take.pressed.connect(func()->void:ui._dispatch("warehouse_take",take.get_meta("stock_entry",{})))
	if selected.is_empty():
		hero["title"].text="此分類沒有物品";hero["description"].text="將冒險取得的物品存入倉庫，即可在這裡查看。";hero["requirements"].text="";take.disabled=true
	else:preview.call(selected)
	ui.call_deferred("focus_first")

static func _result_card(ui,result:Dictionary,heading:String) -> void:
	if result.is_empty():return
	var frame:=PanelContainer.new();frame.name="CraftResultCard";frame.add_theme_stylebox_override("panel",ui._box(Color("20392b"),ui.GOLD,12,8));ui.panel_rows.add_child(frame)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);frame.add_child(row)
	var image:TextureRect=ui._icon(str(result.get("icon","secondary_"+str(result.get("id","")))),64);image.name="CraftResultArt";row.add_child(image)
	var col:=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(col)
	_text(ui,col,heading+" · "+str(result.get("name","")),18,ui.GOLD)
	_text(ui,col,str(result.get("description",result.get("desc","")))+(" · 強化 +%d / 8"%int(result["duplicate_bonus"]) if result.has("duplicate_bonus") else ""),13,ui.INK)
