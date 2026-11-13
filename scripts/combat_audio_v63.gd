class_name CombatAudioV63
extends Node

const BANK := "res://assets/short_sfx.bank"
const Data = preload("res://scripts/game_data.gd")
const Combat = preload("res://scripts/combat_library.gd")
const VOICE_COUNT := 12
const ACTIONS := [
	"jump", "double_jump", "wall_jump", "wall_attach", "mantle", "drop_through", "land", "heavy_land",
	"mushroom_bounce", "mushroom_pogo", "flight_boost", "water_splash", "dash_wind", "double_dash_wind",
	"slam_wind", "attack_heavy", "heal_build", "heal_finish", "hurt", "death", "dream_burst", "dream_slash",
	"item_energy", "item_shield", "item_power", "item_freeze", "item_shock", "projectile_bounce",
	"trap_land", "fire_land", "enemy_melee", "enemy_ram", "enemy_poison", "enemy_defeat", "enemy_jump",
	"boss_jump", "boss_defeat", "boss_phase", "boss_warning", "boss_summon", "boss_move_sky",
	"boss_move_canopy", "boss_move_trunk", "boss_move_underground"
]
const PROJECTILES := [
	"bee", "linear", "arc", "trap", "flying_slash", "mineral_dart", "resin_orb", "seed_needle", "web_seed",
	"leaf_crescent", "feather", "storm_dart", "moss_shard", "spring_seed", "lamp_pollen", "mist_spore", "root_spear",
	"hail", "storm_pod", "spore_pod", "acorn", "moth_needle", "guardian_acorn", "sound_crescent"
]

var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var last_played: Dictionary = {}
var variation := RandomNumberGenerator.new()

func _ready() -> void:
	variation.randomize()
	for index in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.bus = "Effects"
		voices.append(voice)
		add_child(voice)

static var directory: Dictionary = {}
static var bank_start: int = 0
static var streams: Dictionary = {}

static func _read_directory() -> void:
	if not directory.is_empty():
		return
	var file := FileAccess.open(BANK, FileAccess.READ)
	if file == null:
		return
	var index_size := file.get_32()
	directory = JSON.parse_string(file.get_buffer(index_size).get_string_from_utf8())
	bank_start = file.get_position()

static func has_cue(id: String) -> bool:
	_read_directory()
	return directory.has(id)

static func cue_stream(id: String) -> AudioStream:
	if not has_cue(id):
		return null
	if not streams.has(id):
		var file := FileAccess.open(BANK, FileAccess.READ)
		if file == null:
			return null
		var location: Array = directory[id]
		file.seek(bank_start + int(location[0]))
		streams[id] = AudioStreamOggVorbis.load_from_buffer(file.get_buffer(int(location[1])))
	return streams[id] as AudioStream

static func load_cues(sounds: Dictionary) -> void:
	_read_directory()
	for id: String in directory:
		if not id.begins_with("actor_") and not id.begins_with("footstep_"):
			var stream := cue_stream(id)
			if stream != null:
				sounds[id] = stream

static func actor_cue(actor: Dictionary, event: String, fallback: String) -> String:
	if int(actor.get("model", 0)) == 4:
		var boss := "boss_%s_%s" % [event, actor.get("biome", "")]
		return boss if has_cue(boss) else fallback
	var species := str(actor.get("roster_id", actor.get("species", "")))
	if actor.get("training", false) or actor.has("tutorial_respawn"):
		species = "tutorial_dummy"
	var id := "actor_%s_%s" % [species, event]
	return id if has_cue(id) else fallback

static func enemy_attack_cue(actor: Dictionary, definition: Dictionary, slot: int) -> String:
	var fallback := attack_cue(definition)
	if slot < 0 or int(actor.get("model", 0)) == 4:
		return fallback
	return actor_cue(actor, "attack_%d" % slot, fallback)

static func primary_cue(definition: Dictionary) -> String:
	if definition.get("style", "") == "heavy":
		return "attack_heavy"
	match str(definition.get("direction", "")):
		"up":
			return "attack_up"
		"down":
			return "attack_down"
	return "attack_reverse" if int(definition.get("combo", 0)) % 2 == 1 else "attack_whoosh"

static func attack_cue(definition: Dictionary) -> String:
	var boss: String = definition.get("boss_sound", "")
	if not boss.is_empty():
		return "boss_" + boss
	if definition.get("dream_slash", false):
		return "dream_slash"
	if definition.get("ram", false):
		return "enemy_ram"
	if definition.get("poison_cloud", false):
		return "enemy_poison"
	var id := str(definition.get("id", ""))
	if not id.is_empty():
		return "shot_" + id
	for key in ["visual_id", "style_id"]:
		var asset := str(definition.get(key, ""))
		var variant := asset.get_slice(":", 2) if ":" in asset else asset
		if variant in PROJECTILES:
			return "shot_" + variant
	var kind: String = definition.get("library_kind", "")
	match kind:
		"slash":
			return "enemy_melee"
		"explosion":
			return "" # The detonation supplies its own cue.
		"arc", "trap", "flying_slash":
			return "shot_" + kind
	return "shot_linear"

func play_cue(id: String, stream: AudioStream) -> void:
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	var interval := 70 if id in ["coin", "coin_collect", "impact_hit", "impact_heavy", "shot_bee", "projectile_bounce"] else 42
	if now - int(last_played.get(id, -1000)) < interval:
		return
	last_played[id] = now
	for offset in voices.size():
		var index := (next_voice + offset) % voices.size()
		if not voices[index].playing:
			next_voice = index
			break
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = stream
	voice.pitch_scale = variation.randf_range(.97, 1.03)
	voice.volume_db = -6
	if id.begins_with("boss_") and id != "boss_warning":
		voice.volume_db = -5
	elif id in ["shot_bee", "land", "wall_attach", "projectile_bounce", "enemy_jump"]:
		voice.volume_db = -10
	voice.play()

func stop_all() -> void:
	for voice in voices:
		voice.stop()
	last_played.clear()
