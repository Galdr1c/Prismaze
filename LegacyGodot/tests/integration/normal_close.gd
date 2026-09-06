extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not load("res://tests/test_save_directory.gd").validate_args():
		quit(1)
		return
	var app: Control = load("res://scenes/boot/boot.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	# This must exercise production quit, with no test-side audio drain.
	print("Normal close requested during startup audio")
	app.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
