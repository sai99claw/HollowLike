class_name BossArt
extends RefCounted
## Six imported Boss sheets and six VFX sheets. AttackState controls animation
## phase selection; body collision and texture cropping remain independent.
const FX=preload("res://scripts/combat_visual.gd")
const Appearance=preload("res://scripts/monster_appearance.gd")
const MotionV18=preload("res://scripts/monster_motion_v18.gd")
const Actions=preload("res://scripts/monster_actions_v22.gd")
const ActionArt=preload("res://scripts/boss_art_v55.gd")
const Art=preload("res://scripts/art.gd")
const INK=Color("172c36")

const ROOT="res://assets/bosses/"
static var manifest:Dictionary={}
static var textures:Dictionary={}
static func _ensure() -> bool:
	if not manifest.is_empty():return true
	if not FileAccess.file_exists(ROOT+"manifest.json"):return false
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	if parsed is Dictionary:manifest=parsed
	return not manifest.is_empty()
static func _texture(path:String) -> Texture2D:
	if not textures.has(path):textures[path]=load(ROOT+path)
	return textures[path]
static func warmup() -> void:
	# Load metadata only. Decode each room/actor texture when it is first drawn.
	_ensure()

static func frame(c:CanvasItem,clip:String,index:int,at:Vector2,base:Transform2D=Transform2D.IDENTITY,face:float=1,tint:Color=Color.WHITE,scale_value:float=1,angle:float=0) -> bool:
	if not _ensure() or not manifest["animations"].has(clip):return false
	var frames:Array=manifest["animations"][clip]["frames"]
	var f:Dictionary=frames[clampi(index,0,frames.size()-1)]
	var pivot:Vector2=Vector2(f["pivot"][0],f["pivot"][1])
	if clip.ends_with("_move") or clip.ends_with("_melee") or clip.ends_with("_ranged"):
		pivot=Vector2(float(f["size"][0])*.5,float(f["size"][1]))
	c.draw_set_transform_matrix(base*Transform2D(angle,Vector2((-1.0 if face<0 else 1.0)*scale_value,scale_value),0,at))
	c.draw_texture(_texture(f["path"]),-pivot,tint)
	c.draw_set_transform_matrix(base)
	return true

static func draw(c:CanvasItem,en:Dictionary,time:float,base:Transform2D) -> void:
	var identity:String=Appearance.biome(en)
	if identity.is_empty():return
	var charge:String=en.get("charge_phase","idle")
	if charge in ["windup","active","recovery"]:
		var t:float=1-clampf(float(en.get("charge_left",0))/maxf(.01,float(en.get("dash_windup",.8))),0,1)
		var lean:float=(-.13*t if charge=="windup" else (.18 if charge=="active" else -.04))*float(en["face"])
		var stretch:=Vector2(1.08,.94) if charge=="active" else Vector2(1+t*.06,1-t*.06)
		var offset:Vector2=-Vector2(en.get("charge_vector",Vector2.RIGHT))*t*5 if charge=="windup" else Vector2.ZERO
		base=base*Transform2D(lean,stretch,0,en["pos"]+offset)*Transform2D(0,-Vector2(en["pos"]))
	var atk=en["attack"]
	if ActionArt.draw_actor(c,en,time,base) or Actions.boss(c,en,time,base):
		if atk.is_busy() and (bool(atk.attack.get("primary",false)) or atk.attack.get("animation_role","")=="melee") and atk.phase in ["active","recovery"]:
			var origin:Vector2=en["pos"]+Vector2(float(en["face"])*float(atk.attack.get("range",190))*.35,float(atk.attack.get("origin_y",-60)))
			frame(c,identity+"_slash_fx",1+mini(1,int(atk.progress()*2)),origin,base,float(en["face"]))
		return
	if not atk.is_busy() and float(en.get("hurt",0))>0 and float(en.get("stun",0))>0 and delivered(c,en,"hurt",1-float(en["hurt"])/.2,base):return
	if not atk.is_busy() and MotionV18.draw(c,en,time,base):return
	if _ensure():
		var biome:String=identity
		var role:String="move"
		var index:int=int(time*8)%4 if en["vel"].length_squared()>9 or en.get("move","")=="fly" else 0
		if atk.is_busy():
			role="melee" if bool(atk.attack.get("primary",false)) or atk.attack.get("animation_role","")=="melee" else "ranged"
			index=0 if atk.phase=="windup" else (3 if atk.phase=="recovery" else mini(2,1+int(atk.progress()*2)))
		var tint:Color=Color("ffbdab") if float(en["hurt"])>0 else Color.WHITE
		if biome=="canopy" and role=="melee" and delivered(c,en,"melee_repaired",float(index)/3.0,base,tint):return
		if frame(c,biome+"_"+role,index,en["pos"],base,float(en["face"]),tint):
			if role=="melee" and atk.phase in ["active","recovery"]:
				var origin:Vector2=en["pos"]+Vector2(float(en["face"])*float(atk.attack.get("range",190))*.35,float(atk.attack.get("origin_y",-60)))
				frame(c,biome+"_slash_fx",index,origin,base,float(en["face"]))
			return
	# A missing pose holds this Boss' own resting image. Historical procedural
	# fallbacks included a woodpecker for the stag Boss and are never substituted.
	frame(c,identity+"_move",0,en["pos"],base,float(en["face"]),Color("ffbdab") if float(en.get("hurt",0))>0 else Color.WHITE)

