class_name DreamVisualV41
extends Node2D
const FX=preload("res://scripts/combat_visual.gd")
var middle_bubbles:CPUParticles2D
var front_bubbles:CPUParticles2D
var rage:CPUParticles2D
var vignette:ColorRect
var waves:Array[Dictionary]=[]
var world:Transform2D=Transform2D.IDENTITY
var enabled:bool=true
func _ready() -> void:
	var texture:=GradientTexture2D.new();texture.width=64;texture.height=64;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5)
	var rim:=Gradient.new();rim.offsets=PackedFloat32Array([0,.68,.80,.90,1]);rim.colors=PackedColorArray([Color(1,1,1,0),Color(1,1,1,0),Color(.7,.9,1,.25),Color(.9,1,1,.8),Color(1,1,1,0)]);texture.gradient=rim
	for front in [false,true]:
		var bubble:=CPUParticles2D.new();bubble.name="DreamFrontBubbles" if front else "DreamMiddleBubbles"
		bubble.texture=texture;bubble.z_index=6 if front else -13;bubble.z_as_relative=false;bubble.position=Vector2(640,850)
		bubble.amount=12 if front else 18;bubble.lifetime=12;bubble.preprocess=8;bubble.local_coords=true
		bubble.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;bubble.emission_rect_extents=Vector2(740,150)
		bubble.direction=Vector2.UP;bubble.spread=12;bubble.gravity=Vector2(0,-2);bubble.initial_velocity_min=40 if front else 22;bubble.initial_velocity_max=70 if front else 42
		bubble.scale_amount_min=.35 if front else .12;bubble.scale_amount_max=.75 if front else .35;bubble.modulate=Color(.78,.87,1,.22 if front else .15)
		var fade:=Gradient.new();fade.offsets=PackedFloat32Array([0,.15,.8,1]);fade.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)]);bubble.color_ramp=fade
		add_child(bubble)
		if front:front_bubbles=bubble
		else:middle_bubbles=bubble
	rage=CPUParticles2D.new();rage.name="DreamRageAura";rage.z_index=3;rage.z_as_relative=false
	rage.texture=preload("res://scripts/adventure_art_v29.gd").feather_texture();rage.amount=28;rage.lifetime=.7;rage.local_coords=false
	rage.emission_shape=CPUParticles2D.EMISSION_SHAPE_SPHERE;rage.emission_sphere_radius=23;rage.direction=Vector2.UP;rage.spread=35;rage.gravity=Vector2(0,-45);rage.initial_velocity_min=25;rage.initial_velocity_max=65
	var extent:float=maxf(rage.texture.get_width(),rage.texture.get_height());rage.scale_amount_min=5/extent;rage.scale_amount_max=11/extent
	var fade:=Gradient.new();fade.colors=PackedColorArray([Color(.5,.7,1,.8),Color(.9,.5,1,0)]);rage.color_ramp=fade;add_child(rage)
	vignette=ColorRect.new();vignette.name="DreamVignette";vignette.z_index=8;vignette.z_as_relative=false;vignette.size=Vector2(1280,720);vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material:=ShaderMaterial.new();material.shader=preload("res://shaders/player_focus.gdshader");material.set_shader_parameter("darkness",.48);vignette.material=material;add_child(vignette)
	set_view(false,Transform2D.IDENTITY,Vector2.ZERO,false,true)
func set_view(active:bool,base:Transform2D,at:Vector2,raging:bool,frozen:bool=false,speed:float=1) -> void:
	if not active and not enabled:return
	enabled=active;world=base;visible=active
	for bubble in [middle_bubbles,front_bubbles]:
		bubble.visible=active;bubble.emitting=active;bubble.speed_scale=0 if frozen else speed;bubble.process_mode=Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	rage.visible=active and raging;rage.emitting=rage.visible;rage.position=base*(at-Vector2(0,24));rage.speed_scale=0 if frozen else speed;rage.process_mode=Node.PROCESS_MODE_INHERIT if rage.visible else Node.PROCESS_MODE_DISABLED
	vignette.visible=active;vignette.material.set_shader_parameter("focus",(base*(at-Vector2(0,24)))/Vector2(1280,720))
func clear_waves() -> void:waves.clear();queue_redraw()
func body_progress() -> float:
	for i in range(waves.size()-1,-1,-1):
		if not waves[i]["injury"]:return clampf(float(waves[i]["age"])/float(waves[i]["duration"]),0,1)
	return -1.0
func pulse(at:Vector2,radius:float,injury:bool=false,damage:float=0) -> void:
	if waves.size()>=8:waves.pop_front()
	waves.append({"pos":at,"radius":radius,"age":0.0,"duration":.6,"injury":injury,"damage":damage,"hits":{}});queue_redraw()
func step(delta:float) -> void:
	if waves.is_empty():return
	for wave:Dictionary in waves:wave["age"]+=delta
	waves=waves.filter(func(wave:Dictionary)->bool:return float(wave["age"])<=float(wave["duration"]))
	queue_redraw()
func _draw() -> void:
	if not enabled:return
	for wave:Dictionary in waves:
		var progress:float=clampf(float(wave["age"])/float(wave["duration"]),0,1)
		var radius:float=float(wave["radius"])*(.15+.85*progress)
		if wave["injury"]:
			draw_set_transform_matrix(world)
			draw_circle(wave["pos"],radius,Color(.55,.7,1,(1-progress)*.10))
			for i in 3:draw_arc(wave["pos"],radius*(1-float(i)*.08),0,TAU,64,Color(.65,.8,1,(1-progress)*(.8-i*.18)),4-i,true)
		else:
			FX.fitted(self,"feather_charge",progress,Rect2(Vector2(wave["pos"])-Vector2.ONE*radius,Vector2.ONE*radius*2),world,"right","active",Color(.8,.9,1,1-progress*.5))
	draw_set_transform_matrix(Transform2D.IDENTITY)
