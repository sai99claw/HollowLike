extends Control

var fill:float=0.0
var _breath:float=0.0

func _ready() -> void:
	custom_minimum_size=Vector2(170,17)
	size_flags_vertical=Control.SIZE_SHRINK_CENTER
	mouse_filter=Control.MOUSE_FILTER_PASS

func set_fill(value:float) -> void:
	var next:float=clampf(value,0.0,1.0)
	if next==fill:return
	fill=next
	if fill<1.0:_breath=0.0
	tooltip_text="大招 %d%%"%roundi(fill*100.0)
	queue_redraw()

func _process(delta:float) -> void:
	if fill<1.0 or not is_visible_in_tree():return
	_breath=fposmod(_breath+delta/1.35,1.0)
	queue_redraw()

func target_center() -> Vector2:
	return get_global_transform_with_canvas()*Vector2(lerpf(4.0,size.x-4.0,fill),size.y*.5)

func _draw() -> void:
	var outer:=Rect2(Vector2.ZERO,size)
	var track:=outer.grow(-2.0)
	var ready:bool=fill>=1.0
	var glow:float=.5-.5*cos(TAU*_breath)
	if ready:
		draw_rect(outer.grow(3.0),Color(1,.67,.27,.12+glow*.22),false,4.0)
	draw_rect(outer,Color("17111c"))
	draw_rect(outer,Color("ddab57") if ready else Color("876646"),false,1.0)
	if fill<=0.0:return
	var charged:=Rect2(track.position,Vector2(track.size.x*fill,track.size.y))
	var gold:=Color("c98735")
	if ready:gold=gold.lerp(Color("fff4a9"),glow)
	draw_rect(charged,gold)
	draw_rect(Rect2(charged.position,Vector2(charged.size.x,3)),Color(1.0,.91,.65,.65))
