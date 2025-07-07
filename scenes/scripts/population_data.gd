extends Control

@onready var current_population_label: Label = $CurrentPopulation
@onready var max_population_label: Label = $MaxPopulation
@onready var population_progress_bar: ProgressBar = %PopulationProgressBar


func _ready() -> void:
	Units.unit_spawned.connect(_on_unit_spawned)
	Units.unit_destroyed.connect(_on_unit_destroyed)
	Units.start_unit_spawn.connect(_on_start_unit_spawn)
	Units.clear_all_units.connect(_on_clear_all_units)
	Global.program_reset.connect(_on_program_reset)

func _on_start_unit_spawn() -> void:
	update_max_population()

func _on_unit_spawned(_id) -> void:
	current_population_label.text = str(Units.current_population.size())
	update_max_population()
	
func _on_unit_destroyed(_id) -> void:
	current_population_label.text = str(Units.current_population.size())
	update_max_population()
	
func update_max_population() -> void:
	max_population_label.text = str(Units.max_population)
	population_progress_bar.max_value = Units.max_population
	if population_progress_bar.max_value < Units.requested_population:
		population_progress_bar.max_value = Units.requested_population
	if Units.current_population.size() > 0:
		population_progress_bar.value = Units.current_population.size()
	else:
		population_progress_bar.value = 0

func _on_clear_all_units() -> void:
	update_max_population()

func _on_program_reset() -> void:
	# Reset all population displays
	current_population_label.text = "0"
	max_population_label.text = "0"
	population_progress_bar.value = 0
	population_progress_bar.max_value = 1  # Set to 1 to avoid division by zero
	population_progress_bar.value = 0
