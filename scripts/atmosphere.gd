class_name TowerAtmosphere
extends Node2D
var profiler:RefCounted
const Midground=preload("res://scripts/tower_midground_v51.gd")
const DepthStyle=preload("res://scripts/depth_style_v32.gd")
const BiomeArt=preload("res://scripts/biome_art_v15.gd")
const FX=preload("res://scripts/combat_visual.gd")
const Sprites=preload("res://scripts/sprite_art.gd")
const Boss=preload("res://scripts/boss_art.gd")
const EnvArt=preload("res://scripts/environment_art.gd")
const Wildlife=preload("res://scripts/ambient_wildlife.gd")
const SanctuaryArt=preload("res://scripts/sanctuary_art.gd")
const Cache=preload("res://scripts/cached_canvas.gd")
const MID_FACTOR:float=.42
const FAR_FACTOR:float=.10
var room_bounds:Vector2=Vector2(2800,1800)
var backdrop_transform:=Transform2D.IDENTITY
var depth_origin:=Vector2.ZERO
var depth_origin_ready:bool=false
var middle_objects:Node2D
var middle:Node2D
var near_layer:Node2D
var ambient:Array[CPUParticles2D]=[]
var far_birds:Node2D
var near_dragonflies:Node2D
var middle_structures:Array[Dictionary]=[]
var merchant_room:bool=false
var effects_reduced:bool=false
var biome:String="branches"
var wind:float=1
var room_seed:int=0
var active:bool=true
var _blur:ShaderMaterial
var _near_blur:ShaderMaterial
var rain_layers:Array[CPUParticles2D]=[]
var rain_audio:AudioStreamPlayer
var rainy:bool=false
var audio_enabled:bool=true
var reduced_mode:int=-1
var quiet_room:bool=false
var ambient_frame:int=-1
func _ready() -> void:
	middle=Cache.new();middle.z_index=-15;middle.paint=_paint_middle;add_child(middle)
	_blur=ShaderMaterial.new();_blur.shader=load("res://shaders/depth_blur.gdshader");_blur.set_shader_parameter("blur_radius",2.5);middle.material=_blur;middle.modulate=Color.WHITE
	_near_blur=_blur.duplicate();_near_blur.set_shader_parameter("blur_radius",5.0)
	middle_objects=Cache.new();middle_objects.z_index=-14;middle_objects.paint=_paint_middle_objects;middle_objects.material=_blur;add_child(middle_objects)
	near_layer=Cache.new();near_layer.z_index=5;near_layer.paint=_paint_near;near_layer.material=_near_blur;add_child(near_layer)
	far_birds=Wildlife.new();far_birds.kind="bird";far_birds.z_index=-18;add_child(far_birds)
	near_dragonflies=Wildlife.new();near_dragonflies.kind="dragonfly";near_dragonflies.z_index=7;add_child(near_dragonflies)
	for i in 3:
		var motes:=CPUParticles2D.new();motes.z_index=-13;motes.amount=10;motes.lifetime=12;motes.preprocess=12;motes.local_coords=true
		motes.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;motes.emission_rect_extents=Vector2(800,540)
		motes.gravity=Vector2.ZERO;motes.direction=Vector2.RIGHT;motes.spread=30;motes.initial_velocity_min=4;motes.initial_velocity_max=14
		motes.scale_amount_min=.04;motes.scale_amount_max=.12;motes.modulate=Color(1,1,1,.26);motes.material=_blur
		add_child(motes);ambient.append(motes)
	for depth in 2:
		var rain:=CPUParticles2D.new();rain.name="RainFar" if depth==0 else "RainMiddle";rain.z_index=-17 if depth==0 else -14
		rain.amount=110 if depth==0 else 75;rain.lifetime=2.8;rain.preprocess=2.8;rain.local_coords=true
		rain.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;rain.emission_rect_extents=Vector2(950,650)
		rain.direction=Vector2(.15,1);rain.spread=3;rain.gravity=Vector2.ZERO;rain.initial_velocity_min=290 if depth==0 else 400;rain.initial_velocity_max=410 if depth==0 else 550
		var streak:=GradientTexture2D.new();streak.width=3;streak.height=30;streak.fill_from=Vector2(.5,0);streak.fill_to=Vector2(.5,1)
		var rain_gradient:=Gradient.new();rain_gradient.offsets=PackedFloat32Array([0,.35,.65,1]);rain_gradient.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)]);streak.gradient=rain_gradient;rain.texture=streak
		rain.modulate=Color(.72,.83,.9,.14 if depth==0 else .22);rain.scale_amount_min=.45;rain.scale_amount_max=.8;rain.material=_blur
		add_child(rain);rain_layers.append(rain)
	rain_audio=AudioStreamPlayer.new();rain_audio.name="RoomRainAmbience";rain_audio.bus="Background";rain_audio.stream=load("res://assets/atmosphere_v10/rain.wav");rain_audio.volume_db=-18
	var rain_stream:AudioStreamWAV=rain_audio.stream;rain_stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;rain_stream.loop_begin=0;rain_stream.loop_end=rain_stream.data.size()/2
	add_child(rain_audio)
