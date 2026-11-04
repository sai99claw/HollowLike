extends RefCounted

const CELL:=Vector2(160,144)
const ANCHOR:=Vector2(80,137)
const SCALE:float=.69
static var sheet:Texture2D

static func draw_station(canvas:CanvasItem,index:int,at:Vector2) -> void:
	if sheet==null:sheet=load("res://assets/v62/tutorial/stations.webp")
	canvas.draw_texture_rect_region(sheet,Rect2(at-ANCHOR*SCALE,CELL*SCALE),Rect2(Vector2(CELL.x*index,0),CELL))
