extends SceneTree
## Regression for the self-crossing animated wing which flooded the renderer.
func _initialize() -> void:
	for i in 2001:
		var wing:float=-1.1+float(i)/2000.0*2.0
		var tip:Vector2=Vector2(-10+wing*13,-8-absf(wing)*8)
		var polygon:PackedVector2Array=PackedVector2Array([Vector2(-7,-28),Vector2(5,-22),tip+Vector2(5,2),tip+Vector2(-4,0)])
		if Geometry2D.triangulate_polygon(polygon).size()!=6:
			push_error("Wing triangulation failed at "+str(wing));quit(1);return
	print("Animated wing: all 2001 flap positions triangulate")
	quit()
