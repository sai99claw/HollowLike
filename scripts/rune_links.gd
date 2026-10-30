class_name RuneLinks
extends RefCounted
## Orthogonal grid edges only. Empty cells and row-wrap do not connect.
static func edges(slots:Array) -> Array[Vector2i]:
	var result:Array[Vector2i]=[]
	for i in mini(16,slots.size()):
		if str(slots[i]).is_empty():continue
		for next in [i+1 if i%4<3 else -1,i+4]:
			if next<0 or next>=mini(16,slots.size()):continue
			if slots[next]==slots[i]:result.append(Vector2i(i,next))
	return result
static func count_by_id(slots:Array) -> Dictionary:
	var result:Dictionary={}
	for edge in edges(slots):
		var id:String=slots[edge.x];result[id]=int(result.get(id,0))+1
	return result
static func occupied(slots:Array) -> int:
	var count:int=0
	for id in slots:
		if not str(id).is_empty():count+=1
	return count
