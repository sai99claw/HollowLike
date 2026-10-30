class_name WeaponPreviewV27
extends Control
const Art=preload("res://scripts/weapon_art_v24.gd")
const Data=preload("res://scripts/game_data.gd")
const Arsenal=preload("res://scripts/arsenal_v24.gd")
var weapon_id:String=""
var clock:float=0
func _init() -> void:
	custom_minimum_size=Vector2(150,115);size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
func set_weapon(id:String) -> void:
	if weapon_id!=id:clock=0
	weapon_id=id;visible=Arsenal.index_of(id)>=0;queue_redraw()
func _process(delta:float) -> void:
	if not is_visible_in_tree() or weapon_id.is_empty():return
	clock+=delta;queue_redraw()
func _draw() -> void:
	if weapon_id.is_empty():return
	var w:float=maxf(150,size.x);var h:float=maxf(95,size.y);var floor_y:float=h-18;var t:float=fmod(clock,2.1);var travel:float=clampf((t-.22)/1.2,0,1)
	draw_style_box(_box(),Rect2(Vector2.ZERO,size));draw_line(Vector2(10,floor_y),Vector2(w-10,floor_y),Color("38534b"),1,true)
	var source:=Vector2(27,floor_y-35)
	Art.draw(self,weapon_id,source,Vector2.RIGHT,22,false)
	if t<.22:
		draw_arc(source,23,0,TAU*t/.22,24,Color("a3e3cb"),2,true);return
	var x:float=lerpf(56,w-24,travel);var at:=Vector2(x,floor_y-34);var heading:=Vector2.RIGHT
	match weapon_id:
		"chain_staff":
			var pts:=PackedVector2Array([source+Vector2(20,0)])
			for i in 8:pts.append(Vector2(55+(w-85)*i/7,floor_y-35+sin(i*2.7+floor(clock*12))*10))
			draw_polyline(pts,Color("a5b8ff"),5,true);draw_polyline(pts,Color("f1f3ff"),1.5,true);return
		"piercing_laser":
			draw_line(source+Vector2(15,0),Vector2(w-18,source.y),Color(.3,.8,1,.25),12,true);draw_line(source+Vector2(15,0),Vector2(w-18,source.y),Color("d9fbff"),3,true);return
		"impact_bomb","trap_pod","fire_flask":
			at.y=floor_y-22-42*sin(travel*PI);heading=Vector2(1,-cos(travel*PI))
			if travel>.90:
				if weapon_id=="fire_flask":preload("res://scripts/ground_fire_v27.gd").draw(self,{"pos":Vector2(w-40,floor_y),"size":62,"elapsed":.2},clock,Transform2D.IDENTITY)
				elif weapon_id=="trap_pod":draw_arc(Vector2(w-35,floor_y),20,PI,TAU,16,Color("b2d78a"),5,true)
				else:draw_arc(at,18+sin(clock*10)*5,0,TAU,24,Color("ffbc7a"),5,true)
				return
		"ricochet":
			x=56+(w-80)*(1-absf(2*travel-1));at=Vector2(x,floor_y-34+sin(travel*TAU)*17);heading=Vector2(1 if travel<.5 else -1,0)
		"homing_missile":at.y+=sin(travel*PI)*20;heading=Vector2(1,cos(travel*PI)*.4)
	var path:=PackedVector2Array()
	for i in 8:
		var d:float=(7-i)*5;path.append(at-heading.normalized()*d)
	for i in range(1,6):draw_circle(at-heading.normalized()*i*3+Vector2(0,sin(i*1.7+clock*3)),maxf(.3,1.3-i*.16),Color(.53,.51,.47,.19*(1-i/6.0)))
	Art.draw(self,weapon_id,at,heading,12,true,Transform2D.IDENTITY,t-.22)
func _box() -> StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=Color("091b1d");box.border_color=Color("35564c");box.set_border_width_all(1);box.set_corner_radius_all(9);return box
