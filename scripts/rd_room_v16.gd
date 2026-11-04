class_name RDRoomV16
extends Control
## Full-screen, mouse-first atlas/animation inspection. No gameplay state is owned.
signal closed
const Procedural=preload("res://scripts/rd_procedural_v16.gd")
const Catalog=preload("res://scripts/art_catalog_v16.gd")
const PAGE_SIZE:int=24
const GALLERY_PAGE_SIZE:int=12
const INK:=Color("e5eee5")
const MUTED:=Color("9eb8ac")
const GOLD:=Color("e8ce8c")
class Checker:
	extends Control
	func _draw() -> void:
		var edge:int=28
		for y in range(0,int(size.y)+edge,edge):
			for x in range(0,int(size.x)+edge,edge):draw_rect(Rect2(x,y,edge,edge),Color("243331") if (x/edge+y/edge)%2==0 else Color("1b2928"))

var current_entry:Dictionary={}
var frame_index:int=0
var fps:float=12
var playing:bool=true
var entries:Array[Dictionary]=[]
var filtered_entries:Array[Dictionary]=[]
var thumbnail_page:int=0
var _timeline:Array[Dictionary]=[]
var _phase_edits:Dictionary={}
var _phase_id:String="all"
var _elapsed:float=0
var _built:bool=false
var _changing:bool=false
var _preview_frame:int=-1
var _preview_id:String=""
var _thumb_buttons:Array[Button]=[]
var _thumb_indices:Array[int]=[]
var _search:LineEdit
var _kind:OptionButton
var _category:OptionButton
var _list:ItemList
var _filtered_count:Label
var _procedural:Control
var _preview:TextureRect
var _name:Label
var _source:Label
var _notes:RichTextLabel
var _counter:Label
var _scrubber:HSlider
var _fps_control:SpinBox
var _play_button:Button
var _insert_blank:Button
var _toggle_hidden:Button
var _remove_blank:Button
var _reset_preview:Button
var _thumbnail_scroll:ScrollContainer
var _strip:HBoxContainer
var _page_label:Label
var _previous_page:Button
var _next_page:Button
var _phase:OptionButton
var _usage:OptionButton
var _view:OptionButton
var _inspector:Control
var _gallery:Control
var _gallery_grid:GridContainer
var _gallery_page_label:Label
var _gallery_previous:Button
var _gallery_next:Button
var _asset_id:LineEdit
var gallery_page:int=0
var gallery_cards:Array[Dictionary]=[]
var _cache_label:Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	process_mode=Node.PROCESS_MODE_ALWAYS
	var shared:=Theme.new();shared.default_font_size=14
	if ResourceLoader.exists("res://assets/Chinese.otf"):
		shared.default_font=load("res://assets/Chinese.otf") as Font
		for role:String in ["normal_font","bold_font","italics_font","bold_italics_font","mono_font"]:shared.set_font(role,"RichTextLabel",shared.default_font)
	for type:String in ["Label","Button","LineEdit","OptionButton","ItemList","PopupMenu"]:shared.set_color("font_color",type,INK)
	theme=shared
	_build();entries=Catalog.all_entries();_fill_categories();_filter();_built=true
	if not entries.is_empty():select_entry(entries[0])
	set_process(visible)
func setup_ready() -> void:
	# Optional explicit hook for a parent that creates this Control before adding it.
	if is_inside_tree() and not _built:_ready()
func _style(color:Color,border:Color=Color.TRANSPARENT) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new();box.bg_color=color;box.border_color=border
	box.set_border_width_all(1);box.set_corner_radius_all(10)
	box.content_margin_left=12;box.content_margin_right=12;box.content_margin_top=10;box.content_margin_bottom=10
	return box
func _label(text:String,point:int=16,color:Color=INK) -> Label:
	var value:=Label.new();value.text=text;value.add_theme_font_size_override("font_size",point);value.add_theme_color_override("font_color",color);return value
func _button(text:String,callback:Callable,width:float=0) -> Button:
	var value:=Button.new();value.text=text;value.custom_minimum_size=Vector2(width,34)
	value.add_theme_color_override("font_color",INK);value.add_theme_stylebox_override("normal",_style(Color("294a3e"),Color("416553")))
	value.add_theme_stylebox_override("hover",_style(Color("37614d"),GOLD));value.add_theme_stylebox_override("pressed",_style(Color("1c352d"),GOLD))
	value.pressed.connect(callback);return value
