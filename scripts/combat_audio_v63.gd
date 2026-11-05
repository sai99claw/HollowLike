class_name CombatAudioV63
extends Node

const ROOT := "res://assets/v63/audio/"
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
		voices.append(voice)
		add_child(voice)

static func load_cues(sounds: Dictionary) -> void:
	var ids := ACTIONS.duplicate()
	for weapon in Data.SECONDARY:
		ids.append("shot_" + str(weapon["id"]))
	for projectile in PROJECTILES:
		ids.append("shot_" + projectile)
	for biome in Combat.BOSS_BIOMES:
		for slot in 4:
			ids.append("boss_%s_%d" % [biome, slot])
	for id: String in ids:
		var stream := load(ROOT + id + ".ogg") as AudioStream
		if stream != null:
			sounds[id] = stream

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
	var interval := 70 if id in ["coin", "impact_hit", "impact_heavy", "shot_bee", "projectile_bounce"] else 42
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
	voice.volume_db = -13
	if id.begins_with("boss_") and id != "boss_warning":
		voice.volume_db = -10
	elif id in ["shot_bee", "land", "wall_attach", "projectile_bounce", "enemy_jump"]:
		voice.volume_db = -20
	voice.play()

func stop_all() -> void:
	for voice in voices:
		voice.stop()
	last_played.clear()
