class_name RDRoomV16
extends Control
## Full-screen, mouse-first atlas/animation inspection. No gameplay state is owned.
signal closed
const Procedural=preload("res://scripts/rd_procedural_v16.gd")
const Burst=preload("res://scripts/pigeon_burst_v72.gd")
const TagRules=preload("res://scripts/art_tags_v73.gd")
const TAG_FILE:String="user://rd_asset_tags.cfg"
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

class FrameButton:
	extends Button
	var timeline_index:int
	var reorder:Callable
	func _get_drag_data(_at:Vector2) -> Variant:
		var badge:=Label.new()
		badge.text="第 %d 格"%(timeline_index+1)
		set_drag_preview(badge)
		return {"timeline":reorder,"index":timeline_index}
	func _can_drop_data(_at:Vector2,data:Variant) -> bool:
		return data is Dictionary and data.get("timeline") == reorder and data.get("index") != timeline_index
	func _drop_data(at:Vector2,data:Variant) -> void:
		reorder.call(int(data["index"]),timeline_index+int(at.x>=size.x*.5))

var current_entry:Dictionary={}
var frame_index:int=0
var fps:float=12
var playing:bool=true
var entries:Array[Dictionary]=[]
var filtered_entries:Array[Dictionary]=[]
var thumbnail_page:int=0
var _timeline:Array[Dictionary]=[]
var _phase_edits:Dictionary={}
var _playable:Array[int]=[]
var _copied_frame:Dictionary={}
var _copied_asset:String=""
var _phase_id:String="all"
var _elapsed:float=0
var _built:bool=false
var _changing:bool=false
var _preview_frame:int=-1
var _preview_id:String=""
var _thumb_buttons:Array[Button]=[]
var _thumb_indices:Array[int]=[]
var _search:LineEdit
var _include_menu:MenuButton
var _exclude_menu:MenuButton
var _tag_summary:Label
var _custom_tag:LineEdit
var _entry_tags:Label
var included_tags:Dictionary={}
var excluded_tags:Dictionary={}
var custom_tags:Dictionary={}
var tag_options:PackedStringArray=[]
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
var _active_frame_style:StyleBoxFlat
var _inactive_frame_style:StyleBoxFlat

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
	_build()
	entries=Catalog.all_entries()
	var saved:=ConfigFile.new()
	if saved.load(TAG_FILE)==OK:
		var stored:Variant=saved.get_value("art","tags",{})
		if stored is Dictionary:custom_tags=stored
	_fill_tag_menus()
	_built=true
	_filter()
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
func _button(text:String,callback:Callable,width:float=0,provided:Button=null) -> Button:
	var value:Button=provided if provided!=null else Button.new();value.text=text;value.custom_minimum_size=Vector2(width,34)
	value.add_theme_color_override("font_color",INK);value.add_theme_stylebox_override("normal",_style(Color("294a3e"),Color("416553")))
	value.add_theme_stylebox_override("hover",_style(Color("37614d"),GOLD));value.add_theme_stylebox_override("pressed",_style(Color("1c352d"),GOLD))
	value.pressed.connect(callback);return value
