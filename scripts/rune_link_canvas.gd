class_name RuneLinkCanvas
extends Control
const Links=preload("res://scripts/rune_links.gd")
var slots:Array=[]
var board:GridContainer
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if board==null:return
	for edge in Links.edges(slots):
		if edge.y>=board.get_child_count():continue
		var a:Control=board.get_child(edge.x);var b:Control=board.get_child(edge.y)
		var start:Vector2=board.position+a.position+a.size*.5;var finish:Vector2=board.position+b.position+b.size*.5
		draw_line(start,finish,Color(.69,.43,1,.12),12,true)
		draw_line(start,finish,Color(.78,.55,1,.45),5,true)
		draw_line(start,finish,Color(.95,.84,1,.96),1.5,true)
func _process(_delta:float) -> void:
	if board!=null:
		var desired:float=maxf(0,(size.x-board.size.x)*.5)
		if not is_equal_approx(board.position.x,desired):board.position.x=desired;queue_redraw()
