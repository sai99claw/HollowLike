class_name MusouDreamV41
extends RefCounted
const Roster=preload("res://scripts/monster_roster_v36.gd")
const CAPACITY:int=20
const RAGE_SECONDS:float=120.0
var energy:int=0
var rage_left:float=0
func clear() -> void:
	energy=0;rage_left=0
func hit() -> void:
	energy=mini(CAPACITY,energy+1)
func step(delta:float) -> void:rage_left=maxf(0,rage_left-maxf(0,delta))
func damage_factor() -> float:return 2.0 if rage_left>0 else 1.0
func injure() -> void:rage_left=RAGE_SECONDS
static func instant(definition:Dictionary) -> Dictionary:
	definition["windup"]=0.0;definition["recovery"]=0.0
	return definition
static func population_factor(stage:int) -> float:return 1.4*pow(1.1,maxi(0,stage))
static func expand_plan(base:Array[Dictionary],layout:Dictionary,stage:int,seed_value:int,doors:Array) -> Array[Dictionary]:
	var result:Array[Dictionary]=base.duplicate(true)
	var ordinary:Array[Dictionary]=[]
	for entry:Dictionary in base:
		if int(entry["model"])!=4:ordinary.append(entry)
	if ordinary.is_empty():return result
	var target:int=ceili(ordinary.size()*population_factor(stage))+base.size()-ordinary.size()
	var candidates:Array[Dictionary]=[]
	var platforms:Array=layout.get("platforms",[])
	for index in platforms.size():
		var platform:Rect2=platforms[index]
		for x in range(ceili(platform.position.x+32),floori(platform.end.x-31),48):
			var at:=Vector2(x,platform.position.y)
			if doors.any(func(door:Dictionary)->bool:return at.distance_to(door["pos"])<180):continue
			var body:=Rect2(at-Vector2(18,46),Vector2(36,45))
			if layout.get("solids",[]).any(func(rock:Rect2)->bool:return rock.intersects(body)):continue
			candidates.append({"pos":at,"platform":index})
	var random:=RandomNumberGenerator.new();random.seed=seed_value+410041
	while result.size()<target and not candidates.is_empty():
		var candidate:Dictionary=candidates.pop_at(random.randi_range(0,candidates.size()-1))
		if result.any(func(entry:Dictionary)->bool:return Vector2(entry["pos"]).distance_to(candidate["pos"])<36):continue
		var entry:Dictionary=ordinary[(result.size()-base.size())%ordinary.size()].duplicate(true)
		entry["pos"]=candidate["pos"];entry["platform"]=candidate["platform"];entry["roster_variant"]=posmod(result.size()+seed_value,Roster.REGULAR_COUNT)
		result.append(entry)
	return result
