extends Control
@onready var food_supply_amount: SpinBox = %FoodSupplyAmount
@onready var food_supply_increment: SpinBox = %FoodSupplyIncrement
@onready var food_supply_hold: CheckBox = %FoodSupplyHold
@onready var food_supply_max: SpinBox = %FoodSupplyMax
@onready var food_supply_max_hold: CheckBox = %FoodSupplyMaxHold
@onready var food_supply_min: SpinBox = %FoodSupplyMin
@onready var food_supply_min_hold: CheckBox = %FoodSupplyMinHold


func _ready() -> void:
	Global.program_reset.connect(_on_program_reset)
	food_supply_amount.value_changed.connect(_on_food_supply_amount_changed)
	food_supply_increment.value_changed.connect(_on_food_supply_increment_changed)
	food_supply_hold.toggled.connect(_on_food_supply_hold_toggled)
	food_supply_max.value_changed.connect(_on_food_supply_max_changed)
	food_supply_max_hold.toggled.connect(_on_food_supply_max_hold_toggled)
	food_supply_min.value_changed.connect(_on_food_supply_min_changed)
	food_supply_min_hold.toggled.connect(_on_food_supply_min_hold_toggled)
	setup_values()

func setup_values() -> void:
	food_supply_amount.value = float(Food.amount)
	food_supply_increment.value = float(Food.increment)
	food_supply_hold.button_pressed = Food.hold_amount
	food_supply_max.value = float(Food.max_amount)
	food_supply_max_hold.button_pressed = Food.hold_max
	food_supply_min.value = float(Food.min_amount)
	food_supply_min_hold.button_pressed = Food.hold_min

func _on_food_supply_amount_changed(value: float) -> void:
	Food.amount = int(value)

func _on_food_supply_increment_changed(value: float) -> void:
	Food.increment = int(value)

func _on_food_supply_hold_toggled(toggled_on: bool) -> void:
	Food.hold_amount = toggled_on

func _on_food_supply_max_changed(value: float) -> void:
	Food.max_amount = int(value)

func _on_food_supply_max_hold_toggled(toggled_on: bool) -> void:
	Food.hold_max = toggled_on

func _on_food_supply_min_changed(value: float) -> void:
	Food.min_amount = int(value)

func _on_food_supply_min_hold_toggled(toggled_on: bool) -> void:
	Food.hold_min = toggled_on

func _on_program_reset() -> void:
	setup_values()
