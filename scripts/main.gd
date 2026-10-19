extends Control
## Координатор: связывает состояние партии, интерфейс, звук и ввод.

const Session = preload("res://scripts/gameplay/game_session.gd")
const Progress = preload("res://scripts/data/progress_store.gd")
const View = preload("res://scripts/ui/game_view.gd")
const Voice = preload("res://scripts/audio/voice_controller.gd")
const Audio = preload("res://scripts/audio/game_audio.gd")
const Balloons = preload("res://scripts/gameplay/balloon_spawner.gd")
const GameInput = preload("res://scripts/input/game_input.gd")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")

var session = Session.new()
var progress = Progress.new()
var view: View
var voice: Node
var audio: Audio
var balloons: Balloons
var game_input: GameInput
var settings_menu: SettingsMenu
var settings_store = SettingsMenu.SettingsStore.new()

func _ready() -> void:
	progress.load_progress()
	view = View.new()
	add_child(view)
	view.setup(self)
	voice = _create_voice_controller()
	add_child(voice)
	audio = Audio.new()
	add_child(audio)
	settings_menu = SettingsMenu.new()
	settings_menu.store = settings_store
	add_child(settings_menu)
	settings_menu.setup(self, audio, voice)
	balloons = Balloons.new()
	add_child(balloons)
	game_input = GameInput.new()
	game_input.menu = view.menu
	game_input.settings_panel = settings_menu.panel
	add_child(game_input)
	view.level_selected.connect(select_level)
	balloons.symbol_selected.connect(_on_symbol_selected)
	game_input.music_toggled.connect(audio.toggle_music)
	game_input.admin_enabled.connect(enable_admin)
	game_input.admin_disabled.connect(disable_admin)
	game_input.progress_reset.connect(reset_progress)
	show_main_menu()

func _create_voice_controller() -> Node:
	return Voice.new()

func show_main_menu() -> void:
	session.stop()
	voice.stop()
	balloons.stop()
	view.show_menu(progress.unlocked_level)

func select_level(level_number: int) -> void:
	if settings_menu.panel.visible:
		return
	if level_number < 1 or level_number > progress.unlocked_level or level_number > session.levels.size():
		return
	voice.stop()
	balloons.stop()
	session.start(level_number)
	view.show_game(session.lives)
	_start_word()

func _start_word() -> void:
	view.show_word(session.word_data(), session.unit_index)
	voice.start_repeating(session.target(), session.word_data() is String)
	balloons.start(session.target(), session.word_data() is Array)

func _on_symbol_selected(symbol: String) -> void:
	if not session.active or session.transitioning:
		return
	if symbol != session.target():
		audio.play_error()
		var lost: bool = session.lose_life()
		view.update_hearts(session.lives)
		if lost:
			_end_game(false)
		return
	if session.advance_unit():
		_complete_word()
	else:
		view.show_word(session.word_data(), session.unit_index)
		voice.start_repeating(session.target(), session.word_data() is String)
		balloons.set_target(session.target())

func _complete_word() -> void:
	voice.stop()
	balloons.stop()
	view.show_completed_word(session.full_word())
	voice.speak(session.full_word())
	var run: int = session.run_id
	var completed: bool = await voice.wait_for_word(voice.speech_id)
	if not completed or run != session.run_id or not session.active or not session.transitioning:
		return
	if session.next_word():
		_start_word()
	else:
		_end_game(true)

func _end_game(won: bool) -> void:
	session.stop()
	voice.stop()
	balloons.stop()
	if won:
		progress.complete_level(session.level_index + 1)
		view.show_level_completed()
	else:
		view.show_game_over()
	var run: int = session.run_id
	await get_tree().create_timer(2.5).timeout
	if run == session.run_id:
		show_main_menu()

func enable_admin() -> void:
	if OS.has_feature("mobile"):
		return
	progress.enable_admin()
	session.lives = session.MAX_LIVES
	if session.active:
		view.update_hearts(session.lives)
	view.update_level_buttons(progress.unlocked_level)

func disable_admin() -> void:
	if OS.has_feature("mobile"):
		return
	progress.disable_admin()
	view.update_level_buttons(progress.unlocked_level)

func reset_progress() -> void:
	if OS.has_feature("mobile") or not progress.admin_enabled:
		return
	progress.reset()
	session.reset()
	show_main_menu()
