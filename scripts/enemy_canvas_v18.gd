extends Node2D
var profiler:RefCounted
var profile_name:String="draw.actors"
## Per-actor material keeps white flash out of weapons, text and other actors.
var paint:Callable
var actor:Dictionary
var local_origin:bool=false
var rebuilds:int=0
var last_signature:Array=[]
static var white_ink:ShaderMaterial
func _init() -> void:
	if white_ink==null:
		white_ink=ShaderMaterial.new()
		white_ink.shader=preload("res://shaders/hit_flash_v18.gdshader")
		white_ink.set_shader_parameter("white_amount",1.0)
func refresh(base:Transform2D,enabled:bool,signature:Array=[]) -> void:
	transform=base*Transform2D(0,Vector2(actor.get("pos",Vector2.ZERO))) if local_origin else base;visible=enabled
	# Ordinary actors use the default material, preserving texture batching.
	material=white_ink if float(actor.get("flash_left",0))>0 else null
	if enabled and (signature.is_empty() or signature!=last_signature):
		last_signature=signature.duplicate();queue_redraw()
func _draw() -> void:
	if profiler==null or not profiler.active:
		_paint_profiled_body();return
	var measured:int=Time.get_ticks_usec()
	_paint_profiled_body()
	profiler.span(profile_name,Time.get_ticks_usec()-measured)
func _paint_profiled_body() -> void:
	if not paint.is_valid():return
	rebuilds+=1
	if local_origin:
		var local_actor:Dictionary=actor.duplicate(false);local_actor["pos"]=Vector2.ZERO;paint.call(self,local_actor)
	else:paint.call(self,actor)
