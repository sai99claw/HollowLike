extends RefCounted

const CELL:=Vector2(160,160)
const BIOME_PROPS={
	"underground":preload("res://assets/v82/underground-props.webp"),
	"trunk":preload("res://assets/v82/trunk-props.webp"),
	"sky":preload("res://assets/v82/sky-props.webp"),
}
const FLORA={
	"underground":preload("res://assets/v82/underground-flora.webp"),
	"trunk":preload("res://assets/v82/trunk-flora.webp"),
	"sky":preload("res://assets/v82/sky-flora.webp"),
}
const STATIONS=preload("res://assets/v82/stations.webp")
const FACILITIES=preload("res://assets/v82/facilities.webp")
const PROP_ROWS={"coin_urn":0,"launcher":1,"energy":2,"energy_infinite":2,"health":3,"chest":4,"stone":5}
const STATION_ROWS={"forge":0,"reforge":1,"wardrobe":2,"aid":3,"mail":4,"gift_pedestal":5}
const FACILITY_ROWS={"fountain":0,"spring":0,"dummy":1,"shop_dummy":1,"home_projector":2,"merchant":3,"merchant_table":3,"adventure_records":4,"trophy_case":5}
const SIZES={
	"coin_urn":Vector2(63,73),"launcher":Vector2(96,74),
	"energy":Vector2(61,72),"energy_infinite":Vector2(79,99),"health":Vector2(61,72),
	"chest":Vector2(102,85),"grass":Vector2(41,42),
	"forge":Vector2(115,107),"reforge":Vector2(105,107),"wardrobe":Vector2(103,119),
	"aid":Vector2(112,104),"mail":Vector2(104,109),"gift_pedestal":Vector2(106,100),
	"fountain":Vector2(240,95),"spring":Vector2(127,85),"dummy":Vector2(66,79),
	"shop_dummy":Vector2(84,120),"home_projector":Vector2(69,60),"merchant":Vector2(142,99),"merchant_table":Vector2(310,102),
	"adventure_records":Vector2(91,104),"trophy_case":Vector2(134,121),
}
const BIOME_TINT={"underground":Color(1.12,.91,.76),"trunk":Color(.89,1.05,.94),"sky":Color(.83,.94,1.15)}

static func entry(prop:Dictionary,biome:String) -> Array:
	var kind:String=prop["kind"]
	if kind in ["ecology_object","grass"]:
		return [FLORA[biome],posmod(int(prop.get("variant",0)),6),Color.WHITE]
	if PROP_ROWS.has(kind):return [BIOME_PROPS[biome],PROP_ROWS[kind],Color.WHITE]
	if STATION_ROWS.has(kind):return [STATIONS,STATION_ROWS[kind],BIOME_TINT[biome]]
	if FACILITY_ROWS.has(kind):return [FACILITIES,FACILITY_ROWS[kind],BIOME_TINT[biome]]
	return []

static func draw_prop(canvas:CanvasItem,prop:Dictionary,biome:String,base:Transform2D,extent:Vector2=Vector2.ZERO) -> bool:
	var art:Array=entry(prop,biome)
	if art.is_empty():return false
	if extent==Vector2.ZERO:extent=SIZES.get(prop["kind"],Vector2(55,62))
	var at:Vector2=prop["pos"]
	var state:int=1 if prop.get("gothic_broken",false) or prop.get("used",false) else 0
	if prop["kind"]=="launcher" and float(prop.get("launch_left",0))>0:
		extent.y*=1.0-.11*sin(clampf(float(prop["launch_left"])/.625,0.0,1.0)*PI)
	canvas.draw_set_transform_matrix(base)
	draw_region(canvas,art,state,Rect2(at-Vector2(extent.x*.5,extent.y),extent))
	return true

static func draw_region(canvas:CanvasItem,art:Array,state:int,destination:Rect2,opacity:float=1.0) -> void:
	var source:=Rect2(Vector2(state,int(art[1]))*CELL,CELL)
	var tint:Color=art[2]
	tint.a*=opacity
	canvas.draw_texture_rect_region(art[0],destination,source,tint)
