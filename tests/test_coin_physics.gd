extends SceneTree

const Coins = preload("res://scripts/coin_physics.gd")
var failures: Array[String] = []


func _initialize() -> void:
	var bounds: Rect2 = Rect2(0, 0, 500, 500)
	var floor_surfaces: Array[Rect2] = [Rect2(0, 300, 500, 20)]
	var coin: Dictionary = {"pos": Vector2(250, 120), "vel": Vector2.ZERO, "value": 137}
	Coins.initialize(coin)
	check(float(coin["radius"]) == 7.0 and float(coin["age"]) == 0.0, "Initialization supplies radius and age")
	var impacts: int = 0
	var lowest: float = coin["pos"].y
	for frame in 300:
		if Coins.step(coin, 1.0 / 60.0, floor_surfaces, bounds):
			impacts += 1
		lowest = maxf(lowest, coin["pos"].y)
	check(impacts > 0, "Falling coins report a visible bounce")
	check(lowest <= 293.1, "Radius prevents centre from entering the platform")
	check(absf(coin["pos"].y - 293.0) < 0.05 and coin["grounded"], "Coins settle at platform top minus radius")
	check(absf(coin["vel"].y) < 0.01, "Low-speed rebounds stop instead of jittering")
	check(not Coins.step(coin, 0.1, floor_surfaces, bounds), "Resting contact does not repeatedly report impact effects")
	check(coin["value"] == 137, "Physics never changes currency value")

	var right: Dictionary = {"pos": Vector2(470, 100), "vel": Vector2(900, 0), "value": 3}
	check(Coins.step(right, 0.06, [], bounds), "Right wall collision is visible")
	check(right["pos"].x <= 493.0 and right["vel"].x < 0.0, "Right wall respects radius and reflects horizontal speed")
	var left: Dictionary = {"pos": Vector2(30, 100), "vel": Vector2(-900, 0), "value": 2}
	check(Coins.step(left, 0.06, [], bounds), "Left wall collision is visible")
	check(left["pos"].x >= 7.0 and left["vel"].x > 0.0, "Left wall respects radius and reflects horizontal speed")

	var side_surfaces: Array[Rect2] = [Rect2(200, 100, 20, 100)]
	var side: Dictionary = {"pos": Vector2(150, 150), "vel": Vector2(1000, 0), "value": 11}
	check(Coins.step(side, 0.06, side_surfaces, bounds), "Platform sides collide")
	check(side["pos"].x < 193.1 and side["vel"].x < 0.0, "Side collision does not tunnel through solid platform")

	var ceiling_surfaces: Array[Rect2] = [Rect2(100, 150, 200, 10)]
	var underside: Dictionary = {"pos": Vector2(200, 215), "vel": Vector2(0, -1100), "value": 12}
	check(Coins.step(underside, 0.08, ceiling_surfaces, bounds), "Platform underside collides")
	check(underside["pos"].y >= 166.9 and underside["vel"].y > 0.0, "Underside hit reflects upward velocity downward")

	var thin_surfaces: Array[Rect2] = [Rect2(80, 300, 340, 2)]
	var fast: Dictionary = {"pos": Vector2(250, 60), "vel": Vector2(0, 9000), "value": 5}
	check(Coins.step(fast, 0.1, thin_surfaces, bounds), "Fast fall hits a two-pixel platform")
	check(fast["pos"].y <= 293.1 and fast["vel"].y < 0.0, "Swept collision catches a thin platform even across a long fall")

	var rolling: Dictionary = {"pos": Vector2(100, 293), "vel": Vector2(140, 0), "value": 17}
	Coins.initialize(rolling)
	var start_x: float = rolling["pos"].x
	Coins.step(rolling, 0.1, floor_surfaces, bounds)
	check(rolling["pos"].x > start_x and absf(float(rolling["rotation"])) > 0.1, "Rolling translates and rotates the coin")
	check(rolling["angular_speed"] > 0.0 and rolling["vel"].x < 140.0, "Rolling spin follows tangent direction while friction slows movement")
	for frame in 300:
		Coins.step(rolling, 1.0 / 60.0, floor_surfaces, bounds)
	check(rolling["vel"].length_squared() < 0.01 and absf(float(rolling["angular_speed"])) < 0.01, "Friction eventually stops translation and spin")
	check(rolling["value"] == 17, "Rolling preserves currency count")

	var ledge_surfaces: Array[Rect2] = [Rect2(70, 200, 130, 10)]
	var edge: Dictionary = {"pos": Vector2(190, 193), "vel": Vector2(160, 0), "value": 23}
	for frame in 25:
		Coins.step(edge, 1.0 / 60.0, ledge_surfaces, bounds)
	check(edge["pos"].x > 207.0 and edge["pos"].y > 205.0 and not edge["grounded"], "Coins leave a ledge and resume falling")
	check(edge["value"] == 23, "Leaving a ledge preserves currency count")

	var resting: Dictionary = {"pos": Vector2(250, 293), "vel": Vector2.ZERO, "value": 19}
	for frame in 120:
		Coins.step(resting, 1.0 / 120.0, floor_surfaces, bounds)
	check(resting["pos"].distance_to(Vector2(250, 293)) < 0.01 and resting["grounded"], "Resting support remains stable across small timesteps")
	var initialized: Dictionary = {"pos": Vector2(250, 200), "value": 9}
	Coins.initialize(initialized, Vector2(-80, -120))
	check(initialized["vel"] == Vector2(-80, -120), "Caller launch velocity is preserved")
	check(initialized["value"] == 9, "Initialization preserves currency count")

	if failures.is_empty():
		print("Coin physics passed: radius landing, bounce damping, walls, platform sides/undersides, swept thin-platform impact, rolling/friction, stable support, ledge fall, currency preservation")
	else:
		print("Coin physics failures: ", failures)
	quit(0 if failures.is_empty() else 1)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
