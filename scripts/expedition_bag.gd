class_name ExpeditionBag
extends RefCounted
## Home vault is durable. Carried contents / one corpse cache are run-local.
static func snapshot(coins:int,runes:Dictionary,items:Dictionary,weapons:Array) -> Dictionary:
	return {"coins":coins,"runes":runes.duplicate(true),"items":items.duplicate(true),"weapons":weapons.duplicate(true)}
static func remove_one(payload:Dictionary,id:String) -> bool:
	if int(payload["runes"].get(id,0))<=0:return false
	payload["runes"][id]-=1
	if payload["runes"][id]<=0:payload["runes"].erase(id)
	return true
static func merge_counts(target:Dictionary,source:Dictionary) -> void:
	for id in source:target[id]=int(target.get(id,0))+int(source[id])
static func deposit(vault:Dictionary,payload:Dictionary) -> void:
	vault["coins"]=int(vault.get("coins",0))+int(payload["coins"])
	if not vault.has("items"):vault["items"]={}
	merge_counts(vault["runes"],payload["runes"]);merge_counts(vault["items"],payload["items"])
	if not vault.has("weapons"):vault["weapons"]=[]
	for weapon in payload.get("weapons",[]):vault["weapons"].append(store_weapon(weapon))
static func store_weapon(weapon:Dictionary) -> Dictionary:
	var result:Dictionary={}
	for key in weapon:
		var value:Variant=weapon[key]
		if value is Color:result[key]=value.to_html()
		elif value is String or value is float or value is int or value is bool:result[key]=value
	return result
static func restore_weapon(stored:Dictionary) -> Dictionary:
	var result:Dictionary=preload("res://scripts/game_data.gd").normalize_secondary(stored)
	if result.get("color") is String:result["color"]=Color(result["color"])
	return result
