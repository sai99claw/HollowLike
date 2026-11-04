extends RefCounted

const DURATION:float=.64
const CELL:=Vector2(192,160)
const ANCHOR:=Vector2(96,153)
static var sheets:Dictionary={}

static func frame(prop:Dictionary) -> int:
	if not prop.get("used",false):return 0
	return clampi(int((1.0-float(prop.get("open_left",0.0))/DURATION)*8),0,7)

static func draw(c:CanvasItem,prop:Dictionary,biome:String,base:Transform2D) -> void:
	if not sheets.has(biome):
		sheets[biome]=load("res://assets/v59/chests/"+biome+".webp")
	var texture:Texture2D=sheets[biome]
	var index:int=frame(prop)
	var source:=Rect2(Vector2(index%4,index/4)*CELL,CELL)
	var at:Vector2=prop["pos"]
	c.draw_set_transform_matrix(base)
	c.draw_texture_rect_region(texture,Rect2(at-ANCHOR*.52,CELL*.52),source)
