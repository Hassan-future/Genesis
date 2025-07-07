extends Control
@onready var population_growth_graph: Graph2D = %PopulationGrowthGraph
@onready var population_growth_series: LineSeries = %PopulationGrowthSeries

@onready var traits_evolution_graph: Graph2D = %TraitsEvolutionGraph
@onready var size_series: LineSeries = %SizeSeries
@onready var energy_series: LineSeries = %EnergySeries
@onready var speed_series: LineSeries = %SpeedSeries
@onready var sense_series: LineSeries = %SenseSeries
@onready var predatory_series: LineSeries = %PredatorySeries

@onready var trait_size: CheckBox = %TraitSize
@onready var trait_energy: CheckBox = %TraitEnergy
@onready var trait_speed: CheckBox = %TraitSpeed
@onready var trait_sense: CheckBox = %TraitSense
@onready var trait_predatory: CheckBox = %TraitPredatory


@onready var population_graph_button: Button = %PopulationGraphButton
@onready var traits_evolution_graph_button: Button = %TraitsEvolutionGraphButton
@onready var file_dialog: FileDialog = %FileDialog


@onready var population_against_generation_renderer: Control = %PopulationAgainstGenerationRenderer
@onready var traits_evolution_renderer: Control = %TraitsEvolutionRenderer

@onready var traits_distribution_graph_button: Button = %TraitsDistributionGraphButton
@onready var trait_distribution: Control = %TraitDistribution
@onready var radar_graph: RadarGraph = %RadarGraph

# Constants for radar graph animation
const RADAR_ANIMATION_DURATION := 0.1

# Track which renderer to screenshot
var current_renderer_to_save: Control = null

# Track maximum trait values for Y-axis scaling
var max_trait_value: float = 0.0

# Track maximum values for radar graph scaling
var radar_max_values: Dictionary = {
	"size": 100.0,
	"energy": 100.0, 
	"speed": 100.0,
	"sense": 100.0,
	"predatory": 100.0
}

func _ready() -> void:
	Units.spawn_completed.connect(graph_population) # this works only for the first generation
	Global.new_generation.connect(graph_population)
	Units.trait_averages_calculated.connect(graph_traits)
	Units.trait_averages_calculated.connect(update_radar_graph)
	
	# Connect to program reset signal to reset all graphs
	Global.program_reset.connect(_on_program_reset)
	
	# Connect checkbox signals
	trait_size.toggled.connect(_on_trait_size_toggled)
	trait_energy.toggled.connect(_on_trait_energy_toggled)
	trait_speed.toggled.connect(_on_trait_speed_toggled)
	trait_sense.toggled.connect(_on_trait_sense_toggled)
	trait_predatory.toggled.connect(_on_trait_predatory_toggled)
	
	# Connect button signals for screenshot functionality
	population_graph_button.pressed.connect(_on_population_graph_button_pressed)
	traits_evolution_graph_button.pressed.connect(_on_traits_evolution_graph_button_pressed)
	traits_distribution_graph_button.pressed.connect(_on_traits_distribution_graph_button_pressed)
	
	# Setup file dialog for PNG export
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.png", "PNG Images")
	file_dialog.file_selected.connect(_on_file_selected)
	
	# Set checkboxes to pressed (on) by default
	trait_size.button_pressed = true
	trait_energy.button_pressed = true
	trait_speed.button_pressed = true
	trait_sense.button_pressed = true
	trait_predatory.button_pressed = true
	
	# Setup radar graph
	setup_radar_graph()
	
	#population graph
	population_growth_series = LineSeries.new(Color(1.0,1.0,1.0), 0.5)
	population_growth_graph.add_series(population_growth_series)

	#traits graphs
	size_series = LineSeries.new(Color(0.25,0.25,0.5), 0.5)
	energy_series = LineSeries.new(Color(0.25,0.5,0.5), 0.5)
	speed_series = LineSeries.new(Color(0.25,0.5,0.25), 0.5)
	sense_series = LineSeries.new(Color(0.5,0.5,0.25), 0.5)
	predatory_series = LineSeries.new(Color(0.5,0.25,0.25), 0.5)
	
	traits_evolution_graph.add_series(size_series)
	traits_evolution_graph.add_series(energy_series)
	traits_evolution_graph.add_series(speed_series)
	traits_evolution_graph.add_series(sense_series)
	traits_evolution_graph.add_series(predatory_series)

func setup_radar_graph() -> void:
	"""Initialize the radar graph with trait labels and configuration"""
	if not radar_graph:
		return
		
	# Set up the radar graph with 5 traits
	radar_graph.key_count = 5
	radar_graph.min_value = 0.0
	radar_graph.max_value = 100.0  # Start with 100.0, will scale up if needed
	
	# Set up trait titles
	#radar_graph.set_item_title(0, "Size")
	#radar_graph.set_item_title(1, "Energy") 
	#radar_graph.set_item_title(2, "Speed")
	#radar_graph.set_item_title(3, "Sense")
	#radar_graph.set_item_title(4, "Predation")
	
	# Initialize all values to 0
	for i in range(5):
		radar_graph.set_item_value(i, 0.0)

