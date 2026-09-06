extends Control

var reduced_motion := false
var time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not reduced_motion:
		time += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#080e1c"))
	for i in range(12):
		var alpha := 0.015 * float(12-i)/12.0
		draw_circle(Vector2(size.x * 0.88, size.y * 0.25), 80.0 + i * 34, Color(0.38,0.35,0.85,alpha))
		draw_circle(Vector2(size.x * 0.1, size.y * 0.88), 60.0 + i * 26, Color(0.12,0.7,0.6,alpha))
	for i in range(42):
		var px := fmod(i * 127.13 + 25, maxf(size.x, 1))
		var py := fmod(i * 223.73 + 50, maxf(size.y, 1))
		var brightness := 0.1 + 0.05 * sin(time * 0.6 + i)
		draw_circle(Vector2(px, py), 1.0 + (i % 3) * 0.5, Color(0.6,0.75,1.0,brightness))