func configure(ecology_id:String,seed_value:int,enabled:bool=true,merchant:bool=false,quiet:bool=false,_layout:Dictionary={},background:Rect2=Rect2()) -> void:
	merchant_room=merchant;quiet_room=quiet;ambient_frame=-1;depth_origin_ready=false
	biome=ecology_id;room_seed=seed_value;wind=-1 if seed_value%2 else 1;active=enabled
	rainy=is_rainy(ecology_id,seed_value) and enabled and not merchant_room and not quiet_room
	for rain in rain_layers:rain.emitting=rainy;rain.visible=rainy
	_sync_rain_audio()
	if not background.has_area():background=DepthStyle.backdrop_rect()
	middle_structures.clear()
	if enabled:middle_structures=Midground.plan(biome,seed_value,background)
	if middle_objects!=null:middle_objects.material=preload("res://scripts/depth_style_v32.gd").material(biome,"middle",effects_reduced)
	if middle_objects!=null:middle_objects.visible=enabled;middle_objects.invalidate()
	if far_birds!=null:far_birds.configure(seed_value+319,false)
	if near_dragonflies!=null:near_dragonflies.configure(seed_value+719,enabled and not merchant_room and not quiet_room)
	if middle!=null:middle.visible=false;middle.invalidate()
	if near_layer!=null:near_layer.visible=enabled;near_layer.invalidate()
	var ids:Array[String]=ambient_clips(biome)
	for i in ambient.size():
		var particle:CPUParticles2D=ambient[i];var id:String=ids[i] if i<ids.size() else ""
		particle.set_meta("clip",id);particle.emitting=enabled and not id.is_empty();particle.visible=particle.emitting
		if not id.is_empty():particle.texture=FX.texture_for(id)
		var grounded:bool=id.ends_with("grass") or id.ends_with("mushroom") or id.ends_with("root_glow")
		particle.emission_rect_extents=Vector2(780,30 if grounded else 500);particle.initial_velocity_min=0 if grounded else 4;particle.initial_velocity_max=1 if grounded else 14
	for particle in ambient+rain_layers:
		particle.process_mode=Node.PROCESS_MODE_DISABLED if quiet_room or not enabled or not particle.emitting else Node.PROCESS_MODE_INHERIT
func update_view(camera:Vector2,zoom:float,world:Transform2D,player:Vector2,time:float,speed:float,reduced:bool) -> void:
	if profiler==null or not profiler.active:
		_update_view_profiled_body(camera,zoom,world,player,time,speed,reduced);return
	var measured:int=Time.get_ticks_usec()
	_update_view_profiled_body(camera,zoom,world,player,time,speed,reduced)
	profiler.span("process.atmosphere",Time.get_ticks_usec()-measured)
