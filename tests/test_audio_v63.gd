extends SceneTree

const Cues = preload("res://scripts/combat_audio_v63.gd")
const Roster = preload("res://scripts/monster_roster_v36.gd")
const Roster55 = preload("res://scripts/monster_roster_v55.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var game: Node = preload("res://main.tscn").instantiate()
	game.audio_enabled = false
	root.add_child(game)
	game.room_music.stream = null
	for weapon in Cues.Data.SECONDARY:
		var id := Cues.attack_cue(weapon)
		check(id == "shot_" + str(weapon["id"]) and game.sounds.has(id), "Weapon launch cue is available " + id)
	for biome in Cues.Combat.BOSS_BIOMES:
		var boss := Cues.Combat.boss(biome)
		var attacks: Array = boss["attacks"].duplicate()
		attacks.append(Cues.Combat.boss_phase_two(boss))
		var heard: Array[String] = []
		for definition in attacks:
			var id := Cues.attack_cue(definition)
			check(game.sounds.has(id) and not heard.has(id), "Each boss attack has its own loaded cue " + id)
			heard.append(id)
	for biome in Roster.BIOMES:
		for index in 5:
			var actors := [Roster.regular(biome, index), Roster55.create(biome, index, Roster.BIOMES.find(biome) * 2)]
			for actor in actors:
				for definition in actor["attacks"]:
					var id := Cues.attack_cue(definition)
					check(game.sounds.has(id), "Species attack is mapped " + id)
	for stage in 6:
		for definition in Roster.elite(stage)["attacks"]:
			var id := Cues.attack_cue(definition)
			check(game.sounds.has(id), "Legacy elite attack is mapped " + id)
	for id in Cues.ACTIONS:
		check(game.sounds.has(id) and game.sounds[id].get_length() > .06, "Action has a packaged cue " + id)
	game.audio_enabled = true
	game._reset_player(Vector2(440, 600))
	game.jump_request = true
	game._update_player(.016)
	game.jump_request = true
	game._update_player(.016)
	check(game.combat_audio.last_played.has("jump") and game.combat_audio.last_played.has("double_jump"), "Ground jump and second jump use distinct cues")
	game._emit_weapon(Vector2(440, 480), Vector2.RIGHT, Cues.Data.secondary_attack(0), true)
	check(game.combat_audio.last_played.has("shot_needle") and not game.combat_audio.last_played.has("slash"), "Projectile launch plays its own cue once with no generic sword sound")
	game.combat_audio.last_played.erase("double_jump")
	game._sound("double_jump")
	var used: int = game.combat_audio.next_voice
	game._sound("double_jump")
	check(used == game.combat_audio.next_voice and used > 0, "Identical immediate cue is rate limited")
	var state: int = game.rng.state
	game._sound("jump")
	check(game.rng.state == state, "Sound pitch does not consume gameplay random state")
	game.audio_enabled = false
	for voice in game.combat_audio.voices:
		check(not voice.playing, "Mute stops each existing sound voice")
	print("v0.63 audio validation with %d failures" % failures)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
