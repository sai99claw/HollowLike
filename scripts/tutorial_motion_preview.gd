extends Control

const Art=preload("res://scripts/art.gd")
const Slash=preload("res://scripts/slash_art_v18.gd")
const Flap=preload("res://scripts/double_jump_v27.gd")
const PigeonBurst=preload("res://scripts/pigeon_burst_v72.gd")
const AdventurePose=preload("res://scripts/adventure_visual.gd")
const Wind=preload("res://scripts/wind_art.gd")
const Weapon=preload("res://scripts/weapon_art_v24.gd")
const READY_TIME:float=.55

var lesson:Dictionary={}
var clock:float=0.0
var timing:Label
var weapon_id:String

func _init() -> void:
	custom_minimum_size=Vector2(320,220)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true

func select_lesson(value:Dictionary) -> void:
	lesson=value
	clock=0.0
	_refresh_timing()
	queue_redraw()

func _process(delta:float) -> void:
	if lesson.is_empty() or not is_visible_in_tree():return
	var duration:float=lesson["duration"]
	clock=fposmod(clock+delta,duration)
	_refresh_timing()
	queue_redraw()

func _refresh_timing() -> void:
	var label:String="準備"
	for event:Array in lesson["events"]:
		if clock<float(event[0]):break
		label=str(event[1])
	timing.text=label

func _draw() -> void:
	if lesson.is_empty():return
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b1e20"))
	var floor_y:float=size.y-34.0
	draw_line(Vector2(14,floor_y),Vector2(size.x-14,floor_y),Color("4d7665"),2,true)
	var at:=Vector2(size.x*.30,floor_y)
	var t:float=clock-READY_TIME
	var action:String=lesson["id"]
	var anim:String="idle"
	var progress:float=0.0
	var direction:=Vector2.RIGHT
	var attack:Dictionary={}
	var slash_box:=Rect2()
	if t>=0:
		match action:
			"jump","double_jump":
				var twice:bool=action=="double_jump"
				var ascent:float=t/.68
				if twice and t>=.30:
					var second:float=clampf((t-.30)/.84,0,1)
					at.y-=lerpf(sin(.30/.68*PI)*74,0,second)+sin(second*PI)*62
				else:at.y-=sin(clampf(ascent,0,1)*PI)*74
				anim="jump_up" if (t<.31 or (twice and t>=.30 and t<.60)) else "jump_down"
				if at.y>=floor_y-1:anim="idle"
				if twice and t>=.30:
					var origin:=Vector2(at.x,floor_y-sin(.30/.68*PI)*74-18)
					PigeonBurst.draw(self,PigeonBurst.IMPULSE,origin,Vector2.DOWN,t-.30,PigeonBurst.IMPULSE_DURATION,110.0,Transform2D.IDENTITY)
				if twice and t>=.30 and t<.58:
					Flap.draw(self,at,1.0,t-.30,Transform2D.IDENTITY,Color.WHITE)
					_draw_timeline()
					return
				if anim=="jump_up":
					AdventurePose.draw_jump(self,t,at,1,Transform2D.IDENTITY,Color.WHITE)
					_draw_timeline()
					return
			"dash","pierce":
				PigeonBurst.draw(self,PigeonBurst.IMPULSE,at-Vector2(12,24),Vector2.LEFT,t,PigeonBurst.IMPULSE_DURATION,110.0,Transform2D.IDENTITY)
				at.x+=minf(t/.16,1)*size.x*.14
				if t<.16:
					Flap.draw(self,at,1.0,t*2.0,Transform2D.IDENTITY,Color.WHITE)
					_draw_timeline()
					return
				if action=="pierce" and t>=.24:
					at.x+=clampf((t-.24)/.46,0,1)*size.x*.29
					if t<.70:
						AdventurePose.draw_action(self,2,1,at,direction.x,Transform2D.IDENTITY,Color.WHITE)
						Wind.wind_form(self,at-AdventurePose.WIND_BODY_CENTER,direction,t-.24,.46,Transform2D.IDENTITY)
						_draw_timeline()
						return
			"slam":
				at.y-=96*clampf(1-pow(maxf(0,t-.24)/.39,2),0,1)
				anim="jump_down" if at.y<floor_y else "land"
				if t>=.24 and t<.63:
					AdventurePose.draw_action(self,3,AdventurePose.slam_frame(t-.24),at,1,Transform2D.IDENTITY,Color.WHITE)
					Wind.wind_form(self,at-AdventurePose.WIND_BODY_CENTER,Vector2.DOWN,t-.24,.39,Transform2D.IDENTITY,true)
					_draw_timeline()
					return
				if t>=.63 and t<.91:
					Wind.impact(self,at,(t-.63)/.28,Transform2D.IDENTITY)
					if t<.755:
						AdventurePose.draw_action(self,3,3,at,1,Transform2D.IDENTITY,Color.WHITE)
						_draw_timeline()
						return
			"attack","down_attack","charged":
				var release:float=lesson.get("hold",0.0)
				var elapsed:float=t-release
				if action=="down_attack":
					at.y-=78.0*clampf(1.0-t/.66,0,1)
					direction=Vector2.DOWN
				if elapsed<0:
					anim="charge"
					draw_arc(at-Vector2(0,25),37,0,TAU*clampf(t/release,0,1),32,Color("98e5c6"),2,true)
				elif elapsed<.44:
					anim="active";progress=elapsed/.44
					attack={"direction":"down" if action=="down_attack" else "right","great_spin_release":action=="charged"}
					slash_box=Rect2(at+Vector2(-29,-8),Vector2(58,82)) if action=="down_attack" else Rect2(at+Vector2(7,-58),Vector2(103,57))
					if action!="charged":attack["wing_pose"]=3 if action=="down_attack" else 0
			"sub":
				if t<.85:
					var origin:Vector2=at-Vector2(0,26)
					var tip:Vector2=origin+direction*size.x*.43*(t/.85)
					Weapon.draw(self,weapon_id,tip,direction,14,true,Transform2D.IDENTITY,t)
	Art.draw_pigeon(self,at,1,clock,anim,Color.WHITE,1.0,progress,Transform2D.IDENTITY,"quick",attack)
	if slash_box.has_area():
		if attack.has("wing_pose"):Slash.draw_straight(self,slash_box.get_center(),attack["direction"],progress,size.x,Transform2D.IDENTITY)
		else:Slash.draw(self,slash_box,attack,progress,Transform2D.IDENTITY)
	_draw_timeline()

func _draw_timeline() -> void:
	var width:float=size.x-32.0
	var y:float=size.y-15.0
	var duration:float=lesson["duration"]
	draw_line(Vector2(16,y),Vector2(16+width,y),Color("34544f"),3,true)
	for event:Array in lesson["events"]:
		var x:float=16+width*float(event[0])/duration
		draw_line(Vector2(x,y-5),Vector2(x,y+5),Color("e8c381"),2,true)
	draw_circle(Vector2(16+width*clock/duration,y),4,Color("e9f8e8"))
