class_name RuneRandomV29
extends RefCounted
const Data=preload("res://scripts/game_data.gd")
static func choose(bag:Dictionary,stash:Dictionary,use_stash:bool,rng:RandomNumberGenerator) -> Dictionary:
	var small:Array[String]=[];var large:Array[String]=[]
	for def:Dictionary in Data.all_runes():
		var id:String=def["id"];var count:int=maxi(0,int(bag.get(id,0)))+(maxi(0,int(stash.get(id,0))) if use_stash else 0)
		if count<=0:continue
		if Data.is_strong(id):large.append(id)
		else:
			for _n in mini(16,count):small.append(id)
	_shuffle(small,rng);_shuffle(large,rng)
	if small.size()>16:small.resize(16)
	if large.size()>3:large.resize(3)
	var needed:Dictionary={}
	for id:String in small+large:needed[id]=int(needed.get(id,0))+1
	var take:Dictionary={}
	for id:String in needed:
		var n:int=maxi(0,int(needed[id])-maxi(0,int(bag.get(id,0))))
		if n>0:take[id]=n
	return {"small":small,"large":large,"take":take}
static func _shuffle(items:Array[String],rng:RandomNumberGenerator) -> void:
	for i in range(items.size()-1,0,-1):
		var j:int=rng.randi_range(0,i);var value:String=items[i];items[i]=items[j];items[j]=value
