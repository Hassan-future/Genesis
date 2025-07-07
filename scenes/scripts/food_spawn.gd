extends Node2D

const FOOD = preload("res://scenes/food.tscn")
@onready var world: ColorRect = %WorldArea
var margin: float = 10.0

var world_pos: Vector2
var world_size: Vector2
var min_x: float
var max_x: float
var min_y: float
var max_y: float

var current_target_amount: float = 0.0
var is_first_spawn: bool = true

func _ready() -> void:
	Food.start_spawn.connect(_on_start_spawn)
	Food.clear_all_food.connect(_on_clear_all_food)
	Units.reproduction_completed.connect(_on_reproduction_completed)
	Global.program_reset.connect(_on_program_reset)
	Global.program_stopped.connect(_on_program_stopped)

	await get_tree().create_timer(1.0).timeout
	world_pos = world.global_position
	world_size = world.size
	min_x = world_pos.x + margin
	max_x = world_pos.x + world_size.x - margin
	min_y = world_pos.y + margin
	max_y = world_pos.y + world_size.y - margin

func _on_reproduction_completed() -> void:
	setup_food_spawn_amount()

func setup_food_spawn_amount() -> void:
	var spawn_amount: float = 0.0
	
	if Food.hold_amount:
		# Hold amount mode: maintain consistent total amount on canvas
		var current_food_count = get_current_food_count()
		spawn_amount = Food.amount - current_food_count
		spawn_amount = max(0, spawn_amount)  # Don't spawn negative amounts
	else:
		# Normal mode: start with initial amount, then apply increments
		if is_first_spawn:
			current_target_amount = Food.amount
			is_first_spawn = false
		else:
			current_target_amount += Food.increment
		
		# Apply min/max limits
		if Food.hold_max and current_target_amount > Food.max_amount:
			current_target_amount = Food.max_amount
		elif Food.hold_min and current_target_amount < Food.min_amount:
			current_target_amount = Food.min_amount
		
		# Ensure we don't go below 0
		current_target_amount = max(0, current_target_amount)
		spawn_amount = current_target_amount
	
	# Always spawn food during reproduction phase, even when paused
	Food.start_spawn.emit(spawn_amount)

func _on_start_spawn(spawn_quantity) -> void:
	Console.output.emit("%s Food spawning started >>>" % Console._time_request())
	
	# Handle initial spawn case - set up the target amount properly
	if is_first_spawn:
		current_target_amount = spawn_quantity
		is_first_spawn = false
	
	for i in spawn_quantity:
		var instance = FOOD.instantiate()
		instance.position = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		add_child(instance)
		
		await get_tree().create_timer(0.01).timeout
	
		if i+1 == spawn_quantity:
			Console.output.emit("%s Food Spawning Completed!" % Console._time_request())
			var current_food_count = get_current_food_count()
			Console.output.emit("	FOOD SPAWNED: %d   TOTAL ON CANVAS: %d" % [spawn_quantity, current_food_count])
			Food.spawn_completed.emit()
	
	if spawn_quantity == 0:
		var current_food_count = get_current_food_count()
		Console.output.emit("%s FOOD SPAWNED: 0   Current amount on canvas: %d" % [Console._time_request(), current_food_count])
		Food.spawn_completed.emit()

func _on_clear_all_food() -> void:
	var has_child:bool = false
	if get_children().size() > 0:
		has_child = true
	else:
		has_child = false

	for child in get_children():
		child.queue_free()
	
	if has_child:
		Console.output.emit("	ALL FOOD CLEARED")

func get_current_food_count() -> int:
	var count = 0
	for child in get_children():
		if child != world:
			count += 1
	return count

func _on_program_reset() -> void:
	# Reset spawning state when program is reset
	current_target_amount = 0.0
	is_first_spawn = true

func _on_program_stopped() -> void:
	# Reset spawning state when program is stopped
	current_target_amount = 0.0
	is_first_spawn = true
