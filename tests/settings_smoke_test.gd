extends SceneTree

const MAIN_SCENE = preload("res://scenes/main.tscn")
const SettingsStore = preload("res://scripts/data/settings_store.gd")
const TEST_PATH: String = "res://.godot/test_settings.cfg"

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	create_timer(15.0).timeout.connect(func(): quit(1))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	var game = MAIN_SCENE.instantiate()
	game.settings_store.save_path = TEST_PATH
	root.add_child(game)
	await create_timer(0.05).timeout
	game.audio.music_player.stop()
	var settings = game.settings_menu
	assert(not settings.panel.visible)
	assert(settings.music_slider.value == 50.0)
	assert(settings.sound_slider.value == 80.0)
	assert(is_equal_approx(game.audio.music_player.volume_linear, 0.5))
	assert(is_equal_approx(game.audio.error_player.volume_linear, 0.8))
	assert(game.voice.volume == 80)
	await click_control(game.get_node("%SettingButton"))
	assert(settings.panel.visible and settings.blocker.visible)
	await click_control(game.view.grid.get_child(0))
	assert(not game.session.active)
	assert(settings.panel.visible)
	await click_control(settings.music_slider, Vector2(0.23, 0.5))
	await click_control(settings.sound_slider, Vector2(0.37, 0.5))
	var chosen_music: float = settings.music_slider.value
	var chosen_sound: float = settings.sound_slider.value
	assert(chosen_music != 50.0 and chosen_sound != 80.0, "Sliders must respond to mouse input")
	assert(is_equal_approx(game.audio.music_player.volume_linear, chosen_music / 100.0))
	assert(is_equal_approx(game.audio.error_player.volume_linear, chosen_sound / 100.0))
	assert(game.voice.volume == roundi(chosen_sound))
	assert(not FileAccess.file_exists(TEST_PATH))
	await click_control(game.get_node("%SaveButton"))
	assert(not settings.panel.visible and not settings.blocker.visible)
	var restored = SettingsStore.new(TEST_PATH)
	restored.load_settings()
	assert(is_equal_approx(restored.music_volume, chosen_music / 100.0))
	assert(is_equal_approx(restored.sound_volume, chosen_sound / 100.0))
	# Новый экземпляр игры применяет сохранённые настройки к звуку и интерфейсу.
	game.free()
	game = MAIN_SCENE.instantiate()
	game.settings_store.save_path = TEST_PATH
	root.add_child(game)
	await create_timer(0.05).timeout
	game.audio.music_player.stop()
	settings = game.settings_menu
	assert(settings.music_slider.value == chosen_music)
	assert(settings.sound_slider.value == chosen_sound)
	assert(game.voice.volume == roundi(chosen_sound))
	assert(is_equal_approx(game.audio.music_player.volume_linear, chosen_music / 100.0))
	# Нулевая громкость действительно выключает музыку, эффекты и речь.
	await click_control(game.get_node("%SettingButton"))
	settings.music_slider.value = 0
	settings.sound_slider.value = 0
	assert(is_zero_approx(game.audio.music_player.volume_linear))
	assert(is_zero_approx(game.audio.error_player.volume_linear))
	assert(game.voice.volume == 0)
	game.voice.speak("Проверка")
	assert(not game.voice.pending)
	await click_control(game.get_node("%SaveButton"))
	# Смена трека сохраняет выбранную громкость.
	game.audio.music_player.finished.emit()
	await create_timer(0.05).timeout
	assert(is_zero_approx(game.audio.music_player.volume_linear))
	game.audio.music_player.stop()
	game.free()
	# Неполные/повреждённые значения не ломают запуск.
	var config = ConfigFile.new()
	config.set_value("Audio", "music_volume", 5.0)
	config.set_value("Audio", "sound_volume", "bad value")
	assert(config.save(TEST_PATH) == OK)
	restored.load_settings()
	assert(restored.music_volume == 1.0 and restored.sound_volume == 0.8)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	await create_timer(0.1).timeout
	print("PASS: settings open/save/close, defaults, live volume, persistence, mute and track changes")
	quit()

func click_control(control: Control, fraction: Vector2 = Vector2(0.5, 0.5)) -> void:
	await process_frame
	var rect: Rect2 = control.get_global_rect()
	var point: Vector2 = rect.position + rect.size * fraction
	var motion = InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event = InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
	await process_frame
