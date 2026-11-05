class_name RoomEcology
extends RefCounted
## The global tower coordinate owns ecology, independent of chapter / entry order.
## Art can be replaced by biome id without changing room generation or combat.

const Roster=preload("res://scripts/monster_roster_v36.gd")
const IDS:Array[String]=["underground","trunk","sky"]
static func from_stage(stage_index:int) -> Dictionary:
	return _definition(IDS[clampi(stage_index/2,0,2)])
static func describe(height:int) -> Dictionary:
	return _definition("sky" if height>=3 else ("trunk" if height>=-1 else "underground"))
static func _definition(id:String) -> Dictionary:
	match id:
		"sky":return {"id":"sky","name":"蒼藍天空","family":"sky","accent":Color("82c7ff"),"weights":[1.0,2.0,5.0,.8]}
		"trunk":return {"id":"trunk","name":"翡翠樹幹","family":"tree","accent":Color("88d4a0"),"weights":[4.0,3.0,2.0,1.0]}
	return {"id":"underground","name":"土色地底","family":"underground","accent":Color("d9aa76"),"weights":[4.0,2.0,2.0,3.0]}

static func spawn_plan(layout: Dictionary, biome: Dictionary, mode: String, seed_value: int, chapter: int, density:float=1.2) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var groups: Array[Array] = []
	for platform in layout["platforms"]:
		var candidates: Array[Vector2] = []
		for at in layout["enemy_spawns"]:
			if absf(at.y-platform.position.y)<0.1 and at.x>platform.position.x and at.x<platform.end.x:
				candidates.append(at)
		groups.append(candidates)
	var plan: Array[Dictionary] = []
	var chance:float=minf(1,(0.85 if mode=="musou" else 0.55)*density)
	for i in groups.size():
		if groups[i].is_empty() or rng.randf()>chance: continue
		var candidates: Array = groups[i].duplicate()
		var count := mini(candidates.size(), (2 if mode=="musou" else 1)+mini(1,chapter/3))
		for j in count:
			var at: Vector2 = candidates.pop_at(rng.randi_range(0,candidates.size()-1))
			plan.append({"pos":at,"platform":i,"model":_choose(biome["weights"],rng)})
	# Avoid an empty / one-role first encounter while retaining independent rolls.
	# Add unused supports in random order only if fewer than three have rolled.
	var remaining: Array[int] = []
	for i in groups.size():
		if not groups[i].is_empty(): remaining.append(i)
	while plan.size()<3 and not remaining.is_empty():
		var i: int=remaining.pop_at(rng.randi_range(0,remaining.size()-1))
		var at: Vector2=groups[i][rng.randi_range(0,groups[i].size()-1)]
		var used := false
		for entry in plan:
			if entry["pos"]==at: used=true
		if not used: plan.append({"pos":at,"platform":i,"model":_choose(biome["weights"],rng)})
	# Spread the three basic combat roles over randomly selected supports.
	for i in mini(3,plan.size()): plan[i]["model"]=[0,1,2][i]
	# Species variation is stable per support and independent of old role weights.
	for i in plan.size():plan[i]["roster_variant"]=posmod(i+seed_value,Roster.REGULAR_COUNT)
	return plan.slice(0,ceili((14 if mode=="musou" else 8)*density))

static func _choose(weights: Array, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for weight in weights: total+=float(weight)
	var roll := rng.randf()*total
	for i in weights.size():
		roll-=float(weights[i])
		if roll<=0: return i
	return weights.size()-1
