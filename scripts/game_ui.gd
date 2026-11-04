class_name GameUI
extends CanvasLayer

signal action_requested(action: String, payload: Variant)
signal touch_action(action: String, pressed: bool)

const INK := Color("edf3de")
const MUTED := Color("a7bbb0")
const PAPER := Color("142d2c")
const LINE := Color("38534b")
const MINT := Color("8bcbb0")
const GOLD := Color("e8c381")
const Icons=preload("res://scripts/ui_asset_art.gd")
const Inventory=preload("res://scripts/inventory_view.gd")
const Cells=preload("res://scripts/vital_cells.gd")

var ui_root: Control
var header: PanelContainer
var title_label: Label
var location_label: Label
var hp_label: Label
var energy_label: Label
var coins_label: Label
var weapon_label: Label
var phase_label: Label
var phase_bar: ProgressBar
var dream_row:VBoxContainer
var dream_label:Label
var dream_cells:Array[ColorRect]=[]
var health_bar: ProgressBar
var energy_bar: ProgressBar
var health_cells:HBoxContainer
var energy_cells:HBoxContainer
var message_label: Label
var legend_label: Label
var prep_button: Button
var overlay: Control
var panel_title: Label
var panel_rows: VBoxContainer
var touch_controls: Control
var _touch_enabled: bool = false
var _message_timer: float = 0.0
var _last_message: String = ""
var shortcut_buttons:Dictionary={}
var primary_art:TextureRect
var coin_art:TextureRect
var minimap_button:Button
var quickbar:HBoxContainer
var _focus_index:int=0
var mute_button:Button
var secondary_art:TextureRect
var secondary_label:Label
var inspector:PanelContainer
var inspect_title:Label
var inspect_body:Label
var inspect_art:TextureRect
var quickbar_rebuilds:int=0
var _quickbar_signature:String=""
var trial_panel:PanelContainer
var trial_caption:Label
var trial_buy:Button
var trial_return:Button
var _trial_signature:String=""
var station_page:String=""
var station_selection:String=""
var station_focus_key:String=""
var inventory_page:String=""
var inventory_focus_key:String=""
var equipment_navigation=preload("res://scripts/equipment_navigation_v25.gd").new()
var attack_feedback_reason:String=""
var attack_feedback_timer:float=0
var _feedback_cooldown:float=0



func _ready() -> void:
	setup()


func setup() -> void:
	if is_instance_valid(ui_root):
		return
	layer = 30
	ui_root = Control.new()
	ui_root.name = "GameInterface"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)
	var theme_value := Theme.new()
	theme_value.default_font_size = 16
	theme_value.set_color("font_color","Label",INK)
	theme_value.set_color("font_color","Button",INK)
	if ResourceLoader.exists("res://assets/Chinese.otf"):
		theme_value.default_font = load("res://assets/Chinese.otf") as Font
	ui_root.theme = theme_value
	_build_header()
	_build_messages()
	_build_panel()
	_build_touch()
	set_touch_visible(OS.has_feature("mobile"))


