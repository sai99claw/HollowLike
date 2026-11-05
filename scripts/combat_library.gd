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
			result.merge({"id":"sky_gale_falcon","name":"逐霆隼王","hp":72.0,"speed":115.0,"move":"fly","color":Color("b9e3f4"),"movement_logic":"roam"},true)
			movements.assign(["drift","hover","dash"])
			attacks.append(_boss_attack(selected,0,"slash","掠空雙爪","cloud_crescent",{"size":49,"range":170,"count":2,"damage":1,"windup":.65,"active":.3,"origin_y":-40,"animation_role":"melee"}))
			attacks.append(_boss_attack(selected,1,"linear","暴風翎槍","storm_feather",{"size":24,"range":1100,"speed":620,"damage":2,"windup":1.15,"origin_y":-65,"boss_tell":"ray"}))
			attacks.append(_boss_attack(selected,2,"flying_slash","散翼風刃","cloud_crescent",{"size":26,"range":720,"speed":255,"count":3,"spread":.24,"damage":1,"windup":.95,"origin_y":-65,"boss_tell":"ray"}))
		"canopy":
			result.merge({"id":"canopy_mantis_queen","name":"綾冠螳后","hp":80.0,"speed":108.0,"color":Color("b7d992")},true)
			movements.assign(["jump","walk","dash"])
			attacks.append(_boss_attack(selected,0,"slash","剪冠雙鐮","mantis_shear",{"size":48,"range":196,"count":2,"damage":1,"windup":.73,"active":.3,"origin_y":-58}))
			attacks.append(_boss_attack(selected,1,"flying_slash","折返葉刃","leaf_moon",{"size":27,"range":850,"speed":335,"count":2,"spread":.20,"damage":1,"piercing":true,"return_after":.8,"windup":.9,"origin_y":-68,"boss_tell":"ray"}))
			attacks.append(_boss_attack(selected,2,"slash","伏鐮穿冠","mantis_shear",{"size":38,"range":345,"ram":true,"ram_speed":560,"damage":2,"windup":1.08,"active":.65,"recovery":.92,"origin_y":-58,"boss_tell":"ram"}))
		"branches":
			result.merge({"id":"bough_nest_weaver","name":"織巢蛛母","hp":76.0,"speed":91.0,"color":Color("c6b4e1"),"movement_logic":"roam"},true)
			movements.assign(["walk","jump"])
			attacks.append(_boss_attack(selected,0,"slash","撐足刺擊","silk_stitch",{"size":35,"range":176,"count":2,"damage":1,"windup":.72,"active":.26,"origin_y":-51}))
			attacks.append(_boss_attack(selected,1,"linear","穿枝束絲","silk_cocoon",{"size":18,"range":830,"speed":510,"count":2,"spread":0.0,"damage":2,"windup":1.08,"origin_y":-52,"boss_tell":"ray"}))
			attacks.append(_boss_attack(selected,2,"trap","三節封網","silk_web",{"size":53,"range":510,"count":3,"damage":1,"max_hits":2,"hit_interval":.85,"lifetime":4.3,"arming_time":.86,"windup":1.05,"origin_y":0}))
		"trunk":
			result.merge({"id":"trunk_amber_stag","name":"琥珀鍬皇","hp":90.0,"speed":81.0,"color":Color("d6a578")},true)
			movements.assign(["walk","dash","jump"])
			attacks.append(_boss_attack(selected,0,"slash","鍬角夾擊","amber_pincers",{"size":46,"range":182,"damage":2,"windup":.95,"active":.24,"origin_y":-49,"boss_tell":"cleave"}))
			attacks.append(_boss_attack(selected,1,"arc","碎琥珀榴彈","amber_resin",{"size":25,"range":760,"speed":355,"damage":2,"gravity":630,"launch_y":-300,"explode_on_hit":true,"explosion_radius":105,"windup":1.25,"origin_y":-55,"boss_tell":"arc"}))
			attacks.append(_boss_attack(selected,2,"slash","低角破木","amber_pincers",{"size":43,"range":340,"ram":true,"ram_speed":485,"damage":2,"windup":1.12,"active":.73,"recovery":.95,"origin_y":-54,"boss_tell":"ram"}))
		"grass":
			result.merge({"id":"grass_dew_toad","name":"露冠蟾王","hp":84.0,"speed":68.0,"color":Color("b4cc83"),"movement_logic":"roam","jump_speed":600.0},true)
			movements.assign(["jump","walk"])
			attacks.append(_boss_attack(selected,0,"slash","長舌點刺","reed_slash",{"size":26,"range":206,"damage":1,"windup":.76,"active":.17,"origin_y":-48,"shape":"thrust","boss_tell":"cleave"}))
			attacks.append(_boss_attack(selected,1,"linear","浮沫氣泡","dew_bubble",{"size":21,"range":655,"speed":140,"count":3,"spread":.14,"damage":1,"wave_amplitude":26,"wave_frequency":4,"windup":.92,"origin_y":-44}))
			attacks.append(_boss_attack(selected,2,"explosion","鼓腹震地","dew_pool",{"size":162,"range":162,"damage":2,"windup":1.18,"recovery":1.15,"boss_tell":"burst","animation_role":"melee"}))
		"underground":
			result.merge({"id":"underroot_blind_mole","name":"盲根掘王","hp":96.0,"speed":85.0,"color":Color("9fbed3")},true)
			movements.assign(["walk","dash"])
			attacks.append(_boss_attack(selected,0,"slash","翻岩掘爪","root_claw",{"size":48,"range":182,"damage":1,"windup":.78,"active":.26,"origin_y":-46}))
			attacks.append(_boss_attack(selected,1,"flying_slash","雙向裂地","root_wave",{"size":26,"range":830,"speed":370,"count":2,"damage":2,"piercing":true,"spread":0.0,"windup":1.08,"origin_y":-26,"boss_tell":"ray"}))
			attacks.append(_boss_attack(selected,2,"trap","鑽土根陣","root_spike",{"size":42,"range":540,"count":3,"damage":1,"max_hits":2,"hit_interval":.8,"lifetime":3.8,"arming_time":.85,"windup":1.07,"origin_y":0}))
	var widths:Dictionary={"sky":96.0,"canopy":84.0,"branches":144.0,"trunk":150.0,"grass":144.0,"underground":160.0}
	result["body_size"]=Vector2(float(widths[selected]),34.0*42.0*8.0/float(widths[selected]))
	result["spawn_surface"]="flight" if selected=="sky" else "ground"
	result["movements"] = movements
	result["attacks"] = attacks
	Design.decorate_boss(result)
	for definition:Dictionary in attacks:definition["color"]=result["color"]
	result["movements"]=movements.filter(func(movement:String)->bool:return movement!="dash" or selected not in ["branches","grass"])
	var pacing:Dictionary={
		"sky":{"hover_height":175.0,"dash_speed":540.0,"dash_windup":.94,"dash_duration":.55,"dash_cooldown":5.2},
		"canopy":{"jump_speed":595.0,"dash_speed":490.0,"dash_windup":.68,"dash_cooldown":4.3},
		"branches":{"jump_speed":410.0,"roam_radius":290.0,"movement_period":3.25},
		"trunk":{"jump_speed":385.0,"dash_speed":420.0,"dash_windup":.96,"dash_duration":.62,"dash_cooldown":5.5},
		"grass":{"jump_speed":600.0,"roam_radius":180.0,"movement_period":3.8},
		"underground":{"dash_speed":470.0,"dash_windup":.88,"dash_duration":.62,"dash_cooldown":5.0}}
	result.merge(pacing[selected],true)
	return result