func _panel() -> PanelContainer:
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",_style(Color("152a23"),Color("365143")));return panel
func _build() -> void:
	var backing:=ColorRect.new();backing.color=Color("0c1b17");backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backing.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backing)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side:String in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,14)
	add_child(margin)
	var vertical:=VBoxContainer.new();vertical.add_theme_constant_override("separation",12);margin.add_child(vertical)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",14);vertical.add_child(header)
	header.add_child(_label("RD 美術檢視房",25,GOLD));var subtitle:=_label("選素材，調整播放速度，逐格查看動畫",14,MUTED);subtitle.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(subtitle)
	_view=OptionButton.new();_view.name="AssetViewMode";_view.add_item("動畫檢視");_view.add_item("貼圖矩陣");_view.item_selected.connect(func(index:int)->void:set_view("gallery" if index==1 else "inspector"));header.add_child(_view)
	header.add_child(_button("返回鳥巢",_close,120))
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",14);columns.size_flags_vertical=Control.SIZE_EXPAND_FILL;vertical.add_child(columns)
	var library:=_panel();library.custom_minimum_size=Vector2(330,0);columns.add_child(library)
	var left:=VBoxContainer.new();left.add_theme_constant_override("separation",9);library.add_child(left)
	left.add_child(_label("篩選與搜尋",18,GOLD))
	left.add_child(_label("關鍵字（名稱、說明或 ID）",12,MUTED))
	_search=LineEdit.new();_search.name="AssetSearch";_search.placeholder_text="搜尋角色、武器、符文或 ID";_search.custom_minimum_size.y=36;_search.clear_button_enabled=true;_search.text_changed.connect(func(_value:String)->void:_filter());left.add_child(_search)
	left.add_child(_label("素材分類",12,MUTED))
	_category=OptionButton.new();_category.name="AssetCategory";_category.custom_minimum_size.y=32;_category.item_selected.connect(func(_index:int)->void:_filter());left.add_child(_category)
	_kind=OptionButton.new();_kind.name="AssetKindFilter";_kind.custom_minimum_size.y=34;left.add_child(_kind)
	for pair in [["全部：動畫與靜態","all"],["只看動畫／逐幀特效","animated"],["只看靜態插圖／圖示","still"]]:_kind.add_item(pair[0]);_kind.set_item_metadata(_kind.item_count-1,pair[1])
	_kind.get_popup().theme=theme;_kind.item_selected.connect(func(_index:int)->void:_filter())
	_usage=OptionButton.new();_usage.name="AssetUsageFilter";_usage.custom_minimum_size.y=32;left.add_child(_usage)
	for pair in [["使用狀態：全部","all"],["遊戲中已使用","used"],["未使用 · un-used","un-used"]]:_usage.add_item(pair[0]);_usage.set_item_metadata(_usage.item_count-1,pair[1])
	_usage.get_popup().theme=theme;_usage.item_selected.connect(func(_index:int)->void:_filter())
	left.add_child(_button("清除全部條件",clear_filters))
	_filtered_count=_label("",13,MUTED);left.add_child(_filtered_count)
	_list=ItemList.new();_list.name="AssetList";_list.size_flags_vertical=Control.SIZE_EXPAND_FILL;_list.select_mode=ItemList.SELECT_SINGLE;_list.allow_reselect=true;_list.add_theme_font_size_override("font_size",14);_list.add_theme_constant_override("v_separation",7);_list.item_selected.connect(_item_selected);left.add_child(_list)
	_cache_label=_label("圖片按需載入 · 最多快取 24 筆",12,MUTED);left.add_child(_cache_label)
	var right:=VBoxContainer.new();right.add_theme_constant_override("separation",6);right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(right)
	_inspector=right
	var preview_panel:=_panel();preview_panel.custom_minimum_size.y=200;preview_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL;right.add_child(preview_panel)
	var checker:=Checker.new();checker.name="PreviewChecker";checker.mouse_filter=Control.MOUSE_FILTER_IGNORE;preview_panel.add_child(checker)
	_preview=TextureRect.new();_preview.name="AnimationPreview";_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE;checker.add_child(_preview)
	_procedural=Procedural.new();_procedural.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);checker.add_child(_procedural);_procedural.hide()
	var title_row:=HBoxContainer.new();right.add_child(title_row)
	_name=_label("選擇一項素材",18,GOLD);_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_row.add_child(_name)
	_phase=OptionButton.new();_phase.get_popup().theme=theme;_phase.name="AnimationPhase";_phase.custom_minimum_size.x=130;_phase.item_selected.connect(_phase_selected);title_row.add_child(_phase)
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",7);right.add_child(controls)
	_play_button=_button("暫停",_toggle_play,70);_play_button.name="PlayPause";controls.add_child(_play_button)
	controls.add_child(_button("‹",func()->void:pause();seek_frame(frame_index-1),36));controls.add_child(_button("›",func()->void:pause();seek_frame(frame_index+1),36))
	_scrubber=HSlider.new();_scrubber.name="FrameScrubber";_scrubber.step=1;_scrubber.min_value=0;_scrubber.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scrubber.value_changed.connect(func(value:float)->void:if not _changing:pause();seek_frame(int(value)));controls.add_child(_scrubber)
	_counter=_label("0 / 0",14);_counter.custom_minimum_size.x=65;_counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;controls.add_child(_counter)
	controls.add_child(_label("FPS",13,MUTED));_fps_control=SpinBox.new();_fps_control.name="AnimationFPS";_fps_control.min_value=1;_fps_control.max_value=60;_fps_control.step=.1;_fps_control.custom_minimum_size.x=82;_fps_control.value_changed.connect(func(value:float)->void:if not _changing:set_fps(value));controls.add_child(_fps_control)
	var edit_controls:=HBoxContainer.new();right.add_child(edit_controls)
	_insert_blank=_button("後方插入空白幀",insert_blank_frame);edit_controls.add_child(_insert_blank)
	_toggle_hidden=_button("隱藏此幀",toggle_frame_visibility);edit_controls.add_child(_toggle_hidden)
	_remove_blank=_button("移除空白幀",remove_blank_frame);edit_controls.add_child(_remove_blank)
	_reset_preview=_button("還原試播",reset_preview);edit_controls.add_child(_reset_preview)
	edit_controls.add_child(_label("只影響試播",12,MUTED))
	var strip_header:=HBoxContainer.new();right.add_child(strip_header)
	strip_header.add_child(_label("影格順序 · 點選任一格定位",13,MUTED));var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;strip_header.add_child(spacer)
	_previous_page=_button("上一頁",func()->void:_change_page(-1),70);strip_header.add_child(_previous_page)
	_page_label=_label("1 / 1",12,MUTED);_page_label.custom_minimum_size.x=45;_page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;strip_header.add_child(_page_label)
	_next_page=_button("下一頁",func()->void:_change_page(1),70);strip_header.add_child(_next_page)
	_thumbnail_scroll=ScrollContainer.new();_thumbnail_scroll.name="FrameStripScroll";_thumbnail_scroll.custom_minimum_size.y=80;_thumbnail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;_thumbnail_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;right.add_child(_thumbnail_scroll)
	_strip=HBoxContainer.new();_strip.name="ChronologicalFrames";_strip.add_theme_constant_override("separation",5);_thumbnail_scroll.add_child(_strip)
	_source=_label("",12,MUTED);_source.name="SourcePath";_source.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;right.add_child(_source)
	var id_row:=HBoxContainer.new();right.add_child(id_row)
	_asset_id=LineEdit.new();_asset_id.name="CopyableAssetID";_asset_id.editable=false;_asset_id.size_flags_horizontal=Control.SIZE_EXPAND_FILL;id_row.add_child(_asset_id)
	id_row.add_child(_button("複製 ID",func()->void:if not current_entry.is_empty():copy_asset_id(str(current_entry["id"])),95))
	_notes=RichTextLabel.new();_notes.name="AssetNotes";_notes.custom_minimum_size.y=40;_notes.scroll_active=true;_notes.add_theme_font_size_override("normal_font_size",12);_notes.add_theme_color_override("default_color",MUTED);right.add_child(_notes)
	_gallery=VBoxContainer.new();_gallery.name="AssetGalleryView";_gallery.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(_gallery);_gallery.hide()
	_gallery.add_child(_label("全部貼圖 · 首幀預覽",20,GOLD));_gallery.add_child(_label("每頁 12 張，按需載入。點圖檢視動畫；ID 可直接複製。",13,MUTED))
	var gallery_scroll:=ScrollContainer.new();gallery_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;gallery_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_gallery.add_child(gallery_scroll)
	_gallery_grid=GridContainer.new();_gallery_grid.name="AssetGallery";_gallery_grid.columns=4;_gallery_grid.add_theme_constant_override("h_separation",10);_gallery_grid.add_theme_constant_override("v_separation",10);_gallery_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gallery_scroll.add_child(_gallery_grid)
	var pages:=HBoxContainer.new();pages.add_theme_constant_override("separation",15);_gallery.add_child(pages)
	_gallery_previous=_button("上一頁",func()->void:change_gallery_page(-1),110);pages.add_child(_gallery_previous)
	_gallery_page_label=_label("",14,MUTED);_gallery_page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_gallery_page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pages.add_child(_gallery_page_label)
	_gallery_next=_button("下一頁",func()->void:change_gallery_page(1),110);pages.add_child(_gallery_next)
