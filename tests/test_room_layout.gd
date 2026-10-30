extends SceneTree

const Layout = preload("res://scripts/room_layout.gd")

func _init() -> void:
	var failures: Array[String] = []
	var signatures: Dictionary = {}
	var archetypes: Dictionary = {}
	var min_count := 1000
	var max_count := 0
	for seed_value in range(600):
		var room := {"id": seed_value % 43, "coord": Vector2i(seed_value % 5 - 2, seed_value % 13 - 6), "type": ["combat", "start", "reward", "boss"][seed_value % 4], "neighbors": {"up": 0, "down": 1, "left": 2, "right": 3}}
		var layout: Dictionary = Layout.generate(room, seed_value)
		var errors: Array[String] = Layout.validate(layout)
		for error in errors:
			failures.append("seed %d: %s" % [seed_value, error])
		if seed_value < 10 and layout != Layout.generate(room, seed_value):
			failures.append("Layout is not reproducible")
		if room["type"] != "start":signatures[str(layout["platforms"])] = true
		else:
			var tiers:Dictionary={}
			for surface in layout["platforms"]:tiers[surface.position.y]=true
			if not tiers.has(850.0) or not tiers.has(1050.0) or float(layout.get("ceiling_y",999))!=0:failures.append("Prep room needs full-height ceiling, first floor and second-floor deck")
		archetypes[layout["archetype"]] = true
		min_count = mini(min_count, layout["platforms"].size())
		max_count = maxi(max_count, layout["platforms"].size())
		if layout["enemy_spawns"].size() < (26 if room["type"] == "combat" else 7):
			failures.append("Not enough distributed enemy spawn slots")
	if signatures.size() < 440:
		failures.append("Room geometries lack diversity")
	if archetypes.size() != 6:
		failures.append("Missing archetype coverage")
	if max_count <= min_count:
		failures.append("Platform count never varies")
	if not failures.is_empty():
		for failure in failures.slice(0, 30):
			push_error(failure)
		print("Total failures: ", failures.size())
		quit(1)
		return
	print("Room layout tests passed: 600 seeds, four combat archetypes + three-tier nest + Boss arena, %d–%d platforms, %d unique geometries; all doors, entries and enemy spawns supported and ordinary-jump reachable" % [min_count, max_count, signatures.size()])
	quit(0)
