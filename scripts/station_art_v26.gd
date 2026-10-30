class_name StationArtV26
extends RefCounted
static var textures:Dictionary={}
const FILES={"forge":"blueprint-forge","reforge":"rune-reforge","mail":"warehouse"}
const BOUNDS={"forge":Rect2(15,151,1210,950),"reforge":Rect2(26,54,1206,1131),"mail":Rect2(38,14,1178,1198)}
static func texture(kind:String) -> Texture2D:
	if textures.has(kind):return textures[kind]
	if not FILES.has(kind):return null
	var path:String="res://assets/v26/stations/"+str(FILES[kind])+".png"
	if ResourceLoader.exists(path):textures[kind]=load(path);return textures[kind]
	return null
static func draw(canvas:CanvasItem,kind:String,at:Vector2,base:Transform2D) -> void:
	var image:Texture2D=texture(kind)
	if image==null:return
	var original:Rect2=BOUNDS[kind];var ratio:Vector2=image.get_size()/Vector2(1254,1254);var source:=Rect2(original.position*ratio,original.size*ratio);var size:Vector2=source.size;var factor:float=minf(144/size.x,116/size.y)
	canvas.draw_set_transform_matrix(base)
	canvas.draw_texture_rect_region(image,Rect2(at-Vector2(size.x*.5,size.y)*factor,size*factor),source)
