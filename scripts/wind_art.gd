class_name WindArt
extends RefCounted
## Three independent authored sprite sequences. Scale is fixed for every frame.
const ROOT="res://assets/motion_v14/"
const JET_SCALE:float=.10
const FORM_SCALE:float=.34
const IMPACT_SCALE:float=.90
const FORM_PIVOT:=Vector2(256,152)
const IMPACT_CELL:=Vector2(384,180)
const JET_ANCHORS=[Vector2(438,270),Vector2(392,270),Vector2(390,270),Vector2(438,258),Vector2(392,258),Vector2(390,258)]
const FORM_SEQUENCE=[0,1,3,5,6,7]
const FORM_FPS:float=24.0
const OVERLAY_TINT:=Color(1,1,1,.9)
static var textures:Dictionary={}
static func texture(kind:String) -> Texture2D:
	var path:String={"jet":ROOT+"dash-jet.png","form":"res://assets/v75/wind-form.webp","impact":"res://assets/v76/wind-impact.webp"}[kind]
	if not textures.has(kind):textures[kind]=load(path)
	return textures[kind]
static func frame_count(kind:String) -> int:return {"jet":6,"form":8,"impact":4}[kind]
static func frame_index(kind:String,progress:float) -> int:
	return mini(frame_count(kind)-1,int(clampf(progress,0,.999999)*frame_count(kind)))
static func region(kind:String,index:int) -> Rect2:
	var columns:int={"jet":3,"form":4,"impact":2}[kind]
	var rows:int=2
	var tex:Texture2D=texture(kind)
	var x:int=index%columns*int(tex.get_width()/columns)
	var y:int=floori(float(index/columns)*tex.get_height()/rows)
	var next_y:int=floori(float(index/columns+1)*tex.get_height()/rows)
	return Rect2(x,y,tex.get_width()/columns,next_y-y)
static func small_jet(c:CanvasItem,at:Vector2,dir:Vector2,elapsed:float,base:Transform2D) -> void:
	var index:int=frame_index("jet",elapsed/.16);var source:Rect2=region("jet",index)
	var anchor:Vector2=at-dir*18
	c.draw_set_transform_matrix(base*Transform2D(dir.angle(),Vector2.ONE*JET_SCALE,0,anchor))
	c.draw_texture_rect_region(texture("jet"),Rect2(-JET_ANCHORS[index],source.size),source)
	c.draw_set_transform_matrix(base)
static func form_index(elapsed:float,duration:float,down:bool) -> int:
	var slot:int=int(maxf(0,elapsed)*FORM_FPS)%FORM_SEQUENCE.size() if down else mini(FORM_SEQUENCE.size()-1,int(clampf(elapsed/maxf(.001,duration),0,1)*FORM_SEQUENCE.size()))
	return FORM_SEQUENCE[slot]
static func wind_form(c:CanvasItem,at:Vector2,dir:Vector2,elapsed:float,duration:float,base:Transform2D,down:bool=false) -> void:
	var index:int=form_index(elapsed,duration,down);var source:Rect2=region("form",index)
	c.draw_set_transform_matrix(base*Transform2D(dir.angle(),Vector2.ONE*FORM_SCALE,0,at))
	c.draw_texture_rect_region(texture("form"),Rect2(-FORM_PIVOT,source.size),source,OVERLAY_TINT)
	c.draw_set_transform_matrix(base)
static func impact_rect(at:Vector2,_progress:float) -> Rect2:
	# Conservative, fixed-size bounds for all four frames, entirely above ground.
	var size:=IMPACT_CELL*IMPACT_SCALE
	return Rect2(at-Vector2(size.x*.5,size.y),size)
static func impact(c:CanvasItem,at:Vector2,progress:float,base:Transform2D) -> void:
	var index:int=frame_index("impact",progress);var source:Rect2=region("impact",index)
	var pivot:=Vector2(source.size.x*.5,source.size.y)
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2.ONE*IMPACT_SCALE,0,at))
	c.draw_texture_rect_region(texture("impact"),Rect2(-pivot,source.size),source,OVERLAY_TINT)
	c.draw_set_transform_matrix(base)
