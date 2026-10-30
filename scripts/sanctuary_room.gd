class_name SanctuaryRoom
extends RefCounted
const WIDTH:float=1500
const HEIGHT:float=1120
const FLOOR:float=1050
const POOL:=Rect2(480,FLOOR-12,420,54)
const TABLES=[Vector2(370,FLOOR),Vector2(770,FLOOR),Vector2(1170,FLOOR)]
static func is_sanctuary(room:Dictionary) -> bool:return room.get("type","")=="merchant" or bool(room.get("spring",false))
static func generate(room:Dictionary,seed_value:int) -> Dictionary:
	var platforms:Array[Rect2]=[];var floor_parts:Array[Rect2]=[]
	var spring:bool=bool(room.get("spring",false));var down:bool=room.get("neighbors",{}).has("down")
	if spring:
		for part in [[0,480,FLOOR],[480,20,FLOOR+8],[500,20,FLOOR+18],[520,340,FLOOR+28],[860,20,FLOOR+18],[880,20,FLOOR+8],[900,45 if down else 600,FLOOR]]:floor_parts.append(Rect2(part[0],part[2],part[1],HEIGHT-part[2]))
		if down:floor_parts.append(Rect2(1055,FLOOR,445,HEIGHT-FLOOR))
	else:
		floor_parts.assign([Rect2(0,FLOOR,945,HEIGHT-FLOOR),Rect2(1055,FLOOR,445,HEIGHT-FLOOR)] if down else [Rect2(0,FLOOR,WIDTH,HEIGHT-FLOOR)])
	platforms.assign(floor_parts)
	# A fixed side loft gives ordinary-jump access to a ceiling passage.
	var steps:Array=[[290,950,220],[180,850,220],[330,750,220],[500,650,220],[390,550,220],[510,450,220],[390,350,220],[500,250,220]]
	if room.get("neighbors",{}).has("up"):steps.append([550,150,220]);steps.append([595,110,290])
	else:steps.append([595,150,290])
	for step in steps:platforms.append(Rect2(step[0],step[1],step[2],18))
	var walls:Array[Rect2]=[]
	for direction in ["left","right"]:
		var x:float=0 if direction=="left" else WIDTH-18
		if room.get("neighbors",{}).has(direction):walls.append(Rect2(x,0,18,FLOOR-150));walls.append(Rect2(x,FLOOR,18,HEIGHT-FLOOR))
		else:walls.append(Rect2(x,0,18,HEIGHT))
	if room.get("neighbors",{}).has("up"):walls.append(Rect2(0,0,680,18));walls.append(Rect2(800,0,700,18))
	else:walls.append(Rect2(0,0,WIDTH,18))
	var doors:Dictionary={}
	for direction in room.get("neighbors",{}):doors[direction]={"left":Vector2(58,FLOOR),"right":Vector2(WIDTH-58,FLOOR),"up":Vector2(740,20),"down":Vector2(1000,FLOOR+35)}[direction]
	var reserved:Array[Rect2]=[];var spawns:Array[Vector2]=[]
	return {"size":Vector2(WIDTH,HEIGHT),"floor_y":FLOOR,"single_screen":true,"pool":POOL if spring else Rect2(),"platforms":platforms,"walls":walls,"solids":floor_parts+walls,"doors":doors,"spawn_positions":{"center":Vector2(230,FLOOR),"left":Vector2(1340,FLOOR),"right":Vector2(160,FLOOR),"up":Vector2(1110,FLOOR),"down":Vector2(800,110 if room.get("neighbors",{}).has("up") else 150)},"reserved_regions":reserved,"enemy_spawns":spawns,"decorations":[],"route_indices":[],"archetype":"onsen_retreat" if spring else "owl_showroom","seed":seed_value*931+int(room.get("id",0))*1741+32}
static func stock(map_index:int) -> Array[Dictionary]:
	# A curated showroom, stable between visits; three tables, two goods each.
	var catalogs=[[0,4,8,0,8,0],[1,6,10,1,9,1],[2,7,9,2,10,2],[3,8,10,3,4,4],[4,9,7,5,8,7],[5,10,8,6,9,8]]
	var values:Array=catalogs[posmod(map_index,catalogs.size())];var result:Array[Dictionary]=[]
	for i in 6:
		var kind:String="weapon" if i<3 else "rune"
		var value:int=int(values[i])+(preload("res://scripts/game_data.gd").RUNES.size() if i==5 else 0)
		if kind=="weapon":
			var arsenal=preload("res://scripts/arsenal_v24.gd");value=arsenal.index_of(arsenal.IDS[posmod(value,9)])
		result.append({"kind":kind,"value":value,"price":[24,32,44,20,28,60][i],"sold":false,"table":i/2,"pos":TABLES[i/2]+Vector2(-65 if i%2==0 else 65,-124)})
	return result
static func nearest_stock(stock_items:Array,at:Vector2) -> int:
	var nearest:float=125;var chosen:int=-1
	for i in stock_items.size():
		if stock_items[i].get("sold",false):continue
		var pos:Vector2=stock_items[i]["pos"]
		var distance:float=(at-Vector2(0,35)).distance_to(pos)
		if distance<nearest:nearest=distance;chosen=i
	return chosen
