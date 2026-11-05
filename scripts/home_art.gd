class_name PigeonHomeArt
extends RefCounted
const ROOT="res://assets/home_v13/"
const LEFT_GATE:=Rect2(80,315,240,285)
const RIGHT_GATE:=Rect2(960,315,240,285)
# Default pogo + air jump reaches feet Y=42 against the nest ceiling.
const ROGUE_PLATFORM_Y:float=64.44+50.0
const ROGUE_PLATFORM:=Rect2(505,ROGUE_PLATFORM_Y,270,9)
const ROGUE_GATE:=Rect2(520,ROGUE_PLATFORM_Y-285,240,285)
const PROJECTION_SCREEN:=Rect2(444,248,390,128)
const STATION_SINK:=Vector2(0,10)
const CEILING_Y:float=-260.0
const STATIONS={"musou":Vector2(200,600),"tutorial":Vector2(1080,600),"rogue":Vector2(640,ROGUE_PLATFORM_Y),"trophy":Vector2(925,600),"records":Vector2(790,600),"exit":Vector2(72,600)}
const STATION_ATLAS=preload("res://assets/v63/home/stations.webp")
static var textures:Dictionary={}
static func texture(id:String) -> Texture2D:
	if not textures.has(id):
		if id=="background":textures[id]=preload("res://scripts/scene_art_v33.gd").texture("res://assets/v33/home/background.png")
		elif id=="nest":textures[id]=preload("res://scripts/scene_art_v33.gd").texture("res://assets/v34/home/nest.png")
		elif id in ["musou","rogue"]:textures[id]=preload("res://scripts/scene_art_v33.gd").region("res://assets/v33/home/props.json",id)
		else:textures[id]=load(ROOT+id+".png")
	return textures[id]
static func background(c:CanvasItem,camera_y:float=0.0) -> void:
	preload("res://scripts/home_visual_v33.gd").background(c,camera_y)
static var openings:Dictionary={}

static func gates(c:CanvasItem,time:float,reduced:bool,base:Transform2D) -> void:
	c.draw_set_transform_matrix(base)
	var home_visual=preload("res://scripts/home_visual_v33.gd")
	for entry:Array in [["rogue",ROGUE_GATE],["musou",LEFT_GATE],["rogue",RIGHT_GATE]]:
		var box:Rect2=entry[1]
		var feet:=Vector2(box.get_center().x,box.end.y)
		_draw_opening(c,feet,Vector2(95,147),time+feet.x*.002,reduced)
		home_visual.gate(c,entry[0],feet+STATION_SINK,base)
	preload("res://scripts/terrain_art_v24.gd").platform(c,"trunk",ROGUE_PLATFORM)

static func falling_mote(feet:Vector2,size:Vector2,time:float,index:int) -> Vector2:
	var x:float=(fposmod(index*.6180339,1.0)-.5)*size.x*.70+sin(time*1.6+index*2.4)*size.x*.10
	var half:float=size.x*.5
	var top:float=feet.y-size.y*.67-size.y*.33*sqrt(1.0-pow(x/half,2))
	var progress:float=fposmod(index*.7548777+time*(.15+float(index%4)*.035),1.0)
	return Vector2(feet.x+x,lerpf(top+6,feet.y-4,progress))

static func _draw_opening(c:CanvasItem,feet:Vector2,size:Vector2,time:float,reduced:bool) -> void:
	if not openings.has(feet):
		var arch:=PackedVector2Array([feet+Vector2(-size.x*.5,0)])
		for step in 17:
			var angle:float=PI+PI*float(step)/16.0
			arch.append(feet+Vector2(cos(angle)*size.x*.5,-size.y*.67+sin(angle)*size.y*.33))
		arch.append(feet+Vector2(size.x*.5,0))
		openings[feet]=arch
	c.draw_colored_polygon(openings[feet],Color.BLACK)
	var count:int=17 if reduced else 32
	for index in count:
		var at:Vector2=falling_mote(feet,size,time,index)
		var tint:=Color(1,1,1,.53+float(index%4)*.13)
		c.draw_circle(at,1.1 if index%4 else 1.55,tint)
		if index%4==0:
			for arm in 3:
				var offset:=Vector2.from_angle(time*.32+arm*PI/3.0)*2.8
				c.draw_line(at-offset,at+offset,tint,.8,true)

static func station_light(c:CanvasItem,at:Vector2,tint:Color=Color("ffdf9a")) -> void:
	var glow:=Color(tint,.30)
	var clear:=Color(tint,0)
	c.draw_polygon(PackedVector2Array([at+Vector2(-24,0),at+Vector2(24,0),at+Vector2(66,-108),at+Vector2(-66,-108)]),PackedColorArray([glow,glow,clear,clear]))
	c.draw_line(at+Vector2(-24,-1),at+Vector2(24,-1),Color(tint,.88),3,true)

static func fixture(c:CanvasItem,index:int,feet:Vector2,size:Vector2,tint:Color=Color.WHITE) -> void:
	c.draw_texture_rect_region(STATION_ATLAS,Rect2(feet-Vector2(size.x*.5,size.y),size),Rect2(index*160,0,160,144),tint)

static func lamp_center(lamp:Dictionary,time:float) -> Vector2:
	if not lamp.get("used",false):return Vector2(lamp["pos"])+Vector2(0,sin(time*2.4)*5)
	var elapsed:float=time-float(lamp["broken_at"])
	return Vector2(lamp["break_origin"])+Vector2(0,minf(580.0-float(lamp["break_origin"].y),480.0*elapsed*elapsed))

static func nest(c:CanvasItem) -> void:
	c.draw_texture_rect(texture("nest"),Rect2(510,532,260,100),false)

static func resting(c:CanvasItem,time:float,waking:float,base:Transform2D) -> void:
	if waking<0 and preload("res://scripts/pigeon_motion_v22.gd").draw_drowsy(c,Vector2(640,588),1.0,6.0+time,base,Color.WHITE):return
	var tex:Texture2D=texture("sleep");var index:int=0 if waking<0 else mini(3,1+int((1-waking/.48)*3))
	var regions=[Rect2(43,339,500,238),Rect2(543,301,531,274),Rect2(1122,132,495,458),Rect2(1657,178,477,406)]
	var region:Rect2=regions[index];var size:Vector2=region.size*.14
	var at:=Vector2(640,588 if index<2 else 600)
	at.y+=sin(time*1.8)*.5 if index==0 else 0
	c.draw_texture_rect_region(tex,Rect2(at-Vector2(size.x*.5,size.y),size),region)

static func gate_at(point:Vector2) -> String:
	if LEFT_GATE.has_point(point):return "musou"
	if RIGHT_GATE.has_point(point):return "tutorial"
	if ROGUE_GATE.has_point(point):return "rogue"
	return ""
