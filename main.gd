# ЭТОТ КОД ПИШЕМ В СКРИПТЕ MAIN.GD

extends Node2D

var balloon_scene = null

# Наш алфавит — буквы будут выбираться случайно для каждого шарика
var alphabet = ["А", "Б", "В", "Г", "Д", "Е", "Ж", "З", "И", "К", "Л", "М", "Н", "О", "П", "Р", "С"]
var current_target = ""

func _ready():
	# Загружаем сцену шарика (с проверкой имени файла)
	if ResourceLoader.exists("res://balloon.tscn"):
		balloon_scene = load("res://balloon.tscn")
	elif ResourceLoader.exists("res://Balloon.tscn"):
		balloon_scene = load("res://Balloon.tscn")
	
	next_task()

# Загадываем букву, которую нужно искать
func next_task():
	alphabet.shuffle()
	current_target = alphabet[0]
	print("Ищем букву: ", current_target)

# Эта функция срабатывает каждый раз по таймеру
func _on_timer_timeout():
	if balloon_scene == null:
		print(" Ошибка: Файл balloon.tscn не найден!")
		return

	# 1. Создаём новый шарик
	var balloon = balloon_scene.instantiate()
	
	# 2. Даём ему случайную букву из алфавита
	var random_letter = alphabet[randi() % alphabet.size()]
	balloon.letter = random_letter
	
	# 3. Даём ему случайную скорость (чтобы они не летели одинаково)
	balloon.speed = randf_range(90, 170)
	
	# 4. Спавним в случайном месте по ширине экрана внизу
	balloon.position = Vector2(randf_range(100, 700), 650)
	
	# 5. Добавляем шарик на экран
	add_child(balloon)

# Проверка клика по шарику
func check_letter(pressed_letter, balloon_object):
	if pressed_letter == current_target:
		balloon_object.pop()
		next_task()
