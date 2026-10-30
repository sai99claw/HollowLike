class_name SpriteArt
extends RefCounted
const Adventure=preload("res://scripts/adventure_visual.gd")
const Walk=preload("res://scripts/walk_animation.gd")
const NewMotion=preload("res://scripts/pigeon_motion_v22.gd")
## Runtime adapter for curated delivered illustrations. Feet pivots live in the
## manifest. Animation phase selects art; art never drives damage or timing.
const ROOT="res://assets/illustrated/"
const FX=preload("res://scripts/combat_visual.gd")
const Ecology=preload("res://scripts/ecology.gd")
static var manifest:Dictionary={}
static var textures:Dictionary={}

static func _ensure() -> bool:
	if not manifest.is_empty():return true
	if not FileAccess.file_exists(ROOT+"manifest.json"):return false
	var value:Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	if value is Dictionary:manifest=value
	return not manifest.is_empty()

static func _texture(path:String) -> Texture2D:
	if not textures.has(path):textures[path]=load(ROOT+path)
	return textures[path]

static func warmup() -> void:
	# Load metadata only. Decode each room/actor texture when it is first drawn.
	_ensure()

static func frame(c:CanvasItem,clip:String,index:int,pos:Vector2,face:float=1.0,tint:Color=Color.WHITE,base:Transform2D=Transform2D.IDENTITY,scale_value:float=1.0,angle:float=0.0) -> bool:
	if not _ensure() or not manifest["animations"].has(clip):return false
	var frames:Array=manifest["animations"][clip]["frames"]
	if frames.is_empty():return false
	var selected:Dictionary=frames[clampi(index,0,frames.size()-1)]
	var pivot:=Vector2(float(selected["pivot"][0]),float(selected["pivot"][1]))
	if clip=="pigeon_wall":
		# The legacy wall metadata used a shoulder pivot (42px high in a64px
		# image), visibly putting the feet below the collision boundary.
		# Use the same bottom-centre feet convention for either facing direction.
		pivot=Vector2(float(selected["size"][0])*.5,float(selected["size"][1]))
	c.draw_set_transform_matrix(base*Transform2D(angle,Vector2((-1.0 if face<0 else 1.0)*scale_value,scale_value),0.0,pos))
	c.draw_texture(_texture(selected["path"]),-pivot,tint)
	c.draw_set_transform_matrix(base)
	return true

static func phase_frame(clip:String,phase:String,progress:float,time:float) -> int:
	if not _ensure() or not manifest["animations"].has(clip):return 0
	var count:int=manifest["animations"][clip]["frames"].size()
	if phase=="windup":return 0
	if phase=="active":return mini(count-2,1+int(progress*maxi(1,count-2)))
	if phase=="recovery":return count-1
	return int(time*8)%maxi(1,count)

static func player(c:CanvasItem,pos:Vector2,face:float,time:float,anim:String,tint:Color,scale_value:float,progress:float,base:Transform2D,weapon:String="quick",attack:Dictionary={}) -> bool:
	if NewMotion.draw_air(c,anim,pos,face,time,base,tint,scale_value):return true
	if anim in ["run","idle","limp"] and Walk.draw_turn(c,pos,tint,scale_value,base):return true
	if Adventure.player_action(c,anim,attack,progress,pos,face,time,base,tint,scale_value,Walk.frame_index):return true
	if anim=="limp":
		var swing:float=sin(float(Walk.frame_index)/12.0*TAU)
		var limp_base:Transform2D=base*Transform2D(.12*face,Vector2.ONE,0,pos+Vector2(0,absf(swing)*2))*Transform2D(0,-pos)
		return Walk.draw_frame(c,pos,face,tint,scale_value,limp_base)
	if anim in ["run","idle"] and Walk.draw_frame(c,pos,face,tint,scale_value,base):return true
	if anim=="heal":return FX.actor(c,"pigeon_talons_charge",fmod(time*.8,1),pos,base,face,scale_value,tint,"windup")
	var delivered:String=FX.player_clip(weapon,attack,anim)
	if not delivered.is_empty():
		var phase:String="idle" if anim=="charge" else anim
		if FX.actor(c,delivered,progress,pos,base,face,scale_value,tint,phase,time if anim=="charge" else -1):return true
	var clip:String="pigeon_walk"
	var index:int=0
	var unarmed:bool=weapon=="foot"
	if unarmed:weapon="quick"
	if anim=="run":index=int(time*10)%4
	elif anim in ["jump","jump_up","jump_apex","jump_down"]:clip="pigeon_jump";index={"jump_up":1,"jump_apex":2,"jump_down":3}.get(anim,1)
	elif anim=="wall":clip="pigeon_wall";index=1
	elif anim=="dash":clip="pigeon_dash";index=1
	elif anim=="charge":clip="pigeon_"+weapon+"_pose";index=0
	elif anim in ["windup","active","recovery"]:
		clip="pigeon_"+weapon
		if attack.get("kind","")=="slam":clip="pigeon_slam"
		elif attack.get("kind","")=="pierce":clip="pigeon_pierce"
		elif bool(attack.get("charged",false)):clip="pigeon_charge_"+weapon
		index=phase_frame(clip,anim,progress,time)
	elif anim=="hurt":tint=tint.lerp(Color("ff9c8a"),.55)
	if unarmed and anim in ["charge","windup","active","recovery"]:clip="pigeon_walk";index=1 if anim=="active" else 0
	return frame(c,clip,index,pos,face,tint,base,scale_value)

