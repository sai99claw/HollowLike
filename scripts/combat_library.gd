class_name CombatLibrary
extends RefCounted
## Shared, independently tunable attack and movement vocabulary.
## AttackState owns the three phases; this file only builds fresh definitions.

const Design=preload("res://scripts/monster_design.gd")

const ATTACK_KINDS: Array[String] = ["slash", "flying_slash", "linear", "arc", "trap", "explosion"]
const MOVEMENTS: Array[String] = ["walk", "jump", "hover", "drift", "dash"]
const LOGICS: Array[String] = ["approach", "roam"]
const BOSS_BIOMES: Array[String] = ["sky", "canopy", "branches", "trunk", "grass", "underground"]
const BOSS_AREA_MULT: float = 8.0
const BOSS_SCALE: float = 2.8284271247461903


static func attack(kind: String, params: Dictionary = {}) -> Dictionary:
	var selected: String = kind if ATTACK_KINDS.has(kind) else "slash"
	var defaults: Dictionary = {
		"slash": {"size": 32.0, "range": 100.0, "speed": 0.0, "windup": 0.5, "active": 0.18, "recovery": 0.6},
		"flying_slash": {"size": 25.0, "range": 800.0, "speed": 300.0, "windup": 0.7, "active": 0.16, "recovery": 0.75},
		"linear": {"size": 9.0, "range": 1000.0, "speed": 400.0, "windup": 0.65, "active": 0.12, "recovery": 0.65},
		"arc": {"size": 15.0, "range": 1000.0, "speed": 340.0, "windup": 0.75, "active": 0.14, "recovery": 0.75},
		"explosion": {"size": 90.0, "range": 90.0, "speed": 0.0, "windup": 0.85, "active": 0.12, "recovery": 0.8},
		"trap": {"size": 55.0, "range": 450.0, "speed": 0.0, "windup": 0.85, "active": 0.12, "recovery": 0.8}
	}
	var values: Dictionary = defaults[selected].duplicate(true)
	values.merge(params, true)
	var curve: Dictionary = params.get("curve", {}) if params.get("curve", {}) is Dictionary else {}
	if not params.has("gravity") and curve.has("gravity"):
		values["gravity"] = curve["gravity"]
	if not params.has("launch_y") and curve.has("launch_y"):
		values["launch_y"] = curve["launch_y"]
	var size_value: float = _number(values, "size", 12.0, 2.0, 240.0)
	var range_value: float = _number(values, "range", 800.0, 8.0, 4000.0)
	var speed_value: float = _number(values, "speed", 300.0, 0.0, 2500.0)
	var gravity_value: float = _number(values, "gravity", 600.0 if selected == "arc" else 0.0, -2500.0, 2500.0)
	var launch_value: float = _number(values, "launch_y", -260.0 if selected == "arc" else 0.0, -1800.0, 1800.0)
	var count_value: int = int(_number(values, "count", _number(values, "shots", 1.0, 1.0, 20.0), 1.0, 20.0))
	var default_lifetime: float = 4.0 if selected == "trap" else range_value / maxf(1.0, speed_value) + 0.2
	var result: Dictionary = values.duplicate(true)
	result.merge({
		"library_kind": selected,
		"kind": "primary" if selected == "slash" else "secondary",
		"weapon_kind": {"slash": "sword", "flying_slash": "flying_slash", "linear": "shot", "arc": "throw", "trap": "trap", "explosion":"explosion"}[selected],
		"primary": selected == "slash",
		"size": size_value, "radius": size_value, "width": size_value * 2.0,
		"range": range_value, "distance": range_value, "speed": speed_value,
		"piercing": bool(values.get("piercing", false)), "count": count_value, "shots": count_value,
		"damage": _number(values, "damage", 1.0, 0.0, 1000.0),
		"gravity": gravity_value, "launch_y": launch_value,
		"curve": {"gravity": gravity_value, "launch_y": launch_value},
		"max_hits": int(_number(values, "max_hits", 1.0, 1.0, 20.0)),
		"hit_interval": _number(values, "hit_interval", 0.7, 0.15, 10.0),
		"lifetime": _number(values, "lifetime", default_lifetime, 0.1, 20.0),
		"arming_time": _number(values, "arming_time", 0.55 if selected == "trap" else 0.0, 0.0, 5.0),
		"windup": _number(values, "windup", 0.65, 0.05, 10.0),
		"active": _number(values, "active", 0.15, 0.03, 10.0),
		"recovery": _number(values, "recovery", 0.7, 0.05, 10.0),
		"color": values.get("color", Color("e8c88c")),
		"style_id": str(values.get("style_id", selected)),
		"name": str(values.get("name", selected)),
		"origin_y": _number(values, "origin_y", -24.0, -500.0, 100.0),
		"attack_cooldown": _number(values, "attack_cooldown", 1.1, 0.1, 20.0),
		"spread": _number(values, "spread", 0.2, 0.0, PI),
		"energy_gain": 0.0
	}, true)
	return result


