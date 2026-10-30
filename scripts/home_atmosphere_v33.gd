class_name HomeAtmosphereV33
extends Node2D
const Art=preload("res://scripts/scene_art_v33.gd")
const Home=preload("res://scripts/home_visual_v33.gd")
const FX=preload("res://scripts/combat_visual.gd")
var particles:Array[CPUParticles2D]=[]
var active:bool=false
var focus_x:float=640
func _ready() -> void:
	z_index=6
	for near in [false,true]:
		for kind in ["leaf","white","black"]:
			var p:=CPUParticles2D.new();p.name=("Near" if near else "Far")+kind.capitalize();p.z_as_relative=false;p.z_index=5 if near else -16
			p.amount=12 if kind=="leaf" else 10;p.lifetime=20;p.preprocess=20;p.position=Vector2(640,-90)
			p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;p.emission_rect_extents=Vector2(690,160);p.local_coords=false
			p.texture=Art.region(Home.ROOT+"leaves.json",str(0 if near else 1)) if kind=="leaf" else FX.texture_for("death_feather_glow")
			p.direction=Vector2(.22,1);p.spread=35;p.gravity=Vector2(3,5);p.initial_velocity_min=15;p.initial_velocity_max=35
			p.angular_velocity_min=-40;p.angular_velocity_max=45
			p.scale_amount_min=.025 if kind=="leaf" else .045;p.scale_amount_max=.05 if kind=="leaf" else .08
			p.scale_amount_min*=1.4 if near else .65;p.scale_amount_max*=1.4 if near else .65
			p.color=Color(.44,.62,.45,.35 if near else .22) if kind=="leaf" else Color(.035,.045,.055,.36 if near else .22) if kind=="black" else Color(.92,.96,1,.32 if near else .20)
			add_child(p);particles.append(p)
	set_active(false)
func set_active(value:bool) -> void:
	active=value;visible=value;set_process(value)
	for p in particles:p.emitting=value;p.visible=value;p.process_mode=Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
func _process(_delta:float) -> void:queue_redraw()
func _draw() -> void:
	if not active:return
	var image:Texture2D=Art.texture(Home.ROOT+"framing.png")
	if image!=null:
		var size:Vector2=image.get_size()*(1320.0/image.get_width())
		draw_texture_rect(image,Rect2(Vector2(-20-(focus_x-640)*.025,-100),size),false,Color(.38,.50,.43,.65))
