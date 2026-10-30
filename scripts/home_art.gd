class_name PigeonHomeArt
extends RefCounted
const ROOT="res://assets/home_v13/"
const LEFT_GATE:=Rect2(80,315,240,285)
const RIGHT_GATE:=Rect2(960,315,240,285)
static var textures:Dictionary={}
static func texture(id:String) -> Texture2D:
	if not textures.has(id):
		if id=="background":textures[id]=preload("res://scripts/scene_art_v33.gd").texture("res://assets/v33/home/background.png")
		elif id=="nest":textures[id]=preload("res://scripts/scene_art_v33.gd").texture("res://assets/v34/home/nest.png")
		elif id in ["musou","rogue"]:textures[id]=preload("res://scripts/scene_art_v33.gd").region("res://assets/v33/home/props.json",id)
		else:textures[id]=load(ROOT+id+".png")
	return textures[id]
static func background(c:CanvasItem) -> void:
	preload("res://scripts/home_visual_v33.gd").background(c)
static func gates(c:CanvasItem,time:float,player:Vector2) -> void:
	for entry in [["musou",LEFT_GATE,Color("ffd887")],["rogue",RIGHT_GATE,Color("9cdcf3")]]:
		var box:Rect2=entry[1];var near:bool=absf(player.x-box.get_center().x)<100
		preload("res://scripts/home_visual_v33.gd").gate(c,str(entry[0]),Vector2(box.get_center().x,600))
		if near:
			var center:=Vector2(box.get_center().x,box.end.y-85)
			for i in 6:
				var t:float=fposmod(time*.8+i/6.0,1)
				c.draw_circle(center+Vector2(sin(i*2.4)*25,-t*100),1.5,Color(entry[2],sin(t*PI)*.5))
static func nest(c:CanvasItem,front:bool=false) -> void:
	var tex:Texture2D=texture("nest");var box:=Rect2(510,532,260,100)
	if front:
		var fraction:float=.70
		c.draw_texture_rect_region(tex,Rect2(box.position+Vector2(0,box.size.y*fraction),Vector2(box.size.x,box.size.y*(1-fraction))),Rect2(0,tex.get_height()*fraction,tex.get_width(),tex.get_height()*(1-fraction)))
	else:c.draw_texture_rect(tex,box,false)
static func resting(c:CanvasItem,time:float,waking:float) -> void:
	var tex:Texture2D=texture("sleep");var index:int=0 if waking<0 else mini(3,1+int((1-waking/.48)*3))
	var regions=[Rect2(43,339,500,238),Rect2(543,301,531,274),Rect2(1122,132,495,458),Rect2(1657,178,477,406)]
	var region:Rect2=regions[index];var size:Vector2=region.size*.14
	var at:=Vector2(640,588 if index<2 else 600)
	at.y+=sin(time*1.8)*.5 if index==0 else 0
	c.draw_texture_rect_region(tex,Rect2(at-Vector2(size.x*.5,size.y),size),region)
