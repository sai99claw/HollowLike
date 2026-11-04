class_name EquipmentViewV24
extends RefCounted
const Data=preload("res://scripts/game_data.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
const Inventory=preload("res://scripts/inventory_view.gd")
const TITLES:Array[String]=["主武器","附武器","消耗品","符文"]
static func tabs(ui,page:int) -> void:
	var bar:=HBoxContainer.new();bar.name="EquipmentTabsV24";bar.add_theme_constant_override("separation",8);ui.panel_rows.add_child(bar);ui.panel_rows.move_child(bar,0)
	for i:int in [2,1,0,3]:
		var button:Button=ui._button(("◆ " if i==page else "◇ ")+TITLES[i],"equipment_page",i);button.custom_minimum_size=Vector2(208,38)
		if i==page:button.add_theme_stylebox_override("normal",ui._box(Color("36574b"),Color("ebca83"),10,7))
		button.set_meta("equipment_zone","tabs");button.set_meta("equipment_key","tab:"+str(i));button.set_meta("equipment_page",i);bar.add_child(button)
	ui.panel_rows.add_child(ui._label("←→ 換頁 · ↓／X 進入清單 · ↑ 回頁籤 · X 確認 · E／Esc 關閉",12,ui.MUTED))
static func build(ui,data:Dictionary,page:int) -> void:
	var sections:Array[Dictionary]=[]
	ui.show_panel("羽旅兵裝  /  "+TITLES[page],sections);ui.inventory_page="equipment_v25"
	tabs(ui,page)
	ui.inspector.visible=true;ui.inspect_item("兵裝狀態","指向或選擇清單中的物件，查看詳細效果與強化。","")
	if page==3:
		var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",22);ui.panel_rows.add_child(columns)
		var left:VBoxContainer=ui._column(columns,418);var right:VBoxContainer=ui._column(columns,440)
		Inventory._runes(ui,data,left,right)
		_mark_runes(ui,right);ui.call_deferred("focus_first");return
	var body:=HBoxContainer.new();body.add_theme_constant_override("separation",24);ui.panel_rows.add_child(body)
	var hero:VBoxContainer=ui._column(body,360);var list:VBoxContainer=ui._column(body,492)
	var definition:Dictionary=data["primary"]
	if page==1:definition=data["weapons"][clampi(int(data["selected"]),0,data["weapons"].size()-1)] if not data["weapons"].is_empty() else {}
	if page==2:
		definition={}
		for i in Data.ITEMS.size():
			if int(data["items"].get(str(i),0))>0:definition=Data.ITEMS[i];break
	var icon:String="" if definition.is_empty() else Icons.primary(definition) if page==0 else Icons.secondary(definition) if page==1 else "items_"+str(definition["id"])
	var image:TextureRect=ui._icon(icon,210);image.name="EquipmentHeroArt";image.custom_minimum_size=Vector2(340,210);hero.add_child(image)
	var preview:Control=null
	if page==1:
		hero.remove_child(image);var art_row:=HBoxContainer.new();art_row.add_theme_constant_override("separation",10);hero.add_child(art_row);image.custom_minimum_size=Vector2(140,170);art_row.add_child(image)
		preview=preload("res://scripts/weapon_preview_v27.gd").new();preview.name="WeaponFiringPreview";art_row.add_child(preview);preview.set_weapon(str(definition.get("id","")))
	var title:Label=ui._label(str(definition.get("name","尚無附武器" if page==1 else "沒有消耗品")),26,ui.INK);title.name="EquipmentHeroName";hero.add_child(title)
	var description:String=str(definition.get("description",definition.get("desc","")))
	if page==1:
		description+=("\n無雙夢境齊射：%d / 16把\n按Z消耗1格能量，全部武器同時發動。"%data["weapons"].size() if data["mode"]=="musou" else "\n重複武器增加投射物，最多 +8。\n遊戲中Q切換；面板內↓進入清單，X裝備。")
		if data["mode"]=="musou":description+="\n齊射週期 %.2f秒（基礎0.60秒），受攻速符文調整；前搖0，不隨選取武器改變。"%float(data.get("musou_cycle_seconds",.6))
		if not data["weapons"].is_empty():description+="\n目前重複強化 +%d"%int(definition.get("duplicate_bonus",0))
	if page==2:description+="\n快捷：Shift＋1～5 使用消耗品。\n未綁定的數字鍵也可使用消耗品。"
	var text:Label=ui._label(description,16,ui.MUTED);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hero.add_child(text)
	list.add_child(ui._label(["主武器動作","附武器清單","隨身補給"][clampi(page,0,2)],20,ui.MINT))
	if page==1 and data["mode"]=="musou":
		var sockets:=GridContainer.new()
		sockets.columns=8
		list.add_child(sockets)
		for i in 16:
			var socket:=PanelContainer.new()
			socket.custom_minimum_size=Vector2(43,43)
			socket.add_theme_stylebox_override("panel",ui._box(Color("20352d"),ui.GOLD,6,3))
			sockets.add_child(socket)
			if i<data["weapons"].size():
				var weapon:Dictionary=data["weapons"][i]
				socket.add_child(ui._icon(Icons.secondary(weapon),34))
				socket.tooltip_text=weapon["name"]
			else:socket.add_child(ui._label("·",15,ui.MUTED))
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(490,310);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;list.add_child(scroll)
	var rows:=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",8);scroll.add_child(rows)
	if page==0:
		for i in [1]:
			var weapon:Dictionary=Data.PRIMARY[i]
			Inventory._tile(ui,rows,str(weapon["name"]),str(weapon["description"]),Icons.primary(weapon),"primary_inventory",i,weapon["color"],i==int(data["primary_index"]))
	elif page==1:
		for i in data["weapons"].size():
			var weapon:Dictionary=data["weapons"][i];var bonus:int=int(weapon.get("duplicate_bonus",0))
			Inventory._tile(ui,rows,str(weapon["name"])+(" · 齊射%02d"%(i+1) if data["mode"]=="musou" else " · +%d / 8"%bonus),str(weapon["description"])+"\n基本傷害 %.1f · 基本投射物 %d\n速度、射程、範圍與傷害由符文強化。"%[float(weapon.get("damage",0)),int(weapon.get("count",weapon.get("shots",1)))+bonus],Icons.secondary(weapon),"sub_select",i,weapon.get("color",ui.MINT),i==int(data["selected"]))
		if data["weapons"].is_empty():rows.add_child(ui._label("先領取安全屋的免費附武器。",16,ui.MUTED))
	else:
		for i in Data.ITEMS.size():
			var count:int=int(data["items"].get(str(i),0));var item:Dictionary=Data.ITEMS[i]
			if count>0:Inventory._tile(ui,rows,str(item["name"])+" ×%d"%count,str(item["desc"]),"items_"+str(item["id"]),"use_item",i,item["color"])
		if rows.get_child_count()==0:rows.add_child(ui._label("目前沒有消耗品。",16,ui.MUTED))
	for child:Node in rows.get_children():
		if child is Button:
			child.set_meta("equipment_zone","list");child.set_meta("equipment_key",str(child.get_meta("inventory_focus","")))
			child.set_meta("equipment_selected",str(child.get_meta("inventory_focus","")).ends_with("|"+str(int(data.get("primary_index",0)) if page==0 else int(data.get("selected",0)))))
			if page==1:
				var position:int=int(str(child.get_meta("inventory_focus","")).get_slice("|",1));var weapon:Dictionary=data["weapons"][position]
				var show_weapon:Callable=func()->void:
					image.texture=Icons.texture(Icons.secondary(weapon));title.text=weapon["name"];text.text=str(weapon["description"])+( "\n無雙夢境齊射週期 %.2f秒 · 前搖0\n全部武器同時發動，不隨選取武器改變。"%float(data.get("musou_cycle_seconds",.6)) if data["mode"]=="musou" else "\n強化 +%d / 8 · 發射預覽"%int(weapon.get("duplicate_bonus",0)));preview.set_weapon(str(weapon["id"]))
				child.focus_entered.connect(show_weapon);child.mouse_entered.connect(show_weapon)

	ui.call_deferred("focus_first")

static func _mark_runes(ui,right:VBoxContainer) -> void:
	for group:String in ["grid","strong"]:
		var board:Node=ui.panel_rows.find_child("RuneBoard" if group=="grid" else "StrongRuneBoard",true,false)
		if board==null:continue
		for i in board.get_child_count():
			var control:Control=board.get_child(i);control.set_meta("equipment_zone",group);control.set_meta("equipment_index",i);control.set_meta("equipment_key",group+":"+str(i))
	var controls:Array[Control]=[];ui._navigable(right,controls)
	for control:Control in controls:control.set_meta("equipment_zone","runes_list");control.set_meta("equipment_key",str(control.get_meta("inventory_focus","")))
