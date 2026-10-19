extends RefCounted
## Сохранённый прогресс и временный доступ администратора.

const SAVE_FILE_PATH: String = "user://save_data.cfg"
const LEVEL_COUNT: int = 20

var unlocked_level: int = 1
var admin_enabled: bool = false
var save_path: String

func _init(path: String = SAVE_FILE_PATH) -> void:
	save_path = path

func load_progress() -> void:
	var config = ConfigFile.new()
	unlocked_level = 1
	if config.load(save_path) == OK:
		unlocked_level = clampi(int(config.get_value("Progress", "unlocked_level", 1)), 1, LEVEL_COUNT)

func save_progress() -> void:
	var config = ConfigFile.new()
	config.set_value("Progress", "unlocked_level", unlocked_level)
	var error = config.save(save_path)
	if error != OK:
		push_warning("Не удалось сохранить прогресс: " + error_string(error))

func complete_level(level_number: int) -> void:
	if level_number >= unlocked_level and unlocked_level < LEVEL_COUNT:
		unlocked_level = level_number + 1
		save_progress()

func enable_admin() -> void:
	admin_enabled = true
	unlocked_level = LEVEL_COUNT

func disable_admin() -> void:
	admin_enabled = false
	load_progress()

func reset() -> void:
	unlocked_level = 1
	save_progress()
