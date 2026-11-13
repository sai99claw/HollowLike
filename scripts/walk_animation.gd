class_name WalkAnimation
extends Node
const AudioCues=preload("res://scripts/combat_audio_v63.gd")
const ROOT="res://assets/walk_v2/"
const DISTANCE_PER_FRAME:float=16.5
const WALK_SEQUENCE=[6,2,7,8,9]
const LIMP_FRAME_COUNT:int=10
static var manifest:Dictionary={}
static var textures:Dictionary={}
static var frame_index:int=0
static var limping:bool=false
const TURN_DURATION:float=.24
const TURN_FACTOR:float=57.0/330.0
const TURN_REGIONS=[[38,84,390,320,265.0,318],[511,73,333,333,206.0,331],[958,73,307,339,195.0,337],[1397,74,306,336,202.0,334],[102,498,336,337,129.0,335],[509,496,325,341,108.0,339],[930,496,333,335,127.0,333],[1359,506,377,323,126.0,321]]
static var turn_texture:Texture2D
static var turn_from:float=1
static var turn_to:float=1
static var turn_elapsed:float=TURN_DURATION
var phase:float=0
var moving:bool=false
var last_variants:Dictionary={}
var voices:Array[AudioStreamPlayer]=[]
var voice_index:int=0
var emitted_events:int=0
func _ready() -> void:
	for i in 3:
		var voice:=AudioStreamPlayer.new();voice.volume_db=-8;add_child(voice);voices.append(voice)
static func ensure() -> bool:
	if manifest.is_empty() and FileAccess.file_exists(ROOT+"manifest.json"):
		manifest=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	return not manifest.is_empty()
static func clip() -> Dictionary:
	if not ensure():return {}
	return manifest["animations"]["pigeon_walk_master"]
static func draw_frame(c:CanvasItem,at:Vector2,face:float,tint:Color,scale_value:float,base:Transform2D) -> bool:
	var def:Dictionary=clip()
	if def.is_empty():return false
	var frame:Dictionary=def["frames"][WALK_SEQUENCE[frame_index%WALK_SEQUENCE.size()]]
	var path:String=ROOT+frame["path"]
	if not textures.has(path):textures[path]=load(path)
	var pixel_scale:float=80.0/256.0
	var pivot:=Vector2(frame["pivot"][0],frame["pivot"][1])*pixel_scale;var size:=Vector2(frame["size"][0],frame["size"][1])*pixel_scale
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2(face*scale_value,scale_value),0,at))
	c.draw_texture_rect(textures[path],Rect2(-pivot,size),false,tint);c.draw_set_transform_matrix(base);return true
func reset() -> void:
	phase=0;frame_index=0;moving=false
func advance(distance:float,enabled:bool,ground:String,audible:bool) -> void:
	if not enabled or distance<.001:reset();return
	if not moving:
		moving=true;phase=0;_footstep(ground,audible)
	var previous:int=int(floor(phase))
	phase+=distance/DISTANCE_PER_FRAME
	var current:int=int(floor(phase))
	for boundary in range(previous+1,current+1):
		if boundary%5==0:_footstep(ground,audible)
	frame_index=current%(LIMP_FRAME_COUNT if limping else WALK_SEQUENCE.size())
	if phase>12000:phase=fmod(phase,60)
func _footstep(ground:String,audible:bool) -> void:
	emitted_events+=1
	var variant:int=randi_range(1,4)
	if variant==int(last_variants.get(ground,0)):variant=variant%4+1
	last_variants[ground]=variant
	if not audible or voices.is_empty():return
	var voice:AudioStreamPlayer=voices[voice_index%voices.size()];voice_index+=1
	voice.stream=AudioCues.cue_stream("footstep_%s_%02d"%[ground,variant])
	voice.pitch_scale=randf_range(.97,1.03)
	if voice.stream!=null:voice.play()

func stop_audio() -> void:
	for voice in voices:voice.stop()

static func surface(biome:String,at:Vector2,layout:Dictionary) -> String:
	for block:Rect2 in layout.get("blocks",[]):
		if absf(at.y-block.position.y)<4 and at.x>=block.position.x-10 and at.x<=block.end.x+10:return "stone"
	if biome in ["canopy","grass"]:return "grass"
	if biome=="underground":return "stone"
	return "wood"

func reset_turn(face:float) -> void:
	turn_from=face;turn_to=face;turn_elapsed=TURN_DURATION
func step_turn(face:float,delta:float,enabled:bool) -> void:
	if not enabled:reset_turn(face);return
	if face!=turn_to:
		if turn_elapsed<TURN_DURATION:
			var previous:float=turn_from;turn_from=turn_to;turn_to=previous;turn_elapsed=TURN_DURATION-turn_elapsed
		else:turn_from=turn_to;turn_to=face;turn_elapsed=0
	turn_elapsed=minf(TURN_DURATION,turn_elapsed+delta)
static func turn_index() -> int:
	var index:int=clampi(int(turn_elapsed/TURN_DURATION*8),0,7)
	return index if turn_from>0 else 7-index
static func draw_turn(c:CanvasItem,at:Vector2,tint:Color,scale_value:float,base:Transform2D) -> bool:
	if turn_elapsed>=TURN_DURATION:return false
	if turn_texture==null:turn_texture=load("res://assets/atmosphere_v09/turn.png")
	var f:Array=TURN_REGIONS[turn_index()]
	var factor:float=TURN_FACTOR*scale_value
	c.draw_set_transform_matrix(base*Transform2D(0,Vector2.ONE*factor,0,at))
	c.draw_texture_rect_region(turn_texture,Rect2(-Vector2(f[4],f[5]),Vector2(f[2],f[3])),Rect2(f[0],f[1],f[2],f[3]),tint)
	c.draw_set_transform_matrix(base)
	return true
