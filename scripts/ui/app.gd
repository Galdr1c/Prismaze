extends Control

const STYLE = preload("res://scripts/ui/ui_style.gd")
const BACKGROUND = preload("res://scripts/ui/background.gd")
const BOARD = preload("res://scripts/game/views/level_board.gd")
const CATALOG = preload("res://scripts/levels/level_catalog.gd")
const SESSION = preload("res://scripts/game/session/game_session.gd")
const SAVE = preload("res://scripts/platform/save_service.gd")
const AUDIO = preload("res://scripts/platform/audio_service.gd")

var catalog := CATALOG.new()
var session := SESSION.new()
var save_service: RefCounted
var profile: Dictionary
var screen := "menu"
var board: Control
var content: VBoxContainer
var safe_margin: MarginContainer
var background: Control
var overlay: Control
var status_label: Label
var caption: Label
var audio: Node
var _save_clock := 0.0
var _training := false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var save_directory := "user://"
	for arg in args:
		if arg.begins_with("--save-dir="):
			save_directory = arg.trim_prefix("--save-dir=")
	save_service = SAVE.new(save_directory)
	profile = save_service.load_data()
	theme = STYLE.make_theme()
	background = BACKGROUND.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin = MarginContainer.new()
	add_child(safe_margin)
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safe_margin.add_child(content)
	resized.connect(_safe_layout)
	_safe_layout()
	audio = AUDIO.new()
	add_child(audio)
	audio.configure(profile.settings)
	get_tree().auto_accept_quit = false
	if args.has("--silent"):
		var muted: Dictionary = profile.settings.duplicate()
		muted.music = 0.0
		muted.sfx = 0.0
		audio.configure(muted)
	else:
		audio.startup()
	show_menu()
	if args.has("--preview-game"):
		open_level(0, false)

func _safe_layout() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	var top := 0.0
	var bottom := 0.0
	if OS.get_name() in ["Android", "iOS"] and window.y > 0 and safe.size.y > 0:
		top = safe.position.y * size.y / window.y
		bottom = maxf(0, window.y - safe.end.y) * size.y / window.y
	safe_margin.add_theme_constant_override("margin_left", 36)
	safe_margin.add_theme_constant_override("margin_right", 36)
	safe_margin.add_theme_constant_override("margin_top", int(top + 26))
	safe_margin.add_theme_constant_override("margin_bottom", int(bottom + 26))

func _process(delta: float) -> void:
	background.reduced_motion = profile.settings.get("reduced_motion", false)
	if screen == "playing" and is_instance_valid(board) and not is_instance_valid(overlay):
		session.elapsed += delta
		_save_clock += delta
		if _save_clock > 5:
			_save_clock = 0
			persist()

