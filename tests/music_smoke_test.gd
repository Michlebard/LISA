extends SceneTree

const GameAudio = preload("res://scripts/audio/game_audio.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	create_timer(20.0).timeout.connect(func(): quit(1))
	var audio = GameAudio.new()
	root.add_child(audio)
	assert(audio.track_paths.size() >= 2)
	assert(audio.music_player.playing)
	var last_track: String = ""
	for cycle in range(3):
		var played: Array[String] = []
		for index in range(audio.track_paths.size()):
			assert(audio.current_track != last_track)
			assert(not played.has(audio.current_track))
			assert(audio.music_player.stream is AudioStreamMP3)
			assert(not audio.music_player.stream.loop)
			played.append(audio.current_track)
			last_track = audio.current_track
			audio.music_player.finished.emit()
			await create_timer(0.03).timeout
		assert(played.size() == audio.track_paths.size())

	# Пауза не меняет текущий трек, возобновление не сбрасывает позицию.
	await create_timer(0.1).timeout
	var path: String = audio.current_track
	audio.toggle_music()
	var position: float = audio.music_player.get_playback_position()
	await create_timer(0.1).timeout
	assert(audio.music_player.stream_paused and audio.current_track == path)
	assert(absf(audio.music_player.get_playback_position() - position) < 0.02)
	audio.toggle_music()
	assert(not audio.music_player.stream_paused)
	assert(audio.current_track == path)

	# Проверяем настоящий сигнал окончания на коротком звуке вместо длинного MP3.
	var short_stream = AudioStreamWAV.new()
	short_stream.mix_rate = 44100
	short_stream.data = PackedByteArray()
	var samples = PackedByteArray()
	samples.resize(441)
	short_stream.data = samples
	audio.music_player.stream = short_stream
	audio.music_player.play()
	await create_timer(0.3).timeout
	assert(audio.current_track != path)
	assert(audio.music_player.stream is AudioStreamMP3)
	assert(audio.music_player.playing)

	# При единственном треке повторяется он же, пустой список безопасен.
	audio.track_paths.assign([audio.current_track])
	audio._remaining_tracks.clear()
	path = audio.current_track
	audio.music_player.finished.emit()
	assert(audio.current_track == path and audio.music_player.playing)
	audio.track_paths.clear()
	audio._remaining_tracks.clear()
	audio.music_player.stop()
	audio._play_next_track()
	assert(not audio.music_player.playing)
	audio.free()
	await create_timer(0.1).timeout
	print("PASS: shuffled cycles, no adjacent repeats, pause/resume, natural finish, single/empty playlist")
	quit()
