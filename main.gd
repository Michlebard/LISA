extends Node2D

@export var word_label: Label
@export var hearts_label: Label

var balloon_scene = null

# Путь к файлу сохранения на компьютере
const SAVE_FILE_PATH = "user://save_data.cfg"

# 100 слов на 20 уровней
# Уровни 1-10: Буквы
# Уровни 11-20: Слоги
var levels = [
	# --- УРОВНИ 1 - 10 (По буквам) ---
	["КОТ", "ДОМ", "СОН", "ЛЕС", "МЯЧ"],                                # Уровень 1
	["МАК", "НОС", "РОТ", "СЫР", "ЧАЙ"],                                # Уровень 2
	["СУП", "СОК", "ЛЕВ", "КИТ", "ДУБ"],                                # Уровень 3
	["МЕД", "УХО", "ЭХО", "ЛЕТО", "НЕБО"],                              # Уровень 4
	["МАМА", "ПАПА", "ВОДА", "РЫБА", "РУКА"],                            # Уровень 5
	["СТРЕКОЗА", "СКОВОРОДА", "ВЫКЛЮЧАТЕЛЬ", "ВЕЛОСИПЕД", "ПОЛОТЕНЦЕ"],  # Уровень 6
	["БИНОКЛЬ", "КОМПЬЮТЕР", "МАРГАРИТКА", "ПРИКЛЮЧЕНИЕ", "ВОДОПРОВОД"],  # Уровень 7
	["ВЕЗДЕХОД", "ПОДСОЛНУХ", "БУТЕРБРОД", "ТЕЛЕВИЗОР", "КАРАНДАШ"],      # Уровень 8
	["ИГРУШКА", "ЭКСКУРСИЯ", "ПУТЕШЕСТВИЕ", "СМОРОДИНА", "ШОКОЛАД"],       # Уровень 9
	["ПРАЗДНИК", "СНЕЖИНКА", "ТЕЛЕФОН", "АВТОБУС", "ДИНОЗАВР"],            # Уровень 10

	# --- УРОВНИ 11 - 20 (По слогам) ---
	[["БЕ", "ЛОЧ", "КА"], ["КА", "РАН", "ДАШ"], ["КАР", "ТИН", "КА"], ["ПО", "ДУШ", "КА"], ["ИГ", "РУШ", "КА"]],         # Уровень 11
	[["ТЕТ", "РАДЬ"], ["О", "БЕЗЬ", "Я", "НА"], ["ЛО", "ПАТ", "КА"], ["АВ", "ТО", "БУС"], ["СА", "МО", "ЛЁТ"]],          # Уровень 12
	[["О", "ДУ", "ВАН", "ЧИК"], ["КРО", "ВАТ", "КА"], ["ПО", "ДРУЖ", "КА"], ["МЕД", "ВЕ", "ЖО", "НОК"], ["СИ", "НИЧ", "КА"]], # Уровень 13
	[["ПО", "ДА", "РОК"], ["ЗВЁЗ", "ДОЧ", "КА"], ["КЛУБ", "НИ", "КА"], ["ТРО", "ПИН", "КА"], ["ВО", "РО", "БЕЙ"]],       # Уровень 14
	[["КОМ", "НА", "ТА"], ["ТА", "РЕЛ", "КА"], ["РУЧ", "КА"], ["ЗЕР", "КА", "ЛО"], ["КАС", "ТРЮ", "ЛЯ"]],                # Уровень 15
	[["КО", "РОВ", "КА"], ["КОН", "ФЕТ", "КА"], ["ПО", "СЫЛ", "КА"], ["СА", "ПОЖ", "КИ"], ["СНЕ", "ЖИН", "КА"]],         # Уровень 16
	[["РЫ", "БАЛ", "КА"], ["КОР", "ЗИН", "КА"], ["РО", "МАШ", "КА"], ["ТРАМ", "ВАЙ", "ЧИК"], ["КУ", "БИК"]],              # Уровень 17
	[["ПИ", "РА", "МИД", "КА"], ["ЗА", "НА", "ВЕС", "КА"], ["ЛАС", "ТОЧ", "КА"], ["КО", "ЛО", "КОЛЬ", "ЧИК"], ["ПО", "ДУ", "ШЕЧ", "КА"]], # Уровень 18
	[["СО", "СУЛЬ", "КА"], ["МОР", "КОВ", "КА"], ["КА", "ЧЕ", "ЛИ"], ["СТО", "ЛО", "ВА", "Я"], ["КАР", "ТОШ", "КА"]],     # Уровень 19
	[["КА", "ПУС", "ТА"], ["ФОН", "ТАН", "ЧИК"], ["СКА", "МЕЙ", "КА"], ["КАР", "МАН", "ЧИК"], ["МО", "РО", "ЖЕ", "НО", "Е"]] # Уровень 20
]

