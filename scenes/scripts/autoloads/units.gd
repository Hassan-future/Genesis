extends Node

const HERBIVORE_COLOR = Color(0.25, 0.5, 0.25)
const CARNIVORE_COLOR = Color(0.5, 0.25, 0.25)
const DEFAULTS_FILE_PATH = "user://unit_defaults.json"

signal unit_spawned
signal unit_destroyed
signal clear_all_units
@warning_ignore("unused_signal")
signal start_unit_spawn
@warning_ignore("unused_signal")
signal start_reproduction_spawn
signal spawn_completed
@warning_ignore("unused_signal")
signal reproduction_completed
@warning_ignore("unused_signal")
signal trait_averages_calculated(size_avg: float, energy_avg: float, speed_avg: float, sense_avg: float, carnivore_avg: float)

var is_ready:bool = false
var current_population: Array = []
var max_population: int = 0
var requested_population: int = 0
var next_unit_id: int = 1

# Default values
var population: float = 100.0
var population_random: float = 0.0
var carnivore: float = 50.0
var carnivore_random: float = 10.0
var speed: float = 100.0
var speed_random: float = 10.0
var energy: float = 100.0
var energy_random: float = 10.0
var size: float = 100.0
var size_random: float = 10.0
var sense: float = 100.0 
var sense_random: float = 10.0
var is_tradeoff_enabled: bool = true
var tradeoff_threshold: float = 10.0

var reproduction_threshold: float = 80.0
var reproduction_randomization: bool = true
var parent_energy_drain: float = 60.0
var movement_energy_drain: float = 2.0

# Boundary behavior options
enum BoundaryBehavior {
	TELEPORT_RANDOM,    # Teleport to random position (most robust)
	CLAMP_AND_REVERSE,  # Clamp position and reverse direction
	ROTATE_ONLY         # Original behavior - just rotate 180 degrees
}
var boundary_behavior: BoundaryBehavior = BoundaryBehavior.TELEPORT_RANDOM

func _ready() -> void:
	Global.program_reset.connect(_on_program_reset)
	spawn_completed.connect(_on_spawn_completed)
	unit_spawned.connect(_on_unit_spawned)
	unit_destroyed.connect(_on_unit_destroyed)
	clear_all_units.connect(_on_clear_all_units)
	# Save default values to file when ready
	save_default_values()

func _on_spawn_completed() -> void:
	is_ready = true

func _on_unit_destroyed(id) -> void:
	current_population.erase(id)

func _on_unit_spawned(id) -> void:
	current_population.append(id)
	update_max_population()
	if id >= next_unit_id:
		next_unit_id = id + 1

func _on_clear_all_units() -> void:
	current_population.clear()

func update_max_population() -> void:
	if current_population.size() >= max_population:
		max_population = current_population.size()

func _on_program_reset() -> void:
	load_default_values()
	current_population.clear()
	max_population = 0
	next_unit_id = 1
	update_max_population()

func save_default_values() -> void:
	var defaults = {
		"population": population,
		"population_random": population_random,
		"carnivore": carnivore,
		"carnivore_random": carnivore_random,
		"speed": speed,
		"speed_random": speed_random,
		"energy": energy,
		"energy_random": energy_random,
		"size": size,
		"size_random": size_random,
		"sense": sense,
		"sense_random": sense_random,
		"is_tradeoff_enabled": is_tradeoff_enabled,
		"tradeoff_threshold": tradeoff_threshold,
		"reproduction_threshold": reproduction_threshold,
		"reproduction_randomization": reproduction_randomization,
		"parent_energy_drain": parent_energy_drain,
		"movement_energy_drain": movement_energy_drain,
		"boundary_behavior": boundary_behavior
	}
	
	var file = FileAccess.open(DEFAULTS_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(defaults))
		file.close()

func load_default_values() -> void:
	if not FileAccess.file_exists(DEFAULTS_FILE_PATH):
		return
	
	var file = FileAccess.open(DEFAULTS_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var defaults = json.data
			
			# Restore all default values
			population = defaults.get("population", 100.0)
			population_random = defaults.get("population_random", 0.0)
			carnivore = defaults.get("carnivore", 50.0)
			carnivore_random = defaults.get("carnivore_random", 10.0)
			speed = defaults.get("speed", 100.0)
			speed_random = defaults.get("speed_random", 10.0)
			energy = defaults.get("energy", 100.0)
			energy_random = defaults.get("energy_random", 10.0)
			size = defaults.get("size", 100.0)
			size_random = defaults.get("size_random", 10.0)
			sense = defaults.get("sense", 100.0)
			sense_random = defaults.get("sense_random", 10.0)
			is_tradeoff_enabled = defaults.get("is_tradeoff_enabled", true)
			tradeoff_threshold = defaults.get("tradeoff_threshold", 10.0)
			reproduction_threshold = defaults.get("reproduction_threshold", 80.0)
			reproduction_randomization = defaults.get("reproduction_randomization", true)
			parent_energy_drain = defaults.get("parent_energy_drain", 60.0)
			movement_energy_drain = defaults.get("movement_energy_drain", 2.0)
			boundary_behavior = defaults.get("boundary_behavior", BoundaryBehavior.TELEPORT_RANDOM)
