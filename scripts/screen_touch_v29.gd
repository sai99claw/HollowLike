class_name ScreenTouchV29
extends Control
signal action_changed(action:String,pressed:bool)

const ACTIONS:Array[String]=["left","right","up","down","sub","attack","dash","jump","heal"]
var held:Dictionary={}
var fingers:Dictionary={}
var stick_finger:int=-1
var stick_vector:=Vector2.ZERO
var bridge:JavaScriptObject
var callback:JavaScriptObject

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visibility_changed.connect(_visibility_changed)
	if OS.has_feature("web"):
		bridge=JavaScriptBridge.get_interface("PigeonTouch")
		if bridge!=null:
			callback=JavaScriptBridge.create_callback(_web_action)
			bridge.attach(callback)
	_visibility_changed()

static func mobile_default() -> bool:
	if OS.has_feature("mobile"):return true
	if OS.has_feature("web"):return bool(JavaScriptBridge.eval("navigator.maxTouchPoints > 0 || matchMedia('(pointer: coarse)').matches",true))
	return false

func _web_action(arguments:Array) -> void:
	if arguments.is_empty():return
	var data:Variant=JSON.parse_string(str(arguments[0]))
	if data is Dictionary and ACTIONS.has(str(data.get("action",""))):_set_action(str(data["action"]),bool(data.get("pressed",false)))

func _visibility_changed() -> void:
	if not is_visible_in_tree():release_all()
	if bridge!=null:bridge.setVisible(is_visible_in_tree())
	queue_redraw()

func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:release_all()

func _exit_tree() -> void:
	release_all()
	if bridge!=null:bridge.detach()

func _set_action(action:String,pressed:bool) -> void:
	if bool(held.get(action,false))==pressed:return
	held[action]=pressed;action_changed.emit(action,pressed);queue_redraw()

func release_all() -> void:
	for action:String in ACTIONS:_set_action(action,false)
	fingers.clear();stick_finger=-1;stick_vector=Vector2.ZERO
	if bridge!=null:bridge.releaseAll()
	queue_redraw()

func geometry() -> Dictionary:
	var extent:Vector2=get_viewport_rect().size
	var unit:float=clampf(minf(extent.x/1280.0,extent.y/720.0),.55,1.5)
	var r:float=64*unit;var b:float=70*unit;var margin:float=24*unit
	var right:Vector2=extent-Vector2(margin+b*.5,margin+b*.5)
	return {"stick":Vector2(margin+r,extent.y-margin-r),"radius":r,"button_radius":b*.5,"sub":right-Vector2(b+12*unit,b+12*unit),"attack":right-Vector2(0,b+12*unit),"dash":right-Vector2(b+12*unit,0),"jump":right,"heal":Vector2(extent.x-margin-b*.5,margin+b*.5+45*unit)}

func _input(event:InputEvent) -> void:
	if bridge!=null or not is_visible_in_tree():return
	if event is InputEventScreenTouch:
		if event.pressed:press(event.index,event.position)
		else:release(event.index)
	elif event is InputEventScreenDrag:drag(event.index,event.position)

func press(index:int,at:Vector2) -> void:
	var g:Dictionary=geometry()
	if stick_finger<0 and at.distance_to(g["stick"])<=float(g["radius"])*1.3:
		stick_finger=index;drag(index,at);get_viewport().set_input_as_handled();return
	for action:String in ["sub","attack","dash","jump","heal"]:
		if at.distance_to(g[action])<=float(g["button_radius"])*1.12:
			fingers[index]=action;_set_action(action,true);get_viewport().set_input_as_handled();return

func drag(index:int,at:Vector2) -> void:
	if index!=stick_finger:return
	var g:Dictionary=geometry();stick_vector=((at-Vector2(g["stick"]))/float(g["radius"])).limit_length()
	_set_action("left",stick_vector.x<-.26);_set_action("right",stick_vector.x>.26)
	_set_action("up",stick_vector.y<-.48 and absf(stick_vector.y)>absf(stick_vector.x)*1.2);_set_action("down",stick_vector.y>.48)
	queue_redraw();get_viewport().set_input_as_handled()

func release(index:int) -> void:
	if index==stick_finger:
		stick_finger=-1;stick_vector=Vector2.ZERO
		for action:String in ["left","right","up","down"]:_set_action(action,false)
	if fingers.has(index):
		var action:String=fingers[index];fingers.erase(index)
		if not fingers.values().has(action):_set_action(action,false)
	queue_redraw()

func _draw() -> void:
	if bridge!=null:return
	var g:Dictionary=geometry();var r:float=g["radius"];var center:Vector2=g["stick"]
	draw_circle(center,r,Color(.04,.12,.15,.55));draw_arc(center,r,0,TAU,48,Color("c5d3b9",.65),2,true)
	draw_circle(center+stick_vector*r*.63,r*.4,Color("c7d7c3",.82))
	var font:Font=get_theme_default_font()
	for entry:Array in [["sub","副武器"],["attack","主武器"],["dash","衝"],["jump","跳躍"],["heal","回血"]]:
		var at:Vector2=g[entry[0]];var br:float=g["button_radius"]
		draw_circle(at,br,Color(.38,.55,.49,.8) if held.get(entry[0],false) else Color(.04,.12,.15,.58))
		draw_arc(at,br,0,TAU,40,Color("d9cda5",.8),2,true)
		var text_size:Vector2=font.get_string_size(entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,16)
		draw_string(font,at-Vector2(text_size.x*.5,-6),entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f5edd6"))
