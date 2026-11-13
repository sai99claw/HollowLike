class_name MenuViewV27
extends RefCounted
const Station=preload("res://scripts/station_view_v26.gd")
static func build(ui,game,category:String) -> void:
	if ui.station_page!="settings":ui.station_focus_key="";ui.station_selection=""
	var body:HBoxContainer=Station._begin(ui,"冒險選單  /  羽旅手冊","settings")
	var left:VBoxContainer=Station._pane(ui,body,240);var right:VBoxContainer=Station._pane(ui,body,650)
	Station._text(ui,left,"功能分類",22,ui.GOLD)
	for entry:Array in [["adventure","冒險與進度"],["controls","操作與鏡頭"],["display","畫面與聲音"],["practice","練習與檢查"]]:
		var button:Button=Station._button(ui,left,entry[1],"menu_category",entry[0],"settings:category:"+str(entry[0]))
		if entry[0]==category:button.add_theme_stylebox_override("normal",ui._box(Color("36574b"),ui.GOLD,9,10))
	Station._button(ui,left,"意見反饋","feedback",null,"settings:feedback")
	Station._button(ui,left,"繼續冒險","close",null,"settings:resume")
	Station._text(ui,left,"方向鍵選擇 · X確認\nEsc關閉選單",13)
	match category:
		"controls":
			Station._text(ui,right,"操作與鏡頭",22,ui.GOLD)
			_slider(ui,right,"全域移動速度","speed",.4,1.5,.05,game.world_speed)
			_slider(ui,right,"鏡頭縮放","zoom",.8,2,.05,game.camera_zoom)
			Station._button(ui,right,"自訂鍵位","keybindings",null,"settings:keybindings")
			Station._button(ui,right,"虛擬搖桿與按鈕："+("顯示" if game.touch_enabled else "隱藏"),"touch",null,"settings:touch")
			Station._text(ui,right,"左下：虛擬搖桿（向上使用站點）\n右下：副武器／主武器；衝／跳躍\n右上：按住回血。按鈕固定於實際螢幕邊緣。",14)
			Station._button(ui,right,"操作說明","help",null,"settings:help")
		"display":
			Station._text(ui,right,"畫面與聲音",22,ui.GOLD)
			Station._button(ui,right,"放大填滿"+(" ✓" if game.display_fit=="cover" else ""),"display_fit","cover","settings:cover")
			Station._button(ui,right,"縮小完整"+(" ✓" if game.display_fit=="contain" else ""),"display_fit","contain","settings:contain")
			if game.display_fit=="cover":_display_zoom(ui,right,game.display_zoom,game.DISPLAY_ZOOM_MAX)
			Station._button(ui,right,"特效量："+("精簡" if game.low_effects else "標準"),"effects",null,"settings:effects")
			Station._button(ui,right,"音樂與音效："+("開" if game.audio_enabled else "關"),"audio",null,"settings:audio")
			_slider(ui,right,"背景音量","background_volume",0,1,.05,game.background_volume,"%d%%",100)
			_slider(ui,right,"特效音量","sfx_volume",0,1,.05,game.sfx_volume,"%d%%",100)
			Station._text(ui,right,"精簡模式保留投射物軌跡、命中回饋與地面燃燒。",15)
		"practice":
			Station._text(ui,right,"練習與檢查",22,ui.GOLD)
			if OS.has_feature("web"):Station._button(ui,right,"效能紀錄","performance_panel",null,"settings:perf")
			if game.screen=="hub":
				Station._button(ui,right,"進入練習房","lab_enter",null,"settings:enter_practice")
				Station._button(ui,right,"開發工具","developer_tools",null,"settings:developer_tools")
			Station._button(ui,right,"練習模式："+("全部技能可用" if game.practice_mode else "依進度解鎖"),"practice",null,"settings:practice")
			Station._button(ui,right,"判定框與彈道預警："+("開" if game.show_hitboxes else "關"),"hitboxes",null,"settings:hitboxes")
			Station._button(ui,right,"攻擊階段："+("慢速觀察" if game.phase_multiplier>1.2 else "正常速度"),"timing_slower",null,"settings:timing")
		_:
			Station._text(ui,right,"冒險與進度",22,ui.GOLD)
			var links:=HBoxContainer.new();links.add_theme_constant_override("separation",8);right.add_child(links)
			for entry:Array in [["裝備","bag"],["符文","runes"],["技能樹","skills"],["全塔地圖","map"],["造型工坊","shop"]]:Station._button(ui,links,entry[0],entry[1],null,"settings:"+str(entry[1]))
			if game.lab_mode=="tutorial":
				Station._button(ui,right,"教學與武器","tutorial_guide",null,"settings:tutorial")
				Station._button(ui,right,"返回鳥巢","hub",null,"settings:hub")
				ui.call_deferred("focus_first")
				return
			Station._text(ui,right,"開始新冒險",18,ui.MINT);Station._text(ui,right,"以下選擇會重置本次局內進度，永久收藏保留。",14)
			Station._button(ui,right,"無雙夢境 · 轉頭起飛鴿子","start_musou",null,"settings:musou")
			Station._button(ui,right,"Roguelike · 戰士鴿子","start_rogue",null,"settings:rogue")
			Station._button(ui,right,"回鳥巢（結束本次）","hub",null,"settings:hub")
	ui.call_deferred("focus_first")
static func _slider(ui,parent:Node,title:String,action:String,min_value:float,max_value:float,step:float,value:float,format:String="%.2f×",display_scale:float=1.0) -> void:
	var caption:Label=Station._text(ui,parent,title+" "+format%(value*display_scale),17,ui.INK)
	var slider:=HSlider.new();slider.min_value=min_value;slider.max_value=max_value;slider.step=step;slider.value=value;slider.custom_minimum_size.y=35;slider.set_meta("station_key","settings:"+action);parent.add_child(slider)
	slider.value_changed.connect(func(next:float)->void:caption.text=title+" "+format%(next*display_scale);ui.action_requested.emit(action,next))


static func _display_zoom(ui,parent:Node,value:float,max_value:float) -> void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	parent.add_child(row)
	Station._text(ui,row,"填滿縮放 Zoom",17,ui.INK)
	var input:=LineEdit.new()
	input.name="DisplayZoomInput"
	input.custom_minimum_size=Vector2(94,38)
	input.alignment=HORIZONTAL_ALIGNMENT_CENTER
	input.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	input.set_meta("station_key","settings:display_zoom_input")
	input.text="%.2f"%value
	row.add_child(input)
	Station._text(ui,row,"×",17,ui.INK)
	var apply:Button=Station._button(ui,row,"套用","","","settings:display_zoom_apply")
	var hint:Label=Station._text(ui,parent,"等比例置中裁切，可輸入 1.00～%.2f。"%max_value,14)
	var submit:Callable=func(raw:String)->void:
		var number:String=raw.strip_edges()
		var zoom:float=number.to_float()
		if not number.is_valid_float() or not is_finite(zoom) or zoom<1.0 or zoom>max_value:
			hint.text="請輸入 1.00～%.2f 的數字。"%max_value
			return
		var next:float=snappedf(zoom,.01)
		input.text="%.2f"%next
		hint.text="已套用 %.2f×"%next
		ui.action_requested.emit("display_zoom",next)
		apply.grab_focus()
	input.text_submitted.connect(submit)
	apply.pressed.connect(func()->void:submit.call(input.text))
