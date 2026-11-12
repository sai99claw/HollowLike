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
var trails:Dictionary={}
var reduced:bool=true
var trail_serial:int=0
var trail_texture:GradientTexture2D
var cache_motes:CPUParticles2D
const FLASH_LENGTH:float=1280.0/3.0*1.2
var impact_rng:=RandomNumberGenerator.new()
func hit(en:Dictionary,at:Vector2,direction:Vector2,style:String,_killed:bool,show_crescent:bool=true,straight_slash:bool=false) -> void:
	if flashes.size()>=12:flashes.pop_front()
	at=impact_center(en,at)
	var spray:Vector2=direction.normalized() if direction.length_squared()>.01 else Vector2.RIGHT
	flashes.append({"at":at,"spray_at":spray_origin(en,at,spray),"dir":spray,"angle":spray.angle()+impact_rng.randf_range(-.24,.24),"style":style,"life":.25,"max":.25,"length":1280.0/3.0,"started_usec":Time.get_ticks_usec(),"feathers":true,"crescent":show_crescent,"straight":straight_slash,"straight_angle":spray.angle()+impact_rng.randf_range(-.56,.56) if straight_slash else 0.0})
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
	for key in trails.keys():
		var record:Dictionary=trails[key]
		if record["ending"]:
			record["left"]-=delta
			if record["left"]<=0:
				record["emitter"].queue_free();trails.erase(key)
	bursts=bursts.filter(func(b)->bool:return is_instance_valid(b))
	if was_drawing or charging:queue_redraw()
func clear() -> void:
	flashes.clear();corpses.clear();sparks.clear();impulses.clear()
	for b in bursts:
		if is_instance_valid(b):b.queue_free()
	bursts.clear()
	for record in trails.values():record["emitter"].queue_free()
	trails.clear();queue_redraw()
func _draw() -> void:
	for impulse in impulses:
		PigeonBurst.draw(self,PigeonBurst.IMPULSE,impulse["origin"],impulse["direction"],impulse["age"],PigeonBurst.IMPULSE_DURATION,110.0,Transform2D.IDENTITY)
	if charging:
		var col:Color=Color("fff0ac") if charge_amount>=1 else Color("c9f1ef")
		for i in range(5,0,-1):draw_circle(charge_at,12+i*5,Color(col,.013*(6-i)*(charge_amount+.4)))
		draw_arc(charge_at,27,0,TAU*charge_amount,40,Color(col,.65),1.8,true)
	for corpse in corpses:
		var en:Dictionary=corpse["en"];var progress:float=1-float(corpse["life"])/float(corpse["max"])
		if int(en.get("model",0))==4:
			Boss.delivered(self,en,"death",progress,Transform2D.IDENTITY,Color(1,1,1,1-progress*.7));continue
		FX.actor(self,FX.enemy_clip(en,"death"),progress,en["pos"],Transform2D.IDENTITY,float(en["face"]),float(en.get("scale",1)),Color(1,1,1,1-progress*.8),"death",-1,str(en.get("visual_movement",en.get("movements",["walk"])[0])) in ["hover","drift"])
func draw_screen(c:CanvasItem,base:Transform2D,screen_width:float=1280.0) -> void:
	for flash:Dictionary in flashes:preload("res://scripts/hit_art_v37.gd").draw(c,flash,base,screen_width)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)

