class_name EnvironmentArt
extends RefCounted
## Delivered environment art. Gameplay owns collision and event timers; these
## helpers draw only, and return false when an asset is absent.
const WorldDetail=preload("res://scripts/world_detail.gd")
const FX=preload("res://scripts/combat_visual.gd")
const BIOMES:Array[String]=["sky","canopy","branches","trunk","grass","underground"]
const SOLID_COLORS={"sky":Color("344d5d"),"canopy":Color("30483d"),"branches":Color("293e3c"),"trunk":Color("3f3730"),"grass":Color("33453c"),"underground":Color("293b48")}
const PROP_SIZES={"rack":Vector2(90,90),"dummy":Vector2(55,66),"energy_infinite":Vector2(56,65),"aid":Vector2(80,82),"mail":Vector2(78,82),"energy":Vector2(48,60),"health":Vector2(48,60)}

static func terrain_clips(biome:String,type:String) -> Array[String]:
	var names:Array[String]=[]
	for suffix in (["top","middle","bottom"] if type=="trunk" else ["top","edge","center"]):names.append(biome+"_"+type+"_"+suffix)
	return names

static func solid(c:CanvasItem,rect:Rect2,biome:String,type:String,base:Transform2D=Transform2D.IDENTITY) -> bool:
	if biome not in BIOMES or type not in ["trunk","block"] or rect.size.x<=0 or rect.size.y<=0:return false
	for id in terrain_clips(biome,type):
		if not FX.has_clip(id):return false
	c.draw_set_transform_matrix(base)
	# Transparent bark edges remain visible; collision rectangles draw only in debug mode.
	if type=="trunk":
		var cap:float=minf(rect.size.y*.24,rect.size.x*1.12)
		var middle:=Rect2(rect.position+Vector2(0,cap),Vector2(rect.size.x,maxf(0,rect.size.y-cap*2)))
		var y:float=middle.position.y
		while y<middle.end.y-.01:
			var height:float=minf(rect.size.x*2.0,middle.end.y-y)
			FX.fitted(c,biome+"_trunk_middle",0,Rect2(rect.position.x,y,rect.size.x,height),base)
			y+=height
		FX.fitted(c,biome+"_trunk_top",0,Rect2(rect.position,Vector2(rect.size.x,cap)),base)
		FX.fitted(c,biome+"_trunk_bottom",0,Rect2(rect.position.x,rect.end.y-cap,rect.size.x,cap),base)
	else:
		FX.fitted(c,biome+"_block_center",0,rect,base)
		var rim:float=minf(12,rect.size.x*.18)
		var top:float=minf(25,rect.size.y*.28)
		var edge_height:float=maxf(0,rect.size.y-top)
		FX.fitted(c,biome+"_block_edge",0,Rect2(rect.position+Vector2(0,top),Vector2(rim,edge_height)),base)
		FX.fitted(c,biome+"_block_edge",0,Rect2(rect.end.x-rim,rect.position.y+top,rim,edge_height),base,"left")
		FX.fitted(c,biome+"_block_top",0,Rect2(rect.position,Vector2(rect.size.x,top)),base)
	c.draw_set_transform_matrix(base)
	return true

static func draw_platform(_c:CanvasItem,_rect:Rect2,_biome:String,_base:Transform2D=Transform2D.IDENTITY) -> bool:
	# These six new batches add solid tiles, not one-way branch platforms. The
	# existing distinct small/large platform modules remain the proper fallback.
	return false

static func prop_clip(p:Dictionary,biome:String,weapon_index:int=0) -> String:
	var kind:String=str(p.get("kind",""))
	var hurt:float=float(p.get("hurt",0))
	var event:String=str(p.get("event","")) if float(p.get("event_left",0))>0 else ""
	match kind:
		"rack":return "rack_empty" if p.get("empty",false) else ["rack_talons","rack_feather","rack_great"][clampi(int(p.get("weapon_index",weapon_index)),0,2)]
		"dummy":return "dummy_hit" if hurt>0 else "dummy_idle"
		"energy_infinite":return "energy_flower_hit" if hurt>0 else "energy_flower_idle"
		"aid":return "first_aid_heal" if event=="heal" or p.get("healing",false) else "first_aid_idle"
		"mail":return "delivery_send" if event=="send" else "delivery_idle"
		"energy","health":return biome+("_fullheal_" if kind=="health" else "_energy_")+("break" if p.get("used",false) or float(p.get("break_left",0))>0 else "idle")
	return ""

static func _bounds(clip:Dictionary) -> Rect2:
	var b:Array=clip.get("visual_bounds",clip.get("active_bounds",[]))
	if b.size()!=4:
		var f:Dictionary=clip["frames"][0]
		return Rect2(Vector2.ZERO,Vector2(f["size"][0],f["size"][1]))
	return Rect2(b[0],b[1],b[2],b[3])

