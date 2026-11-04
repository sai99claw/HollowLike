class_name ExplosionV16
extends RefCounted
static var frames:Dictionary={}
static func texture(surface:bool,index:int) -> Texture2D:
	var key:String=("surface" if surface else "air")+str(clampi(index,0,7))
	if frames.has(key):return frames[key]
	var image:Texture2D=load("res://assets/v16/explosion_%s.png"%("surface" if surface else "air"))
	var cell:Vector2=image.get_size()/Vector2(4,2)
	var result:=AtlasTexture.new();result.atlas=image;result.region=Rect2(Vector2(index%4,index/4)*cell,Vector2(cell.x,cell.y*(.875 if surface else 1.0)));result.filter_clip=true
	frames[key]=result;return result
static func draw(c:CanvasItem,e:Dictionary,base:Transform2D) -> void:
	var normal:Vector2=e.get("normal",Vector2.ZERO);var surface:bool=normal!=Vector2.ZERO
	var image:Texture2D=texture(surface,mini(7,int((1-float(e["life"])/float(e["max"]))*8)))
	var width:float=float(e["radius"])*2.7;var extent:=Vector2(width,width*image.get_height()/image.get_width())
	var angle:float=normal.angle()+PI*.5 if surface else 0
	c.draw_set_transform_matrix(base*Transform2D(angle,e["pos"]))
	c.draw_texture_rect(image,Rect2(Vector2(-extent.x*.5,-extent.y if surface else -extent.y*.5),extent),false,Color(1,1,1,.30))
	c.draw_set_transform_matrix(base)
static func contact(at:Vector2,velocity:Vector2,world:Array,radius:float) -> Dictionary:
	var best:Dictionary={};var nearest:float=INF
	for rect:Rect2 in world:
		var grown:Rect2=rect.grow(radius+2)
		if not grown.has_point(at):continue
		for pair in [[Vector2.UP,Vector2(clampf(at.x,rect.position.x,rect.end.x),rect.position.y)],[Vector2.DOWN,Vector2(clampf(at.x,rect.position.x,rect.end.x),rect.end.y)],[Vector2.LEFT,Vector2(rect.position.x,clampf(at.y,rect.position.y,rect.end.y))],[Vector2.RIGHT,Vector2(rect.end.x,clampf(at.y,rect.position.y,rect.end.y))]]:
			var n:Vector2=pair[0];var point:Vector2=pair[1];var distance:float=at.distance_to(point)
			if velocity.dot(n)<0 and distance<nearest:nearest=distance;best={"normal":n,"point":point}
	return best
