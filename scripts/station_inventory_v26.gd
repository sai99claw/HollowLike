class_name StationInventoryV26
extends RefCounted
const Data=preload("res://scripts/game_data.gd")
const Bag=preload("res://scripts/expedition_bag.gd")
const Icons=preload("res://scripts/ui_asset_art.gd")
static func equipped(id:String,slots:Array,strong:Array) -> int:return slots.count(id)+strong.count(id)
static func free_count(id:String,bag:Dictionary,slots:Array,strong:Array) -> int:return maxi(0,int(bag.get(id,0))-equipped(id,slots,strong))
static func available(id:String,bag:Dictionary,vault:Dictionary) -> int:return int(bag.get(id,0))+int(vault.get("runes",{}).get(id,0))
static func store_unused(bag:Dictionary,vault:Dictionary,slots:Array,strong:Array) -> int:
	var total:int=0
	for id:String in bag.keys():
		var count:int=free_count(id,bag,slots,strong)
		if count<=0:continue
		vault["runes"][id]=int(vault["runes"].get(id,0))+count;bag[id]-=count;total+=count
		if int(bag[id])<=0:bag.erase(id)
	return total
static func consume(selection:Array,bag:Dictionary,vault:Dictionary,slots:Array,strong:Array) -> bool:
	if selection.size()!=3:return false
	for id:String in selection:
		if available(id,bag,vault)<selection.count(id):return false
	# Preserve equipped copies whenever any unused carried or stored copy exists.
	for id:String in selection:
		if free_count(id,bag,slots,strong)>0:
			bag[id]-=1
		elif int(vault["runes"].get(id,0))>0:
			vault["runes"][id]-=1
			if int(vault["runes"][id])<=0:vault["runes"].erase(id)
		else:
			bag[id]-=1
			if strong.has(id):strong.erase(id)
			else:
				var index:int=slots.find(id)
				if index>=0:slots[index]=""
		if int(bag.get(id,0))<=0:bag.erase(id)
	return true
static func entries(vault:Dictionary) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	result.append({"key":"coins","category":"resources","name":"金幣","description":"家中永久保存的金幣，可供藍圖鍛造使用。","icon":"coin","count":int(vault.get("coins",0)),"kind":"coins","payload":""})
	for def:Dictionary in Data.all_runes():
		var id:String=def["id"];var count:int=int(vault.get("runes",{}).get(id,0))
		if count>0:result.append({"key":"rune:"+id,"category":"strong" if Data.is_strong(id) else "runes","name":def["name"],"description":def["description"],"icon":Icons.rune(id),"count":count,"kind":"rune","payload":id})
	for i in Data.ITEMS.size():
		var count:int=int(vault.get("items",{}).get(str(i),0));var def:Dictionary=Data.ITEMS[i]
		if count>0:result.append({"key":"item:"+str(i),"category":"items","name":def["name"],"description":def["description"],"icon":"items_"+str(def["id"]),"count":count,"kind":"item","payload":str(i)})
	for i in vault.get("weapons",[]).size():
		var def:Dictionary=Bag.restore_weapon(vault["weapons"][i])
		result.append({"key":"weapon:"+str(i),"category":"weapons","name":def.get("name","附武器"),"description":str(def.get("description",""))+"\n重複強化 +%d"%int(def.get("duplicate_bonus",0)),"icon":Icons.secondary(def),"count":1,"kind":"weapon","payload":str(i)})
	return result
