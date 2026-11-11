class_name HitArtV37
extends RefCounted
const PigeonBurst=preload("res://scripts/pigeon_burst_v72.gd")
const CRESCENT_DURATION_USEC:int=125000

static func draw(c:CanvasItem,flash:Dictionary,base:Transform2D) -> void:
	var elapsed:float=float(flash["max"])-float(flash["life"])
	var angle:float=float(flash.get("angle",Vector2(flash["dir"]).angle()))
	var zoom:float=maxf(.1,base.get_scale().x)
	var now_usec:int=Time.get_ticks_usec()
	var start_usec:int=flash.get("started_usec",now_usec-roundi(elapsed*1000000))
	var elapsed_usec:int=now_usec-start_usec
	if bool(flash.get("crescent",true)) and elapsed_usec<CRESCENT_DURATION_USEC:
		preload("res://scripts/clean_crescent_v39.gd").draw(c,flash["at"],angle,float(flash.get("length",1280.0/3))/zoom,base,1.0)
	if bool(flash.get("feathers",false)):
		PigeonBurst.draw(c,PigeonBurst.IMPACT,flash.get("spray_at",flash["at"]),flash["dir"],elapsed,PigeonBurst.IMPACT_DURATION,PigeonBurst.IMPACT_EXTENT,base,PigeonBurst.IMPACT_TINT)
	c.draw_set_transform_matrix(base)