func _fill_categories() -> void:
	_category.clear();_category.get_popup().theme=theme;_category.add_item("全部分類")
	for category:String in Catalog.categories():_category.add_item(category)
func _filter() -> void:
	if _list==null:return
	var selected_category:String="" if _category.selected<=0 else _category.get_item_text(_category.selected)
	var kind:String=str(_kind.get_item_metadata(_kind.selected)) if _kind!=null else "all"
	filtered_entries=Catalog.search(_search.text,selected_category,kind)
	var usage:String=str(_usage.get_item_metadata(_usage.selected)) if _usage!=null else "all"
	if usage!="all":filtered_entries=filtered_entries.filter(func(item:Dictionary)->bool:return item.get("runtime_usage","un-used")==usage)
	_list.clear();gallery_page=0
	for item:Dictionary in filtered_entries:
		_list.add_item(str(item["label"]));_list.set_item_tooltip(_list.item_count-1,str(item["id"])+"\n"+str(item["frame_count"])+" 格 · "+str(item["fps"])+"fps")
	_filtered_count.text="%d / %d 項素材"%[filtered_entries.size(),Catalog.all_entries().size()]
	if _gallery!=null and _gallery.visible:_rebuild_gallery()
	if filtered_entries.is_empty():_clear_selection();return
	for i in filtered_entries.size():
		if filtered_entries[i]["id"]==current_entry.get("id",""):_list.select(i);return
	select_entry(filtered_entries[0])
