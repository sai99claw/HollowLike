class_name MonsterRosterV55
extends RefCounted

const Legacy=preload("res://scripts/monster_roster_v36.gd")
const Art=preload("res://scripts/monster_art_v55.gd")
const Combat=preload("res://scripts/combat_library.gd")
const NAMES={
	"underground":["灰燼跳蚤","墓沼蟾","提燈蜈蚣","黑曜螳螂","棺甲蠍"],
	"trunk":["樹皮胡蜂","苔痕蛞蝓","荊棘壁虎","刺冠鍬形蟲","空心梟"],
	"sky":["雲魟","霜霧水母","裂風雨燕","暴風鷺","雷翼飛龍"]
}
const MOVES={
	"underground":["jump","walk","walk","walk","walk"],
	"trunk":["hover","walk","jump","walk","hover"],
	"sky":["drift","hover","drift","hover","drift"]
}

static func create(biome:String,row:int,stage:int) -> Dictionary:
	var elite:bool=row>=3
	var enemy:Dictionary=Legacy.elite(stage) if elite else Legacy.regular(biome,row)
	var movement:String=MOVES[biome][row]
	enemy.merge({"id":"v55_%s_%d"%[biome,row],"roster_id":"v55_%s_%d"%[biome,row],"roster_biome":biome,
		"name":NAMES[biome][row],"v55_row":row,"visual_movement":movement,"movements":[movement],
		"spawn_surface":"wall" if biome=="trunk" and row==2 else ("flight" if movement in ["hover","drift"] else "ground"),
		"move":"fly" if movement in ["hover","drift"] else "walk","movement_logic":"roam" if movement!="walk" else "approach",
		"projectile_riposte":elite},true)
	var common:Dictionary={"damage":1.0,"attack_cooldown":1.3,"windup":.5,"active":.22,"recovery":.48,"color":enemy["color"],"parryable":true}
	var charge:Dictionary=Combat.attack("slash",common.merged({"ram":true,"ram_speed":440.0,"range":270.0,"active":.37},true))
	var poison:Dictionary=Combat.attack("linear",common.merged({"poison_cloud":true,"range":245.0,"windup":.62},true))
	var strike:Dictionary=Combat.attack("slash",common.merged({"range":130.0,"size":45.0},true))
	var shot:Dictionary=Combat.attack("flying_slash",common.merged({"range":580.0,"speed":350.0,"size":15.0},true))
	if row==0:enemy["attacks"]=[charge]
	elif row==1:enemy["attacks"]=[poison]
	elif row==2:enemy["attacks"]=[charge if biome=="underground" else strike,shot]
	elif row==3:enemy["attacks"]=[strike,charge]
	else:enemy["attacks"]=[shot,strike]
	enemy["body_size"]=Art.neutral_size(enemy)*.90
	return enemy
