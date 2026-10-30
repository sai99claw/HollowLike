class_name ChoiceViewV27
extends RefCounted
const Station=preload("res://scripts/station_view_v26.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
static func build(ui,title:String,entries:Array[Dictionary],page:String,explanation:String,selected:int=0) -> void:
	if ui.station_page!=page:ui.station_focus_key="";ui.station_selection=""
	var body:HBoxContainer=Station._begin(ui,title,page)
	var left:VBoxContainer=Station._pane(ui,body,320);var right:VBoxContainer=Station._pane(ui,body,590)
	Station._text(ui,left,"選擇物件",20,ui.MINT);var grid:GridContainer=Station._grid(ui,left,350);grid.name="ChoiceGrid"
	var hero:Dictionary=Station._hero(ui,right)
	var preview:Control=hero["animation"]
	var buttons:=HBoxContainer.new();buttons.add_theme_constant_override("separation",8);right.add_child(buttons)
	Station._text(ui,right,explanation,13)
	var show_entry:Callable=func(index:int)->void:
		var entry:Dictionary=entries[index];ui.station_selection=str(index);hero["image"].texture=Icons.texture(str(entry.get("icon","")));hero["title"].text=entry["name"];hero["description"].text=entry.get("description","");hero["requirements"].text=entry.get("caption","");preview.set_weapon(str(entry.get("weapon_id","")))
		for child:Node in buttons.get_children():buttons.remove_child(child);child.queue_free()
		for def:Dictionary in entry.get("buttons",[]):
			var button:Button=Station._button(ui,buttons,str(def["label"]),str(def["action"]),def.get("payload",null),page+":confirm:"+str(def["action"]));button.disabled=bool(def.get("disabled",false));button.set_meta("choice_primary",buttons.get_child_count()==1)
	for i in entries.size():
		var entry:Dictionary=entries[i];var tile:Button=Station._tile(ui,grid,str(entry["name"]),str(entry.get("icon","")),str(entry.get("caption","")),"station_noop",null,page+":item:"+str(i));tile.set_meta("choice_item",true);tile.focus_entered.connect(show_entry.bind(i));tile.mouse_entered.connect(show_entry.bind(i));tile.pressed.connect(show_entry.bind(i))
	if not entries.is_empty():show_entry.call(clampi(selected,0,entries.size()-1))
	ui.station_focus_key=page+":item:"+str(clampi(selected,0,maxi(0,entries.size()-1)));ui.call_deferred("focus_first")
