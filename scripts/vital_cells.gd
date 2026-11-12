class_name VitalCells
extends HBoxContainer
## Whole resource cells; recovery is an animated pending cell, never a decimal
## amount presented as completed health or energy.
var value:int=0
var capacity:int=1
var recovery_progress:float=0
var recovering_index:int=-1
var filled_color:Color=Color("e8a18c")
var _phase:float=0
var empty_texture:Texture2D
var full_texture:Texture2D
var cell_size:=Vector2(12,16)
var _cells:Array[Control]=[]
var _last_state:=Vector3i(-1,-1,-1)
var _styles:Dictionary={}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation",3)
	size_flags_vertical=Control.SIZE_SHRINK_CENTER

func set_state(amount:int,maximum:int,progress:float=0,recovering:bool=false) -> void:
	value=clampi(amount,0,maxi(1,maximum));capacity=maxi(1,maximum)
	recovery_progress=clampf(progress,0,1)
	recovering_index=value if recovering and value<capacity else -1
	var state:=Vector3i(value,capacity,recovering_index)
	if state==_last_state:
		if recovering_index>=0:_cells[recovering_index].tooltip_text="恢復中 %d%%"%int(recovery_progress*100)
		return
	_last_state=state
	if _cells.size()!=capacity:
		for cell in _cells:
			remove_child(cell);cell.queue_free()
		_cells.clear()
		for i in capacity:
			var cell:Control
			if full_texture!=null and empty_texture!=null:
				var icon:=TextureRect.new()
				icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				cell=icon
			else:
				cell=Panel.new()
			cell.name="Cell%02d"%(i+1)
			cell.custom_minimum_size=cell_size
			cell.mouse_filter=Control.MOUSE_FILTER_IGNORE
			add_child(cell);_cells.append(cell)
	for i in capacity:
		var cell:Control=_cells[i]
		var full:bool=i<value
		var pending:bool=i==recovering_index
		if cell is TextureRect:
			cell.texture=full_texture if full or pending else empty_texture
		else:
			var style_key:String=filled_color.to_html()+str(full or pending)
			if not _styles.has(style_key):
				var created:=StyleBoxFlat.new();created.bg_color=filled_color if full or pending else Color("203c39");created.border_color=filled_color.lightened(.25) if full or pending else Color("527168");created.set_corner_radius_all(3);created.set_border_width_all(1);_styles[style_key]=created
			var style:StyleBoxFlat=_styles[style_key]
			cell.add_theme_stylebox_override("panel",style)
		cell.set_meta("filled",full);cell.set_meta("recovering",pending)
		cell.tooltip_text="恢復中 %d%%"%int(recovery_progress*100) if pending else ("已回復" if full else "空格")
		cell.modulate.a=_pending_alpha() if pending else 1.0

func _process(delta:float) -> void:
	_phase=fmod(_phase+delta,1.0)
	if recovering_index>=0 and recovering_index<_cells.size():_cells[recovering_index].modulate.a=_pending_alpha()

func _pending_alpha() -> float:
	return .25+.75*(.5+.5*sin(_phase*TAU*2.0))


func target_center() -> Vector2:
	if _cells.is_empty():return get_global_transform_with_canvas()*(size*.5)
	var cell:Control=_cells[mini(value,_cells.size()-1)]
	return cell.get_global_transform_with_canvas()*(cell.size*.5)