func _build_header() -> void:
	# Compact floating vitals; no full-width bar obscures the room.
	header = PanelContainer.new()
	header.name = "CompactVitals"
	header.position = Vector2(20,16)
	header.custom_minimum_size = Vector2(440,100)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel", _box(Color(0.035,0.09,0.09,0.78),Color.TRANSPARENT,12,12))
	ui_root.add_child(header)
	var main := VBoxContainer.new()
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_theme_constant_override("separation",5)
	header.add_child(main)
	title_label = _label("枝間鴿行",16,INK)
	title_label.visible = false
	main.add_child(title_label)
	location_label = _label("鳥巢 · 選擇冒險",12,MINT)
	main.add_child(location_label)
	var vitals := HBoxContainer.new()
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals.add_theme_constant_override("separation",8)
	main.add_child(vitals)
	hp_label = _label("生命 5 / 5",13,INK)
	vitals.add_child(hp_label)
	health_bar = _bar(Color("e8a18c"),Vector2(70,6))
	health_bar.visible=false;vitals.add_child(health_bar)
	health_cells=Cells.new();health_cells.name="HealthCells";health_cells.filled_color=Color("e8a18c");vitals.add_child(health_cells)
	energy_label = _label("能量 3 / 6",13,INK)
	vitals.add_child(energy_label)
	energy_bar = _bar(MINT,Vector2(62,6))
	energy_bar.visible=false;vitals.add_child(energy_bar)
	energy_cells=Cells.new();energy_cells.name="EnergyCells";energy_cells.filled_color=MINT;vitals.add_child(energy_cells)
	coin_art=_icon("coin",20)
	vitals.add_child(coin_art)
	coins_label = _label("金幣 0",13,GOLD)
	vitals.add_child(coins_label)
	var equipment_row:=HBoxContainer.new()
	equipment_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	equipment_row.add_theme_constant_override("separation",6)
	main.add_child(equipment_row)
	primary_art=_icon("weapon_feather",24)
	equipment_row.add_child(primary_art)
	weapon_label = _label("",11,MUTED)
	equipment_row.add_child(weapon_label)
	var secondary_row:=HBoxContainer.new();secondary_row.add_theme_constant_override("separation",7);secondary_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;main.add_child(secondary_row)
	secondary_art=_icon("",28);secondary_row.add_child(secondary_art)
	secondary_label=_label("副武器 尚未裝備 · Q 切換",13,MINT);secondary_label.custom_minimum_size.x=300;secondary_row.add_child(secondary_label)
	var phase_row:=HBoxContainer.new();phase_row.name="AttackReadiness";phase_row.add_theme_constant_override("separation",10);main.add_child(phase_row)
	phase_label = _label("可出擊",12,MINT)
	phase_label.custom_minimum_size.x=218
	phase_row.add_child(phase_label)
	phase_bar = _bar(MINT,Vector2(108,4));phase_bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	phase_row.add_child(phase_bar)
	dream_row=VBoxContainer.new();dream_row.name="DreamEnergy";dream_row.visible=false;main.add_child(dream_row)
	dream_label=_label("無雙能量 0 / 20",12,GOLD);dream_row.add_child(dream_label)
	var cells:=HBoxContainer.new();cells.add_theme_constant_override("separation",3);dream_row.add_child(cells)
	for i in 20:
		var cell:=ColorRect.new();cell.custom_minimum_size=Vector2(9,7);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;cells.add_child(cell);dream_cells.append(cell)
	var tools := HBoxContainer.new()
	tools.position = Vector2(944,18)
	tools.add_theme_constant_override("separation",6)
	ui_root.add_child(tools)
	for entry: Array in [["裝備 E","bag"],["符文 R","runes"],["選單 Esc","settings"]]:
		var button := _button(str(entry[0]),str(entry[1]),null)
		shortcut_buttons[str(entry[1])]=button;button.focus_mode=Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(98,34)
		button.add_theme_font_size_override("font_size",12)
		tools.add_child(button)
	mute_button=_button("聲音：開", "mute", null);mute_button.focus_mode=Control.FOCUS_NONE;mute_button.name="TopMuteButton";mute_button.position=Vector2(809,18);mute_button.custom_minimum_size=Vector2(120,34);ui_root.add_child(mute_button)
	prep_button = _button("安全屋 ↑","prep",null)
	prep_button.focus_mode=Control.FOCUS_NONE
	prep_button.position = Vector2(20,190)
	prep_button.visible = false
	ui_root.add_child(prep_button)
	minimap_button=_button("Tab 切換地圖","",null);minimap_button.disabled=true;minimap_button.focus_mode=Control.FOCUS_NONE;minimap_button.mouse_filter=Control.MOUSE_FILTER_IGNORE
	minimap_button.position=Vector2(950,86);minimap_button.custom_minimum_size=Vector2(312,32)
	ui_root.add_child(minimap_button)
	quickbar=HBoxContainer.new();quickbar.position=Vector2(20,642);quickbar.add_theme_constant_override("separation",6);ui_root.add_child(quickbar)


