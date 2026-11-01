class_name InventoryView
extends RefCounted
const Data=preload("res://scripts/game_data.gd")
const Links=preload("res://scripts/rune_links.gd")
const LinkCanvas=preload("res://scripts/rune_link_canvas.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
const PURPLE=Color("bc98ed")
const GOLD=Color("ebca83")
static func build(ui,data:Dictionary,page:String) -> void:
	var sections:Array[Dictionary]=[]
	ui.show_panel("行囊  /  羽旅收藏",sections)
	ui.inventory_page=page;ui.inspector.visible=true
	ui.inspect_item("羽旅行囊","左側是目前裝備，右側選擇更換或使用。方向鍵移動焦點，攻擊鍵確認；滑鼠指向也能查看說明。","")
	var tabs:=HBoxContainer.new();tabs.name="InventoryTabs";tabs.add_theme_constant_override("separation",10);ui.panel_rows.add_child(tabs)
	for entry in [["武器與補給","bag"],["符文刻印","runes"]]:
		var button:Button=ui._button(entry[0],entry[1],null);button.name="InventoryTab_"+str(entry[1]);button.custom_minimum_size=Vector2(210,32)
		if (page=="weapons")== (entry[1]=="bag"):button.add_theme_stylebox_override("normal",ui._box(Color("36574b"),GOLD,10,7))
		ui.bind_description(button,entry[0],"切換背包頁面，冒險會在關閉後繼續。","");tabs.add_child(button)
	var body:=HBoxContainer.new();body.name="InventoryColumns";body.add_theme_constant_override("separation",22);ui.panel_rows.add_child(body)
	var left:VBoxContainer=ui._column(body,418);left.name="EquippedColumn";left.add_theme_constant_override("separation",4)
	var right:VBoxContainer=ui._column(body,440);right.name="AvailableColumn";right.add_theme_constant_override("separation",4)
	if page=="runes":_runes(ui,data,left,right)
	else:_weapons(ui,data,left,right)
	ui.call_deferred("focus_first")
static func _list(ui,parent:Node) -> VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.name="AvailableItemsScroll";scroll.custom_minimum_size=Vector2(0,340);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);scroll.add_child(list);return list
static func _tile(ui,parent:Node,title:String,description:String,icon:String,action:String="inspect",payload:Variant=null,color:Color=PURPLE,selected:bool=false) -> Button:
	var button:Button=ui._button("",action,payload);button.custom_minimum_size=Vector2(0,70);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.set_meta("inventory_focus",action+"|"+str(payload));button.tooltip_text=description
	button.add_theme_stylebox_override("normal",ui._box(Color("28483e") if selected else Color("1c3431"),color if selected else color.darkened(.65),11,9))
	var row:=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);row.offset_left=10;row.offset_top=7;row.offset_right=-10;row.offset_bottom=-7;row.add_theme_constant_override("separation",12);button.add_child(row)
	var art:TextureRect=ui._icon(icon,50);art.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(art)
	var words:=VBoxContainer.new();words.mouse_filter=Control.MOUSE_FILTER_IGNORE;words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
	var caption:Label=ui._label(title,15,color);caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;words.add_child(caption)
	var hint:Label=ui._label("使用中" if selected else {"sub_select":"裝備副武器","use_item":"使用一次","stash_item":"從家中取用一次","stash_weapon":"從家中取出並裝備","rune_equip":"裝入選定空槽","rune_take":"取出一枚並裝入","primary_inventory":"更換主武器"}.get(action,"選中查看說明"),11,ui.MUTED);words.add_child(hint)
	ui.bind_description(button,title,description,icon);parent.add_child(button);return button
