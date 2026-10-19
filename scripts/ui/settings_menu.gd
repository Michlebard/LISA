extends Node
## Открытие окна, предварительное прослушивание и сохранение громкости.

const SettingsStore = preload("res://scripts/data/settings_store.gd")

var store = SettingsStore.new()
var panel: Control
var music_slider: HSlider
var sound_slider: HSlider
var blocker: Control
var audio: Node
var voice: Node

func setup(screen: Control, game_audio: Node, game_voice: Node) -> void:
	audio = game_audio
	voice = game_voice
	panel = screen.get_node("%SettingContainer")
	music_slider = screen.get_node("%MusicSlider")
	sound_slider = screen.get_node("%SoundSlider")
	for slider in [music_slider, sound_slider]:
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 1.0
	screen.get_node("%SettingButton").pressed.connect(open)
	screen.get_node("%SaveButton").pressed.connect(save_and_close)
	music_slider.value_changed.connect(_on_music_changed)
	sound_slider.value_changed.connect(_on_sound_changed)
	# Перехватываем клики за окном, чтобы они не запускали уровни под ним.
	blocker = Control.new()
	blocker.name = "SettingsInputBlocker"
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.z_index = 10
	panel.get_parent().add_child(blocker)
	panel.z_index = 11
	store.load_settings()
	_sync_sliders()
	_apply_volumes()
	panel.hide()
	blocker.hide()

func open() -> void:
	_sync_sliders()
	_apply_volumes()
	blocker.show()
	panel.show()
	music_slider.grab_focus()

func save_and_close() -> void:
	store.music_volume = music_slider.value / 100.0
	store.sound_volume = sound_slider.value / 100.0
	var error = store.save_settings()
	if error != OK:
		push_warning("Не удалось сохранить настройки: " + error_string(error))
		return
	panel.hide()
	blocker.hide()

func _sync_sliders() -> void:
	music_slider.set_value_no_signal(store.music_volume * 100.0)
	sound_slider.set_value_no_signal(store.sound_volume * 100.0)

func _apply_volumes() -> void:
	_on_music_changed(music_slider.value)
	_on_sound_changed(sound_slider.value)

func _on_music_changed(value: float) -> void:
	audio.set_music_volume(value / 100.0)

func _on_sound_changed(value: float) -> void:
	audio.set_sound_volume(value / 100.0)
	voice.set_volume(value / 100.0)
