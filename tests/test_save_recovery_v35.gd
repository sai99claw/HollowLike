extends SceneTree
const Store=preload("res://scripts/meta_store_v35.gd")
var failures:Array[String]=[]
const PATH="user://save_recovery_test.json"
const DEFAULT={"coins":0,"runes":{},"settings":{},"weapons":[]}
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func write(path:String,text:String)->void:
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(text);file.close()
func _initialize()->void:
	var first:Dictionary={"coins":42,"runes":{"gale":3},"settings":{"zoom":1.3},"weapons":[]}
	check(Store.save_data(PATH,first,DEFAULT),"Initial save creates a verified main and backup")
	var loaded:Dictionary=Store.load_data(PATH,DEFAULT)["data"]
	check(loaded["coins"]==42 and loaded["runes"]["gale"]==3 and loaded["settings"]["zoom"]==1.3,"Plain JSON round trips without format migration")
	var second:Dictionary=first.duplicate(true);second["coins"]=77
	check(Store.save_data(PATH,second,DEFAULT),"Replacing existing main is supported")
	check(Store.load_data(PATH,DEFAULT)["data"]["coins"]==77,"Latest valid main is preferred")
	write(PATH,"{interrupted")
	var result:Dictionary=Store.load_data(PATH,DEFAULT)
	check(result["recovered"] and result["data"]["coins"]==42,"Corrupt main recovers previous checkpoint")
	check(Store.save_data(PATH,result["data"],DEFAULT),"Recovered data repairs main without overwriting valid backup")
	check(JSON.parse_string(FileAccess.get_file_as_string(PATH+".bak"))["coins"]==42,"Corrupt main never rotates over good backup")
	write(PATH,"{}")
	check(Store.load_data(PATH,DEFAULT)["recovered"],"Empty object cannot silently wipe warehouse")
	check(not Store.save_data(PATH,{},DEFAULT),"Invalid new data is rejected")
	check(not Store.save_data(PATH,{"coins":0,"runes":[]},DEFAULT),"Malformed rune inventory rejected even if caller defaults have wrong type")
	write(PATH+".bak","broken backup")
	result=Store.load_data(PATH,DEFAULT)
	check(result["damaged"] and result["data"].is_empty(),"Both damaged files are reported")
	check(not Store.save_data(PATH,first,DEFAULT),"Both damaged originals are preserved for recovery instead of overwritten by defaults")
	check(FileAccess.get_file_as_string(PATH)=="{}","Damaged original remains untouched")
	for suffix in ["",".bak",".tmp",".bak.tmp"]:
		if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	print("Save recovery v35: ","passed" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
