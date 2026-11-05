class_name BossArtV57
extends RefCounted

const SkillArt=preload("res://scripts/skill_art_v59.gd")
const Motion=preload("res://scripts/enemy_motion.gd")
const MotionArt=preload("res://scripts/monster_motion_v18.gd")
const ROOT="res://assets/v57/bosses/"
const CELL=Vector2(144,112)
const ANCHOR=Vector2(72,106)
const REDRAW_CELL:=Vector2(320,224)
const REDRAW_ANCHOR:=Vector2(160,216)
const BIOMES=["underground","grass","trunk","branches","canopy","sky"]
const PHASE_START={"windup":0,"active":2,"recovery":4}
const DASH_DURATION={"windup":"dash_windup","active":"dash_duration","recovery":"dash_recovery"}
const DEATH_COLUMNS=[0,1,2,3,3,4,5,5]
static var textures:Dictionary={}
static var geometry:Dictionary={}
static var hd_motion:Dictionary={}
static var hd_neutral_height:Dictionary={}
const HD_CELL:=Vector2(320,256)
const HD_ANCHOR:=Vector2(160,249)
static var effect_regions:Dictionary={}

static func _texture(id:String) -> Texture2D:
	if not textures.has(id):
		var path:String=ROOT+id+".webp"
		if not ResourceLoader.exists(path):return null
		textures[id]=load(path)
	return textures[id]

static func has_actor(biome:String) -> bool:
	return biome in BIOMES and _texture(biome)!=null

static func pose(en:Dictionary,time:float) -> Vector3i:
	var attack:Variant=en["attack"]
	if attack.is_busy():
		var slot:int=int(attack.attack.get("boss_animation_slot",-1))
		if slot>=0 and slot<4 and PHASE_START.has(attack.phase):
			return Vector3i(int(PHASE_START[attack.phase])+mini(1,int(attack.progress()*2)),3+slot,0)
		return Vector3i(-1,0,0)
	var biome:String=en["biome"]
	var charge:String=en.get("charge_phase","idle")
	if PHASE_START.has(charge):
		var column:int=int(PHASE_START[charge])+mini(1,int((1.0-float(en.get("charge_left",0.0))/maxf(.01,float(en.get(DASH_DURATION[charge],.6))))*2.0))
		return Vector3i(clampi(column,0,5),2,1 if biome in ["trunk","canopy"] else 0)
	if float(en.get("hurt",0.0))>0:
		var column:int=clampi(int((1.0-float(en["hurt"])/.2)*6),0,5)
		return Vector3i(column,7,0)
	var velocity:Vector2=en.get("vel",Vector2.ZERO)
	match Motion.current(en):
		"jump":
			var launch:float=maxf(1.0,float(en.get("jump_speed",450.0)))
			var airborne_left:float=1.7-float(en.get("jump_left",0.0))
			if absf(velocity.y)>25.0 or (airborne_left>=0.0 and airborne_left<2.0*launch/Motion.GRAVITY):
				var column:int=clampi(floori(3.0+velocity.y/launch*3.0),0,5)
				return Vector3i(column,2,0)
		"hover":
			if biome=="sky":return Vector3i(posmod(int(time*9.0),6),1,2)
		"drift":
			if biome=="sky":return Vector3i(posmod(int(time*9.0),6),1,0)
	if absf(velocity.x)>12.0:return Vector3i(posmod(int(time*9.0),6),1,0)
	return Vector3i(posmod(int(time*5.0),6),0,0)

static func draw_actor(c:CanvasItem,en:Dictionary,time:float,base:Transform2D) -> bool:
	var biome:String=en["biome"]
	if not has_actor(biome):return false
	var selection:=pose(en,time)
	if selection.x<0:return false
	var sheet:String=biome
	var row:int=selection.y
	if selection.z==1:
		sheet+="-dash";row=0
	elif selection.z==2:
		sheet+="-hover";row=0
	var tint:Color=Color("ffbdab") if float(en.get("hurt",0.0))>0 else Color.WHITE
	if selection.z==0 and row<=1 and biome in ["sky","trunk"] and not _is_redraw(_texture(biome)):
		if _draw_hd_motion(c,en,biome,row,time,base,tint):return true
	return _draw(c,biome,sheet,Vector2i(selection.x,row),en["pos"],float(en["face"]),base,tint)

static func _draw_hd_motion(c:CanvasItem,en:Dictionary,biome:String,row:int,time:float,base:Transform2D,tint:Color) -> bool:
	if not hd_motion.has(biome):
		var path:String="res://assets/v59/monsters/"+biome+".webp"
		if not ResourceLoader.exists(path):return false
		var texture:Texture2D=load(path)
		hd_motion[biome]=texture
		hd_neutral_height[biome]=texture.get_image().get_region(Rect2i(Vector2i.ZERO,Vector2i(HD_CELL))).get_used_rect().size.y
	var column:int=posmod(int(time*(9.0 if row==1 else 5.0)),4)
	var factor:float=float(MotionArt.definition(biome).get("world_height",99.0))/maxf(1.0,float(hd_neutral_height[biome]))
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(float(en["face"]),1)*factor,0,en["pos"]))
	c.draw_texture_rect_region(hd_motion[biome],Rect2(-HD_ANCHOR,HD_CELL),Rect2(Vector2(column,row)*HD_CELL,HD_CELL),tint)
	c.draw_set_transform_matrix(base)
	return true

