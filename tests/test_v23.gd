extends "res://tests/test_platformer_v15.gd"
const Maze=preload("res://scripts/custom_maze_generator.gd")
const Map=preload("res://scripts/tower_map_view.gd")
const Pigeon=preload("res://scripts/pigeon_motion_v22.gd")
const Atlas=preload("res://scripts/atlas_v23.gd")
const Platform=preload("res://scripts/platform_art_v23.gd")
const Edge=preload("res://scripts/edge_decor_v23.gd")
const NewBiome=preload("res://scripts/biome_art_v21.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
func run() -> void:
	var rewarded:int=0
	for seed_value in 600:
		var cfg=Maze.MazeConfig.new();cfg.width=17+2*(seed_value%5);cfg.height=9+2*(seed_value%3);cfg.seed_value=seed_value;cfg.platformer=true;cfg.layout_profile=["pillars","terraces","twin_halls","cavern","shaft","loops"][seed_value%6];cfg.doors={"left":5,"right":5,"up":5,"down":5};Maze.apply_profile(cfg)
		var maze=Maze.new(cfg);maze.generate()
		check(maze.validate().is_empty(),"Reserving a long reward tunnel preserves every carved floor and door")
		if not maze.dead_end_rewards.is_empty():rewarded+=1
		for reward:Dictionary in maze.dead_end_rewards:
			check(reward["length"]>=10 and maze._corridor_neighbors(reward["cell"],reward["corridor_stride"]).size()==1,"Every identified reward is an actual10+cell unbraided cul-de-sac")
	print("v23 stage1 statistical complete")
	check(rewarded>=120,"At least20percent of600seeded rooms retain a long reward branch")
	var checked:int=0;var launcher_rooms:int=0
	for seed_value in range(32):
		if checked>=12:break
		var room:Dictionary={"id":seed_value,"width":21,"height":13,"type":"combat","maze_seed":seed_value,"layout_profile":"cavern","maze_config":{"dead_end_chance":1.0},"doors_config":{"left":5,"right":5,"up":5,"down":5}}
		var layout:Dictionary=Layout.generate(room,seed_value);var ps:Array=layout["platforms"]
		check(not layout["dead_end_rewards"].is_empty(),"A100percent RD branch setting creates a real long dead end")
		if not layout["launcher_spawns"].is_empty():launcher_rooms+=1
		for at:Vector2 in layout["launcher_spawns"]:
			check(ps.any(func(surface:Rect2)->bool:return is_equal_approx(surface.position.y,at.y) and at.x-46>=surface.position.x and at.x+46<=surface.end.x),"Launcher feet have full real terrain support")
			check(not layout["solids"].any(func(rock:Rect2)->bool:return rock.intersects(Rect2(at-Vector2(46,400),Vector2(92,399.9)))),"Launcher leaves air for its full triple-height arc")
		var reachable:Dictionary={};var pending:Array[int]=[];var center:Vector2=layout["spawn_positions"]["center"]
		for index in ps.size():
			if absf(center.y-ps[index].position.y)<1 and center.x>=ps[index].position.x and center.x<=ps[index].end.x:reachable[index]=true;pending.append(index)
		var cursor:int=0
		while cursor<pending.size():
			var from:int=pending[cursor];cursor+=1
			for index in ps.size():
				if not reachable.has(index) and jump(ps[from],ps[index],layout):reachable[index]=true;pending.append(index)
		for reward:Dictionary in layout["dead_end_rewards"]:
			var at:=Vector2((reward["cell"].x+.5)*96,(reward["cell"].y+1)*96);var accessible:bool=false
			for index in reachable:
				if absf(ps[index].position.y-at.y)<1 and at.x>=ps[index].position.x+17 and at.x<=ps[index].end.x-17:accessible=true
			check(accessible,"Ordinary jumps can physically reach the chest at the sealed end")
		NewBiome.prepare(layout,seed_value)
		var details:Array=layout["edge_details_v23"];check(not details.is_empty(),"New forefront decorations are instantiated")
		check(details.any(func(item:Dictionary)->bool:return item["size_class"]=="small") and details.any(func(item:Dictionary)->bool:return item["size_class"]=="large"),"Foreground includes fixed small and large authored pieces")
		checked+=1
		print("v23 branch ",checked)
	# An open cavern without a reserved tunnel must still receive launchers.
	var open:Dictionary=Layout.generate({"id":100,"type":"combat","width":25,"height":15,"practice_arena":true,"maze_seed":123},123)
	check(not open["launcher_spawns"].is_empty(),"Large open rooms actually receive the spring object")
	for biome:String in ["sky","trunk","underground"]:
		for cells in range(1,5):
			var data:Dictionary=Platform.definition(biome,cells)
			check(not data.is_empty() and Platform.texture(data)!=null,"Every fixed1/2/3/4cell platform has exported native artwork")
			if cells<4:check(data["asset_id"]=="v21:terrain:"+biome+":"+str(cells+7),"One-way renderer uses the requested v21family")
		check(Atlas.clip("launcher",biome)["frames"].size()==8 and Edge.pieces(biome).size()==6,"Three biomes own8launcher poses and6edge pieces")
	var factor:float=Pigeon.pose_factor()
	for clip:String in ["air","wall"]:
		for frame:Dictionary in Atlas.clip("pigeon-motion",clip)["frames"]:
			var landmarks:Dictionary=frame["body_landmarks"];var head:Array=landmarks["head_center"];var neck:Array=landmarks["neck"]
			var distance:float=Vector2(head[0]-neck[0],head[1]-neck[1]).length()*factor
			check(distance>11 and distance<15,"Air and wall head/neck landmarks retain the walking body's size")
	for side in [-1.0,1.0]:
		var at:=Vector2(700,600);var contact:Vector2=Pigeon.wall_anchor(at,side)
		check(contact==Vector2(700+17*side,600),"Wall visual is rooted at the true side and bottom of the34x42collider")
		for frame:Dictionary in Atlas.clip("pigeon-motion","wall")["frames"]:
			check(frame["pivot"]==frame["wall_contact"],"Wall clip pivot is the authored flatsole contact")
	check(is_equal_approx(PlayerMotion.WALL_SLIDE_SPEED,43.2),"Wall slide is 20 percent faster than v0.67")
	var tower:Dictionary=Tower.generate(3322);var chapters:Array=Map.full_tower_layout(tower,Rect2(180,155,915,422));var points:Dictionary={}
	for chapter:Dictionary in chapters:points.merge(chapter["graph"]["points"])
	check(points.size()==tower["rooms"].size(),"One full tower includes every room")
	var stride:Vector2=chapters[0]["graph"]["stride"]
	for room:Dictionary in tower["rooms"]:
		for next:int in room["neighbors"].values():
			var expected:Vector2=Vector2(tower["rooms"][next]["coord"]-room["coord"])*stride
			check((Vector2(points[next])-Vector2(points[room["id"]])).is_equal_approx(expected),"All room links and cross-stage Boss→Start seams share one continuous tower coordinate transform")
	print("v23 stage2 geometry/art complete")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false);game.practice_mode=true;game.new_run("rogue",3322)
	game._clear_keys();game.p_attack.cancel();game.props.clear();game.enemies.clear();game.hazards.clear();game.solids.clear();game.platforms.clear();game.doors.clear();game.layout={"size":Vector2(2000,1800),"floor_y":1700.0};game._reset_player(Vector2(700,1000))
	var launcher:Dictionary={"kind":"launcher","pos":Vector2(700,1050),"hurt":0.0,"used":false};game.props.assign([launcher]);game._update_props(.01)
	check(is_equal_approx(game.p["vel"].y,-530) and not game.p["grounded"],"Touching the launcher fires immediately at normal jump velocity")
	var touch_velocity:float=game.p["vel"].y;game._hit_props(Rect2(650,960,100,100),1,1)
	check(game.p["vel"].y==touch_velocity,"A remote projectile cannot launch its owner from across the room")
	game.p_attack.begin({"kind":"melee","windup":0.0,"active":.1,"recovery":.1,"damage":1,"direction":"down"});game._hit_props(Rect2(650,960,100,100),1)
	check(is_equal_approx(game.p["vel"].y,-530*sqrt(3.0)),"An intentional attack upgrades an overlapping touch to exactly triple HEIGHT")
	game.p_attack.cancel();game._reset_player(Vector2(700,900));launcher["launch_hit_cooldown"]=0;launcher["launch_cooldown"]=0
	game.p_attack.begin({"kind":"slam","dir":Vector2.DOWN,"windup":0.0,"active":.5,"recovery":.1,"damage":2});game._update_player(.12)
	check(game.p["vel"].y<0 and not game._wind_form_active(),"A swept down-slam into a launcher turns into an upward bounce, not another forced downward frame")
	var heights:Array[float]=[]
	for attacked:bool in [false,true]:
		game._reset_player(Vector2(700,1000));game.p_attack.cancel();game._launch_from_object(launcher,attacked);var peak:float=1000
		for tick in 240:
			game._step_player(1.0/240);peak=minf(peak,game.p["pos"].y)
			if game.p["vel"].y>=0:break
		check(not game.p["jump_cut_allowed"],"Releasing jump cannot truncate a physical launcher impulse")
		heights.append(1000-peak)
	check(heights[1]/heights[0]>2.95 and heights[1]/heights[0]<3.05,"Actual controller integration produces threefold height rather than ninefold")
	game.room={"id":0,"type":"combat","map_index":0};game.layout=Layout.generate({"id":0,"type":"combat","width":21,"height":13,"maze_seed":2,"maze_config":{"dead_end_chance":1.0}},2);game.solids.assign(game.layout["solids"]);game.doors.clear();var props:Array=game._make_props()
	var rewards:Array=props.filter(func(prop:Dictionary)->bool:return prop.has("dead_end_length"))
	check(rewards.size()==game.layout["dead_end_rewards"].size() and not rewards.is_empty(),"Every retained long dead end creates its own actual chest")
	for prop:Dictionary in rewards:
		check(not prop["used"] and game.layout["platforms"].any(func(surface:Rect2)->bool:return absf(surface.position.y-prop["pos"].y)<1 and prop["pos"].x>=surface.position.x and prop["pos"].x<=surface.end.x),"Chest is available on its own real support on first entry")
	for id:String in ["v23:pigeon-motion:wall","v23:launcher:trunk","v23:edge:sky:grass","v23:platform:underground:4"]:check(not Catalog.entry(id).is_empty(),"RD catalog exposes new artwork: "+id)
	game.queue_free();await process_frame
	print("v23: ",rewarded,"/600rewardrooms; ",checked,"physicalchestbranchchecks; ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
