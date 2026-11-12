class_name BossArtV55
extends RefCounted
const Ink=preload("res://scripts/enemy_ink_v74.gd")

const Motion=preload("res://scripts/monster_motion_v18.gd")
const ROOT:String="res://assets/v55/bosses/"
const CELL:=Vector2(232,168)
const ANCHOR:=Vector2(116,164)
const REST_HEIGHT:Dictionary={"underground":107.0,"grass":118.0,"trunk":100.0,"branches":105.0,"canopy":128.0,"sky":158.0}
const FALLEN_SIZE:Dictionary={"underground":Vector2(210,75),"grass":Vector2(194,95),"trunk":Vector2(222,69),"branches":Vector2(191,70),"canopy":Vector2(201,57),"sky":Vector2(194,61)}
static var sheets:Dictionary={}


static func draw_actor(c:CanvasItem,en:Dictionary,time:float,base:Transform2D) -> bool:
	var atk:Variant=en["attack"]
	var phase:String=en.get("charge_phase","idle")
	var frame:int=-1
	if phase=="windup":frame=1
	elif phase=="active":frame=2
	elif phase=="recovery":frame=0
	elif atk.phase=="windup":frame=1
	elif atk.phase=="active" and (atk.attack.get("primary",false) or atk.attack.get("animation_role","")=="melee"):frame=2
	elif atk.phase=="recovery":frame=0
	elif not atk.is_busy() and float(en.get("stun",0))<=0.0:
		var velocity:Vector2=en.get("vel",Vector2.ZERO)
		if en.get("move","")!="fly" and "jump" in en.get("movements",[]) and absf(velocity.y)>95.0:
			frame=1 if velocity.y<0 else 2
		elif velocity.length_squared()<9.0:frame=0
	if frame<0:return false
	var tint:Color=Color("ffbdab") if float(en.get("hurt",0))>0.0 else Color.WHITE
	var breathing:float=1.0+sin(time*3)*.012 if frame==0 else 1.0
	return draw_frame(c,str(en["biome"]),frame,en["pos"],float(en["face"]),base,tint,breathing)


static func corpse_extent(biome:String) -> Vector2:
	if not FALLEN_SIZE.has(biome) or not ResourceLoader.exists(ROOT+biome+".webp"):return Vector2.ZERO
	return Vector2(FALLEN_SIZE[biome])*_factor(biome)


static func draw_corpse(c:CanvasItem,body:Dictionary) -> bool:
	if not body.get("boss_v55",false) or int(body["frame"])<3:return false
	return draw_frame(c,body["identity"],3,body["pos"],body["face"],Transform2D.IDENTITY,Color("d4cbc9"))


static func draw_frame(c:CanvasItem,biome:String,frame:int,at:Vector2,face:float,base:Transform2D,tint:Color=Color.WHITE,stretch:float=1.0) -> bool:
	if not REST_HEIGHT.has(biome):return false
	if not sheets.has(biome):
		var path:String=ROOT+biome+".webp"
		if not ResourceLoader.exists(path):return false
		sheets[biome]=load(path)
	var scale_value:float=_factor(biome)
	var pose:Transform2D=base*Transform2D(0,Vector2(face/stretch,stretch)*scale_value,0,at)
	if Ink.draw_frame(c,sheets[biome],ANCHOR,Rect2(Vector2(frame*CELL.x,0),CELL),pose,tint):return true
	c.draw_set_transform_matrix(pose)
	c.draw_texture_rect_region(sheets[biome],Rect2(-ANCHOR,CELL),Rect2(Vector2(frame*CELL.x,0),CELL),tint)
	c.draw_set_transform_matrix(base)
	return true


static func _factor(biome:String) -> float:
	return float(Motion.definition(biome).get("world_height",99.0))/float(REST_HEIGHT[biome])
