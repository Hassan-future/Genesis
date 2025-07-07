extends Control


@onready var start_button: Button = %StartButton
@onready var pause_button: Button = %PauseButton
@onready var stop_button: Button = %StopButton
@onready var reset_button: Button = %ResetButon



func _ready() -> void:
	Global.simulation_started.connect(_on_simulaion_started)
	Global.program_stopped.connect(_on_program_stopped)
	Global.program_started.connect(_on_program_started)
	Global.new_generation.connect(_on_new_generation)
	Units.start_reproduction_spawn.connect(_on_spawning_started)
	Units.start_unit_spawn.connect(_on_initial_unit_spawning_started)
	Units.reproduction_completed.connect(_on_reproduction_completed)
	Food.start_spawn.connect(_on_food_spawning_started)
	Food.spawn_completed.connect(_on_spawning_completed)
	start_button.pressed.connect(_on_start_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	stop_button.pressed.connect(_on_stop_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	
	
	
	pause_button.disabled = true
	stop_button.disabled = true



func _on_start_button_pressed() -> void:
	if Global.is_program_started:
		Console.output.emit("%s >> RESUME" % Console._time_request())
		Global.is_paused = false
		pause_button.disabled = false
		start_button.disabled = true
		
	else:
		Console.output.emit("%s >> START" % Console._time_request())
		Global.emit_signal("program_started")
		start_button.disabled = true
		reset_button.disabled = true
		



func _on_pause_button_pressed() -> void:
	Console.output.emit("%s >> PAUSE" % Console._time_request())
	Global.emit_signal("program_paused")

	start_button.disabled = false
	pause_button.disabled = true


func _on_stop_button_pressed() -> void:
	Console.output.emit("%s >> STOP" % Console._time_request())
	Global.emit_signal("program_stopped")



func _on_simulaion_started() -> void:
	start_button.disabled = true
	pause_button.disabled = false
	stop_button.disabled = false
	reset_button.disabled = false


func _on_program_started() -> void:
	# Disable pause and stop buttons during initial setup (food + unit spawning)
	pause_button.disabled = true
	stop_button.disabled = true


func _on_initial_unit_spawning_started() -> void:
	# Disable pause and stop buttons during initial unit spawning
	pause_button.disabled = true
	stop_button.disabled = true


func _on_new_generation() -> void:
	# Disable pause and stop buttons when new generation starts (spawning phase)
	pause_button.disabled = true
	stop_button.disabled = true


func _on_spawning_started() -> void:
	# Disable pause and stop buttons during unit reproduction spawning
	pause_button.disabled = true
	stop_button.disabled = true


func _on_reproduction_completed() -> void:
	# Keep buttons disabled as food spawning will start next
	pause_button.disabled = true
	stop_button.disabled = true


func _on_food_spawning_started(_amount) -> void:
	# Disable pause and stop buttons during food spawning
	pause_button.disabled = true
	stop_button.disabled = true


func _on_spawning_completed() -> void:
	# Re-enable pause and stop buttons after all spawning is complete
	# Only enable if simulation is actually running and not paused
	if Global.is_simulation_running and not Global.is_paused:
		pause_button.disabled = false
		stop_button.disabled = false
	# For initial spawning, buttons will be enabled by _on_simulaion_started signal


func _on_reset_button_pressed() -> void:
	Console.output.emit("%s >> RESET" % Console._time_request())
	Global.program_stopped.emit()
	Global.program_reset.emit()
	await get_tree().create_timer(2.0).timeout
	Console.output.emit("%s Parameters Restored!" % Console._time_request())



func _on_program_stopped() -> void:
	start_button.disabled = false
	pause_button.disabled = true
	stop_button.disabled = true
	reset_button.disabled = false
