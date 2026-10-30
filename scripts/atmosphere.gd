class_name TowerAtmosphere
extends Node2D
const NewArt=preload("res://scripts/biome_art_v21.gd")
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
var depth_origin:=Vector2.ZERO
var depth_origin_ready:bool=false
var middle_objects:Node2D
var middle:Node2D
var near_layer:Node2D
var ambient:Array[CPUParticles2D]=[]
var foreground:Array[CPUParticles2D]=[]
var mid_particles:Array[CPUParticles2D]=[]
var spores:CPUParticles2D
var focus:ColorRect
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
	for depth in [0,1,2]:
		for dark in [false,true]:
			var particle:CPUParticles2D=_feathers(depth,dark)
			add_child(particle)
			if depth==0:mid_particles.append(particle)
			else:foreground.append(particle)
	spores=CPUParticles2D.new();spores.name="BioluminescentSpores";spores.z_index=-11;spores.amount=40;spores.lifetime=9;spores.preprocess=9;spores.local_coords=true
	spores.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;spores.emission_rect_extents=Vector2(730,430)
	spores.direction=Vector2.UP;spores.spread=55;spores.gravity=Vector2(0,-3);spores.initial_velocity_min=5;spores.initial_velocity_max=15
	spores.scale_amount_min=.12;spores.scale_amount_max=.32;spores.color=Color(.36,.75,1,.45)
	var glow:=GradientTexture2D.new();glow.width=32;glow.height=32;glow.fill=GradientTexture2D.FILL_RADIAL;glow.fill_from=Vector2(.5,.5);glow.fill_to=Vector2(1,.5)
	var gradient:=Gradient.new();gradient.colors=PackedColorArray([Color(.6,1,1,.9),Color(.2,.45,1,0)]);glow.gradient=gradient;spores.texture=glow
	add_child(spores)
	for depth in 2:
		var rain:=CPUParticles2D.new();rain.name="RainFar" if depth==0 else "RainMiddle";rain.z_index=-17 if depth==0 else -14
		rain.amount=110 if depth==0 else 75;rain.lifetime=2.8;rain.preprocess=2.8;rain.local_coords=true
		rain.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;rain.emission_rect_extents=Vector2(950,650)
		rain.direction=Vector2(.15,1);rain.spread=3;rain.gravity=Vector2.ZERO;rain.initial_velocity_min=290 if depth==0 else 400;rain.initial_velocity_max=410 if depth==0 else 550
		var streak:=GradientTexture2D.new();streak.width=3;streak.height=30;streak.fill_from=Vector2(.5,0);streak.fill_to=Vector2(.5,1)
		var rain_gradient:=Gradient.new();rain_gradient.offsets=PackedFloat32Array([0,.35,.65,1]);rain_gradient.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)]);streak.gradient=rain_gradient;rain.texture=streak
		rain.modulate=Color(.72,.83,.9,.14 if depth==0 else .22);rain.scale_amount_min=.45;rain.scale_amount_max=.8;rain.material=_blur
		add_child(rain);rain_layers.append(rain)
	rain_audio=AudioStreamPlayer.new();rain_audio.name="RoomRainAmbience";rain_audio.stream=load("res://assets/atmosphere_v10/rain.wav");rain_audio.volume_db=-18
	var rain_stream:AudioStreamWAV=rain_audio.stream;rain_stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;rain_stream.loop_begin=0;rain_stream.loop_end=rain_stream.data.size()/2
	add_child(rain_audio)
	focus=ColorRect.new();focus.name="PlayerFocusLight";focus.z_index=8;focus.size=Vector2(1280,720);focus.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var mat:=ShaderMaterial.new();mat.shader=load("res://shaders/player_focus.gdshader");mat.set_shader_parameter("darkness",.22);focus.material=mat;add_child(focus)
func _feathers(depth:int,dark:bool) -> CPUParticles2D:
	var particle:=CPUParticles2D.new();particle.name="Feathers_%d_%s"%[depth,"Black" if dark else "White"]
	particle.z_index=[-12,4,6][depth];particle.amount=[23,15,9][depth];particle.lifetime=14;particle.preprocess=14;particle.local_coords=true
	particle.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;particle.emission_rect_extents=Vector2(850,650)
	particle.texture=FX.texture_for("death_feather_glow")
	particle.direction=Vector2(1,.25);particle.spread=24;particle.gravity=Vector2(2,3);particle.initial_velocity_min=10;particle.initial_velocity_max=25
	particle.angular_velocity_min=-24;particle.angular_velocity_max=30
	particle.scale_amount_min=[.035,.05,.14][depth];particle.scale_amount_max=[.06,.09,.24][depth]
	particle.modulate=Color(.03,.035,.05,.16 if depth==2 else .26) if dark else Color(.88,.94,1,.12 if depth==2 else .21)
	particle.color=Color.WHITE;particle.set_meta("full_amount",particle.amount)
	var ramp:=Gradient.new();ramp.offsets=PackedFloat32Array([0,.15,.8,1]);ramp.colors=PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)]);particle.color_ramp=ramp
	if depth!=1:particle.material=_near_blur if depth==2 else _blur
	return particle
