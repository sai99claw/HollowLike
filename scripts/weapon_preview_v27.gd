class_name WeaponPreviewV27
extends Control
const Art=preload("res://scripts/weapon_art_v24.gd")
const Data=preload("res://scripts/game_data.gd")
const Arsenal=preload("res://scripts/arsenal_v24.gd")
const VFX=preload("res://scripts/gameplay_vfx.gd")
const Ribbon=preload("res://scripts/projectile_readability_v25.gd")
var effects:Node2D
var weapon_id:String=""
var clock:float=0
func _init() -> void:
	custom_minimum_size=Vector2(150,115);size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
func set_weapon(id:String) -> void:
	if weapon_id!=id:clock=0
	weapon_id=id;visible=Arsenal.index_of(id)>=0;queue_redraw()
func _process(delta:float) -> void:
	if not is_visible_in_tree() or weapon_id.is_empty():return
	clock+=delta;queue_redraw()
func _ready() -> void:
	effects=VFX.new()
	add_child(effects)

func _draw() -> void:
	if weapon_id.is_empty() or effects==null:return
	var t:=fposmod(clock,2.1)
	effects.begin(t)
	var floor_y:=size.y-18.0
	draw_style_box(_box(),Rect2(Vector2.ZERO,size))
	draw_line(Vector2(10,floor_y),Vector2(size.x-10,floor_y),Color("38534b"),1,true)
	var source:=Vector2(27,floor_y-35)
	Art.draw(self,weapon_id,source,Vector2.RIGHT,22,false)
	if t<.22:
		effects.charge(self,Transform2D.IDENTITY,source+Vector2(0,21),t/.22,false,.8)
		return
	draw_shot(self,effects,weapon_id,source,Vector2(size.x-24,source.y),floor_y,t-.22,1.2)

static func draw_shot(canvas:CanvasItem,vfx:Node2D,id:String,source:Vector2,target:Vector2,floor_y:float,elapsed:float,duration:float) -> void:
	var index:=Arsenal.index_of(id)
	if index<0:return
	var def:=Data.secondary_attack(index)
	var color:Color=def["color"]
	if id in ["chain_staff","piercing_laser"]:
		var life:=.34
		if elapsed>=life:return
		var effect:={"pos":source,"end":target,"color":color,"width":float(def["size"])*2.40,"life":life-elapsed,"max":life}
		if id=="piercing_laser":vfx.beam(canvas,effect,Transform2D.IDENTITY)
		else:VFX.lightning(canvas,effect,Transform2D.IDENTITY)
		return
	var arc:=id in ["impact_bomb","trap_pod","fire_flask"]
	var travel:=clampf(elapsed/duration,0.0,1.0)
	if arc and travel>=.9:
		var age:=elapsed-duration*.9
		var landing:=Vector2(target.x-12,floor_y)
		if id=="fire_flask":
			vfx.fire(Transform2D.IDENTITY,landing,64,1.0)
		elif id=="trap_pod":
			preload("res://scripts/monster_design.gd").draw_hazard(canvas,{"pos":landing,"elapsed":age,"arming_time":def.get("arming_time",.2),"hazard_visual_id":"moss_thorns","from_player":true,"group":"biological","color":color},elapsed,Transform2D.IDENTITY)
		elif age<.5:
			vfx.burst(canvas,{"pos":landing,"normal":Vector2.UP,"color":Color("ffc483"),"radius":38,"life":.5-age,"max":.5},Transform2D.IDENTITY)
		return
	if elapsed>duration:return
	var at:=_path(id,source,target,floor_y,travel)
	var direction:=_path(id,source,target,floor_y,minf(1.0,travel+.008))-_path(id,source,target,floor_y,maxf(0.0,travel-.008))
	var shot:={"pos":at,"vel":direction,"kind":def["weapon_kind"],"gravity":600 if arc else 0,"from_player":true,"radius":10.0,"color":color,"elapsed":elapsed}
	var start:=maxf(0.0,elapsed-Ribbon.TRAIL_SECONDS)
	var previous:=_path(id,source,target,floor_y,start/duration)
	for i in range(1,11):
		var next:=_path(id,source,target,floor_y,lerpf(start,elapsed,i/10.0)/duration)
		Ribbon.record(shot,previous,next,(elapsed-start)*.1)
		previous=next
	Ribbon.draw_trail(canvas,shot,Transform2D.IDENTITY)
	Art.draw(canvas,id,at,direction,10,true,Transform2D.IDENTITY,elapsed)
	vfx.shot(canvas,shot,Transform2D.IDENTITY,10)

static func _path(id:String,source:Vector2,target:Vector2,floor_y:float,t:float) -> Vector2:
	if id in ["impact_bomb","trap_pod","fire_flask"]:
		var arc:=clampf(t/.9,0.0,1.0)
		return source.lerp(Vector2(target.x-12,floor_y),arc)-Vector2(0,43*sin(arc*PI))
	var at:=source.lerp(target,t)
	if id=="ricochet":
		at.x=lerpf(source.x,target.x,1.0-absf(2*t-1.0))
		at.y+=sin(t*TAU)*14
	elif id=="homing_missile":at.y+=sin(t*PI)*18
	return at

func _box() -> StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=Color("091b1d");box.border_color=Color("35564c");box.set_border_width_all(1);box.set_corner_radius_all(9);return box
