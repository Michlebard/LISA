extends Node
## Горячие клавиши и переключение музыки кликом в нижних углах меню.

signal music_toggled
signal admin_enabled
signal admin_disabled
signal progress_reset

var menu: Control
var settings_panel: Control

func _input(event: InputEvent) -> void:
	if menu.visible and (settings_panel == null or not settings_panel.visible) and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var screen = get_viewport().get_visible_rect().size
		if event.position.y >= screen.y - 150 and (event.position.x <= 150 or event.position.x >= screen.x - 150):
			music_toggled.emit()
			get_viewport().set_input_as_handled()
			return
	if not event is InputEventKey or not event.pressed or event.is_echo():
		return
	if event.physical_keycode == KEY_M:
		music_toggled.emit()
		return
	if OS.has_feature("mobile"):
		return
	if _matches(event, KEY_1, KEY_KP_1):
		admin_enabled.emit()
	elif _matches(event, KEY_2, KEY_KP_2):
		admin_disabled.emit()
	elif _matches(event, KEY_3, KEY_KP_3):
		progress_reset.emit()
	else:
		return
	get_viewport().set_input_as_handled()

func _matches(event: InputEventKey, key: Key, keypad_key: Key) -> bool:
	return event.physical_keycode == key or event.keycode == key or event.keycode == keypad_key
