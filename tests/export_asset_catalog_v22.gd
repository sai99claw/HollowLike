extends SceneTree
const Catalog=preload("res://scripts/art_catalog_v16.gd")
func _initialize() -> void:
	var args:PackedStringArray=OS.get_cmdline_user_args()
	if args.is_empty():quit(1);return
	var output:FileAccess=FileAccess.open(args[0],FileAccess.WRITE)
	output.store_string(JSON.stringify(Catalog.all_entries()));output.close();quit(0)
