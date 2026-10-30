class_name RoomMusic
extends AudioStreamPlayer
## Selection is based only on the supplied filenames; no audio-content analysis.
const ROOT="res://assets/music/"
const FIGHT={"sky":"FIGHT_Beyond_The_Twilight_Sea","canopy":"FIGHT_Beneath_the_Ancient_Canopy","branches":"FIGHT_Beneath_the_Ancient_Canopy","trunk":"FIGHT_Beneath_the_Ancient_Canopy","grass":"FIGHT_Beneath_the_Glowing_Roots","underground":"FIGHT_Beneath_the_Glowing_Roots"}
const BOSS={"sky":"BOSS_Storm_Over_The_Spire","canopy":"BOSS_Storm_Over_The_Spire","branches":"BOSS_Wrath_of_the_Root","trunk":"BOSS_Wrath_of_the_Root","grass":"BOSS_Wrath_of_the_Root","underground":"BOSS_Beneath_the_Luminous_Maw"}
const RELAX={"sky":"RELEX_Waters_Above_the_Clouds","canopy":"RELEX_Morning_at_the_Hidden_Spring","branches":"RELEX_Morning_at_the_Hidden_Spring","trunk":"RELEX_Morning_at_the_Hidden_Spring","grass":"RELEX_Morning_at_the_Hidden_Spring","underground":"RELEX_Breath_of_the_Thermal_Spring"}
var current_title:String=""
var enabled:bool=true
var music_volume:float=.55

static func title_for(room_type:String,biome:String,spring:bool=false) -> String:
	if spring or room_type in ["hub","start","reward","win"]:return RELAX.get(biome,RELAX["branches"])
	if room_type=="boss":return BOSS.get(biome,BOSS["branches"])
	return FIGHT.get(biome,FIGHT["branches"])

func select(room_type:String,biome:String,spring:bool=false) -> void:
	var title:String=title_for(room_type,biome,spring)
	if title==current_title:return
	current_title=title
	stream_paused=false;stop();stream=null
	var audio=load(ROOT+title+".ogg") as AudioStreamOggVorbis
	if audio==null:return
	audio.loop=true;stream=audio;volume_db=linear_to_db(maxf(.001,music_volume))-7
	if enabled:play()

func set_enabled(value:bool) -> void:
	enabled=value
	AudioServer.set_bus_mute(0,not value)
	# The master bus handles muting; an already-playing track keeps its place.
	# Never freeze a playback while replacing room streams or leaving the tree.
	stream_paused=false
	if value and stream!=null and not playing:play()

func set_volume(value:float) -> void:
	music_volume=clampf(value,0,1)
	volume_db=linear_to_db(maxf(.001,music_volume))-7

func _exit_tree() -> void:
	stream_paused=false;stop();stream=null
