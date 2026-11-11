class_name AdventureVisual
extends RefCounted
const FX=preload("res://scripts/combat_visual.gd")
static var owl:Texture2D
static var actions:Texture2D
static var portal_dot:GradientTexture2D
const FEATHER_SIZE:=Vector2(120,80)
const FEATHER_BOB:float=6.0
const NEW_MOTION=preload("res://assets/v68/pigeon_motion.webp")
const MOTION_CELL:=Vector2(288,288)
const MOTION_PIVOT:=Vector2(155,237)
const JUMP_FPS:float=30.0
const JUMP_SEQUENCE=[1,2]
const LIMPS=preload("res://assets/v70/pigeon_limp.webp")
const GLIDE=preload("res://assets/v70/pigeon_glide.webp")
const LIMP_CELL:=Vector2(330,256)
const WIND_BODY_CENTER:=Vector2(0,22)
const SLAM_FRAMES=[0,1,2,2,2,2,2,2,2]
const SLAM_FPS:float=24.0
const ACTION_REGIONS=[[[20,105,259,211],[346,87,251,230],[656,63,258,254],[969,69,240,248]],[[25,423,266,220],[335,417,274,218],[648,426,289,212],[967,421,279,217]],[[19,715,297,178],[312,714,317,144],[625,736,317,118],[938,713,303,168]],[[69,922,196,250],[408,921,143,279],[720,914,222,302],[938,1026,299,165]]]
static func portal_mote(at:Vector2,time:float,index:int) -> Dictionary:
	var t:float=fposmod(time/8.0+index*.6180339,1)
	var angle:float=index*2.39996
	var radius:float=(160+fposmod(index*79.0,300))*pow(1-t,.85)
	var center:Vector2=at-Vector2(0,38)
	return {"pos":center+Vector2(cos(angle),sin(angle)*.7)*radius,"alpha":sin(t*PI)*.24,"radius":radius,"progress":t}
static func portal(c:CanvasItem,at:Vector2,color:Color,time:float,base:Transform2D,_biome:String,direction:String="left",opening:float=64,reduced:bool=false) -> void:
	var center:Vector2=at-Vector2(0,opening*.5) if direction in ["left","right"] else at
	if portal_dot==null:
		var fade:=Gradient.new()
		fade.offsets=PackedFloat32Array([0.0,.37,.48,.72,1.0])
		fade.colors=PackedColorArray([Color.WHITE,Color.WHITE,Color(1,1,1,.40),Color(1,1,1,.09),Color(1,1,1,0)])
		portal_dot=GradientTexture2D.new()
		portal_dot.width=32;portal_dot.height=32
		portal_dot.fill=GradientTexture2D.FILL_RADIAL
		portal_dot.fill_from=Vector2(.5,.5);portal_dot.fill_to=Vector2(1,.5)
		portal_dot.gradient=fade
	c.draw_set_transform_matrix(base)
	for i in (84 if reduced else 168):
		var mote:Dictionary=portal_mote(center+Vector2(0,38),time,i)
		var tint:Color=color.lerp(Color.WHITE,.25);tint.a=float(mote["alpha"])
		var radius:float=1+fposmod(i*.37,1.1)
		var extent:float=radius+1.8
		c.draw_texture_rect(portal_dot,Rect2(Vector2(mote["pos"])-Vector2.ONE*extent,Vector2.ONE*(extent*2)),false,tint)
	c.draw_set_transform_matrix(base)

static func dash(c:CanvasItem,at:Vector2,dir:Vector2,time:float,base:Transform2D,slam:bool=false) -> void:
	preload("res://scripts/wind_art.gd").wind_form(c,at-Vector2(0,22),dir,fposmod(time,.24),.24,base,slam)
static func chest(c:CanvasItem,at:Vector2,time:float,base:Transform2D,opened:bool) -> void:
	FX.fitted(c,"delivery_parcel",0,Rect2(at-Vector2(35,54),Vector2(70,54)),base)
	var lid:Vector2=at-Vector2(0,52+(12 if opened else 0))
	c.draw_line(lid-Vector2(32,0),lid+Vector2(32,0),Color("ab895a"),9,true)
	c.draw_line(at-Vector2(0,52),at-Vector2(0,3),Color("e8c97e"),4)
	c.draw_circle(at-Vector2(0,30),5,Color("ffecb6"))
	if not opened:
		for i in 4:c.draw_circle(at+Vector2(sin(time+i*2)*37,-25+cos(time*.9+i)*22),1.5,Color(1,.84,.45,.6))
