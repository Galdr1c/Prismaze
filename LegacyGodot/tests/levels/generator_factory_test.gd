extends RefCounted

var results: Array[Dictionary] = []
func check(label: String, ok: bool) -> void:
	results.append({"name": label, "passed": ok, "message": "GeneratorFactory contract failed" if not ok else ""})

func run() -> Array[Dictionary]:
	var path := "res://scripts/levels/generator/generator_factory.gd"
	if not ResourceLoader.exists(path):
		check(path + " exists", false)
		return results
	var factory = load(path).new()
	var v1 = factory.create(1)
	check("Factory serves v1", v1 != null and v1.has_method("generate"))
	check("Future version is not served", factory.create(2) == null)
	check("Unknown version is not served", factory.create(0) == null)
	return results