static func ground_rect(id:String,at:Vector2,maximum:Vector2) -> Rect2:
	var clip:Dictionary=FX.definition(id)
	if clip.is_empty():return Rect2()
	var bounds:Rect2=_bounds(clip)
	var factor:float=minf(maximum.x/maxf(1,bounds.size.x),maximum.y/maxf(1,bounds.size.y))
	var size:Vector2=bounds.size*factor
	return Rect2(at-Vector2(size.x*.5,size.y),size)

static func _ground(c:CanvasItem,id:String,at:Vector2,maximum:Vector2,time:float,base:Transform2D,progress:float=-1,tint:Color=Color.WHITE) -> bool:
	if not FX.has_clip(id):return false
	var clip:Dictionary=FX.definition(id)
	var index:int=FX.sample_index(clip,maxf(0,progress),"event" if progress>=0 else "idle",-1 if progress>=0 else time)
	var f:Dictionary=clip["frames"][index];var rest:Dictionary=clip["frames"][0]
	var source:Array=rest.get("visible_bounds",[0,0,rest["size"][0],rest["size"][1]])
	var factor:float=minf(maximum.x/maxf(1,float(source[2])),maximum.y/maxf(1,float(source[3])))
	var bounds:Array=f.get("visible_bounds",[0,0,f["size"][0],f["size"][1]])
	var anchor:=Vector2(float(source[0])+float(source[2])*.5,float(bounds[1])+float(bounds[3]))
	# Frame selection may change silhouette, but never its fixed object scale.
	# Its measured planted foot, rather than a union crop, rests on the surface.
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2.ONE*factor,0,at))
	c.draw_texture_rect(FX.texture_for(id,index),Rect2(-anchor,Vector2(f["size"][0],f["size"][1])),false,tint)
	c.draw_set_transform_matrix(base);return true

static func spring(c:CanvasItem,at:Vector2,biome:String,time:float,base:Transform2D=Transform2D.IDENTITY,width:float=260) -> bool:
	if WorldDetail.spring(c,at,time,base,width):return true
	for role in ["base","water","steam"]:
		if not FX.has_clip(biome+"_spring_"+role):return false
	var anchor:Dictionary=FX.definition(biome+"_spring_base")
	var bounds:Rect2=_bounds(anchor)
	var factor:float=width/maxf(1,bounds.size.x)
	# All three layers share one authored canvas and one transform. Fitting them
	# independently would stretch the water and put the steam under the floor.
	var origin:Vector2=Vector2(bounds.get_center().x,bounds.end.y)
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2.ONE*factor,0,at))
	for role in ["base","water","steam"]:
		var id:String=biome+"_spring_"+role
		var clip:Dictionary=FX.definition(id)
		var index:int=int(time*float(clip.get("fps",12)))%clip["frames"].size()
		var f:Dictionary=clip["frames"][index]
		var size:Vector2=Vector2(f["size"][0],f["size"][1])
		c.draw_texture_rect(FX.texture_for(id,index),Rect2(-origin,size),false,Color(1,1,1,.72 if role=="steam" else 1))
	c.draw_set_transform_matrix(base)
	return true

static func prop(c:CanvasItem,p:Dictionary,biome:String,time:float,base:Transform2D=Transform2D.IDENTITY,weapon_index:int=0) -> bool:
	var kind:String=str(p.get("kind",""))
	var at:Vector2=p.get("pos",Vector2.ZERO)
	if kind=="spring":return spring(c,at,biome,time,base)
	if not PROP_SIZES.has(kind):return false
	if p.get("used",false) and float(p.get("break_left",0))<=0:return false
	var id:String=prop_clip(p,biome,weapon_index)
	if not FX.has_clip(id):return false
	var progress:float=-1
	if kind in ["energy","health"] and (p.get("used",false) or float(p.get("break_left",0))>0):progress=clampf(1-float(p.get("break_left",0))/.5,0,1)
	elif kind in ["dummy","energy_infinite"] and float(p.get("hurt",0))>0:progress=clampf(1-float(p["hurt"])/.3,0,1)
	elif kind in ["aid","mail"] and float(p.get("event_left",0))>0:progress=clampf(1-float(p["event_left"])/.8,0,1)
	var drawn:bool=_ground(c,id,at,PROP_SIZES[kind],time,base,progress)
	if drawn and kind=="mail" and id=="delivery_send" and FX.has_clip("delivery_parcel"):
		var t:float=maxf(0,progress)
		_ground(c,"delivery_parcel",at+Vector2(15+t*50,-36-t*35),Vector2(28,28),time,base,-1,Color(1,1,1,1-t*.65))
	return drawn

static func door_light(c:CanvasItem,at:Vector2,direction:String,time:float,base:Transform2D=Transform2D.IDENTITY,animated:bool=true) -> bool:
	var id:String="door_light_loop" if animated else "door_light_static"
	if not FX.has_clip(id):return false
	var angle:float={"left":0.0,"right":PI,"up":PI*.5,"down":-PI*.5}.get(direction,0.0)
	var local:=Rect2(0,-70,80,140)
	var local_base:Transform2D=base*Transform2D(angle,at)
	var result:bool=FX.fitted(c,id,0,local,local_base,"right","idle",Color(1,1,1,.75),time)
	c.draw_set_transform_matrix(base)
	return result
