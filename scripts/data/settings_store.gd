extends RefCounted
## Настройки звука хранятся отдельно от прогресса уровней.

const SAVE_PATH: String = "user://settings.cfg"
const DEFAULT_MUSIC: float = 0.5
const DEFAULT_SOUND: float = 0.8

var music_volume: float = DEFAULT_MUSIC
var sound_volume: float = DEFAULT_SOUND
var save_path: String

func _init(path: String = SAVE_PATH) -> void:
	save_path = path

func load_settings() -> void:
	music_volume = DEFAULT_MUSIC
	sound_volume = DEFAULT_SOUND
	var config = ConfigFile.new()
	if config.load(save_path) == OK:
		music_volume = _read_volume(config, "music_volume", DEFAULT_MUSIC)
		sound_volume = _read_volume(config, "sound_volume", DEFAULT_SOUND)

func save_settings() -> Error:
	var config = ConfigFile.new()
	config.set_value("Audio", "music_volume", music_volume)
	config.set_value("Audio", "sound_volume", sound_volume)
	return config.save(save_path)

func _read_volume(config: ConfigFile, key: String, default_value: float) -> float:
	var value = config.get_value("Audio", key, default_value)
	if not (value is float or value is int) or not is_finite(float(value)):
		return default_value
	return clampf(float(value), 0.0, 1.0)
