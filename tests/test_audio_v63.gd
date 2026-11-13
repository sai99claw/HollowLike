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
	var background:=AudioServer.get_bus_index("Background")
	var effects:=AudioServer.get_bus_index("Effects")
	check(background>0 and effects>0 and background!=effects,"Independent audio buses are loaded")
	game._set_audio_volume("Background",0.0)
	game._set_audio_volume("Effects",.5)
	check(AudioServer.is_bus_mute(background) and not AudioServer.is_bus_mute(effects),"Silencing background leaves effects enabled")
	check(is_equal_approx(AudioServer.get_bus_volume_db(effects),linear_to_db(.5)),"Effects gain is independent")
	game._save_settings()
	check(game.meta["settings"]["background_volume"]==0.0 and game.meta["settings"]["sfx_volume"]==.5,"Both gains are saved")
	game._load_settings()
	check(game.background_volume==0.0 and game.sfx_volume==.5,"Both gains reload")
	check(game.room_music.bus=="Background" and game.combat_audio.voices[0].bus=="Effects","Music and gameplay use separate buses")
	game.room_music.select("combat","underground")
	check(game.room_music.current_title=="Subterranean_Roots_Ambient" and game.room_music.stream!=null,"Underground combat uses the supplied track")
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
		for index in Roster.REGULAR_COUNT:
			var actors := [Roster.regular(biome, index)]
			if index < 5:actors.append(Roster55.create(biome, index, Roster.BIOMES.find(biome) * 2))
			for actor in actors:
				for slot in actor["attacks"].size():
					var id := Cues.enemy_attack_cue(actor, actor["attacks"][slot], slot)
					check(id.begins_with("actor_") and Cues.cue_stream(id) != null, "Species attack is mapped " + id)
				for event in ["hit","defeat","jump","rush"]:
					var id := Cues.actor_cue(actor,event,"")
					check(Cues.cue_stream(id) != null, "Species has its own " + event + " cue: " + id)
	for stage in 6:
		var elite := Roster.elite(stage)
		for slot in elite["attacks"].size():
			var id := Cues.enemy_attack_cue(elite, elite["attacks"][slot], slot)
			check(id.begins_with("actor_") and Cues.cue_stream(id) != null, "Legacy elite attack is mapped " + id)
	for id in Cues.ACTIONS:
		check(game.sounds.has(id) and game.sounds[id].get_length() > .06, "Action has a packaged cue " + id)
	for id in Cues.directory:
		var stream := Cues.cue_stream(id)
		check(stream != null and stream.get_length() > .06 and stream.get_length() < 1.0, "Every bank stream decodes with a one-shot duration " + id)
	for surface in ["wood","stone","grass"]:
		for take in range(1,5):
			check(Cues.cue_stream("footstep_%s_%02d" % [surface,take]) != null, "All four surface footstep takes exist")
	check(Cues.primary_cue(Cues.Data.action_attack("right",false,false,0)) == "attack_whoosh", "A1 uses its own cue")
	check(Cues.primary_cue(Cues.Data.action_attack("right",false,false,1)) == "attack_reverse", "A2 uses its own cue")
	check(Cues.primary_cue(Cues.Data.action_attack("up",false,false)) == "attack_up", "Up slash uses its own cue")
	check(Cues.primary_cue(Cues.Data.action_attack("down",false,false)) == "attack_down", "Down slash uses its own cue")
	game.audio_enabled = true
	game._reset_player(Vector2(610, 600))
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
	print("Short audio bank validation with %d failures" % failures)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
