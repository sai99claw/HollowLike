class_name WeaponArtV24
extends RefCounted
const Animated=preload("res://scripts/projectile_animation_v31.gd")
static var cache:Dictionary={}
static func texture(id:String,projectile:bool=false) -> Texture2D:
	if projectile and Animated.has(id):return Animated.texture(id)
	var key:String=("projectile_" if projectile else "weapon_")+id
	if cache.has(key):return cache[key]
	var path:String="res://assets/v24/weapons/"+("weapon_fire_flask" if id=="fire_flask" and projectile else key)+".png"
	if ResourceLoader.exists(path):cache[key]=load(path);return cache[key]
	return null
static func draw(c:CanvasItem,id:String,at:Vector2,heading:Vector2,radius:float,projectile:bool=true,base:Transform2D=Transform2D.IDENTITY,elapsed:float=0.0,launch_angle:float=0.0) -> bool:
	if projectile and Animated.has(id):return Animated.draw(c,id,at,heading,radius,elapsed,base,launch_angle)
	var image:Texture2D=texture(id,projectile)
	if image==null:return false
	var extent:Vector2=preload("res://scripts/projectile_readability_v25.gd").sprite_extent(image.get_size(),radius) if projectile else image.get_size()*(radius*2/maxf(image.get_width(),image.get_height()))
	var factor:float=extent.x/image.get_width()
	c.draw_set_transform_matrix(draw_transform(base,at,heading,factor))
	if projectile:
		for offset:Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:c.draw_texture(image,-image.get_size()*.5+offset*(1.5/maxf(factor,.001)),Color(.015,.025,.045,.85))
	c.draw_texture(image,-image.get_size()*.5)
	c.draw_set_transform_matrix(base)
	return true

static func draw_transform(base:Transform2D,at:Vector2,heading:Vector2,factor:float) -> Transform2D:
	return base*Transform2D(heading.angle(),Vector2.ONE*factor,0,at)
