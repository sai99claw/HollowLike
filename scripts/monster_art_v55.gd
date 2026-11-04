class_name MonsterArtV55
extends RefCounted

const ROOT: String = "res://assets/v55/monsters/"
const CELL := Vector2(144, 112)
const ANCHOR := Vector2(72, 106)
const REFERENCE_HEIGHT: float = 74.0
const POSE_BOUNDS: Dictionary = {
	"sky": [
		Vector2i(97, 73), Vector2i(94, 50), Vector2i(91, 67), Vector2i(106, 47), Vector2i(84, 56), Vector2i(104, 28),
		Vector2i(83, 73), Vector2i(96, 74), Vector2i(77, 79), Vector2i(115, 73), Vector2i(74, 68), Vector2i(101, 38),
		Vector2i(94, 73), Vector2i(94, 66), Vector2i(74, 101), Vector2i(112, 79), Vector2i(83, 77), Vector2i(116, 38),
		Vector2i(74, 73), Vector2i(86, 69), Vector2i(85, 76), Vector2i(117, 71), Vector2i(72, 61), Vector2i(101, 25),
		Vector2i(90, 73), Vector2i(96, 69), Vector2i(86, 83), Vector2i(125, 72), Vector2i(93, 64), Vector2i(104, 37),
	],
	"trunk": [
		Vector2i(79, 73), Vector2i(84, 48), Vector2i(58, 70), Vector2i(91, 56), Vector2i(77, 55), Vector2i(74, 27),
		Vector2i(110, 60), Vector2i(120, 45), Vector2i(97, 77), Vector2i(134, 56), Vector2i(102, 48), Vector2i(120, 40),
		Vector2i(123, 60), Vector2i(132, 56), Vector2i(105, 82), Vector2i(132, 58), Vector2i(101, 56), Vector2i(134, 36),
		Vector2i(109, 65), Vector2i(115, 61), Vector2i(100, 86), Vector2i(134, 57), Vector2i(101, 56), Vector2i(124, 42),
		Vector2i(72, 73), Vector2i(88, 66), Vector2i(82, 82), Vector2i(111, 67), Vector2i(67, 59), Vector2i(99, 33),
	],
	"underground": [
		Vector2i(81, 59), Vector2i(94, 57), Vector2i(86, 80), Vector2i(134, 72), Vector2i(82, 57), Vector2i(116, 43),
		Vector2i(92, 69), Vector2i(111, 69), Vector2i(93, 80), Vector2i(136, 73), Vector2i(88, 65), Vector2i(129, 51),
		Vector2i(102, 36), Vector2i(106, 39), Vector2i(88, 70), Vector2i(135, 47), Vector2i(95, 36), Vector2i(106, 25),
		Vector2i(88, 74), Vector2i(92, 72), Vector2i(78, 88), Vector2i(129, 67), Vector2i(80, 69), Vector2i(109, 31),
		Vector2i(82, 74), Vector2i(89, 69), Vector2i(82, 77), Vector2i(118, 73), Vector2i(82, 64), Vector2i(100, 38),
	],
}
static var sheets: Dictionary = {}

static func actor_sample(en: Dictionary, time: float) -> Dictionary:
	var attack: Variant = en.get("attack")
	var phase: String = attack.phase if attack != null else "idle"
	var column: int = 0
	match phase:
		"windup":
			column = 1 if attack.progress() < .2 else 2
		"active":
			column = 3 if attack.progress() < .82 else 4
		"recovery":
			column = 4 if attack.progress() < .68 else 0
		_:
			if Vector2(en.get("vel", Vector2.ZERO)).length_squared() >= 9.0 or en.get("move") == "fly":
				column = posmod(floori(time * 8.0), 2)
	return {"sheet": "v55", "row": int(en.get("v55_row", -1)), "column": column, "phase": phase}

static func _pose_size(en: Dictionary, column: int) -> Vector2:
	var biome: String = en.get("roster_biome", "")
	var row: int = int(en.get("v55_row", -1))
	var height: float = float(en.get("world_height", 51.0))
	if not POSE_BOUNDS.has(biome) or row < 0 or row >= 5:
		return Vector2(height * .7, height)
	return Vector2(POSE_BOUNDS[biome][row * 6 + column]) * (height / REFERENCE_HEIGHT)

static func neutral_size(en: Dictionary) -> Vector2:
	return _pose_size(en, 0)

static func actor_bounds(en: Dictionary, time: float = 0.0) -> Rect2:
	var size: Vector2 = _pose_size(en, int(actor_sample(en, time)["column"]))
	return Rect2(Vector2(en["pos"]) - Vector2(size.x * .5, size.y), size)

static func draw_actor(c: CanvasItem, en: Dictionary, time: float, base: Transform2D = Transform2D.IDENTITY) -> bool:
	if not en.has("v55_row"):
		return false
	var sample: Dictionary = actor_sample(en, time)
	var tint := Color("f8d8c4") if float(en.get("hurt", 0)) > 0.0 else Color.WHITE
	return _draw(c, en, int(sample["column"]), en["pos"], float(en.get("face", 1.0)), base, tint)

static func corpse_extent(en: Dictionary) -> Vector2:
	return _pose_size(en, 5)

static func draw_corpse(c: CanvasItem, body: Dictionary) -> bool:
	var actor: Dictionary = body.get("roster_actor", {})
	if not actor.has("v55_row"):
		return false
	var column: int = 4 if int(body["frame"]) < 2 else 5
	return _draw(c, actor, column, body["pos"], float(body["face"]), Transform2D.IDENTITY, Color(.85, .85, .85))

static func _draw(c: CanvasItem, en: Dictionary, column: int, at: Vector2, face: float, base: Transform2D, tint: Color) -> bool:
	var biome: String = en.get("roster_biome", "")
	var row: int = int(en.get("v55_row", -1))
	if row < 0 or row >= 5:
		return false
	if not sheets.has(biome):
		var path: String = ROOT + biome + ".webp"
		if not ResourceLoader.exists(path):
			return false
		sheets[biome] = load(path)
	var factor: float = float(en.get("world_height", 51.0)) / REFERENCE_HEIGHT
	var source := Rect2(Vector2(column, row) * CELL, CELL)
	c.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(face * factor, factor), 0.0, at))
	c.draw_texture_rect_region(sheets[biome], Rect2(-ANCHOR, CELL), source, tint)
	c.draw_set_transform_matrix(base)
	return true
