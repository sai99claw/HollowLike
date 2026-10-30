extends SceneTree
const NewArt=preload("res://scripts/adventure_art_v29.gd")
const Cloaks=preload("res://scripts/cloak_art_v29.gd")
var failures:Array[String]=[]
func check(value:bool,message:String) -> void:
 if not value:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false)
 game.new_run("musou",30123);game._close_panel();game.bag_weapons.assign([game.Data.secondary_attack(0)]);game.rune_slots.clear();game.strong_slots.clear()
 var def:Dictionary=game._secondary();check(is_equal_approx(float(def["size"])*2,game.ProjectileReadability.PLAYER_HEIGHT/4*1.5),"Projectile diameter equals one quarter times1.5 of canonical player height")
 game.bag_runes={"sub_volume":2};game.rune_slots.assign(["sub_volume"]);var grown:Dictionary=game._secondary()
 check(is_equal_approx(float(grown["size"])/float(def["size"]),1.05),"One size rune grows projectile five percent")
 var wind:Dictionary=NewArt.info("res://assets/v30/effects/wing-puff.json")
 check(wind["frames"].size()==4 and float(wind["duration"])<=.21,"Double jump uses four-frame short puff")
 for i in range(1,5):
  var cloak:Dictionary=Cloaks.definition(i);var factor:float=minf(22.0/float(cloak["visible_height"]),36.0/float(cloak["visible_width"]))
  check(float(cloak["visible_height"])*factor<=22.001 and float(cloak["visible_width"])*factor<=36.001,"Redrawn cloak stays within pigeon shoulder dimensions")
  check(Cloaks.texture(i)!=null and cloak["frames"].size()==3,"All four fitted cloak textures ship")
 for id:String in ["charge_build","charge_release","impact_hit","impact_heavy","attack_whoosh","dash_wind"]:
  check(game.sounds.has(id) and game.sounds[id].get_length()>.1,"Distinct combat sound is included: "+id)
 var vault:Dictionary=game.meta.duplicate(true);game.meta["coins"]=37;game.meta["runes"]={"reach":4};game.meta["items"]={"0":2}
 game.meta["weapons"]=[game.Bag.store_weapon(game.Data.secondary_attack(0))]
 var before:Dictionary={"weapons":game.meta["weapons"].duplicate(true),"coins":game.meta["coins"],"runes":game.meta["runes"].duplicate(),"items":game.meta["items"].duplicate()}
 game.run_coins=999;game.bag_items={"0":5};game.bag_runes={"gale":9};game.rune_slots.assign(["gale"]);game.strong_slots.assign(["reflect"]);game.sub_growth={"power":8};game.weapon_index=2
 game.projectiles.append({"pos":Vector2.ZERO});game.room["cleared"]=true;var old_seed:int=int(game.tower["seed"])
 game.revive_used=true;game._death();check(game.life_event["kind"]=="death" and not game.feather.is_empty(),"Second lethal hit snapshots recoverable feather cache")
 game.life_event["landed"]=true;game.life_event["land_time"]=0;game._update_life_event(1.11)
 check(game.life_event.get("kind")=="await_choice" and game.ui.is_panel_open(),"Death opens rune grid choice")
 game._choose_soul_rune("");game._update_life_event(1.41)
 check(int(game.tower["seed"])==old_seed and game.room["type"]=="start" and game.mode=="musou","Death returns to safety in the same adventure")
 check(game.bag_runes.is_empty() and game.bag_items.is_empty() and game.bag_weapons.is_empty() and game.run_coins==0 and game.rune_slots.is_empty() and game.strong_slots.is_empty() and game.sub_growth.is_empty(),"Carried inventory clears into the recoverable feather cache")
 check(game.projectiles.is_empty() and game.hazards.is_empty() and game.life_event.is_empty() and game.weapon_index==2 and not game.ui.is_panel_open(),"Combat state clears and main weapon choice persists after soul return")
 check(game.meta["weapons"]==before["weapons"] and game.meta["coins"]==before["coins"] and game.meta["runes"]==before["runes"] and game.meta["items"]==before["items"],"Warehouse items and coins persist unchanged")
 game.meta=vault;game._save_meta();game.combat_feedback.clear();game.queue_free();await process_frame
 print("v30: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