func _build_messages() -> void:
	message_label = _label("", 19, INK)
	message_label.name = "Message"
	message_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	message_label.offset_left = 40
	message_label.offset_right = -40
	message_label.offset_top = 155
	message_label.offset_bottom = 192
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_shadow_color", Color(0.04, 0.10, 0.09, 0.9))
	message_label.add_theme_constant_override("shadow_offset_x", 1)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	message_label.visible = false
	ui_root.add_child(message_label)
	legend_label = _label("移動 方向鍵    跳躍 Space    攻擊 X    衝刺 C ×2    副武器 Z    回血 A    地圖 Tab", 12, INK)
	legend_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	legend_label.offset_left = 20
	legend_label.offset_right = -20
	legend_label.offset_top = -32
	legend_label.offset_bottom = -8
	legend_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend_label.add_theme_color_override("font_shadow_color", Color(0.03, 0.09, 0.07, 0.85))
	legend_label.add_theme_constant_override("shadow_offset_y", 1)
	ui_root.add_child(legend_label)


func _build_panel() -> void:
	overlay = Control.new()
	overlay.name = "PanelOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_root.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.035,0.04,0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	var frame := PanelContainer.new()
	frame.name = "Panel"
	frame.anchor_left = 0.08
	frame.anchor_top = 0.04
	frame.anchor_right = 0.92
	frame.anchor_bottom = 0.96
	frame.add_theme_stylebox_override("panel", _box(PAPER, LINE, 18, 22))
	overlay.add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 15)
	frame.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	panel_title = _label("背包", 25, INK)
	panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(panel_title)
	var close := _button("關閉  ×", "close", null)
	close.custom_minimum_size = Vector2(100, 38)
	title_row.add_child(close)
	var separator := HSeparator.new()
	separator.modulate = LINE
	column.add_child(separator)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	panel_rows = VBoxContainer.new()
	panel_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_rows.add_theme_constant_override("separation", 14)
	scroll.add_child(panel_rows)
	inspector=PanelContainer.new();inspector.name="ItemInspector";inspector.custom_minimum_size=Vector2(0,94);inspector.add_theme_stylebox_override("panel",_box(Color("102825"),Color("766b8d"),12,10));column.add_child(inspector)
	var detail_row:=HBoxContainer.new();detail_row.add_theme_constant_override("separation",16);inspector.add_child(detail_row)
	inspect_art=_icon("",62);detail_row.add_child(inspect_art)
	var details:=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",3);detail_row.add_child(details)
	inspect_title=_label("",18,GOLD);details.add_child(inspect_title)
	inspect_body=_label("",13,INK);inspect_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;inspect_body.max_lines_visible=3;details.add_child(inspect_body)
	inspector.visible=false
	overlay.visible = false


func _build_touch() -> void:
	touch_controls = preload("res://scripts/screen_touch_v29.gd").new()
	touch_controls.name = "TouchControls"
	ui_root.add_child(touch_controls)
	touch_controls.action_changed.connect(func(action:String,pressed:bool)->void:touch_action.emit(action,pressed))


