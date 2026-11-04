extends RefCounted

const CELL:=Vector2(192,144)
const SWIPE:int=0
const RUSH:int=1
const POISON:int=2
const SHOT:int=3
static var atlas:Texture2D

static func frame(progress:float) -> int:
	return clampi(int(progress*4.0),0,3)

static func attack_row(attack:Dictionary) -> int:
	if attack.get("poison_cloud",false):return POISON
	if attack.get("ram",false):return RUSH
	return SWIPE if attack.get("primary",false) else SHOT

static func draw(c:CanvasItem,row:int,progress:float,dest:Rect2,tint:Color=Color.WHITE) -> void:
	if atlas==null:atlas=load("res://assets/v59/effects/release.webp")
	c.draw_texture_rect_region(atlas,dest,Rect2(Vector2(frame(progress),row)*CELL,CELL),tint)

static var ring:Texture2D

static func draw_ring(c:CanvasItem,progress:float,dest:Rect2,tint:Color) -> void:
	if ring==null:ring=load("res://assets/v59/effects/ring.webp")
	var cell:=Vector2(ring.get_width()/4.0,ring.get_height())
	c.draw_texture_rect_region(ring,dest,Rect2(Vector2(frame(progress)*cell.x,0),cell),tint)
