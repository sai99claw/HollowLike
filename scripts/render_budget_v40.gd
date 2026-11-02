class_name RenderBudgetV40
extends RefCounted
## Bound WebGL fill cost on large/high-DPI displays; retain native HD output.
const WEB_SIZE:=Vector2i(1280,720)
static func region(view:Rect2) -> Rect2:
	# Retain a generous halo and change draw lists only across coarse cells.
	var start:Vector2=(view.position/384).floor()*384-Vector2.ONE*128
	var end:Vector2=(view.end/384).ceil()*384+Vector2.ONE*128
	return Rect2(start,end-start)
static func configure(window:Window,web:bool) -> void:
	if not web:return
	window.content_scale_size=WEB_SIZE
	window.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