var current_level_index = 0
var current_word_index = 0
var current_word_data = null
var current_unit_index = 0
var current_target_symbol = ""

var is_game_active = false
var is_transitioning = false 

# Система прогресса
var unlocked_level = 1

# Жизни
var max_lives = 5
var current_lives = 5

# Таймер голоса
var voice_timer: Timer

func _ready():
	load_game()
	
	if ResourceLoader.exists("res://balloon.tscn"):
		balloon_scene = load("res://balloon.tscn")
	elif ResourceLoader.exists("res://Balloon.tscn"):
		balloon_scene = load("res://Balloon.tscn")
	
	setup_custom_cursor()
	setup_voice_timer()
	find_labels_automatically()
	get_or_create_word_label()
	show_main_menu()

# --- СИСТЕМА СОХРАНЕНИЯ И ЗАГРУЗКИ ---

func save_game():
	var config = ConfigFile.new()
	config.set_value("Progress", "unlocked_level", unlocked_level)
	config.save(SAVE_FILE_PATH)
	print("Прогресс сохранён! Открыт уровень: ", unlocked_level)

func load_game():
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE_PATH)
	if err == OK:
		unlocked_level = config.get_value("Progress", "unlocked_level", 1)
		print("Прогресс успешно загружен! Открытый уровень: ", unlocked_level)
	else:
		unlocked_level = 1
		print("Файл сохранения не найден. Начинаем с 1 уровня.")

# --- ПОИСК КАРТИНКИ ДРОТИКА ---

func get_dart_texture() -> Texture2D:
	var paths = [
		"res://dart.png", "res://dart.png.png", "res://dart.jpg", "res://dart.JPG", "res://dart.PNG",
		"res://Броцик.png", "res://броцик.png", "res://Броцик.jpg", "res://броцик.jpg", "res://Броцик.png.png"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func setup_custom_cursor():
	var dart_tex = get_dart_texture()
	if dart_tex != null:
		Input.set_custom_mouse_cursor(dart_tex, Input.CURSOR_ARROW, Vector2(16, 0))

# --- СИСТЕМА БЛОКИРОВКИ КНОПОК УРОВНЕЙ ---

func update_level_buttons():
	var btns = []
	get_all_children_of_type(self, "Button", btns)
	
	for b in btns:
		var b_name = b.name.to_lower()
		var b_text = b.text.to_lower()
		var lvl_num = 0
		
		for i in range(20, 0, -1):
			var s = str(i)
			if s in b_name or s in b_text:
				lvl_num = i
				break
		
		if lvl_num > 0:
			if lvl_num <= unlocked_level:
				b.disabled = false
				b.modulate = Color(1, 1, 1, 1)
			else:
				b.disabled = true
				b.modulate = Color(0.5, 0.5, 0.5, 0.6)

# --- НАСТРОЙКА ТАЙМЕРА ГОЛОСА ---

func setup_voice_timer():
	voice_timer = Timer.new()
	voice_timer.name = "VoiceRepeatTimer"
	voice_timer.wait_time = 1.8
	voice_timer.timeout.connect(_on_voice_timer_timeout)
	add_child(voice_timer)

func _on_voice_timer_timeout():
	if is_game_active and not is_transitioning and current_target_symbol != "":
		play_letter_sound(current_target_symbol)

func start_voice_repetition():
	if voice_timer:
		play_letter_sound(current_target_symbol)
		voice_timer.start()

func stop_voice_repetition():
	if voice_timer:
		voice_timer.stop()

# --- ТЕКСТ СЛОВА И НАДПИСИ ---

func get_or_create_word_label() -> Label:
	if word_label != null and is_instance_valid(word_label):
		return word_label
		
	var existing = find_node_by_name(self, "DynamicWordLabel") as Label
	if existing != null:
		word_label = existing
		return word_label
		
	var new_lbl = Label.new()
	new_lbl.name = "DynamicWordLabel"
	new_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	new_lbl.custom_minimum_size = Vector2(400, 60)
	var viewport_width = get_viewport_rect().size.x
	if viewport_width > 0:
		new_lbl.position = Vector2((viewport_width - 400) / 2, 30)
	else:
		new_lbl.position = Vector2(200, 30)
		
	new_lbl.add_theme_font_size_override("font_size", 48)
	new_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0))
	new_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	new_lbl.add_theme_constant_override("outline_size", 8)
	
	add_child(new_lbl)
	word_label = new_lbl
	return word_label

