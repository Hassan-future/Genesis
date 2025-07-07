extends Control

@onready var terminate_button: Button = $TerminateButton
@onready var minimize_button: CheckButton = $MinimizeButton
@onready var information_button: Button = $InformationButton
@onready var info_window: Window = $InfoWindow

# Add confirmation dialog
var confirmation_dialog: ConfirmationDialog

func _ready():
	terminate_button.pressed.connect(_on_terminate_pressed)
	minimize_button.toggled.connect(_on_minimize_toggled)
	information_button.pressed.connect(_on_information_pressed)
	
	# Connect the info window's close request signal to handle window closing
	info_window.close_requested.connect(_on_info_window_close_requested)
	info_window.show()
	
	# Create and setup confirmation dialog
	_setup_confirmation_dialog()

func _setup_confirmation_dialog():
	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = "Terminate and exit Genesis?"
	confirmation_dialog.title = "< Terminate >"
	
	# Connect the confirmation signals
	confirmation_dialog.confirmed.connect(_on_exit_confirmed)
	confirmation_dialog.canceled.connect(_on_exit_canceled)
	
	# Add the dialog to the scene tree
	add_child(confirmation_dialog)

func _on_terminate_pressed():
	# Show confirmation dialog instead of immediately quitting
	confirmation_dialog.popup_centered()

func _on_exit_confirmed():
	# User confirmed exit
	Console.output.emit("%s >> EXIT" % Console._time_request())
	get_tree().quit()

func _on_exit_canceled():
	# User canceled exit - dialog will close automatically
	pass

func _on_minimize_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		terminate_button.visible = true
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		terminate_button.visible = false

func _on_information_pressed():
	if info_window.visible:
		info_window.hide()
	else:
		info_window.show()

func _on_info_window_close_requested():
	info_window.hide()
