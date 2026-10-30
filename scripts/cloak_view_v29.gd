class_name CloakViewV29
extends RefCounted
const Station=preload("res://scripts/station_view_v26.gd")
const Cloaks=preload("res://scripts/cloak_art_v29.gd")
static func build(ui,skins:Array,equipped:int) -> void:
	var body:HBoxContainer=Station._begin(ui,"披風換裝站  /  旅行衣櫥","wardrobe")
	var left:VBoxContainer=Station._pane(ui,body,350);var right:VBoxContainer=Station._pane(ui,body,560)
	Station._text(ui,left,"披風收藏 · 五款皆可穿戴",21,ui.GOLD)
	var grid:GridContainer=Station._grid(ui,left,350)
	var art:=preload("res://scripts/cloak_preview_v29.gd").new();art.name="CloakHeroArt";art.custom_minimum_size=Vector2(330,220);right.add_child(art)
	var title:Label=Station._text(ui,right,"",25,ui.GOLD)
	var text:Label=Station._text(ui,right,"",16)
	var wear:Button=Station._button(ui,right,"穿戴披風","buy_skin",equipped,"wardrobe:wear")
	Station._text(ui,right,"只更換披風，主角羽色、身形、碰撞與能力維持原樣。\n↑↓←→ 選擇 · X 穿戴 · Esc 返回",14)
	var select:Callable=func(index:int)->void:
		art.index=index;art.queue_redraw();title.text=skins[index]["name"]
		text.text=["原本的羽色與圍巾，保留最初的旅行模樣。","街頭剪裁、撞色飾邊，讓旅途更有個性。","冷色發光接縫與科技布料。","古典織紋與金色細節，帶著騎士的沉穩。","柔和粉色、蝴蝶結與精緻荷葉邊。"][index]+("\n目前穿戴中。" if index==equipped else "\n可免費更換。")
		wear.disabled=index==equipped;wear.text="穿戴中" if index==equipped else "穿戴這件披風"
		# Recreate the action connection through its actual payload, without stale captures.
		wear.set_meta("cloak_index",index)
	for i in skins.size():
		var button:Button=Station._button(ui,grid,"", "station_noop",null,"wardrobe:item:"+str(i));button.custom_minimum_size=Vector2(100,106)
		var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);button.add_child(column)
		var icon:=TextureRect.new();icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.texture=Cloaks.atlas(i);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(95,70);column.add_child(icon)
		var caption:Label=ui._label(skins[i]["name"],12,ui.GOLD if i==equipped else ui.INK);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(caption)
		button.focus_entered.connect(select.bind(i));button.mouse_entered.connect(select.bind(i));button.pressed.connect(select.bind(i))
	# The standard Station button's connected action carries the selected dynamic index.
	for connection:Dictionary in wear.pressed.get_connections():wear.pressed.disconnect(connection["callable"])
	wear.pressed.connect(func()->void:ui.action_requested.emit("buy_skin",int(wear.get_meta("cloak_index",equipped))))
	select.call(equipped);ui.station_focus_key="wardrobe:item:"+str(equipped);ui.call_deferred("focus_first")
