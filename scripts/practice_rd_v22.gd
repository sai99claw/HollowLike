class_name PracticeRDV22
extends Control
signal regenerate(parameters:Dictionary)
signal closed
const ROOM_TYPES:Array[Array]=[
	["一般戰鬥房","combat"],["開放練習場","arena"],["菁英房","elite"],["首領房","boss"],
	["整備房","start"],["商人房","merchant"],["獎勵房","reward"],["尖刺島","spike_islands"],["漂浮香菇房","mushroom_air"]
]
const DEFAULTS:Dictionary={"room_kind":"combat","biome":"trunk","arena":false,"width":21,"height":13,"seed":0,"profile":"terraces","straight_bias":.55,"braid_rate":.45,"plaza_scale":1.0,"enemy_density":0.0,"dead_end_chance":.25}
var draft:Dictionary={}
var editors:Dictionary={}
func setup(parameters:Dictionary) -> void:
	draft=DEFAULTS.duplicate();draft.merge(parameters,true)
	if parameters.get("arena",false) and not parameters.has("room_kind"):draft["room_kind"]="arena"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	var skin:=Theme.new();skin.default_font=load("res://assets/Chinese.otf");skin.default_font_size=17;theme=skin
	var backing:=ColorRect.new();backing.color=Color(.02,.05,.06,.93);backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backing)
	var panel:=PanelContainer.new();panel.position=Vector2(240,38);panel.size=Vector2(800,644);add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=Color("16343b");style.set_content_margin_all(22);style.set_corner_radius_all(14);panel.add_theme_stylebox_override("panel",style)
	var body:=VBoxContainer.new();body.add_theme_constant_override("separation",10);panel.add_child(body)
	var title:=Label.new();title.text="練習房 · RD 即時生成";title.add_theme_font_size_override("font_size",26);body.add_child(title)
	var note:=Label.new();note.text="生成會清空房內怪物、屍體與掉落物；你的裝備保留。只影響練習房。";note.add_theme_font_size_override("font_size",14);body.add_child(note)
	var grid:=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",15);grid.add_theme_constant_override("v_separation",12);body.add_child(grid)
	_choice(grid,"生態系","biome",[["土色地底","underground"],["綠色樹幹","trunk"],["藍色天空","sky"]])
	_choice(grid,"房型","room_kind",ROOM_TYPES)
	_choice(grid,"地形輪廓","profile",[["階梯層岩","terraces"],["雙廳分流","twin_halls"],["洞穴岩柱","pillars"],["大廳豎井","shaft"],["寬闊洞穴","cavern"],["環狀長廊","loops"]])
	_number(grid,"隨機種子（0 隨機）","seed",0,2000000000,1)
	_number(grid,"寬度（格）","width",17,25,2);_number(grid,"高度（格）","height",11,17,2)
	_number(grid,"直線走廊偏好","straight_bias",.1,.95,.05);_number(grid,"死巷打通機率","braid_rate",0,1,.05)
	_number(grid,"廣場開闊程度","plaza_scale",.5,1.5,.05);_number(grid,"怪物倍率（0 無怪）","enemy_density",0,2.5,.1)
	_number(grid,"長寶箱支線機率","dead_end_chance",.2,1,.05)
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(spacer)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",18);body.add_child(footer)
	var generate:=Button.new();generate.name="RegeneratePracticeRoom";generate.text="套用並重新生成";generate.custom_minimum_size=Vector2(260,46);generate.pressed.connect(apply);footer.add_child(generate)
	var close:=Button.new();close.text="取消返回";close.custom_minimum_size=Vector2(170,46);close.pressed.connect(func()->void:closed.emit());footer.add_child(close)
func _choice(grid:GridContainer,label:String,id:String,options:Array) -> void:
	var name:=Label.new();name.text=label;grid.add_child(name)
	var select:=OptionButton.new();select.custom_minimum_size=Vector2(190,34);select.name="Practice_"+id;grid.add_child(select)
	for pair:Array in options:
		select.add_item(pair[0]);select.set_item_metadata(select.item_count-1,pair[1])
		if pair[1]==draft[id]:select.select(select.item_count-1)
	select.item_selected.connect(func(index:int)->void:draft[id]=select.get_item_metadata(index));editors[id]=select
func _number(grid:GridContainer,label:String,id:String,minimum:float,maximum:float,step:float) -> void:
	var name:=Label.new();name.text=label;grid.add_child(name)
	var spin:=SpinBox.new();spin.name="Practice_"+id;spin.custom_minimum_size=Vector2(190,34);spin.min_value=minimum;spin.max_value=maximum;spin.step=step;spin.value=draft[id];grid.add_child(spin)
	spin.value_changed.connect(func(value:float)->void:draft[id]=value);editors[id]=spin
func set_value(id:String,value:Variant) -> void:
	if not draft.has(id):return
	draft[id]=value
	if editors.get(id) is SpinBox:editors[id].value=value
	elif editors.get(id) is OptionButton:
		var select:OptionButton=editors[id]
		for index in select.item_count:
			if select.get_item_metadata(index)==value:select.select(index);break
func apply() -> void:
	regenerate.emit(draft.duplicate(true));closed.emit()
