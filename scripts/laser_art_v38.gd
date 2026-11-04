class_name LaserArtV38
extends RefCounted
const ROOT:String="res://assets/v38/effects/"
static var data:Dictionary={}
static var image:Texture2D
static func info() -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"laser-beam.json"))
	return data
static func texture() -> Texture2D:
	if image==null:image=load(ROOT+str(info()["path"]))
	return image
static func frame_index(elapsed:float) -> int:return posmod(int(elapsed*24),8)
static func draw(c:CanvasItem,e:Dictionary,base:Transform2D) -> void:
	var delta:Vector2=Vector2(e["end"])-Vector2(e["pos"])
	if delta.length_squared()<.01:return
	var elapsed:float=float(e["max"])-float(e["life"])
	var f:Dictionary=info()["frames"][frame_index(elapsed)];var r:Array=f["source_rect"];var p:Array=f["pivot"]
	var scale_value:=Vector2(delta.length()/float(f["reference_width"]),float(e.get("width",18))/float(f["reference_height"]))
	c.draw_set_transform_matrix(base*Transform2D(delta.angle(),scale_value,0,e["pos"]))
	c.draw_texture_rect_region(texture(),Rect2(-Vector2(p[0],p[1]),Vector2(r[2],r[3])),Rect2(r[0],r[1],r[2],r[3]))
	c.draw_set_transform_matrix(base)
