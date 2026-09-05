extends RefCounted

var directory: String
var recovery_message: String = ""

func _init(save_directory: String = "user://") -> void:
	directory = save_directory
	if directory.ends_with("/") and not directory.ends_with("://"):
		directory = directory.trim_suffix("/")
	DirAccess.make_dir_recursive_absolute(directory)

func defaults() -> Dictionary:
	return {"schema": 1, "unlocked": 1, "current": 0, "stars": {}, "best_moves": {}, "active": {}, "tutorial_done": false, "settings": {"music": 0.65, "sfx": 0.65, "vibration": true, "reduced_motion": false, "reduced_glow": false, "high_contrast": false, "color_assist": false}}

func load_data() -> Dictionary:
	recovery_message = ""
	var primary: Dictionary = _read(directory + "/save.json")
	if not primary.is_empty():
		return _merge(primary)
	var backup: Dictionary = _read(directory + "/save.backup.json")
	if not backup.is_empty():
		recovery_message = "Kayıt yedekten kurtarıldı."
		return _merge(backup)
	if FileAccess.file_exists(directory + "/save.json"):
		recovery_message = "Önceki kayıt okunamadı. Yeni oyun açıldı."
	return defaults()

func save_data(data: Dictionary) -> bool:
	if not _valid(data):
		return false
	var temp := directory + "/save.tmp.json"
	var primary := directory + "/save.json"
	var backup := directory + "/save.backup.json"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or _read(temp).is_empty():
		return false
	# Copy only a validated primary; a corrupt primary must not replace the backup.
	if not _read(primary).is_empty():
		if DirAccess.copy_absolute(primary, backup) != OK:
			return false
	return DirAccess.rename_absolute(temp, primary) == OK

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	if not parser.data is Dictionary or not _valid(parser.data):
		return {}
	return parser.data

func _valid(data: Dictionary) -> bool:
	return data.get("schema") == 1 and (data.get("unlocked") is int or data.get("unlocked") is float) and data.unlocked >= 1 and data.unlocked <= 12 and data.get("stars") is Dictionary and data.get("active") is Dictionary and data.get("settings") is Dictionary

func _merge(data: Dictionary) -> Dictionary:
	var merged := defaults()
	for key in merged:
		if data.has(key):
			merged[key] = data[key]
	var settings: Dictionary = defaults().settings
	for key in settings:
		if merged.settings.has(key) and typeof(merged.settings[key]) == typeof(settings[key]):
			settings[key] = merged.settings[key]
	for key in ["music", "sfx"]:
		settings[key] = clampf(float(settings[key]), 0, 1)
	merged.settings = settings
	merged.unlocked = clampi(int(merged.unlocked), 1, 12)
	merged.current = clampi(int(merged.get("current", 0)), 0, merged.unlocked - 1)
	return merged
