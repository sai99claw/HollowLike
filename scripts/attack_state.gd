class_name AttackState
extends RefCounted
## Shared attack clock for players, enemies, melee attacks and projectiles.
## Durations are measured in seconds. Only the active phase can deal damage.

signal phase_changed(new_phase: String)
signal active_started
signal finished

const DEFAULT_WINDUP := 0.12
const DEFAULT_ACTIVE := 0.10
const DEFAULT_RECOVERY := 0.18
const PHASES := ["windup", "active", "recovery"]

var phase: String = "idle"
var elapsed: float = 0.0
var attack: Dictionary = {}
var attack_id: int = 0
var _hit_targets: Dictionary = {}
var _timed_hits:Dictionary={}


func begin(definition: Dictionary) -> bool:
	if is_busy():
		return false
	attack = definition.duplicate(true)
	attack["windup"] = _read_duration(definition, "windup", DEFAULT_WINDUP)
	attack["active"] = _read_duration(definition, "active", DEFAULT_ACTIVE)
	attack["recovery"] = _read_duration(definition, "recovery", DEFAULT_RECOVERY)
	# Independent animation identifiers let each actor render its own three poses.
	attack["windup_animation"] = definition.get("windup_animation", "windup")
	attack["active_animation"] = definition.get("active_animation", "active")
	attack["recovery_animation"] = definition.get("recovery_animation", "recovery")
	attack_id += 1
	_hit_targets.clear();_timed_hits.clear()
	_change_phase("windup")
	_skip_zero_phases(attack_id)
	return true


func tick(delta: float) -> void:
	if not is_busy() or not is_finite(delta) or delta < 0.0:
		return
	var remaining := delta
	var expected_id := attack_id
	# A single attack has three phases. This bound also protects against signal
	# callbacks starting another attack during completion.
	for _transition in range(4):
		if not is_busy() or attack_id != expected_id:
			break
		var duration := float(attack[phase])
		var until_boundary := maxf(0.0, duration - elapsed)
		if remaining < until_boundary:
			elapsed += remaining
			break
		remaining = maxf(0.0, remaining - until_boundary)
		_advance_phase()
		if remaining <= 0.0:
			_skip_zero_phases(expected_id)
			break


func is_busy() -> bool:
	return phase != "idle"


func is_active() -> bool:
	return phase == "active"


func progress() -> float:
	if not is_busy():
		return 0.0
	var duration := float(attack.get(phase, 0.0))
	if duration <= 0.0:
		return 1.0
	return clampf(elapsed / duration, 0.0, 1.0)


func animation_name() -> String:
	if not is_busy():
		return "idle"
	return str(attack.get(phase + "_animation", phase))


func cancel() -> void:
	if is_busy():
		_change_phase("idle")
	else:
		elapsed = 0.0
	_hit_targets.clear();_timed_hits.clear()


func mark_hit(target_id: int) -> bool:
	if not is_active() or _hit_targets.has(target_id):
		return false
	_hit_targets[target_id] = true
	return true


func _read_duration(definition: Dictionary, key: String, fallback: float) -> float:
	var raw = definition.get(key, definition.get(key + "_time", fallback))
	if not (raw is int or raw is float):
		return fallback
	var value := float(raw)
	if not is_finite(value):
		return fallback
	return maxf(0.0, value)


func _change_phase(next_phase: String) -> void:
	phase = next_phase
	elapsed = 0.0
	phase_changed.emit(phase)
	if phase == "active":
		active_started.emit()


func _advance_phase() -> void:
	match phase:
		"windup":
			_change_phase("active")
		"active":
			_change_phase("recovery")
		"recovery":
			_change_phase("idle")
			finished.emit()


func _skip_zero_phases(expected_id: int) -> void:
	for _transition in range(3):
		if not is_busy() or attack_id != expected_id:
			break
		if float(attack[phase]) > 0.0:
			break
		_advance_phase()

func mark_timed_hit(target_id:int,interval:float=.5,maximum:int=3) -> bool:
	if not is_active() or elapsed>=float(attack["active"])-.000001:return false
	var state:Dictionary=_timed_hits.get(target_id,{"count":0,"next":0.0})
	if int(state["count"])>=maximum or elapsed+.000001<float(state["next"]):return false
	state["count"]+=1;state["next"]=elapsed+interval;_timed_hits[target_id]=state;return true
