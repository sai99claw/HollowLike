extends Node2D
const LAUNCH:=Vector2(.78,1.25)
const LAND:=Vector2(1.28,.75)
var events:Array[Dictionary]=[]
var time:float=0.0
var reduced:bool=false

func _ready() -> void:
	z_index=4
	var glow:=CanvasItemMaterial.new()
	glow.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	glow.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material=glow

static func squash(actor:Dictionary,stretch:Vector2,now:float,duration:float) -> void:
	actor["juice_scale"]=stretch
	actor["juice_start"]=now
	actor["juice_duration"]=duration

static func pose(actor:Dictionary,now:float,idle:bool) -> Vector2:
	var age:float=now-float(actor.get("juice_start",-1.0))
	var duration:float=actor.get("juice_duration",0.0)
	if age>=0.0 and age<duration:
		var stretch:Vector2=actor["juice_scale"]
		return Tween.interpolate_value(stretch,Vector2.ONE-stretch,age,duration,Tween.TRANS_BACK,Tween.EASE_OUT)
	return Vector2(1,1+.03*sin(now*3.2+int(actor.get("uid",0))%47*.21)) if idle else Vector2.ONE

static func enemy_pose(actor:Dictionary,now:float) -> Transform2D:
	var attack=actor["attack"]
	var stretch:=pose(actor,now,attack.phase=="idle" and Vector2(actor.get("vel",Vector2.ZERO)).length_squared()<9)
	var lean:float=0.0
	var face:float=actor["face"]
	if attack.phase=="windup":
		var build:float=smoothstep(0.0,1.0,attack.progress())
		lean=-face*deg_to_rad(13.0)*build
		stretch*=1+.12*build
	elif attack.phase=="active":
		lean=face*deg_to_rad(11.0)*lerpf(1,.33,attack.progress())
	elif attack.phase=="recovery":
		lean=face*deg_to_rad(4.0)*(1.0-attack.progress())
	return Transform2D(lean,stretch,0,Vector2.ZERO)

func flash(at:Vector2,dir:Vector2,now:float,kind:String="spark",extent:float=1.0) -> void:
	if events.size()>=24:events.pop_front()
	events.append({"at":at,"dir":dir.normalized(),"start":now,"kind":kind,"extent":extent})
	queue_redraw()

func update_view(base:Transform2D,now:float,low:bool) -> void:
	transform=base
	var active:bool=not events.is_empty()
	while not events.is_empty() and now-float(events[0]["start"])>.27:events.pop_front()
	if active and now!=time:queue_redraw()
	time=now
	reduced=low

func clear() -> void:
	events.clear()
	queue_redraw()

func _draw() -> void:
	for event:Dictionary in events:
		var age:float=maxf(0.0,time-float(event["start"]))
		var at:Vector2=event["at"]
		var dir:Vector2=event["dir"]
		if event["kind"]=="smear":
			if age<.15:
				var alpha:float=1.0-age/.15
				var angle:float=dir.angle()
				var radius:float=event["extent"]
				draw_arc(at,radius,angle-1.12,angle+1.12,24,Color(1,.61,.27,.20*alpha),16,true)
				draw_arc(at,radius,angle-.98,angle+.98,24,Color(1,.81,.51,.72*alpha),6,true)
				draw_arc(at,radius*.98,angle-.71,angle+.72,20,Color(1,.98,.90,.84*alpha),2,true)
			continue
		var dust:bool=event["kind"]=="dust"
		var opacity:float=clampf(1.0-age/.23,0,1)
		if opacity<=0.0:continue
		for i in ((6 if reduced else 8) if dust else (12 if reduced else 16)):
			var phase:float=fposmod(i*.618034,.999)
			var velocity:Vector2=dir.rotated((phase-.5)*(2.4 if dust else 1.55))*lerpf(100.0 if dust else 340.0,185.0 if dust else 675.0,fposmod(i*.38197,.999))
			var p:Vector2=at+velocity*(age+.008)+Vector2(0,230.0 if dust else 130.0)*age*age
			var axis:Vector2=velocity.normalized()*(1.7 if dust else 4.0+phase*4.0)*opacity
			var width:Vector2=axis.orthogonal()*.29
			var tint:Color=Color(.69,.48,.33,.30*opacity) if dust else Color(1,.65+phase*.3,.34+phase*.5,opacity)
			draw_colored_polygon(PackedVector2Array([p-axis,p-width,p+axis,p+width]),tint)

static func warning(canvas:CanvasItem,center:Vector2,progress:float) -> void:
	var opacity:float=smoothstep(.22,.75,progress)*(.65+.35*sin(progress*31.0))
	if opacity<=0.0:return
	for axis:Vector2 in [Vector2(0,11),Vector2(8,0)]:
		canvas.draw_line(center-axis,center+axis,Color(1,.58,.29,opacity*.35),4,true)
		canvas.draw_line(center-axis*.75,center+axis*.75,Color(1,.95,.73,opacity),1.5,true)