func update_hud(info: Dictionary) -> void:
	setup()
	var hp:int=maxi(0,int(info.get("hp",5)))
	var max_hp:int=maxi(1,int(info.get("max_hp",5)))
	var energy:int=maxi(0,int(info.get("energy",3)))
	var max_energy:int=maxi(1,int(info.get("max_energy",6)))
	hp_label.text = "生命 %d / %d" % [hp,max_hp]
	energy_label.text = "能量 %d / %d" % [energy,max_energy]
	health_cells.set_state(hp,max_hp,float(info.get("hp_recovery",0)),bool(info.get("hp_recovering",false)))
	energy_cells.set_state(energy,max_energy,float(info.get("energy_recovery",0)),bool(info.get("energy_recovering",false)))
	health_bar.value = float(hp) / max_hp * 100.0
	energy_bar.value = float(energy) / max_energy * 100.0
	coins_label.text = "金幣 %s" % str(info.get("coins", 0))
	if coin_art.texture==null:coin_art.texture=Icons.texture("coin")
	for weapon in Icons.Data.PRIMARY:
		if str(weapon["name"])==str(info.get("weapon","")):primary_art.texture=Icons.texture(Icons.primary(weapon));break
	var mode_value: String = str(info.get("mode", ""))
	var mode_name: String = "無雙夢境" if mode_value in ["musou", "無雙", "無雙夢境"] else "Roguelike"
	if mode_value in ["", "hub", "鳥巢"]:
		mode_name = "鳥巢"
	var map_value: String = str(info.get("map", "—"))
	var room_value: String = str(info.get("room", ""))
	var biome_value: String = str(info.get("biome", "樹枝"))
	location_label.text = "%s · 圖 %s · %s %s  ·  %d FPS" % [mode_name, map_value, biome_value, room_value, int(info.get("fps",60))]
	var home:bool=mode_name=="鳥巢"
	if home:location_label.text="鳥巢 · 選擇左右大門開始冒險"
	elif bool(info.get("in_start",false)):location_label.text="安全屋 · "+biome_value
	dream_row.visible=mode_name=="無雙夢境" and not home
	if dream_row.visible:
		var amount:int=clampi(int(info.get("dream_energy",0)),0,20)
		var rage_left:float=float(info.get("dream_rage",0))
		dream_label.text="無雙能量 %d / 20"%amount+(" · 攻擊 ×2　%d秒"%ceili(rage_left) if rage_left>0 else "")
		for i in dream_cells.size():dream_cells[i].color=GOLD if i<amount else Color("30434e")
	for control:Control in [hp_label,energy_label,health_cells,energy_cells]:control.visible=not home
	primary_art.get_parent().visible=not home
	secondary_art.get_parent().visible=not home
	header.custom_minimum_size=Vector2(330,0) if home else Vector2(440,100)
	if home:header.reset_size()
	var revive_value:String="重傷 · 回安全屋急救" if info.get("injured",false) else "健全"
	weapon_label.text = "主武器 %s  ·  %s" % [str(info.get("weapon", "—")), str(revive_value)]
	secondary_label.text="附武器 %s ×%d  ·  %s 切換"%[str(info.get("sub","尚未裝備")),int(info.get("sub_count",0)),str(info.get("cycle_key","Q"))]
	secondary_art.texture=Icons.texture(str(info.get("sub_icon","")))
	mute_button.text="聲音：開" if info.get("audio_enabled",true) else "聲音：靜音"
	var phase: String = str(info.get("phase", "idle"))
	var remaining:float=float(info.get("phase_remaining",0))
	var ready:bool=phase=="idle"
	if ready and attack_feedback_reason in ["busy","locked"]:clear_attack_feedback()
	phase_label.get_parent().visible=bool(info.get("show_attack",false))
	var phases:Dictionary={"idle":"可出擊", "windup":"前搖", "active":"攻擊中", "recovery":"後搖"}
	phase_label.text=str(phases.get(phase,phase))
	if not ready:phase_label.text+=" %.1f 秒"%remaining
	if phase=="recovery":phase_label.text+=" · %s 可取消"%str(info.get("dash_key","C"))
	if attack_feedback_timer>0:
		match attack_feedback_reason:
			"energy":phase_label.text="能量不足 · 近戰命中回能"
			"no_weapon":phase_label.text="尚未裝備副武器"
			"hurt":phase_label.text="受傷硬直中"
			"busy","locked":phase_label.text="尚未就緒 · "+phase_label.text if not ready else "技能施放中"
	phase_bar.value=100 if ready else clampf(float(info.get("phase_progress",0)),0,1)*100
	var phase_color:Color=MINT if ready or phase=="active" else GOLD
	phase_bar.modulate=Color("ffb482") if attack_feedback_timer>0 else phase_color
	phase_label.modulate=Color("ffc296") if attack_feedback_timer>0 else Color.WHITE
	prep_button.visible = bool(info.get("in_start", false))
	var message: String = str(info.get("message", ""))
	if not message.is_empty() and message != _last_message:
		_last_message = message
		show_message(message)


