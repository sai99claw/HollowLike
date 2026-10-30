extends Button
func _draw() -> void:
	var center:Vector2=Vector2(size.x*.5,57)
	draw_circle(center,43,Color("081614"))
	draw_arc(center,43,0,TAU,64,Color("739d8a"),2,true)
	draw_arc(center,37,0,TAU,64,Color("293e37"),1,true)
	for i in 4:
		var direction:Vector2=Vector2.from_angle(i*PI*.5)
		draw_line(center+direction*45,center+direction*50,Color("d2b680"),2,true)