static func _weapons(ui,data:Dictionary,left:VBoxContainer,right:VBoxContainer) -> void:
	left.add_child(ui._label("目前裝備",18,ui.INK))
	var primary:Dictionary=data.get("primary",Data.PRIMARY[0])
	_tile(ui,left,"主武器 · "+str(primary["name"]),str(primary["description"]),Icons.primary(primary),"inspect",null,primary["color"],true)
	var weapons:Array=data.get("weapons",[]);var selected:int=int(data.get("selected",0))
	left.add_child(ui._label("副武器  ·  "+str(data.get("cycle_key","Q"))+" 切換",16,ui.MINT))
	if not weapons.is_empty() and selected>=0 and selected<weapons.size():
		var weapon:Dictionary=weapons[selected];_tile(ui,left,str(weapon["name"]),weapon_description(weapon),Icons.secondary(weapon),"inspect",null,weapon.get("color",PURPLE),true)
	else:left.add_child(ui._label("尚未裝備副武器",14,ui.MUTED))
	left.add_child(ui._label("補給快捷鍵 Shift+1–9",15,ui.MINT))
	var items:Dictionary=data.get("items",{});var supply:=HFlowContainer.new();supply.add_theme_constant_override("h_separation",6);left.add_child(supply)
	for key in items:
		if int(items[key])<=0:continue
		var item:Dictionary=Data.ITEMS[int(key)];var b:Button=ui._button("%d ×%d"%[int(key)+1,int(items[key])],"use_item",int(key));b.icon=Icons.texture("items_"+str(item["id"]));b.expand_icon=true;b.add_theme_constant_override("icon_max_width",28);b.custom_minimum_size=Vector2(116,42)
		ui.bind_description(b,item["name"],item["desc"],"items_"+str(item["id"]));supply.add_child(b)
	if data.get("mode","")=="musou":
		left.add_child(ui._label("無雙成長",15,GOLD));var growth:=HFlowContainer.new();growth.name="GrowthArt";left.add_child(growth)
		for id in Icons.held_growth(str(data.get("upgrades",""))):growth.add_child(ui._icon("growth_"+id,32))
	right.add_child(ui._label("可更換／使用  ·  家中收藏" if data.get("in_start",false) else "可更換／使用",18,ui.INK))
	var list:VBoxContainer=_list(ui,right)
	if data.get("in_start",false):
		list.add_child(ui._label("主武器",13,GOLD))
		for i in [1]:
			var weapon:Dictionary=Data.PRIMARY[i];_tile(ui,list,str(weapon["name"]),str(weapon["description"]),Icons.primary(weapon),"primary_inventory",i,weapon["color"],i==int(data.get("primary_index",0)))
	list.add_child(ui._label("隨身副武器",13,ui.MINT))
	for i in weapons.size():
		var weapon:Dictionary=weapons[i];_tile(ui,list,str(weapon["name"]),weapon_description(weapon),Icons.secondary(weapon),"sub_select",i,weapon.get("color",PURPLE),i==selected)
	for key in items:
		if int(items[key])<=0:continue
		var item:Dictionary=Data.ITEMS[int(key)];_tile(ui,list,str(item["name"])+" ×%d"%int(items[key]),str(item["desc"]),"items_"+str(item["id"]),"use_item",int(key),item["color"])
	if data.get("in_start",false):
		list.add_child(ui._label("家中儲藏  ·  可直接取用",14,GOLD))
		var home:Array=data.get("stash_weapons",[])
		for i in home.size():_tile(ui,list,str(home[i]["name"]),weapon_description(home[i]),Icons.secondary(home[i]),"stash_weapon",i,GOLD)
		var stored:Dictionary=data.get("stash_items",{})
		for key in stored:
			if int(stored[key])<=0:continue
			var item:Dictionary=Data.ITEMS[int(key)];_tile(ui,list,str(item["name"])+" · 家中×%d"%int(stored[key]),str(item["desc"])+"\n取出一份後立即使用。","items_"+str(item["id"]),"stash_item",int(key),GOLD)
	if list.get_child_count()<=1:list.add_child(ui._label("探索時拾取武器與補給。",14,ui.MUTED))
