class_name EquipmentNavigationV25
extends RefCounted
var page:int=0
var zone:String="tabs"
var cursor:String=""
func prepare(ui,next_page:int,preserve:bool=false) -> void:
	if preserve:remember(ui)
	else:zone="tabs";cursor=""
	page=next_page
func remember(ui) -> void:
	var focused:Control=ui.get_viewport().gui_get_focus_owner()
	if focused==null or not focused.has_meta("equipment_zone"):return
	zone="tabs" if str(focused.get_meta("equipment_zone"))=="tabs" else "content"
	cursor=str(focused.get_meta("equipment_key",""))
func _collect(node:Node,items:Array[Control]) -> void:
	for child:Node in node.get_children():
		if child is Button and child.has_meta("equipment_zone") and not child.disabled and child.is_visible_in_tree():items.append(child)
		_collect(child,items)
func controls(ui,group:String="") -> Array[Control]:
	var result:Array[Control]=[];_collect(ui.panel_rows,result)
	return result.filter(func(control:Control)->bool:return str(control.get_meta("equipment_zone",""))==group) if not group.is_empty() else result
func _focus(ui,control:Control) -> void:
	control.grab_focus();remember(ui)
	var scroll:Node=control.get_parent()
	while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
	if scroll is ScrollContainer:scroll.ensure_control_visible(control)
func _tabs(ui) -> void:
	for button:Control in controls(ui,"tabs"):
		if int(button.get_meta("equipment_page",-1))==page:_focus(ui,button);return
func _enter(ui) -> void:
	var items:Array[Control]=controls(ui,"rune_auto" if page==3 else "list")
	if items.is_empty():_tabs(ui);return
	for control:Control in items:
		if control.get_meta("equipment_selected",false):_focus(ui,control);return
	_focus(ui,items[0])
func focus_first(ui) -> void:
	if zone=="tabs":_tabs(ui);return
	for control:Control in controls(ui):
		if str(control.get_meta("equipment_key",""))==cursor:_focus(ui,control);return
	_enter(ui)
func navigate(ui,action:String) -> bool:
	var current:Control=ui.get_viewport().gui_get_focus_owner()
	if current==null or not current.has_meta("equipment_zone"):focus_first(ui);current=ui.get_viewport().gui_get_focus_owner()
	if current==null:return true
	var group:String=str(current.get_meta("equipment_zone","tabs"))
	if group=="tabs":
		if action in ["left","right"]:ui.action_requested.emit("equipment_page",posmod(page+(1 if action=="left" else -1),4))
		elif action in ["down","attack"]:_enter(ui)
		return true
	if action=="attack":
		remember(ui)
		if current is Button:current.pressed.emit()
		return true
	var items:Array[Control]=controls(ui,group);var index:int=items.find(current)
	if index<0:_enter(ui);return true
	if group=="rune_auto":
		if action=="up":_tabs(ui)
		elif action=="right":_rune_list(ui)
		elif action=="down":
			var next:Array[Control]=controls(ui,"strong")
			if next.is_empty():next=controls(ui,"grid")
			if not next.is_empty():_focus(ui,next[0])
	elif group=="list":
		if action in ["left","right"]:ui.action_requested.emit("equipment_page",posmod(page+(1 if action=="left" else -1),4));return true
		if action=="up" and index==0:_tabs(ui)
		elif action in ["up","down"]:_focus(ui,items[clampi(index+(-1 if action=="up" else 1),0,items.size()-1)])
	elif group=="grid":
		if action=="left" and index%4>0:_focus(ui,items[index-1])
		elif action=="right":
			if index%4<3:_focus(ui,items[index+1])
			else:_rune_list(ui)
		elif action=="up":
			if index>=4:_focus(ui,items[index-4])
			else:
				var strong:Array[Control]=controls(ui,"strong")
				if not strong.is_empty():_focus(ui,strong[mini(index,strong.size()-1)])
				else:_tabs(ui)
		elif action=="down" and index<12:_focus(ui,items[index+4])
	elif group=="strong":
		if action=="up":
			var auto:Array[Control]=controls(ui,"rune_auto")
			if not auto.is_empty():_focus(ui,auto[0])
			else:_tabs(ui)
		elif action=="down":
			var grid:Array[Control]=controls(ui,"grid")
			if not grid.is_empty():_focus(ui,grid[mini(index,grid.size()-1)])
		elif action=="left" and index>0:_focus(ui,items[index-1])
		elif action=="right":
			if index<items.size()-1:_focus(ui,items[index+1])
			else:_rune_list(ui)
	elif group=="runes_list":
		if action=="left":
			var grid:Array[Control]=controls(ui,"grid");var target:int=int(current.get_meta("equipment_return_slot",0))
			if not grid.is_empty():_focus(ui,grid[clampi(target,0,15)])
		elif action=="up" and index==0:_tabs(ui)
		elif action in ["up","down"]:_focus(ui,items[clampi(index+(-1 if action=="up" else 1),0,items.size()-1)])
	return true
func _rune_list(ui) -> void:
	var items:Array[Control]=controls(ui,"runes_list")
	var current:Control=ui.get_viewport().gui_get_focus_owner();var target:int=int(current.get_meta("equipment_index",0)) if current!=null else 0
	for item:Control in items:item.set_meta("equipment_return_slot",target)
	if not items.is_empty():_focus(ui,items[0])
