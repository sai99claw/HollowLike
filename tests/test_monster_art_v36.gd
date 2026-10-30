extends SceneTree
const Art=preload("res://scripts/monster_art_v36.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Corpse=preload("res://scripts/corpse_field_v21.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String) -> void:
	if not value:failures.append(message);push_error(message)
func run() -> void:
	var actors:int=0;var frames:int=0;var projectile_count:int=0
	var effect_test=Attack.new()
	for primary:bool in [false,true]:
		effect_test.cancel();effect_test.begin({"windup":0.0,"active":.3,"recovery":.2,"primary":primary,"melee_visual_id":"v36:sky:melee_fx"})
		check(Art.melee_visible(effect_test)==primary,"Ranged shots never trigger a giant melee crescent")
	effect_test.attack["ram"]=true;check(not Art.melee_visible(effect_test),"Body rams use their own actor animation, not a sword effect")
	for biome:String in ["underground","trunk","sky"]:
		var data:Dictionary=Art.manifest(biome)
		check(not data.is_empty(),"Runtime metadata is exported: "+biome)
		if data.is_empty():continue
		for sheet:String in ["regular","elite","projectiles"]:
			var spec:Dictionary=data["sheets"][sheet];var tex:Texture2D=Art.texture(spec["path"])
			check(tex!=null,"Actual atlas texture is available in source/PCK: "+biome+sheet)
			if tex==null:continue
			check(tex.get_size()==Vector2(spec["size"][0],spec["size"][1]),"Import keeps the atlas coordinates intact: "+biome+sheet)
			check(spec["frames"].size()==int(spec["columns"])*int(spec["rows"]),"Every authored cell has runtime metadata")
			for f:Dictionary in spec["frames"]:
				var r:Array=f["rect"];var b:Array=f["bounds"];var pivot:Array=f["pivot"]
				check(r[0]>=0 and r[1]>=0 and r[0]+r[2]<=tex.get_width() and r[1]+r[3]<=tex.get_height(),"Region remains within imported texture")
				check(b[2]>0 and b[3]>0 and pivot[0]>=0 and pivot[0]<=r[2] and pivot[1]>=0 and pivot[1]<=r[3],"Pose has visible content and valid pivot")
				frames+=1
		for elite:bool in [false,true]:
			for row:int in (2 if elite else 5):
				actors+=1
				var actor:Dictionary={"roster_id":biome+str(row),"roster_biome":biome,"roster_row":row,"roster_elite":elite,"pos":Vector2(300,500),"vel":Vector2(20,0),"face":1.0,"body_size":Vector2(34,45),"attack":Attack.new(),"hurt":.2}
				for attack_index:int in (2 if elite else 1):
					actor["attack"].cancel();actor["attack"].begin({"windup":.9,"active":.3,"recovery":.6,"roster_attack":attack_index})
					actor["attack"].tick(.1);var early:Dictionary=Art.actor_sample(actor,0)
					actor["attack"].tick(.53);var late:Dictionary=Art.actor_sample(actor,0)
					check(early["phase"]=="windup" and late["phase"]=="windup" and early["column"]!=late["column"],"Every attack has animated preparation even while hurt")
					check(early["row"]==row*(2 if elite else 1)+attack_index,"Elite attacks select their own authored pose row")
					check(Catalog.entry("v36:"+biome+":"+("elite" if elite else "regular")+":"+str(early["row"])+":windup").get("frame_count",0)==(3 if elite else 2),"RD exposes actual authored windup poses")
				var body:Dictionary=Corpse.create(actor)
				check(body.get("identity","")==actor["roster_id"] and body.has("roster_actor"),"Death fall retains new species rather than old creature fallback")
		for id:String in data["projectiles"]:
			var spec:Dictionary=data["projectiles"][id];projectile_count+=1
			check(int(spec["frames"])==8 and int(spec["fps"])>0,"Each projectile/effect has eight independent animation frames")
			check(Catalog.entry("v36:"+biome+":"+id).get("runtime_usage","")=="used","RD labels integrated projectile assets correctly")
			var distinct:Dictionary={}
			for index:int in 8:distinct[str(Art.frame(data,"projectiles",int(spec["row"]),index)["rect"])]=true
			check(distinct.size()==8,"Eight-frame sequence samples eight different cells")
	check(actors==21 and frames==468 and projectile_count==18,"Complete15 regular +6 elite and468 authored cells are present")
	print("Monster art V36: ",actors," actors, ",frames," cells, ",projectile_count," projectile/effect sequences; ",failures)
	quit(0 if failures.is_empty() else 1)
