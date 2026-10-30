class_name StationNavigationV26
extends RefCounted
static func controls(ui) -> Array[Control]:
	var all:Array[Control]=[];ui._navigable(ui.panel_rows,all)
	return all.filter(func(control:Control)->bool:return control.has_meta("station_key"))
static func focus(ui,control:Control) -> void:
	control.grab_focus();ui.station_focus_key=str(control.get_meta("station_key"))
	var parent:Node=control.get_parent()
	while parent!=null and not parent is ScrollContainer:parent=parent.get_parent()
	if parent is ScrollContainer:parent.ensure_control_visible(control)
static func focus_first(ui) -> void:
	var items:Array[Control]=controls(ui)
	for control:Control in items:
		if str(control.get_meta("station_key"))==ui.station_focus_key:focus(ui,control);return
	if not items.is_empty():focus(ui,items[0])
static func navigate(ui,action:String) -> bool:
	var items:Array[Control]=controls(ui)
	if items.is_empty():return true
	var current:Control=ui.get_viewport().gui_get_focus_owner()
	if current not in items:focus_first(ui);current=ui.get_viewport().gui_get_focus_owner()
	if action in ["attack","interact"]:
		if current.has_meta("choice_item"):
			for candidate:Node in ui.panel_rows.find_children("*","Button",true,false):
				if candidate.get_meta("choice_primary",false) and not candidate.disabled:candidate.pressed.emit();break
			return true
		if current is Button:current.pressed.emit()
		return true
	if current is HSlider and action in ["left","right"]:
		current.value+=current.step*(-1 if action=="left" else 1);return true
	if action not in ["left","right","up","down"]:return true
	var direction:Vector2={"left":Vector2.LEFT,"right":Vector2.RIGHT,"up":Vector2.UP,"down":Vector2.DOWN}[action]
	var origin:Vector2=current.get_global_rect().get_center();var best:float=INF;var target:Control=null
	for control:Control in items:
		if control==current:continue
		var offset:Vector2=control.get_global_rect().get_center()-origin;var ahead:float=offset.dot(direction)
		if ahead<5:continue
		var cross:float=absf(offset.dot(direction.orthogonal()))
		# A visible row/column wins over a diagonally closer control.
		var score:float=ahead+cross*4
		if score<best:best=score;target=control
	if target!=null:focus(ui,target)
	return true
