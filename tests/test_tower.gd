extends SceneTree

const Generator = preload("res://scripts/tower.gd")


func _init() -> void:
	var failures: Array[String] = []
	var reward_maps := 0
	var map_count := 0
	var total_height := 0.0
	var total_width := 0.0
	var signatures: Dictionary = {}
	for seed_value in range(500):
		var tower: Dictionary = Generator.generate(seed_value)
		var errors: Array[String] = Generator.validate(tower)
		for error in errors:
			failures.append("seed %d: %s" % [seed_value, error])
		if seed_value < 10 and tower != Generator.generate(seed_value):
			failures.append("seed %d is not deterministic" % seed_value)
		var min_coord := Vector2i.ZERO
		var max_coord := Vector2i.ZERO
		var signature := ""
		for room in tower["rooms"]:
			var coord: Vector2i = room["coord"]
			min_coord.x = mini(min_coord.x, coord.x)
			min_coord.y = mini(min_coord.y, coord.y)
			max_coord.x = maxi(max_coord.x, coord.x)
			max_coord.y = maxi(max_coord.y, coord.y)
			signature += str(coord) + ":" + room["type"] + ";"
			if not room.has("cleared") or not room.has("drops") or not room.has("enemies"):
				failures.append("Room state missing on seed %d" % seed_value)
		signatures[signature] = true
		total_width += max_coord.x - min_coord.x + 1
		total_height += max_coord.y - min_coord.y + 1
		for map_data in tower["maps"]:
			map_count += 1
			if map_data["reward_id"] != -1:
				reward_maps += 1
		# Mutating one room's retained state cannot mutate another room or a fresh run.
		if seed_value == 0:
			tower["rooms"][0]["drops"].append({"kind": "test"})
			if not tower["rooms"][1]["drops"].is_empty():
				failures.append("Room drop arrays alias one another")
			if not Generator.generate(0)["rooms"][0]["drops"].is_empty():
				failures.append("Generated runs share mutable state")
	var reward_rate := float(reward_maps) / float(map_count)
	if reward_rate < 0.66 or reward_rate > 0.74:
		failures.append("Per-map reward rate outside expected sample tolerance: %f" % reward_rate)
	if total_height <= total_width:
		failures.append("Tower ensemble must have more vertical than horizontal span")
	if signatures.size() != 500:
		failures.append("Different seeds produced duplicate complete layouts")
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("Tower tests passed: 500 seeds, %d maps, reward rate %.3f, average dimensions %.2f x %.2f" % [map_count, reward_rate, total_width / 500.0, total_height / 500.0])
	quit(0)
