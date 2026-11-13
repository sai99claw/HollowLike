extends Node2D

const Cache = preload("res://scripts/cached_canvas.gd")
const Flow = preload("res://shaders/vfx_flow.gdshader")
const Water = preload("res://shaders/pool_water.gdshader")
enum { SHOT, SMOKE, BEAM, FIRE, SHAFT, VORTEX, SLASH }
const LIMITS := [28, 22, 8, 16, 4, 8, 12]
const Z := [-1, -1, 2, 1, -13, 2, 2]
static var white: Texture2D
static var halo: GradientTexture2D
static var noise: NoiseTexture2D
static var cells: NoiseTexture2D
var layers: Array[Node2D] = []
var commands: Array[Array] = [[], [], [], [], [], [], []]
var water: ColorRect
var copy: BackBufferCopy
var clock := 0.0
var reduced := false

static func shared_noise(cellular: bool = false) -> NoiseTexture2D:
	if cellular:
		if cells == null:
			cells = _noise(FastNoiseLite.TYPE_CELLULAR, 8221, .047)
		return cells
	if noise == null:
		noise = _noise(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 24019, .033)
	return noise

static func _noise(kind: int, seed_value: int, frequency: float) -> NoiseTexture2D:
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	var source := FastNoiseLite.new()
	source.noise_type = kind
	source.seed = seed_value
	source.frequency = frequency
	source.fractal_octaves = 3
	texture.noise = source
	return texture

func _ready() -> void:
	if white == null:
		var pixel := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		pixel.fill(Color.WHITE)
		white = ImageTexture.create_from_image(pixel)
		halo = GradientTexture2D.new()
		halo.width = 64
		halo.height = 64
		halo.fill = GradientTexture2D.FILL_RADIAL
		halo.fill_from = Vector2(.5, .5)
		halo.fill_to = Vector2(1, .5)
		var ramp := Gradient.new()
		ramp.offsets = PackedFloat32Array([0, .21, .57, 1])
		ramp.colors = PackedColorArray([Color.WHITE, Color(1,1,1,.64), Color(1,1,1,.16), Color(1,1,1,0)])
		halo.gradient = ramp
	for style in commands.size():
		var layer := Cache.new()
		layer.z_index = Z[style]
		var material := ShaderMaterial.new()
		material.shader = Flow
		material.set_shader_parameter("style", style)
		material.set_shader_parameter("noise_tex", shared_noise())
		layer.material = material
		layer.paint = _paint.bind(style)
		add_child(layer)
		layers.append(layer)

func begin(now: float, low: bool = false) -> void:
	clock = now
	reduced = low
	for style in commands.size():
		if not commands[style].is_empty():
			commands[style].clear()
			layers[style].invalidate()
	if water != null:
		water.hide()
		copy.copy_mode = BackBufferCopy.COPY_MODE_DISABLED

func flow(style: int, base: Transform2D, at: Vector2, size: Vector2, angle: float, tint: Color) -> void:
	var batch: Array = commands[style]
	if batch.size() >= int(LIMITS[style]) / (2 if reduced else 1) or tint.a <= .006:
		return
	if batch.is_empty():
		layers[style].material.set_shader_parameter("clock", clock)
		layers[style].invalidate()
	batch.append([base * Transform2D(angle, at), Rect2(-size * .5, size), tint])

func _paint(canvas: CanvasItem, style: int) -> void:
	for command: Array in commands[style]:
		canvas.draw_set_transform_matrix(command[0])
		canvas.draw_texture_rect(white, command[1], false, command[2])

func pool(rect: Rect2, base: Transform2D, tint: Color, recessed: bool) -> void:
	if not rect.has_area():
		return
	if water == null:
		copy = BackBufferCopy.new()
		copy.z_index = 1
		add_child(copy)
		water = ColorRect.new()
		water.mouse_filter = Control.MOUSE_FILTER_IGNORE
		water.z_index = 1
		var material := ShaderMaterial.new()
		material.shader = Water
		material.set_shader_parameter("cells", shared_noise(true))
		water.material = material
		add_child(water)
	water.position = base * rect.position
	water.size = rect.size * base.get_scale()
	copy.rect = Rect2(water.position, water.size).grow(5)
	copy.copy_mode = BackBufferCopy.COPY_MODE_RECT
	water.material.set_shader_parameter("clock", clock)
	water.material.set_shader_parameter("span", rect.size)
	water.material.set_shader_parameter("tint", tint)
	water.material.set_shader_parameter("recessed", 1.0 if recessed else 0.0)
	water.show()

