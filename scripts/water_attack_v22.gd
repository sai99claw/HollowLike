class_name WaterAttackV22
extends RefCounted
const Atlas=preload("res://scripts/atlas_v22.gd")
static func create(at:Vector2,direction:Vector2) -> Dictionary:
	return {"water_attack":true,"pos":at,"direction":direction.normalized(),"life":.5,"max":.5,"color":Color.WHITE,"vel":Vector2.ZERO,"ring":false,"radius":0.0}
static func draw(c:CanvasItem,e:Dictionary,base:Transform2D) -> void:
	var data:Dictionary=Atlas.metadata("water-splash")
	if data.is_empty():return
	var age:float=float(e["max"])-float(e["life"]);var index:int=clampi(int(age*float(data["fps"])),0,7)
	var f:Dictionary=data["frames"][index];var image:Texture2D=Atlas.texture(data["path"],f["source_rect"])
	if image==null:return
	var raw:Array=f["pivot"];var pivot:=Vector2(raw[0],raw[1]);var direction:Vector2=e["direction"]
	var factor:float=float(data["world_size"][0])/444.0
	var angle:float=0 if absf(direction.x)>=absf(direction.y) else (-PI*.5 if direction.y<0 else PI*.5)
	var face:float=-1 if direction.x<-.5 else 1
	c.draw_set_transform_matrix(base*Transform2D(angle,Vector2(face*factor,factor),0,e["pos"]))
	c.draw_texture(image,-pivot);c.draw_set_transform_matrix(base)
