extends Control
const Art=preload("res://scripts/art.gd")
const Cloaks=preload("res://scripts/cloak_art_v29.gd")
var index:int=0
var time:float=0
var refresh:float=0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta:float) -> void:
	time+=delta;refresh+=delta
	if refresh>.08:refresh=0;queue_redraw()
func _draw() -> void:
	var base:=Transform2D(0,Vector2(2.7,2.7),0,Vector2(size.x*.6,size.y*.72))
	Art.draw_pigeon(self,Vector2.ZERO,1,time,"idle",Color.WHITE,1,0,base)
	Cloaks.draw(self,index,Vector2.ZERO,1,time,false,base)