func configure(ecology_id:String,seed_value:int,enabled:bool=true,merchant:bool=false,quiet:bool=false,layout:Dictionary={}) -> void:
	merchant_room=merchant;quiet_room=quiet;ambient_frame=-1;depth_origin_ready=false
	biome=ecology_id;room_seed=seed_value;wind=-1 if seed_value%2 else 1;active=enabled
	rainy=is_rainy(ecology_id,seed_value) and enabled and not merchant_room and not quiet_room
	for rain in rain_layers:rain.emitting=rainy;rain.visible=rainy
	_sync_rain_audio()
	middle_structures=NewArt.middle_plan(seed_value,room_bounds,layout,biome,quiet_room)
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
	if spores!=null:spores.emitting=enabled and biome in ["grass","underground"];spores.visible=spores.emitting
	for particle in foreground+mid_particles:particle.emitting=enabled;particle.visible=enabled
	if focus!=null:focus.visible=enabled
	for particle in ambient+foreground+mid_particles+rain_layers+[spores]:
		particle.process_mode=Node.PROCESS_MODE_DISABLED if quiet_room or not enabled or not particle.emitting else Node.PROCESS_MODE_INHERIT
func update_view(camera:Vector2,zoom:float,world:Transform2D,player:Vector2,time:float,speed:float,reduced:bool) -> void:
	if middle==null:return
	if not active:return
	if not depth_origin_ready:depth_origin=camera;depth_origin_ready=true
	if reduced:
		middle.material=null;near_layer.material=null
		for particle in ambient+foreground+mid_particles+rain_layers:particle.material=null
	near_layer.visible=not quiet_room
	for particle in foreground+mid_particles:particle.visible=not quiet_room;particle.emitting=not quiet_room;particle.process_mode=Node.PROCESS_MODE_DISABLED if quiet_room else Node.PROCESS_MODE_INHERIT
	if effects_reduced!=reduced:
		effects_reduced=reduced
		middle_objects.material=preload("res://scripts/depth_style_v32.gd").material(biome,"middle",reduced)
		for particle in ambient+foreground+mid_particles+rain_layers:
			particle.material=null if reduced else (_near_blur if particle in foreground else _blur)
	var quiet:bool=quiet_room or not active
	if quiet:
		for particle in ambient+foreground+mid_particles+rain_layers+[spores]:particle.emitting=false;particle.visible=false;particle.process_mode=Node.PROCESS_MODE_DISABLED
		focus.visible=false;near_layer.visible=false
		middle_objects.transform=depth_transform(camera,zoom,MID_FACTOR)
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
	middle_objects.transform=depth_transform(camera,zoom,MID_FACTOR)
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
	var mid:Transform2D=parallax(camera,zoom,.50)
	for particle in mid_particles:
		particle.transform=mid*Transform2D(0,Vector2(750,550));particle.direction=Vector2(wind,.25);particle.gravity=Vector2(wind*3+sin(time*.12)*2,4);particle.speed_scale=speed
		var amount:int=maxi(2,int(particle.get_meta("full_amount",15))*(.2 if reduced else 1))
		if particle.amount!=amount:particle.amount=amount
	for i in foreground.size():
		var particle:CPUParticles2D=foreground[i]
		var factor:float=1.0 if i<2 else 1.18
		particle.transform=parallax(camera,zoom,factor)*Transform2D(0,Vector2(750,550));particle.direction=Vector2(wind,.22);particle.gravity=Vector2(wind*4,6);particle.speed_scale=speed
		var amount:int=maxi(2,int(particle.get_meta("full_amount",15))*(.2 if reduced else 1))
		if particle.amount!=amount:particle.amount=amount
	for particle in ambient:
		particle.emitting=active and not reduced;particle.visible=particle.emitting;particle.process_mode=Node.PROCESS_MODE_INHERIT if particle.emitting else Node.PROCESS_MODE_DISABLED
	spores.emitting=active;spores.visible=spores.emitting;spores.process_mode=Node.PROCESS_MODE_INHERIT if spores.emitting else Node.PROCESS_MODE_DISABLED
	focus.visible=active and not reduced
	var mote_count:int=(28 if reduced else 84) if biome=="underground" else (24 if reduced else 68) if biome in ["trunk","grass","branches","canopy"] else (20 if reduced else 60)
	if spores.amount!=mote_count:spores.amount=mote_count
	spores.color=Color(1,.70,.30,.38) if biome=="underground" else Color(.48,1,.59,.42) if biome!="sky" else Color(.57,.88,1,.38)
	spores.direction=Vector2(wind,-.25) if biome=="sky" else Vector2(wind*.5,-1)
	spores.gravity=Vector2(wind*4+sin(time*.7)*3,-2)
	spores.initial_velocity_min=12;spores.initial_velocity_max=32 if biome=="sky" else 23
	spores.transform=world*Transform2D(0,Vector2(750,680));spores.speed_scale=speed
	focus.material.set_shader_parameter("focus",(world*(player-Vector2(0,22)))/Vector2(1280,720))
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

func _paint_middle_objects(c:CanvasItem) -> void:
	NewArt.draw_middle(c,biome,middle_structures)