func find_labels_automatically():
	var all_labels = []
	get_all_children_of_type(self, "Label", all_labels)
	get_all_children_of_type(self, "RichTextLabel", all_labels)
	
	for l in all_labels:
		var name_lower = l.name.to_lower()
		if ("heart" in name_lower or "life" in name_lower or "жизн" in name_lower) and hearts_label == null:
			hearts_label = l

func get_all_children_of_type(node: Node, type_name: String, arr: Array):
	if node.is_class(type_name) or node.get_class() == type_name:
		arr.append(node)
	for c in node.get_children():
		get_all_children_of_type(c, type_name, arr)

func find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name.to_lower() == target_name.to_lower():
		return node
	for child in node.get_children():
		var res = find_node_by_name(child, target_name)
		if res != null:
			return res
	return null

func set_buttons_visible(v: bool):
	var btns = []
	get_all_children_of_type(self, "Button", btns)
	for b in btns:
		b.visible = v

func show_main_menu():
	is_game_active = false
	is_transitioning = false
	stop_voice_repetition()
	clear_all_balloons()
	hide_game_over_screen()
	
	set_buttons_visible(true)
	update_level_buttons()
	
	var w_lbl = get_or_create_word_label()
	if w_lbl: w_lbl.visible = false
	if hearts_label: hearts_label.visible = false

# --- ИГРОВОЙ ПРОЦЕСС ---

func select_level(level_num: int):
	if level_num > unlocked_level:
		return
		
	current_level_index = level_num - 1
	current_word_index = 0
	current_lives = max_lives
	
	set_buttons_visible(false)
	hide_game_over_screen()
	
	var w_lbl = get_or_create_word_label()
	if w_lbl:
		w_lbl.visible = true
		
	if hearts_label:
		hearts_label.visible = true
		
	update_hearts_display()
	is_game_active = true
	is_transitioning = false
	start_next_word()

func start_next_word():
	if not is_game_active:
		return
		
	if current_word_index < levels[current_level_index].size():
		current_word_data = levels[current_level_index][current_word_index]
		current_unit_index = 0
		
		var display_text = ""
		if typeof(current_word_data) == TYPE_ARRAY:
			current_target_symbol = current_word_data[0]
			for i in range(current_word_data.size()):
				display_text += current_word_data[i]
				if i < current_word_data.size() - 1:
					display_text += "-"
		else:
			current_target_symbol = current_word_data[0]
			display_text = current_word_data
		
		var w_lbl = get_or_create_word_label()
		if w_lbl:
			w_lbl.text = display_text
			w_lbl.visible = true
			
		is_transitioning = false
		start_voice_repetition()
	else:
		finish_level()

