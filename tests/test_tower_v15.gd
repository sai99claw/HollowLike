extends SceneTree
const Tower=preload("res://scripts/tower.gd")
const Maze=preload("res://scripts/custom_maze_generator.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Art=preload("res://scripts/biome_art_v15.gd")
const Ecology=preload("res://scripts/ecology.gd")
const Music=preload("res://scripts/room_music.gd")
var failures:Array[String]=[]
func check(ok:bool,label:String) -> void:
	if not ok and failures.size()<40:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var instance:=Tower.new(6,7);instance.straight_bias=.91;instance.braid_rate=.23;instance.corridor_width_mode="narrow";instance.generate_tower(13)
	check(instance.stages.size()==6 and instance.all_rooms.size()==42 and instance.world_room_map.size()==42,"Configurable instance API builds the complete tower")
	check(instance.all_rooms[0]["maze_config"]=={"straight_bias":.91,"braid_rate":.23,"corridor_width_mode":"narrow","dead_end_chance":.25},"Tower configuration reaches room-maze inputs")
	var tile_set:=TileSet.new();tile_set.tile_size=Vector2i(64,64)
	var image:=Image.create(128,64,false,Image.FORMAT_RGBA8);image.fill(Color.WHITE)
	var atlas:=TileSetAtlasSource.new();atlas.texture=ImageTexture.create_from_image(image);atlas.texture_region_size=Vector2i(64,64);atlas.create_tile(Vector2i.ZERO);atlas.create_tile(Vector2i(1,0));tile_set.add_source(atlas,0)
	var layer:=TileMapLayer.new();layer.tile_set=tile_set
	var output:=Tower.new(1,6);output.generate_tower(771);output.populate_full_tower_to_tilemap_layer(layer)
	var expected_cells:Dictionary={}
	for tile_room in output.all_rooms:
		for y in tile_room["height"]:
			for x in tile_room["width"]:expected_cells[tile_room["world_tile_pos"]+Vector2i(x,y)]=true
	check(layer.get_used_cells().size()==expected_cells.size(),"Native TileMapLayer export writes every unique tower cell")
	for cell_room:Dictionary in output.all_rooms:
		for side in cell_room["doors_config"]:
			var value:int=cell_room["doors_config"][side]
			var cell:Vector2i=Vector2i(value,0 if side=="up" else cell_room["height"]-1) if side in ["up","down"] else Vector2i(0 if side=="left" else cell_room["width"]-1,value)
			check(layer.get_cell_atlas_coords(cell_room["world_tile_pos"]+cell)==Vector2i(1,0),"Cross-room openings are carved into the exported TileMapLayer")
	layer.free()
	var maze_count:int=0;var corridor_modes:Dictionary={};var dimensions:Dictionary={}
	for seed_value in 60:
		var tower:Dictionary=Tower.generate(seed_value)
		check(Tower.validate(tower).is_empty(),"Connected six-stage topology seed"+str(seed_value))
		for stage:Dictionary in tower["maps"]:
			check(stage["merchant_id"]==-1 or tower["rooms"][stage["merchant_id"]]["type"]=="merchant","Optional merchant metadata refers to a real merchant")
			if stage["index"]<5:
				var boss:Dictionary=tower["rooms"][stage["boss_id"]];var next:Dictionary=tower["rooms"][tower["maps"][stage["index"]+1]["start_id"]]
				check(boss["neighbors"].get("left",-1)==next["id"] or boss["neighbors"].get("right",-1)==next["id"],"Boss horizontal exit directly joins next Start")
		for room:Dictionary in tower["rooms"]:
			check(room["width"] in Tower.WIDTHS and room["height"] in Tower.HEIGHTS and room["width"]>room["height"],"Random odd horizontal room bounds")
			dimensions[Vector2i(room["width"],room["height"])]=true
			check(room["biome_id"]==Ecology.from_stage(room["map_index"])["id"],"Two stages per ecology")
			for direction in room["neighbors"]:
				var other:Dictionary=tower["rooms"][room["neighbors"][direction]];var reverse:String=Tower.OPPOSITE[direction]
				var value:int=room["doors_config"][direction];check(value==other["doors_config"][reverse] and value%2==1,"Shared odd doorway")
				var local:=Vector2i(value,0 if direction=="up" else room["height"]-1) if direction in ["up","down"] else Vector2i(0 if direction=="left" else room["width"]-1,value)
				var remote:=Vector2i(value,0 if reverse=="up" else other["height"]-1) if reverse in ["up","down"] else Vector2i(0 if reverse=="left" else other["width"]-1,value)
				check(room["world_tile_pos"]+local==other["world_tile_pos"]+remote,"Door world tiles coincide, no fixed-stride gaps")
			if seed_value>=4:continue
			var cfg:=Maze.MazeConfig.new();cfg.width=room["width"];cfg.height=room["height"];cfg.seed_value=room["maze_seed"];cfg.doors=room["doors_config"].duplicate();cfg.room_max_size=cfg.height-2
			var maze:=Maze.new(cfg);maze.generate();maze_count+=1
			check(maze.validate().is_empty(),"All floor cells, including cross-stage doors, connected")
			for width in maze.corridor_widths:corridor_modes[width]=true
			check(maze.rooms[0].size.y==room["height"]-2,"First plaza spans full interior height")
			var layout:Dictionary=Layout.generate(room,tower["seed"])
			check(Layout.validate(layout).is_empty(),"Room entries clear of solid terrain: "+str([seed_value,room["id"],Layout.validate(layout)]))
	check(dimensions.size()>=15 and corridor_modes.has(1) and corridor_modes.has(2),"Dimension and corridor width diversity")
	for role in ["far","mid"]:check(Art.texture("merchant",role)!=null,"Merchant keeps independent new architecture and awning layers")
	for biome in Art.BIOMES:
		for role in ["far","mid","near","objects","terrain"]:check(Art.texture(biome,role)!=null,"New painted asset imported: "+biome+role)
		for variant in 6:
			check(not Art.object_id(biome,variant).is_empty(),"Six named distinct biome objects")
			for column in 5:check(Art.region(biome,"objects",column,variant)!=null,"All90spriteframes available")
		check(Music.title_for("combat",biome).length()>0 and Music.title_for("start",biome).length()>0,"Music remains mapped by ecology")
	for i in 4:check(Art.cut_frame({"used":true,"break_left":.6-(i+.1)*.15})==i+1,"Four sequential break frames")
	var scene=load("res://main.tscn").instantiate();scene.audio_enabled=false;root.add_child(scene);await process_frame;scene.set_process(false);scene.set_physics_process(false);scene.new_run("rogue",91451);scene._close_panel()
	var doors_checked:int=0;var objects_checked:int=0
	for r:Dictionary in scene.tower["rooms"]:
		r["cleared"]=true;scene._enter_room(r["id"]);scene._close_panel()
		for direction in r["neighbors"].keys():
			scene._enter_room(r["id"]);scene.room_cooldown=0;var at:Vector2=scene.layout["doors"][direction]
			if direction=="up":at.y=32
			elif direction=="down":at.y=scene._room_size().y-20
			scene.p["pos"]=at;scene.p["vel"]=Vector2.ZERO;scene._check_portals()
			check(scene.current_room==r["neighbors"][direction],"All actual portal trigger positions transition: "+str([r["id"],direction]))
			doors_checked+=1
		scene._enter_room(r["id"])
		for prop:Dictionary in scene.props:
			if prop["kind"]!="ecology_object":continue
			scene._hit_props(Rect2(prop["pos"]-Vector2(50,90),Vector2(100,92)),1,99)
			check(prop["used"] and is_equal_approx(prop["break_left"],Art.CUT_DURATION),"Attack destroys actual ecology object and starts sprite animation")
			objects_checked+=1;break
		for en:Dictionary in scene.enemies:
			if en.get("training",false) or en.get("model",0)==4:continue
			for door:Dictionary in scene.doors:check(en["pos"].distance_to(door["pos"])>=180,"No monster beside doors")
	scene.queue_free();await process_frame
	print("v15: ",maze_count," mazes; ",doors_checked," reciprocal live portals; ",objects_checked," cuttable room fixtures;15newatlases;",failures)
	quit(0 if failures.is_empty() else 1)
