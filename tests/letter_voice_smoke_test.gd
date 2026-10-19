extends SceneTree

class VoiceProbe extends "res://scripts/audio/voice_controller.gd":
	var synthesized: Array[String] = []

	func speak(text: String) -> void:
		synthesized.append(text)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	create_timer(15.0).timeout.connect(func(): quit(1))
	var voice = VoiceProbe.new()
	root.add_child(voice)
	assert(voice.get_tts_volume() >= voice.volume and voice.get_tts_volume() <= 100)
	var available_voices: Array = [
		{"id": "en", "language": "en_US", "name": "Pavel English"},
		{"id": "irina", "language": "ru_RU", "name": "Microsoft Irina"},
		{"id": "pavel", "language": "ru_RU", "name": "Microsoft Pavel"}
	]
	assert(voice.choose_russian_voice(available_voices) == "pavel")
	available_voices.pop_back()
	assert(voice.choose_russian_voice(available_voices) == "irina")
	assert(voice.choose_russian_voice([available_voices[0]]).is_empty())
	var alphabet: String = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
	for letter in alphabet:
		voice.start_repeating(letter)
		assert(voice.letter_player.playing)
		assert(voice.letter_player.stream is AudioStreamMP3)
		assert(not voice.letter_player.stream.loop)
		assert(voice.synthesized.is_empty())
		assert(not voice.repeat_timer.is_stopped())
		await create_timer(0.03).timeout
	voice.set_volume(0.37)
	assert(voice.get_tts_volume() >= voice.volume and voice.get_tts_volume() <= 100)
	assert(is_equal_approx(voice.letter_player.volume_linear, 0.37))
	voice.stop()
	assert(not voice.letter_player.playing)
	voice.start_repeating("БЕ", false)
	assert(voice.synthesized.back() == "БЕ")
	assert(not voice.letter_player.playing)
	# Однобуквенный слог на уровнях 11–20 также остаётся за системным голосом.
	voice.start_repeating("О", false)
	assert(voice.synthesized.back() == "О")
	assert(not voice.letter_player.playing)
	voice.start_repeating("А")
	voice.letter_player.stop()
	voice._repeat()
	assert(voice.letter_player.playing)
	await create_timer(0.03).timeout
	voice.set_volume(0.0)
	assert(voice.get_tts_volume() == 0)
	assert(not voice.letter_player.playing)
	voice.start_repeating("Б")
	assert(not voice.letter_player.playing)
	voice.stop()
	voice.set_volume(1.0)
	assert(voice.get_tts_volume() == 100)
	assert(is_equal_approx(voice.letter_player.volume_linear, 1.0))
	voice.free()
	await create_timer(0.1).timeout
	print("PASS: all 33 letter recordings, repeats, volume, mute and synthesized syllables")
	quit()
