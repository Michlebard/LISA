extends Area2D

var letter = "А"
var speed = 100 
var is_popping = false

# Словарик с твоими шариками и их лопнувшими версиями
var balloon_data = [
	{
		"texture": preload("res://blue.png"),
		"pop_texture": preload("res://blue-pop.png")
	},
	{
		"texture": preload("res://green.png"),
		"pop_texture": preload("res://green-pop.png")
	},
	{
		"texture": preload("res://red.png"),
		"pop_texture": preload("res://red-pop.png")
	},
	{
		"texture": preload("res://yellow.png"),
		"pop_texture": preload("res://yellow-pop.png")
	}
]

var chosen_data = null

func _ready():
	# Задаём текст буквы
	if has_node("Label"):
		$Label.text = letter

	# Выбираем случайный цвет шарика
	var random_index = randi() % balloon_data.size()
	chosen_data = balloon_data[random_index]
	
	if has_node("Sprite2D"):
		$Sprite2D.texture = chosen_data["texture"]

func _process(delta):
	if not is_popping:
		position.y -= speed * delta
		if position.y < -100:
			queue_free()

# САМЫЙ НАДЁЖНЫЙ СПОСОБ КЛИКА: проверяем расстояние от клика до центра шарика
func _input(event):
	if is_popping:
		return
		
	# Когда нажата левая кнопка мыши или выполнен тап по экрану
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_position = get_global_mouse_position()
		
		# Проверяем: если расстояние от клика до центра шарика меньше 65 пикселей — считаем, что попали!
		if global_position.distance_to(click_position) <= 65:
			print("Попадание по шарику с буквой: ", letter)
			var main_node = get_tree().current_scene
			if main_node and main_node.has_method("check_letter"):
				main_node.check_letter(letter, self)

# Функция лопания шарика
func pop():
	if is_popping:
		return
		
	is_popping = true
	
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	if has_node("Label"):
		$Label.visible = false
	
	if has_node("PopSprite") and chosen_data != null:
		$PopSprite.texture = chosen_data["pop_texture"]
		$PopSprite.visible = true
	
	await get_tree().create_timer(0.4).timeout
	queue_free()
