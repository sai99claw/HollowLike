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
var coins_label: Label
var health_art:TextureRect
var energy_art:TextureRect
var injury_art:TextureRect
var phase_art:TextureRect
var phase_bar: ProgressBar
var dream_row:HBoxContainer
var dream_label:Label
var dream_cells:Array[ColorRect]=[]
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
var edge_tools:HBoxContainer
var quickbar:HBoxContainer
var _focus_index:int=0
var mute_button:Button
var health_background:TextureRect
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
		var readable_font:=FontVariation.new()
		readable_font.base_font=load("res://assets/Chinese.otf") as Font
		readable_font.fallbacks=[ThemeDB.fallback_font]
		theme_value.default_font=readable_font
	ui_root.theme = theme_value
	_build_header()
	_build_messages()
	_build_panel()
	_build_touch()
	set_touch_visible(OS.has_feature("mobile"))


func set_safe_rect(safe:Rect2) -> void:
	var logical:=Vector2(1280,720)
	var factor:float=minf(safe.size.x/logical.x,safe.size.y/logical.y)
	ui_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ui_root.position=safe.position
	ui_root.scale=Vector2.ONE*factor
	ui_root.size=safe.size/factor
	var extra:Vector2=ui_root.size-logical
	edge_tools.position=Vector2(ui_root.size.x-edge_tools.get_combined_minimum_size().x-20,13)
	quickbar.position=Vector2(20,642+extra.y)

func _build_header() -> void:
	health_background=TextureRect.new()
	health_background.name="HealthBackdrop"
	health_background.texture=preload("res://assets/v75/canopy-left.webp")
	health_background.position=Vector2(0,0)
	health_background.size=Vector2(270,92)
	health_background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	health_background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(health_background)
	header = PanelContainer.new()
	header.name = "CompactVitals"
	header.position = Vector2(20,16)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	ui_root.add_child(header)
	var main := VBoxContainer.new()
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_theme_constant_override("separation",4)
	header.add_child(main)

	var vitals := HBoxContainer.new()
	vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitals.add_theme_constant_override("separation",6)
	main.add_child(vitals)
	health_art=_icon("strong_heartplus",20)
	health_art.mouse_filter=Control.MOUSE_FILTER_PASS
	vitals.add_child(health_art)
	health_cells=Cells.new()
	health_cells.name="HealthCells"
	health_cells.filled_color=Color("e8a18c")
	vitals.add_child(health_cells)
	energy_art=_icon("items_energy",20)
	energy_art.mouse_filter=Control.MOUSE_FILTER_PASS
	vitals.add_child(energy_art)
	energy_cells=Cells.new()
	energy_cells.name="EnergyCells"
	energy_cells.filled_color=MINT
	vitals.add_child(energy_cells)
	coin_art=_icon("coin",20)
	coin_art.mouse_filter=Control.MOUSE_FILTER_PASS
	vitals.add_child(coin_art)
	coins_label=_label("0",13,GOLD)
	vitals.add_child(coins_label)

	var equipment_row:=HBoxContainer.new()
	equipment_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	equipment_row.add_theme_constant_override("separation",6)
	main.add_child(equipment_row)
	primary_art=_icon("weapon_feather",24)
	primary_art.mouse_filter=Control.MOUSE_FILTER_PASS
	equipment_row.add_child(primary_art)
	var secondary_row:=HBoxContainer.new()
	secondary_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	equipment_row.add_child(secondary_row)
	secondary_art=_icon("",24)
	secondary_art.mouse_filter=Control.MOUSE_FILTER_PASS
	secondary_row.add_child(secondary_art)
	secondary_label=_label("",13,MINT)
	secondary_row.add_child(secondary_label)
	injury_art=_icon("items_heal",20)
	injury_art.mouse_filter=Control.MOUSE_FILTER_PASS
	injury_art.tooltip_text="重傷 · 回安全屋急救"
	injury_art.modulate=Color("ffb482")
	equipment_row.add_child(injury_art)
	var phase_row:=HBoxContainer.new()
	phase_row.name="AttackReadiness"
	phase_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	equipment_row.add_child(phase_row)
	phase_art=_icon("strong_swiftblade",18)
	phase_art.mouse_filter=Control.MOUSE_FILTER_PASS
	phase_row.add_child(phase_art)
	phase_bar=_bar(MINT,Vector2(44,4))
	phase_bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	phase_row.add_child(phase_bar)

	dream_row=HBoxContainer.new()
	dream_row.name="DreamEnergy"
	dream_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	dream_row.visible=false
	main.add_child(dream_row)
	var dream_art:=_icon("strong_motion_energy",18)
	dream_art.mouse_filter=Control.MOUSE_FILTER_PASS
	dream_art.tooltip_text="無雙能量"
	dream_row.add_child(dream_art)
	var cells:=HBoxContainer.new()
	cells.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cells.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	cells.add_theme_constant_override("separation",3)
	dream_row.add_child(cells)
	for i in 20:
		var cell:=ColorRect.new()
		cell.custom_minimum_size=Vector2(7,6)
		cell.mouse_filter=Control.MOUSE_FILTER_IGNORE
		cells.add_child(cell)
		dream_cells.append(cell)
	dream_label=_label("",12,GOLD)
	dream_row.add_child(dream_label)
	var tools := HBoxContainer.new()
	edge_tools=tools
	tools.position = Vector2(1186,13)
	tools.add_theme_constant_override("separation",6)
	ui_root.add_child(tools)
	mute_button=_tool_button("mute","靜音",preload("res://assets/v75/audio-on.svg"))
	mute_button.name="TopMuteButton"
	shortcut_buttons["settings"]=_tool_button("settings","暫停選單 · Esc",preload("res://assets/v75/pause-menu.svg"))
	prep_button = _button("安全屋 ↑","prep",null)
	prep_button.focus_mode=Control.FOCUS_NONE
	prep_button.position = Vector2(20,190)
	prep_button.visible = false
	ui_root.add_child(prep_button)

	quickbar=HBoxContainer.new();quickbar.position=Vector2(20,642);quickbar.add_theme_constant_override("separation",6);ui_root.add_child(quickbar)


