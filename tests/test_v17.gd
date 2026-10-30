extends SceneTree
const Scale=preload("res://scripts/world_scale_v17.gd")
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/room_layout.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures.append(label);push_error(label)
func run() -> void:
	check(Scale.TILE==96 and Scale.TILE==int(64*1.5),"Every tile grows exactly1.5x")
	for value in Scale.BASE_WIDTHS:check(Scale.WIDTHS.has(Scale.half_odd(value)),"Width baseline is halved and rounded to an odd maze size")
	for value in Scale.BASE_HEIGHTS:check(Scale.HEIGHTS.has(Scale.half_odd(value)),"Height baseline is halved and rounded to an odd maze size")
	for seed_value in [17,12345,91451,192]:
		var tower:Dictionary=Tower.generate(seed_value)
		check(Tower.validate(tower).is_empty(),"Smaller tower remains connected")
		for room:Dictionary in tower["rooms"]:
			check(room["world_pixel_pos"]==room["world_tile_pos"]*96,"World seam positions use the larger cell")
			var result:Dictionary=Layout.generate(room,seed_value)
			check(Layout.validate(result).is_empty(),"No smaller-room spawn overlaps a solid: "+str([seed_value,room["id"]]))
			for solid:Rect2 in result["solids"]:check(solid.size.y>24,"No thin, impassable stair/perch/gallery remains")
			for ledge:Rect2 in result["navigation_one_way"]:
				# v20 routes fit one-cell96px passages instead of the old144px perimeter ladder.
				check(ledge.size.x>=Scale.TILE and not result["solids"].has(ledge) and result["one_way"].has(ledge),"Necessary routes have a full tile of pass-through standing room")
	var game=load("res://main.tscn").instantiate();game.audio_enabled=false;root.add_child(game);await process_frame;game.set_process(false);game.set_physics_process(false)
	game.new_run("rogue",171717);game._close_panel()
	for ledge:Rect2 in game.layout["navigation_one_way"]:check(not game._projectile_surfaces().has(ledge),"Pass-through ledges do not secretly remain projectile walls")
	game.queue_free();await process_frame
	var viewer=load("res://scripts/rd_room_v16.gd").new();root.add_child(viewer);await process_frame;await process_frame
	var chinese:Font=load("res://assets/Chinese.otf")
	for control in [viewer._search,viewer._category,viewer._kind,viewer._list,viewer._name,viewer._category.get_popup(),viewer._kind.get_popup(),viewer._phase.get_popup()]:
		check(control.get_theme_font("font")==chinese,"RD child and popup inherit the Chinese font")
	check(viewer._notes.get_theme_font("normal_font")==chinese,"RD descriptions use the same Chinese font")
	for entry:Dictionary in Catalog.all_entries():
		for character in str(entry["label"])+str(entry["category"])+str(entry["notes"]):
			var code:int=character.unicode_at(0)
			if code>=0x3400 and code<=0x9fff:check(chinese.has_char(code),"Bundled font includes actual catalog character: "+character)
	check(viewer._notes.get_global_rect().end.y<=720,"Chinese font does not push RD controls below viewport")
	check(viewer._search.get_global_rect().end.x<=360 and viewer._kind.get_global_rect().end.y<400,"Search and filters stay visibly above the asset list")
	check(not Catalog.search("鴿子 走路").is_empty(),"Chinese synonyms and multiple search terms find walking art")
	viewer._search.text="pigeon_walk";viewer._search.text_changed.emit(viewer._search.text)
	check(viewer.filtered_entries.size()<Catalog.all_entries().size(),"Typing a keyword reduces the displayed list")
	for entry:Dictionary in viewer.filtered_entries:check(entry["id"].contains("pigeon_walk"),"Keyword search narrows the displayed list")
	viewer.clear_filters();viewer._kind.select(1);viewer._kind.item_selected.emit(1)
	check(viewer.filtered_entries.all(func(e):return e["frame_count"]>1),"Animated filter actually changes visible entries")
	var category_index:int=-1
	for i in viewer._category.item_count:
		if viewer._category.get_item_text(i)=="生態可砍物件":category_index=i
	viewer._category.select(category_index);viewer._category.item_selected.emit(category_index);viewer._search.text="天空";viewer._search.text_changed.emit(viewer._search.text)
	check(viewer.filtered_entries.size()==6,"Category, animation and keyword filters intersect")
	viewer._search.text="不存在的素材999999";viewer._search.text_changed.emit(viewer._search.text);check(viewer.filtered_entries.is_empty() and viewer.current_entry.is_empty() and not viewer.playing and viewer._preview.texture==null,"No match clears old animation and stops playback")
	viewer.clear_filters();check(viewer.filtered_entries.size()==Catalog.all_entries().size() and not viewer.current_entry.is_empty(),"Clear filters restores a valid selection")
	viewer._close();viewer.queue_free();await process_frame
	print("v17: ","passed" if failures.is_empty() else failures);quit(0 if failures.is_empty() else 1)
