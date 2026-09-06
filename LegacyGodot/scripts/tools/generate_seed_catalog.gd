extends SceneTree

const BUILDER = preload("res://scripts/tools/catalog_builder.gd")
const DEFAULT_OUTPUT := "res://data/catalogs/endless_seed_catalog_v1.tres"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var count := 500
	var output := DEFAULT_OUTPUT
	for arg in args:
		if arg.begins_with("--count="):
			count = maxi(1, int(arg.trim_prefix("--count=")))
		elif arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	var catalog: Resource = BUILDER.new().build(count)
	var error := ResourceSaver.save(catalog, output)
	print("Catalog saved: %d entries -> %s (%s)" % [catalog.entries.size(), output, error_string(error)])
	quit(0 if error == OK else 1)