func _tool_button(action:String,tip:String,art:Texture2D) -> Button:
	var button:=_button("",action,null)
	button.focus_mode=Control.FOCUS_NONE
	button.flat=true
	button.tooltip_text=tip
	button.icon=art
	button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size=Vector2(34,34)
	edge_tools.add_child(button)
	return button


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
	legend_label = _label("移動 方向鍵    跳躍 Space    攻擊 X    衝刺 C ×2    副武器 Z    回血 A    地圖 按住 Tab ／ M", 12, INK)
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
	health_art.tooltip_text="生命 %d / %d" % [hp,max_hp]
	energy_art.tooltip_text="能量 %d / %d" % [energy,max_energy]
	health_cells.set_state(hp,max_hp,float(info.get("hp_recovery",0)),bool(info.get("hp_recovering",false)))
	energy_cells.set_state(energy,max_energy,float(info.get("energy_recovery",0)),bool(info.get("energy_recovering",false)))
	coins_label.text=str(info.get("coins",0))
	coin_art.tooltip_text="金幣"
	primary_art.tooltip_text=str(info.get("weapon",""))
	for weapon in Icons.Data.PRIMARY:
		if str(weapon["name"])==primary_art.tooltip_text:
			primary_art.texture=Icons.texture(Icons.primary(weapon))
			break
	var mode_value:String=str(info.get("mode",""))
	var home:bool=mode_value in ["","hub","鳥巢"]
	dream_row.visible=mode_value in ["musou","無雙","無雙夢境"]
	if dream_row.visible:
		var amount:int=clampi(int(info.get("dream_energy",0)),0,20)
		var rage_left:float=float(info.get("dream_rage",0))
		dream_label.visible=rage_left>0
		dream_label.text="×2  %ds"%ceili(rage_left) if rage_left>0 else ""
		for i in dream_cells.size():dream_cells[i].color=GOLD if i<amount else Color("30434e")
	for control:Control in [health_background,health_art,energy_art,health_cells,energy_cells]:control.visible=not home
	primary_art.get_parent().visible=not home
	injury_art.visible=not home and bool(info.get("injured",false))
	var sub_count:int=int(info.get("sub_count",0))
	secondary_art.texture=Icons.texture(str(info.get("sub_icon","")))
	secondary_art.tooltip_text="%s · %s 切換"%[str(info.get("sub","")),str(info.get("cycle_key","Q"))]
	secondary_art.get_parent().visible=not home and secondary_art.texture!=null
	secondary_label.text="×%d"%sub_count
	var audio_on:bool=bool(info.get("audio_enabled",true))
	mute_button.icon=preload("res://assets/v75/audio-on.svg") if audio_on else preload("res://assets/v75/audio-off.svg")
	mute_button.tooltip_text="靜音" if audio_on else "開啟聲音"
	var phase:String=str(info.get("phase","idle"))
	var remaining:float=float(info.get("phase_remaining",0))
	var ready:bool=phase=="idle"
	if ready and attack_feedback_reason in ["busy","locked"]:clear_attack_feedback()
	phase_art.get_parent().visible=bool(info.get("show_attack",false))
	var phases:Dictionary={"idle":"可出擊","windup":"前搖","active":"攻擊中","recovery":"後搖"}
	var phase_tip:String=str(phases.get(phase,phase))
	if not ready:phase_tip+=" %.1f 秒"%remaining
	if phase=="recovery":phase_tip+=" · %s 可取消"%str(info.get("dash_key","C"))
	if attack_feedback_timer>0:
		match attack_feedback_reason:
			"energy":phase_tip="能量不足 · 近戰命中回能"
			"no_weapon":phase_tip="尚未裝備副武器"
			"hurt":phase_tip="受傷硬直中"
			"busy","locked":phase_tip="尚未就緒 · "+phase_tip if not ready else "技能施放中"
	phase_art.tooltip_text=phase_tip
	phase_bar.value=100 if ready else clampf(float(info.get("phase_progress",0)),0,1)*100
	var phase_color:Color=MINT if ready or phase=="active" else GOLD
	phase_bar.modulate=Color("ffb482") if attack_feedback_timer>0 else phase_color
	phase_art.modulate=phase_bar.modulate
	header.reset_size()
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
	shortcut_buttons["settings"].tooltip_text="暫停選單 · "+str(names.get("settings","Esc"))
	legend_label.text="移動 %s %s %s %s    跳 %s    攻擊 %s    衝刺 %s ×2    副武器 %s    回血 %s    地圖 按住 %s ／ M"%[names.get("up","↑"),names.get("down","↓"),names.get("left","←"),names.get("right","→"),names.get("jump","Space"),names.get("attack","X"),names.get("dash","C"),names.get("sub","Z"),names.get("heal","A"),names.get("map","Tab")]


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

