class_name HomeVisualV33
extends RefCounted
const Art=preload("res://scripts/scene_art_v33.gd")
const ROOT:String="res://assets/v33/home/"
const FLOOR:float=600
const BOUNCE:=Vector2(455,600)
const RECORDS:=Vector2(790,600)
static func background(c:CanvasItem,camera_y:float=0.0) -> void:
	var image:Texture2D=Art.texture(ROOT+"background.png")
	if image==null:return
	var data:Dictionary=Art.info(ROOT+"background.json")
	var original:Array=data.get("original_size",[1536,1024])
	var scale_value:float=1280.0/float(original[0])
	var floor_source:float=image.get_height()*float(data.get("authored_floor_y",730))/float(original[1])
	var floor_screen:float=FLOOR-camera_y
	var canopy_top:float=FLOOR-float(data.get("authored_floor_y",730))*scale_value-camera_y*.20
	var canopy_height:float=floor_screen-canopy_top
	# The painted floor shares the station collision plane. The canopy moves
	# more slowly, with a continuous seam where the two texture regions meet.
	if canopy_top>0.0:
		c.draw_set_transform_matrix(Transform2D(Vector2.RIGHT,Vector2.UP,Vector2(0,canopy_top*2)))
		c.draw_texture_rect_region(image,Rect2(0,canopy_top,1280,canopy_top),Rect2(0,0,image.get_width(),floor_source*canopy_top/canopy_height))
		c.draw_set_transform_matrix(Transform2D.IDENTITY)
	c.draw_texture_rect_region(image,Rect2(0,canopy_top,1280,canopy_height),Rect2(0,0,image.get_width(),floor_source))
	c.draw_texture_rect_region(image,Rect2(0,floor_screen,1280,(float(original[1])-float(data.get("authored_floor_y",730)))*scale_value),Rect2(0,floor_source,image.get_width(),image.get_height()-floor_source))
static func prop(c:CanvasItem,id:String,at:Vector2,size:Vector2,base:Transform2D) -> void:
	Art.prop(c,ROOT+"props.json",id,at,size,base)
static func gate(c:CanvasItem,id:String,at:Vector2,base:Transform2D) -> void:
	prop(c,id,at,Vector2(205,280),base)
static func body() -> Rect2:return Rect2(BOUNCE-Vector2(36,55),Vector2(72,55))
