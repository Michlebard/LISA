extends Node
## Записи букв и системный голос для слогов и слов. Повторы и отмена озвучки.

const LETTER_DIRECTORY: String = "res://assets/audio/letters"
const PREFERRED_VOICE_NAME: String = "pavel"
const TTS_VOLUME_MULTIPLIER: float = 1.4

var voice_id: String = ""
var warning_shown: bool = false
var speech_id: int = 0
var pending: bool = false
var repeated_symbol: String = ""
var repeat_timer: Timer
var volume: int = 80
var letter_player: AudioStreamPlayer
var letter_paths: Dictionary = {}
var repeat_as_letter: bool = true

func get_tts_volume() -> int:
	# Системная речь обходит аудиошины Godot; её API принимает только 0–100.
	return clampi(roundi(volume * TTS_VOLUME_MULTIPLIER), 0, 100)

func set_volume(value: float) -> void:
	volume = roundi(clampf(value, 0.0, 1.0) * 100.0)
	if letter_player:
		letter_player.volume_linear = volume / 100.0
	if volume == 0:
		stop()

func _ready() -> void:
	letter_player = AudioStreamPlayer.new()
	letter_player.volume_linear = volume / 100.0
	add_child(letter_player)
	# Индекс хранит точное имя файла: А.mp3 и Б.mp3 начинаются с заглавных букв.
	for file_name in ResourceLoader.list_directory(LETTER_DIRECTORY):
		if file_name.get_extension().to_lower() in ["mp3", "wav", "ogg"]:
			letter_paths[file_name.get_basename().to_lower()] = LETTER_DIRECTORY.path_join(file_name)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_speech_finished)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _on_speech_finished)
	repeat_timer = Timer.new()
	repeat_timer.wait_time = 1.8
	repeat_timer.timeout.connect(_repeat)
	add_child(repeat_timer)

func start_repeating(symbol: String, as_letter: bool = true) -> void:
	stop()
	repeated_symbol = symbol
	repeat_as_letter = as_letter
	_play_repeated_symbol()
	repeat_timer.start()

func stop() -> void:
	if repeat_timer:
		repeat_timer.stop()
	repeated_symbol = ""
	speech_id += 1
	pending = false
	if letter_player:
		letter_player.stop()
	if voice_id != "":
		DisplayServer.tts_stop()

func speak(text: String) -> void:
	if text.is_empty() or volume == 0:
		return
	letter_player.stop()
	# На Android голоса могут стать доступны после асинхронной инициализации.
	if voice_id == "" and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		voice_id = choose_russian_voice(DisplayServer.tts_get_voices())
	if voice_id == "":
		if not warning_shown:
			push_warning("Озвучка недоступна: установите русский голос синтеза речи в настройках устройства.")
			warning_shown = true
		return
	speech_id += 1
	pending = true
	DisplayServer.tts_speak(text.to_lower(), voice_id, get_tts_volume(), 1.0, 0.85, speech_id, true)

func choose_russian_voice(voices: Array) -> String:
	var fallback: String = ""
	for voice in voices:
		var language: String = str(voice.get("language", "")).to_lower().replace("_", "-")
		if language != "ru" and not language.begins_with("ru-"):
			continue
		var id: String = str(voice.get("id", ""))
		if fallback.is_empty():
			fallback = id
		var voice_name: String = str(voice.get("name", "")).to_lower()
		if PREFERRED_VOICE_NAME in voice_name or "павел" in voice_name:
			return id
	# На других устройствах Павла может не быть: сохраняем доступную русскую озвучку.
	return fallback

func wait_for_word(utterance_id: int) -> bool:
	# Сохраняем минимальную паузу успеха и ждём даже отложенного запуска TTS.
	await get_tree().create_timer(1.2).timeout
	var elapsed: float = 1.2
	while pending and speech_id == utterance_id and elapsed < 15.0:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	return speech_id == utterance_id

func _repeat() -> void:
	if repeated_symbol.is_empty() or pending or letter_player.playing:
		return
	if voice_id != "" and DisplayServer.tts_is_speaking():
		return
	_play_repeated_symbol()

func _play_repeated_symbol() -> void:
	if repeat_as_letter:
		_play_letter(repeated_symbol)
	else:
		speak(repeated_symbol)

func _play_letter(symbol: String) -> void:
	if symbol.is_empty() or volume == 0:
		return
	var path: String = letter_paths.get(symbol.to_lower(), "")
	if path.is_empty():
		push_warning("Не найдена запись буквы: " + symbol)
		return
	var stream = load(path).duplicate() as AudioStream
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = false
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	letter_player.stream = stream
	letter_player.play()

func _on_speech_finished(utterance_id: int) -> void:
	if utterance_id == speech_id:
		pending = false

func _exit_tree() -> void:
	stop()