static func _runes(ui,data:Dictionary,left:VBoxContainer,right:VBoxContainer) -> void:
	var slots:Array=data.get("slots",[]);var strong_slots:Array=data.get("strong_slots",[]);var definitions:Array=data.get("defs",Data.all_runes())
	var auto_button:Button=ui._button("隨機自動裝配符文","rune_random",null);auto_button.name="RandomRuneLoadout";auto_button.custom_minimum_size=Vector2(0,34);auto_button.set_meta("equipment_zone","rune_auto");auto_button.set_meta("equipment_key","rune_auto");left.add_child(auto_button)
	ui.bind_description(auto_button,"隨機自動裝配符文","從可用符文隨機裝入最多16枚小符文與3枚不同大符文。安全屋可取用家中收藏；不消耗符文。","")
	left.add_child(ui._label("大符文  %d / 3"%strong_slots.size(),17,GOLD))
	var strong:=HBoxContainer.new();strong.name="StrongRuneBoard";strong.alignment=BoxContainer.ALIGNMENT_CENTER;strong.add_theme_constant_override("separation",12);left.add_child(strong)
	for i in 3:
		var id:String=str(strong_slots[i]) if i<strong_slots.size() else "";var definition:Dictionary=_definition(id,definitions)
		var button:Button=ui._button("", "strong_remove" if not id.is_empty() else "inspect",i);button.custom_minimum_size=Vector2(106,64);button.name="StrongRuneSlot%d"%i
		button.add_theme_stylebox_override("normal",ui._box(Color("3a3327"),GOLD,20,5));_slot_art(ui,button,definition,true,i)
		ui.bind_description(button,definition.get("name","大符文空槽"),definition.get("desc","可裝入一顆大型金色符文，最多三顆。"),Icons.rune(id,true));strong.add_child(button)
	left.add_child(ui._label("小符文  %d / 16"%Links.occupied(slots),17,PURPLE))
	var connector:=LinkCanvas.new();connector.name="RuneConnections";connector.custom_minimum_size=Vector2(212,200);connector.slots=slots;left.add_child(connector)
	var board:=GridContainer.new();board.name="RuneBoard";board.columns=4;board.add_theme_constant_override("h_separation",9);board.add_theme_constant_override("v_separation",7);connector.add_child(board);connector.board=board
	for i in 16:
		var id:String=str(slots[i]) if i<slots.size() else "";var definition:Dictionary=_definition(id,definitions)
		var button:Button=ui._button("", "rune_remove" if not id.is_empty() else "rune_slot",i);button.custom_minimum_size=Vector2(44,44);button.name="RuneSlot%02d"%(i+1)
		button.add_theme_stylebox_override("normal",ui._box(Color("352b45"),GOLD if i==int(data.get("target_slot",-1)) else PURPLE.darkened(.2),8,3));_slot_art(ui,button,definition,false,i)
		ui.bind_description(button,definition.get("name","小符文空槽 %02d"%(i+1)),str(definition.get("desc","先選擇這個空槽，再從右側裝入符文。"))+ ("\n相鄰同種連線：這種符文總效果 +%d%%"%int(Links.count_by_id(slots).get(id,0)) if not id.is_empty() else ""),Icons.rune(id));board.add_child(button)
	var links:int=Links.edges(slots).size();left.add_child(ui._label("同種相鄰連線 %d 條 · 每條效果 +1%%"%links,12,PURPLE))
	right.add_child(ui._label("可裝配符文  ·  家中收藏" if data.get("in_start",false) else "可裝配符文",18,ui.INK))
	var list:VBoxContainer=_list(ui,right);var bag:Dictionary=data.get("bag",{})
	for rune in definitions:
		var id:String=rune["id"];var count:int=int(bag.get(id,0));var used:int=strong_slots.count(id) if rune.get("strong",false) else slots.count(id)
		if count<=0:continue
		var available:int=count-used
		_tile(ui,list,str(rune["name"])+" · 可用%d／已裝%d"%[available,used],str(rune["desc"])+"\n"+("大型金色符文 · 3格獨立刻印" if rune.get("strong",false) else "小型紫色符文 · 相同符文上下左右相連，每條讓該符文總效果增加1%。"),Icons.rune(id,rune.get("strong",false)),"rune_equip",id,GOLD if rune.get("strong",false) else PURPLE)
	if data.get("in_start",false):
		list.add_child(ui._label("家中符文  ·  取出即裝入",14,GOLD))
		for rune in definitions:
			var id:String=rune["id"];var count:int=int(data.get("stash",{}).get(id,0))
			if count>0:_tile(ui,list,str(rune["name"])+" · 家中×%d"%count,str(rune["desc"]),Icons.rune(id,rune.get("strong",false)),"rune_take",id,GOLD)
	if list.get_child_count()==0:list.add_child(ui._label("尚無符文，探索房間或返回安全屋取用收藏。",14,ui.MUTED))
static func _definition(id:String,definitions:Array) -> Dictionary:
	for definition in definitions:
		if definition["id"]==id:return definition
	return {}
static func _slot_art(ui,button:Button,definition:Dictionary,strong:bool,index:int) -> void:
	var contents:=VBoxContainer.new();contents.name="DeliveredRuneArt";contents.mouse_filter=Control.MOUSE_FILTER_IGNORE;contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);contents.offset_top=3;contents.add_theme_constant_override("separation",0);button.add_child(contents)
	if not definition.is_empty():
		var art:TextureRect=ui._icon(Icons.rune(str(definition["id"]),strong),38 if strong else 30);art.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;contents.add_child(art)
	else:
		var blank:Label=ui._label("◇" if strong else "+",27 if strong else 23,GOLD if strong else PURPLE);blank.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;contents.add_child(blank)
	var label:Label=ui._label(str(definition.get("name","大刻印" if strong else "%02d"%(index+1))),10,GOLD if strong else PURPLE);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;contents.add_child(label)
static func weapon_description(weapon:Dictionary) -> String:
	return str(weapon.get("description","合成副武器"))+"\n傷害 %.1f · 投射物 %d · 能量 1\n按副武器立即出招（零前搖）；%s切換下一把。"%[float(weapon.get("damage",0)),int(weapon.get("count",weapon.get("shots",1))),"Q"]
