class_name WorldItemArt
extends RefCounted
const Icons=preload("res://scripts/ui_asset_art.gd")
const Data=preload("res://scripts/game_data.gd")
static func draw_icon(c:CanvasItem,clip:String,rect:Rect2,base:Transform2D,tint:Color=Color.WHITE) -> bool:
	var texture:Texture2D=Icons.texture(clip)
	if texture==null:return false
	var factor:float=minf(rect.size.x/texture.get_width(),rect.size.y/texture.get_height());var size:Vector2=texture.get_size()*factor
	c.draw_set_transform_matrix(base);c.draw_texture_rect(texture,Rect2(rect.get_center()-size*.5,size),false,tint);return true
static func stock_icon(item:Dictionary) -> String:
	if item["kind"]=="weapon":return Icons.secondary(Data.secondary_attack(int(item["value"])))
	var rune:Dictionary=Data.all_runes()[int(item["value"])];return Icons.rune(str(rune["id"]),bool(rune.get("strong",false)))
static func secondary(c:CanvasItem,weapon:Dictionary,at:Vector2,face:float,base:Transform2D) -> bool:
	var clip:String=Icons.secondary(weapon);var local:Transform2D=base*Transform2D(-.3*face,Vector2(face,1),0,at+Vector2(face*21,-28))
	var result:bool=draw_icon(c,clip,Rect2(-27,-23,54,46),local);c.draw_set_transform_matrix(base);return result
