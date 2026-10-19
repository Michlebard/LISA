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
	game.get_node("%SettingButton").pressed.emit()
	assert(settings.panel.visible and settings.blocker.visible)
	game.select_level(1)
	assert(not game.session.active)
	settings.music_slider.value = 23
	settings.sound_slider.value = 37
	assert(is_equal_approx(game.audio.music_player.volume_linear, 0.23))
	assert(is_equal_approx(game.audio.error_player.volume_linear, 0.37))
	assert(game.voice.volume == 37)
	assert(not FileAccess.file_exists(TEST_PATH))
	game.get_node("%SaveButton").pressed.emit()
	assert(not settings.panel.visible and not settings.blocker.visible)
	var restored = SettingsStore.new(TEST_PATH)
	restored.load_settings()
	assert(is_equal_approx(restored.music_volume, 0.23))
	assert(is_equal_approx(restored.sound_volume, 0.37))
	# Новый экземпляр игры применяет сохранённые настройки к звуку и интерфейсу.
	game.free()
	game = MAIN_SCENE.instantiate()
	game.settings_store.save_path = TEST_PATH
	root.add_child(game)
	await create_timer(0.05).timeout
	game.audio.music_player.stop()
	settings = game.settings_menu
	assert(settings.music_slider.value == 23)
	assert(settings.sound_slider.value == 37)
	assert(game.voice.volume == 37)
	assert(is_equal_approx(game.audio.music_player.volume_linear, 0.23))
	# Нулевая громкость действительно выключает музыку, эффекты и речь.
	game.get_node("%SettingButton").pressed.emit()
	settings.music_slider.value = 0
	settings.sound_slider.value = 0
	assert(is_zero_approx(game.audio.music_player.volume_linear))
	assert(is_zero_approx(game.audio.error_player.volume_linear))
	assert(game.voice.volume == 0)
	game.voice.speak("Проверка")
	assert(not game.voice.pending)
	game.get_node("%SaveButton").pressed.emit()
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
