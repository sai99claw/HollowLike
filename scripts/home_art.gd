class_name PigeonHomeArt
extends RefCounted
const ROOT="res://assets/home_v13/"
const LEFT_GATE:=Rect2(80,315,240,285)
const RIGHT_GATE:=Rect2(960,315,240,285)
# Default pogo + air jump reaches feet Y=42 against the nest ceiling.
const ROGUE_PLATFORM_Y:float=64.44+50.0
const ROGUE_PLATFORM:=Rect2(505,ROGUE_PLATFORM_Y,270,9)
const ROGUE_GATE:=Rect2(600,ROGUE_PLATFORM_Y-78,80,78)
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
static var openings:Dictionary={}

static func gates(c:CanvasItem,time:float,reduced:bool) -> void:
	var home_visual=preload("res://scripts/home_visual_v33.gd")
	var top_feet:=Vector2(ROGUE_GATE.get_center().x,ROGUE_PLATFORM_Y)
	_draw_opening(c,top_feet,Vector2(29,44),time+.4,reduced)
	home_visual.prop(c,"rogue",top_feet,Vector2(61,78))
	c.draw_rect(ROGUE_PLATFORM,Color("393138"))
	c.draw_line(ROGUE_PLATFORM.position,Vector2(ROGUE_PLATFORM.end.x,ROGUE_PLATFORM.position.y),Color("c4a279"),3)
	for entry:Array in [["musou",LEFT_GATE],["rogue",RIGHT_GATE]]:
		var box:Rect2=entry[1]
		var feet:=Vector2(box.get_center().x,box.end.y)
		_draw_opening(c,feet,Vector2(95,147),time+(0.8 if entry[0]=="musou" else 0.0),reduced)
		home_visual.gate(c,entry[0],feet)

static func falling_mote(feet:Vector2,size:Vector2,time:float,index:int) -> Vector2:
	var x:float=(fposmod(index*.6180339,1.0)-.5)*size.x*.85
	var half:float=size.x*.5
	var top:float=feet.y-size.y*.67-size.y*.33*sqrt(1.0-pow(x/half,2))
	var progress:float=fposmod(index*.7548777+time*(.29+float(index%4)*.055),1.0)
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
	var count:int=7 if size.x<40 else (14 if reduced else 25)
	for index in count:
		var at:Vector2=falling_mote(feet,size,time,index)
		var tint:=Color(1,1,1,.53+float(index%4)*.13)
		c.draw_line(at-Vector2(0,2+index%4),at,tint,1.1,true)
		c.draw_circle(at,1.1 if index%4 else 1.55,tint)

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

static func gate_at(point:Vector2) -> String:
	if LEFT_GATE.has_point(point):return "musou"
	if RIGHT_GATE.has_point(point):return "tutorial"
	if ROGUE_GATE.has_point(point):return "rogue"
	return ""

static var focus_frames:Dictionary={}

static func draw_gate_focus(canvas:CanvasItem,gate:String,pressed:bool) -> void:
	var bounds:Rect2={"musou":LEFT_GATE,"tutorial":RIGHT_GATE,"rogue":ROGUE_GATE}[gate]
	var key:String=gate+str(pressed)
	if not focus_frames.has(key):
		var accent:Color={"musou":Color("f2cc7d"),"tutorial":Color("a2edc6"),"rogue":Color("a8cef6")}[gate]
		var frame:=StyleBoxFlat.new()
		frame.bg_color=Color.TRANSPARENT
		frame.border_color=accent
		frame.set_corner_radius_all(20)
		frame.set_border_width_all(4 if pressed else 3)
		frame.shadow_color=Color(accent,.48)
		frame.shadow_size=3 if pressed else 8
		focus_frames[key]=frame
	canvas.draw_style_box(focus_frames[key],bounds.grow(-4 if pressed else 0))