func advance_symbol():
	current_unit_index += 1
	
	var total_units = 0
	if typeof(current_word_data) == TYPE_ARRAY:
		total_units = current_word_data.size()
	else:
		total_units = current_word_data.length()
	
	if current_unit_index < total_units:
		if typeof(current_word_data) == TYPE_ARRAY:
			current_target_symbol = current_word_data[current_unit_index]
		else:
			current_target_symbol = current_word_data[current_unit_index]
		start_voice_repetition()
	else:
		is_transitioning = true
		stop_voice_repetition()
		clear_all_balloons()
		
		var full_word = ""
		if typeof(current_word_data) == TYPE_ARRAY:
			for s in current_word_data:
				full_word += s
		else:
			full_word = current_word_data
		
		var w_lbl = get_or_create_word_label()
		if w_lbl:
			w_lbl.text = "👍 " + full_word + "!"
			
		await get_tree().create_timer(1.2).timeout
		
		if is_game_active:
			current_word_index += 1
			start_next_word()

func update_hearts_display():
	if hearts_label:
		var txt = ""
		for i in range(current_lives):
			txt += "❤️"
		hearts_label.text = txt
		hearts_label.visible = true

# --- ЭКРАН ПРОИГРЫША / ПОБЕДЫ ---

func show_game_over_screen():
	var overlay = find_node_by_name(self, "GameOverOverlay")
	if overlay == null:
		overlay = ColorRect.new()
		overlay.name = "GameOverOverlay"
		overlay.color = Color(0, 0, 0, 0.75)
		overlay.size = get_viewport_rect().size
		
		var label = Label.new()
		label.name = "GameOverText"
		label.text = "ИГРА ОКОНЧЕНА!"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = overlay.size
		label.add_theme_font_size_override("font_size", 48)
		
		overlay.add_child(label)
		add_child(overlay)
	else:
		overlay.visible = true

func hide_game_over_screen():
	var overlay = find_node_by_name(self, "GameOverOverlay")
	if overlay:
		overlay.visible = false

func game_over():
	is_game_active = false
	is_transitioning = false
	stop_voice_repetition()
	clear_all_balloons()
	
	var w_lbl = get_or_create_word_label()
	if w_lbl: w_lbl.visible = false
	
	show_game_over_screen()
	
	await get_tree().create_timer(2.5).timeout
	show_main_menu()

func finish_level():
	is_game_active = false
	is_transitioning = false
	stop_voice_repetition()
	clear_all_balloons()
	
	var completed_level = current_level_index + 1
	if completed_level >= unlocked_level and unlocked_level < 20:
		unlocked_level = completed_level + 1
		save_game()
	
	var w_lbl = get_or_create_word_label()
	if w_lbl:
		w_lbl.text = "УРОВЕНЬ ПРОЙДЕН!"
		w_lbl.visible = true
	if hearts_label: hearts_label.visible = false
	
	await get_tree().create_timer(2.5).timeout
	show_main_menu()

# --- СПАВН ШАРИКОВ С ПОДДЕРЖКОЙ СЛОГОВ ---

func _on_timer_timeout():
	if not is_game_active or is_transitioning or balloon_scene == null:
		return

	var balloon = balloon_scene.instantiate()
	
	var random_symbol = ""
	if randf() < 0.6 and current_target_symbol != "":
		random_symbol = current_target_symbol
	else:
		if typeof(current_word_data) == TYPE_ARRAY:
			# Набор случайных слогов для помех
			var extra_syllables = [
				"МА", "ПА", "БА", "ТА", "КО", "СИ", "МУ", "ЛА", "РА", "ДО",
				"КА", "ЛО", "НИ", "ША", "ШКА", "ЧКА", "ЛИ", "НО", "ВА", "ГА"
			]
			random_symbol = extra_syllables[randi() % extra_syllables.size()]
		else:
			# Набор букв для 1-10 уровней
			var alphabet = "АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЭЮЯ"
			random_symbol = alphabet[randi() % alphabet.length()]
	
	if "letter" in balloon:
		balloon.letter = random_symbol
		
	# Стандартная удобная скорость полета для всех уровней
	balloon.speed = randf_range(90, 160)
		
	balloon.position = Vector2(randf_range(100, 700), 650)
	balloon.add_to_group("balloons")
	add_child(balloon)
	
	var balloon_label = find_node_by_name(balloon, "Label")
	if balloon_label and "text" in balloon_label:
		balloon_label.text = random_symbol

