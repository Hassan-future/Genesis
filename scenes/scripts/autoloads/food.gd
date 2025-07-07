extends Node

const DEFAULTS_FILE_PATH = "user://food_defaults.json"

@warning_ignore("unused_signal")
signal start_spawn
signal spawn_completed
var is_ready:bool = false

# Default values
var amount: int = 10
var increment: int = 0
var max_amount: int = 100
var min_amount: int = 10
var hold_max: bool = true
var hold_min: bool = true
var hold_amount: bool = false

@warning_ignore("unused_signal")
signal settings_changed
@warning_ignore("unused_signal")
signal clear_all_food

func _ready() -> void:
	
	spawn_completed.connect(_on_spawn_completed)
	Global.program_reset.connect(_on_program_reset)
	
	# Save default values to file when ready
	save_default_values()

func _on_spawn_completed() -> void:
	is_ready = true


func _on_program_reset() -> void:
	load_default_values()

func save_default_values() -> void:
	var defaults = {
		"amount": amount,
		"increment": increment,
		"max_amount": max_amount,
		"min_amount": min_amount,
		"hold_max": hold_max,
		"hold_min": hold_min,
		"hold_amount": hold_amount
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
			amount = defaults.get("amount", 10)
			increment = defaults.get("increment", 0)
			max_amount = defaults.get("max_amount", 100)
			min_amount = defaults.get("min_amount", 10)
			hold_max = defaults.get("hold_max", true)
			hold_min = defaults.get("hold_min", true)
			hold_amount = defaults.get("hold_amount", false)
