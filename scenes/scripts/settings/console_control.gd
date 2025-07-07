extends TextEdit

@onready var file_dialog: FileDialog = %FileDialog
@onready var console_search_text: LineEdit = %ConsoleSearchText
@onready var console_search_button: Button = %ConsoleSearchButton
@onready var console_copy_button: Button = %ConsoleCopyButton
@onready var console_export_button: Button = %ConsoleExportButton
@onready var console_clear_button: Button = %ConsoleClearButton
@onready var console_write_to_file_check: CheckBox = %ConsoleWriteToFileCheck
@onready var path_to_file_label: Label = %PathToFileLabel

var auto_save_file_path: String = ""
var is_auto_saving: bool = false

# Console optimization variables
const MAX_DISPLAY_LINES: int = 1000
var full_log_text: String = ""
var cache_file_path: String = ""
var displayed_lines: Array[String] = []

func _ready() -> void:
	Console.output.connect(_on_console_output)
	
	# Connect UI signals
	console_search_button.pressed.connect(_on_search_pressed)
	console_copy_button.pressed.connect(_on_copy_pressed)
	console_export_button.pressed.connect(_on_export_pressed)
	console_clear_button.pressed.connect(_on_clear_pressed)
	console_write_to_file_check.toggled.connect(_on_write_to_file_toggled)
	
	# Connect search text enter key
	console_search_text.text_submitted.connect(_on_search_text_submitted)
	
	# Setup file dialog
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.txt", "Text Files")
	file_dialog.file_selected.connect(_on_file_selected)
	
	# Setup cache file path
	cache_file_path = OS.get_user_data_dir() + "/genesis_console_cache.txt"
	
	# Set initial UI state
	path_to_file_label.text = "No file selected"
	editable = false  # Make console read-only

	Console.output.emit("GENESIS SIMULATOR")
	Console.output.emit("-----------------------")
	Console.output.emit("Evolution of Traits by Selection")
	Console.output.emit("-----------------------")
	
	
	var date_text = ("DATE: %s\ninitiating >>>\n" % Console._date_request())
	
	Console.output.emit(date_text)

func _on_console_output(output_text: String):
	print(output_text)
	var new_line = output_text + "\n"
	
	# Always add to full log
	full_log_text += new_line
	
	# Add to displayed lines array
	displayed_lines.append(output_text)
	
	# Limit displayed lines to MAX_DISPLAY_LINES
	if displayed_lines.size() > MAX_DISPLAY_LINES:
		displayed_lines.pop_front()
	
	# Update display text
	text = "\n".join(displayed_lines)
	scroll_vertical = get_line_count()
	
	# Handle file writing
	if is_auto_saving and auto_save_file_path != "":
		# For auto-save, append to the selected file
		_append_to_file(auto_save_file_path, new_line)
	else:
		# Always write to cache file when auto-save is disabled
		_write_to_cache_file()

func _write_to_cache_file():
	var file = FileAccess.open(cache_file_path, FileAccess.WRITE)
	if file:
		file.store_string(full_log_text)
		file.close()

func _append_to_file(file_path: String, _content: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		# For auto-save, we want to write the complete log to maintain consistency
		file.store_string(full_log_text)
		file.close()
	else:
		push_error("Failed to append to file: " + file_path)

func _on_search_pressed():
	_perform_search()

func _on_search_text_submitted(_new_text: String):
	_perform_search()

func _perform_search():
	var search_term = console_search_text.text.strip_edges()
	if search_term == "":
		return
	
	# Search in displayed text only
	var last_pos = text.rfind(search_term, -1)
	if last_pos != -1:
		# Calculate line number for the found position
		var line_number = text.substr(0, last_pos).count("\n")
		
		# Set cursor to the found position
		set_caret_line(line_number)
		set_caret_column(last_pos - text.rfind("\n", last_pos) - 1)
		
		# Scroll to show the found text
		scroll_vertical = line_number
		
		# Search successful - no visual feedback needed
		pass
	else:
		# Search failed - no visual feedback needed
		pass

func _on_copy_pressed():
	# Copy displayed text only
	DisplayServer.clipboard_set(text)

func _on_export_pressed():
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_clear_pressed():
	clear()
	displayed_lines.clear()
	full_log_text = ""
	# Clear cache file
	var file = FileAccess.open(cache_file_path, FileAccess.WRITE)
	if file:
		file.store_string("")
		file.close()

func _on_write_to_file_toggled(button_pressed: bool):
	is_auto_saving = button_pressed
	
	if button_pressed:
		if auto_save_file_path == "":
			# Need to select a file first
			file_dialog.popup_centered(Vector2i(800, 600))
		else:
			path_to_file_label.text = auto_save_file_path
	else:
		path_to_file_label.text = "Auto-save disabled (using cache)"

func _on_file_selected(path: String):
	if is_auto_saving:
		# Auto-save mode: set the file and save current content
		auto_save_file_path = path
		path_to_file_label.text = path
		# Save current full log immediately
		_save_full_log_to_file(path)
	else:
		# Manual export mode: export from cache or full log
		_export_full_log_to_file(path)

func _save_full_log_to_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(full_log_text)
		file.close()
	else:
		push_error("Failed to save console output to: " + file_path)

func _export_full_log_to_file(file_path: String):
	# Export the full log (not just displayed text)
	var export_text = full_log_text
	if export_text == "":
		# Fallback to cache file if full_log_text is empty
		var cache_file = FileAccess.open(cache_file_path, FileAccess.READ)
		if cache_file:
			export_text = cache_file.get_as_text()
			cache_file.close()
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(export_text)
		file.close()
	else:
		push_error("Failed to export console output to: " + file_path)

func _clear():
	clear()
	displayed_lines.clear()
	full_log_text = ""
	# Clear cache file
	var file = FileAccess.open(cache_file_path, FileAccess.WRITE)
	if file:
		file.store_string("")
		file.close()