static func projectile(c:CanvasItem,pr:Dictionary,time:float,base:Transform2D) -> bool:
	var biome:String=pr.get("boss_biome","")
	if not biome.is_empty() and _ensure():
		var clip:String=biome+"_projectile"
		var frames:Array=manifest["animations"][clip]["frames"]
		var index:int=int(time*9)%4
		var f:Dictionary=frames[index]
		var scale_value:float=float(pr["radius"])*2.6/maxf(float(f["size"][0]),float(f["size"][1]))
		return frame(c,clip,index,pr["pos"],base,1,Color.WHITE,scale_value,pr["vel"].angle())
	var style:String=pr.get("style_id","")
	if not style in ["cloud_crescent","silk_crescent","root_wave","storm_feather","wood_splinter"]:return false
	var color:Color=pr["color"]
	var radius:float=float(pr["radius"])
	var angle:float=pr["vel"].angle()
	c.draw_set_transform_matrix(base*Transform2D(angle,pr["pos"]))
	if pr["kind"]=="flying_slash":
		c.draw_arc(Vector2.ZERO,radius,-1.2,1.2,18,Color(color,.22),radius*.55,false)
		c.draw_arc(Vector2.ZERO,radius,-1.2,1.2,18,color,3,false)
		c.draw_arc(Vector2(-5,0),radius*.7,-1.1,1.1,16,Color("ecf5e5"),1.5,false)
		if style=="silk_crescent":
			for i in 3:c.draw_line(Vector2(-radius-i*9,-7+i*7),Vector2(0,0),Color(color,.5),1,false)
	elif style=="wood_splinter":
		Art._poly(c,[Vector2(-radius*2,-radius*.5),Vector2(radius*2,0),Vector2(-radius*2,radius*.5)],color)
	else:
		Art._line(c,[Vector2(-radius*2,-5),Vector2(-radius,-2),Vector2(0,-6),Vector2(radius*2,0)],color,2.5)
	c.draw_set_transform_matrix(base)
	return true

static func hazard(c:CanvasItem,h:Dictionary,time:float,base:Transform2D=Transform2D.IDENTITY,debug:bool=false) -> void:
	var at:Vector2=h["pos"]
	var radius:float=float(h["size"])
	var color:Color=h["color"]
	var armed:bool=float(h["elapsed"])>=float(h.get("arming_time",0))
	if debug:Art._ellipse(c,at-Vector2(0,2),Vector2(radius,radius*.22),Color(color,.12 if not armed else .3))
	if not armed:
		FX.fitted(c,"trap_spore",clampf(float(h["elapsed"])/maxf(.01,float(h.get("arming_time",.5))),0,.99)*.6,Rect2(at-Vector2(radius*.5,radius*.7),Vector2(radius,radius*.7)),base,"right","arming")
		if debug:c.draw_line(at-Vector2(radius,0),at+Vector2(radius,0),Color(color,.55+.25*sin(time*8)),2,false)
		return
	var biome:String=h.get("boss_biome","")
	if not biome.is_empty() and _ensure():
		var clip:String=biome+"_impact"
		var f:Dictionary=manifest["animations"][clip]["frames"][2]
		var scale_value:float=radius*2/maxf(float(f["size"][0]),float(f["size"][1]))
		frame(c,clip,1+int(time*4)%2,at-Vector2(0,radius*.25),base,1,Color.WHITE,scale_value)
	var style:String=h.get("style_id","")
	if style=="silk_web":
		for i in 8:
			var d:Vector2=Vector2.from_angle(i*TAU/8)
			c.draw_line(at,at+d*Vector2(radius,radius*.65),color,1.5,false)
		for i in 3:Art._ellipse(c,at-Vector2(0,3),Vector2(radius,radius*.45)*(.25+float(i)*.3),Color(color,.12))
	else:
		for i in 5:
			var x:float=at.x+(i-2)*radius*.35
			var height:float=radius*(.4+.3*absf(sin(time*2+i)))
			Art._poly(c,[Vector2(x-radius*.12,at.y),Vector2(x+4,at.y-height),Vector2(x+radius*.12,at.y)],color.darkened(.15))
			c.draw_line(Vector2(x,at.y),Vector2(x+4,at.y-height),Color("e9ead3"),1.5,false)

static func impact(c:CanvasItem,e:Dictionary,base:Transform2D) -> void:
	var biome:String=e.get("boss_fx","")
	if biome.is_empty() or not _ensure():return
	var clip:String=biome+"_impact"
	var index:int=clampi(int((1-float(e["life"])/float(e["max"]))*4),0,3)
	frame(c,clip,index,e["pos"],base,1,Color.WHITE,float(e.get("fx_scale",.6)))

static func delivered(c:CanvasItem,en:Dictionary,role:String,progress:float,base:Transform2D,tint:Color=Color.WHITE) -> bool:
	var identity:String=Appearance.biome(en)
	if identity.is_empty():return false
	var id:String=identity+"_"+role
	if not FX.has_clip(id):
		return frame(c,identity+"_move",0,en["pos"],base,float(en.get("face",1)),tint) if role in ["hurt","death"] else false
	# Use a single body canvas, retaining death fragments outside the body.
	var clip:Dictionary=FX.definition(id);var index:int=FX.sample_index(clip,progress)
	var f:Dictionary=clip["frames"][index]
	var size:Vector2=Vector2(f["size"][0],f["size"][1]);var pivot:Vector2=Vector2(f["pivot"][0],f["pivot"][1])
	var bounds:Array=f.get("visible_bounds",[0,0,size.x,size.y])
	pivot=Vector2(float(bounds[0])+float(bounds[2])*.5,float(bounds[1])+float(bounds[3]))
	var reference:Array=clip["frames"][0].get("visible_bounds",[0,0,size.x,size.y])
	var factor:float=float(MotionV18.definition(identity).get("world_height",99))/maxf(1,float(reference[3]))
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(float(en.get("face",1))*factor,factor),0,en["pos"]))
	c.draw_texture_rect(FX.texture_for(id,index),Rect2(-pivot,size),false,tint);c.draw_set_transform_matrix(base);return true
