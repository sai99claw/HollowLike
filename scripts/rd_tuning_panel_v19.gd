extends Control
signal saved(parameters:Dictionary)
signal closed
const Tuning=preload("res://scripts/rd_tuning_v19.gd")
const Tower=preload("res://scripts/tower.gd")
const Layout=preload("res://scripts/room_layout.gd")
var draft:Dictionary={}
var editors:Dictionary={}
var sliders:Dictionary={}
var body:VBoxContainer
var preview:Node2D
var preview_rooms:Array=[]
var preview_layout:Dictionary={}
var room_preview:bool=false
var preview_cursor:int=0
var preview_title:Label
var current_group:String="地圖生成"
var status:Label
func setup(parameters:Dictionary) -> void:
	draft=Tuning.sanitize(parameters)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var skin:=Theme.new();skin.default_font=load("res://assets/Chinese.otf");skin.default_font_size=17;theme=skin
	var backdrop:=ColorRect.new();backdrop.color=Color("102b2a");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	_label("RD 參數調教",Vector2(50,28),30,Color("ffe2a1"))
	_label("儲存後套用到下一次冒險與練習；現有房間保留原樣。",Vector2(52,76),17)
	var groups:=VBoxContainer.new();groups.position=Vector2(50,145);groups.add_theme_constant_override("separation",14);add_child(groups)
	for group:String in ["地圖生成","怪物與戰鬥","移動與集氣"]:
		var button:=Button.new();button.text=group;button.custom_minimum_size=Vector2(180,52);button.pressed.connect(func()->void:current_group=group;_rebuild());groups.add_child(button)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(252,130);scroll.size=Vector2(670,465);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",16);scroll.add_child(body)
	preview_title=_label("全塔拓撲預覽",Vector2(956,140),20,Color("c4e4d3"))
	preview=Node2D.new();preview.position=Vector2(953,180);preview.draw.connect(_paint_preview);add_child(preview)
	var switcher:=Button.new();switcher.text="全塔／房間";switcher.position=Vector2(955,458);switcher.size=Vector2(125,34);switcher.pressed.connect(func()->void:room_preview=not room_preview;_update_preview());add_child(switcher)
	var next:=Button.new();next.text="下一間";next.position=Vector2(1090,458);next.size=Vector2(100,34);next.pressed.connect(func()->void:preview_cursor+=1;room_preview=true;_update_preview());add_child(next)
	var note:=Label.new();note.position=Vector2(954,500);note.size=Vector2(280,88);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.text="預覽使用目前種子。地圖包含六種房型，Boss 從側面進場；通關後向上接下一關。";add_child(note)
	status=_label("",Vector2(52,605),16,Color("a5d5c5"))
	var footer:=HBoxContainer.new();footer.position=Vector2(50,650);footer.add_theme_constant_override("separation",18);add_child(footer)
	for entry in [["恢復預設",_reset],["儲存並返回",_save],["取消返回",_close]]:
		var button:=Button.new();button.text=entry[0];button.custom_minimum_size=Vector2(190,44);button.pressed.connect(entry[1]);footer.add_child(button)
	_rebuild();_update_preview()
func _label(text:String,at:Vector2,size:int,color:Color=Color("dbe9de")) -> Label:
	var label:=Label.new();label.text=text;label.position=at;label.add_theme_font_size_override("font_size",size);label.modulate=color;add_child(label);return label
