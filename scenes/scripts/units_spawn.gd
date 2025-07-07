extends Node2D

const UNIT = preload("res://scenes/units/unit.tscn")

@export_group("spawning")
@onready var world: ColorRect = %WorldArea
@export var amount: int = 10

var margin: float = 100.0

@export_group("type")
@export_range(0.0, 100.0, 0.1)
var carnivore: float = 0.0

@export_group("movement")
@export var speed: float = 100.0
@export var speed_random: float = 10.0

@export_group("energy")
@export var energy: float = 100.0
@export var energy_random: float = 10.0
var max_energy: float

@export_group("appearance")
@export var size: float = 100.0 # px
@export var size_random: float = 10.0

@export_group("sense")
@export var sense: float = 100.0 # radius px
@export var sense_random: float = 10.0

func _ready() -> void:
	Units.start_unit_spawn.connect(_on_start_unit_spawn)
	Units.start_reproduction_spawn.connect(_on_start_reproduction_spawn)
	Units.clear_all_units.connect(_on_clear_all_units)
	Global.new_generation.connect(_on_new_generation)

func get_world_bounds(new_margin) -> Dictionary:
	var world_pos: Vector2 = world.global_position
	var world_size: Vector2 = world.size
	return {
		"min_x": world_pos.x + new_margin,
		"max_x": world_pos.x + world_size.x - new_margin,
		"min_y": world_pos.y + new_margin,
		"max_y": world_pos.y + world_size.y - new_margin
	}

func setup_population() -> int:
	var population = Units.population
	var final_population = population + randf_range(-Units.population_random, Units.population_random)
	var population_int = int(final_population)
	Units.requested_population = population_int
	return population_int

# Consolidated unit stats calculation - works for both new units and offspring
func calculate_unit_stats(base_stats: Dictionary = {}) -> Dictionary:
	# If no base stats provided, use global Units values (for new units)
	var stats = {
		"size": base_stats.get("size", Units.size),
		"energy": base_stats.get("energy", Units.energy),
		"sense": base_stats.get("sense", Units.sense),
		"speed": base_stats.get("speed", Units.speed),
		"carnivore": base_stats.get("carnivore", Units.carnivore)
	}
	
	# Apply randomization (always for new units, conditionally for offspring)
	var apply_randomization = base_stats.is_empty() or Units.reproduction_randomization
	if apply_randomization:
		stats.size += randf_range(-Units.size_random, Units.size_random)
		stats.energy += randf_range(-Units.energy_random, Units.energy_random)
		stats.sense += randf_range(-Units.sense_random, Units.sense_random)
		stats.speed += randf_range(-Units.speed_random, Units.speed_random)
		stats.carnivore += randf_range(-Units.carnivore_random, Units.carnivore_random)
	
	# Apply tradeoffs if enabled
	if Units.is_tradeoff_enabled:
		var threshold = Units.tradeoff_threshold * 0.01
		stats.energy += (stats.size * threshold)
		stats.sense -= (stats.size * threshold)
		stats.speed -= (stats.size * threshold)
	
	# Apply bounds checking
	stats.energy = max(1.0, stats.energy)
	stats.size = max(1.0, stats.size)
	stats.sense = max(1.0, stats.sense)
	stats.speed = max(1.0, stats.speed)
	stats.carnivore = clamp(stats.carnivore, 0.0, 100.0)
	
	return stats

# Legacy function kept for compatibility
func setup_unit() -> Dictionary:
	return calculate_unit_stats()

# Optimized function that replaces setup_offspring_stats
func setup_offspring_stats(parent_unit: Area2D) -> Dictionary:
	var parent_stats = {
		"size": parent_unit.size,
		"energy": parent_unit.energy,
		"sense": parent_unit.sense,
		"speed": parent_unit.speed,
		"carnivore": parent_unit.predatory_threshold
	}
	return calculate_unit_stats(parent_stats)

# Consolidated unit creation and setup
func create_and_setup_unit(stats: Dictionary, position_n: Vector2) -> Area2D:
	var unit = UNIT.instantiate()
	unit.position = position_n
	unit.energy = stats.energy
	unit.sense = stats.sense
	unit.size = stats.size
	unit.speed = stats.speed
	unit.predatory_threshold = stats.carnivore
	unit.id = Units.next_unit_id
	return unit

# Consolidated console output formatting
func format_unit_output(unit: Area2D, parent_id: int = -1) -> String:
	if parent_id >= 0:
		# Offspring format with parent ID
		return "	UNIT:" + ("%04d   %04d %05.1f %05.1f %05.1f %05.1f %05.1f" % [
			unit.id, parent_id, unit.size, unit.energy, unit.sense, unit.speed, unit.predatory_threshold
		])
	else:
		# Regular unit format
		return "	UNIT:" + ("%04d %05.1f %05.1f %05.1f %05.1f %05.1f" % [
			unit.id, unit.size, unit.energy, unit.sense, unit.speed, unit.predatory_threshold
		])