func _clear() -> void:
	_close_overlay()
	board = null
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func _label(text: String, font_size: int = 24, color: Color = STYLE.TEXT, display: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if display:
		label.add_theme_font_override("font", load("res://assets/fonts/DynaPuff-SemiBold.ttf"))
	return label

func _button(text: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 96
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary:
		button.add_theme_stylebox_override("normal", STYLE.box(STYLE.ACCENT, STYLE.ACCENT))
		button.add_theme_stylebox_override("hover", STYLE.box(STYLE.ACCENT.lightened(0.15), Color.WHITE))
		button.add_theme_stylebox_override("pressed", STYLE.box(STYLE.ACCENT.darkened(0.15), STYLE.ACCENT))
		button.add_theme_color_override("font_color", STYLE.INK)
		button.add_theme_color_override("font_hover_color", STYLE.INK)
		button.add_theme_color_override("font_pressed_color", STYLE.INK)
	button.pressed.connect(func():
		audio.sfx("click")
		callback.call()
	)
	return button

func _space(parent: Node, expand: bool = true, height: float = 0) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	if expand:
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)

func _header(title: String, callback: Callable) -> void:
	var row := HBoxContainer.new()
	var back := _button("‹", callback)
	back.custom_minimum_size = Vector2(88, 88)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(back)
	var heading := _label(title, 28, STYLE.TEXT, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(heading)
	content.add_child(row)

func show_menu() -> void:
	_clear()
	screen = "menu"
	audio.set_context("menu")
	var top := _label("CRYSTAL LAB   /   İLK IŞIK", 19, STYLE.MUTED)
	content.add_child(top)
	_space(content)
	var gem := _label("◇", 138, STYLE.ACCENT)
	gem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(gem)
	var title := _label("Prismaze", 68, STYLE.TEXT, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var tagline := _label("Işığı yönlendir. Renkleri buluştur.", 25, STYLE.MUTED)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(tagline)
	_space(content, false, 36)
	var stars := 0
	for value in profile.stars.values():
		stars += int(value)
	var progress := _label("%d / 12 bölüm   ·   %d / 36 yıldız" % [profile.stars.size(), stars], 22, STYLE.LILAC)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(progress)
	_space(content)
	var current := int(profile.current)
	content.add_child(_button("Başla" if profile.stars.is_empty() and profile.active.is_empty() else "Devam Et  ·  %02d" % (current+1), func(): open_level(current), true))
	var row := HBoxContainer.new()
	row.add_child(_button("Bölümler", show_levels))
	row.add_child(_button("Ayarlar", func(): show_settings(show_menu)))
	content.add_child(row)
	content.add_child(_button("Nasıl oynanır?", func(): open_level(0, false, true)))
	var footer := _label("12 bulmaca  ·  Çevrimdışı  ·  Kendi hızında", 19, STYLE.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(footer)
	if not save_service.recovery_message.is_empty():
		content.add_child(_label(save_service.recovery_message, 18, STYLE.LILAC))

func show_levels() -> void:
	_clear()
	screen = "levels"
	_header("Işık yolculuğu", show_menu)
	content.add_child(_label("Bir dokunuşla başlar.", 24, STYLE.MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in range(catalog.count()):
		var definition: Resource = catalog.get_level(i)
		var stars := int(profile.stars.get(str(i+1), 0))
		var unlocked: bool = i < profile.unlocked
		var button := _button("%02d   %s   %s" % [i+1, definition.title, "✦".repeat(stars) if unlocked else "•"], func(): open_level(i, false))
		button.disabled = not unlocked
		list.add_child(button)

func open_level(index: int, resume_saved: bool = true, training: bool = false) -> void:
	if index < 0 or index >= catalog.count() or index >= int(profile.unlocked):
		return
	_clear()
	_training = training
	session.start(catalog.get_level(index))
	if resume_saved and not profile.active.is_empty():
		session.restore(profile.active)
	profile.current = index
	screen = "playing"
	audio.set_context("game")
	_header("%02d  /  %s" % [index+1, session.definition.title], pause_game)
	status_label = _label("", 22, STYLE.MUTED)
	content.add_child(status_label)
	board = BOARD.new()
	board.custom_minimum_size.y = 300
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(board)
	board.setup(session, profile.settings)
	board.tutorial = index == 0 and (training or not profile.tutorial_done) and not session.result.solved
	board.object_tapped.connect(_rotate)
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", STYLE.box(STYLE.PANEL, Color("#34405c"), 18))
	caption = _label("Aynayı döndürmek için elin gösterdiği yere dokun." if board.tutorial else session.definition.lesson, 24, STYLE.ACCENT if board.tutorial else STYLE.MUTED)
	info.add_child(caption)
	content.add_child(info)
	var row := HBoxContainer.new()
	row.add_child(_button("Sıfırla", _confirm_reset))
	row.add_child(_button("İpucu", show_hint))
	if board.tutorial:
		row.add_child(_button("Atla", skip_tutorial))
	content.add_child(row)
	_update_status()
	persist()
	if session.result.solved:
		_complete()

func _update_status() -> void:
	var lit := 0
	var total := 0
	for object in session.objects:
		if object.kind == 3:
			total += 1
			if session.result.hits.get(object.id,0) == object.color:
				lit += 1
	status_label.text = "%d hamle  ·  Hedef %d     /     %d / %d ışık" % [session.moves, session.definition.par_moves, lit, total]

func _rotate(id: String) -> void:
	if screen != "playing" or is_instance_valid(overlay):
		return
	if board.tutorial and id != "m1":
		return
	if not session.rotate(id):
		return
	audio.sfx("rotate")
	if OS.get_name() == "Android" and profile.settings.vibration:
		Input.vibrate_handheld(18)
	board.hint_id = ""
	_update_status()
	if session.result.solved:
		_complete()
	else:
		persist()

func _complete() -> void:
	if screen == "result":
		return
	screen = "result"
	board.enabled = false
	board.tutorial = false
	profile.tutorial_done = true
	var id := str(session.definition.id)
	var stars := 3 if session.moves <= session.definition.par_moves else (2 if session.moves <= session.definition.par_moves + 3 else 1)
	profile.stars[id] = maxi(int(profile.stars.get(id,0)), stars)
	profile.best_moves[id] = mini(int(profile.best_moves.get(id,session.moves)), session.moves)
	profile.unlocked = maxi(int(profile.unlocked), mini(session.definition.id + 1, 12))
	profile.current = mini(session.definition.id, 11)
	profile.active = {}
	save_service.save_data(profile)
	caption.text = "Harika! Bütün ışıklar yerini buldu."
	audio.sfx("complete")
	var expected_id: int = session.definition.id
	await get_tree().create_timer(0.4).timeout
	if screen == "result" and session.definition.id == expected_id:
		_result_modal(stars)

func _result_modal(stars: int) -> void:
	var box := _modal("Işık tamamlandı!")
	var star_label := _label("✦".repeat(stars) + "◇".repeat(3-stars), 58, Color("#ffe3a1"))
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(star_label)
	box.add_child(_label("%d hamle  ·  %d:%02d" % [session.moves, int(session.elapsed)/60, int(session.elapsed)%60], 24, STYLE.MUTED))
	if session.definition.id < 12:
		box.add_child(_button("Sonraki Bölüm", func(): open_level(session.definition.id, false), true))
	else:
		box.add_child(_label("12 bölüm tamam! Işık yolculuğunun ilk adımını bitirdin.", 25))
		box.add_child(_button("Bölümleri Keşfet", show_levels, true))
	box.add_child(_button("Tekrar Oyna", func(): open_level(session.definition.id-1, false)))
	box.add_child(_button("Ana Menü", show_menu))

func show_hint() -> void:
	var hint: Dictionary = session.hint()
	if hint.is_empty():
		return
	board.hint_id = hint.id
	board.hint_orientation = hint.orientation
	var object_kind := 1
	for object in session.objects:
		if object.id == hint.id:
			object_kind = object.kind
	var turns := posmod(int(hint.orientation) - session.orientation_of(hint.id),4)
	caption.text = "İşaretli %s %d kez dokun." % ["aynaya" if object_kind == 1 else "prizmaya", turns]
	# Free hints in the initial offline slice.
	audio.sfx("click")

func skip_tutorial() -> void:
	profile.tutorial_done = true
	board.tutorial = false
	caption.text = session.definition.lesson
	persist()
	open_level(session.definition.id-1, true)

func _confirm_reset() -> void:
	if session.moves == 0:
		return
	screen = "paused"
	board.enabled = false
	var box := _modal("Baştan deneyelim mi?")
	box.add_child(_label("Bu bölümdeki hamlelerin sıfırlanacak.", 24, STYLE.MUTED))
	box.add_child(_button("Bölümü Sıfırla", func(): open_level(session.definition.id-1, false), true))
	box.add_child(_button("Vazgeç", resume_game))

func pause_game() -> void:
	if screen != "playing":
		return
	screen = "paused"
	board.enabled = false
	persist()
	var box := _modal("Bir nefes.")
	box.add_child(_label("Işık yolu seni bekliyor.", 24, STYLE.MUTED))
	box.add_child(_button("Devam Et", resume_game, true))
	box.add_child(_button("Ayarlar", func(): show_settings(_return_from_settings)))
	box.add_child(_button("Ana Menü", show_menu))

func resume_game() -> void:
	_close_overlay()
	screen = "playing"
	board.enabled = true
	audio.resume()

func _return_from_settings() -> void:
	open_level(session.definition.id-1, true, _training)
	pause_game()

func _modal(title: String) -> VBoxContainer:
	_close_overlay()
	overlay = Control.new()
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02,0.035,0.07,0.87)
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minf(size.x-72, 570)
	panel.add_theme_stylebox_override("panel", STYLE.box(STYLE.PANEL, Color("#405071"), 28))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)
	box.add_child(_label(title, 36, STYLE.TEXT, true))
	return box

func _close_overlay() -> void:
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
	overlay = null

func show_settings(back: Callable) -> void:
	persist()
	_clear()
	screen = "settings"
	_header("Ayarlar", back)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for key in ["music", "sfx"]:
		list.add_child(_label("Müzik" if key == "music" else "Ses efektleri", 26, STYLE.LILAC, true))
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = profile.settings[key]
		slider.custom_minimum_size.y = 72
		slider.value_changed.connect(func(value: float):
			profile.settings[key] = value
			audio.configure(profile.settings)
			save_service.save_data(profile)
		)
		list.add_child(slider)
	var options := {"vibration": "Titreşim", "reduced_motion": "Hareketi azalt", "reduced_glow": "Parlamayı azalt", "high_contrast": "Yüksek kontrast", "color_assist": "Renk sembolleri"}
	for key in options:
		var toggle := CheckButton.new()
		toggle.text = options[key]
		toggle.custom_minimum_size.y = 90
		toggle.button_pressed = profile.settings[key]
		toggle.toggled.connect(func(on: bool):
			profile.settings[key] = on
			save_service.save_data(profile)
		)
		list.add_child(toggle)
	list.add_child(_label("Kendi hızında oyna. Tüm bulmacalar ve kayıtların bu cihazda çalışır.", 23, STYLE.MUTED))
	list.add_child(_button("İlk Bölüm Eğitimini Tekrarla", func(): open_level(0, false, true)))
	list.add_child(_label("Prismaze · İlk Işık\nFont: DynaPuff · SIL OFL 1.1\nSes: Proje sahibi tarafından sağlandı.", 20, STYLE.MUTED))

func persist() -> void:
	if not profile.is_empty() and session.definition and screen in ["playing", "paused"]:
		profile.active = session.snapshot()
	if not profile.is_empty():
		save_service.save_data(profile)

func _notification(what: int) -> void:
	if not is_inside_tree() or not is_instance_valid(audio) or screen == "quitting":
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		persist()
		pause_game()
		audio.suspend()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		audio.resume()
	elif what in [NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_WM_CLOSE_REQUEST]:
		if screen == "playing":
			pause_game()
		elif screen == "paused":
			resume_game()
		elif screen in ["levels", "settings", "result"]:
			show_menu()
		else:
			quit_game()

func quit_game() -> void:
	if screen == "quitting":
		return
	persist()
	screen = "quitting"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await audio.shutdown_and_wait()
	get_tree().quit()
