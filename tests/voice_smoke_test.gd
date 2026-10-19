extends SceneTree
## Запуск: godot --headless --path . --script tests/voice_smoke_test.gd
## Для системного голоса: без --headless, с -- --native-tts.

const MAIN_SCENE = preload("res://scenes/main.tscn")
const Progress = preload("res://scripts/data/progress_store.gd")
const TEST_SAVE: String = "res://.godot/test_progress.cfg"

class VoiceProbe extends "res://scripts/audio/voice_controller.gd":
	var spoken: Array[String] = []
	var recorded: Array[String] = []

	func _play_letter(symbol: String) -> void:
		assert(letter_paths.has(symbol.to_lower()))
		recorded.append(symbol)
		spoken.append(symbol)

	func speak(text: String) -> void:
		speech_id += 1
		spoken.append(text)

class MainProbe extends "res://scripts/main.gd":
	func _create_voice_controller() -> Node:
		return VoiceProbe.new()

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	# При падении assert завершаем процесс с ошибкой, а не оставляем его висеть.
	create_timer(35.0).timeout.connect(func(): quit(1))
	assert(ProjectSettings.get_setting("audio/general/text_to_speech"))
	var game = MAIN_SCENE.instantiate()
	game.set_script(MainProbe)
	game.progress.save_path = TEST_SAVE
	root.add_child(game)
	game.audio.music_player.stop()
	game.progress.unlocked_level = 20
	var checked_units: int = 0
	var checked_words: int = 0
	for level_number in range(1, 21):
		game.select_level(level_number)
		for word_index in range(5):
			game.session.word_index = word_index
			game.session.active = true
			game.session.load_word()
			game._start_word()
			var data = game.session.word_data()
			var word: String = game.session.full_word()
			for index in range(len(data)):
				assert(game.voice.spoken.back() == data[index])
				assert(game.voice.repeat_as_letter == (level_number <= 10))
				assert(not game.voice.repeat_timer.is_stopped())
				game._on_symbol_selected(data[index])
				checked_units += 1
			assert(game.voice.spoken.back() == word)
			assert(game.session.transitioning)
			assert(game.voice.repeat_timer.is_stopped())
			game.show_main_menu()
			checked_words += 1
	await create_timer(1.3).timeout
	assert(game.session.word_index == 4)
	assert(not game.session.active)
	print("PASS: ", checked_units, " units and ", checked_words, " words across all 20 levels; canceled transitions")

	# Кнопки связаны с номерами явно, закрытые уровни не запускаются.
	game.progress.unlocked_level = 1
	game.show_main_menu()
	assert(not game.view.grid.get_child(0).disabled)
	assert(game.view.grid.get_child(10).disabled)
	game.select_level(11)
	assert(not game.session.active)
	game.view.grid.get_child(0).pressed.emit()
	assert(game.session.active and game.session.level_index == 0)
	assert(not game.view.menu.visible)
	assert(game.view.hearts.visible)
	assert(game.view.word_label.text.contains("К"))

	# Повтор и остановка речи в меню.
	var previous_count: int = game.voice.spoken.size()
	game.voice._repeat()
	assert(game.voice.spoken.size() == previous_count + 1)
	game.show_main_menu()
	game.voice._repeat()
	assert(game.voice.spoken.size() == previous_count + 1)
	assert(not game.view.word_label.visible)

	# Реальная сцена шарика: сигнал, зачёт попадания, защита от двойного клика.
	game.select_level(1)
	game.balloons._spawn()
	var balloon = game.balloons.get_child(game.balloons.get_child_count() - 1)
	balloon.letter = "ОШИБКА"
	balloon.selected.emit(balloon.letter, balloon)
	assert(game.session.lives == 4)
	balloon.selected.emit(balloon.letter, balloon)
	assert(game.session.lives == 4)
	game.show_main_menu()
	assert(game.balloons.spawn_timer.is_stopped())
	assert(not balloon.is_processing_input())

	# Завершение уровня сохраняет прогресс, сохраняя старый формат файла.
	game.select_level(1)
	game.session.word_index = 4
	game.session.load_word()
	game.session.unit_index = len(game.session.word_data()) - 1
	game._on_symbol_selected(game.session.target())
	await create_timer(1.3).timeout
	assert(game.progress.unlocked_level == 2)
	assert(not game.session.active)
	var restored = Progress.new(TEST_SAVE)
	restored.load_progress()
	assert(restored.unlocked_level == 2)
	game.show_main_menu()

	# Админка временная; сброс выполняется только при её включении.
	game.enable_admin()
	assert(game.progress.admin_enabled and game.progress.unlocked_level == 20)
	game.disable_admin()
	assert(not game.progress.admin_enabled and game.progress.unlocked_level == 2)
	game.enable_admin()
	game.reset_progress()
	assert(game.progress.unlocked_level == 1 and game.session.lives == 5)
	assert(game.view.grid.get_child(1).disabled)
	game.disable_admin()

	# M переключает музыку, пять ошибок показывают проигрыш.
	var key = InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_M
	game.audio.music_player.play()
	game.game_input._input(key)
	assert(game.audio.music_player.stream_paused)
	game.audio.music_player.stop()
	game.select_level(1)
	for index in range(5):
		game._on_symbol_selected("ОШИБКА")
	assert(game.session.lives == 0 and not game.session.active)
	assert(game.view.game_over_overlay.visible)
	# Старый таймер проигрыша не должен закрывать уже начатую новую партию.
	game.select_level(1)
	await create_timer(2.6).timeout
	assert(game.session.active and not game.view.menu.visible)
	game.show_main_menu()
	game.free()
	print("PASS: menu, input, balloons, lives, win/loss, progress, admin and reset")

	if "--native-tts" in OS.get_cmdline_user_args():
		await check_native_voice()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	quit()

func check_native_voice() -> void:
	var game = MAIN_SCENE.instantiate()
	game.progress.save_path = TEST_SAVE
	root.add_child(game)
	game.audio.music_player.stop()
	game.select_level(1)
	assert(game.voice.letter_player.playing)
	assert(game.voice.letter_player.stream != null)
	assert(game.voice.voice_id.is_empty(), "Letters must not use TTS")
	await create_timer(0.25).timeout
	game.show_main_menu()
	assert(not game.voice.letter_player.playing)
	await create_timer(0.1).timeout
	assert(not DisplayServer.tts_is_speaking() and not game.voice.pending)
	game.progress.unlocked_level = 20
	game.select_level(11)
	assert(game.voice.voice_id != "", "No Russian system voice")
	assert(not game.voice.letter_player.playing)
	await create_timer(0.25).timeout
	assert(DisplayServer.tts_is_speaking())
	game.select_level(6)
	game.session.word_index = 2
	game.session.unit_index = len(game.session.word_data()) - 1
	game._on_symbol_selected(game.session.target())
	assert(game.session.transitioning and game.voice.pending)
	await create_timer(0.25).timeout
	assert(DisplayServer.tts_is_speaking())
	var elapsed: float = 0.0
	while game.session.transitioning and elapsed < 10.0:
		await create_timer(0.1).timeout
		if game.voice.pending and game.session.transitioning:
			assert(game.session.word_index == 2)
		elapsed += 0.1
	assert(game.session.word_index == 3)
	game.show_main_menu()
	game.free()
	print("PASS: recorded letters, native Russian TTS for syllables and words; waits for completion")