func _on_start_reproduction_spawn() -> void:
	Console.output.emit("%s Reproduction spawning started >>>" % Console._time_request())
	
	var eligible_parents = []
	var offspring_count = 0
	
	# Check all existing units for reproduction eligibility
	for child in get_children():
		if child.has_method("get_reproduction_eligibility") and child.get_reproduction_eligibility():
			eligible_parents.append(child)
	
	Console.output.emit("	ELIGIBLE PARENTS: %d" % eligible_parents.size())
	
	if eligible_parents.size() > 0:
		Console.output.emit("	OFFSPRING  PRNT   SZE   ENG   SEN   SPD   PRD")
		
		for parent in eligible_parents:
			var offspring_stats = setup_offspring_stats(parent)
			var offspring = create_and_setup_unit(offspring_stats, parent.position)
			
			add_child(offspring)
			
			# Drain parent energy
			var energy_drain = parent.max_energy * (Units.parent_energy_drain / 100.0)
			parent.energy = max(1.0, parent.energy - energy_drain)
			
			Console.output.emit(format_unit_output(offspring, parent.id))
			Units.unit_spawned.emit(offspring.id)
			offspring_count += 1
			
			await get_tree().create_timer(0.05).timeout
	
	Console.output.emit("%s Reproduction Completed!" % Console._time_request())
	Console.output.emit("	OFFSPRING SPAWNED: %d  TOTAL UNITS: %d" % [offspring_count, Units.current_population.size()])
	calculate_trait_averages()
	Units.reproduction_completed.emit()

func _on_start_unit_spawn() -> void:
	Console.output.emit("%s Unit spawning started >>>" % Console._time_request())
	
	amount = setup_population()
	Console.output.emit("	TARGET POPULATION: " + str(amount))
	Console.output.emit("	UNIT-ID   SZE   ENG   SEN   SPD   PRD")

	await get_tree().create_timer(1.0).timeout
	
	var bounds = get_world_bounds(margin)
	
	for i in amount:
		var unit_stats = setup_unit()
		var random_position = Vector2(
			randf_range(bounds.min_x, bounds.max_x),
			randf_range(bounds.min_y, bounds.max_y)
		)
		
		var instance = create_and_setup_unit(unit_stats, random_position)
		add_child(instance)
		
		Console.output.emit(format_unit_output(instance))
		Units.unit_spawned.emit(instance.id)
		
		await get_tree().create_timer(0.05).timeout
		
		if i == (amount-1):
			Console.output.emit("%s Unit Spawning Completed!" % Console._time_request())
			Console.output.emit("	UNITS SPAWNED: %d" % amount)
			calculate_trait_averages()
			Units.spawn_completed.emit()

	if amount == 0 and not Global.is_simulation_running:
		Console.output.emit("%s Program Aborted: No Population!" % Console._time_request())
		Global.program_stopped.emit()

func _on_clear_all_units() -> void:
	var has_child: bool = get_children().size() > 0
	
	for child in get_children():
		var id = child.id
		Units.unit_destroyed.emit(id)
		child.queue_free()
	
	if has_child:
		Console.output.emit("	ALL UNITS CLEARED")

func _process(_delta: float) -> void:
	keep_units_in_bounds()

func keep_units_in_bounds() -> void:
	var bounds = get_world_bounds(10)
	for child in get_children():
		if not is_instance_valid(child):
			continue
			
		var pos = child.global_position
		# Calculate unit's effective radius (similar to spawned_unit.gd collision threshold)
		var unit_radius = child.size * 0.05  # Same calculation as body_draw.radius in spawned_unit.gd
		
		# Check bounds considering unit size
		var needs_correction = (pos.x - unit_radius < bounds.min_x or pos.x + unit_radius > bounds.max_x or 
							   pos.y - unit_radius < bounds.min_y or pos.y + unit_radius > bounds.max_y)
		
		if needs_correction:
			teleport_unit_to_random_position(child, bounds)

func teleport_unit_to_random_position(unit: Area2D, bounds: Dictionary) -> void:
	"""Teleport unit to a random position inside the world bounds"""
	var unit_radius = unit.size * 0.05  # Same calculation as body_draw.radius in spawned_unit.gd
	var buffer = max(50.0, unit_radius + 10.0)  # Ensure buffer is large enough for the unit size
	var new_position = Vector2(
		randf_range(bounds.min_x + buffer, bounds.max_x - buffer),
		randf_range(bounds.min_y + buffer, bounds.max_y - buffer)
	)
	unit.global_position = new_position
	unit.set_rotation(randf() * TAU)



func calculate_trait_averages() -> void:
	"""Calculate average traits of all living units and emit signal"""
	var unit_count = get_children().size()
	
	if unit_count == 0:
		Units.trait_averages_calculated.emit(0.0, 0.0, 0.0, 0.0, 0.0)
		return
	
	var totals = {"size": 0.0, "energy": 0.0, "speed": 0.0, "sense": 0.0, "carnivore": 0.0}
	
	# Sum all traits from living units
	for child in get_children():
		if child.has_method("get_reproduction_eligibility"):  # Ensure it's a unit
			totals.size += child.size
			totals.energy += child.energy
			totals.speed += child.speed
			totals.sense += child.sense
			totals.carnivore += child.predatory_threshold
	
	# Calculate and emit averages
	var averages = {
		"size": totals.size / unit_count,
		"energy": totals.energy / unit_count,
		"speed": totals.speed / unit_count,
		"sense": totals.sense / unit_count,
		"carnivore": totals.carnivore / unit_count
	}
	
	Units.trait_averages_calculated.emit(averages.size, averages.energy, averages.speed, averages.sense, averages.carnivore)
	
	Console.output.emit("	[TRAIT AVERAGES]\n	SZE   ENG   SPD   SNS   PRD")
	Console.output.emit("	%05.1f %05.1f %05.1f %05.1f %05.1f" % [averages.size, averages.energy, averages.speed, averages.sense, averages.carnivore])

func _on_new_generation() -> void:
	"""Calculate trait averages when a new generation starts"""
	calculate_trait_averages()
