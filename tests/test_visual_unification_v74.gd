extends SceneTree

const Edge=preload("res://scripts/platform_overhang_v74.gd")
const Vitals=preload("res://scripts/enemy_vitals_v74.gd")
const Juice=preload("res://scripts/visual_juice_v74.gd")
var failures:Array[String]=[]

func _initialize() -> void:
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	if not ok:
		failures.append(label)
		push_error(label)

func run() -> void:
	var floor:=Rect2(80,500,420,80)
	var layout:Dictionary={"seed":7419,"one_way":[]}
	var decoration:=Edge.plan(layout,[floor])
	check(decoration==Edge.plan(layout,[floor]),"Visual geometry is deterministic for a room seed")
	var corners:int=0
	var hanging:int=0
	for item:Dictionary in decoration:
		var at:Vector2=item["at"]
		if at.x in [floor.position.x,floor.end.x]:corners+=1
		if not item["sway"]:continue
		hanging+=1
		var depth:float=Rect2(item["rect"]).size.y
		check(depth>=25 and depth<=60,"Roots extend outside the platform")
	check(corners==4 and hanging>=4,"The platform has four overhanging corners and a row of hanging roots")
	var enemy:Dictionary={"hp":10.0,"max_hp":10.0}
	check(Vitals.opacity(enemy,10.0)==0,"Full health is hidden")
	Vitals.damaged(enemy,10.0)
	enemy["hp"]=6.0
	check(Vitals.opacity(enemy,10.2)>.9 and Vitals.trailing(enemy,.1)==10.0,"Damage reveals a trailing bar")
	check(Vitals.opacity(enemy,13.4)==0 and Vitals.trailing(enemy,1.0)==6.0,"The bar and its trail decay separately")
	var actor:Dictionary={}
	Juice.squash(actor,Juice.LAUNCH,4.0,.15)
	check(Juice.pose(actor,4.0,false).is_equal_approx(Vector2(.78,1.25)) and Juice.pose(actor,4.16,false)==Vector2.ONE,"Launch stretch ends at rest scale")
	var game=load("res://main.tscn").instantiate()
	game.audio_enabled=false
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.new_run("rogue",74074)
	game._process(.016)
	var world=game.visual_depth
	check(world.spores is GPUParticles2D and world.spores.amount==76,"Standard mode enables 76 additive GPU spores")
	check(world.grade.glow_enabled and world.fogs.size()==2,"Standard mode enables bloom and both fog layers")
	check(world.foreground.z_index>world.details.z_index and world.FOREGROUND_FACTOR>1.4,"The super-foreground sits above platform decor")
	check(world.lantern.position.is_equal_approx(game.world_transform*(game.p["pos"]-Vector2(0,27))) and world.lantern.range_z_min<=game.terrain.z_index,"Lantern follows the pigeon and lights the terrain layer")
	game.low_effects=true
	game._process(.016)
	check(world.spores.amount==32 and not world.grade.glow_enabled and not world.fogs[1].visible,"Reduced mode lowers effects while retaining the lantern")
	check(game.ui.edge_tools.get_child_count()==2 and game.ui.mute_button.visible and game.ui.mute_button.icon!=null,"Menu and mute have visible texture icons")
	game.camera_pos+=Vector2(100,70)
	game._process(.016)
	check(world.canopy_base.origin+world.safe.position==game.world_transform.origin,"Near scenery shares the terrain anchor on both camera axes")
	check(is_equal_approx(game.ui.health_background.size.x,game.ui.energy_cells.get_combined_minimum_size().x),"Health backdrop is only as wide as the energy cells")
	check(game.ui.health_background.texture.resource_path.ends_with("canopy-left.webp"),"The old left canopy now belongs to the health HUD")
	game.room_music.stream=null
	var mute_icon:Texture2D=game.ui.mute_button.icon
	var audio_on:bool=game.audio_enabled
	game.ui.mute_button.pressed.emit()
	check(game.audio_enabled!=audio_on and game.ui.mute_button.icon!=mute_icon,"Clicking the mute icon changes the audio and icon")
	game.ui.mute_button.pressed.emit()
	check(not world.root_sprites.is_empty() and Edge.ART.size()==3,"Both foreground depths use painted textures")
	for sprite:Dictionary in world.root_sprites:
		var local:Rect2=sprite["local"]
		check(local.has_point(Vector2.ZERO) and local.size.x<=46.01 and local.size.y<=41.01,"Opaque near sprite remains small and attached at its edge anchor")
	game.queue_free()
	await process_frame
	print("v74 visual checks: ",failures)
	quit(0 if failures.is_empty() else 1)