static func _boss_attack(biome:String,slot:int,kind:String,title:String,style:String,settings:Dictionary) -> Dictionary:
	var params:Dictionary={"name":title,"style_id":style,"boss_biome":biome,"boss_animation_slot":slot,"boss_sound":"%s_%d"%[biome,slot],"attack_cooldown":1.2,"recovery":.88}
	params.merge(settings,true)
	return attack(kind,params)


static func boss_phase_two(en:Dictionary) -> Dictionary:
	var biome:String=str(en["biome"])
	var definition:Dictionary
	match biome:
		"sky":definition=_boss_attack(biome,3,"linear","折翼雷列","storm_feather",{"size":17,"range":930,"speed":495,"count":5,"spread":.14,"damage":1,"windup":1.18,"origin_y":-68,"boss_tell":"ray"})
		"canopy":definition=_boss_attack(biome,3,"flying_slash","雙層返刃","leaf_moon",{"size":28,"range":900,"speed":370,"count":3,"spread":.24,"damage":1,"windup":1.03,"origin_y":-66,"return_after":.74,"boss_tell":"ray"})
		"branches":definition=_boss_attack(biome,3,"arc","蛛絲流星","silk_cocoon",{"size":22,"range":750,"speed":310,"gravity":620,"launch_y":-215,"count":2,"spread":.24,"damage":2,"windup":1.15,"origin_y":-52,"boss_tell":"arc"})
		"trunk":definition=_boss_attack(biome,3,"linear","琥珀碎槍","amber_resin",{"size":25,"range":915,"speed":530,"count":2,"spread":.18,"damage":2,"windup":1.22,"origin_y":-55,"boss_tell":"ray"})
		"grass":definition=_boss_attack(biome,3,"trap","落露泥沼","dew_pool",{"size":54,"range":460,"count":3,"damage":1,"arming_time":.9,"lifetime":4.0,"windup":1.04,"origin_y":0})
		_:definition=_boss_attack(biome,3,"slash","潛鑽破根","root_claw",{"size":46,"range":365,"ram":true,"ram_speed":510,"damage":2,"windup":1.12,"active":.7,"origin_y":-46,"boss_tell":"ram"})
	definition["visual_id"]="v57:%s:3"%biome
	definition["hazard_visual_id"]=definition["visual_id"]
	definition["color"]=en["color"]
	if definition["library_kind"]=="trap":definition["hp"]=1.0
	return definition


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
	en["spawn_surface"]="flight" if movements[0] in ["hover","drift"] else "ground"
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