func projectile_trail(pr:Dictionary,speed:float=1) -> void:
	var dust:bool=preload("res://scripts/projectile_readability_v25.gd").uses_dust(pr)
	if not pr.has("trail_id"):
		if trails.size()>=(24 if reduced else 96):return
		trail_serial+=1;pr["trail_id"]=trail_serial
		if trail_texture==null:
			trail_texture=GradientTexture2D.new();trail_texture.width=16;trail_texture.height=16;trail_texture.fill=GradientTexture2D.FILL_RADIAL
			trail_texture.fill_from=Vector2(.5,.5);trail_texture.fill_to=Vector2(1,.5)
			var glow:=Gradient.new();glow.colors=PackedColorArray([Color.WHITE,Color(1,1,1,0)]);trail_texture.gradient=glow
		var emitter:=CPUParticles2D.new();emitter.name="ProjectilePath%d"%trail_serial
		emitter.amount=5 if reduced else 14;emitter.lifetime=.48;emitter.local_coords=true;emitter.texture=trail_texture;emitter.gravity=Vector2.ZERO
		emitter.emission_shape=CPUParticles2D.EMISSION_SHAPE_POINTS;emitter.emission_points=PackedVector2Array([pr["pos"]])
		emitter.scale_amount_min=.30;emitter.scale_amount_max=clampf(float(pr.get("radius",8))*.09,.5,1.8)
		emitter.initial_velocity_min=3;emitter.initial_velocity_max=14;emitter.spread=18
		emitter.modulate=Color(pr.get("color",Color("a3e4eb")),.9)
		if dust:
			emitter.name="ProjectileDust%d"%trail_serial;emitter.amount=3 if reduced else 6;emitter.lifetime=.20
			emitter.scale_amount_min=.04;emitter.scale_amount_max=.10;emitter.initial_velocity_min=2;emitter.initial_velocity_max=7;emitter.spread=28;emitter.gravity=Vector2(0,3)
			emitter.modulate=Color(.53,.51,.47,.28)
		var fade:=Gradient.new();fade.colors=PackedColorArray([Color.WHITE,Color(1,1,1,0)]);emitter.color_ramp=fade
		add_child(emitter);trails[trail_serial]={"emitter":emitter,"ending":false,"left":.55}
	var key:int=int(pr["trail_id"])
	if not trails.has(key):return
	var emitter:CPUParticles2D=trails[key]["emitter"]
	# Keep the emitter's transform at the world origin: previous particles stay
	# on the actual curved/bouncing path instead of following the projectile.
	emitter.emission_points=PackedVector2Array([pr["pos"]]);emitter.direction=-Vector2(pr.get("vel",Vector2.RIGHT)).normalized();emitter.speed_scale=speed
func finish_trail(pr:Dictionary) -> void:
	var key:int=int(pr.get("trail_id",-1))
	if trails.has(key):trails[key]["emitter"].emitting=false;trails[key]["ending"]=true

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

var charge_motes:CPUParticles2D
var charge_at:Vector2
var charge_amount:float=0
var charging:bool=false
func update_charge(enabled:bool,at:Vector2,elapsed:float,threshold:float) -> void:
	if not enabled and not charging:return
	if charging!=enabled:queue_redraw()
	charging=enabled;charge_at=at;charge_amount=clampf(elapsed/maxf(.1,threshold),0,1)
	if charge_motes==null:
		charge_motes=CPUParticles2D.new();charge_motes.name="PigeonChargeInwardMotes";charge_motes.amount=36;charge_motes.lifetime=.65;charge_motes.local_coords=false
		charge_motes.texture=FX.texture_for("death_feather_glow");charge_motes.emission_shape=CPUParticles2D.EMISSION_SHAPE_SPHERE;charge_motes.emission_sphere_radius=46
		charge_motes.gravity=Vector2.ZERO;charge_motes.spread=180;charge_motes.initial_velocity_min=2;charge_motes.initial_velocity_max=8
		charge_motes.radial_accel_min=-100;charge_motes.radial_accel_max=-65;charge_motes.tangential_accel_min=15;charge_motes.tangential_accel_max=28
		charge_motes.scale_amount_min=.02;charge_motes.scale_amount_max=.05
		var fade:=Gradient.new();fade.offsets=PackedFloat32Array([0,.25,.8,1]);fade.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)]);charge_motes.color_ramp=fade
		add_child(charge_motes)
	charge_motes.position=at;charge_motes.visible=enabled;charge_motes.emitting=enabled;charge_motes.modulate=Color("fff0ac") if charge_amount>=1 else Color("c9f1ef")
	queue_redraw()
func grass_hit(at:Vector2,direction:Vector2,style:String) -> void:
	if flashes.size()>=12:flashes.pop_front()
	flashes.append({"at":at,"dir":direction,"style":style,"life":.25,"max":.25,"started_usec":Time.get_ticks_usec(),"length":1280.0/3.0,"angle":direction.angle(),"feathers":false})

func set_frozen(frozen:bool,speed:float=1.0) -> void:
	for child in get_children():
		if child is CPUParticles2D:child.speed_scale=0.0 if frozen else speed