func show_panel(title: String, sections: Array[Dictionary]) -> void:
	setup()
	inspector.visible=false;inventory_page=""
	if trial_panel!=null:trial_panel.visible=false
	panel_title.text = title
	for child: Node in panel_rows.get_children():
		panel_rows.remove_child(child)
		child.queue_free()
	for section: Dictionary in sections:
		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 7)
		panel_rows.add_child(group)
		var heading: String = str(section.get("heading", ""))
		if not heading.is_empty():
			group.add_child(_label(heading, 18, INK))
		var text_value: String = str(section.get("text", ""))
		if not text_value.is_empty():
			var body := _label(text_value, 15, MUTED)
			body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var clip:String=str(section.get("icon",Icons.by_text(text_value)))
			if Icons.texture(clip)!=null:
				var illustrated:=HBoxContainer.new()
				illustrated.add_theme_constant_override("separation",14)
				group.add_child(illustrated)
				illustrated.add_child(_icon(clip,48))
				illustrated.add_child(body)
			else:group.add_child(body)
		if section.has("tower_graph"):
			var graph=load("res://scripts/tower_map_view.gd").new()
			graph.name="FullTowerGraph"
			graph.custom_minimum_size=Vector2(720,420)
			graph.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			group.add_child(graph)
			graph.set_data(section["tower_graph"]["tower"],int(section["tower_graph"]["current"]))
		if section.has("slider"):
			var def:Dictionary=section["slider"]
			var caption:=_label(str(def["label"])+"  %.2f×"%float(def["value"]),17,INK)
			group.add_child(caption)
			var slider:=HSlider.new()
			slider.min_value=float(def["min"]);slider.max_value=float(def["max"]);slider.step=float(def["step"]);slider.value=float(def["value"])
			slider.custom_minimum_size=Vector2(420,32)
			slider.focus_mode=Control.FOCUS_ALL
			group.add_child(slider)
			slider.value_changed.connect(func(value:float)->void:caption.text=str(def["label"])+"  %.2f×"%value;action_requested.emit(str(def["action"]),value))
		var button_defs: Array = section.get("buttons", [])
		if not button_defs.is_empty():
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 7)
			flow.add_theme_constant_override("v_separation", 7)
			group.add_child(flow)
			for raw_button: Variant in button_defs:
				var def: Dictionary = raw_button as Dictionary
				var b := _button(str(def.get("label", "選擇")), str(def.get("action", "")), def.get("payload", null))
				b.disabled = bool(def.get("disabled", false))
				b.custom_minimum_size.y = 38
				flow.add_child(b)
	overlay.visible = true
	touch_controls.visible = false
	_focus_index=0
	call_deferred("focus_first")


func update_shortcuts(names:Dictionary) -> void:
	prep_button.text="安全屋 "+str(names.get("up","↑"))
	for action in shortcut_buttons:
		shortcut_buttons[action].text={"bag":"裝備","runes":"符文","settings":"選單"}[action]+" "+str(names.get("interact" if action=="bag" else action,""))
	minimap_button.text=str(names.get("map","Tab"))+" 切換地圖"
	legend_label.text="移動 %s %s %s %s    跳 %s    攻擊 %s    衝刺 %s ×2    副武器 %s    回血 %s    地圖 %s"%[names.get("up","↑"),names.get("down","↓"),names.get("left","←"),names.get("right","→"),names.get("jump","Space"),names.get("attack","X"),names.get("dash","C"),names.get("sub","Z"),names.get("heal","A"),names.get("map","Tab")]


func _inventory_nav(active:String) -> void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	panel_rows.add_child(row)
	for entry:Array in [["行囊","bag"],["符文盤","runes"],["技能樹","skills"],["全塔地圖","map"]]:
		var button:=_button(str(entry[0]),str(entry[1]),null)
		button.disabled=active==str(entry[1])
		button.custom_minimum_size=Vector2(130,36)
		row.add_child(button)

func _column(parent:Node,width:float=0) -> VBoxContainer:
	var column:=VBoxContainer.new()
	column.custom_minimum_size.x=width
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	parent.add_child(column)
	return column