func _panel() -> PanelContainer:
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",_style(Color("152a23"),Color("365143")));return panel
func _build() -> void:
	_active_frame_style=_style(Color("49634a"),GOLD)
	_inactive_frame_style=_style(Color("294a3e"),Color("416553"))
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
	var filters:=HBoxContainer.new()
	left.add_child(filters)
	_include_menu=_tag_menu("包含標籤",included_tags,excluded_tags)
	_exclude_menu=_tag_menu("排除標籤",excluded_tags,included_tags)
	filters.add_child(_include_menu)
	filters.add_child(_exclude_menu)
	filters.add_child(_button("清除",clear_filters))
	_tag_summary=_label("",12,MUTED)
	_tag_summary.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	left.add_child(_tag_summary)
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
	strip_header.add_child(_label("影格順序 · 可拖曳 · Ctrl+C／Ctrl+V",13,MUTED));var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;strip_header.add_child(spacer)
	_previous_page=_button("上一頁",func()->void:_change_page(-1),70);strip_header.add_child(_previous_page)
	_page_label=_label("1 / 1",12,MUTED);_page_label.custom_minimum_size.x=45;_page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;strip_header.add_child(_page_label)
	_next_page=_button("下一頁",func()->void:_change_page(1),70);strip_header.add_child(_next_page)
	_thumbnail_scroll=ScrollContainer.new();_thumbnail_scroll.name="FrameStripScroll";_thumbnail_scroll.custom_minimum_size.y=80;_thumbnail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;_thumbnail_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;right.add_child(_thumbnail_scroll)
	_strip=HBoxContainer.new();_strip.name="ChronologicalFrames";_strip.add_theme_constant_override("separation",5);_thumbnail_scroll.add_child(_strip)
	_source=_label("",12,MUTED);_source.name="SourcePath";_source.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;right.add_child(_source)
	var id_row:=HBoxContainer.new();right.add_child(id_row)
	_asset_id=LineEdit.new();_asset_id.name="CopyableAssetID";_asset_id.editable=false;_asset_id.size_flags_horizontal=Control.SIZE_EXPAND_FILL;id_row.add_child(_asset_id)
	id_row.add_child(_button("複製 ID",func()->void:if not current_entry.is_empty():copy_asset_id(str(current_entry["id"])),95))
	_entry_tags=_label("",12,MUTED)
	_entry_tags.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	right.add_child(_entry_tags)
	var custom_row:=HBoxContainer.new()
	right.add_child(custom_row)
	_custom_tag=LineEdit.new()
	_custom_tag.name="CustomAssetTag"
	_custom_tag.placeholder_text="自訂標籤"
	_custom_tag.max_length=30
	_custom_tag.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_custom_tag.text_submitted.connect(func(_value:String)->void:set_custom_tag(_custom_tag.text,true))
	custom_row.add_child(_custom_tag)
	custom_row.add_child(_button("加到素材",func()->void:set_custom_tag(_custom_tag.text,true)))
	custom_row.add_child(_button("從素材移除",func()->void:set_custom_tag(_custom_tag.text,false)))
	_notes=RichTextLabel.new();_notes.name="AssetNotes";_notes.custom_minimum_size.y=40;_notes.scroll_active=true;_notes.add_theme_font_size_override("normal_font_size",12);_notes.add_theme_color_override("default_color",MUTED);right.add_child(_notes)
	_gallery=VBoxContainer.new();_gallery.name="AssetGalleryView";_gallery.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(_gallery);_gallery.hide()
	_gallery.add_child(_label("全部貼圖 · 首幀預覽",20,GOLD));_gallery.add_child(_label("每頁 12 張，按需載入。點圖檢視動畫；ID 可直接複製。",13,MUTED))
	var gallery_scroll:=ScrollContainer.new();gallery_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;gallery_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_gallery.add_child(gallery_scroll)
	_gallery_grid=GridContainer.new();_gallery_grid.name="AssetGallery";_gallery_grid.columns=4;_gallery_grid.add_theme_constant_override("h_separation",10);_gallery_grid.add_theme_constant_override("v_separation",10);_gallery_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gallery_scroll.add_child(_gallery_grid)
	var pages:=HBoxContainer.new();pages.add_theme_constant_override("separation",15);_gallery.add_child(pages)
	_gallery_previous=_button("上一頁",func()->void:change_gallery_page(-1),110);pages.add_child(_gallery_previous)
	_gallery_page_label=_label("",14,MUTED);_gallery_page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_gallery_page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pages.add_child(_gallery_page_label)
	_gallery_next=_button("下一頁",func()->void:change_gallery_page(1),110);pages.add_child(_gallery_next)
func _tag_menu(title:String,selected:Dictionary,opposite:Dictionary) -> MenuButton:
	var button:=MenuButton.new()
	button.text=title
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var popup:=button.get_popup()
	popup.theme=theme
	popup.max_size=Vector2i(0,440)
	popup.hide_on_checkable_item_selection=false
	popup.id_pressed.connect(func(index:int)->void:
		if index<0 or index>=tag_options.size():return
		var tag:String=tag_options[index]
		if selected.has(tag):selected.erase(tag)
		else:
			opposite.erase(tag)
			selected[tag]=true
		_sync_tag_checks()
		_filter())
	return button

