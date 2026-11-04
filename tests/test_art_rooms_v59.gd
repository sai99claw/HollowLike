extends SceneTree

const Hazards=preload("res://scripts/hazard_room_v54.gd")
const Chest=preload("res://scripts/chest_art_v59.gd")
const Skill=preload("res://scripts/skill_art_v59.gd")
const Layout=preload("res://scripts/room_layout.gd")
var failures:Array[String]=[]

func check(value:bool,message:String) -> void:
	if not value:failures.append(message)

func sheet(path:String,cell:Vector2i,columns:int,rows:int) -> void:
	var texture:Texture2D=load(path)
	if texture==null:
		check(false,"Missing texture "+path)
		return
	var source:Image=texture.get_image()
	check(source.get_size()==cell*Vector2i(columns,rows),"Correct grid for "+path)
	for row in rows:
		var poses:Dictionary={}
		for col in columns:
			var image:Image=source.get_region(Rect2i(Vector2i(col,row)*cell,cell))
			check(image.get_used_rect().has_area(),"Nonempty sprite "+path)
			poses[hash(image.get_data())]=true
		check(poses.size()==columns,"Each frame is distinct "+path)

func _initialize() -> void:
	for seed in [14,59,107]:
		for kind:String in ["mushroom_air","spike_islands"]:
			var room:Dictionary={"id":4,"type":"combat","map_index":2,"width":29,"height":17,"neighbors":{"left":0,"right":1,"up":2,"down":3},"coord":Vector2i.ZERO,"doors_config":{"left":7,"right":9,"up":11,"down":15}}
			var layout:Dictionary=Layout.generate(room,seed)
			Hazards.prepare(layout,4,kind)
			var size:Vector2=layout["size"]
			var solids:Array=layout["solids"]
			for side:String in ["left","right","up","down"]:
				var at:Vector2=layout["doors"][side]
				var anchor:Vector2
				match side:
					"left":anchor=Vector2(12,at.y-40)
					"right":anchor=Vector2(size.x-12,at.y-40)
					"up":anchor=Vector2(at.x,15)
					_:anchor=Vector2(at.x,size.y-15)
				var clearance:=Rect2(anchor-Vector2(10,10),Vector2(20,20))
				check(not solids.any(func(cell:Rect2)->bool:return cell.intersects(clearance)),"Open "+kind+" "+side+" gate")
			check(solids.any(func(cell:Rect2)->bool:return cell.has_point(Vector2(10,10))),"Physical corner tile exists")
			check(solids.any(func(cell:Rect2)->bool:return cell.has_point(size-Vector2(10,10))),"Physical bottom corner exists")
			if kind=="mushroom_air":
				check(solids.all(func(cell:Rect2)->bool:return cell.position.x==0 or cell.position.y==0 or cell.end.x==size.x or cell.end.y==size.y),"Floating room only has boundary solids")
	for biome:String in ["underground","trunk","sky"]:
		sheet("res://assets/v59/chests/"+biome+".webp",Vector2i(192,160),4,2)
	for biome:String in ["trunk","sky"]:
		sheet("res://assets/v59/monsters/"+biome+".webp",Vector2i(320,256),4,2)
	sheet("res://assets/v59/effects/release.webp",Vector2i(192,144),4,4)
	sheet("res://assets/v59/effects/ring.webp",Vector2i(224,224),4,1)
	check(Chest.frame({"used":false})==0 and Chest.frame({"used":true})==7,"Rest states use first and last chest poses")
	for i in 8:check(Chest.frame({"used":true,"open_left":Chest.DURATION*(1.0-(i+.5)/8)})==i,"Chest frame "+str(i))
	for i in 4:check(Skill.frame((i+.5)/4)==i,"Skill frame "+str(i))
	print("v59 room and art verification: ",failures)
	quit(0 if failures.is_empty() else 1)