static func boss(biome_id: String) -> Dictionary:
	var selected: String = biome_id if BOSS_BIOMES.has(biome_id) else "branches"
	var result: Dictionary = {
		"id": "", "name": "", "biome": selected, "model": 4,
		"is_boss": true, "scale": BOSS_SCALE, "area_mult": BOSS_AREA_MULT,
		"hp": 80.0, "speed": 95.0, "range": 190.0, "damage": 2.0,
		"windup": 0.75, "active": 0.2, "recovery": 0.8,
		"secondary": 2, "secondary_cooldown": 2.7, "contact_damage": 1.0,
		"move": "walk", "movement_logic": "approach", "movement_period": 2.8,
		"jump_speed": 540.0, "dash_speed": 390.0, "dash_windup": 0.45, "dash_duration": 0.4,
		"hover_height": 210.0, "roam_radius": 230.0,
		"visual_kind": "boss", "visual_scale": BOSS_SCALE,
		"color": Color("d5b788")
	}
	var attacks: Array[Dictionary] = []
	var movements: Array[String] = []
	match selected:
		"sky":
			result.merge({"id":"sky_gale_falcon","name":"逐霆隼王","hp":72.0,"speed":112.0,"move":"fly","color":Color("b9e3f4"),"movement_logic":"roam"},true)
			movements.assign(["hover","drift"])
			attacks.append(attack("flying_slash",{"name":"裂風爪襲","size":30,"range":850,"speed":330,"count":2,"damage":1,"piercing":true,"spread":.28,"windup":.85,"active":.25,"recovery":.90,"origin_y":-60,"color":Color("b9e3f4"),"style_id":"cloud_crescent","animation_role":"melee"}))
			attacks.append(attack("linear",{"name":"雷羽梭","size":10,"range":1050,"speed":440,"count":3,"damage":1,"spread":.18,"windup":1.0,"active":.15,"recovery":.85,"origin_y":-65,"color":Color("d8edff"),"style_id":"storm_feather"}))
		"canopy":
			result.merge({"id":"canopy_mantis_queen","name":"綾冠螳后","hp":80.0,"speed":105.0,"color":Color("b7d992")},true)
			movements.assign(["jump","dash"])
			attacks.append(attack("slash",{"name":"新月雙鐮","size":42,"range":195,"count":2,"damage":1,"windup":.75,"active":.24,"recovery":.8,"origin_y":-58,"color":Color("d3edab"),"style_id":"mantis_shear"}))
			attacks.append(attack("flying_slash",{"name":"迴葉月刃","size":24,"range":850,"speed":320,"count":1,"damage":1,"piercing":true,"return_after":1.0,"windup":.85,"active":.15,"recovery":.75,"origin_y":-70,"color":Color("d4d58b"),"style_id":"leaf_moon"}))
		"branches":
			result.merge({"id":"bough_nest_weaver","name":"織巢蛛母","hp":76.0,"speed":85.0,"move":"walk","color":Color("c6b4e1"),"movement_logic":"roam"},true)
			movements.assign(["walk","jump"])
			attacks.append(attack("slash",{"name":"斷枝刺繡","size":35,"range":185,"count":2,"damage":1,"windup":.9,"active":.28,"recovery":1.0,"origin_y":-52,"color":Color("dccbf4"),"style_id":"silk_stitch"}))
			attacks.append(attack("arc",{"name":"結網繭彈","size":18,"range":740,"speed":290,"count":1,"damage":1,"windup":1.1,"active":.15,"recovery":.9,"origin_y":-52,"color":Color("dccbf4"),"style_id":"silk_cocoon"}))
			attacks.append(attack("trap",{"name":"結網封路","size":62,"range":510,"count":2,"damage":1,"max_hits":2,"hit_interval":.85,"lifetime":4.3,"arming_time":.7,"windup":1,"active":.12,"recovery":.9,"origin_y":0,"color":Color("d7c2ed"),"style_id":"silk_web"}))
		"trunk":
			result.merge({"id":"trunk_amber_stag","name":"琥珀鍬皇","hp":90.0,"speed":88.0,"color":Color("d6a578")},true)
			movements.assign(["walk","dash"])
			attacks.append(attack("slash",{"name":"鎖木巨鉗","size":45,"range":205,"count":1,"damage":2,"windup":1.05,"active":.30,"recovery":1.1,"origin_y":-55,"color":Color("f1c28c"),"style_id":"amber_pincers"}))
			attacks.append(attack("arc",{"name":"琥珀榴彈","size":20,"range":1000,"speed":330,"count":1,"damage":1,"gravity":600,"launch_y":-310,"windup":1.15,"active":.15,"recovery":1,"origin_y":-55,"color":Color("ddb081"),"style_id":"amber_resin"}))
		"grass":
			result.merge({"id":"grass_dew_toad","name":"露冠蟾王","hp":84.0,"speed":70.0,"color":Color("b4cc83"),"movement_logic":"roam","jump_speed":590.0},true)
			movements.assign(["jump","walk"])
			attacks.append(attack("slash",{"name":"蘆槍橫掃","size":38,"range":185,"damage":1,"windup":.95,"active":.28,"recovery":.95,"origin_y":-45,"color":Color("b7dfd4"),"style_id":"reed_slash"}))
			attacks.append(attack("linear",{"name":"露泡浮雷","size":23,"range":700,"speed":125,"count":2,"damage":1,"wave_amplitude":35,"wave_frequency":4,"windup":1,"active":.15,"recovery":.85,"origin_y":-45,"color":Color("c4ece5"),"style_id":"dew_bubble"}))
			attacks.append(attack("trap",{"name":"露環苗床","size":48,"range":500,"count":3,"damage":1,"max_hits":3,"hit_interval":.9,"lifetime":4.5,"arming_time":.8,"windup":1,"active":.12,"recovery":.95,"origin_y":0,"color":Color("b9d5b9"),"style_id":"dew_pool"}))
		"underground":
			result.merge({"id":"underroot_blind_mole","name":"盲根掘王","hp":96.0,"speed":82.0,"color":Color("9fbed3"),"dash_speed":350.0},true)
			movements.assign(["walk","dash"])
			attacks.append(attack("slash",{"name":"裂根掘爪","size":40,"range":190,"damage":1,"windup":.9,"active":.26,"recovery":1,"origin_y":-48,"color":Color("a9d1dd"),"style_id":"root_claw"}))
			attacks.append(attack("flying_slash",{"name":"根鑽螺彈","size":24,"range":900,"speed":270,"count":2,"damage":1,"piercing":true,"spread":0,"windup":1.05,"active":.15,"recovery":.9,"origin_y":-24,"color":Color("a9d1dd"),"style_id":"root_wave"}))
			attacks.append(attack("trap",{"name":"根刺破土","size":42,"range":560,"count":3,"damage":1,"max_hits":2,"hit_interval":.8,"lifetime":3.8,"arming_time":.75,"windup":1.1,"active":.12,"recovery":1,"origin_y":0,"color":Color("b2d5d1"),"style_id":"root_spike"}))
	for definition:Dictionary in attacks:definition["boss_biome"]=selected
	var widths:Dictionary={"sky":96.0,"canopy":84.0,"branches":144.0,"trunk":150.0,"grass":144.0,"underground":160.0}
	result["body_size"]=Vector2(float(widths[selected]),34.0*42.0*8.0/float(widths[selected]))
	result["movements"] = movements
	result["attacks"] = attacks
	Design.decorate_boss(result)
	return result