func _asset_tags(item:Dictionary) -> PackedStringArray:
	var tags:PackedStringArray=item["tags"].duplicate()
	for value:Variant in custom_tags.get(item["id"],[]):
		tags.append("自訂/"+str(value))
	return tags

func _fill_tag_menus() -> void:
	var unique:Dictionary={}
	for item:Dictionary in entries:
		for tag:String in _asset_tags(item):unique[tag]=true
	tag_options.clear()
	for button:MenuButton in [_include_menu,_exclude_menu]:button.get_popup().clear()
	for facet:String in TagRules.FACETS:
		var values:Array=unique.keys().filter(func(tag:String)->bool:return tag.begins_with(facet+"/"))
		if values.is_empty():continue
		values.sort_custom(func(left:String,right:String)->bool:return left.naturalnocasecmp_to(right)<0)
		for button:MenuButton in [_include_menu,_exclude_menu]:button.get_popup().add_separator(facet)
		for tag:String in values:
			for button:MenuButton in [_include_menu,_exclude_menu]:button.get_popup().add_check_item(tag.get_slice("/",1),tag_options.size())
			tag_options.append(tag)
	for selected:Dictionary in [included_tags,excluded_tags]:
		for tag:String in selected.keys():
			if not unique.has(tag):selected.erase(tag)
	_sync_tag_checks()

func _sync_tag_checks() -> void:
	for button:MenuButton in [_include_menu,_exclude_menu]:
		var selected:Dictionary=included_tags if button==_include_menu else excluded_tags
		var popup:=button.get_popup()
		for row in popup.item_count:
			if not popup.is_item_separator(row):popup.set_item_checked(row,selected.has(tag_options[popup.get_item_id(row)]))
	var terms:=PackedStringArray()
	for tag:String in included_tags:terms.append("＋"+tag)
	for tag:String in excluded_tags:terms.append("－"+tag)
	_tag_summary.text=" · ".join(terms) if not terms.is_empty() else "同類任一符合，跨類須同時符合"
	_tag_summary.tooltip_text=_tag_summary.text

func set_custom_tag(raw:String,enabled:bool) -> void:
	if current_entry.is_empty():return
	var label:String=raw.strip_edges().replace("/","／")
	if label.is_empty():return
	var id:String=current_entry["id"]
	var labels:Array=custom_tags.get(id,[])
	if enabled and not labels.has(label):labels.append(label)
	elif not enabled:labels.erase(label)
	if labels.is_empty():custom_tags.erase(id)
	else:custom_tags[id]=labels
	var saved:=ConfigFile.new()
	saved.set_value("art","tags",custom_tags)
	if saved.save(TAG_FILE)!=OK:push_warning("無法儲存 RD 自訂標籤")
	_fill_tag_menus()
	_update_entry_tags()
	_filter()

func _update_entry_tags() -> void:
	_entry_tags.text=" · ".join(_asset_tags(current_entry)) if not current_entry.is_empty() else ""
	_entry_tags.tooltip_text=_entry_tags.text

func _filter() -> void:
	if _list==null:return
	filtered_entries=Catalog.search(_search.text).filter(func(item:Dictionary)->bool:return TagRules.matches(_asset_tags(item),included_tags,excluded_tags))
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
	_search.text=""
	included_tags.clear()
	excluded_tags.clear()
	_sync_tag_checks()
	_filter()
func _clear_selection() -> void:
	pause();current_entry={};_phase_edits.clear();_timeline=[];frame_index=0;_preview_frame=-1;_preview_id=""
	if _preview==null:return
	_update_entry_tags()
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
	_preview.modulate=Burst.IMPACT_TINT if item["id"]=="v72:impact_feathers" else Color.WHITE
	_name.text=str(item["label"]);_name.tooltip_text=str(item["id"])
	_source.text=str(item["id"])+"  ·  "+str(item["frames"][0].get("path",""));_source.tooltip_text=_source.text
	_asset_id.text=str(item["id"])
	_update_entry_tags()
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
		slots.append({"source":source,"hidden":source in current_entry.get("hidden_frames",[])})
	return slots

