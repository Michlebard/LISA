extends Node
## Отображение меню, слова, жизней и результата. Правила игры сюда не входят.

signal level_selected(level_number: int)

var screen: Control
var menu: Control
var grid: GridContainer
var hearts: Label
var word_label: RichTextLabel
var game_over_overlay: ColorRect

func setup(root: Control) -> void:
	screen = root
	menu = screen.get_node("ColorRect/MainMenu")
	grid = menu.get_node("%LevelsContainer")
	hearts = screen.get_node("HeartsLabel")
	for index in range(grid.get_child_count()):
		grid.get_child(index).pressed.connect(_select_level.bind(index + 1))
	menu.resized.connect(update_menu_layout)
	_create_word_label()
	_create_game_over_overlay()
	update_menu_layout()

func _select_level(level_number: int) -> void:
	level_selected.emit(level_number)

func update_menu_layout() -> void:
	var available_width: float = maxf(menu.size.x - 64.0, 1.0)
	var font_size: int = int(clampf(available_width / 12.0, 24.0, 37.0))
	grid.add_theme_font_size_override("font_size", font_size)
	var button_width: float = 1.0
	for button in grid.get_children():
		button_width = maxf(button_width, button.get_combined_minimum_size().x)
	var separation: int = grid.get_theme_constant("h_separation")
	grid.columns = clampi(int((available_width + separation) / (button_width + separation)), 1, 5)

func update_level_buttons(unlocked_level: int) -> void:
	for index in range(grid.get_child_count()):
		var button = grid.get_child(index)
		button.disabled = index + 1 > unlocked_level
		button.modulate = Color(0.5, 0.5, 0.5, 0.6) if button.disabled else Color.WHITE

func show_menu(unlocked_level: int) -> void:
	menu.show()
	word_label.hide()
	hearts.hide()
	game_over_overlay.hide()
	update_level_buttons(unlocked_level)

func show_game(lives: int) -> void:
	menu.hide()
	game_over_overlay.hide()
	update_hearts(lives)

func update_hearts(lives: int) -> void:
	hearts.text = "❤️".repeat(lives)
	hearts.show()

func show_word(data: Variant, unit_index: int) -> void:
	var text: String = ""
	for index in range(len(data)):
		var color: String = "red" if index < unit_index else "#FFD700"
		text += "[color=" + color + "]" + data[index] + "[/color]"
		if data is Array and index < data.size() - 1:
			text += "[color=#FFD700]-[/color]"
	word_label.text = "[center]" + text + "[/center]"
	word_label.show()
	word_label.move_to_front()

func show_completed_word(word: String) -> void:
	_show_success("👍 " + word + "!")

func show_level_completed() -> void:
	_show_success("УРОВЕНЬ ПРОЙДЕН!")
	hearts.hide()

func show_game_over() -> void:
	word_label.hide()
	game_over_overlay.show()

func _show_success(text: String) -> void:
	word_label.text = "[center][color=green]" + text + "[/color][/center]"
	word_label.show()
	word_label.move_to_front()

func _create_word_label() -> void:
	word_label = RichTextLabel.new()
	word_label.name = "DynamicWordLabel"
	word_label.bbcode_enabled = true
	word_label.scroll_active = false
	word_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	word_label.clip_contents = false
	word_label.anchor_right = 1.0
	word_label.anchor_bottom = 0.2
	word_label.offset_top = 25
	word_label.add_theme_font_size_override("normal_font_size", 56)
	word_label.add_theme_color_override("default_color", Color.WHITE)
	word_label.add_theme_color_override("font_outline_color", Color.BLACK)
	word_label.add_theme_constant_override("outline_size", 12)
	word_label.z_index = 100
	screen.add_child(word_label)

func _create_game_over_overlay() -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.name = "GameOverOverlay"
	game_over_overlay.color = Color(0, 0, 0, 0.75)
	game_over_overlay.anchor_right = 1.0
	game_over_overlay.anchor_bottom = 1.0
	game_over_overlay.z_index = 200
	var label = Label.new()
	label.text = "ИГРА ОКОНЧЕНА!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.add_theme_font_size_override("font_size", 48)
	game_over_overlay.add_child(label)
	screen.add_child(game_over_overlay)