func show_tutorial_items(instructions:String,entries:Array[Dictionary],runes:bool) -> void:
	var body:=HBoxContainer.new()
	body.add_theme_constant_override("separation",22)
	panel_rows.add_child(body)
	var left:=_column(body,350)
	_card(left,"領取方式" if runes else "試用方式",instructions,MINT)
	if runes:left.add_child(_button("開啟符文盤","runes",false))
	var right:=_column(body,440)
	right.add_child(_label("可領取的符文" if runes else "可試用的附武器",18,INK))
	var list:=Inventory._list(self,right)
	for item in entries:
		Inventory._tile(self,list,item["name"],item["detail"],item["icon"],item["action"],item["payload"],item["color"],item.get("selected",false))
	inspector.visible=true
	inspect_item(entries[0]["name"],entries[0]["detail"],entries[0]["icon"])

func show_tutorial_lessons(lessons:Array[Dictionary],weapon_id:String,instructions:String) -> void:
	var body:=HBoxContainer.new()
	body.add_theme_constant_override("separation",22)
	panel_rows.add_child(body)
	var left:=_column(body,370)
	left.add_child(_label("操作說明",18,INK))
	var intro:=_label(instructions,14,MUTED)
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	left.add_child(intro)
	var list:=Inventory._list(self,left)
	var right:=_column(body,415)
	var heading:=_label("動畫展示",19,INK)
	right.add_child(heading)
	var preview=preload("res://scripts/tutorial_motion_preview.gd").new()
	preview.name="TutorialMotionPreview"
	right.add_child(preview)
	var timing:=_label("",22,GOLD)
	timing.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(timing)
	preview.timing=timing
	preview.weapon_id=weapon_id
	var try_action:=_button("關閉後在場內演示","",null)
	right.add_child(try_action)
	try_action.pressed.connect(func()->void:action_requested.emit("tutorial_demo",preview.lesson["id"]))
	for lesson in lessons:
		var button:=_button(lesson["name"],"",null)
		list.add_child(button)
		var description:=_label(lesson["detail"],14,MUTED)
		description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		list.add_child(description)
		button.pressed.connect(func()->void:
			heading.text="動畫展示  ·  "+str(lesson["name"])
			preview.select_lesson(lesson))
	preview.select_lesson(lessons[0])
	heading.text="動畫展示  ·  "+str(lessons[0]["name"])

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
	energy_art.modulate=tint;energy_cells.modulate=tint
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
	style_button(b)
	if not action.is_empty():b.pressed.connect(_dispatch.bind(action, payload))
	return b


func style_button(button:Button,accent:Color=MINT,padding:int=10) -> void:
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal",_button_face(Color("203c37"),accent.darkened(.42),padding,0))
	button.add_theme_stylebox_override("hover",_button_face(Color("34584a"),accent,padding,0))
	button.add_theme_stylebox_override("pressed",_button_face(Color("132a24"),accent.lightened(.18),padding,3))
	var focus:=StyleBoxFlat.new()
	focus.bg_color=Color.TRANSPARENT
	focus.border_color=GOLD
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(9)
	button.add_theme_stylebox_override("focus",focus)
	button.add_theme_stylebox_override("disabled",_button_face(Color("192f2d"),Color("2a403a"),padding,0,false))

func _button_face(fill:Color,edge:Color,padding:int,depth:int,raised:bool=true) -> StyleBoxFlat:
	var face:=StyleBoxFlat.new()
	face.bg_color=fill
	face.border_color=edge
	face.set_corner_radius_all(9)
	face.set_border_width_all(2)
	face.set_content_margin_all(padding)
	face.content_margin_top=padding+depth
	face.content_margin_bottom=padding-depth
	face.shadow_color=Color("#071310b8")
	face.shadow_size=3 if raised and depth==0 else 0
	face.shadow_offset=Vector2(0,4)
	return face

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
		elif (child is HSlider or (child is LineEdit and child.has_meta("station_key"))) and child.is_visible_in_tree():out.append(child)
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
