extends RefCounted

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "Persistence contract failed" if not ok else ""})

func run() -> Array[Dictionary]:
	var path := "res://scripts/platform/save_service.gd"
	if not ResourceLoader.exists(path):
		check("SaveService exists", false)
		return results
	var directory := "user://test_save_%d" % Time.get_ticks_usec()
	var service = load(path).new(directory)
	var data: Dictionary = service.load_data()
	check("New profile starts at first level", data.unlocked == 1 and data.stars.is_empty())
	data.unlocked = 3
	data.tutorial_done = true
	check("Save commits successfully", service.save_data(data))
	var restored: Dictionary = service.load_data()
	check("Roundtrip retains progress", restored.unlocked == 3 and restored.tutorial_done)
	data.unlocked = 4
	service.save_data(data)
	var file := FileAccess.open(directory + "/save.json", FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check("Corrupt primary recovers backup", service.load_data().unlocked == 3)
	check("Recovery does not overwrite backup with corruption", service.save_data(service.load_data()))
	file = FileAccess.open(directory + "/save.json", FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check("Backup survives a recovery write", service.load_data().unlocked == 3)
	for name in ["save.json", "save.backup.json", "save.tmp.json"]:
		DirAccess.remove_absolute(directory + "/" + name)
	DirAccess.remove_absolute(directory)
	return results
