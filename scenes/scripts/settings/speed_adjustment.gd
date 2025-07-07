extends HBoxContainer

@onready var speed_spin: SpinBox = $Speed
var current_speed: float = 0.0

@onready var gen_time_label: Label = $GenTime
@onready var elapsed_time_label: Label = $ElapsedTime

var elapsed_seconds: float = 0.0
var is_running: bool = false

func _ready() -> void:
	Global.program_started.connect(_on_program_started)
	Global.program_stopped.connect(_on_program_stopped)
	Global.new_generation.connect(_on_new_generation)
	speed_spin.value = Global.speed
	gen_time_label.text = "%03d" % Global.generation
	current_speed = Global.speed

func _on_speed_label_value_changed(value: float) -> void:
	Global.speed = value
	current_speed = value
	Console.output.emit("%s Speed changed to: %2.1f > GenTime: %2.1f sec." % [Console._time_request(), value, (Global.generation_time/Global.speed)])

func _process(delta: float) -> void:
	if is_running and not Global.is_paused:
		elapsed_seconds += delta
		@warning_ignore("integer_division")
		var minutes = int(elapsed_seconds) / 60
		var seconds = int(elapsed_seconds) % 60
		elapsed_time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_new_generation() -> void:
	gen_time_label.text = "%03d" % Global.generation

func _on_program_started() -> void:
	elapsed_seconds = 0.0
	is_running = true
	gen_time_label.text = "%03d" % Global.generation

func _on_program_stopped() -> void:
	is_running = false
	elapsed_seconds = 0.0
	elapsed_time_label.text = "00:00"
	gen_time_label.text = "%03d" % Global.generation