func update_radar_graph(size_avg: float, energy_avg: float, speed_avg: float, sense_avg: float, predatory_avg: float) -> void:
	"""Update radar graph with current trait averages using smooth animations"""
	if not radar_graph:
		return
	
	# Update maximum values for proper scaling
	var trait_values = [size_avg, energy_avg, speed_avg, sense_avg, predatory_avg]
	var current_max = trait_values.max()
	
	# Set radar graph max value: keep at 100.0 unless any trait exceeds 100.0
	if current_max > 100.0:
		radar_graph.max_value = current_max + 10.0
	else:
		radar_graph.max_value = 100.0
	
	# Create smooth transitions for each trait value
	var tween := create_tween().set_parallel()
	
	# Animate each trait value to its new average
	tween.tween_property(radar_graph, "items/key_0/value", size_avg, RADAR_ANIMATION_DURATION)
	tween.tween_property(radar_graph, "items/key_1/value", energy_avg, RADAR_ANIMATION_DURATION)
	tween.tween_property(radar_graph, "items/key_2/value", speed_avg, RADAR_ANIMATION_DURATION)
	tween.tween_property(radar_graph, "items/key_3/value", sense_avg, RADAR_ANIMATION_DURATION)
	tween.tween_property(radar_graph, "items/key_4/value", predatory_avg, RADAR_ANIMATION_DURATION)

func _on_trait_size_toggled(button_pressed: bool) -> void:
	if button_pressed:
		traits_evolution_graph.add_series(size_series)
	else:
		traits_evolution_graph.remove_series(size_series)

func _on_trait_energy_toggled(button_pressed: bool) -> void:
	if button_pressed:
		traits_evolution_graph.add_series(energy_series)
	else:
		traits_evolution_graph.remove_series(energy_series)

func _on_trait_speed_toggled(button_pressed: bool) -> void:
	if button_pressed:
		traits_evolution_graph.add_series(speed_series)
	else:
		traits_evolution_graph.remove_series(speed_series)

func _on_trait_sense_toggled(button_pressed: bool) -> void:
	if button_pressed:
		traits_evolution_graph.add_series(sense_series)
	else:
		traits_evolution_graph.remove_series(sense_series)

func _on_trait_predatory_toggled(button_pressed: bool) -> void:
	if button_pressed:
		traits_evolution_graph.add_series(predatory_series)
	else:
		traits_evolution_graph.remove_series(predatory_series)

func graph_population() -> void:
	
	population_growth_graph.x_max = Global.generation
	traits_evolution_graph.x_max = Global.generation
	
	population_growth_graph.y_max = Units.max_population
	population_growth_series.add_point(Global.generation,Units.current_population.size())

func graph_traits(size_avg: float, energy_avg: float, speed_avg: float, sense_avg: float, carnivore_avg: float) -> void:
	# Update maximum trait value for proper Y-axis scaling
	var current_max = max(max(size_avg, energy_avg), max(max(speed_avg, sense_avg), carnivore_avg))
	if current_max > max_trait_value:
		max_trait_value = current_max
		traits_evolution_graph.y_max = max_trait_value
	
	# Add data points to each series
	size_series.add_point(Global.generation, size_avg)
	energy_series.add_point(Global.generation, energy_avg)
	speed_series.add_point(Global.generation, speed_avg)
	sense_series.add_point(Global.generation, sense_avg)
	predatory_series.add_point(Global.generation, carnivore_avg)

func _on_program_reset() -> void:
	"""Resets all graphs and their scaling variables."""
	
	# Clear population growth graph data
	population_growth_graph.clear_data()
	
	# Clear traits evolution graph data
	traits_evolution_graph.clear_data()
	
	# Reset radar graph values to zero
	for i in range(5):
		radar_graph.set_item_value(i, 0.0)
	
	# Reset radar graph scaling
	radar_graph.max_value = 100.0
	
	# Reset scaling variables
	max_trait_value = 0.0
	radar_max_values = {
		"size": 100.0,
		"energy": 100.0, 
		"speed": 100.0,
		"sense": 100.0,
		"predatory": 100.0
	}
	
	# Reset graph axis ranges
	population_growth_graph.x_max = 10.0
	population_growth_graph.y_max = 100.0
	traits_evolution_graph.x_max = 10.0
	traits_evolution_graph.y_max = 100.0


func _on_population_graph_button_pressed() -> void:
	current_renderer_to_save = population_against_generation_renderer
	var default_filename = "population_graph_gen_%d.png" % Global.generation
	file_dialog.current_file = default_filename
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_traits_evolution_graph_button_pressed() -> void:
	current_renderer_to_save = traits_evolution_renderer
	var default_filename = "traits_evolution_gen_%d.png" % Global.generation
	file_dialog.current_file = default_filename
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_traits_distribution_graph_button_pressed() -> void:
	current_renderer_to_save = trait_distribution
	var default_filename = "traits_distribution_gen_%d.png" % Global.generation
	file_dialog.current_file = default_filename
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_file_selected(path: String) -> void:
	if current_renderer_to_save == null:
		return
	
	# Take screenshot of the selected renderer
	_save_renderer_screenshot(current_renderer_to_save, path)
	current_renderer_to_save = null

func _save_renderer_screenshot(renderer: Control, file_path: String) -> void:
	# Wait for the next frame to ensure everything is rendered
	await get_tree().process_frame
	
	# Get the main viewport
	var viewport = get_viewport()
	
	# Get the renderer's global position and size
	var global_pos = renderer.global_position
	var size_n = renderer.size
	
	# Get the full screen texture
	var full_texture = viewport.get_texture()
	var full_image = full_texture.get_image()
	
	# Create a new image with the same format as the source image
	var cropped_image = Image.create(int(size_n.x), int(size_n.y), false, full_image.get_format())
	
	# Copy the relevant portion from the full screen
	cropped_image.blit_rect(full_image, Rect2i(int(global_pos.x), int(global_pos.y), int(size_n.x), int(size_n.y)), Vector2i.ZERO)
	
	# Save the cropped image as PNG
	var error = cropped_image.save_png(file_path)
	if error != OK:
		push_error("Image save failed: " + file_path)
	else:
		Console.output.emit("Image saved to: " + file_path)
