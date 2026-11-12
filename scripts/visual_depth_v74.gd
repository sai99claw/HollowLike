extends Node2D
const FOREGROUND_FACTOR:float=1.35
const Cache=preload("res://scripts/cached_canvas.gd")
const Edge=preload("res://scripts/platform_overhang_v74.gd")
var ambient:CanvasModulate
var grade:Environment
var lantern:PointLight2D
var lights:Array[PointLight2D]=[]
var foreground:ColorRect
var vignette:ColorRect
var fogs:Array[ColorRect]=[]
var details:Node2D
var drifting_feathers:Node2D
var bokeh:Node2D
var spores:GPUParticles2D
var soft:GradientTexture2D
var feather:Texture2D
var shapes:Array[Dictionary]=[]
var region:=Rect2()
var safe:=Rect2(0,0,1280,720)
var origin:=Vector2.INF
var drift:=Vector2.ZERO
var fog_y:float=INF
var time:float=0.0
var reduced:bool=false

func _ready() -> void:
	ambient=CanvasModulate.new()
	ambient.color=Color("9e96ab")
	add_child(ambient)
	var world:=WorldEnvironment.new()
	grade=Environment.new()
	grade.background_mode=Environment.BG_CANVAS
	grade.background_canvas_max_layer=0
	grade.glow_intensity=.23
	grade.glow_bloom=.035
	grade.glow_hdr_threshold=.88
	world.environment=grade
	add_child(world)
	soft=GradientTexture2D.new()
	soft.width=96
	soft.height=96
	soft.fill=GradientTexture2D.FILL_RADIAL
	soft.fill_from=Vector2(.5,.5)
	soft.fill_to=Vector2(1,.5)
	var ramp:=Gradient.new()
	ramp.offsets=PackedFloat32Array([0,.18,.47,.76,1])
	ramp.colors=PackedColorArray([Color.WHITE,Color(1,1,1,.75),Color(1,1,1,.33),Color(1,1,1,.09),Color(1,1,1,0)])
	soft.gradient=ramp
	lantern=_light(Color("fff0d7"),.8)
	for depth:int in [-12,3]:
		var fog:=_overlay("GroundFog",depth,preload("res://shaders/ground_fog_v74.gdshader"))
		fog.material.set_shader_parameter("haze",Color(.43,.46,.66,.19) if depth<0 else Color(.61,.48,.59,.15))
		fogs.append(fog)
	foreground=_overlay("SuperForeground",10,preload("res://shaders/super_foreground_v74.gdshader"))
	vignette=_overlay("Vignette",12,preload("res://shaders/corner_vignette_v74.gdshader"))
	feather=preload("res://scripts/combat_visual.gd").texture_for("death_feather_glow")
	drifting_feathers=Cache.new()
	drifting_feathers.z_index=4
	drifting_feathers.paint=_paint_feathers
	add_child(drifting_feathers)
	bokeh=Cache.new()
	bokeh.z_index=11
	bokeh.paint=_paint_bokeh
	add_child(bokeh)
	details=Cache.new()
	details.z_index=6
	details.paint=func(canvas:CanvasItem)->void:Edge.draw(canvas,shapes,region)
	details.material=ShaderMaterial.new()
	details.material.shader=preload("res://shaders/overhang_sway_v74.gdshader")
	add_child(details)
	_build_spores()

func _overlay(label:String,z:int,shader:Shader) -> ColorRect:
	var layer:=ColorRect.new()
	layer.name=label
	layer.z_index=z
	layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.material=ShaderMaterial.new()
	layer.material.shader=shader
	add_child(layer)
	return layer

func _light(tint:Color,energy:float) -> PointLight2D:
	var light:=PointLight2D.new()
	light.texture=soft
	light.color=tint
	light.energy=energy
	light.range_z_min=-10
	light.range_z_max=6
	add_child(light)
	return light

func _build_spores() -> void:
	spores=GPUParticles2D.new()
	spores.name="GlowingSpores"
	spores.z_index=5
	spores.amount=76
	spores.lifetime=8.0
	spores.preprocess=8.0
	spores.local_coords=true
	spores.visibility_rect=Rect2(-1000,-650,2000,1300)
	spores.texture=soft
	var blend:=CanvasItemMaterial.new()
	blend.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	blend.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	spores.material=blend
	var flow:=ParticleProcessMaterial.new()
	flow.particle_flag_disable_z=true
	flow.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	flow.emission_box_extents=Vector3(690,425,0)
	flow.direction=Vector3(.3,-1,0)
	flow.spread=55
	flow.gravity=Vector3(2,-1,0)
	flow.initial_velocity_min=4
	flow.initial_velocity_max=15
	flow.scale_min=.021
	flow.scale_max=.052
	flow.color_initial_ramp=_ramp(PackedFloat32Array([0,1]),PackedColorArray([Color("ffcf77"),Color("b0f1f5")]))
	flow.color_ramp=_ramp(PackedFloat32Array([0,.22,.43,.65,1]),PackedColorArray([Color(1,1,1,0),Color(1,1,1,.86),Color(1,1,1,.24),Color(1,1,1,.8),Color(1,1,1,0)]))
	spores.process_material=flow
	add_child(spores)

func _ramp(offsets:PackedFloat32Array,colors:PackedColorArray) -> GradientTexture1D:
	var texture:=GradientTexture1D.new()
	var gradient:=Gradient.new()
	gradient.offsets=offsets
	gradient.colors=colors
	texture.gradient=gradient
	return texture

