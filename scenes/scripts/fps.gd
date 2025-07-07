extends Label

@onready var world_area: ColorRect = %WorldArea
@onready var canvas: Label = $"../Canvas"

func _ready() -> void:
	canvas.text = " Canvas: %3.0fpx" % (world_area.size.x / 1920.0 * get_window().size.x)


func _process(_delta: float) -> void:
	text = "FPS: %d" % Engine.get_frames_per_second()

	
