extends Node
## Фоновая музыка и звуковые эффекты; синтез речи живёт в VoiceController.

const MUSIC_DIRECTORY: String = "res://assets/audio/music"

var music_player: AudioStreamPlayer
var error_player: AudioStreamPlayer
var track_paths: Array[String] = []
var current_track: String = ""
var _remaining_tracks: Array[String] = []

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_linear = 0.5
	music_player.finished.connect(_play_next_track)
	add_child(music_player)
	# ResourceLoader сохраняет исходные имена ресурсов и в экспортированной игре.
	for file_name in ResourceLoader.list_directory(MUSIC_DIRECTORY):
		if file_name.get_extension().to_lower() in ["mp3", "ogg", "wav"]:
			track_paths.append(MUSIC_DIRECTORY.path_join(file_name))
	if track_paths.is_empty():
		push_warning("В папке " + MUSIC_DIRECTORY + " нет музыкальных треков.")
	else:
		_play_next_track()
	error_player = AudioStreamPlayer.new()
	error_player.volume_linear = 0.8
	error_player.stream = preload("res://assets/audio/effects/error.mp3")
	add_child(error_player)

func toggle_music() -> void:
	music_player.stream_paused = not music_player.stream_paused

func set_music_volume(value: float) -> void:
	music_player.volume_linear = clampf(value, 0.0, 1.0)

func set_sound_volume(value: float) -> void:
	error_player.volume_linear = clampf(value, 0.0, 1.0)

func _play_next_track() -> void:
	# Ограничиваем число попыток: повреждённые файлы не зациклят переключение.
	for attempt in range(track_paths.size()):
		if _remaining_tracks.is_empty():
			_remaining_tracks.assign(track_paths)
			_remaining_tracks.shuffle()
			# Последний трек прошлого круга не повторяется первым в новом.
			if _remaining_tracks.size() > 1 and _remaining_tracks.back() == current_track:
				var first: String = _remaining_tracks[0]
				_remaining_tracks[0] = _remaining_tracks[-1]
				_remaining_tracks[-1] = first
		var path: String = _remaining_tracks.pop_back()
		var resource = load(path) as AudioStream
		if resource == null:
			push_warning("Не удалось загрузить музыкальный трек: " + path)
			continue
		var stream = resource.duplicate() as AudioStream
		if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
			stream.loop = false
		elif stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		var paused: bool = music_player.stream_paused
		current_track = path
		music_player.stream = stream
		music_player.play()
		music_player.stream_paused = paused
		return

func play_error() -> void:
	error_player.play()