func configure(layout:Dictionary,solids:Array,doors:Array,props:Array,active:bool,biome:String="trunk") -> void:
	origin=Vector2.INF
	fog_y=INF
	shapes.clear()
	if active:shapes=Edge.plan(layout,solids)
	details.invalidate()
	for light:PointLight2D in lights:
		light.hide()
		light.queue_free()
	lights.clear()
	for door:Dictionary in doors:_warm(Vector2(door["pos"])-Vector2(0,43),164)
	var luminous:Array={"underground":[0,1,4],"trunk":[3,5],"sky":[2,3]}.get(biome,[])
	for prop:Dictionary in props:
		if prop.get("kind")=="launcher" or (prop.get("kind")=="ecology_object" and int(prop.get("variant",-1)) in luminous):
			_warm(Vector2(prop["pos"])-Vector2(0,23),144)

func _warm(at:Vector2,radius:float) -> void:
	var light:=_light(Color("ffc178"),.53)
	light.set_meta("at",at)
	light.set_meta("radius",radius)
	lights.append(light)
	var pulse:=light.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	pulse.tween_property(light,"energy",.67,1.35+fposmod(at.x,100.0)*.008)
	pulse.tween_property(light,"energy",.46,1.55)

func update_view(camera:Vector2,base:Transform2D,viewport:Rect2,feet:Vector2,floor_y:float,now:float,active:bool,low:bool,paused:bool,visible_region:Rect2) -> void:
	var dt:float=clampf(now-time,0,.1)
	time=now
	safe=viewport
	reduced=low
	if not origin.is_finite():origin=camera
	drift=(camera-origin)*FOREGROUND_FACTOR
	var zoom:float=base.x.length()
	ambient.visible=active
	if grade.glow_enabled!=(active and not low):grade.glow_enabled=active and not low
	lantern.enabled=active
	lantern.position=base*(feet-Vector2(0,27))
	lantern.texture_scale=440.0*zoom/soft.get_width()
	var count:int=0
	for light:PointLight2D in lights:
		var at:Vector2=base*Vector2(light.get_meta("at"))
		light.enabled=active and count<(2 if low else 5) and safe.grow(180).has_point(at)
		if not light.enabled:continue
		count+=1
		light.position=at
		light.texture_scale=float(light.get_meta("radius"))*2.0*zoom/soft.get_width()
	for layer:ColorRect in [foreground,vignette]:
		layer.position=safe.position
		layer.size=safe.size
		layer.visible=active
	foreground.material.set_shader_parameter("drift",drift)
	foreground.material.set_shader_parameter("intensity",.82 if low else 1.0)
	if not is_finite(fog_y):fog_y=floor_y
	fog_y=lerpf(fog_y,floor_y,1.0-exp(-dt*4.5))
	for i in fogs.size():
		var fog:ColorRect=fogs[i]
		fog.visible=active and (i==0 or not low)
		fog.position=Vector2(safe.position.x,(base*Vector2(feet.x,fog_y)).y-(155.0 if i==0 else 57.0)*zoom)
		fog.size=Vector2(safe.size.x,(220.0 if i==0 else 85.0)*zoom)
		fog.material.set_shader_parameter("drift",camera.x*.002-time*.08)
	spores.position=safe.get_center()
	spores.visible=active
	if spores.emitting!=active:spores.emitting=active
	spores.speed_scale=0.0 if paused else 1.0
	var amount:int=32 if low else 76
	if spores.amount!=amount:spores.amount=amount
	drifting_feathers.visible=active
	if active:drifting_feathers.invalidate()
	bokeh.visible=active and not low
	if bokeh.visible:bokeh.invalidate()
	details.visible=active
	details.transform=base
	details.material.set_shader_parameter("sway_time",time)
	if region!=visible_region:
		region=visible_region
		details.invalidate()

func _paint_feathers(canvas:CanvasItem) -> void:
	if feather!=null:
		for i in (14 if reduced else 30):
			var depth:float=[.44,.78,1.08][i%3]
			var x:float=fposmod(i*.618+sin(time*.95+i)*.024-drift.x*.00049*depth,1.0)
			var y:float=fposmod(i*.373+time*(.021+depth*.012)-drift.y*.00052*depth,1.0)
			var at:Vector2=safe.position+Vector2(x,y)*safe.size
			var span:Vector2=feather.get_size()
			span*=(6.0+5.0*depth)/maxf(span.x,span.y)
			canvas.draw_set_transform(at,time*(.35+i%5*.16)+i)
			canvas.draw_texture_rect(feather,Rect2(-span*.5,span),false,Color(.8,.84,.98,.23) if i%2==0 else Color(.09,.065,.15,.42))
		canvas.draw_set_transform(Vector2.ZERO)

func _paint_bokeh(canvas:CanvasItem) -> void:
	for i in 10:
		var x:float=fposmod(i*.381+drift.x*.0013+time*.009,1.0)
		var edge:float=.045+fposmod(i*.129,.15)
		var at:Vector2=safe.position+Vector2(x,edge if i%2==0 else 1.0-edge)*safe.size
		var span:float=15+fposmod(i*7.17,15.0)
		canvas.draw_texture_rect(soft,Rect2(at-Vector2.ONE*span*.5,Vector2.ONE*span),false,Color(.86,.71,.43,.08+.07*(.5+.5*sin(time*.6+i))))