func clear_filters() -> void:
	_search.text="";_category.select(0);_kind.select(0);_usage.select(0);_filter()
func _clear_selection() -> void:
	pause();current_entry={};_phase_edits.clear();_timeline=[];frame_index=0;_preview_frame=-1;_preview_id=""
	if _preview==null:return
	_preview.texture=null;_procedural.hide();_name.text="沒有符合條件的素材";_source.text="";_asset_id.text="";_notes.text="請換個關鍵字，或按「清除全部條件」。";_counter.text="0 / 0";_play_button.disabled=true
	_update_edit_controls()
	_changing=true;_scrubber.max_value=0;_scrubber.value=0;_changing=false
	for child in _strip.get_children():_strip.remove_child(child);child.queue_free()
	_thumb_buttons.clear();_thumb_indices.clear();_page_label.text="0 / 0";_previous_page.disabled=true;_next_page.disabled=true
func _item_selected(index:int) -> void:
	if index>=0 and index<filtered_entries.size():select_entry(filtered_entries[index])
func select_entry(value:Variant) -> void:
	var item:Dictionary={}
	if value is Dictionary:item=value
	elif value is int:
		var library:Array[Dictionary]=Catalog.all_entries()
		if not library.is_empty():item=library[clampi(int(value),0,library.size()-1)]
	else:item=Catalog.entry(str(value))
	if item.is_empty():return
	current_entry=item;frame_index=0;thumbnail_page=0;_elapsed=0;_preview_frame=-1;_preview_id=""
	_phase_edits.clear();_phase_id="all";_timeline=_original_timeline();fps=clampf(float(item.get("fps",12)),1,60)
	if not _built:return
	_changing=true;_fps_control.value=fps;_phase.clear();_phase.add_item("完整動畫");_phase.set_item_metadata(0,"all")
	for raw in item.get("phases",{}):
		var key:String=str(raw)
		if item["phases"][raw].is_empty():continue
		_phase.add_item({"idle":"完整姿態","break":"破壞動畫","windup":"前搖","active":"出擊","recovery":"後搖","flight":"飛行","arming":"陷阱設置"}.get(key,key));_phase.set_item_metadata(_phase.item_count-1,key)
	_phase.selected=0;_phase.disabled=_phase.item_count<=1
	_name.text=str(item["label"]);_name.tooltip_text=str(item["id"])
	_source.text=str(item["id"])+"  ·  "+str(item["frames"][0].get("path",""));_source.tooltip_text=_source.text
	_asset_id.text=str(item["id"])
	_notes.text=("已使用" if item.get("runtime_usage","")=="used" else "un-used")+" · "+str(item.get("usage_note",""))+"\n"+str(item.get("density_note",""))+"\n"+str(item.get("notes",""));_changing=false
	playing=_timeline.size()>1;_play_button.text="暫停" if playing else "播放"
	_refresh_timeline();_filter_selection()
