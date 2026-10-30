class_name AmbientWildlife
extends Node2D
var kind:String="bird"
var flights:Array[Dictionary]=[]
var enabled:bool=false
var random:=RandomNumberGenerator.new()
var cooldown:float=3.0
var last_time:float=-1
var camera:Vector2=Vector2.ZERO
var zoom:float=1.0
var texture:Texture2D
var elapsed:float=0
func _ready() -> void:
	var mat:=ShaderMaterial.new();mat.shader=load("res://shaders/wildlife_blur.gdshader");mat.set_shader_parameter("blur_radius",22.0 if kind=="dragonfly" else 9.0);material=mat
static func depth_size(progress:float) -> float:return lerpf(1.0,.18,smoothstep(0,1,progress))
static func depth_alpha(progress:float) -> float:return (1-smoothstep(.45,1,progress))*.48
func configure(seed_value:int,active:bool) -> void:
	random.seed=seed_value;enabled=active;visible=active;flights.clear();last_time=-1
	cooldown=random.randf_range(2,5) if kind=="bird" else random.randf_range(4,8)
	queue_redraw()
func update_view(at:Vector2,magnification:float,time:float) -> void:
	camera=at;zoom=magnification
	var delta:float=0 if last_time<0 else clampf(time-last_time,0,.25)
	last_time=time
	if not enabled:return
	elapsed+=delta;cooldown-=delta
	if cooldown<=0:
		spawn_flight()
		cooldown=random.randf_range(9,17) if kind=="bird" else random.randf_range(12,22)
	for flight in flights:flight["age"]+=delta
	flights=flights.filter(func(f:Dictionary)->bool:return float(f["age"])<float(f["duration"]))
	queue_redraw()
func spawn_flight() -> void:
	if flights.size()>=2:return
	var left:bool=random.randf()<.5
	var start:=Vector2(-90 if left else 1370,random.randf_range(130,360))
	var finish:=Vector2(1370 if left else -90,start.y+random.randf_range(-65,65))
	if kind=="dragonfly":
		start=Vector2(random.randf_range(180,1100),790)
		finish=start+Vector2(random.randf_range(-240,240),-random.randf_range(300,510))
	flights.append({"age":0.0,"duration":random.randf_range(8,12) if kind=="bird" else random.randf_range(4,6),"start":start,"finish":finish,"camera":camera,"face":1.0 if finish.x>start.x else -1.0,"phase":random.randf()*TAU})
func point(flight:Dictionary) -> Vector2:
	var t:float=clampf(float(flight["age"])/float(flight["duration"]),0,1)
	var at:Vector2=Vector2(flight["start"]).lerp(flight["finish"],t)
	at.y+=sin(t*TAU*2+float(flight["phase"]))* (8 if kind=="bird" else 24)
	if kind=="dragonfly":at.x+=sin(t*TAU*3)*18
	return at-(camera-Vector2(flight["camera"]))*zoom*(.12 if kind=="bird" else 1.12)
func _draw() -> void:
	if not enabled:return
	if texture==null and ResourceLoader.exists("res://assets/atmosphere_v09/"+kind+".png"):texture=load("res://assets/atmosphere_v09/"+kind+".png")
	if texture==null:return
	for flight in flights:
		var t:float=float(flight["age"])/float(flight["duration"])
		var alpha:float=minf(1,minf(t*7,(1-t)*7))*(depth_alpha(t) if kind=="bird" else .23)
		var frame:int=int(float(flight["age"])*(7 if kind=="bird" else 22))%4
		var region:=Rect2(frame*texture.get_width()/4.0,0,texture.get_width()/4.0,texture.get_height())
		var width:float=86*depth_size(t) if kind=="bird" else 158
		var size:Vector2=Vector2(width,width*region.size.y/region.size.x)
		draw_set_transform(point(flight),0,Vector2(float(flight["face"]),1))
		draw_texture_rect_region(texture,Rect2(-size*.5,size),region,Color(.39,.45,.51,alpha) if kind=="bird" else Color(.015,.018,.02,alpha))
	draw_set_transform(Vector2.ZERO)