func clear_all_balloons():
	for b in get_tree().get_nodes_in_group("balloons"):
		b.queue_free()

# --- ЗВУКИ И АНИМАЦИЯ ДРОТИКА ---

func play_letter_sound(symbol_name: String):
	if symbol_name == "":
		return
		
	var audio_player = find_node_by_name(self, "AudioStreamPlayer") as AudioStreamPlayer
	if audio_player == null:
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "AudioStreamPlayer"
		add_child(audio_player)
		
	var sound_path = "res://sounds/" + symbol_name.to_lower() + ".mp3"
	if not ResourceLoader.exists(sound_path):
		sound_path = "res://sounds/" + symbol_name.to_lower() + ".wav"
		
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		audio_player.stream = sound
		audio_player.play()

func play_error_sound():
	var audio_player = find_node_by_name(self, "AudioStreamPlayer") as AudioStreamPlayer
	if audio_player == null:
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "AudioStreamPlayer"
		add_child(audio_player)
		
	var error_paths = [
		"res://sounds/бзз.mp3", "res://sounds/бзз.wav", "res://sounds/бзз.ogg",
		"res://sounds/бз.mp3", "res://sounds/бз.wav",
		"res://sounds/bzz.mp3", "res://sounds/bzz.wav",
		"res://sounds/error.mp3", "res://sounds/error.wav"
	]
	
	for path in error_paths:
		if ResourceLoader.exists(path):
			var sound = load(path)
			audio_player.stream = sound
			audio_player.play()
			return

func check_letter(pressed_symbol, balloon_object):
	if not is_game_active or is_transitioning:
		return
		
	if balloon_object.has_meta("already_popped"):
		return
	balloon_object.set_meta("already_popped", true)
	
	spawn_dart_and_pop(pressed_symbol, balloon_object)

func spawn_dart_and_pop(pressed_symbol: String, balloon_object: Node2D):
	var dart_tex = get_dart_texture()

	if dart_tex != null and is_instance_valid(balloon_object):
		var dart = Sprite2D.new()
		dart.texture = dart_tex
		dart.z_index = 100
		
		var tex_size = dart_tex.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var max_side = max(tex_size.x, tex_size.y)
			var target_scale = 60.0 / max_side
			dart.scale = Vector2(target_scale, target_scale)

		var start_pos = Vector2(balloon_object.global_position.x, get_viewport_rect().size.y + 60)
		dart.position = start_pos
		
		dart.look_at(balloon_object.global_position)
		dart.rotation += deg_to_rad(90)
		
		add_child(dart)
		
		var tween = create_tween()
		tween.tween_property(dart, "global_position", balloon_object.global_position, 0.1)
		
		await tween.finished
		if is_instance_valid(dart):
			dart.queue_free()

	if is_instance_valid(balloon_object):
		if pressed_symbol == current_target_symbol:
			balloon_object.pop()
			advance_symbol()
		else:
			balloon_object.pop()
			play_error_sound()
			
			current_lives -= 1
			if current_lives < 0:
				current_lives = 0
			update_hearts_display()
			
			if current_lives <= 0:
				game_over()

# --- СИГНАЛЫ КНОПОК ---
func _on_level_1_pressed(): select_level(1)
func _on_level_2_pressed(): select_level(2)
func _on_level_3_pressed(): select_level(3)
func _on_level_4_pressed(): select_level(4)
func _on_level_5_pressed(): select_level(5)
func _on_level_6_pressed(): select_level(6)
func _on_level_7_pressed(): select_level(7)
func _on_level_8_pressed(): select_level(8)
func _on_level_9_pressed(): select_level(9)
func _on_level_10_pressed(): select_level(10)
func _on_level_11_pressed(): select_level(11)
func _on_level_12_pressed(): select_level(12)
func _on_level_13_pressed(): select_level(13)
func _on_level_14_pressed(): select_level(14)
func _on_level_15_pressed(): select_level(15)
func _on_level_16_pressed(): select_level(16)
func _on_level_17_pressed(): select_level(17)
func _on_level_18_pressed(): select_level(18)
func _on_level_19_pressed(): select_level(19)
func _on_level_20_pressed(): select_level(20)
