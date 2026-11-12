class_name DepthStyleV32
extends RefCounted
const FOG:Dictionary={"sky":Color("465674"),"trunk":Color("414e63"),"underground":Color("464159")}
static var materials:Dictionary={}
static func material(biome:String,role:String,reduced:bool=false) -> ShaderMaterial:
	var key:String=biome+":"+role+":"+str(reduced)
	if materials.has(key):return materials[key]
	var result:=ShaderMaterial.new();result.shader=load("res://shaders/depth_grade_v32.gdshader")
	result.set_shader_parameter("fog_color",FOG.get(biome,FOG["trunk"]))
	result.set_shader_parameter("blur_radius",(0.0 if reduced else 2.4) if role=="far" else (.65 if reduced else 1.05))
	result.set_shader_parameter("saturation",.43 if role=="far" else .40)
	result.set_shader_parameter("contrast",.58 if role=="far" else .66)
	result.set_shader_parameter("fog_amount",.34 if role=="far" else .25)
	result.set_shader_parameter("brightness",.78 if role=="far" else .62)
	materials[key]=result
	return result
static func backdrop_rect() -> Rect2:
	# Original paintings are3:2; retain their shapes instead of stretching to4:3.
	return Rect2(-160,-120,2400,1600)
