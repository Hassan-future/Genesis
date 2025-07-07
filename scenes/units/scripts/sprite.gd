extends Control

@export var radius: float = 5.0
@export var color: Color = Color(1, 1, 1)
@export var filled: bool = true
var center = Vector2(0, 0)

func ready() -> void:
	_draw()

func _draw():
	draw_circle(center, radius, color, filled)
