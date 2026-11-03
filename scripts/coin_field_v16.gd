class_name CoinFieldV16
extends RefCounted
## Static broad phase is built once per room; resting circles do no wall scans.
const CELL:float=128
var buckets:Dictionary={}
var surfaces:Array[Rect2]=[]
func rebuild(platforms:Array,solids:Array) -> void:
	buckets.clear();surfaces.clear()
	for raw:Rect2 in solids+platforms:
		if surfaces.has(raw):continue
		var id:int=surfaces.size();surfaces.append(raw)
		for y in range(floori(raw.position.y/CELL),floori(raw.end.y/CELL)+1):
			for x in range(floori(raw.position.x/CELL),floori(raw.end.x/CELL)+1):
				var key:=Vector2i(x,y)
				if not buckets.has(key):buckets[key]=[]
				buckets[key].append(id)
func query(at:Vector2,velocity:Vector2,delta:float,radius:float=16) -> Array:
	var end:Vector2=at+velocity*delta+Vector2(0,1250*delta*delta)
	var area:=Rect2(at.min(end),at.max(end)-at.min(end)).grow(radius)
	var result:Array=[];var seen:Dictionary={}
	for y in range(floori(area.position.y/CELL),floori(area.end.y/CELL)+1):
		for x in range(floori(area.position.x/CELL),floori(area.end.x/CELL)+1):
			for id:int in buckets.get(Vector2i(x,y),[]):
				if not seen.has(id):seen[id]=true;result.append(surfaces[id])
	return result
static func collide(coins:Array) -> void:
	var grid:Dictionary={}
	for i in coins.size():
		var coin:Dictionary=coins[i]
		if coin.get("kind","")!="coin" or coin.get("taken",false) or coin.get("display_only",false) or coin.get("gift",false):continue
		if coin.get("sleeping",false) and Vector2(coin["vel"]).length_squared()<.01:continue
		var key:=Vector2i(Vector2(coin["pos"])/24)
		for dy in range(-1,2):
			for dx in range(-1,2):
				for other:int in grid.get(key+Vector2i(dx,dy),[]):
					var b:Dictionary=coins[other]
					var gap:Vector2=coin["pos"]-b["pos"];var distance:float=gap.length()
					if distance>=14:continue
					var normal:Vector2=gap/distance if distance>.001 else Vector2.RIGHT
					# Side-by-side resting money rolls apart along the floor.
					if coin.get("grounded",false) and b.get("grounded",false):normal=Vector2(signf(gap.x) if absf(gap.x)>.01 else 1,0)
					var correction:Vector2=normal*(14-distance)*.5
					coin["pos"]+=correction;b["pos"]-=correction
					var approach:float=(Vector2(coin["vel"])-Vector2(b["vel"])).dot(normal)
					if approach<0:
						var impulse:Vector2=-normal*approach*.65
						coin["vel"]+=impulse;b["vel"]-=impulse
					if absf(approach)>2 or correction.length()>.2:coin["sleeping"]=false;b["sleeping"]=false
		if not grid.has(key):grid[key]=[]
		grid[key].append(i)
