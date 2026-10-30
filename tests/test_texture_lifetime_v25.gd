extends SceneTree
## Retained CanvasItems hold texture RIDs, not owning Texture2D references.
## Source/existence tests cannot catch a texture released after _draw returns.
const Edge=preload("res://scripts/edge_decor_v23.gd")
var failures:Array[String]=[]
class DecorationCanvas:
	extends Node2D
	var biome:String="trunk"
	var paints:int=0
	func _draw() -> void:
		paints+=1
		var details:Array=[]
		for side:String in ["top","bottom","left","right"]:
			for size_class:String in ["small","medium","large"]:
				for variant in 6:details.append({"pos":Vector2(100,100),"side":side,"size_class":size_class,"variant":variant})
		var layout:Dictionary={"edge_details_v23":details}
		Edge.draw(self,biome,layout,-1)
		Edge.draw(self,biome,layout,1)
func _initialize() -> void:call_deferred("run")
func check(condition:bool,message:String) -> void:
	if not condition:failures.append(message);push_error(message)
func run() -> void:
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/v24/edges/manifest.json"))
	var canvases:Array[DecorationCanvas]=[]
	for biome:String in ["sky","trunk","underground"]:
		var canvas:=DecorationCanvas.new();canvas.biome=biome;canvases.append(canvas);root.add_child(canvas)
	for frame in 4:await process_frame
	var paths:Array[String]=[]
	for canvas:DecorationCanvas in canvases:
		check(canvas.paints==1,"Decorations use retained commands rather than forced redraws")
		for piece:Dictionary in manifest["biomes"][canvas.biome]:
			var path:String="res://assets/v24/edges/"+str(piece["path"]);paths.append(path)
			check(ResourceLoader.has_cached(path),"Drawn texture must survive _draw scope: "+path)
	# Even when a room's retained nodes are replaced, the shared artwork must
	# survive until subsequent rooms can reuse it. Do not load images in checks.
	for canvas:DecorationCanvas in canvases:canvas.queue_free()
	for frame in 4:await process_frame
	for path:String in paths:check(ResourceLoader.has_cached(path),"Room transition must retain texture ownership: "+path)
	print("Texture lifetime: ",paths.size()," artwork paths, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
