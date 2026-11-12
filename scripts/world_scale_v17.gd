class_name WorldScaleV17
extends RefCounted
## Cell density and physical cell size are independent from actor/movement scale.
const BASE_TILE:int=64
const CELL_SCALE:float=1.5
const ROOM_GRID_SCALE:float=.5
const TILE:int=96
const TILE_HEIGHT:float=preload("res://scripts/player_motion_v18.gd").BASE_JUMP_HEIGHT*2.5
const CELL_SIZE:=Vector2(TILE,TILE_HEIGHT)
const CLIMB_STEP:float=TILE_HEIGHT/3.0
const BASE_WIDTHS:Array[int]=[33,37,41,45,49]
const BASE_HEIGHTS:Array[int]=[17,19,21,23]
const WIDTHS:Array[int]=[17,19,21,23,25]
const HEIGHTS:Array[int]=[9,11,13]
# Authored functional rooms keep space for tables, stations and the bath.
const SANCTUARY_GRID:=Vector2i(17,11)
const MIN_ZOOM:float=720.0/(9*96)
static func half_odd(value:int) -> int:return ceili(value*ROOM_GRID_SCALE)|1
