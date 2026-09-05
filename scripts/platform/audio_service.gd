extends Node

var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var stinger: AudioStreamPlayer
var preferences: Dictionary = {}
var _started := false
var _context := "menu"
var _suspended := false
var _shutdown := false

const STARTUP_PATH := "res://assets/audio/stingers/starting_sound.mp3"
const EFFECTS := ["click", "rotate", "complete"]

func _ready() -> void:
	music = AudioStreamPlayer.new()
	effects = AudioStreamPlayer.new()
	stinger = AudioStreamPlayer.new()
	for player in [music, effects, stinger]:
		add_child(player)
	stinger.finished.connect(_finish_startup)

func configure(settings: Dictionary) -> void:
	preferences = settings
	music.volume_db = linear_to_db(maxf(0.0001, float(settings.get("music", 0.65)) * 0.4))
	stinger.volume_db = linear_to_db(maxf(0.0001, float(settings.get("music", 0.65)) * 0.5))
	effects.volume_db = linear_to_db(maxf(0.0001, float(settings.get("sfx", 0.65)) * 0.65))
	if float(settings.get("music", 0.65)) <= 0:
		music.stop()
		stinger.stop()
		stinger.stream = null
	elif _started and not stinger.playing:
		_play_context()
	if float(settings.get("sfx", 0.65)) <= 0:
		effects.stop()

func startup() -> void:
	if _started or _shutdown:
		return
	_started = true
	if preferences.get("music", 0.65) > 0 and not _suspended and ResourceLoader.exists(STARTUP_PATH):
		music.stop()
		stinger.stream = load(STARTUP_PATH)
		stinger.play()
	else:
		set_context("menu")

func set_context(context: String) -> void:
	_context = context
	if stinger.playing and context == "menu":
		return
	if stinger.playing:
		stinger.stop()
	stinger.stream = null
	_play_context()

func _finish_startup() -> void:
	stinger.stream = null
	_play_context()

func _play_context() -> void:
	if _shutdown or _suspended or preferences.get("music", 0.65) <= 0:
		return
	var path := "res://assets/audio/runtime/menu.mp3" if _context == "menu" else "res://assets/audio/runtime/gameplay.mp3"
	if music.stream and music.stream.resource_path == path:
		if not music.playing:
			music.play()
		return
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStreamMP3
	if stream:
		stream.loop = true
		music.stream = stream
		music.play()

func sfx(event: String) -> void:
	if _shutdown or _suspended or preferences.get("sfx", 0.65) <= 0 or event not in EFFECTS:
		return
	var path := "res://assets/audio/runtime/" + event + ".mp3"
	if not ResourceLoader.exists(path):
		return
	effects.stream = load(path)
	if effects.stream:
		effects.play()

func suspend() -> void:
	_suspended = true
	stinger.stop()
	stinger.stream = null
	effects.stop()
	music.stream_paused = true

func resume() -> void:
	_suspended = false
	music.stream_paused = false
	if not stinger.playing:
		_play_context()

func shutdown() -> void:
	_shutdown = true
	for player in [music, effects, stinger]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func _exit_tree() -> void:
	shutdown()

func shutdown_and_wait() -> void:
	var resources: Array[WeakRef] = []
	for player in [music, effects, stinger]:
		if is_instance_valid(player) and player.stream != null:
			resources.append(weakref(player.stream))
	shutdown()
	# stop() retires playback on the audio thread. Keep the tree alive until
	# the mixer releases those references; bound the wait for external owners.
	var deadline := Time.get_ticks_msec() + 1000
	while resources.any(func(reference: WeakRef): return reference.get_ref() != null) and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.05, true, false, true).timeout
