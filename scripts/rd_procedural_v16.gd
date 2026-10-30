class_name RDProceduralV16
extends Control
const Adventure=preload("res://scripts/adventure_visual.gd")
const Bath=preload("res://scripts/bath_water.gd")
const Detail=preload("res://scripts/world_detail.gd")
var asset:String=""
var frame_index:int=0
func configure(id:String,index:int) -> void:asset=id;frame_index=index;mouse_filter=Control.MOUSE_FILTER_IGNORE;queue_redraw()
func _draw() -> void:
	var scale_value:float=minf(size.x/680,size.y/360);var base:=Transform2D(0,Vector2.ONE*scale_value,0,(size-Vector2(680,360)*scale_value)*.5)
	draw_set_transform_matrix(base)
	var time:float=float(frame_index)/12
	if asset.begins_with("procedural:door"):
		var color:=Color("fa9395") if asset.ends_with("boss") else (Color("8bdfb1") if asset.ends_with("safe") else Color("efcf7d"))
		Adventure.portal(self,Vector2(72,280),color,time,base,"trunk","left",192,true)
	elif asset=="procedural:water":
		var water:=Bath.new();water.ripples=[{"x":340.0,"age":fposmod(time,1.2),"splash":true}];water.draw(self,Rect2(100,230,480,65),base,time)
	elif asset=="procedural:grass":Detail.grass(self,{"pos":Vector2(340,290),"seed":3.0,"used":false},time,base)
	draw_set_transform_matrix(Transform2D.IDENTITY)
