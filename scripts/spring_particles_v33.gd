class_name SpringParticlesV33
extends Node2D
var bursts:Array[CPUParticles2D]=[]
var drop:GradientTexture2D
func _ready() -> void:
	drop=GradientTexture2D.new();drop.width=8;drop.height=12;drop.fill=GradientTexture2D.FILL_RADIAL
	drop.fill_from=Vector2(.5,.5);drop.fill_to=Vector2(1,.5)
	var ramp:=Gradient.new();ramp.offsets=PackedFloat32Array([0,.55,1]);ramp.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,.8),Color(1,1,1,0)]);drop.gradient=ramp
func splash(at:Vector2,biome:String,direction:Vector2=Vector2.UP) -> void:
	if bursts.size()>=12:return
	var p:=CPUParticles2D.new();p.name="WaterDroplets";p.position=at;p.texture=drop
	p.amount=18;p.lifetime=.72;p.one_shot=true;p.explosiveness=1;p.local_coords=true
	p.direction=(Vector2.UP+direction*.35).normalized();p.spread=68;p.gravity=Vector2(0,310)
	p.initial_velocity_min=65;p.initial_velocity_max=150;p.scale_amount_min=.12;p.scale_amount_max=.30
	p.color=Color("b2e8f2") if biome=="sky" else Color("a0e4ce") if biome=="trunk" else Color("e6d8b5")
	var fade:=Gradient.new();fade.offsets=PackedFloat32Array([0,.65,1]);fade.colors=PackedColorArray([Color.WHITE,Color.WHITE,Color(1,1,1,0)]);p.color_ramp=fade
	add_child(p);bursts.append(p);p.finished.connect(func()->void:bursts.erase(p);p.queue_free());p.emitting=true
func clear() -> void:
	for p in bursts:p.queue_free()
	bursts.clear()
