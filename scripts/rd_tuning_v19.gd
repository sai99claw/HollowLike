class_name RDTuningV19
extends RefCounted
## Persisted draft is applied only at the next expedition / practice session.
const SPECS:Array[Dictionary]=[
	{"id":"seed","group":"地圖生成","label":"固定種子（0 為隨機）","default":0,"min":0,"max":2000000000,"step":1},
	{"id":"rooms_per_stage","group":"地圖生成","label":"每關房數（0 為隨機）","default":0,"min":0,"max":12,"step":1},
	{"id":"vertical_bias","group":"地圖生成","label":"縱向生長機率","default":.68,"min":.3,"max":.9,"step":.01},
	{"id":"straight_bias","group":"地圖生成","label":"直線走廊偏好","default":.55,"min":.1,"max":.95,"step":.01},
	{"id":"braid_rate","group":"地圖生成","label":"死巷打通機率","default":.45,"min":0,"max":1,"step":.01},
	{"id":"dead_end_chance","group":"地圖生成","label":"長死路寶箱支線機率","default":.25,"min":.2,"max":1,"step":.05},
	{"id":"plaza_scale","group":"地圖生成","label":"廣場開闊程度","default":1.0,"min":.5,"max":1.5,"step":.05},
	{"id":"room_scale","group":"地圖生成","label":"房間尺寸倍率","default":1.0,"min":.8,"max":1.4,"step":.05},
	{"id":"reward_chance","group":"地圖生成","label":"獎勵房機率","default":.7,"min":0,"max":1,"step":.05},
	{"id":"merchant_chance","group":"地圖生成","label":"每關商店機率","default":.3,"min":0,"max":1,"step":.05},
	{"id":"fountain_chance","group":"地圖生成","label":"戰鬥房泉水機率","default":.1,"min":0,"max":1,"step":.05},
	{"id":"enemy_density","group":"怪物與戰鬥","label":"怪物生成倍率","default":1.2,"min":.5,"max":2.5,"step":.1},
	{"id":"enemy_hp","group":"怪物與戰鬥","label":"怪物生命倍率","default":1.0,"min":.25,"max":3,"step":.05},
	{"id":"enemy_speed","group":"怪物與戰鬥","label":"怪物移速倍率","default":1.0,"min":.5,"max":2,"step":.05},
	{"id":"player_damage","group":"怪物與戰鬥","label":"主副武器傷害倍率","default":1.0,"min":.25,"max":3,"step":.05},
	{"id":"attack_recovery","group":"怪物與戰鬥","label":"攻擊後搖倍率","default":1.0,"min":.25,"max":2,"step":.05},
	{"id":"charge_seconds","group":"移動與集氣","label":"集氣所需秒數","default":1.4,"min":.3,"max":5,"step":.1},
	{"id":"move_speed","group":"移動與集氣","label":"移動速度倍率","default":1.0,"min":.6,"max":1.5,"step":.05},
	{"id":"jump_speed","group":"移動與集氣","label":"跳躍速度倍率","default":1.0,"min":1.0,"max":1.5,"step":.05},
	{"id":"fall_gravity","group":"移動與集氣","label":"下落重力倍率","default":2.0,"min":1,"max":3,"step":.1}]
static var current:Dictionary={}
static func defaults() -> Dictionary:
	var result:Dictionary={}
	for spec:Dictionary in SPECS:result[spec["id"]]=spec["default"]
	return result
static func sanitize(raw:Dictionary) -> Dictionary:
	var result:Dictionary=defaults()
	for spec:Dictionary in SPECS:
		var value:Variant=raw.get(spec["id"],spec["default"])
		if not (value is float or value is int) or not is_finite(float(value)):continue
		result[spec["id"]]=clampf(float(value),float(spec["min"]),float(spec["max"]))
		if float(spec["step"])==1:result[spec["id"]]=int(result[spec["id"]])
	if int(result["rooms_per_stage"]) in [1,2,3,4,5]:result["rooms_per_stage"]=6
	return result
static func activate(raw:Dictionary) -> void:current=sanitize(raw)
static func value(id:String) -> float:
	if current.is_empty():current=defaults()
	return float(current.get(id,1.0))
