class_name DeathArtV39
extends RefCounted
const ROOT:String="res://assets/v39/monsters/"
static var data:Dictionary={}
static var images:Dictionary={}
static func info(biome:String) -> Dictionary:
	if not data.has(biome):data[biome]=JSON.parse_string(FileAccess.get_file_as_string(ROOT+biome+"-death.json"))
	return data[biome]
static func frame(en:Dictionary) -> Dictionary:
	return info(str(en["roster_biome"]))["frames"][5+int(en["roster_row"]) if en.get("roster_elite",false) else int(en["roster_row"])]
static func extent(en:Dictionary) -> Vector2:
	var f:Dictionary=frame(en);var b:Array=f["bounds"]
	return Vector2(b[2],b[3])*float(f["world_width"])/float(f["reference_width"])
static func draw(c:CanvasItem,body:Dictionary) -> bool:
	var en:Dictionary=body["roster_actor"];var biome:String=en["roster_biome"];var d:Dictionary=info(biome);var f:Dictionary=frame(en)
	if not images.has(biome):images[biome]=load(ROOT+d["path"])
	var r:Array=f["source_rect"];var p:Array=f["pivot"];var factor:float=float(f["world_width"])/float(f["reference_width"])
	# Authored collapsed pose. Same facing throughout the knockback; no rotation.
	c.draw_set_transform_matrix(Transform2D(0,Vector2(float(body["face"])*factor,factor),0,body["pos"]))
	c.draw_texture_rect_region(images[biome],Rect2(-Vector2(p[0],p[1]),Vector2(r[2],r[3])),Rect2(r[0],r[1],r[2],r[3]),Color(.85,.85,.85,1))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
	return true
