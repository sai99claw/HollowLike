extends SceneTree

const Art=preload("res://scripts/boss_art_v57.gd")
const Combat=preload("res://scripts/combat_library.gd")
const Attack=preload("res://scripts/attack_state.gd")
const Corpses=preload("res://scripts/corpse_field_v21.gd")
const Monster=preload("res://scripts/monster_design.gd")
var failures:int=0

func check(value:bool,description:String) -> void:
	if not value:
		printerr(description)
		failures+=1

func sheet(name:String,columns:int,rows:int) -> void:
	var path:String=Art.ROOT+name+".webp"
	if not ResourceLoader.exists(path):
		check(false,"Missing sheet "+name)
		return
	var texture:Texture2D=load(path)
	var source:Image=texture.get_image()
	check(source!=null,"CPU atlas image readable "+name)
	if source==null:return
	var size:Vector2i=source.get_size()/Vector2i(columns,rows)
	for row in rows:
		var hashes:Dictionary={}
		for col in columns:
			var cell:Image=source.get_region(Rect2i(Vector2i(col,row)*size,size))
			check(cell.get_used_rect().has_area(),"Missing frame "+name+" %d,%d"%[row,col])
			hashes[hash(cell.get_data())]=true
		check(hashes.size()==columns,"Repeated frame "+name+" row %d"%row)

func _initialize() -> void:
	for biome:String in Art.BIOMES:
		sheet(biome,6,9)
		var boss:Dictionary=Combat.boss(biome)
		boss["pos"]=Vector2.ZERO
		boss["attack"]=Attack.new()
		var attacks:Array=boss["attacks"].duplicate()
		attacks.append(Combat.boss_phase_two(boss))
		for slot in 4:
			var def:Dictionary=attacks[slot]
			check(def.get("boss_animation_slot",-1)==slot,"Wrong slot "+biome+" %d"%slot)
			check(def.get("visual_id","")==Art.effect_key(biome,slot),"Wrong VFX "+biome+" %d"%slot)
			check(Monster.texture_for(def["visual_id"])!=null,"VFX asset failed "+biome+" %d"%slot)
			boss["attack"].begin(def)
			for phase:String in ["windup","active","recovery"]:
				boss["attack"].phase=phase
				for j in 2:
					boss["attack"].elapsed=float(def[phase])*(.2+.6*j)
					var pose:Vector3i=Art.pose(boss,0.0)
					check(pose.y==3+slot and pose.x==Art.PHASE_START[phase]+j,"Wrong phase frame "+biome+" %d "%slot+phase)
			boss["attack"].cancel()
		boss["hurt"]=.12
		check(Art.pose(boss,0.0).y==7,"Hurt animation was not selected "+biome)
		boss["hurt"]=0.0
		var modes:Array=boss["movements"]
		for mode:String in modes:
			boss["motion_index"]=modes.find(mode)
			boss["charge_phase"]="idle"
			boss["vel"]=Vector2(54,0)
			match mode:
				"walk","drift":
					check(Art.pose(boss,0.2).y==1,"Locomotion did not use its own row "+biome+":"+mode)
				"hover":
					check(Art.pose(boss,0.2).z==2,"Hover did not use its own strip "+biome)
				"jump":
					boss["vel"]=Vector2.ZERO
					boss["jump_left"]=1.7-float(boss.get("jump_speed",450.0))/1250.0
					check(Art.pose(boss,0.2).y==2,"Jump apex did not use the jump row "+biome)
				"dash":
					boss["charge_phase"]="active"
					boss["charge_left"]=float(boss.get("dash_duration",.6))*.75
					var dash:Vector3i=Art.pose(boss,0.2)
					check(dash.x==2 and dash.y==2 and dash.z==(1 if biome in ["trunk","canopy"] else 0),"Dash did not use its own frames "+biome)
		var extent:Vector2=Art.corpse_extent(biome)
		check(extent.x>1.0 and extent.y>1.0,"Invalid corpse measurement "+biome)
		var corpse:Dictionary=Corpses.create(boss)
		check(corpse.get("boss_v57",false),"Corpse did not select new atlas "+biome)
	for name:String in ["trunk-dash","canopy-dash","sky-hover"]:
		sheet(name,6,1)
	sheet("effects",6,4)
	print("V57 boss atlas verification failures: ",failures)
	quit(0 if failures==0 else 1)