static func _is_redraw(texture:Texture2D) -> bool:
	return texture.get_width()==int(REDRAW_CELL.x)*6

static func _draw(c:CanvasItem,biome:String,sheet:String,cell:Vector2i,at:Vector2,face:float,base:Transform2D,tint:Color) -> bool:
	var tex:Texture2D=_texture(sheet)
	if tex==null:return false
	var scale_value:float=_factor(biome)
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face,1)*scale_value,0,at))
	var redraw:bool=_is_redraw(tex)
	var pixels:Vector2=REDRAW_CELL if redraw else CELL
	var anchor:Vector2=REDRAW_ANCHOR if redraw else ANCHOR
	c.draw_texture_rect_region(tex,Rect2(-anchor,pixels),Rect2(Vector2(cell)*pixels,pixels),tint)
	c.draw_set_transform_matrix(base)
	return true

static func _measure(biome:String) -> Dictionary:
	if not geometry.has(biome):
		var tex:Texture2D=_texture(biome)
		if tex==null:return {}
		var source:Image=tex.get_image()
		var pixels:=Vector2i(REDRAW_CELL if _is_redraw(tex) else CELL)
		var neutral:=source.get_region(Rect2i(Vector2i.ZERO,pixels)).get_used_rect()
		var fallen:=source.get_region(Rect2i(pixels*Vector2i(5,8),pixels)).get_used_rect()
		geometry[biome]={"neutral":neutral.size,"fallen":fallen.size}
	return geometry[biome]

static func _factor(biome:String) -> float:
	var measurement:Dictionary=_measure(biome)
	var height:float=Vector2(measurement.get("neutral",Vector2(70,70))).y
	return float(MotionArt.definition(biome).get("world_height",99.0))/maxf(1.0,height)

static func corpse_extent(biome:String) -> Vector2:
	if not has_actor(biome):return Vector2.ZERO
	return Vector2(_measure(biome)["fallen"])*_factor(biome)

static func draw_corpse(c:CanvasItem,body:Dictionary) -> bool:
	if not body.get("boss_v57",false):return false
	var biome:String=body["identity"]
	var column:int=DEATH_COLUMNS[clampi(int(body["frame"]),0,7)]
	return _draw(c,biome,biome,Vector2i(column,8),body["pos"],float(body["face"]),Transform2D.IDENTITY,Color("e0d7d2"))

static func effect_key(biome:String,slot:int) -> String:
	return "v57:%s:%d"%[biome,slot]

static func effect_texture(key:String) -> Texture2D:
	if effect_regions.has(key):return effect_regions[key]
	var parts:PackedStringArray=key.split(":")
	if parts.size()!=3 or parts[0]!="v57" or not parts[2].is_valid_int():return null
	var column:int=BIOMES.find(parts[1]);var row:int=int(parts[2])
	if column<0 or row<0 or row>3:return null
	var atlas:Texture2D=_texture("effects")
	if atlas==null:return null
	var cell:Vector2=atlas.get_size()/Vector2(6,4)
	var region:=AtlasTexture.new()
	region.atlas=atlas;region.region=Rect2(Vector2(column,row)*cell,cell);region.filter_clip=true
	effect_regions[key]=region
	return region

static func draw_release(c:CanvasItem,en:Dictionary,attack:Dictionary,progress:float,base:Transform2D) -> bool:
	var slot:int=int(attack.get("boss_animation_slot",-1))
	if slot<0:return false

	var burst:bool=attack.get("library_kind","")=="explosion"
	var reach:float=float(attack.get("range",100))
	var width:float=reach*(2.0 if burst else (.72 if attack.get("ram",false) else 1.15))
	var height:float=width*.65
	if burst:height*=.55
	var face:float=float(en["face"])
	var origin:Vector2=Vector2(en["pos"])+Vector2(0,0 if burst else float(attack.get("origin_y",-50)))
	var placement:=Vector2(-width*.5,-height) if burst else Vector2(8,-height*.5)
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face,1),0,origin))
	var tint:Color=Color.WHITE.lerp(en.get("color",Color.WHITE),.45)
	tint.a=.10 if burst else 1.0
	var dest:=Rect2(placement,Vector2(width,height))
	if burst:SkillArt.draw_ring(c,progress,dest,tint)
	else:SkillArt.draw(c,SkillArt.attack_row(attack),progress,dest,tint)
	c.draw_set_transform_matrix(base)
	return true

static func draw_movement_charge(c:CanvasItem,en:Dictionary,phase:String,_time:float,base:Transform2D) -> bool:
	var heading:Vector2=en.get("charge_vector",Vector2.RIGHT)
	var pivot:Vector2=en["pos"]-Vector2(0,20)
	var phase_duration:float=float(en.get(DASH_DURATION[phase],.6))
	var progress:float=1.0-float(en.get("charge_left",0.0))/maxf(.01,phase_duration)
	var width:float=72.0 if phase=="windup" else 135.0
	var height:float=width*.42
	var offset:float=-width*(.3 if phase=="windup" else .84)
	var tint:Color=Color.WHITE.lerp(en.get("color",Color.WHITE),.4)
	c.draw_set_transform_matrix(base*Transform2D(heading.angle(),pivot))
	SkillArt.draw(c,SkillArt.RUSH,progress,Rect2(Vector2(offset,-height*.5),Vector2(width,height)),tint)
	c.draw_set_transform_matrix(base)
	return true