func _filter_selection() -> void:
	for i in filtered_entries.size():
		if filtered_entries[i]["id"]==current_entry.get("id",""):_list.select(i);_list.ensure_current_is_visible();break
func _phase_selected(index:int) -> void:
	if _changing or current_entry.is_empty():return
	_phase_id=str(_phase.get_item_metadata(index))
	_timeline=_phase_edits.get(_phase_id,_original_timeline())
	seek_frame(0)
	_refresh_timeline()

func _original_timeline() -> Array[Dictionary]:
	var slots:Array[Dictionary]=[]
	for source:int in Catalog.sequence(current_entry,_phase_id):
		slots.append({"source":source,"hidden":false})
	return slots

func insert_blank_frame() -> void:
	if _timeline.is_empty():return
	_timeline.insert(frame_index+1,{"source":-1,"hidden":false})
	frame_index+=1
	_finish_timeline_edit()

func toggle_frame_visibility() -> void:
	if _timeline.is_empty() or int(_timeline[frame_index]["source"])<0:return
	var slot:Dictionary=_timeline[frame_index]
	slot["hidden"]=not slot["hidden"]
	_finish_timeline_edit()

func remove_blank_frame() -> void:
	if _timeline.is_empty() or int(_timeline[frame_index]["source"])>=0:return
	_timeline.remove_at(frame_index)
	frame_index=mini(frame_index,_timeline.size()-1)
	_finish_timeline_edit()

func reset_preview() -> void:
	if _timeline.is_empty():return
	pause()
	_phase_edits.clear()
	_timeline=_original_timeline()
	set_fps(float(current_entry.get("fps",12)))
	frame_index=0
	_refresh_timeline()

func _finish_timeline_edit() -> void:
	pause()
	_phase_edits[_phase_id]=_timeline
	_elapsed=0
	_refresh_timeline()

func _refresh_timeline() -> void:
	_changing=true
	_scrubber.max_value=maxi(0,_timeline.size()-1)
	_changing=false
	_play_button.disabled=_timeline.size()<=1
	if _play_button.disabled:pause()
	thumbnail_page=frame_index/PAGE_SIZE
	_preview_frame=-1
	_rebuild_thumbnails()
	_refresh_preview()

func _update_edit_controls() -> void:
	var empty:bool=_timeline.is_empty()
	var blank:bool=not empty and int(_timeline[frame_index]["source"])<0
	var hidden:bool=not empty and bool(_timeline[frame_index]["hidden"])
	_insert_blank.disabled=empty
	_toggle_hidden.disabled=empty or blank
	_toggle_hidden.text="顯示此幀" if hidden else "隱藏此幀"
	_remove_blank.disabled=not blank
	_reset_preview.disabled=empty

func seek_frame(index:int) -> void:
	if _timeline.is_empty():return
	frame_index=clampi(index,0,_timeline.size()-1);_elapsed=0
	var desired_page:int=frame_index/PAGE_SIZE
	if desired_page!=thumbnail_page:thumbnail_page=desired_page;_rebuild_thumbnails()
	_refresh_preview()
