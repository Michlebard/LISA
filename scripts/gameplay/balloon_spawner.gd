extends Node2D
## Создаёт шарики и сообщает о выборе через сигнал, не зная правил игры.

signal symbol_selected(symbol: String)

const BALLOON_SCENE = preload("res://scenes/balloon.tscn")
const EXTRA_SYLLABLES: Array[String] = [
	"МА", "ПА", "БА", "ТА", "КО", "СИ", "МУ", "ЛА", "РА", "ДО",
	"КА", "ЛО", "НИ", "ША", "ШКА", "ЧКА", "ЛИ", "НО", "ВА", "ГА"
]
const ALPHABET: String = "АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЭЮЯ"

var target_symbol: String = ""
var syllable_mode: bool = false
var spawn_timer: Timer

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0
	spawn_timer.timeout.connect(_spawn)
	add_child(spawn_timer)

func start(symbol: String, use_syllables: bool) -> void:
	target_symbol = symbol
	syllable_mode = use_syllables
	spawn_timer.start()

func set_target(symbol: String) -> void:
	target_symbol = symbol

func stop() -> void:
	spawn_timer.stop()
	for balloon in get_children():
		if balloon is Area2D:
			# Отключаем ввод сразу: queue_free удаляет только в конце кадра.
			balloon.set_process_input(false)
			balloon.queue_free()

func _spawn() -> void:
	if spawn_timer.is_stopped() or target_symbol.is_empty():
		return
	var symbol: String = target_symbol
	if randf() >= 0.6:
		symbol = EXTRA_SYLLABLES.pick_random() if syllable_mode else ALPHABET[randi() % ALPHABET.length()]
	var balloon = BALLOON_SCENE.instantiate()
	balloon.letter = symbol
	balloon.speed = randf_range(90, 160)
	var screen = get_viewport_rect().size
	balloon.position = Vector2(randf_range(100, screen.x - 100), screen.y + 50)
	balloon.selected.connect(_on_balloon_selected)
	add_child(balloon)

func _on_balloon_selected(symbol: String, balloon: Area2D) -> void:
	if spawn_timer.is_stopped() or balloon.is_popping or balloon.has_meta("already_popped"):
		return
	balloon.set_meta("already_popped", true)
	balloon.pop()
	symbol_selected.emit(symbol)
