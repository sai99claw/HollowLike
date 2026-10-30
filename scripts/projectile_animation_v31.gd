class_name ProjectileAnimationV31
extends RefCounted
const ROOT:String="res://assets/v31/projectiles/"
const IDS:Array[String]=["needle","impact_bomb","ricochet","homing_missile","trap_pod","moonblade","fire_flask"]
const FPS:Dictionary={"needle":14.0,"impact_bomb":12.0,"ricochet":16.0,"homing_missile":10.0,"trap_pod":24.0,"moonblade":20.0,"fire_flask":8.0}
const ROTATION:Dictionary={"needle":"axial_clockwise","impact_bomb":"clockwise","ricochet":"counterclockwise","homing_missile":"axial_counterclockwise","trap_pod":"counterclockwise","moonblade":"clockwise","fire_flask":"clockwise"}
static var images:Dictionary={}
static var definitions:Dictionary={}
static func has(id:String) -> bool:return IDS.has(id)
static func definition(id:String) -> Dictionary:
	if not has(id):return {}
	if not definitions.has(id):definitions[id]=JSON.parse_string(FileAccess.get_file_as_string(ROOT+id+".json"))
	return definitions[id]
static func texture(id:String) -> Texture2D:
	if not has(id):return null
	if not images.has(id):images[id]=load(ROOT+id+".png")
	return images[id]
static func frame_index(id:String,elapsed:float) -> int:return posmod(int(floor(maxf(0,elapsed)*float(FPS.get(id,12)))),8)
static func angle(id:String,heading:Vector2,launch_angle:float) -> float:
	# Axial rolls keep noses on the flight vector. Tumbling objects keep their
	# launch orientation; eight authored views supply the rotation themselves.
	return heading.angle() if id in ["needle","homing_missile"] else launch_angle
static func draw(c:CanvasItem,id:String,at:Vector2,heading:Vector2,radius:float,elapsed:float,base:Transform2D,launch_angle:float=0) -> bool:
	var tex:Texture2D=texture(id);var data:Dictionary=definition(id)
	if tex==null or data.is_empty():return false
	var frame:Dictionary=data["frames"][frame_index(id,elapsed)];var r:Array=frame["rect"];var pivot:Array=frame["pivot"]
	var ratio:Vector2=tex.get_size()/Vector2(data["original_size"][0],data["original_size"][1])
	var factor:float=radius*2.0/maxf(1,float(data["max_body_extent"]))
	c.draw_set_transform_matrix(base*Transform2D(angle(id,heading,launch_angle),Vector2.ONE*factor,0,at))
	c.draw_texture_rect_region(tex,Rect2(-Vector2(pivot[0],pivot[1]),Vector2(r[2],r[3])),Rect2(Vector2(r[0],r[1])*ratio,Vector2(r[2],r[3])*ratio))
	c.draw_set_transform_matrix(base)
	return true