func set_fps(value:float) -> void:
	fps=clampf(value,1,60);_elapsed=0
	if _fps_control!=null:_changing=true;_fps_control.value=fps;_changing=false
func pause() -> void:
	playing=false
	if _play_button!=null:_play_button.text="播放"
func play() -> void:
	if _timeline.size()<=1:return
	playing=true;_elapsed=0
	if _play_button!=null:_play_button.text="暫停"
func _toggle_play() -> void:
	if playing:pause()
	else:play()
func _process(delta:float) -> void:
	if not visible or (_gallery!=null and _gallery.visible) or not playing or _timeline.size()<=1:return
	_elapsed+=delta
	var interval:float=1.0/fps
	if _elapsed<interval:return
	var advance:int=maxi(1,int(_elapsed/interval));_elapsed=fmod(_elapsed,interval)
	frame_index=(frame_index+advance)%_timeline.size()
	var desired_page:int=frame_index/PAGE_SIZE
	if desired_page!=thumbnail_page:thumbnail_page=desired_page;_rebuild_thumbnails()
	_refresh_preview()
func _refresh_preview() -> void:
	if _preview==null or current_entry.is_empty():return
	if _preview_frame==frame_index and _preview_id==current_entry["id"]:return
	var slot:Dictionary=_timeline[frame_index]
	var source:int=slot["source"]
	var shown:bool=source>=0 and not slot["hidden"]
	_procedural.visible=shown and current_entry.get("kind","")=="procedural"
	if _procedural.visible:_procedural.configure(current_entry["id"],source)
	_preview.texture=Catalog.frame(current_entry,source) if shown else null
	_preview_frame=frame_index;_preview_id=current_entry["id"]
	_counter.text="%d / %d"%[frame_index+1,_timeline.size()]
	_update_edit_controls()
	_changing=true;_scrubber.value=frame_index;_changing=false
	_highlight_thumbnails()
	_cache_label.text="按需載入 · 快取 %d / 24 筆"%Catalog.cache_size()
func _highlight_thumbnails() -> void:
	for i in _thumb_buttons.size():_thumb_buttons[i].modulate=Color.WHITE if _thumb_indices[i]==frame_index else Color(.67,.75,.69,1)
func _rebuild_thumbnails() -> void:
	if _strip==null or current_entry.is_empty():return
	for child in _strip.get_children():_strip.remove_child(child);child.queue_free()
	_thumb_buttons.clear();_thumb_indices.clear()
	var count:int=_timeline.size();var pages:int=maxi(1,ceili(float(count)/PAGE_SIZE));thumbnail_page=clampi(thumbnail_page,0,pages-1)
	for index in range(thumbnail_page*PAGE_SIZE,mini(count,(thumbnail_page+1)*PAGE_SIZE)):
		var frame_number:int=index
		var source:int=_timeline[index]["source"]
		var hidden:bool=_timeline[index]["hidden"]
		var status:String="空白" if source<0 else ("隱藏" if hidden else "")
		var button:=_button("",func()->void:pause();seek_frame(frame_number));button.name="Frame_%d"%index;button.custom_minimum_size=Vector2(72,76);button.tooltip_text="第 %d 格"%(index+1);_strip.add_child(button)
		var box:=VBoxContainer.new();box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);box.offset_left=4;box.offset_right=-4;box.offset_top=3;box.offset_bottom=-3;box.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(box)
		var image:=TextureRect.new();image.texture=Catalog.frame(current_entry,source) if source>=0 and not hidden else null;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.custom_minimum_size=Vector2(64,48);image.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(image)
		if source>=0 and not hidden and current_entry.get("kind","")=="procedural":
			var sample:=Procedural.new();sample.custom_minimum_size=Vector2(64,48);sample.configure(current_entry["id"],source);box.remove_child(image);image.queue_free();box.add_child(sample)
		var number:=_label(str(index+1)+" "+status,11,MUTED);number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;number.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(number)
		_thumb_buttons.append(button);_thumb_indices.append(index)
	_page_label.text="%d / %d"%[thumbnail_page+1,pages];_previous_page.disabled=thumbnail_page==0;_next_page.disabled=thumbnail_page>=pages-1
	_highlight_thumbnails()