func _card(parent:Node,title:String,body:String,color:Color,button:Dictionary={},icon:String="") -> void:
	var frame:=PanelContainer.new()
	frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel",_box(Color("1c3732"),color.darkened(.5),12,16))
	parent.add_child(frame)
	var col:=_column(frame)
	var heading:=HBoxContainer.new()
	heading.add_theme_constant_override("separation",12)
	col.add_child(heading)
	var clip:String=icon if not icon.is_empty() else Icons.by_text(title)
	if Icons.texture(clip)!=null:heading.add_child(_icon(clip,46))
	var caption:=_label(title,18,color)
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_child(caption)
	var detail:=_label(body,14,MUTED)
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(detail)
	if not button.is_empty():
		var b:=_button(str(button.get("label","選擇")),str(button.get("action","")),button.get("payload",null))
		b.disabled=bool(button.get("disabled",false))
		col.add_child(b)

func show_inventory(data:Dictionary) -> void:
	Inventory.build(self,data,"weapons")
func show_rune_board(data:Dictionary) -> void:
	Inventory.build(self,data,"runes")
func inspect_item(title:String,description:String,icon:String) -> void:
	if inspector==null:return
	inspect_title.text=title;inspect_body.text=description;inspect_art.texture=Icons.texture(icon);inspect_art.visible=inspect_art.texture!=null
func bind_description(control:Control,title:String,description:String,icon:String) -> void:
	control.set_meta("item_title",title);control.set_meta("item_description",description)
	control.focus_entered.connect(inspect_item.bind(title,description,icon))
	control.mouse_entered.connect(inspect_item.bind(title,description,icon))

func _icon(clip:String,extent:float) -> TextureRect:
	var image:=TextureRect.new()
	image.name="Art_"+clip
	image.texture=Icons.texture(clip)
	image.custom_minimum_size=Vector2.ONE*extent
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	return image

func _rune_button_art(button:Button,clip:String,title:String,number:String="") -> void:
	if Icons.texture(clip)==null:return
	button.text=""
	var contents:=VBoxContainer.new()
	contents.name="DeliveredRuneArt"
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left=4;contents.offset_right=-4;contents.offset_top=4;contents.offset_bottom=-4
	contents.mouse_filter=Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation",1)
	button.add_child(contents)
	if not number.is_empty():
		var count:=_label(number,10,MUTED);count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;contents.add_child(count)
	var art:=_icon(clip,32);art.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;contents.add_child(art)
	var caption:=_label(title,11,INK);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;contents.add_child(caption)



func close_panel() -> void:
	if not is_instance_valid(overlay):
		return
	overlay.visible = false
	touch_controls.visible = _touch_enabled


func is_panel_open() -> bool:
	return is_instance_valid(overlay) and overlay.visible


func set_touch_visible(enabled: bool) -> void:
	_touch_enabled = enabled
	if is_instance_valid(touch_controls):
		touch_controls.visible = enabled and not is_panel_open()
	if is_instance_valid(legend_label):
		legend_label.visible = not enabled


func show_message(text: String) -> void:
	setup()
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0
	_message_timer = 3.6


func reject_attack(reason:String) -> void:
	if _feedback_cooldown>0 and reason==attack_feedback_reason:return
	attack_feedback_reason=reason;attack_feedback_timer=.8;_feedback_cooldown=.25
	if reason=="energy":show_message("能量不足：每次副武器消耗 1 格，近戰命中可回能")
	elif reason=="no_weapon":show_message("先拾取安全屋的免費副武器")

func clear_attack_feedback() -> void:
	attack_feedback_reason="";attack_feedback_timer=0;_feedback_cooldown=0

func _process(delta: float) -> void:
	_feedback_cooldown=maxf(0,_feedback_cooldown-delta)
	attack_feedback_timer=maxf(0,attack_feedback_timer-delta)
	var pulse:bool=attack_feedback_timer>0 and attack_feedback_reason=="energy"
	var tint:Color=Color("ffb482") if pulse and fmod(.8-attack_feedback_timer,.24)<.14 else Color.WHITE
	energy_label.modulate=tint;energy_cells.modulate=tint
	if _message_timer > 0.0:
		_message_timer = maxf(0.0, _message_timer - delta)
		message_label.modulate.a = minf(1.0, _message_timer / 0.4)
		if _message_timer <= 0.0:
			message_label.visible = false


