extends SceneTree

const Grid = preload("res://scripts/collision_grid.gd")
const Coll = preload("res://scripts/world_collision.gd")
const Flight = preload("res://scripts/flight_navigation.gd")
const Explosion = preload("res://scripts/explosion_v16.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _run() -> void:
	var terrain: Array[Rect2] = [
		Rect2(-256,128,1536,64), Rect2(128,0,24,128), Rect2(512,-128,32,256),
		Rect2(-24,64,48,16), Rect2(128,0,24,128), Rect2(72,96,36,32)
	]
	var grid := Grid.new()
	grid.rebuild(terrain)
	var rng := RandomNumberGenerator.new()
	rng.seed = 531
	var equivalent := true
	for i in 1000:
		var at := Vector2(rng.randf_range(-280,1100),rng.randf_range(-180,190))
		var vel := Vector2(rng.randf_range(-1600,1600),rng.randf_range(-1600,1600))
		var finish := at + vel * .06
		var radius := rng.randf_range(1,24)
		var exact := Coll.first_solid(at,finish,radius,terrain)
		var local := Coll.first_solid(at,finish,radius,terrain,grid)
		equivalent = equivalent and exact == local
		var old := Coll.move_body(at,vel,.06,Vector2(34,42),terrain)
		var indexed := Coll.move_body(at,vel,.06,Vector2(34,42),terrain,0,false,[],grid)
		equivalent = equivalent and old == indexed
		if exact < INF:
			var impact := at.lerp(finish,maxf(0,exact-.0001))
			equivalent = equivalent and Explosion.contact(impact,vel,terrain,radius) == Explosion.contact(impact,vel,grid.query(Rect2(impact,Vector2.ZERO).grow(radius+2)),radius)
	check(equivalent,"Indexed sweeps, contact normals and body movement match full scans")
	check(grid.ids(Rect2(128,128,0,0)) == [0,1,4],"Cell boundary preserves inclusion, duplicates and input order")
	var flyer := {"pos":Vector2(108,74),"speed":96.0}
	var indexed_flyer := flyer.duplicate(true)
	for i in 40:
		var goal := Vector2(300,32)
		var a := Flight.steer(flyer,goal,Vector2.RIGHT*96,Vector2(22,30),terrain,1.0/60)
		var b := Flight.steer(indexed_flyer,goal,Vector2.RIGHT*96,Vector2(22,30),terrain,1.0/60,grid)
		check(a == b and flyer == indexed_flyer,"Indexed flight follows the original navigation and escape probes")
		flyer["pos"] += a / 60
		indexed_flyer["pos"] += b / 60

	var game = load("res://main.tscn").instantiate()
	game.audio_enabled = false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.new_run("rogue",531)
	game._close_panel()
	game.enemies.clear()
	game.solids.clear()
	var ledge := Rect2(200,200,160,8)
	game.platforms.assign([ledge,Rect2(0,600,800,20)])
	game.layout["one_way"] = [ledge]
	game._rebuild_projectile_surfaces()
	check(game._enemy_support({"pos":Vector2(250,200)}) == ledge,"Indexed ground support includes one-way ledges")
	check(Coll.first_solid(Vector2(250,180),Vector2(250,240),1,game._projectile_surfaces(),game._shot_terrain) == INF,"One-way ledges remain transparent to projectiles")
	game._clear_projectiles()
	var def := {"count":1,"size":20,"color":Color.WHITE,"target":Vector2(345,600)}
	game._emit_traps({"pos":Vector2(90,250),"uid":20},def)
	game._emit_traps({"pos":Vector2(540,250),"uid":21},def)
	var friendly := def.duplicate()
	friendly["from_player"] = true
	game._emit_traps({"pos":Vector2(90,250),"uid":22},friendly)
	check(game._hostile_carriers.size() == 2,"Index contains only enemy carriers")
	game.projectiles[0]["vel"] = Vector2(2100,0)
	game.projectiles[0]["gravity"] = 0.0
	game._update_projectiles(.04)
	var hostile: Dictionary = game.projectiles[0]
	var old_zone := Rect2(80,200,20,40)
	game._damage_traps(old_zone,1)
	check(hostile["life"]>0,"A carrier is removed from its old bucket after crossing a cell")
	var at: Vector2 = hostile["pos"]
	game._damage_traps(Rect2(at-Vector2.ONE*8,Vector2.ONE*16),1)
	check(hostile["destroyed"] and game.projectiles[1]["life"]>0 and game.projectiles[2]["life"]>0 and game._hostile_carriers.size()==1,"Only the nearby hostile carrier is destroyed")
	game._update_projectiles(.5)
	check(game._hostile_carriers.is_empty(),"Expired and settled carriers are removed from the index")
	game._emit_traps({"pos":Vector2(90,250),"uid":23},def)
	game._enter_room(game.current_room)
	check(game._hostile_carriers.is_empty() and game.projectiles.is_empty(),"Entering a room resets the carrier index")
	game.queue_free()
	await process_frame
	print("Collision broad phase: ",failures," failures")
	quit(int(failures>0))