func shot(c: CanvasItem, pr: Dictionary, base: Transform2D, radius: float, fallback: bool = false) -> void:
	var at: Vector2 = pr["pos"]
	var velocity: Vector2 = pr.get("vel", Vector2.RIGHT)
	var direction := velocity.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var side := direction.orthogonal()
	var tint: Color = pr.get("color", Color("abe7f1"))
	var friendly: bool = pr.get("from_player", false)
	var allegiance := Color("86f2ff") if friendly else Color("ff896e")
	var kind: String = pr.get("kind", "")
	var style: String = pr.get("style_id", "")
	var bubble := "bubble" in style
	var slash := kind in ["flying_slash", "wave"]
	var arc := absf(float(pr.get("gravity", 0.0))) > 20
	var tail := at - direction * radius * .48
	c.draw_set_transform_matrix(base)
	if not reduced and commands[SHOT].size() < LIMITS[SHOT]:
		if not bubble and not arc and not slash:
			flow(SHOT, base, tail, Vector2(radius * 4.6, radius * 2.5), direction.angle(), Color(tint.lerp(allegiance,.32), .49))
		var age: float = pr.get("elapsed", 0.0)
		for i in 3:
			var phase := fposmod(age * (4.5 + i * .6) + i * .37, 1.0)
			var spark := at - direction * radius * (1.1 + 2.8 * phase) + side * sin(i * 4.1 + phase * 3.2) * radius * phase
			c.draw_line(spark - direction * (2.5 + radius * .22), spark, Color(allegiance, (1.0 - phase) * .71), 1.2, true)
	if not fallback:
		return
	if slash:
		var angle := direction.angle()
		c.draw_arc(at - direction * radius * .8, radius * 1.55, angle - 1.13, angle + 1.13, 16, Color(allegiance,.76), radius * .35, true)
		c.draw_arc(at - direction * radius * .8, radius * 1.55, angle - .88, angle + .88, 16, Color("fff8de"), 1.6, true)
	elif bubble:
		c.draw_circle(at, radius * .81, Color(tint,.24), true, -1, true)
		c.draw_arc(at, radius * .81, 0, TAU, 24, Color(tint.lightened(.42),.89), 1.7, true)
		c.draw_arc(at, radius * .64, 3.65, 4.93, 10, Color("ecffff"), 1.7, true)
	elif arc or pr.get("trap_carrier", false):
		var shell := PackedVector2Array([at + direction*radius, at + side*radius*.66, at - direction*radius*.76, at - side*radius*.62])
		c.draw_colored_polygon(shell, tint.darkened(.22))
		shell.append(shell[0])
		c.draw_polyline(shell, tint.lightened(.49), 1.8, true)
	else:
		c.draw_line(at - direction * radius, at + direction * radius * .64, Color(allegiance,.85), radius * .56, true)
		c.draw_line(at - direction * radius * .20, at + direction * radius * .64, Color("fffbe7"), maxf(1.5,radius * .14), true)

