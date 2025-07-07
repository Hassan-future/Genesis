extends Control

@onready var population_value: SpinBox = %PopulationValue
@onready var population_random: SpinBox = %PopulationRandom
@onready var size_value: SpinBox = %SizeValue
@onready var size_random: SpinBox = %SizeRandom
@onready var energy_value: SpinBox = %EnergyValue
@onready var energy_random: SpinBox = %EnergyRandom
@onready var sense_value: SpinBox = %SenseValue
@onready var sense_random: SpinBox = %SenseRandom
@onready var speed_value: SpinBox = %SpeedValue
@onready var speed_random: SpinBox = %SpeedRandom
@onready var carnivore_value: SpinBox = %CarnivoreValue
@onready var carnivore_random: SpinBox = %CarnivoreRandom
@onready var tradeoff_check: CheckBox = %TradeoffCheck
@onready var tradeoff_threshold: SpinBox = %TradeoffThreshold

@onready var reproduction_threshold: SpinBox = %ReproductionThreshold
@onready var reproduction_randomize: CheckBox = %ReproductionRandomize

@onready var reproduction_energy_drain: SpinBox = %ReproductionEnergyDrain
@onready var movement_energy_drain: SpinBox = %MovementEnergyDrain



func _ready() -> void:
	Global.program_reset.connect(_on_program_reset)
	population_value.value_changed.connect(_on_population_value_changed)
	population_random.value_changed.connect(_on_population_random_changed)
	size_value.value_changed.connect(_on_size_value_changed)
	size_random.value_changed.connect(_on_size_random_changed)
	energy_value.value_changed.connect(_on_energy_value_changed)
	energy_random.value_changed.connect(_on_energy_random_changed)
	sense_value.value_changed.connect(_on_sense_value_changed)
	sense_random.value_changed.connect(_on_sense_random_changed)
	speed_value.value_changed.connect(_on_speed_value_changed)
	speed_random.value_changed.connect(_on_speed_random_changed)
	carnivore_value.value_changed.connect(_on_carnivore_value_changed)
	carnivore_random.value_changed.connect(_on_carnivore_random_changed)
	tradeoff_check.toggled.connect(_on_tradeoff_check_toggled)
	tradeoff_threshold.value_changed.connect(_on_tradeoff_changed)
	reproduction_threshold.value_changed.connect(_on_reproduction_threshold_changed)
	reproduction_randomize.toggled.connect(_on_reproduction_randomize_toggled)
	reproduction_energy_drain.value_changed.connect(_on_reproduction_energy_drain_changed)
	movement_energy_drain.value_changed.connect(_on_movement_energy_drain_changed)
	setup_values()

func setup_values() -> void:
	population_value.value = Units.population
	population_random.value = Units.population_random
	size_value.value = Units.size
	size_random.value = Units.size_random
	energy_value.value = Units.energy
	energy_random.value = Units.energy_random
	sense_value.value = Units.sense
	sense_random.value = Units.sense_random
	speed_value.value = Units.speed
	speed_random.value = Units.speed_random
	carnivore_value.value = Units.carnivore
	carnivore_random.value = Units.carnivore_random
	tradeoff_check.button_pressed = Units.is_tradeoff_enabled
	tradeoff_threshold.value = Units.tradeoff_threshold
	reproduction_threshold.value = Units.reproduction_threshold
	reproduction_randomize.button_pressed = Units.reproduction_randomization
	reproduction_energy_drain.value = Units.parent_energy_drain
	movement_energy_drain.value = Units.movement_energy_drain

func _on_program_reset() -> void:
	await get_tree().create_timer(0.1).timeout
	setup_values()

func _on_population_value_changed(value: float) -> void:
	Units.population = value

func _on_population_random_changed(value: float) -> void:
	Units.population_random = value

func _on_size_value_changed(value: float) -> void:
	Units.size = value

func _on_size_random_changed(value: float) -> void:
	Units.size_random = value

func _on_energy_value_changed(value: float) -> void:
	Units.energy = value

func _on_energy_random_changed(value: float) -> void:
	Units.energy_random = value

func _on_sense_value_changed(value: float) -> void:
	Units.sense = value

func _on_sense_random_changed(value: float) -> void:
	Units.sense_random = value

func _on_speed_value_changed(value: float) -> void:
	Units.speed = value

func _on_speed_random_changed(value: float) -> void:
	Units.speed_random = value

func _on_carnivore_value_changed(value: float) -> void:
	Units.carnivore = value

func _on_carnivore_random_changed(value: float) -> void:
	Units.carnivore_random = value

func _on_tradeoff_check_toggled(toggled: bool) -> void:
	Units.is_tradeoff_enabled = toggled

func _on_tradeoff_changed(value: float) -> void:
	Units.tradeoff_threshold = value

func _on_reproduction_threshold_changed(value: float) -> void:
	Units.reproduction_threshold = value

func _on_reproduction_randomize_toggled(toggled: bool) -> void:
	Units.reproduction_randomization = toggled

func _on_reproduction_energy_drain_changed(value: float) -> void:
	Units.parent_energy_drain = value

func _on_movement_energy_drain_changed(value: float) -> void:
	Units.movement_energy_drain = value
