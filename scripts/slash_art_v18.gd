class_name SlashArtV18
extends RefCounted
const PATH:String="res://assets/v18/slash-smear.png"
static var texture:Texture2D
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
