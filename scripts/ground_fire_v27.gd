class_name GroundFireV27
extends RefCounted
static var texture:Texture2D
static func image() -> Texture2D:
	if texture==null:texture=load("res://assets/v27/fire/ground-flame.png")
	return texture
static func source_rect(time:float,size:Vector2) -> Rect2:
	var index:int=posmod(int(time*10),4);var ratio:Vector2=size/Vector2(2048,768)
	return Rect2(Vector2(index*512+8,288)*ratio,Vector2(496,354)*ratio)
static func draw(c:CanvasItem,hazard:Dictionary,time:float,base:Transform2D) -> void:
	var tex:Texture2D=image()
	if tex==null:return
	var width:float=float(hazard.get("size",140));var segment:float=minf(width,100);var count:int=maxi(1,int(ceil(width/segment)));var at:Vector2=hazard["pos"]
	c.draw_set_transform_matrix(base)
	c.draw_line(at-Vector2(width*.5,1),at+Vector2(width*.5,-1),Color("5b2519"),5,true)
	for i in count:
		var extent:Vector2=Vector2(width/count+8,(width/count+8)*354/496)
		var center:Vector2=at+Vector2(-width*.5+(i+.5)*width/count,3)
		c.draw_texture_rect_region(tex,Rect2(center-Vector2(extent.x*.5,extent.y),extent),source_rect(time+i*.13,tex.get_size()),Color(1,1,1,minf(1,(float(hazard.get("lifetime",4))-float(hazard.get("elapsed",0)))*2)))
static func emit(hazard:Dictionary,effects:Array,delta:float,reduced:bool,limit:int) -> void:
	hazard["ember_clock"]=float(hazard.get("ember_clock",0))+delta
	var interval:float=.12 if reduced else .05
	if float(hazard["ember_clock"])<interval:return
	hazard["ember_clock"]=fmod(float(hazard["ember_clock"]),interval)
	if effects.size()>=limit:return
	var phase:float=float(hazard.get("elapsed",0));var width:float=float(hazard.get("size",140))
	var side:float=sin(phase*31.7+Vector2(hazard["pos"]).x)*.45
	effects.append({"pos":Vector2(hazard["pos"])+Vector2(side*width,-8),"vel":Vector2(sin(phase*13)*15,-44-absf(side)*65),"life":.55,"max":.55,"radius":2.8 if reduced else 3.5,"color":Color("ffc16b"),"ring":false,"fire_ember":true})
