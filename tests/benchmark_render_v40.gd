extends SceneTree
const Terrain=preload("res://scripts/biome_art_v21.gd")
const Budget=preload("res://scripts/render_budget_v40.gd")
class Probe extends Node2D:
 var layout:Dictionary
 var solids:Array
 var region:Rect2
 var samples:Array=[]
 func _draw() -> void:
  var start:int=Time.get_ticks_usec()
  Terrain.draw_terrain(self,"underground",layout,solids,region)
  Terrain.draw_details(self,"underground",layout,-1,region)
  Terrain.draw_details(self,"underground",layout,1,region)
  samples.append(Time.get_ticks_usec()-start)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var g=load("res://main.tscn").instantiate();g.audio_enabled=false;root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.practice_mode=true;g.new_run("rogue",171);g._close_panel()
 var room:Dictionary=g.tower["rooms"].filter(func(r):return r["type"]=="combat" and int(r["map_index"])==0)[0]
 g._enter_room(room["id"]);g._close_panel();g._process(0)
 var probe:=Probe.new();probe.layout=g.layout;probe.solids=g.solids;root.add_child(probe)
 var result:Dictionary={"note":"CPU command rebuilding only; not WebGL FPS","solids":g.solids.size(),"room_size":str(g.layout["size"])}
 for clipped in [false,true]:
  probe.region=Budget.region(g.view_rect) if clipped else Rect2()
  for i in 12:probe.queue_redraw();await process_frame
  var samples:Array=probe.samples.slice(2);samples.sort()
  result["visible_us" if clipped else "whole_room_us"]=samples[samples.size()/2]
  probe.samples.clear()
 print(JSON.stringify(result));probe.queue_free();g.queue_free();await process_frame;quit()
