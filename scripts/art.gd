class_name PigeonArt
extends RefCounted
## Deterministic, resolution independent game illustration. All anchors are feet.
## Phase animations are intentionally distinct: pull back, extend, then settle.

const Sprites=preload("res://scripts/sprite_art.gd")

const INK := Color("#253747")
const PALE := Color("#edf0e8")
const TEAL := Color("#65c8ab")
const GOLD := Color("#f5c86d")

# Reuse GPU-side geometry. Ellipses previously rebuilt/triangulated a 28-point
# polygon (56 trigonometric calls) every time, including every face detail.
static var _ellipse_meshes: Dictionary = {}
static var _box_styles: Dictionary = {}
static var _background_gradients: Dictionary = {}

static func _poly(c: CanvasItem, points: Array, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array(points), color)

static func _ellipse_mesh(segments: int) -> ArrayMesh:
	if _ellipse_meshes.has(segments):
		return _ellipse_meshes[segments]
	var vertices := PackedVector2Array([Vector2.ZERO])
	var indices := PackedInt32Array()
	for i in range(segments):
		var angle := float(i) / float(segments) * TAU
		vertices.append(Vector2(cos(angle), sin(angle)))
		indices.append_array(PackedInt32Array([0, i + 1, (i + 1) % segments + 1]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_ellipse_meshes[segments] = mesh
	return mesh

static func _ellipse(c: CanvasItem, center: Vector2, radii: Vector2, color: Color, segments: int = 20) -> void:
	var transform := Transform2D(Vector2(radii.x, 0), Vector2(0, radii.y), center)
	c.draw_mesh(_ellipse_mesh(segments), null, transform, color)

static func _line(c: CanvasItem, points: Array, color: Color, width: float = 2.0) -> void:
	c.draw_polyline(PackedVector2Array(points), color, width, false)

static func draw_pigeon(c: CanvasItem, pos: Vector2, face: float, t: float,
		anim: String = "idle", tint: Color = Color.WHITE, scale_value: float = 1.0,
		phase_progress: float = 0.0, base_transform: Transform2D = Transform2D.IDENTITY, weapon:String="quick",attack:Dictionary={}) -> void:
	if Sprites.player(c,pos,face,t,anim,tint,scale_value,phase_progress,base_transform,weapon,attack):return
	var dir := -1.0 if face < 0.0 else 1.0
	var bob := sin(t * 3.6) * 0.7
	var tilt := 0.0
	var wing := 0.0
	var head_offset := Vector2.ZERO
	var foot_step := 0.0
	match anim:
		"run":
			bob = -abs(sin(t * 15.0)) * 2.3
			tilt = 0.08
			foot_step = sin(t * 15.0) * 4.5
			wing = sin(t * 15.0) * 0.12
		"jump", "dash":
			bob = -1.0
			wing = -0.9 + sin(t * 15.0) * 0.2
			tilt = 0.12
		"wall":
			wing = -0.55
			tilt = -0.15
			head_offset = Vector2(1.0, -1.0)
		"hurt":
			tilt = -0.22
			wing = 0.65
			head_offset = Vector2(-3.0, 2.0)
		"charge":
			bob = sin(t * 45.0) * 0.45
			tilt = -0.11
			wing = -0.5
			head_offset = Vector2(-2.0, 1.5)
		"windup":
			tilt = -0.18 * phase_progress
			wing = -0.8 * phase_progress
			head_offset = Vector2(-3.0 * phase_progress, 1.5 * phase_progress)
		"active":
			tilt = 0.18
			wing = 0.9
			head_offset = Vector2(3.0, -1.0)
			bob = -1.5
		"recovery":
			tilt = lerpf(0.12, 0.0, phase_progress)
			wing = lerpf(0.55, 0.0, phase_progress)
			head_offset = Vector2(1.0, 1.0 - phase_progress)
	# Parent camera transform must survive every local illustration transform.
	c.draw_set_transform_matrix(base_transform)
	_ellipse(c, pos + Vector2(0.0, 1.0), Vector2(17.0, 3.0) * scale_value, Color(0.04, 0.12, 0.16, 0.21))
	# Feet stay on the collision anchor. Only the body bobs/leans, so landing
	# does not visually float above or slide below a platform.
	c.draw_set_transform_matrix(base_transform * Transform2D(0.0, Vector2(dir * scale_value, scale_value), 0.0, pos))
	_line(c, [Vector2(-5, -6 + bob), Vector2(-6 + foot_step, 0), Vector2(-11 + foot_step, 0)], Color("#d48f8b"), 2.4)
	_line(c, [Vector2(5, -6 + bob), Vector2(5 - foot_step, 0), Vector2(10 - foot_step, 0)], Color("#eeaaa1"), 2.4)
	c.draw_set_transform_matrix(base_transform * Transform2D(tilt * dir, Vector2(dir * scale_value, scale_value), 0.0, pos + Vector2(0.0, bob * scale_value)))
	var body_color := Color("#a7b9ca") * tint
	var wing_color := Color("#7a91ac") * tint
	var head_color := Color("#718ba2") * tint
	if anim == "hurt":
		body_color = body_color.lerp(Color("#ffe3d7"), 0.7)
		wing_color = wing_color.lerp(Color("#e56f6f"), 0.55)
	# Tail is behind the round body, with two readable dark feather bars.
	_poly(c, [Vector2(-12, -20), Vector2(-25, -15), Vector2(-22, -7), Vector2(-8, -10)], INK * tint)
	_line(c, [Vector2(-23, -13), Vector2(-12, -13)], Color("#647b92") * tint, 2.0)
	_ellipse(c, Vector2(-1, -17), Vector2(17, 15), INK)
	_ellipse(c, Vector2(-1, -18), Vector2(15.3, 13.8), body_color)
	_ellipse(c, Vector2(5, -16), Vector2(8, 10.7), Color("#d8dfdf") * tint)
	# Wing pose changes across windup/active/recovery, even without a weapon.
	var wing_tip := Vector2(-10.0 + wing * 13.0, -8.0 - abs(wing) * 8.0)
	# A convex four-point wing stays valid through the full flap range. The
	# old fixed fifth corner crossed the moving tip during jump poses and
	# produced a rendering error every frame.
	_poly(c, [Vector2(-7, -28), Vector2(5, -22), wing_tip + Vector2(5, 2), wing_tip + Vector2(-4, 0)], wing_color)
	_line(c, [Vector2(-11, -22), Vector2(-3, -16), wing_tip + Vector2(2, 0)], Color("#51687f") * tint, 2.6)
	_line(c, [Vector2(-14, -18), Vector2(-8, -12), wing_tip + Vector2(-1, 2)], Color("#405770") * tint, 2.4)
	# Pigeon's iridescent throat: teal and violet crescent patches.
	_ellipse(c, Vector2(5, -29) + head_offset, Vector2(8.1, 9.7), head_color)
	_ellipse(c, Vector2(7, -27) + head_offset, Vector2(5.7, 6.1), Color("#5cb9a0") * tint)
	_ellipse(c, Vector2(3.5, -28) + head_offset, Vector2(3.2, 5.5), Color("#9a8ab4") * tint)
	_ellipse(c, Vector2(7, -35) + head_offset, Vector2(10.3, 9.5), INK)
	_ellipse(c, Vector2(7.1, -35.5) + head_offset, Vector2(8.9, 8.4), head_color)
	# Pale forehead, alert amber eye and soft beak cere.
	_ellipse(c, Vector2(10.5, -38.1) + head_offset, Vector2(4.1, 3.0), Color("#cad8d6") * tint)
	c.draw_circle(Vector2(11, -35) + head_offset, 3.0, Color("#edbd73"))
	c.draw_circle(Vector2(11.7, -35) + head_offset, 1.65, INK)
	c.draw_circle(Vector2(12.2, -35.8) + head_offset, 0.6, Color.WHITE)
	_poly(c, [Vector2(14, -33) + head_offset, Vector2(23, -30.5) + head_offset, Vector2(15, -28.9) + head_offset], Color("#d9a65d"))
	_ellipse(c, Vector2(15.4, -32.5) + head_offset, Vector2(3.3, 1.7), PALE)
	if anim == "charge":
		c.draw_arc(Vector2(0, -22), 25.0 + sin(t * 8.0) * 2.0, -1.2, 1.1, 22, Color(1.0, 0.85, 0.45, 0.75), 1.6, false)
	c.draw_set_transform_matrix(base_transform)

static func draw_enemy(c: CanvasItem, pos: Vector2, face: float, t: float,
		kind: String = "melee", phase: String = "idle", phase_progress: float = 0.0,
		base_transform: Transform2D = Transform2D.IDENTITY, biome:String="branches",ranged:bool=false) -> void:
	if Sprites.enemy(c,pos,face,t,kind,phase,phase_progress,base_transform,ranged):return
	var scale_value:=1.7 if kind=="boss" else (1.25 if kind=="elite" else (.9 if kind=="fly" else 1.0))
	var dir:float=-1.0 if face<0 else 1.0
	var strike:=0.0
	if phase=="windup":strike=-phase_progress*.5
	elif phase=="active":strike=1.0
	elif phase=="recovery":strike=1.0-phase_progress
	var lean:float=strike*.16
	var color:=Color("87aa84")
	if biome=="underground":color=Color("8196aa")
	elif biome=="sky":color=Color("b2c7cf")
	if phase=="hurt":color=Color("ffbda6")
	c.draw_set_transform_matrix(base_transform*Transform2D(lean*dir,Vector2(dir*scale_value,scale_value),0,pos))
	if kind=="fly" or kind=="flyer":
		# Moth: wings attach to its thorax, symmetric lift, no legs / ground shadow.
		var flap:float=.45+absf(sin(t*13.0))*.55
		var wing_color:=Color("b9a1cd") if biome!="underground" else Color("8db4c4")
		if phase=="hurt":wing_color=Color("ffbaa9")
		for side in [-1,1]:
			var wing_tip:=Vector2(side*(17+21*flap),-31-12*flap)
			_poly(c,[Vector2(side*3,-28),wing_tip,Vector2(side*30,-15),Vector2(side*8,-13)],wing_color)
			_poly(c,[Vector2(side*4,-22),Vector2(side*27,-14),Vector2(side*16,-4),Vector2(side*3,-12)],wing_color.darkened(.22))
			_ellipse(c,Vector2(side*(14+8*flap),-24),Vector2(5,7),Color("635d88"))
			c.draw_circle(Vector2(side*(14+8*flap),-24),2.4,GOLD)
		_ellipse(c,Vector2(0,-23),Vector2(6,14),INK)
		_ellipse(c,Vector2(0,-25),Vector2(4,11),Color("d6c7b0"))
		_ellipse(c,Vector2(0,-35),Vector2(7,6),INK)
		c.draw_circle(Vector2(4,-35),2.2,Color("ffdb95"))
		_line(c,[Vector2(-3,-39),Vector2(-8,-45),Vector2(-11,-44)],wing_color,1.5)
		_line(c,[Vector2(3,-39),Vector2(8,-45),Vector2(11,-44)],wing_color,1.5)
	elif kind=="melee":
		# Low armored beetle silhouette and six separate walking legs.
		for i in 3:
			var x:float=-12+i*11
			var step:float=sin(t*8+i*PI*.7)*3
			_line(c,[Vector2(x,-13),Vector2(x-7,-5),Vector2(x-9+step,0)],INK,2.8)
		_ellipse(c,Vector2(-2,-20),Vector2(22,17),INK)
		_ellipse(c,Vector2(-3,-22),Vector2(19,14),color)
		_line(c,[Vector2(-4,-35),Vector2(-1,-23),Vector2(-2,-9)],color.darkened(.35),2.5)
		for i in 3:c.draw_circle(Vector2(-15+i*9,-27+abs(i-1)*2),3,Color("c8d59e"))
		_ellipse(c,Vector2(17,-19),Vector2(11,10),INK)
		c.draw_circle(Vector2(22,-21),2.6,GOLD)
		_line(c,[Vector2(24,-16),Vector2(32+strike*10,-22),Vector2(28+strike*10,-12)],Color("d7c58e"),3)
	elif kind=="ranged":
		# Seed slinger: upright leaf hood, satchel and a throwing arm.
		var step:float=sin(t*7)*3
		_line(c,[Vector2(-6,-10),Vector2(-9+step,0)],INK,4)
		_line(c,[Vector2(6,-10),Vector2(9-step,0)],INK,4)
		_ellipse(c,Vector2(0,-21),Vector2(14,16),Color("a6805c"))
		_ellipse(c,Vector2(-12,-18),Vector2(10,12),Color("71583f"))
		_poly(c,[Vector2(-13,-33),Vector2(-4,-46),Vector2(12,-40),Vector2(18,-28),Vector2(0,-30)],color.darkened(.1))
		_ellipse(c,Vector2(5,-32),Vector2(10,8),Color("dccba4"))
		c.draw_circle(Vector2(10,-33),2.2,INK)
		var hand:=Vector2(13+strike*19,-23-strike*7)
		_line(c,[Vector2(6,-24),hand],Color("d9b98b"),5)
		c.draw_circle(hand,5,Color("d4a477"))
		_line(c,[hand+Vector2(-4,-3),hand+Vector2(4,-3)],Color("65583d"),3)
	else:
		# Root guardians / boss: bark mask, branching limbs, no pigeon base sprite.
		var wood:=Color("a38a62") if kind!="boss" else Color("8c806e")
		if biome=="underground":wood=Color("7b8890")
		if phase=="hurt":wood=Color("ffbda6")
		for side in [-1,1]:
			_line(c,[Vector2(side*7,-15),Vector2(side*10,-5),Vector2(side*18,0)],wood.darkened(.25),7)
		_poly(c,[Vector2(-15,-34),Vector2(10,-38),Vector2(19,-9),Vector2(0,-4),Vector2(-19,-12)],wood)
		_line(c,[Vector2(-7,-33),Vector2(-3,-16),Vector2(4,-6)],wood.darkened(.3),2)
		_ellipse(c,Vector2(1,-37),Vector2(13,11),wood.darkened(.35))
		for side in [-1,1]:
			c.draw_circle(Vector2(side*5,-38),2.5,Color("d0efd2"))
			_line(c,[Vector2(side*8,-43),Vector2(side*12,-53),Vector2(side*19,-56)],wood,4)
			_ellipse(c,Vector2(side*18,-55),Vector2(7,3),color)
		var hand:=Vector2(24+strike*20,-22-strike*7)
		_line(c,[Vector2(10,-30),Vector2(22,-27),hand],wood,7)
		_line(c,[hand,hand+Vector2(12,-28)],wood.darkened(.2),7)
		_poly(c,[hand+Vector2(9,-32),hand+Vector2(25,-31),hand+Vector2(29,-13),hand+Vector2(9,-16)],Color("bcbd9a"))
		if kind=="boss":
			c.draw_circle(Vector2(0,-21),6,Color("a4d7c1"))
			c.draw_arc(Vector2(0,-21),9,0,TAU,16,Color("e8d5a4"),1.5,false)
	if phase=="windup":
		c.draw_line(Vector2(-8,-52),Vector2(8,-52),Color("ffbf83"),3,false)
	c.draw_set_transform_matrix(base_transform)

static func _cloud(c: CanvasItem, center: Vector2, width: float, color: Color) -> void:
	_ellipse(c, center, Vector2(width, width * 0.18), color)
	_ellipse(c, center + Vector2(-width * 0.35, -width * 0.08), Vector2(width * 0.38, width * 0.23), color)
	_ellipse(c, center + Vector2(width * 0.12, -width * 0.17), Vector2(width * 0.45, width * 0.30), color)

static func draw_background(c: CanvasItem, size: Vector2, height: int, t: float) -> void:
	if Sprites.background(c,size,height):return
	var top := Color("#b7d4d1")
	var bottom := Color("#dce4c5")
	if height >= 3:
		top = Color("#8db7d5")
		bottom = Color("#e1ecdf")
	elif height == 2:
		top = Color("#8db5a5")
		bottom = Color("#d9ddb1")
	elif height == -1:
		top = Color("#79968d")
		bottom = Color("#b6bd8d")
	elif height == -2:
		top = Color("#9eaf91")
		bottom = Color("#b7bf89")
	elif height <= -3:
		top = Color("#323e4c")
		bottom = Color("#58626a")
	var gradient_key := top.to_rgba32()
	if not _background_gradients.has(gradient_key):
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([top, bottom])
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 2
		texture.height = 64
		texture.fill_from = Vector2.ZERO
		texture.fill_to = Vector2.DOWN
		_background_gradients[gradient_key] = texture
	c.draw_texture_rect(_background_gradients[gradient_key], Rect2(Vector2.ZERO, size), false)
	if height > -3:
		c.draw_circle(Vector2(size.x * 0.74, size.y * 0.21), 58.0, Color(1, 0.94, 0.71, 0.25))
		c.draw_circle(Vector2(size.x * 0.74, size.y * 0.21), 35.0, Color(1, 0.96, 0.78, 0.46))
		for i in range(5):
			var x := fmod(float(i) * size.x * 0.29 + t * (2.0 + i * 0.25), size.x + 300.0) - 150.0
			_cloud(c, Vector2(x, size.y * (0.16 + float(i % 3) * 0.15)), 80.0 + i * 14.0, Color(0.97, 0.98, 0.91, 0.35))
	if height >= 3:
		# Airborne seeds quietly communicate altitude without filling the foreground.
		for i in range(16):
			var x := fmod(i * 117.0 + t * 9.0, size.x)
			var y := size.y * (0.15 + fmod(i * 0.173, 0.7)) + sin(t + i) * 8.0
			c.draw_line(Vector2(x, y), Vector2(x + 4, y - 2), Color(1, 1, 0.9, 0.5), 1.0, false)
	elif height <= -3:
		# Root silhouettes and warm subterranean specks.
		for i in range(7):
			var x := float(i) * size.x / 6.0
			_line(c, [Vector2(x, 0), Vector2(x + 30, size.y * 0.18), Vector2(x - 20, size.y * 0.38)], Color(0.08, 0.14, 0.17, 0.23), 17.0)
		for i in range(25):
			var center := Vector2(fmod(i * 139.0, size.x), fmod(i * 83.0, size.y))
			c.draw_circle(center, 1.5 + sin(t * 1.4 + i) * 0.5, Color(0.81, 0.82, 0.56, 0.20))
	else:
		var trunk := Color("#718878") if height >= 0 else Color("#6c7d66")
		trunk.a = 0.30
		_poly(c, [Vector2(size.x * 0.68, 0), Vector2(size.x * 0.80, 0), Vector2(size.x * 0.75, size.y), Vector2(size.x * 0.62, size.y)], trunk)
		for side in [-1, 1]:
			for i in range(4):
				var y := size.y * (0.15 + i * 0.24)
				var origin := Vector2(size.x * 0.71, y + 80)
				var tip := Vector2(size.x * 0.71 + side * size.x * 0.46, y - 30)
				_line(c, [origin, origin.lerp(tip, 0.5) + Vector2(0, 10), tip], trunk, 18.0 - i * 2.0)
				if height >= 0:
					for j in range(5):
						var leaf_pos := tip + Vector2(side * (j * 30 - 55), sin(j * 1.7) * 22)
						_ellipse(c, leaf_pos, Vector2(50, 28), Color(0.29, 0.48, 0.37, 0.12))
		if height == -2:
			for i in range(20):
				var x := float(i) * size.x / 19.0
				_poly(c, [Vector2(x - 13, size.y), Vector2(x + 4, size.y - 65 - i % 3 * 22), Vector2(x + 15, size.y)], Color(0.36, 0.48, 0.31, 0.28))
	if height==2:
		# Dense crown framing is visibly different from the open middle branches.
		for i in 9:
			var at:=Vector2(i*size.x/8,25+(i%3)*28)
			_ellipse(c,at,Vector2(160,78),Color("4f8069",.42))
			_ellipse(c,at+Vector2(30,30),Vector2(95,49),Color("83a773",.24))
	elif height<=-3:
		for i in 8:
			var at:=Vector2(70+i*170,size.y-40-(i%3)*40)
			c.draw_line(at,at-Vector2(0,18),Color("718e96"),3)
			_ellipse(c,at-Vector2(0,19),Vector2(12,5),Color("99b8ad",.65))
			_ellipse(c,at-Vector2(0,19),Vector2(23,13),Color("b7dabf",.06))
	# Light vignettes frame the room without obscuring collision surfaces.
	c.draw_rect(Rect2(0, 0, size.x, 6), Color(0.1, 0.19, 0.20, 0.05))

static func draw_platform(c: CanvasItem, rect: Rect2, height: int, debug:bool=false) -> void:
	if Sprites.platform(c,rect,height,debug):return
	var wood := Color("#826b56")
	var lip := Color("#c9c991")
	if height <= -3:
		wood = Color("#5a6062")
		lip = Color("#899787")
	c.draw_style_box(_rounded_box(wood, 7), rect)
	c.draw_line(rect.position + Vector2(6, 2), rect.position + Vector2(rect.size.x - 6, 2), lip, 4.0, false)
	c.draw_line(rect.position + Vector2(8, rect.size.y - 3), rect.position + Vector2(rect.size.x - 8, rect.size.y - 3), Color(0.22, 0.20, 0.18, 0.3), 2.0, false)
	for i in range(int(rect.size.x / 40.0)):
		var x := rect.position.x + i * 40.0 + 17.0
		c.draw_line(Vector2(x, rect.position.y + 8), Vector2(x + 13, rect.position.y + 10), Color(0.23, 0.19, 0.15, 0.22), 1.0, false)
	if height > -3:
		for i in range(int(rect.size.x / 70.0)):
			var x := rect.position.x + i * 70.0 + 25.0
			_line(c, [Vector2(x, rect.position.y), Vector2(x - 3, rect.position.y - 5)], Color("#90aa72"), 1.8)
			_line(c, [Vector2(x + 3, rect.position.y), Vector2(x + 6, rect.position.y - 4)], Color("#adc184"), 1.5)

static func _rounded_box(color: Color, radius: int) -> StyleBoxFlat:
	var key := str(color.to_rgba32()) + ":" + str(radius)
	if _box_styles.has(key):
		return _box_styles[key]
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 3
	style.anti_aliasing = false
	_box_styles[key] = style
	return style

static func draw_nest(c: CanvasItem, pos: Vector2, t: float) -> void:
	if Sprites.module(c,"nest",Rect2(pos-Vector2(78,60),Vector2(156,65))):return
	_ellipse(c, pos + Vector2(0, 5), Vector2(80, 17), Color(0.18, 0.20, 0.15, 0.17))
	_ellipse(c, pos, Vector2(78, 26), Color("#886b4d"))
	_ellipse(c, pos + Vector2(0, -5), Vector2(65, 19), Color("#614e3d"))
	for i in range(17):
		var a := float(i) / 17.0 * TAU
		var b := a + 0.48
		var start := pos + Vector2(cos(a) * 72.0, sin(a) * 22.0)
		var end := pos + Vector2(cos(b) * 76.0, sin(b) * 24.0 + 5)
		c.draw_line(start, end, Color("#c0a46b") if i % 2 == 0 else Color("#a58c5c"), 3.0, false)
	_ellipse(c, pos + Vector2(-15, -9), Vector2(10, 13), Color("#e8e4cc"))
	_ellipse(c, pos + Vector2(8, -12), Vector2(9, 12), Color("#f0ebd7"))
	c.draw_circle(pos + Vector2(-18, -13), 1.2, Color("#bdbca3"))
	c.draw_circle(pos + Vector2(11, -14), 1.0, Color("#bdbca3"))
	var leaf_pos := pos + Vector2(55, -5 + sin(t * 2.0) * 1.0)
	_ellipse(c, leaf_pos, Vector2(13, 5), Color("#aab779"))

static func draw_portal(c: CanvasItem, pos: Vector2, _label_unused: String, t: float, warrior: bool) -> void:
	if Sprites.module(c,"door_rogue" if warrior else "door_musou",Rect2(pos-Vector2(92,205),Vector2(184,210))):return
	var accent := Color("#b398d1") if warrior else Color("#ddbb78")
	var portal_rect := Rect2(pos + Vector2(-58, -118), Vector2(116, 118))
	var outer := _rounded_box(Color("#607b71"), 24)
	outer.border_color = Color("#a9bba1")
	outer.set_border_width_all(3)
	c.draw_style_box(outer, portal_rect)
	var inside := _rounded_box(Color("#304f50"), 19)
	c.draw_style_box(inside, portal_rect.grow(-8))
	_ellipse(c, pos + Vector2(0, -6), Vector2(38, 8), Color(accent, 0.15))
	if warrior:
		draw_pigeon(c, pos + Vector2(-2, -24), 1.0, t, "idle", Color("#d0c8dc"), 1.55)
		# A short heroic cloak and leaf blade in front of the pigeon emblem.
		_poly(c, [pos + Vector2(-24, -64), pos + Vector2(-38, -28), pos + Vector2(-12, -24), pos + Vector2(-5, -58)], Color("#846c9f"))
		c.draw_line(pos + Vector2(20, -37), pos + Vector2(34, -87), Color("#e8ecd6"), 5.0, false)
		c.draw_line(pos + Vector2(10, -41), pos + Vector2(31, -35), GOLD, 4.0, false)
	else:
		var takeoff := sin(t * 1.7)
		var bird_y := -26.0 - maxf(0.0, takeoff) * 13.0
		var face := 1.0 if sin(t * 0.8) > -0.45 else -1.0
		draw_pigeon(c, pos + Vector2(0, bird_y), face, t, "jump" if takeoff > 0.0 else "idle", Color.WHITE, 1.55)
		if takeoff > 0.0:
			for i in range(3):
				var y := pos.y - 17 + i * 7
				c.draw_line(Vector2(pos.x - 22, y), Vector2(pos.x + 22, y), Color(accent, (1.0 - i * 0.2) * 0.4), 1.5, false)
	for i in range(4):
		var angle := t * 0.6 + i * TAU / 4.0
		var spark := pos + Vector2(cos(angle) * 51, -60 + sin(angle) * 49)
		c.draw_circle(spark, 1.9, Color(accent, 0.7))
