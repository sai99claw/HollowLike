class_name ArsenalV24
extends RefCounted
const IDS:Array[String]=["needle","chain_staff","impact_bomb","ricochet","homing_missile","trap_pod","moonblade","fire_flask","piercing_laser"]
const Data=preload("res://scripts/game_data.gd")
const MAX_MUSOU:int=16
const MAX_DUPLICATES:int=8
const CRAFT_COST:int=30
static func index_of(id:String) -> int:
	for i in Data.SECONDARY.size():
		if Data.SECONDARY[i]["id"]==id:return i
	return -1
static func random_index(rng:RandomNumberGenerator) -> int:return index_of(IDS[rng.randi_range(0,IDS.size()-1)])
static func acquisition_status(bag:Array,weapon:Dictionary,mode:String) -> String:
	if mode=="rogue":
		for held:Dictionary in bag:
			if held.get("id","")==weapon.get("id",""):
				return "max" if int(held.get("duplicate_bonus",0))>=MAX_DUPLICATES else "upgrade"
	elif bag.size()>=MAX_MUSOU:return "full"
	return "new"

static func acquire(bag:Array,weapon:Dictionary,mode:String) -> String:
	var status:String=acquisition_status(bag,weapon,mode)
	if status in ["max","full"]:return status
	if status=="upgrade":
		for held:Dictionary in bag:
			if held.get("id","")==weapon.get("id",""):
				held["duplicate_bonus"]=mini(MAX_DUPLICATES,int(held.get("duplicate_bonus",0))+1);return "upgrade"
	var fresh:Dictionary=weapon.duplicate(true);fresh["duplicate_bonus"]=clampi(int(fresh.get("duplicate_bonus",0)),0,MAX_DUPLICATES)
	bag.append(fresh);return "new"
