extends RefCounted
const SHADER=preload("res://shaders/enemy_toon_outline.gdshader")

static func draw_frame(canvas:CanvasItem,texture:Texture2D,anchor:Vector2,source:Rect2,pose:Transform2D,tint:Color) -> bool:
	if texture==null or not canvas.has_method("draw_ink_sprite") or not canvas.get("toon"):return false
	canvas.draw_ink_sprite(texture,anchor,source,pose,tint)
	return true
