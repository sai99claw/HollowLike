extends Node2D

const FX=preload("res://scripts/combat_visual.gd")
const LIMIT:int=64
const BURST_TIME:float=.13
const SHARD_SCALE:float=2.0
var shards:Array[Dictionary]=[]
var rng:=RandomNumberGenerator.new()
var texture:Texture2D
var world_to_screen:Transform2D
var target:Vector2

func _ready() -> void:
	texture=FX.texture_for("death_feather_glow")

func burst(origin:Vector2,direction:Vector2,base:Transform2D,reduced:bool) -> void:
	world_to_screen=base
	for i in (5 if reduced else 9):
		if shards.size()>=LIMIT:shards.pop_front()
		var velocity:=direction.rotated(rng.randf_range(-1.2,1.2))*rng.randf_range(200.0,470.0)
		shards.append({"origin":origin,"velocity":velocity,"age":0.0,
			"duration":rng.randf_range(.38,.56),"size":rng.randf_range(9.0,18.0)*SHARD_SCALE,
			"spin":rng.randf_range(-12.0,12.0)})
	queue_redraw()

func step(delta:float,base:Transform2D,hud_target:Vector2) -> void:
	if shards.is_empty():return
	world_to_screen=base
	target=hud_target
	for i in range(shards.size()-1,-1,-1):
		shards[i]["age"]+=delta
		if float(shards[i]["age"])>=float(shards[i]["duration"]):shards.remove_at(i)
	queue_redraw()

func clear() -> void:
	shards.clear()
	queue_redraw()

func _draw() -> void:
	if texture==null:return
	for shard:Dictionary in shards:
		var age:float=shard["age"]
		var travel:float=minf(age,BURST_TIME)
		var velocity:Vector2=shard["velocity"]
		var at:Vector2=world_to_screen*(Vector2(shard["origin"])+velocity*travel*(1.0-travel*2.2))
		var t:float=clampf((age-BURST_TIME)/(float(shard["duration"])-BURST_TIME),0.0,1.0)
		if t>0.0:
			var bend:Vector2=(world_to_screen.basis_xform(velocity)).normalized()*72.0
			at=at.lerp(target,pow(t,2.4))+bend*sin(t*PI)*.26
		var size:float=float(shard["size"])*lerpf(1.0,.34,t)
		var tint:=Color(1.0,.87,.73,1.0-t*.55)
		draw_set_transform(at,velocity.angle()+float(shard["spin"])*age)
		draw_texture_rect(texture,Rect2(Vector2(-.5,-.5)*size,Vector2.ONE*size),false,tint)
	draw_set_transform(Vector2.ZERO)
