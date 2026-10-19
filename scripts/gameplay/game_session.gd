extends RefCounted
## Состояние одной партии. Не зависит от сцены, звука или сохранений.

const Levels = preload("res://scripts/data/levels_data.gd")
const MAX_LIVES: int = 5

var levels: Array = Levels.LEVELS
var level_index: int = 0
var word_index: int = 0
var unit_index: int = 0
var lives: int = MAX_LIVES
var active: bool = false
var transitioning: bool = false
var run_id: int = 0

func start(level_number: int) -> void:
	run_id += 1
	level_index = level_number - 1
	word_index = 0
	lives = MAX_LIVES
	active = true
	load_word()

func load_word() -> void:
	unit_index = 0
	transitioning = false

func word_data() -> Variant:
	return levels[level_index][word_index]

func target() -> String:
	return word_data()[unit_index]

func full_word() -> String:
	var data = word_data()
	return "".join(data) if data is Array else data

func advance_unit() -> bool:
	unit_index += 1
	transitioning = unit_index >= len(word_data())
	return transitioning

func next_word() -> bool:
	word_index += 1
	if word_index >= levels[level_index].size():
		return false
	load_word()
	return true

func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	return lives == 0

func stop() -> void:
	run_id += 1
	active = false
	transitioning = false

func reset() -> void:
	stop()
	level_index = 0
	word_index = 0
	unit_index = 0
	lives = MAX_LIVES
