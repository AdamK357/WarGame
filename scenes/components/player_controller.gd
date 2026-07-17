extends Node2D
class_name PlayerController

@onready var targeting_arrow: PackedScene = preload("res://scenes/ui/targeting_arrow.tscn")
var current_arrow: Node2D

@export var team: int = -1
var faction_data_instance: FactionData
static var instance: PlayerController = null

var selected_position: Vector2 = Vector2.ZERO
var selected_source: BaseStructure = null
var hovered_structure: BaseStructure = null

var is_choosing_target: bool = false

enum InteractionMode {NONE, CHOOSE_POSITION, CHOOSE_STRUCTURE, CHOOSE_UNIT}
var interaction_mode: InteractionMode = InteractionMode.NONE

var current_ability_index: int = 0

var unit_send_mode: Globals.UnitSendMode = Globals.UnitSendMode.PERCENT
var send_value: float = 0.5

func _ready():
	instance = self
	connect_to_signals()
	retrieve_faction_data_instance()


func _exit_tree(): # ensures that when queue_free() is called, any references to this playercontroller become null.
	if instance == self:
		instance = null


func _process(_delta):
	if is_choosing_target:
		if current_arrow == null:
			current_arrow = targeting_arrow.instantiate()
			add_child(current_arrow)
			current_arrow.global_position = selected_source.global_position
		current_arrow.look_at(get_global_mouse_position())
	elif current_arrow != null:
		current_arrow.queue_free()
		current_arrow = null

func select_source(structure: BaseStructure) -> void:
	if structure.get_team() != team:
		return
	GameManager.select_source_structure(structure)


func select_target(structure: BaseStructure) -> void:
	GameManager.select_target_structure(structure)


func set_hovered_structure(structure: BaseStructure = null):
	hovered_structure = structure


func retrieve_faction_data_instance():
	faction_data_instance = FactionManager.get_controller(MultiplayerManager.get_local_team_id()).faction_data_instance


func connect_to_signals():
	StructureManager.structure_registered.connect(connect_structure_signals)
	initial_connect_structure_signals()
	var player_menu: PlayerMenu = get_tree().get_root().get_node("/root/Map/UI/PlayerMenu")
	if player_menu:
		player_menu.connect("ability_pressed", _handle_ability_pressed)

# Connects to a structure's signals using the structure ID to get a reference to the structure.
# Requires StructureManager._structures_by_id to already contain the structure and structure id.
# Only called by the structure_registered function in StructureManager.
func connect_structure_signals(structure_id: int):
	var structure = StructureManager.get_structure(structure_id)
	structure.mouse_hover_entered.connect(set_hovered_structure)
	structure.mouse_hover_exited.connect(set_hovered_structure)
	#print("signals connected to controller" + str(MultiplayerManager.get_local_peer_id()))

# Connects to each structure's signals that already exist in the map on ready using direct references to the structure.
func initial_connect_structure_signals():
	var structure_group := get_tree().get_nodes_in_group("structures")
	for structure in structure_group:
		structure.mouse_hover_entered.connect(set_hovered_structure)
		structure.mouse_hover_exited.connect(set_hovered_structure)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_handle_left_click()
			MOUSE_BUTTON_RIGHT:
				_handle_right_click()

	if event.is_action_pressed("1"):
		_handle_ability_pressed(1)
	elif event.is_action_pressed("2"):
		_handle_ability_pressed(2)


func _handle_left_click():
	match interaction_mode:
		InteractionMode.NONE:
			var structure := hovered_structure
			if structure == null:
				return
				
			if structure.get_team() == team:
				# Clicked own structure
				if selected_source == null:
					selected_source = structure
					selected_source.set_selected(true)
					is_choosing_target = true
				else:
					_send_from_selected_to(structure)
			else:
				# Clicked enemy/other team
				if selected_source != null:
					_send_from_selected_to(structure)
		InteractionMode.CHOOSE_POSITION:
			selected_position = get_global_mouse_position()
			_submit_ability_request()


func _handle_right_click():
	# Cancel selected source
	if selected_source:
		is_choosing_target = false
		selected_source.set_selected(false)
		selected_source = null


func _send_from_selected_to(target: BaseStructure):
	var source := selected_source
	if source == null:
		return

	var request := UnitSendRequest.new()
	request.initialize(
		source.structure_id,
		target.structure_id,
		MultiplayerManager.get_local_peer_id(),
		MultiplayerManager.get_local_team_id(),
		-1,
		unit_send_mode,
		send_value,
		-1
	)
	request.unit_speed = FactionManager.get_team_faction_data(team).base_unit_speed
	
	UnitManager.request_send_units(request)
	#reset_temp_vars()
	selected_source.set_selected(false)
	selected_source = null
	is_choosing_target = false




func _handle_ability_pressed(index: int) -> void:
	current_ability_index = index
	if current_ability_index > faction_data_instance.ability_resources.size():
		return
	
	var ability_activation_type: Globals.ActivationType = faction_data_instance.ability_resources[index - 1].activation_type
	match ability_activation_type:
		Globals.ActivationType.INSTANT:
			interaction_mode = InteractionMode.NONE
		Globals.ActivationType.TARGET_POSITION:
			interaction_mode = InteractionMode.CHOOSE_POSITION
		Globals.ActivationType.TARGET_STRUCTURE:
			interaction_mode = InteractionMode.CHOOSE_STRUCTURE
		Globals.ActivationType.TARGET_UNIT:
			interaction_mode = InteractionMode.CHOOSE_UNIT
		Globals.ActivationType.TARGET_AREA:
			pass


func _submit_ability_request():
	var new_req := FactionAbilityRequest.new()
	new_req.team_id = MultiplayerManager.get_local_team_id()
	new_req.ability_index = current_ability_index
	new_req.mouse_pos = selected_position
	AbilityManager.request_ability(new_req)
	
	reset_temp_vars()


func reset_temp_vars():
	if selected_position != Vector2.ZERO:
		selected_position = Vector2.ZERO
	if selected_source:
		selected_source.set_selected(false)
		selected_source = null
	is_choosing_target = false
	current_ability_index = 0
	interaction_mode = InteractionMode.NONE
