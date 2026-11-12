extends SceneTree

const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Scale=preload("res://scripts/world_scale_v17.gd")
const Motion=preload("res://scripts/player_motion_v18.gd")
var failures:Array[String]=[]

func _initialize() -> void:
	call_deferred("run")

func check(condition:bool,message:String) -> void:
	if not condition:
		failures.append(message)
		if failures.size()<=12:push_error(message)

func is_open(grid:Array,cell:Vector2i) -> bool:
	return cell.y>=0 and cell.y<grid.size() and cell.x>=0 and cell.x<grid[cell.y].size() and grid[cell.y][cell.x]==1

func run() -> void:
	var walls:int=0
	var mushrooms:int=0
	var rooms:int=0
	for seed_value in 10:
		var tower:Dictionary=Tower.generate(seed_value)
		for room:Dictionary in tower["rooms"]:
			var layout:Dictionary=Layout.generate(room,seed_value)
			var plan:Dictionary=layout.get("navigation_plan",{})
			if plan.is_empty():continue
			rooms+=1
			var grid:Array=layout["maze_grid"]
			var connected:Dictionary={}
			for link:Dictionary in plan["climbs"]:
				var lower:Vector2i=link["from"]
				var upper:Vector2i=link["to"]
				connected[lower]=true
				var feet:Vector2=link["feet"]
				if link["method"]=="wall":
					walls+=1
					var left:bool=not is_open(grid,lower+Vector2i.LEFT) and not is_open(grid,upper+Vector2i.LEFT)
					var right:bool=not is_open(grid,lower+Vector2i.RIGHT) and not is_open(grid,upper+Vector2i.RIGHT)
					check(left or right,"Climbing uses a continuous rock face")
					check(link["step_height"]==Scale.TILE_HEIGHT,"Wall routes do not need assisted vertical tiers")
				else:
					mushrooms+=1
					check(plan["launchers"].has(feet),"An open vertical link gets a launch mushroom")
					check(link["step_height"]<=Motion.BASE_JUMP_HEIGHT*3.0*.30,"Mushroom path is planned at 30% of actual down-cut height")
					var approach:=Rect2(feet-Vector2(17,42),Vector2(34,41.9))
					check(not layout["solids"].any(func(rock:Rect2)->bool:return approach.intersects(rock)),"Mushroom has room for the player at launch")
			var cells:Dictionary={}
			for cell:Vector2i in plan["cells"]:cells[cell]=true
			var start:Vector2i=plan["start"]
			var reached:Dictionary={start:true}
			var queue:Array[Vector2i]=[start]
			while not queue.is_empty():
				var cell:Vector2i=queue.pop_front()
				for step:Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var next:Vector2i=cell+step
					if not cells.has(next) or reached.has(next):continue
					if step.y!=0 and not connected.has(cell if step.y<0 else next):continue
					reached[next]=true
					queue.append(next)
			for target:Vector2i in plan["targets"]:
				check(reached.has(target),"Door or reward has a route with available movement")
			check(plan["targets"].has(Vector2i(1,1)) and plan["targets"].has(Vector2i(grid[0].size()-2,1)),"Both upper corners are checked")
			for span:Array in plan["horizontal_links"]:
				for i in range(1,span.size()):
					check(span[i]!=span[i-1],"Long spans alternate mushroom and platform")
	check(rooms>80 and walls>0 and mushrooms>0,"Seeded rooms exercise walls and mushrooms")
	var game=load("res://main.tscn").instantiate()
	game.audio_enabled=false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.new_run("rogue",81081)
	game.enemies.clear()
	game.props.clear()
	game.layout={"size":Vector2(1600,1200),"floor_y":900.0}
	game.solids.assign([Rect2(450,0,50,1200)])
	game.platforms.clear()
	game._reset_player(Vector2(517,850))
	game.p["grounded"]=false
	game.p["wall"]=-1
	game.keys["left"]=true
	game.room_cooldown=999.0
	for jump in 3:
		game._set_action("jump",true)
		for tick in 85:
			game._physics_process(1.0/120.0)
			if tick>22 and game.p["wall"]==-1:break
		game._set_action("jump",false)
	check(game.p["pos"].y<850.0-Scale.TILE_HEIGHT,"Live wall jumps climb a full tall cell without a ledge")
	game._clear_keys()
	game.solids.clear()
	game._reset_player(Vector2(700,850))
	var mushroom:Dictionary={"pos":Vector2(700,850),"navigation":true}
	game._launch_from_object(mushroom,Vector2.DOWN)
	var highest:float=850.0
	for tick in 80:
		game._step_player(1.0/120.0)
		highest=minf(highest,game.p["pos"].y)
	check(highest<850.0-Scale.TILE_HEIGHT,"A down-cut bounces the live controller through a tall cell")
	game.queue_free()
	await process_frame
	print("Traversal rooms: ",rooms,"  wall links: ",walls,"  mushroom links: ",mushrooms,"  failures: ",failures.size())
	quit(0 if failures.is_empty() else 1)
