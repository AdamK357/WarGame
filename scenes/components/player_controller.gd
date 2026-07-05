extends Node2D
class_name PlayerController

@export var team: int = -1
static var instance: PlayerController = null

var selected_source: BaseStructure = null
var hovered_structure: BaseStructure = null

var unit_send_mode: Globals.UnitSendMode = Globals.UnitSendMode.PERCENT
var send_value: float = 0.5

func _ready():
	instance = self
	connect_to_signals()

func _exit_tree(): # ensures that when queue_free() is called, any references to this playercontroller become null.
	if instance == self:
		instance = null


func select_source(structure: BaseStructure) -> void:
	if structure.get_team() != team:
		return
	GameManager.select_source_structure(structure)


func select_target(structure: BaseStructure) -> void:
	GameManager.select_target_structure(structure)


func set_hovered_structure(structure: BaseStructure = null):
	hovered_structure = structure


func connect_to_signals():
	StructureManager.structure_registered.connect(connect_structure_signals)
	initial_connect_structure_signals()

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
		_on_ability_pressed(1)


func _handle_left_click():
	var s := hovered_structure
	if s == null:
		return

	if s.get_team() == team:
		# Clicked own structure
		if selected_source == null:
			selected_source = s
		else:
			_send_from_selected_to(s)
	else:
		# Clicked enemy/other team
		if selected_source != null:
			_send_from_selected_to(s)


func _handle_right_click():
	# Optional: right‑click could cancel selection, quick‑send, or do nothing.
	# Keeping your current behavior: only send if selected_source exists.
	var s := hovered_structure
	if s != null and selected_source != null:
		_send_from_selected_to(s)


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

	GameManager.try_send_units(request)
	selected_source = null



func _on_ability_pressed(index: int) -> void:
	var new_req := FactionAbilityRequest.new()
	new_req.team_id = MultiplayerManager.get_local_team_id()
	new_req.ability_index = index
	new_req.mouse_pos = get_global_mouse_position()
	MultiplayerManager.request_ability(new_req)
