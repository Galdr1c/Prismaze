extends RefCounted

static func is_safe(path: String) -> bool:
	if path.is_empty():
		return false
	var resolved := ProjectSettings.globalize_path(path).replace("\\", "/").simplify_path().trim_suffix("/")
	var test_root := ProjectSettings.globalize_path("res://artifacts/tests").replace("\\", "/").simplify_path()
	return resolved.begins_with(test_root + "/") and not DirAccess.dir_exists_absolute(resolved) and not FileAccess.file_exists(resolved)

static func validate_args() -> bool:
	var directory := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="):
			directory = argument.trim_prefix("--save-dir=")
	if not is_safe(directory):
		printerr("Tests require --save-dir pointing to a NEW folder inside res://artifacts/tests/.")
		return false
	return true