static func enemy(c:CanvasItem,pos:Vector2,face:float,time:float,kind:String,phase:String,progress:float,base:Transform2D,ranged:bool=false,scale_value:float=1) -> bool:
	var id:String={"melee":"beetle","ranged":"slinger","fly":"moth","flyer":"moth","elite":"guardian","boss":"boss"}.get(kind,"beetle")
	var clip:String=id+"_walk"
	if phase in ["windup","active","recovery"]:clip=id+("_ranged" if ranged and id!="beetle" else "_attack")
	var tint:=Color("ffc2ae") if phase=="hurt" else Color.WHITE
	return frame(c,clip,phase_frame(clip,phase,progress,time),pos,face,tint,base,scale_value)

static func background(c:CanvasItem,size:Vector2,height:int) -> bool:
	if not _ensure():return false
	var id:String=Ecology.describe(height)["id"]
	c.draw_texture_rect(_texture(manifest["backgrounds"][id]),Rect2(Vector2.ZERO,size),false)
	# Keep doors and hit flashes readable against illustrated scenery.
	c.draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.05,0.08,.12))
	return true

static func module(c:CanvasItem,id:String,rect:Rect2,tint:Color=Color.WHITE) -> bool:
	if not _ensure() or not manifest["modules"].has(id):return false
	c.draw_texture_rect(_texture(manifest["modules"][id]["path"]),rect,false,tint)
	return true

static func platform(c:CanvasItem,rect:Rect2,height:int,debug:bool=false) -> bool:
	if not _ensure():return false
	var id:String="branch_small" if rect.size.x<220 else ("branch_medium" if rect.size.x<330 else "branch_large")
	if height<=-3:id="mushroom_platform" if rect.size.x<220 else "root_platform"
	elif height==-2 and rect.size.x>=220:id="grass_platform"
	# Visible top lip is exactly the collision top. Decorative roots hang below.
	var top:float=rect.position.y
	var visual_height:float=clampf(rect.size.x*.30,36,78)
	if rect.size.x>1000:
		for i in 5:
			var tile_width:float=rect.size.x/5
			var tile_id:String="grass_platform" if height>=-2 else "root_platform"
			var offset:float=float(manifest["modules"][tile_id]["surface_y"])/float(manifest["modules"][tile_id]["size"][1])*100
			module(c,tile_id,Rect2(rect.position.x+i*tile_width,top-offset,tile_width+2,100))
	else:
		var offset:float=float(manifest["modules"][id]["surface_y"])/float(manifest["modules"][id]["size"][1])*visual_height
		module(c,id,Rect2(rect.position.x,top-offset,rect.size.x,visual_height))
	if debug:c.draw_line(rect.position+Vector2(5,1),rect.position+Vector2(rect.size.x-5,1),Color("c3d4aa",.8),2,false)
	return true

static func decorations(c:CanvasItem,height:int,width:float,floor_y:float) -> void:
	if height<=-3:
		module(c,"hanging_root",Rect2(width-250,0,240,270),Color(1,1,1,.6))
		module(c,"fern",Rect2(25,floor_y-104,100,104),Color(1,1,1,.8))
	elif height<3:
		module(c,"foliage",Rect2(0,0,250,175),Color(1,1,1,.6))
		module(c,"fern",Rect2(width-130,floor_y-115,110,115))

static func projectile(c:CanvasItem,pr:Dictionary,time:float,base:Transform2D) -> bool:
	var skin:String=str(pr.get("sprite",""))
	if skin.is_empty():return false
	var clip:String="projectile_"+skin
	if not _ensure() or not manifest["animations"].has(clip):return false
	var frames:Array=manifest["animations"][clip]["frames"]
	var selected:Dictionary=frames[int(time*10)%frames.size()]
	var size:=Vector2(selected["size"][0],selected["size"][1])
	var angle:float=pr["vel"].angle() if skin=="needle" else 0.0
	c.draw_set_transform_matrix(base*Transform2D(angle,pr["pos"]))
	c.draw_texture(_texture(selected["path"]),-size*.5)
	c.draw_set_transform_matrix(base)
	return true