static func merchant(c:CanvasItem,at:Vector2,time:float,base:Transform2D) -> void:
	if owl==null and ResourceLoader.exists("res://assets/adventure_v08/owl_merchant.png"):owl=load("res://assets/adventure_v08/owl_merchant.png")
	if owl==null:return
	var width:float=owl.get_width()/2.0;var height:float=owl.get_height()/2.0
	var frame:int=int(time*1.5)%4
	c.draw_texture_rect_region(owl,Rect2(at-Vector2(72,136),Vector2(144,144)),Rect2((frame%2)*width,(frame/2)*height,width,height))
	FX.fitted(c,"weapon_feather",0,Rect2(at+Vector2(70,-45),Vector2(50,45)),base)
static func feather(c:CanvasItem,at:Vector2,time:float,base:Transform2D) -> void:
	preload("res://scripts/adventure_art_v29.gd").death_feather(c,at,time,base)

static func player_action(c:CanvasItem,anim:String,attack:Dictionary,progress:float,at:Vector2,face:float,time:float,base:Transform2D,tint:Color,scale_value:float,walk_frame:int) -> bool:
	var kind:String=str(attack.get("kind",""))
	var special:bool=anim in ["windup","active","recovery"] and kind in ["pierce","slam"]
	if anim not in ["heal","limp","dash"] and not special:return false
	if anim=="limp":
		var region:=Rect2(Vector2(walk_frame%5,walk_frame/5)*LIMP_CELL,LIMP_CELL)
		_draw_sprite(c,LIMPS,region,Vector2(221,221),at,face,base,tint,.224*scale_value)
		return true
	var row:int=0 if anim=="heal" else (3 if special and kind=="slam" else 2)
	var index:int=int(time*5)%4
	if row==2:index=1
	elif row==3:index=3 if anim=="recovery" else mini(2,int(progress*3))
	draw_action(c,row,index,at,face,base,tint,scale_value)
	return true

static func draw_action(c:CanvasItem,row:int,index:int,at:Vector2,face:float,base:Transform2D,tint:Color,scale_value:float=1.0) -> void:
	if actions==null:actions=load("res://assets/adventure_v08/pigeon_actions.png")
	var raw:Array=ACTION_REGIONS[row][index]
	var region:=Rect2(raw[0],raw[1],raw[2],raw[3])
	var factor:float=sqrt(4.0/95.0)*scale_value
	var pivot:=Vector2(region.size.x*.65,region.size.y)
	var anchor:Vector2=at
	if row==2:pivot=region.size*.5;anchor-=WIND_BODY_CENTER
	if row==3 and index<3:
		pivot=region.size*.5
		anchor-=WIND_BODY_CENTER
	elif row==3:pivot.x=region.size.x*.6
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face*factor,factor),0,anchor))
	c.draw_texture_rect_region(actions,Rect2(-pivot,region.size),region,tint)
	c.draw_set_transform_matrix(base)

static func jump_frame(elapsed:float) -> int:
	return JUMP_SEQUENCE[clampi(int(elapsed*JUMP_FPS),0,JUMP_SEQUENCE.size()-1)]

static func slam_frame(elapsed:float) -> int:
	return SLAM_FRAMES[clampi(int(elapsed*SLAM_FPS),0,SLAM_FRAMES.size()-1)]

static func draw_jump(c:CanvasItem,elapsed:float,at:Vector2,face:float,base:Transform2D,tint:Color) -> void:
	var region:=Rect2(Vector2(jump_frame(elapsed),0)*MOTION_CELL,MOTION_CELL)
	_draw_sprite(c,NEW_MOTION,region,MOTION_PIVOT,at,face,base,tint,.224)

static func draw_glide(c:CanvasItem,at:Vector2,face:float,base:Transform2D,tint:Color) -> void:
	_draw_sprite(c,GLIDE,Rect2(Vector2.ZERO,GLIDE.get_size()),Vector2(280,241),at,face,base,tint,.224)

static func _draw_sprite(c:CanvasItem,texture:Texture2D,source:Rect2,pivot:Vector2,at:Vector2,face:float,base:Transform2D,tint:Color,factor:float) -> void:
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face*factor,factor),0,at))
	c.draw_texture_rect_region(texture,Rect2(-pivot,source.size),source,tint)
	c.draw_set_transform_matrix(base)

static func door_color(target:Dictionary,locked:bool=false) -> Color:
	if locked:return Color("ad9790")
	if target["type"]=="boss":return Color("ff4e56")
	if target["type"]=="reward":return Color("ffd35b")
	if target["type"] in ["start","merchant"] or target.get("spring",false):return Color("59ee91")
	return Color("bdcfdb")
