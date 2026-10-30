class_name MazeRoutesV20
extends RefCounted
## A small seeded connector tree follows the actual carved air cells. Existing
## rock tops cost less than suspended bridges; the outer frame costs more.
## Only cells on a route to a portal receive supports, at ordinary jump height.
const Scale=preload("res://scripts/world_scale_v17.gd")
const TILE:float=Scale.TILE
const DIRS:Array[Vector2i]=[Vector2i.UP,Vector2i.RIGHT,Vector2i.LEFT,Vector2i.DOWN]
static func generate(maze,seed_value:int) -> Array[Rect2]:
	var width:int=maze.config.width;var height:int=maze.config.height
	var start:=Vector2i(1,height-2)
	for x in range(1,width-1):
		if maze.is_floor(Vector2i(x,height-2)) and not maze.is_floor(Vector2i(x,height-1)):
			start=Vector2i(x,height-2);break
	var network:Dictionary={start:true};var targets:Array[Vector2i]=[]
	for direction:String in maze.doors:
		var cell:Vector2i=maze.doors[direction]
		match direction:
			"up":targets.append(Vector2i(cell.x,1))
			"down":targets.append(Vector2i(cell.x,height-2))
			"left":targets.append(Vector2i(1,mini(height-2,cell.y+1)))
			"right":targets.append(Vector2i(width-2,mini(height-2,cell.y+1)))
	for reward:Dictionary in maze.dead_end_rewards:targets.append(reward["cell"])
	var random:=RandomNumberGenerator.new();random.seed=seed_value+200020
	var costs:Dictionary={}
	for y in range(1,height-1):
		for x in range(1,width-1):
			var at:=Vector2i(x,y)
			if not maze.is_floor(at):continue
			var natural:bool=not maze.is_floor(at+Vector2i.DOWN)
			var edge:bool=x<=2 or x>=width-3 or y==1
			costs[at]=(.55 if natural else 1.0)+(1.8 if edge else 0.0)+random.randf_range(0,.35)
	# Choose each nearest connection to the network, instead of rebuilding an
	# identical ladder on both edges. Noise breaks equal-cost corridor ties.
	for target:Vector2i in targets:
		if network.has(target):continue
		var distances:Dictionary={};var previous:Dictionary={};var pending:Array[Vector2i]=[]
		for at:Vector2i in network:distances[at]=0.0;pending.append(at)
		while not pending.is_empty():
			var best:int=0
			for i in range(1,pending.size()):
				if distances[pending[i]]<distances[pending[best]]:best=i
			var at:Vector2i=pending[best];pending.remove_at(best)
			if at==target:break
			for step:Vector2i in DIRS:
				var to:Vector2i=at+step
				if not costs.has(to):continue
				var cost:float=float(distances[at])+float(costs[to])
				if cost>=float(distances.get(to,INF)):continue
				distances[to]=cost;previous[to]=at
				if not pending.has(to):pending.append(to)
		var cursor:Vector2i=target
		while not network.has(cursor) and previous.has(cursor):
			network[cursor]=true;cursor=previous[cursor]
	# Adjacent air-cell supports are one bridge. Solid tops already support the
	# player and receive no duplicate one-way collision or extra draw object.
	var result:Array[Rect2]=[]
	for y in range(1,height-1):
		var x:int=1
		while x<width-1:
			if not network.has(Vector2i(x,y)) or not maze.is_floor(Vector2i(x,y+1)):x+=1;continue
			var first:int=x
			while x<width-1 and network.has(Vector2i(x,y)) and maze.is_floor(Vector2i(x,y+1)):x+=1
			result.append(Rect2(first*TILE,(y+1)*TILE,(x-first)*TILE,9))
	return result