func _update_view_profiled_body(camera:Vector2,zoom:float,world:Transform2D,player:Vector2,time:float,speed:float,reduced:bool) -> void:
	if middle==null:return
	if not active:return
	if not depth_origin_ready:depth_origin=camera;depth_origin_ready=true
	if reduced:
		middle.material=null;near_layer.material=null
		for particle in ambient+rain_layers:particle.material=null
	near_layer.visible=not quiet_room
	if effects_reduced!=reduced:
		effects_reduced=reduced
		middle_objects.material=preload("res://scripts/depth_style_v32.gd").material(biome,"middle",reduced)
		for particle in ambient+rain_layers:
			particle.material=null if reduced else _blur
	var quiet:bool=quiet_room or not active
	if quiet:
		for particle in ambient+rain_layers:particle.emitting=false;particle.visible=false;particle.process_mode=Node.PROCESS_MODE_DISABLED
		near_layer.visible=false
		middle_objects.transform=_middle_transform(camera)
		middle.transform=parallax(camera,zoom,MID_FACTOR)
		return
	if reduced_mode!=int(reduced):
		reduced_mode=int(reduced)
		middle.material=null if reduced else _blur;near_layer.material=null if reduced else _near_blur
	for i in rain_layers.size():
		rain_layers[i].transform=parallax(camera,zoom,.20 if i==0 else .48)*Transform2D(0,Vector2(750,500));rain_layers[i].speed_scale=speed
		var count:int=([32,22] if reduced else [110,75])[i]
		if rain_layers[i].amount!=count:rain_layers[i].amount=count
	far_birds.update_view(camera,zoom,time)
	near_dragonflies.update_view(camera,zoom,time)
	middle_objects.transform=_middle_transform(camera)
	middle.transform=parallax(camera,zoom,MID_FACTOR)
	near_layer.transform=parallax(camera,zoom,1.12)
	for particle in ambient:
		if reduced:continue
		var id:String=str(particle.get_meta("clip",""))
		if id.is_empty():continue
		var clip:Dictionary=FX.definition(id);var frame:int=FX.sample_index(clip,0,"idle",time)
		if particle.get_meta("frame",-1)!=frame:particle.texture=FX.texture_for(id,frame);particle.set_meta("frame",frame)
		var grounded:bool=id.ends_with("grass") or id.ends_with("mushroom") or id.ends_with("root_glow")
		particle.transform=parallax(camera,zoom,.60)*Transform2D(0,Vector2(750,1020 if grounded else 550));particle.direction=Vector2(wind,.2);particle.speed_scale=speed
	for particle in ambient:
		particle.emitting=active and not reduced;particle.visible=particle.emitting;particle.process_mode=Node.PROCESS_MODE_INHERIT if particle.emitting else Node.PROCESS_MODE_DISABLED
func depth_transform(camera:Vector2,zoom:float,factor:float) -> Transform2D:
	# Rebase at entry so complete props stay in view in tall rooms.
	return Transform2D(0,Vector2.ONE*zoom,0,-(camera*factor+depth_origin*(1-factor))*zoom)
static func parallax(camera:Vector2,zoom:float,factor:float) -> Transform2D:return Transform2D(0,Vector2.ONE*zoom,0,-camera*zoom*factor)
func _paint_middle(c:CanvasItem) -> void:
	pass # Midground consists solely of the large/medium world-object silhouettes.
func _paint_near(c:CanvasItem) -> void:
	pass # Only complete isolated objects are used in depth layers.
static func ambient_clips(id:String) -> Array[String]:
	if id=="sky":return ["sky_ambient_cloud_particles"]
	if id in ["trunk","underground"]:return [id+"_ambient_root_glow",id+"_ambient_mushroom"]
	return [id+"_ambient_leaves",id+"_ambient_light",id+"_ambient_grass"]

static func make_middle_structures(seed_value:int) -> Array[Dictionary]:
	var random:=RandomNumberGenerator.new();random.seed=seed_value+1421
	var parts:Array[Dictionary]=[]
	for i in 4:
		var x:float=-120+i*470+random.randf_range(-50,50)
		var y:float=random.randf_range(150,650)
		var height:float=random.randf_range(250,510)
		parts.append({"type":"trunk","rect":Rect2(x,y,65,height),"collision":false})
		parts.append({"type":"block","rect":Rect2(x+65,y+height-48,190,48),"collision":false})
		var edge:float=random.randf_range(95,165)
		parts.append({"type":"block","rect":Rect2(x+180,y-100,edge,edge),"collision":false})
	return parts

static func is_rainy(ecology_id:String,seed_value:int) -> bool:
	return ecology_id in ["sky","trunk","canopy","branches","grass"] and posmod(seed_value,4)==0
func set_audio_enabled(enabled:bool) -> void:
	if audio_enabled==enabled:return
	audio_enabled=enabled;_sync_rain_audio()
func _sync_rain_audio() -> void:
	if rain_audio==null:return
	if rainy and audio_enabled:
		if not rain_audio.playing:rain_audio.play()
	else:rain_audio.stop()

func _middle_transform(camera:Vector2) -> Transform2D:
	var result:Transform2D=backdrop_transform
	var x_scale:float=result.x.length()
	result.origin.x=depth_transform(camera,x_scale,MID_FACTOR).origin.x
	return result

func _paint_middle_objects(c:CanvasItem) -> void:
	Midground.draw(c,middle_structures)
