extends Area2D

#onready var
@onready var col_shape: CollisionShape2D = $SenseColShape
@onready var body_draw: Control = $Body

var id: int = 0

# var
var predatory_threshold: float = 0.0 

var speed:float = 100.0

var energy:float = 100.0
var max_energy: float

var size:float = 100.0 # px
var body_collosion_threshold: float = 0.05 #when moves inside this radius

var sense:float = 100.0 # radius px

var target_food: Node2D = null
var target_prey: Area2D = null
var sensed_food: Array = []
var sensed_prey: Array = []
var target_position: Vector2

# Add timer for random rotation
var rotation_timer: float = 0.0
var rotation_interval: float = 1.0

func _init() -> void:
	pass

func _ready() -> void:
	Global.new_generation.connect(_on_new_generation)
	area_entered.connect(_on_sense_area_area_entered)
	area_exited.connect(_on_sense_area_area_exited)
	body_entered.connect(_on_sense_area_body_entered)
	body_exited.connect(_on_sense_area_body_exited)
	
	# Set initial random direction
	initiate_unit()
	set_rotation(randf() * TAU)

func _process(delta: float) -> void:
	if Global.is_simulation_running and not Global.is_paused:
		handle_movement(delta)
		handle_energy(-delta * Units.movement_energy_drain * Global.speed)

func initiate_unit() -> void:
	max_energy = energy
	
	col_shape.shape = col_shape.shape.duplicate()
	col_shape.shape.radius = sense
	
	update_unit()

func update_unit() -> void:
	body_draw.radius = size * 0.05
	body_draw.color = get_body_color()
	body_draw.queue_redraw()

func get_body_color() -> Color:
	return Units.HERBIVORE_COLOR.lerp(Units.CARNIVORE_COLOR, clamp(predatory_threshold / 100.0, 0.0, 1.0))

func get_reproduction_eligibility() -> bool:
	var threshold_energy = max_energy * (Units.reproduction_threshold / 100.0)
	return energy >= threshold_energy

func handle_movement(delta: float) -> void:
	# Check for consumption/predation first
	check_food_consumption()
	check_predation()

	# Reset target_position
	target_position = Vector2.ZERO

	# Priority 1: Move toward prey if available
	if target_prey and is_instance_valid(target_prey):
		target_position = target_prey.global_position

	# Priority 2: Move toward food if available (FIXED: was checking target_prey instead of target_food)
	elif target_food and is_instance_valid(target_food):
		target_position = target_food.global_position

	# Rotate toward target or handle random rotation
	if target_position != Vector2.ZERO:
		var dir = (target_position - global_position).normalized()
		rotation = dir.angle() - PI/2
		#rotation_timer = 0.0  # Reset timer when we have a target

	# Always move forward in current direction (+Y is forward)
	var direction = Vector2.DOWN.rotated(rotation)
	position += direction * speed * delta * Global.speed
	
	#handle_energy(delta * speed * 0.01)

func _on_new_generation() -> void:
	pass

func handle_energy(exchange: float) -> void:
	energy += exchange
	energy = clampf(energy,0.0,max_energy)

	if energy <= 0.0:
		Units.unit_destroyed.emit(id)
		Console.output.emit("	UNIT: %d DESTROYED" % id)
		queue_free()

# connetcted signals
func _on_sense_area_area_entered(area: Area2D) -> void:
	if area and area.is_in_group("prey"):
		
		if area.size <= size * (predatory_threshold / 100.0):
			sensed_prey.append(area)
			target_prey = find_closest_prey()

func _on_sense_area_area_exited(area: Area2D) -> void:
	if area in sensed_prey:
		sensed_prey.erase(area)

		if target_prey == area:
			target_prey = find_closest_prey()

func _on_sense_area_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("food"):
		sensed_food.append(body)
		
		target_food = find_closest_food()

func _on_sense_area_body_exited(body: Node2D) -> void:
	if body in sensed_food:
		sensed_food.erase(body)

		if target_food == body:
			target_food = find_closest_food()

func find_closest_food() -> Node2D:
	if sensed_food.is_empty():
		return null
	
	var closest_food = null
	var closest_distance = INF
	
	for food in sensed_food:
		if is_instance_valid(food):
			var distance = global_position.distance_to(food.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_food = food
	
	return closest_food

func find_closest_prey() -> Area2D:
	if sensed_prey.is_empty():
		return null
	
	var closest_prey = null
	var closest_distance = INF
	
	for unit in sensed_prey:
		if is_instance_valid(unit):
			var distance = global_position.distance_to(unit.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_prey = unit
	
	return closest_prey

func check_food_consumption() -> void:
	if not target_food or not is_instance_valid(target_food):
		target_food = null

	elif target_food:
		var distance_to_food = global_position.distance_to(target_food.global_position)

		if distance_to_food <= (size * body_collosion_threshold):
			
			if energy < max_energy:
				handle_energy(target_food.energy)
				target_food.queue_free()
				sensed_food.erase(target_food)
				target_food = find_closest_food()  # Find next food target immediately

func check_predation() -> void:
	if not target_prey or not is_instance_valid(target_prey):
		target_prey = null  
	elif target_prey:
		var distance_to_prey = global_position.distance_to(target_prey.global_position)
		if distance_to_prey <= (size * body_collosion_threshold):
			if energy < max_energy:
				handle_energy(target_prey.energy)
				target_prey.handle_energy(-target_prey.max_energy)  # Kill the prey
				sensed_prey.erase(target_prey)
				target_prey = find_closest_prey()  # Find next prey target immediately
