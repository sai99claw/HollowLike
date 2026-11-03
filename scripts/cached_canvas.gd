extends Node2D
var profiler:RefCounted
var profile_name:String="draw.actors"
## A retained CanvasItem command list. Only rebuild when its content changes.
var paint: Callable
var rebuilds: int = 0

func invalidate() -> void:
	queue_redraw()

func _draw() -> void:
	if profiler==null or not profiler.active:
		_paint_profiled_body();return
	var measured:int=Time.get_ticks_usec()
	_paint_profiled_body()
	profiler.span(profile_name,Time.get_ticks_usec()-measured)
func _paint_profiled_body() -> void:
	rebuilds += 1
	if paint.is_valid(): paint.call(self)