func _dispatch(action: String, payload: Variant) -> void:
	var focused:Control=get_viewport().gui_get_focus_owner()
	if focused!=null:
		inventory_focus_key=str(focused.get_meta("inventory_focus",""))
		if focused.has_meta("station_key"):station_focus_key=str(focused.get_meta("station_key"))
	if action == "close":
		close_panel()
	action_requested.emit(action, payload)


func _button(text: String, action: String, payload: Variant) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", Color("657a71"))
	b.add_theme_stylebox_override("normal", _box(Color("203c37"), LINE, 9, 10))
	b.add_theme_stylebox_override("hover", _box(Color("304f43"), MINT, 9, 10))
	b.add_theme_stylebox_override("pressed", _box(Color("40654f"), MINT, 9, 10))
	b.add_theme_stylebox_override("focus", _box(Color(0,0,0,0), GOLD, 9, 10))
	b.add_theme_stylebox_override("disabled", _box(Color("192f2d"), Color("2a403a"), 9, 10))
	if not action.is_empty():b.pressed.connect(_dispatch.bind(action, payload))
	return b


func _touch_button(text: String, action: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(70, 62)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_stylebox_override("normal", _box(Color(PAPER, 0.82), Color(MINT, 0.65), 24, 8))
	b.add_theme_stylebox_override("pressed", _box(Color("b5d9c5"), MINT, 24, 8))
	b.button_down.connect(func() -> void: touch_action.emit(action, true))
	b.button_up.connect(func() -> void: touch_action.emit(action, false))
	return b


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _bar(color: Color, minimum: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = minimum
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _box(Color("344d44"), Color.TRANSPARENT, 8, 0))
	bar.add_theme_stylebox_override("fill", _box(color, Color.TRANSPARENT, 8, 0))
	return bar


func _box(background: Color, border: Color, radius: int, padding: int) -> StyleBox:
	if border.a>0 and background.a>0 and padding<=12:
		var illustrated:=StyleBoxTexture.new()
		illustrated.texture=preload("res://assets/v55/ui/etched_slot.svg")
		illustrated.modulate_color=Color(.72+background.r*.7,.72+background.g*.7,.72+background.b*.7,background.a)
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
			illustrated.set_texture_margin(side,23)
			illustrated.set_content_margin(side,padding)
		return illustrated
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0.0 else 0)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


func _number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return "%.1f" % value

func _navigable(node:Node,out:Array[Control]) -> void:
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree() and not child.disabled:out.append(child)
		elif child is HSlider and child.is_visible_in_tree():out.append(child)
		_navigable(child,out)

func focus_first() -> void:
	if not is_panel_open():return
	if inventory_page=="equipment_v25":equipment_navigation.focus_first(self);return
	if inventory_page=="station_v26":preload("res://scripts/station_navigation_v26.gd").focus_first(self);return
	var controls:Array[Control]=[];_navigable(panel_rows,controls)
	if controls.is_empty():_navigable(overlay,controls)
	if not inventory_page.is_empty() and not inventory_focus_key.is_empty():
		for control in controls:
			if str(control.get_meta("inventory_focus",""))==inventory_focus_key:control.grab_focus();return
	if not controls.is_empty():controls[clampi(_focus_index,0,controls.size()-1)].grab_focus()

