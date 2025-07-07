extends Node2D

@onready var units_spawn: Node2D = $UnitsSpawn
@onready var food_spawn: Node2D = $FoodSpawn

func _ready() -> void:
	Global.program_stopped.connect(_on_program_stopped)

func _on_program_stopped():
	food_spawn.clear_all_food()
	units_spawn.clear_all_units()