func _change_page(amount:int) -> void:
	if current_entry.is_empty():return
	pause();var pages:int=maxi(1,ceili(float(_timeline.size())/PAGE_SIZE));thumbnail_page=clampi(thumbnail_page+amount,0,pages-1);_rebuild_thumbnails();_refresh_preview()
func _close() -> void:
	pause();hide();set_process(false);_preview.texture=null
	for button:Button in _thumb_buttons:
		for box in button.get_children():
			for child in box.get_children():
				if child is TextureRect:child.texture=null
	Catalog.clear_cache();closed.emit()
func _unhandled_key_input(event:InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_close();get_viewport().set_input_as_handled()
func _exit_tree() -> void:Catalog.clear_cache()

func set_view(view:String) -> void:
	var gallery:bool=view=="gallery";_view.select(1 if gallery else 0);_gallery.visible=gallery;_inspector.visible=not gallery
	if gallery:_rebuild_gallery()
	else:
		for child in _gallery_grid.get_children():_gallery_grid.remove_child(child);child.queue_free()
		gallery_cards.clear()

func change_gallery_page(amount:int) -> void:
	var pages:int=maxi(1,ceili(float(filtered_entries.size())/GALLERY_PAGE_SIZE));gallery_page=clampi(gallery_page+amount,0,pages-1);_rebuild_gallery()

func copy_asset_id(id:String) -> void:
	DisplayServer.clipboard_set(id)
	if _gallery_page_label!=null:_gallery_page_label.text="已複製 ID："+id

func _rebuild_gallery() -> void:
	if _gallery_grid==null:return
	for child in _gallery_grid.get_children():_gallery_grid.remove_child(child);child.queue_free()
	gallery_cards.clear()
	var count:int=filtered_entries.size();var pages:int=maxi(1,ceili(float(count)/GALLERY_PAGE_SIZE));gallery_page=clampi(gallery_page,0,pages-1)
	for index in range(gallery_page*GALLERY_PAGE_SIZE,mini(count,(gallery_page+1)*GALLERY_PAGE_SIZE)):
		var item:Dictionary=filtered_entries[index];gallery_cards.append(item)
		var panel:=PanelContainer.new();panel.custom_minimum_size=Vector2(198,166);panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_theme_stylebox_override("panel",_style(Color("183b39"),Color("3b5857")));_gallery_grid.add_child(panel)
		var card:=VBoxContainer.new();card.add_theme_constant_override("separation",4);panel.add_child(card)
		var picture:=TextureButton.new();picture.name="AssetThumbnail";picture.texture_normal=Catalog.frame(item,0);picture.ignore_texture_size=true;picture.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED;picture.custom_minimum_size=Vector2(168,83);card.add_child(picture)
		picture.pressed.connect(func()->void:select_entry(item);set_view("inspector"))
		if item.get("kind","")=="procedural":
			var sample:=Procedural.new();sample.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);sample.configure(item["id"],0);picture.add_child(sample)
		var label:=_label(str(item["label"]),12);label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.tooltip_text=str(item["label"]);card.add_child(label)
		var status:String="已使用" if item.get("runtime_usage","")=="used" else "un-used"
		var category:=_label(status+" · "+str(item["category"]),10,Color("a0d3ba") if status=="已使用" else Color("d1aa7e"));category.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;category.tooltip_text=str(item.get("usage_note",""));card.add_child(category)
		var id_row:=HBoxContainer.new();card.add_child(id_row)
		var id_text:=LineEdit.new();id_text.text=str(item["id"]);id_text.editable=false;id_text.add_theme_font_size_override("font_size",10);id_text.custom_minimum_size.x=105;id_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;id_row.add_child(id_text)
		var id:String=str(item["id"]);var copy:=_button("複製",func()->void:copy_asset_id(id),43);copy.add_theme_font_size_override("font_size",11);copy.custom_minimum_size.y=27;id_row.add_child(copy)
	_gallery_page_label.text="%d / %d 頁 · %d 張素材"%[gallery_page+1,pages,count];_gallery_previous.disabled=gallery_page==0;_gallery_next.disabled=gallery_page>=pages-1
