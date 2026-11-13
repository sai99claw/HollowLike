class_name CombatFeedback
extends Node2D
const PigeonBurst=preload("res://scripts/pigeon_burst_v72.gd")
const Boss=preload("res://scripts/boss_art.gd")
const FX=preload("res://scripts/combat_visual.gd")
const Motion=preload("res://scripts/monster_motion_v18.gd")
var sparks:Array[Dictionary]=[]
var flashes:Array[Dictionary]=[]
var corpses:Array[Dictionary]=[]
var bursts:Array[CPUParticles2D]=[]
var impulses:Array[Dictionary]=[]
const Ribbon=preload("res://scripts/projectile_readability_v25.gd")
var fading_ribbons:Array[Dictionary]=[]
var reduced:bool=true
var cache_motes:CPUParticles2D
var impact_rng:=RandomNumberGenerator.new()
func hit(en:Dictionary,at:Vector2,direction:Vector2) -> void:
	if flashes.size()>=12:flashes.pop_front()
	at=impact_center(en,at)
	var spray:Vector2=direction.normalized() if direction.length_squared()>.01 else Vector2.RIGHT
	flashes.append({"at":at,"spray_at":at,"dir":spray,"life":.25,"max":.25,"feathers":true,"straight_angle":spray.angle()+impact_rng.randf_range(-.56,.56)})
	queue_redraw()

static func impact_center(en:Dictionary,fallback:Vector2) -> Vector2:
	if en.has("v55_row"):
		return preload("res://scripts/monster_art_v55.gd").actor_bounds(en,float(en.get("_impact_time",0))).get_center()
	if en.has("roster_id") and en.has("roster_biome"):
		return preload("res://scripts/monster_art_v36.gd").actor_bounds(en,float(en.get("_impact_time",0))).get_center()
	if en.has("pos"):return Vector2(en["pos"])-Vector2(0,Motion.body_size(en).y*.5)
	return fallback

static func spray_origin(_en:Dictionary,at:Vector2,_direction:Vector2) -> Vector2:
	# v40: the authored spray starts at the same sprite center as the crescent.
	return at

func single_dash(at:Vector2,direction:Vector2) -> Dictionary:
	return _wing_impulse(at,-direction.normalized())

func double_jump(at:Vector2) -> Dictionary:
	return _wing_impulse(at,Vector2.DOWN)

func _wing_impulse(at:Vector2,direction:Vector2) -> Dictionary:
	if impulses.size()>=6:impulses.pop_front()
	var impulse:Dictionary={"origin":at,"direction":direction,"age":0.0}
	impulses.append(impulse)
	queue_redraw()
	return impulse

func _burst(at:Vector2,tex:Texture2D,count:int,duration:float) -> CPUParticles2D:
	while bursts.size()>=32:
		var old=bursts.pop_front()
		if is_instance_valid(old):old.queue_free()
	var particle:=CPUParticles2D.new();particle.position=at;particle.texture=tex;particle.amount=count;particle.lifetime=duration;particle.one_shot=true;particle.explosiveness=1;particle.local_coords=true;particle.gravity=Vector2.ZERO
	var fade:=Gradient.new();fade.offsets=PackedFloat32Array([0,.3,1]);fade.colors=PackedColorArray([Color.WHITE,Color(1,1,1,.75),Color(1,1,1,0)]);particle.color_ramp=fade
	add_child(particle);bursts.append(particle);particle.finished.connect(particle.queue_free);return particle
func step(delta:float) -> void:
	var was_drawing:bool=not flashes.is_empty() or not corpses.is_empty() or not sparks.is_empty() or not impulses.is_empty()
	for spark in sparks:spark["life"]-=delta;spark["at"]+=spark["vel"]*delta;spark["vel"].y+=180*delta
	sparks=sparks.filter(func(s:Dictionary)->bool:return s["life"]>0)
	for impulse in impulses:impulse["age"]+=delta
	impulses=impulses.filter(func(impulse:Dictionary)->bool:return impulse["age"]<PigeonBurst.IMPULSE_DURATION)
	for flash in flashes:flash["life"]-=delta
	flashes=flashes.filter(func(f:Dictionary)->bool:return f["life"]>0)
	for corpse in corpses:corpse["life"]-=delta
	corpses=corpses.filter(func(f:Dictionary)->bool:return f["life"]>0)
	bursts=bursts.filter(func(b)->bool:return is_instance_valid(b))
	var had_ribbons:=not fading_ribbons.is_empty()
	for ribbon:Dictionary in fading_ribbons:
		ribbon["trail_clock"]+=delta
		ribbon["trail_fade"]-=delta/Ribbon.TRAIL_SECONDS
	if had_ribbons:
		fading_ribbons=fading_ribbons.filter(func(ribbon:Dictionary)->bool:return ribbon["trail_fade"]>0)
	if was_drawing or had_ribbons:queue_redraw()