func burst(c: CanvasItem, effect: Dictionary, base: Transform2D) -> void:
	var age := _age(effect)
	var at: Vector2 = effect["pos"]
	var normal: Vector2 = effect.get("normal", Vector2.ZERO)
	var radius := clampf(float(effect["radius"]), 10.0, 420.0)
	var color: Color = effect.get("color", Color("ffb871"))
	var arc := TAU if normal == Vector2.ZERO else PI * .96
	var start := 0.0 if normal == Vector2.ZERO else normal.angle() - arc * .5
	var flash := pow(1.0 - smoothstep(0.0, .33, age), 2.0)
	var center := at + normal * radius * .24
	c.draw_set_transform_matrix(base)
	if flash > .01:
		var size := Vector2.ONE * radius * (.71 + age * .65)
		c.draw_texture_rect(halo, Rect2(center - size * .5, size), false, Color(color,flash * .82))
		c.draw_circle(center, radius * (.08 + .15 * flash), Color("fff6cd", flash * .88), true, -1, true)
	var shock := radius * lerpf(.22, 1.11, 1.0 - pow(1.0 - age, 2.35))
	var ring := pow(1.0 - age, 2.1)
	if ring > .035:
		var segments := 3 if normal != Vector2.ZERO else 5
		for i in segments:
			var from := start + arc * i / segments
			var length := arc * (.69 + .17 * sin(i * 1.7 + .6)) / segments
			var points := PackedVector2Array()
			var colors := PackedColorArray()
			for j in 13:
				var t := float(j) / 12.0
				var angle := from + length * t
				var uneven := 1.0 + sin(angle * 6.0 + age * 4.0) * .027
				points.append(at + Vector2.from_angle(angle) * shock * uneven)
				colors.append(Color(color.lightened(.62), sin(PI * t) * ring * .71))
			c.draw_polyline_colors(points, colors, 1.7 + flash, true)
	var count := 7 if reduced else 16
	for i in count:
		var direction := Vector2.from_angle(start + (float(i) + .5) / count * arc + sin(i * 13.7) * .07)
		var distance := radius * (.13 + age * (.58 + .42 * absf(sin(i * 3.17 + .6))))
		var ember := at + direction * distance + Vector2.DOWN * radius * .17 * age * age
		if normal != Vector2.ZERO and (ember - at).dot(normal) < 0:
			continue
		var length := minf(radius * (.07 + flash * .15), distance * .56)
		var spark_alpha := (1.0 - age) * (.66 + .34 * absf(sin(i * 4.2)))
		c.draw_line(ember - direction * length, ember, Color(color,.54 * spark_alpha), 3.2, true)
		c.draw_line(ember - direction * length * .51, ember, Color("fff2ca",spark_alpha), 1.2, true)
		if i % (3 if reduced else 4) != 0:
			continue
		var size := radius * (.38 + age * .33)
		var drift := direction * distance * .62
		var smoke := at + drift + normal * size * .62 - Vector2(0, age * size * .28)
		flow(SMOKE,base,smoke,Vector2(size * 1.30, size),direction.angle(),Color(color.darkened(.66), sin(PI * age) * .83))
		if flash > .02:
			flow(FIRE,base,at + drift * .57 + normal * size * .52,Vector2(size * 1.06,size),normal.angle() + PI * .5 if normal != Vector2.ZERO else direction.x * .28,Color(color,flash * .90))

func beam(c: CanvasItem, effect: Dictionary, base: Transform2D) -> void:
	var at: Vector2 = effect["pos"]
	var end: Vector2 = effect["end"]
	var delta := end - at
	if delta.length_squared() < .01:
		return
	var age := _age(effect)
	var width: float = effect["width"]
	var color: Color = effect["color"]
	var energy := (1.0 - smoothstep(.35, 1.0, age)) * smoothstep(0.0, .1, age + .06)
	c.draw_set_transform_matrix(base)
	c.draw_line(at, end, Color(color,.33 * energy), width, true)
	c.draw_line(at, end, Color(color.lightened(.42),.75 * energy), width * .35, true)
	c.draw_line(at, end, Color("fffdf5",energy), maxf(1.1, width * .11), true)
	flow(BEAM,base,at.lerp(end,.5),Vector2(delta.length(),width),delta.angle(),Color(color,energy * .87))

static func lightning(c: CanvasItem, effect: Dictionary, base: Transform2D) -> void:
	var at: Vector2 = effect["pos"]
	var end: Vector2 = effect["end"]
	var age := _age(effect)
	var alpha := 1.0 - age
	var delta := end - at
	var side := delta.normalized().orthogonal()
	var tick := floorf(age * 8.0)
	var points := PackedVector2Array([at])
	for i in range(1, 12):
		var t := float(i) / 12.0
		points.append(at.lerp(end,t) + side * sin(t * PI) * sin(i * 13.27 + tick * 6.41 + at.x * .06) * minf(24.0,delta.length() * .15))
	points.append(end)
	c.draw_set_transform_matrix(base)
	c.draw_polyline(points, Color(.34,.38,1,alpha * .32), 10, true)
	c.draw_polyline(points, Color(.56,.78,1,alpha * .81), 3.4, true)
	c.draw_polyline(points, Color(.91,.98,1,alpha), 1.2, true)
	for i in [3, 8]:
		var tip := points[i] + side * sin(i + tick) * minf(45.0,delta.length() * .22) + delta * .08
		c.draw_polyline(PackedVector2Array([points[i], points[i].lerp(tip,.49) + side * 6, tip]), Color(.69,.77,1,alpha * .67), 1.3, true)

