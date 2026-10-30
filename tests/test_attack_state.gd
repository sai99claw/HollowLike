extends SceneTree

const AttackClock = preload("res://scripts/attack_state.gd")
var failures: Array[String] = []


func _init() -> void:
	_test_regular_phases()
	_test_large_delta()
	_test_zero_and_invalid_durations()
	_test_dedup_and_cancel()
	_test_payload_and_aliases()
	if failures.is_empty():
		print("AttackState: all tests passed")
		quit(0)
	else:
		for message in failures:
			push_error(message)
		quit(1)


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _test_regular_phases() -> void:
	var clock = AttackClock.new()
	var transitions: Array[String] = []
	clock.phase_changed.connect(func(value: String): transitions.append(value))
	check(clock.begin({"windup": 0.2, "active": 0.3, "recovery": 0.4}), "begin accepts idle")
	check(clock.phase == "windup", "starts with windup")
	check(not clock.is_active(), "windup cannot damage")
	check(not clock.begin({}), "busy attacks cannot restart")
	clock.tick(0.1)
	check(is_equal_approx(clock.progress(), 0.5), "phase progress is normalized")
	clock.tick(0.11)
	check(clock.is_active(), "windup transitions to active")
	check(is_equal_approx(clock.elapsed, 0.01), "transition preserves remaining delta")
	clock.tick(0.3)
	check(clock.phase == "recovery", "active transitions to recovery")
	check(not clock.is_active(), "recovery cannot damage")
	clock.tick(0.4)
	check(not clock.is_busy(), "recovery ends at idle")
	check(transitions == ["windup", "active", "recovery", "idle"], "three attack phases fire in order")
	check(clock.progress() == 0.0, "idle progress is zero")


func _test_large_delta() -> void:
	var clock = AttackClock.new()
	var activations: Array[int] = []
	var completions: Array[int] = []
	clock.active_started.connect(func(): activations.append(1))
	clock.finished.connect(func(): completions.append(1))
	clock.begin({"windup": 0.1, "active": 0.1, "recovery": 0.1})
	clock.tick(5.0)
	check(not clock.is_busy(), "large delta completes attack")
	check(activations.size() == 1, "large delta still emits active start once")
	check(completions.size() == 1, "completion emitted once")
	clock.tick(2.0)
	check(completions.size() == 1, "idle tick does not complete again")


func _test_zero_and_invalid_durations() -> void:
	var clock = AttackClock.new()
	clock.begin({"windup": 0.0, "active": 0.0, "recovery": 0.0})
	check(not clock.is_busy(), "all zero phases complete without a loop")
	clock.begin({"windup": -2.0, "active": 0.2, "recovery": 0.0})
	check(clock.is_active(), "negative duration clamps to zero")
	clock.tick(-3.0)
	check(clock.elapsed == 0.0, "negative delta ignored")
	clock.tick(0.21)
	check(not clock.is_busy(), "zero recovery skips to idle")
	clock.begin({"windup": "invalid", "active": INF, "recovery": NAN})
	check(is_equal_approx(clock.attack.windup, 0.12), "invalid duration uses default")
	check(is_equal_approx(clock.attack.active, 0.10), "infinite duration uses default")
	check(is_equal_approx(clock.attack.recovery, 0.18), "NaN duration uses default")


func _test_dedup_and_cancel() -> void:
	var clock = AttackClock.new()
	clock.begin({"windup": 0.0, "active": 1.0, "recovery": 0.1})
	check(clock.mark_hit(42), "first target hit accepted")
	check(not clock.mark_hit(42), "same target hit rejected within same attack")
	check(clock.mark_hit(43), "different target hit accepted")
	var first_id: int = clock.attack_id
	clock.cancel()
	check(not clock.is_busy(), "cancel returns to idle")
	check(not clock.mark_hit(44), "idle cannot mark hits")
	check(clock.begin({"windup": 0.0, "active": 1.0}), "begin accepted after cancel")
	check(clock.attack_id == first_id + 1, "attack id increments")
	check(clock.mark_hit(42), "new attack clears per-target history")
	clock.tick(1.01)
	check(not clock.mark_hit(45), "recovery cannot mark hits")


func _test_payload_and_aliases() -> void:
	var clock = AttackClock.new()
	var original := {"kind": "projectile", "windup_time": 0.25, "active_animation": "wing_strike", "custom": {"value": 4}}
	clock.begin(original)
	check(clock.attack.kind == "projectile", "original attack payload preserved")
	check(is_equal_approx(clock.attack.windup, 0.25), "duration time alias accepted")
	check(clock.animation_name() == "windup", "windup animation independent")
	original.custom.value = 99
	check(clock.attack.custom.value == 4, "attack payload deep copied")
	clock.tick(0.25)
	check(clock.animation_name() == "wing_strike", "custom active animation used")