func clear() -> void:
	flashes.clear();corpses.clear();sparks.clear();impulses.clear();fading_ribbons.clear()
	for b in bursts:
		if is_instance_valid(b):b.queue_free()
	bursts.clear()
	queue_redraw()
func _draw() -> void:
	for impulse in impulses:
		PigeonBurst.draw(self,PigeonBurst.IMPULSE,impulse["origin"],impulse["direction"],impulse["age"],PigeonBurst.IMPULSE_DURATION,110.0,Transform2D.IDENTITY)
	for ribbon:Dictionary in fading_ribbons:
		Ribbon.draw_trail(self,ribbon,Transform2D.IDENTITY,reduced)
	for corpse in corpses:
		var en:Dictionary=corpse["en"];var progress:float=1-float(corpse["life"])/float(corpse["max"])
		if int(en.get("model",0))==4:
			Boss.delivered(self,en,"death",progress,Transform2D.IDENTITY,Color(1,1,1,1-progress*.7));continue
		FX.actor(self,FX.enemy_clip(en,"death"),progress,en["pos"],Transform2D.IDENTITY,float(en["face"]),float(en.get("scale",1)),Color(1,1,1,1-progress*.8),"death",-1,str(en.get("visual_movement",en.get("movements",["walk"])[0])) in ["hover","drift"])
func draw_screen(c:CanvasItem,base:Transform2D,screen_width:float=1280.0) -> void:
	for flash:Dictionary in flashes:preload("res://scripts/hit_art_v37.gd").draw(c,flash,base,screen_width)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

func finish_trail(pr:Dictionary) -> void:
	var points:PackedVector2Array=pr.get("trail_points",PackedVector2Array())
	if points.size()>1:
		if fading_ribbons.size()>=24:fading_ribbons.pop_front()
		var ribbon:Dictionary=pr.duplicate(false)
		ribbon["trail_fade"]=1.0
		fading_ribbons.append(ribbon)
		queue_redraw()

func update_cache(enabled:bool,at:Vector2,time:float) -> void:
	if cache_motes==null and not enabled:return
	if cache_motes==null:
		cache_motes=CPUParticles2D.new();cache_motes.name="DeathCacheFallingWhiteFeathers"
		var atlas:AtlasTexture=preload("res://scripts/adventure_art_v29.gd").feather_texture()
		cache_motes.texture=atlas;cache_motes.amount=24;cache_motes.lifetime=5.6;cache_motes.preprocess=1.2;cache_motes.local_coords=true
		cache_motes.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;cache_motes.emission_rect_extents=Vector2(45,8)
		cache_motes.direction=Vector2.DOWN;cache_motes.spread=22;cache_motes.initial_velocity_min=5;cache_motes.initial_velocity_max=12;cache_motes.gravity=Vector2(0,2)
		cache_motes.scale_amount_min=.028;cache_motes.scale_amount_max=.055;cache_motes.angular_velocity_min=-18;cache_motes.angular_velocity_max=18
		cache_motes.modulate=Color(1,1,1,.8)
		var fade:=Gradient.new();fade.offsets=PackedFloat32Array([0,.15,.7,1]);fade.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color(1,1,1,.8),Color(1,1,1,0)]);cache_motes.color_ramp=fade
		add_child(cache_motes)
	cache_motes.visible=enabled;cache_motes.emitting=enabled
	cache_motes.position=at-Vector2(0,58+sin(time*.65)*6)

func grass_hit(at:Vector2,direction:Vector2,style:String) -> void:
	if flashes.size()>=12:flashes.pop_front()
	flashes.append({"at":at,"dir":direction,"style":style,"life":.25,"max":.25,"started_usec":Time.get_ticks_usec(),"length":1280.0/3.0,"angle":direction.angle(),"feathers":false})

func set_frozen(frozen:bool,speed:float=1.0) -> void:
	for child in get_children():
		if child is CPUParticles2D:child.speed_scale=0.0 if frozen else speed
