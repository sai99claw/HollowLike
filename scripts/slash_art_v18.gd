class_name SlashArtV18
extends RefCounted
const PATH:String="res://assets/v18/slash-smear.png"
const STRAIGHT_PATH:String="res://assets/v72/straight-slash.png"
const STRAIGHT_CELL:=Vector2(640,40)
static var texture:Texture2D
static var straight_texture:Texture2D

static func straight_length(screen_width:float,base:Transform2D) -> float:
	return screen_width*.5/maxf(.001,base.x.length())

static func draw_straight(c:CanvasItem,at:Vector2,direction:String,progress:float,screen_width:float,base:Transform2D) -> void:
	if straight_texture==null:straight_texture=load(STRAIGHT_PATH)
	var index:int=clampi(int(progress*4),0,3)
	var angle:float=-PI*.5 if direction=="up" else (PI*.5 if direction=="down" else 0.0)
	var scale:float=maxf(.001,base.x.length())
	var size:=Vector2(straight_length(screen_width,base),24.0/scale)
	c.draw_set_transform_matrix(base*Transform2D(angle,at))
	var source:=Rect2(Vector2(index%2,index/2)*STRAIGHT_CELL,STRAIGHT_CELL)
	c.draw_texture_rect_region(straight_texture,Rect2(-size*.5,size),source)
	c.draw_set_transform_matrix(base)

static func draw(c:CanvasItem,box:Rect2,definition:Dictionary,progress:float,base:Transform2D) -> void:
	if texture==null:texture=load(PATH)
	var index:int=mini(7,int(clampf(progress,0,.99999)*8))
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
