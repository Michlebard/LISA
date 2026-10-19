extends Node
## Один русский голос для букв, слогов и слов. Управляет повторами и отменой речи.

var voice_id: String = ""
var warning_shown: bool = false
var speech_id: int = 0
var pending: bool = false
var repeated_symbol: String = ""
var repeat_timer: Timer
var volume: int = 80

func set_volume(value: float) -> void:
	volume = roundi(clampf(value, 0.0, 1.0) * 100.0)
	if volume == 0:
		stop()

func _ready() -> void:
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _on_speech_finished)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, _on_speech_finished)
	repeat_timer = Timer.new()
	repeat_timer.wait_time = 1.8
	repeat_timer.timeout.connect(_repeat)
	add_child(repeat_timer)

func start_repeating(symbol: String) -> void:
	stop()
	repeated_symbol = symbol
	speak(symbol)
	repeat_timer.start()

func stop() -> void:
	if repeat_timer:
		repeat_timer.stop()
	repeated_symbol = ""
	speech_id += 1
	pending = false
	if voice_id != "":
		DisplayServer.tts_stop()

func speak(text: String) -> void:
	if text.is_empty() or volume == 0:
		return
	# На Android голоса могут стать доступны после асинхронной инициализации.
	if voice_id == "" and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		var voices = DisplayServer.tts_get_voices_for_language("ru")
		if not voices.is_empty():
			voice_id = voices[0]
	if voice_id == "":
		if not warning_shown:
			push_warning("Озвучка недоступна: установите русский голос синтеза речи в настройках устройства.")
			warning_shown = true
		return
	speech_id += 1
	pending = true
	DisplayServer.tts_speak(text.to_lower(), voice_id, volume, 1.0, 0.85, speech_id, true)

func wait_for_word(utterance_id: int) -> bool:
	# Сохраняем минимальную паузу успеха и ждём даже отложенного запуска TTS.
	await get_tree().create_timer(1.2).timeout
	var elapsed: float = 1.2
	while pending and speech_id == utterance_id and elapsed < 15.0:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	return speech_id == utterance_id

func _repeat() -> void:
	if repeated_symbol.is_empty() or pending:
		return
	if voice_id != "" and DisplayServer.tts_is_speaking():
		return
	speak(repeated_symbol)

func _on_speech_finished(utterance_id: int) -> void:
	if utterance_id == speech_id:
		pending = false

func _exit_tree() -> void:
	stop()