func insert_blank_frame() -> void:
	if _timeline.is_empty():return
	_timeline.insert(frame_index+1,{"source":-1,"hidden":false})
	frame_index+=1
	_finish_timeline_edit()

func copy_frame() -> void:
	if _timeline.is_empty():return
	_copied_frame=_timeline[frame_index].duplicate()
	_copied_asset=str(current_entry["id"])

func paste_frame() -> void:
	if _timeline.is_empty() or _copied_frame.is_empty() or current_entry["id"]!=_copied_asset:return
	frame_index+=1
	_timeline.insert(frame_index,_copied_frame.duplicate())
	_finish_timeline_edit()

func move_frame(from_index:int,insertion_index:int) -> void:
	if from_index<0 or from_index>=_timeline.size():return
	var slot:Dictionary=_timeline.pop_at(from_index)
	frame_index=clampi(insertion_index-int(from_index<insertion_index),0,_timeline.size())
	_timeline.insert(frame_index,slot)
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
	_playable.clear()
	for index:int in _timeline.size():
		if not _timeline[index]["hidden"]:_playable.append(index)
	_play_button.disabled=_playable.size()<=1
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
	if _playable.size()<=1:return
	if not _playable.has(frame_index):
		var next:int=_playable.bsearch(frame_index)
		seek_frame(_playable[next%_playable.size()])
	playing=true;_elapsed=0
	if _play_button!=null:_play_button.text="暫停"
func _toggle_play() -> void:
	if playing:pause()
	else:play()
func _process(delta:float) -> void:
	if not visible or (_gallery!=null and _gallery.visible) or not playing or _playable.size()<=1:return
	_elapsed+=delta
	var interval:float=1.0/fps
	if _elapsed<interval:return
	var advance:int=maxi(1,int(_elapsed/interval));_elapsed=fmod(_elapsed,interval)
	frame_index=_playable[(_playable.bsearch(frame_index)+advance)%_playable.size()]
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
	for i in _thumb_buttons.size():
		var selected:bool=_thumb_indices[i]==frame_index
		var button:Button=_thumb_buttons[i]
		button.modulate=Color.WHITE if selected else Color(.67,.75,.69,1)
		button.add_theme_stylebox_override("normal",_active_frame_style if selected else _inactive_frame_style)
		if selected:_scroll_to_frame.call_deferred(button)
func _scroll_to_frame(button:Button) -> void:
	if is_instance_valid(button) and button.is_inside_tree():_thumbnail_scroll.ensure_control_visible(button)
func _rebuild_thumbnails() -> void:
	if _strip==null or current_entry.is_empty():return
	for child in _strip.get_children():_strip.remove_child(child);child.queue_free()
	_thumb_buttons.clear();_thumb_indices.clear()
	var count:int=_timeline.size();var pages:int=maxi(1,ceili(float(count)/PAGE_SIZE));thumbnail_page=clampi(thumbnail_page,0,pages-1)
	for index in range(thumbnail_page*PAGE_SIZE,mini(count,(thumbnail_page+1)*PAGE_SIZE)):
		var frame_number:int=index
		var source:int=_timeline[index]["source"]
		var hidden:bool=_timeline[index]["hidden"]
		var status:String="空白" if source<0 else ("隱藏" if hidden else "%d"%(source+1))
		var draggable:=FrameButton.new()
		draggable.timeline_index=index
		draggable.reorder=move_frame
		var button:=_button("",func()->void:pause();seek_frame(frame_number),72,draggable)
		button.name="Frame_%d"%index
		button.custom_minimum_size=Vector2(72,76)
		button.tooltip_text="第 %d 格 · 拖到左半部插入前方，右半部插入後方"%(index+1)
		_strip.add_child(button)
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
func _input(event:InputEvent) -> void:
	if not visible or not _built or not _inspector.visible or not event is InputEventKey:return
	if not event.pressed or event.echo or not event.is_command_or_control_pressed():return
	var focused:Control=get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:return
	match event.keycode:
		KEY_C:copy_frame()
		KEY_V:paste_frame()
		_:return
	get_viewport().set_input_as_handled()

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
