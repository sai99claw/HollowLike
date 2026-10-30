extends Node2D
## A retained CanvasItem command list. Only rebuild when its content changes.
var paint: Callable
var rebuilds: int = 0

func invalidate() -> void:
	queue_redraw()

func _draw() -> void:
	rebuilds += 1
	if paint.is_valid(): paint.call(self)