func gas(base: Transform2D, at: Vector2, age: float, hostile: bool) -> void:
	var color := Color("ba78d1") if hostile else Color("91bf69")
	var density := smoothstep(0.0,.14,age + .04) * (1.0 - smoothstep(.47,1.0,age))
	var count := 2 if reduced else 4
	for i in count:
		var offset := (float(i) / float(count - 1) - .5) * (68.0 + age * 33.0)
		var rise := sin(clock * 1.6 + i * 2.3) * 7.0 - age * 13.0
		var size := Vector2(89,58) * (1.0 + age * .22)
		flow(SMOKE,base,at + Vector2(offset,rise + 8),size,sin(i * 1.7) * .31,Color(color.darkened(.43),density * .58))
		flow(SMOKE,base,at + Vector2(offset * .92,rise - 7),size * .68,-.24,Color(color,density * .52))

func fire(base: Transform2D, at: Vector2, width: float, strength: float) -> void:
	for i in (2 if reduced else 4):
		var count := 2 if reduced else 4
		var x := (float(i) - float(count - 1) * .5) * width * (.38 if reduced else .21)
		var height := (34.0 + sin(clock * 6.8 + i * 3.4) * 9.0) * strength
		flow(FIRE,base,at + Vector2(x,-height * .45),Vector2(width * .52,height),sin(i * 1.7) * .18,Color(1,.44,.13,.91 * strength))
		if not reduced:
			flow(SMOKE,base,at + Vector2(x + sin(clock * 2.0 + i) * 9,-height * 1.17),Vector2(52,32),.2,Color(.44,.32,.29,.34 * strength))

func charge(c: CanvasItem, base: Transform2D, at: Vector2, amount: float, lift: bool, alpha: float = 1.0) -> void:
	var strength := clampf(amount,0,1)
	var tint := Color("c5eee5") if lift else Color("efcea0").lerp(Color("e7e1fc"),strength)
	var center := at - Vector2(0,9)
	var width := 68.0 + strength * 49.0
	var size := Vector2(width, 27 + strength * 10.0)
	flow(VORTEX,base,center,size,0,Color(tint,(.38 + .56 * strength) * alpha))
	if not reduced:
		flow(SMOKE,base,center + Vector2(-width * .22, 1),Vector2(width * .66,24),-.12,Color(tint.darkened(.38),alpha * .49))
		flow(SMOKE,base,center + Vector2(width * .22,-6),Vector2(width * .73,23),.19,Color(tint,alpha * .36))
	c.draw_set_transform_matrix(base)
	for i in (5 if reduced else 11):
		var t := fposmod(clock * (1.05 + strength * .77) + i * .19,1.0)
		var angle := clock * (3.7 + strength * 2.3) + i * 2.39996
		var distance := lerpf(1.0,.21,t)
		var particle := center + Vector2(cos(angle) * width * .49 * distance,sin(angle) * 9.0 * distance - t * (12.0 if lift else 30.0))
		var light := sin(PI * t) * alpha * (.36 + strength * .64)
		c.draw_line(particle + Vector2(-cos(angle)*4.8,2.4),particle,Color(tint.lightened(.49),light),1.6,true)

func gust(base: Transform2D, center: Vector2, direction: Vector2, length: float, alpha: float) -> void:
	var facing := direction.normalized()
	flow(SHOT,base,center - facing * length * .18,Vector2(length,39),facing.angle(),Color(.56,.83,.82,alpha))
	flow(SLASH,base,center - facing * length * .18,Vector2(length * 1.08,58),facing.angle(),Color(.91,.99,.87,alpha * .86))
	if not reduced:
		flow(SMOKE,base,center - facing * length * .48,Vector2(length * .70,34),facing.angle(),Color(.53,.69,.73,alpha * .47))

static func _age(effect: Dictionary) -> float:
	return clampf(1.0 - float(effect["life"]) / maxf(.001,float(effect["max"])),0.0,1.0)
