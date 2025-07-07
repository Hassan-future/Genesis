extends Node

#program control signals
signal program_started
signal program_paused
signal program_stopped
@warning_ignore("unused_signal")
signal program_reset
var is_program_started: bool = false

signal simulation_started
var is_simulation_running: bool = false
var is_paused: bool = true

@warning_ignore("unused_signal")
signal console_output
var console

signal new_generation
var generation_time:float = 10.0
var generation: int = 0 
var speed:float = 1.0 # change speed

var time_spent: float = 0.0
var elapsed_time: float = 0.0

var is_sense_area_visible: bool = false

# Track if parameters have been logged for this simulation session
var parameters_logged: bool = false

func _ready() -> void:
	new_generation.connect(_on_new_generation)
	program_started.connect(_on_program_started)
	program_paused.connect(_on_program_paused)
	program_stopped.connect(_on_program_stopped)
	
	simulation_started.connect(_on_simulation_started)
	
	Food.spawn_completed.connect(_on_food_ready)
	Units.spawn_completed.connect(_on_units_ready)
	Units.reproduction_completed.connect(_on_reproduction_ready)

func _process(delta: float) -> void:
	if is_simulation_running and not is_paused:
		time_spent += delta
		elapsed_time = time_spent * speed
		if elapsed_time >= generation_time:
			generation += 1
			time_spent = 0.0
			emit_signal("new_generation")

func _on_new_generation() -> void:
	Console.output.emit("%s New Generation >>> %03d" % [Console._time_request(),generation])
	# Pause simulation during generation transition
	is_paused = true
	# Start reproduction first, then food spawning
	Units.start_reproduction_spawn.emit()

func _on_simulation_started() -> void:
	is_simulation_running = true

func _on_program_started() -> void:
	is_program_started = true
	is_paused = true  # Keep paused until first generation is ready
	generation = 1  # Start with generation 1
	
	# Log parameters only when program starts for the first time
	if not parameters_logged:
		log_simulation_parameters()
		parameters_logged = true
	
	Food.start_spawn.emit(Food.amount)

func _on_program_stopped():
	is_program_started = false
	is_simulation_running = false
	is_paused = true
	generation = 0
	time_spent = 0.0
	# Reset parameter logging flag so it will log again on next start
	parameters_logged = false
	Food.clear_all_food.emit()
	Units.clear_all_units.emit()

func _on_program_paused():
	is_paused = true

func _on_food_ready():
	if not is_simulation_running: # First generation setup
		Units.start_unit_spawn.emit()
	else:
		# Resume simulation after food spawning in new generation
		is_paused = false
		Console.output.emit("%s Generation %03d" % [Console._time_request(), generation])

func _on_units_ready():
	if not is_simulation_running:
		# First generation complete
		simulation_started.emit()
		is_paused = false
		Console.output.emit("%s Generation %03d" % [Console._time_request(), generation])

func _on_reproduction_ready():
	# Reproduction completed, food spawning will be triggered by the reproduction_completed signal
	Console.output.emit("%s Reproduction completed!" % Console._time_request())

func log_simulation_parameters() -> void:
	Console.output.emit("SIMULATION PARAMETERS & SETUP DETAILS")
	Console.output.emit("-------------------------------------")
	
	# Global Settings
	Console.output.emit("[GLOBAL SETTINGS]")
	Console.output.emit("	Speed: %.1f" % speed)
	Console.output.emit("	Generation Time: %.1f seconds" % generation_time)
	Console.output.emit("	Effective Gen Time: %.1f seconds" % (generation_time / speed))
	
	# Unit Parameters
	Console.output.emit("[UNIT PARAMETERS]")
	Console.output.emit("	Population: %.1f ± %.1f" % [Units.population, Units.population_random])
	Console.output.emit("	Size: %.1f ± %.1f" % [Units.size, Units.size_random])
	Console.output.emit("	Energy: %.1f ± %.1f" % [Units.energy, Units.energy_random])
	Console.output.emit("	Sense Range: %.1f ± %.1f" % [Units.sense, Units.sense_random])
	Console.output.emit("	Movement Speed: %.1f ± %.1f" % [Units.speed, Units.speed_random])
	Console.output.emit("	Is Carnivore?: %.1f ± %.1f" % [Units.carnivore, Units.carnivore_random])
	
	# Tradeoff Settings
	Console.output.emit("[TRADEOFF SETTINGS]")
	Console.output.emit("	Tradeoff Enabled: %s" % ("YES" if Units.is_tradeoff_enabled else "NO"))
	Console.output.emit("	Tradeoff Threshold: %.1f%%" % Units.tradeoff_threshold)
	
	# Reproduction Settings
	Console.output.emit("[REPRODUCTION SETTINGS]")
	Console.output.emit("	Reproduction Threshold: %.1f%%" % Units.reproduction_threshold)
	Console.output.emit("	Reproduction Randomization: %s" % ("YES" if Units.reproduction_randomization else "NO"))
	
	# Energy Drain Settings
	Console.output.emit("[ENERGY DRAIN SETTINGS]")
	Console.output.emit("	Parent Energy Drain: %.1f%%" % Units.parent_energy_drain)
	Console.output.emit("	Movement Energy Drain: %.1f/sec" % Units.movement_energy_drain)
	
	# Food Supply Settings
	Console.output.emit("[FOOD SUPPLY SETTINGS]")
	Console.output.emit("	Initial Amount: %d" % Food.amount)
	Console.output.emit("	Increment per Generation: %d" % Food.increment)
	Console.output.emit("	Max Amount: %d (Hold: %s)" % [Food.max_amount, "YES" if Food.hold_max else "NO"])
	Console.output.emit("	Min Amount: %d (Hold: %s)" % [Food.min_amount, "YES" if Food.hold_min else "NO"])
	Console.output.emit("	Hold Amount: %s" % ("YES" if Food.hold_amount else "NO"))
	


	
	Console.output.emit("SIMULATION READY - Parameters Logged")
	Console.output.emit("")
