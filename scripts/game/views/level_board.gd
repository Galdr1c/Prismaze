extends Control

signal object_tapped(id: String)

const STYLE = preload("res://scripts/ui/ui_style.gd")
const COLORS := [Color("#59627b"), Color("#ff6479"), Color("#72e89d"), Color("#ffe08a"), Color("#6eacff"), Color("#dc8bff"), Color("#65e8ee"), Color("#eef7ff")]
var session: RefCounted
var settings: Dictionary = {}
var enabled := true
var tutorial := false
var hint_id := ""
var hint_orientation := -1
var cell_size := 1.0
var origin := Vector2.ZERO
var clock := 0.0
var _angles: Dictionary = {}
var _pressed_id := ""
var _pointer := -2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	clip_contents = false

func setup(game_session: RefCounted, preferences: Dictionary) -> void:
	session = game_session
	settings = preferences
	_angles.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if not settings.get("reduced_motion", false):
		clock += delta
	if session:
		for object in session.objects:
			if object.kind not in [1, 2]:
				continue
			var target: float = _angle(object.kind, object.orientation)
			var old: float = _angles.get(object.id, target)
			_angles[object.id] = target if settings.get("reduced_motion", false) else lerp_angle(old, target, minf(delta * 22, 1))
	queue_redraw()

func _angle(kind: int, orientation: int) -> float:
	return -PI / 2 + orientation * PI / 4 if kind == 1 else orientation * PI / 2

func _layout() -> void:
	if not session:
		return
	var dimensions: Vector2i = session.definition.board_size
	cell_size = minf((size.x - 28) / dimensions.x, (size.y - 28) / dimensions.y)
	origin = (size - Vector2(dimensions) * cell_size) / 2

func point_for(id: String) -> Vector2:
	_layout()
	for object in session.objects:
		if object.id == id:
			return origin + Vector2(object.position.x + 0.5, object.position.y + 0.5) * cell_size
	return Vector2(-100, -100)

func object_at(point: Vector2) -> String:
	_layout()
	if not session or cell_size <= 0:
		return ""
	var cell := Vector2i(((point - origin) / cell_size).floor())
	for object in session.objects:
		if object.rotatable and cell == Vector2i(object.position.x, object.position.y):
			return object.id
	return ""