func _rebuild() -> void:
	for child in body.get_children():body.remove_child(child);child.queue_free()
	editors.clear();sliders.clear()
	for spec:Dictionary in Tuning.SPECS:
		if spec["group"]!=current_group:continue
		var box:=VBoxContainer.new();body.add_child(box)
		var title:=Label.new();title.text=spec["label"];box.add_child(title)
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);box.add_child(row)
		var slider:=HSlider.new();slider.custom_minimum_size=Vector2(460,27);slider.min_value=spec["min"];slider.max_value=spec["max"];slider.step=spec["step"];slider.value=draft[spec["id"]];row.add_child(slider)
		var spin:=SpinBox.new();spin.custom_minimum_size=Vector2(160,30);spin.min_value=spec["min"];spin.max_value=spec["max"];spin.step=spec["step"];spin.value=slider.value;row.add_child(spin)
		var id:String=spec["id"];editors[id]=spin;sliders[id]=slider
		slider.value_changed.connect(func(value:float)->void:spin.set_value_no_signal(value);set_value(id,value))
		spin.value_changed.connect(func(value:float)->void:slider.set_value_no_signal(value);set_value(id,value))
	status.text="待套用：集氣 %.1f 秒 · 怪物 ×%.1f · 0 房數表示每關隨機 9～11 間"%[draft["charge_seconds"],draft["enemy_density"]]
func set_value(id:String,value:float) -> void:
	draft[id]=value;draft=Tuning.sanitize(draft)
	if editors.has(id):editors[id].set_value_no_signal(draft[id]);sliders[id].set_value_no_signal(draft[id])
	status.text="已修改，儲存後於下次出發套用。集氣 %.1f 秒 · 怪物 ×%.1f"%[draft["charge_seconds"],draft["enemy_density"]]
	_update_preview()
func _update_preview() -> void:
	var seed_value:int=int(draft["seed"]);if seed_value==0:seed_value=190019
	preview_rooms=Tower.generate(seed_value,6,int(draft["rooms_per_stage"]),draft)["rooms"]
	var choices:Array=preview_rooms.filter(func(room:Dictionary)->bool:return room.has("layout_profile"))
	if not choices.is_empty():preview_layout=Layout.generate(choices[preview_cursor%choices.size()],seed_value)
	preview_title.text="房間 · "+str(preview_layout.get("archetype","")) if room_preview else "全塔拓撲預覽"
	preview_title.add_theme_font_size_override("font_size",16 if room_preview else 20)
	preview.queue_redraw()
func _paint_preview() -> void:
	if preview_rooms.is_empty():return
	if room_preview and not preview_layout.is_empty():
		var grid:Array=preview_layout["maze_grid"];var scale_value:float=250.0/grid[0].size()
		for y in grid.size():
			for x in grid[y].size():preview.draw_rect(Rect2(x*scale_value,y*scale_value,scale_value,scale_value),Color("6f9b84") if grid[y][x]==0 else Color("163b37"))
		for ledge:Rect2 in preview_layout["one_way"]:
			preview.draw_line(ledge.position/96*scale_value,Vector2(ledge.end.x,ledge.position.y)/96*scale_value,Color("d4c88e"),1)
		return
	var lo:=Vector2i(999,999);var hi:=Vector2i(-999,-999)
	for room:Dictionary in preview_rooms:lo=lo.min(room["coord"]);hi=hi.max(room["coord"])
	var scale_value:float=minf(240.0/maxi(1,hi.x-lo.x+1),265.0/maxi(1,hi.y-lo.y+1))
	for room:Dictionary in preview_rooms:
		var at:Vector2=(Vector2(room["coord"]-lo)+Vector2.ONE*.5)*scale_value
		for target in room["neighbors"].values():
			var dest:Vector2=(Vector2(preview_rooms[target]["coord"]-lo)+Vector2.ONE*.5)*scale_value
			preview.draw_line(at,dest,Color("709289"),2)
		preview.draw_rect(Rect2(at-Vector2.ONE*scale_value*.3,Vector2.ONE*scale_value*.6),Color("e9ab80") if room["type"]=="boss" else (Color("a1d2ae") if room["type"]=="start" else Color("527f76")))
func _reset() -> void:draft=Tuning.defaults();_rebuild();_update_preview()
func _save() -> void:saved.emit(Tuning.sanitize(draft));closed.emit()
func _close() -> void:closed.emit()
