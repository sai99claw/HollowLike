class_name DepthStyleV32
extends RefCounted
const FOG:Dictionary={"sky":Color("779fb2"),"trunk":Color("75947c"),"underground":Color("ac8762")}
static func material(biome:String,role:String,reduced:bool=false) -> ShaderMaterial:
	var result:=ShaderMaterial.new();result.shader=load("res://shaders/depth_grade_v32.gdshader")
	result.set_shader_parameter("fog_color",FOG.get(biome,FOG["trunk"]))
	result.set_shader_parameter("blur_radius",0.0 if reduced else (2.4 if role=="far" else 1.2))
	result.set_shader_parameter("saturation",.58 if role=="far" else .66)
	result.set_shader_parameter("contrast",.62 if role=="far" else .78)
	result.set_shader_parameter("fog_amount",.25 if role=="far" else .12)
	result.set_shader_parameter("brightness",.92 if role=="far" else .82)
	return result
static func backdrop_rect() -> Rect2:
	# Original paintings are3:2; retain their shapes instead of stretching to4:3.
	return Rect2(-160,-120,2400,1600)