static func attach_regular(en: Dictionary) -> void:
	var model: int = int(en.get("model", 0))
	if model >= 4:
		return
	var attacks: Array[Dictionary] = []
	var movements: Array[String] = ["walk"]
	var color: Color = en.get("color", Color("b9c79d"))
	var melee: Dictionary = attack("slash", {
		"name": str(en.get("name", "敵人")) + "近斬",
		"damage": float(en.get("damage", 1.0)), "range": float(en.get("range", 60.0)),
		"size": 32.5 * float(en.get("scale", 1.0)),
		"windup": float(en.get("windup", 0.45)), "active": float(en.get("active", 0.16)),
		"recovery": float(en.get("recovery", 0.55)), "color": color,
		"attack_cooldown": 1.5
	})
	attacks.append(melee)
	en["movement_logic"] = "approach"
	match model:
		1:
			en["movement_logic"] = "roam"
			attacks.append(attack("arc", {"name": "橡實投擲", "size": 9.0, "range": 720.0, "speed": 206.4, "damage": 1.0, "gravity": 600.0, "launch_y": -260.0, "windup": 0.55, "active": 0.12, "recovery": 0.65, "attack_cooldown": 2.4, "color": color, "sprite": "acorn", "style_id": "acorn"}))
		2:
			movements.assign(["hover", "drift"])
			attacks.append(attack("linear", {"name": "翠羽直射", "size": 5.0, "range": 760.0, "speed": 307.2, "damage": 1.0, "windup": 0.55, "active": 0.12, "recovery": 0.65, "attack_cooldown": 2.8, "color": color, "sprite": "needle", "style_id": "moth_needle"}))
		3:
			movements.assign(["walk", "dash"])
			attacks.append(attack("linear", {"name": "橡實散射", "size": 6.0, "range": 760.0, "speed": 259.2, "count": 3, "damage": 1.0, "spread": 0.23, "windup": 0.55, "active": 0.12, "recovery": 0.65, "attack_cooldown": 3.0, "color": color, "sprite": "acorn", "style_id": "guardian_acorn"}))
	en["movements"] = movements
	en["attacks"] = attacks
	en["movement_period"] = float(en.get("movement_period", 3.0))
	en["jump_speed"] = float(en.get("jump_speed", 420.0))
	en["dash_speed"] = float(en.get("dash_speed", float(en.get("speed", 60.0)) * 3.0))
	en["dash_duration"] = float(en.get("dash_duration", 0.32))
	en["dash_windup"] = float(en.get("dash_windup", 0.4))
	en["hover_height"] = float(en.get("hover_height", 70.0))
	en["roam_radius"] = float(en.get("roam_radius", 110.0))


static func _number(values: Dictionary, key: String, fallback: float, minimum: float, maximum: float) -> float:
	var raw: Variant = values.get(key, fallback)
	if not (raw is int or raw is float):
		return clampf(fallback, minimum, maximum)
	var value: float = float(raw)
	if not is_finite(value):
		return clampf(fallback, minimum, maximum)
	return clampf(value, minimum, maximum)
