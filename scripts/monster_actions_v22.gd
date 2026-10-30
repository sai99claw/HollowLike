class_name MonsterActionsV22
extends RefCounted
const Atlas=preload("res://scripts/atlas_v22.gd")
const Appearance=preload("res://scripts/monster_appearance.gd")
static func regular(c:CanvasItem,en:Dictionary,time:float,base:Transform2D) -> bool:
	var species:String=Appearance.species(en);var attack:Variant=en.get("attack")
	var phase:String="hurt" if float(en.get("hurt",0))>0 else (str(attack.phase) if attack!=null else "idle")
	var index:int=0;var role:String="attack"
	if phase=="hurt":role="hurt";index=clampi(int((1-float(en["hurt"])/.2)*4),0,3)
	elif phase in ["windup","active","recovery"]:index=0 if phase=="windup" else (3 if phase=="recovery" else 1+mini(1,int(attack.progress()*2)))
	elif en.get("charge_phase","")=="windup":
		role="prepare";var progress:float=1-float(en.get("charge_left",0))/maxf(.01,float(en.get("dash_windup",.6)));index=clampi(int(progress*2),0,1)
	elif en.get("charge_phase","")=="recovery":
		role="brake";var progress:float=1-float(en.get("charge_left",0))/maxf(.01,float(en.get("dash_recovery",.6)));index=clampi(int(progress*2),0,1)
	else:return false
	return _draw(c,"monster-actions",species+"_"+role,index,en,base,float(en.get("scale",1)))
static func boss(c:CanvasItem,en:Dictionary,time:float,base:Transform2D) -> bool:
	var attack:Variant=en.get("attack");var role:String="";var index:int=0
	if float(en.get("hurt",0))>0 and float(en.get("stun",0))>0:role="hurt";index=clampi(int((1-float(en["hurt"])/.2)*4),0,3)
	elif attack!=null and attack.is_busy():
		role="melee" if bool(attack.attack.get("primary",false)) or attack.attack.get("animation_role","")=="melee" else "ranged"
		index=0 if attack.phase=="windup" else (3 if attack.phase=="recovery" else 1+mini(1,int(attack.progress()*2)))
	else:return false
	return _draw(c,"boss-actions",Appearance.biome(en)+"_"+role,index,en,base,1)
static func _draw(c:CanvasItem,library:String,id:String,index:int,en:Dictionary,base:Transform2D,scale_value:float) -> bool:
	var clip:Dictionary=Atlas.clip(library,id)
	if clip.is_empty():return false
	var factor:float=float(clip["world_height"])/maxf(1,float(clip["reference_height"]))*scale_value
	return Atlas.draw(c,library,id,index,en["pos"],factor,float(en.get("face",1)),base)
