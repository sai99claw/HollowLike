extends SceneTree

const Roster=preload("res://scripts/monster_roster_v55.gd")
const Combat=preload("res://scripts/combat_library.gd")
const Art=preload("res://scripts/monster_art_v55.gd")
var failures:Array[String]=[]

func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var ids:Dictionary={}
	for biome:String in ["underground","trunk","sky"]:
		check(ResourceLoader.exists("res://assets/v55/monsters/"+biome+".webp"),"Creature atlas is packed")
		for row in 5:
			var definition:Dictionary=Roster.create(biome,row,0)
			ids[definition["id"]]=true
			check(definition["elite"]==(row>=3) and definition["projectile_riposte"]==(row>=3),"Each biome has two riposting elites and three regulars")
	check(ids.size()==15,"All fifteen new creatures have stable unique ids")
	for biome:String in ["underground","grass","trunk","branches","canopy","sky"]:
		check(ResourceLoader.exists("res://assets/v55/bosses/"+biome+".webp"),"Boss atlas is packed")
		var boss:Dictionary=Combat.boss(biome)
		check(boss["attacks"].size()==3 and boss["movements"].size()>=2,"Boss has a bespoke attack and movement set")
		check(boss["attacks"].any(func(attack:Dictionary)->bool:return attack.has("boss_tell")),"Boss has a visible tell for a major attack")
		for attack:Dictionary in boss["attacks"]:
			check(ResourceLoader.exists("res://assets/v55/boss_sounds/"+attack["boss_sound"]+".mp3"),"Boss attack cue is packed")
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false);g.set_physics_process(false);g.audio_enabled=false
	g.home_sleeping=false;g.home_wake_left=0;g.p["pos"]=Vector2(620,600)
	check(g._home_interact() and g.trophy_room and not g.ui.is_panel_open(),"Trophy entrance opens a walkable room")
	g.p["pos"]=Vector2(400,600);g.keys["right"]=true;g._update_home(.08)
	check(float(g.p["pos"].x)>400,"The player can walk in the trophy room")
	g.p["pos"]=Vector2(113,600)
	check(g._home_interact() and not g.trophy_room,"Exit returns to the hub")
	g.new_run("rogue",55055)
	var at:Vector2=Vector2(450,400)
	g._emit_weapon(at,Vector2.RIGHT,{"size":10.0,"speed":500,"id":"needle"},true)
	check(is_equal_approx(g.projectiles[-1]["radius"],12.0),"Player projectile radius is increased by 20 percent")
	var elite:Dictionary=Roster.create("trunk",3,2)
	elite.merge({"uid":999,"pos":Vector2(530,425),"attack":g.Attack.new(),"cooldown":0.0},true)
	var shot:Dictionary=g.projectiles[-1]
	check(g._try_projectile_riposte(elite,shot,at,at+Vector2(55,0),12.0) and not shot["from_player"],"Elite slashes and reflects a player projectile")
	g.queue_free()
	await process_frame
	print("v55 expansion checks: ",failures)
	quit(0 if failures.is_empty() else 1)
