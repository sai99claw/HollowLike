extends RefCounted

const IMPULSE=preload("res://assets/v72/wing-impulse.webp")
const IMPACT=preload("res://assets/v75/impact-feathers.webp")
const CELL:=Vector2(384,192)
const PIVOT:=Vector2(64,96)
const FRAME_COUNT:int=4
const IMPULSE_DURATION:float=.24
const IMPACT_DURATION:float=.20
const IMPACT_EXTENT:float=168.0
const IMPACT_TINT:=Color(1.3,1.22,1.24,1)

static func frame_at(elapsed:float,duration:float) -> int:
	if elapsed<0 or elapsed>=duration:return -1
	return mini(FRAME_COUNT-1,int(elapsed/duration*FRAME_COUNT))

static func draw(canvas:CanvasItem,art:Texture2D,origin:Vector2,direction:Vector2,elapsed:float,duration:float,extent:float,base:Transform2D,tint:Color=Color.WHITE) -> void:
	var index:int=frame_at(elapsed,duration)
	if index<0:return
	var source:=Rect2(Vector2(index%2,index/2)*CELL,CELL)
	var factor:float=extent/(CELL.x-PIVOT.x)
	canvas.draw_set_transform_matrix(base*Transform2D(direction.angle(),Vector2.ONE*factor,0,origin))
	canvas.draw_texture_rect_region(art,Rect2(-PIVOT,CELL),source,tint)
	canvas.draw_set_transform_matrix(base)
