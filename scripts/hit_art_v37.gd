class_name HitArtV37
extends RefCounted
const PigeonBurst=preload("res://scripts/pigeon_burst_v72.gd")
const STRAIGHT=preload("res://assets/v75/straight-slash.webp")
const STRAIGHT_CELL:=Vector2(640,64)
const STRAIGHT_SECONDS:float=4.0/24.0

static func straight_extent(screen_width:float,zoom:float) -> Vector2:
	return Vector2(screen_width,24.0)/maxf(.1,zoom)

static func draw(c:CanvasItem,flash:Dictionary,base:Transform2D,screen_width:float=1280.0) -> void:
	var elapsed:float=float(flash["max"])-float(flash["life"])
	if elapsed>=0.0 and elapsed<STRAIGHT_SECONDS:
		var index:int=mini(3,int(elapsed*24.0))
		var cell:=Rect2(Vector2(index%2,index/2)*STRAIGHT_CELL,STRAIGHT_CELL)
		var extent:=straight_extent(screen_width,base.get_scale().x)
		c.draw_set_transform_matrix(base*Transform2D(float(flash.get("straight_angle",Vector2(flash["dir"]).angle())),Vector2(flash["at"])))
		c.draw_texture_rect_region(STRAIGHT,Rect2(-extent*.5,extent),cell,Color(1.1,1.06,1.04,.96))
	if bool(flash.get("feathers",false)):
		PigeonBurst.draw(c,PigeonBurst.IMPACT,flash.get("spray_at",flash["at"]),flash["dir"],elapsed,PigeonBurst.IMPACT_DURATION,PigeonBurst.IMPACT_EXTENT,base,PigeonBurst.IMPACT_TINT)
	c.draw_set_transform_matrix(base)
