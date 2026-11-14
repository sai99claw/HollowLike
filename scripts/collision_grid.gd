extends RefCounted
## Ordered broad phase. Closed bounds preserve exact edge contacts for the narrow phase.
const CELL := 128.0
var bounds: Dictionary = {}
var buckets: Dictionary = {}

func rebuild(rectangles: Array) -> void:
	clear()
	for i in rectangles.size():
		put(i, rectangles[i])

func clear() -> void:
	bounds.clear()
	buckets.clear()

func put(id: int, rect: Rect2) -> void:
	if bounds.has(id):
		var old: Rect2 = bounds[id]
		if old == rect:
			return
		if _cells(old) == _cells(rect):
			bounds[id] = rect
			return
		erase(id)
	bounds[id] = rect
	var cells := _cells(rect)
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var key := Vector2i(x, y)
			if not buckets.has(key):
				buckets[key] = []
			buckets[key].append(id)

func erase(id: int) -> void:
	if not bounds.has(id):
		return
	var cells := _cells(bounds[id])
	bounds.erase(id)
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var key := Vector2i(x, y)
			var bucket: Array = buckets[key]
			bucket.erase(id)
			if bucket.is_empty():
				buckets.erase(key)

func ids(area: Rect2) -> Array[int]:
	var result: Array[int] = []
	if bounds.is_empty():
		return result
	var cells := _cells(area)
	# Very long queries should not walk more empty cells than there are entries.
	if cells.size.x * cells.size.y > bounds.size() * 2:
		for id: int in bounds:
			if area.intersects(bounds[id], true):
				result.append(id)
	else:
		var seen: Dictionary = {}
		for y in range(cells.position.y, cells.end.y):
			for x in range(cells.position.x, cells.end.x):
				var bucket: Variant = buckets.get(Vector2i(x, y))
				if bucket == null:
					continue
				for id: int in bucket:
					if not seen.has(id):
						seen[id] = true
						if area.intersects(bounds[id], true):
							result.append(id)
	result.sort()
	return result

func query(area: Rect2) -> Array:
	var result: Array = []
	for id in ids(area):
		result.append(bounds[id])
	return result

static func _cells(rect: Rect2) -> Rect2i:
	var first := Vector2i((rect.position / CELL).floor())
	var last := Vector2i((rect.end / CELL).floor())
	return Rect2i(first, last - first + Vector2i.ONE)
