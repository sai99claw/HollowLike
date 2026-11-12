extends Node2D
const Ink=preload("res://scripts/enemy_ink_v74.gd")
var toon:bool=false
var ink_sprite:Sprite2D
var ink_material:ShaderMaterial
static var flat_ink:ShaderMaterial
static var flash_ink:ShaderMaterial
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
func draw_ink_sprite(texture:Texture2D,anchor:Vector2,source:Rect2,pose:Transform2D,tint:Color) -> void:
	if ink_sprite==null:
		ink_sprite=Sprite2D.new()
		ink_sprite.name="ToonSilhouette"
		ink_sprite.centered=false
		ink_sprite.region_enabled=true
		ink_material=ShaderMaterial.new()
		ink_material.shader=Ink.SHADER
		ink_material.set_shader_parameter("padded_sprite",true)
		ink_sprite.material=ink_material
		add_child(ink_sprite)
	var pad:float=ceilf(6.0/maxf(.015,minf(pose.x.length(),pose.y.length())))
	ink_sprite.texture=texture
	ink_sprite.region_rect=Rect2(Vector2.ZERO,source.size+Vector2.ONE*2.0*pad)
	ink_sprite.transform=pose*Transform2D(0,-anchor-Vector2.ONE*pad)
	ink_sprite.self_modulate=tint
	ink_sprite.show()
	ink_material.set_shader_parameter("ink_texture",texture)
	ink_material.set_shader_parameter("source_rect",Vector4(source.position.x,source.position.y,source.size.x,source.size.y))
	ink_material.set_shader_parameter("padding",pad)
	ink_material.set_shader_parameter("hit_flash",1.0 if float(actor.get("flash_left",0))>0 else 0.0)

func refresh(base:Transform2D,enabled:bool,signature:Array=[]) -> void:
	transform=base*Transform2D(0,Vector2(actor.get("pos",Vector2.ZERO))) if local_origin else base;visible=enabled
	var flashing:bool=float(actor.get("flash_left",0))>0
	if toon:
		if flat_ink==null:
			flat_ink=ShaderMaterial.new()
			flat_ink.shader=Ink.SHADER
			flash_ink=flat_ink.duplicate()
			flash_ink.set_shader_parameter("hit_flash",1.0)
		material=flash_ink if flashing else flat_ink
		if ink_material!=null:ink_material.set_shader_parameter("hit_flash",1.0 if flashing else 0.0)
	else:material=white_ink if flashing else null
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
	if ink_sprite!=null:ink_sprite.hide()
	if local_origin:
		var local_actor:Dictionary=actor.duplicate(false);local_actor["pos"]=Vector2.ZERO;paint.call(self,local_actor)
	else:paint.call(self,actor)
