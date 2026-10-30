extends "res://tests/test_platformer_v15.gd"
func reach(start_indices:Array[int],edges:Array) -> Dictionary:
	var result:Dictionary={};var pending:Array[int]=start_indices.duplicate();var cursor:int=0
	for index:int in pending:result[index]=true
	while cursor<pending.size():
		var from:int=pending[cursor];cursor+=1
		for to:int in edges[from]:
			if not result.has(to):result[to]=true;pending.append(to)
	return result
func run() -> void:
	var room_count:int=0;var exit_count:int=0;var ratios:Array[float]=[];var baseline_ratios:Array[float]=[];var routes:Dictionary={};var nav_count:int=0;var old_count:int=0;var nav_length:float=0;var old_length:float=0
	for seed_value in range(10):
		var tower:Dictionary=Tower.generate(seed_value)
		for room:Dictionary in tower["rooms"]:
			if not room.has("layout_profile"):continue
			var layout:Dictionary=Layout.generate(room,seed_value);var ps:Array=layout["platforms"];var nav:Array=layout["navigation_one_way"]
			check(Layout.generate(room,seed_value)["navigation_one_way"]==nav,"Seed reproduces the same traversal supports")
			ratios.append(float(nav.size())/ps.size());nav_count+=nav.size();routes[str(nav)]=true
			for rect:Rect2 in nav:nav_length+=rect.size.x
			var levels:int=roundi((layout["floor_y"]-192)/96)
			var legacy_count:int=levels*2+1+layout["doors"].size()
			baseline_ratios.append(float(legacy_count)/(ps.size()-nav.size()+legacy_count))
			old_count+=legacy_count;old_length+=levels*2*144+layout["size"].x-192
			for direction:String in layout["doors"]:old_length+=144 if direction in ["up","down"] else 240
			# Build actual controller jump/drop edges once; verify both directions,
			# including returning from every entrance, not only reaching an exit.
			var edges:Array=[];var reverse:Array=[]
			for i in ps.size():edges.append([]);reverse.append([])
			for i in ps.size():
				for j in ps.size():
					if i==j:continue
					if jump(ps[i],ps[j],layout):edges[i].append(j);reverse[j].append(i)
			var starts:Array[int]=[];var center:Vector2=layout["spawn_positions"]["center"]
			for i in ps.size():
				if absf(ps[i].position.y-center.y)<2 and center.x>=ps[i].position.x+15 and center.x<=ps[i].end.x-15:starts.append(i)
			var forward:Dictionary=reach(starts,edges);var backward:Dictionary=reach(starts,reverse)
			for direction:String in layout["doors"]:
				var door:Vector2=layout["doors"][direction];var outbound:bool=false;var inbound:bool=false
				for i in ps.size():
					var surface:Rect2=ps[i];var at_door:bool=false
					if direction=="up":at_door=surface.position.y<=128 and surface.position.x+18<door.x and surface.end.x-18>door.x
					elif direction=="down":at_door=surface.position.y>=layout["size"].y-170 and surface.position.x<=door.x+100 and surface.end.x>=door.x-100
					else:at_door=absf(surface.position.y-door.y)<1 and surface.position.x<=door.x+80 and surface.end.x>=door.x-80
					if at_door:outbound=outbound or forward.has(i);inbound=inbound or backward.has(i)
				check(outbound and inbound,"Bidirectional ordinary jump route "+str([seed_value,room["id"],direction,outbound,inbound]))
				exit_count+=1
			room_count+=1
	ratios.sort();var median:float=ratios[ratios.size()/2]
	# v21 has ten-room chapters and physically stitched17x11 functional rows.
	# Compare the same generated geometry against its former dual-ladder layout,
	# rather than a fixed absolute ratio taken from v20's different room sample.
	baseline_ratios.sort();var baseline_median:float=baseline_ratios[baseline_ratios.size()/2]
	check(baseline_median-median>.12 and nav_count<float(old_count)*.75,"Navigation density and count fall materially below the same-room dual-ladder baseline")
	check(nav_length<old_length*.8,"Less suspended bridge length, not merely merged rectangles")
	check(routes.size()>room_count*.85,"Distinct navigation routes across seeded geometry")
	print("v20 traversal: rooms=",room_count," exits=",exit_count," nav median=",median," nav counts=",nav_count,"/",old_count," length=",nav_length,"/",old_length," unique=",routes.size(),"; ",failures)
	quit(0 if failures.is_empty() else 1)