func _gui_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _pointer == -2:
			_pointer = event.index
			_pressed_id = object_at(event.position)
		elif not event.pressed and _pointer == event.index:
			_release(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _pointer == -2:
			_pointer = -1
			_pressed_id = object_at(event.position)
		elif not event.pressed and _pointer == -1:
			_release(event.position)

func _release(point: Vector2) -> void:
	var id := object_at(point)
	if id == _pressed_id and not id.is_empty() and (not tutorial or id == "m1"):
		object_tapped.emit(id)
	_pointer = -2
	_pressed_id = ""

func _draw() -> void:
	if not session:
		return
	_layout()
	var bounds := Rect2(origin, Vector2(session.definition.board_size) * cell_size)
	draw_style_box(STYLE.box(Color("#0b1425"), Color("#33425b"), 24), bounds.grow(12))
	for y in range(session.definition.board_size.y):
		for x in range(session.definition.board_size.x):
			var p := origin + Vector2(x + 0.5, y + 0.5) * cell_size
			draw_circle(p, 1.5, Color("#2b3750"))
	for segment in session.result.get("segments", []):
		var start: Vector2 = origin + segment.from * cell_size
		var end: Vector2 = origin + segment.to * cell_size
		var color: Color = COLORS[segment.color]
		if not settings.get("reduced_glow", false):
			draw_line(start, end, Color(color, 0.065), cell_size * 0.32, true)
			draw_line(start, end, Color(color, 0.16), cell_size * 0.15, true)
		draw_line(start, end, color, maxf(2.5, cell_size * 0.047), true)
		draw_line(start, end, color.lightened(0.65), 1.3, true)
		if not settings.get("reduced_motion", false):
			var travel := fposmod(clock * 0.65, 1.0)
			draw_circle(start.lerp(end, travel), 2.2, Color.WHITE)
	for object in session.objects:
		_draw_object(object)
	if tutorial:
		var p := point_for("m1")
		# A quiet vignette preserves the complete light path.
		draw_arc(p, cell_size * 0.63, 0, TAU, 48, STYLE.ACCENT, 2.5, true)
		_hand(p + Vector2(cell_size * 0.12, cell_size * 0.28))
	elif not hint_id.is_empty():
		var p := point_for(hint_id)
		draw_arc(p, cell_size * 0.57, 0, TAU, 48, Color("#ffe6a1"), 3, true)
		if hint_orientation >= 0:
			draw_string(ThemeDB.fallback_font, p + Vector2(-cell_size * 0.4, -cell_size * 0.65), "İpucu", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#ffe6a1"))

func _draw_object(object: RefCounted) -> void:
	var p := point_for(object.id)
	var radius := cell_size * 0.32
	var color: Color = COLORS[object.color]
	var contrast: bool = settings.get("high_contrast", false)
	draw_circle(p + Vector2(0, 5), radius + 2, Color(0, 0, 0, 0.45))
	match object.kind:
		0:
			draw_circle(p, radius, Color("#1c2b42"))
			draw_arc(p, radius, 0, TAU, 32, color, 2, true)
			var forward := Vector2.UP.rotated(object.orientation * PI / 2)
			var side := forward.orthogonal()
			draw_colored_polygon(PackedVector2Array([p + forward * radius * 0.7, p - forward * radius * 0.4 + side * radius * 0.55, p - forward * radius * 0.4 - side * radius * 0.55]), color)
		1:
			draw_circle(p, radius + 2, Color("#27344d") if not contrast else Color("#424f64"))
			draw_arc(p, radius + 3, 0, TAU, 32, Color("#7e8dba"), 1.5, true)
			var angle: float = _angles.get(object.id, _angle(1, object.orientation))
			var axis := Vector2.RIGHT.rotated(angle) * radius
			draw_line(p - axis + Vector2(0, 3), p + axis + Vector2(0, 3), Color("#4d4565"), 12, true)
			draw_line(p - axis, p + axis, Color("#c9b7ff"), 10, true)
			draw_line(p - axis, p + axis, Color("#fbf6ff"), 3, true)
			draw_circle(p - axis, 4, Color("#d2b98c"))
			draw_circle(p + axis, 4, Color("#d2b98c"))
		2:
			var points := PackedVector2Array([p + Vector2(0,-radius * 1.3), p + Vector2(radius * 1.2,0), p + Vector2(0,radius * 1.3), p + Vector2(-radius * 1.2,0)])
			draw_colored_polygon(points, Color("#353d69"))
			draw_colored_polygon(PackedVector2Array([points[0], points[1], p]), Color("#8394bd"))
			draw_colored_polygon(PackedVector2Array([points[0], p, points[3]]), Color("#d0d2ff"))
			draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]), Color("#bacaff"), 2, true)
			var angle: float = _angles.get(object.id, _angle(2, object.orientation))
			for port in [[0,1],[1,2],[3,4]]:
				var v := Vector2.UP.rotated(angle + port[0]*PI/2)
				draw_circle(p + v * radius * 0.76, 4, COLORS[port[1]])
		3:
			var hit: int = session.result.hits.get(object.id, 0)
			var lit: bool = hit == object.color
			draw_circle(p, radius, color.darkened(0.65) if lit else Color("#172135"))
			draw_arc(p, radius, 0, TAU, 40, color, 3, true)
			draw_arc(p, radius * 0.76, 0, TAU, 40, Color(color,0.3), 1, true)
			if lit:
				draw_polyline(PackedVector2Array([p+Vector2(-radius*0.4,0),p+Vector2(-radius*0.08,radius*0.3),p+Vector2(radius*0.4,-radius*0.32)]), Color.WHITE, 3, true)
			else:
				draw_circle(p, radius * 0.24, color)
		4:
			var rect := Rect2(p - Vector2.ONE * radius, Vector2.ONE * radius * 2)
			draw_style_box(STYLE.box(Color("#283044"), Color("#465269"), 7), rect)
			draw_line(rect.position + Vector2(6,6), rect.position + Vector2(rect.size.x-6,6), Color("#707891"), 2, true)
	if settings.get("color_assist", false) and object.kind in [0,3]:
		var names := ["", "R", "G", "RG", "B", "RB", "GB", "RGB"]
		draw_string(ThemeDB.fallback_font, p + Vector2(-radius, radius + 18), names[object.color], HORIZONTAL_ALIGNMENT_CENTER, radius*2, 16, color)

func _hand(point: Vector2) -> void:
	var offset := 0.0
	if not settings.get("reduced_motion", false):
		offset = sin(clock * 4) * 5
	var p := point + Vector2(offset, offset)
	draw_arc(p, 12 + absf(offset), 0, TAU, 32, Color(STYLE.ACCENT, 0.5), 2, true)
	var hand := PackedVector2Array([Vector2(0,0), Vector2(8,-2), Vector2(20,24), Vector2(28,19), Vector2(37,25), Vector2(43,23), Vector2(51,31), Vector2(47,53), Vector2(30,61), Vector2(11,46), Vector2(5,29), Vector2(12,25)])
	var positioned := PackedVector2Array()
	for v in hand:
		positioned.append(p+v)
	draw_colored_polygon(positioned, Color("#eef8ff"))
	positioned.append(positioned[0])
	draw_polyline(positioned, Color("#5d7ba6"), 2, true)
