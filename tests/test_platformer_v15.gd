extends SceneTree
const PlayerMotion=preload("res://scripts/player_motion_v18.gd")
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Coll=preload("res://scripts/world_collision.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok and failures.size()<35:failures.append(label);push_error(label)
func jump(a:Rect2,b:Rect2,layout:Dictionary) -> bool:
	for launch in [-1.0,a.position.x+19,a.end.x-19,b.position.x-24,b.end.x+24]:
		if launch>=0 and (launch<a.position.x+18 or launch>a.end.x-18):continue
		for delay in [false,true]:
			for walk_off in [false,true]:
				if walk_off and a.position.y>=b.position.y:continue
				if attempt_jump(a,b,layout,launch,delay,walk_off):return true
	return false
func attempt_jump(a:Rect2,b:Rect2,layout:Dictionary,launch:float=-1,delay:bool=false,walk_off:bool=false) -> bool:
	var rise:float=a.position.y-b.position.y
	var gap:float=maxf(0,maxf(a.position.x-b.end.x,b.position.x-a.end.x))
	if rise>100 or gap>250 or rise < -150:return false
	var from_x:float=clampf(b.get_center().x,a.position.x+18,a.end.x-18)
	if launch>=0:from_x=launch
	var to_x:float=clampf(from_x,b.position.x+18,b.end.x-18)
	var at:=Vector2(from_x,a.position.y);var velocity:=Vector2(0,-530)
	var dropping:bool=rise<0 and (walk_off or layout["one_way"].has(a))
	var through:bool=dropping and layout["one_way"].has(a)
	if dropping:velocity.y=0
	if through:at.y+=3;velocity.y=130
	for frame in 70:
		velocity.x=0 if delay and at.y>b.position.y and velocity.y<0 else clampf((to_x-at.x)*20,-330,330);velocity.y=minf(velocity.y+PlayerMotion.gravity(velocity.y)/60,PlayerMotion.MAX_FALL_SPEED)
		var old:Vector2=at;var result:Dictionary=Coll.move_body(at,velocity,1.0/60,Vector2(34,42),layout["solids"])
		at=result["pos"];velocity=result["vel"]
		if velocity.y>=0:
			var best:float=INF
			for surface:Rect2 in layout["platforms"]:
				if through and frame<14 and is_equal_approx(surface.position.y,a.position.y):continue
				if old.y<=surface.position.y+.1 and at.y>=surface.position.y and at.x+10>surface.position.x and at.x-10<surface.end.x:best=minf(best,surface.position.y)
			if best<INF:at.y=best;result["grounded"]=true
		if result["grounded"]:
			if dropping and not through and absf(at.y-a.position.y)<1 and frame<40:continue
			return absf(at.y-b.position.y)<1 and at.x>=b.position.x+12 and at.x<=b.end.x-12
	return false
func run() -> void:
	var room_count:int=0;var door_count:int=0
	for seed_value in [91451,192]:
		var tower:Dictionary=Tower.generate(seed_value)
		for room:Dictionary in tower["rooms"]:
			var result:Dictionary=Layout.generate(room,seed_value);var platforms:Array=result["platforms"]
			var reachable:Dictionary={};var pending:Array[int]=[]
			var center:Vector2=result["spawn_positions"]["center"]
			for i in platforms.size():
				var surface:Rect2=platforms[i]
				if absf(center.y-surface.position.y)<2 and center.x>=surface.position.x+15 and center.x<=surface.end.x-15:reachable[i]=true;pending.append(i)
			check(not pending.is_empty(),"Spawn on real support "+str([seed_value,room["id"]]))
			var cursor:int=0
			while cursor<pending.size():
				var from:int=pending[cursor];cursor+=1
				for j in platforms.size():
					if reachable.has(j):continue
					if jump(platforms[from],platforms[j],result):reachable[j]=true;pending.append(j)
			for direction in room["neighbors"]:
				var at:Vector2=result["doors"][direction];var possible:bool=false
				for i in reachable:
					var surface:Rect2=platforms[i]
					if direction=="up":
						if surface.position.x+18<at.x and surface.end.x-18>at.x and surface.position.y<=128:possible=true
					elif direction in ["left","right"]:
						if absf(surface.position.y-at.y)<1 and surface.position.x<=at.x+80 and surface.end.x>=at.x-80:possible=true
					else:
						if surface.position.y>=result["size"].y-170 and surface.position.x<=at.x+100 and surface.end.x>=at.x-100:possible=true
				check(possible,"Ordinary jump/drop route to door "+str([seed_value,room["id"],direction,reachable.size(),platforms.size()]))
				door_count+=1
			room_count+=1
	print("Platformer v15: ",room_count," rooms,",door_count," exits, rise1250/fall2500/jump530/body34x42; ",failures)
	quit(0 if failures.is_empty() else 1)
