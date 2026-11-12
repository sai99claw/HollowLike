class_name SlashArtV18
extends RefCounted
const PATH:String="res://assets/v18/slash-smear.png"
const FPS:float=20.0
const FRAME_COUNT:int=8
const SEQUENCE:Array[int]=[0,1,2,4]
const DURATION:float=4.0/FPS
static var texture:Texture2D

static func frame_at(elapsed:float) -> int:
	return -1 if elapsed<0.0 or elapsed>=DURATION else SEQUENCE[mini(SEQUENCE.size()-1,floori(elapsed*FPS))]

static func draw(c:CanvasItem,box:Rect2,definition:Dictionary,elapsed:float,base:Transform2D) -> void:
	var index:int=frame_at(elapsed)
	if index<0:return
	if texture==null:texture=load(PATH)
	var cell:Vector2=texture.get_size()/Vector2(4,2)
	var direction:String=str(definition.get("direction","right"))
	var angle:float=-PI*.5 if direction=="up" else (PI*.5 if direction=="down" else 0.0)
	var size:Vector2=Vector2(box.size.y,box.size.x) if direction in ["up","down"] else box.size
	# The sprite's core fits the hitbox; translucent fringes can extend slightly.
	size*=1.12
	c.draw_set_transform_matrix(base*Transform2D(angle,Vector2(-1 if direction=="left" else 1,1),0,box.get_center()))
	var tint:Color=Color(1.12,1.12,1.12,1)
	if definition.get("style","")=="heavy":tint=Color(1.2,1.08,.9,1)
	c.draw_texture_rect_region(texture,Rect2(-size*.5,size),Rect2(Vector2(index%4,index/4)*cell,cell),tint)
	c.draw_set_transform_matrix(base)
