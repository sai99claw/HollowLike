extends RefCounted
## Main and backup keep the existing plain JSON format. Only validated data
## can become a new checkpoint; interrupted writes stay in the .tmp file.
const SCHEMA={"coins":0,"runes":{},"skills":[],"attempts":0,"skins":[],"skin":0,"best_map":0,"rd_tuning":{},"items":{},"weapons":[],"records":[],"blueprints":[],"trophies":{},"settings":{}}
static var blocked_paths:Dictionary={}

static func valid(data:Variant, _defaults:Dictionary) -> bool:
	if not data is Dictionary or not data.has("coins") or not data.has("runes"):return false
	for key in SCHEMA:
		if not data.has(key):continue # Older saves may omit newer features.
		var value:Variant=data[key]
		var sample:Variant=SCHEMA[key]
		if sample is int or sample is float:
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0:return false
		elif typeof(value)!=typeof(sample):return false
	for key in ["runes","items"]:
		for count in data.get(key,{}).values():
			if not (count is int or count is float) or not is_finite(float(count)) or float(count)<0:return false
	for key in ["weapons","records"]:
		for entry in data.get(key,[]):
			if not entry is Dictionary:return false
	for key in ["skills","blueprints"]:
		for entry in data.get(key,[]):
			if not entry is String:return false
	for collection:Variant in data.get("trophies",{}).values():
		if not collection is Array:return false
		for entry in collection:
			if not entry is String:return false
	return true

static func _read(path:String, defaults:Dictionary) -> Variant:
	if not FileAccess.file_exists(path):return null
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return null
	var data:Variant=parser.data
	return data if valid(data,defaults) else null

static func load_data(path:String, defaults:Dictionary) -> Dictionary:
	var primary:Variant=_read(path,defaults)
	if primary!=null:
		blocked_paths.erase(path)
		return {"data":primary,"recovered":false,"damaged":false}
	var backup:Variant=_read(path+".bak",defaults)
	if backup!=null:
		blocked_paths.erase(path)
		return {"data":backup,"recovered":true,"damaged":true}
	var damaged:=FileAccess.file_exists(path) or FileAccess.file_exists(path+".bak")
	if damaged:blocked_paths[path]=true
	return {"data":{},"recovered":false,"damaged":damaged}

static func _replace(source:String, destination:String) -> bool:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(destination))==OK

static func save_data(path:String, data:Dictionary, defaults:Dictionary) -> bool:
	if blocked_paths.has(path) or not valid(data,defaults):return false
	var temporary:=path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(data));file.flush()
	var error:=file.get_error();file.close()
	if error!=OK or _read(temporary,defaults)==null:return false
	# Never rotate malformed/empty main data over the last good backup.
	var old:Variant=_read(path,defaults)
	var source:=path if old!=null else temporary
	if old!=null or _read(path+".bak",defaults)==null:
		var backup_temporary:=path+".bak.tmp"
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(backup_temporary))!=OK:return false
		if _read(backup_temporary,defaults)==null or not _replace(backup_temporary,path+".bak"):return false
	return _replace(temporary,path)