func navigate(action:String) -> bool:
	if not is_panel_open():return false
	if inventory_page=="equipment_v25":return equipment_navigation.navigate(self,action)
	if inventory_page=="station_v26":return preload("res://scripts/station_navigation_v26.gd").navigate(self,action)
	var controls:Array[Control]=[];_navigable(panel_rows,controls)
	# Include Close after content, keeping reward/merchant choices first.
	var all:Array[Control]=[];_navigable(overlay,all)
	for control in all:
		if control not in controls:controls.append(control)
	if controls.is_empty():return true
	var current:Control=get_viewport().gui_get_focus_owner()
	var index:int=controls.find(current)
	if index<0:index=0
	if action in ["attack","interact"]:
		var chosen:Control=controls[index]
		if chosen is Button:chosen.pressed.emit()
		return true
	if action in ["up","down","left","right"]:
		if current is HSlider and action in ["left","right"]:
			current.value+=current.step*(-1 if action=="left" else 1);return true
		var next_index:int=-1
		if not inventory_page.is_empty() and current!=null:
			var direction:Vector2={"left":Vector2.LEFT,"right":Vector2.RIGHT,"up":Vector2.UP,"down":Vector2.DOWN}[action]
			var origin:Vector2=current.get_global_rect().get_center();var best:float=INF
			for candidate in controls.size():
				if controls[candidate]==current:continue
				var offset:Vector2=controls[candidate].get_global_rect().get_center()-origin
				var ahead:float=offset.dot(direction)
				if ahead<5:continue
				var score:float=ahead+absf(offset.dot(direction.orthogonal()))*3
				if score<best:best=score;next_index=candidate
		index=next_index if next_index>=0 else posmod(index+(-1 if action in ["left","up"] else 1),controls.size())
		_focus_index=index;controls[index].grab_focus()
		var scroll:Node=controls[index].get_parent()
		while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
		if scroll is ScrollContainer:scroll.ensure_control_visible(controls[index])
		return true
	return false

func update_quickbar(items:Dictionary,definitions:Array) -> void:
	var counts:PackedStringArray=[]
	for i in mini(5,definitions.size()):counts.append(str(items.get(str(i),0)))
	var signature:String=",".join(counts)
	if signature==_quickbar_signature:return
	_quickbar_signature=signature;quickbar_rebuilds+=1
	for child in quickbar.get_children():quickbar.remove_child(child);child.queue_free()
	for i in mini(5,definitions.size()):
		var count:int=int(items.get(str(i),0))
		var b:=_button("%d   ×%d"%[i+1,count],"hot_item",i)
		var id:String=definitions[i]["id"]
		b.icon=Icons.texture("items_"+id)
		b.expand_icon=true;b.tooltip_text=definitions[i]["name"]
		b.focus_mode=Control.FOCUS_NONE;b.add_theme_font_size_override("font_size",11);b.custom_minimum_size=Vector2(78,42);b.disabled=count<=0
		quickbar.add_child(b)

func update_trial(trial:Dictionary,stock:Array,coins:int) -> void:
	if trial.is_empty():
		if trial_panel!=null:trial_panel.visible=false
		_trial_signature="";return
	var index:int=int(trial.get("index",-1))
	if index<0 or index>=stock.size():return
	if trial_panel==null:
		trial_panel=PanelContainer.new();trial_panel.name="MerchantTrialBanner";trial_panel.position=Vector2(829,370);trial_panel.custom_minimum_size=Vector2(405,72);trial_panel.add_theme_stylebox_override("panel",_box(Color("183b32"),GOLD,12,10));ui_root.add_child(trial_panel)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",4);trial_panel.add_child(column)
		trial_caption=_label("",14,GOLD);column.add_child(trial_caption)
		var buttons:=HBoxContainer.new();buttons.add_theme_constant_override("separation",10);column.add_child(buttons)
		trial_buy=_button("買下商品","trial_buy",null);trial_buy.focus_mode=Control.FOCUS_NONE;buttons.add_child(trial_buy)
		trial_return=_button("歸還試用品","merchant_return",null);trial_return.focus_mode=Control.FOCUS_NONE;buttons.add_child(trial_return)
	trial_panel.visible=true
	var signature:String=str(trial.get("room",-1))+":"+str(index)+":"+str(coins)
	if signature==_trial_signature:return
	_trial_signature=signature
	var item:Dictionary=stock[index]
	var definition:Dictionary=Icons.Data.SECONDARY[int(item["value"])] if item["kind"]=="weapon" else Icons.Data.all_runes()[int(item["value"])]
	trial_caption.text="免費試用 · "+str(definition["name"])+" · 能量補充中"
	trial_buy.text="買下 %d 金幣"%int(item["price"]);trial_buy.disabled=coins<int(item["price"])
