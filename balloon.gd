extends Area2D

var letter = "А"
var speed = 100 
var is_popping = false

# Словарик со всеми твоими шариками и их лопнувшими версиями
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
	# 1. Задаём текст буквы
	if has_node("Label"):
		$Label.text = letter

	# 2. Выбираем случайный цвет шарика
	var random_index = randi() % balloon_data.size()
	chosen_data = balloon_data[random_index]
	
	# Применяем выбранную картинку к Sprite2D
	if has_node("Sprite2D"):
		$Sprite2D.texture = chosen_data["texture"]

func _process(delta):
	# Движение вверх, пока шарик цел
	if not is_popping:
		position.y -= speed * delta
		
		# Если шарик улетел за верхний край экрана — удаляем
		if position.y < -100:
			queue_free()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		get_tree().call_group("game", "check_letter", letter, self)

# Функция лопания шарика
func pop():
	if is_popping:
		return
		
	is_popping = true # Останавливаем движение
	
	# Прячем целую картинку и букву
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	if has_node("Label"):
		$Label.visible = false
	
	# Если есть узел PopSprite — ставим в него нужный цвет лопнувшего шарика и показываем
	if has_node("PopSprite") and chosen_data != null:
		$PopSprite.texture = chosen_data["pop_texture"]
		$PopSprite.visible = true
	
	# Задержка 0.4 секунды перед удалением
	await get_tree().create_timer(0.4).timeout
	queue_free()
