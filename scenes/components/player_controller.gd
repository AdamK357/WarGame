extends Node
class_name PlayerController

@export var team: int = -1
static var instance: PlayerController = null

var selected_source: Structure = null
var hovered_structure: Structure = null

var unit_send_mode: Globals.UnitSendMode = Globals.UnitSendMode.PERCENT
var send_value: float = 0.5

func _ready():
	instance = self
	connect_to_signals()

func _exit_tree(): # ensures that when queue_free() is called, any references to this playercontroller become null.
	if instance == self:
		instance = null

func select_source(structure: Structure) -> void:
	if structure.get_team() != team:
		return
	GameManager.select_source_structure(structure)


func select_target(structure: Structure) -> void:
	GameManager.select_target_structure(structure)


func set_hovered_structure(structure: Structure = null):
	hovered_structure = structure


func connect_to_signals():
	var structure_group := get_tree().get_nodes_in_group("structures")
	for structure in structure_group:
		structure.mouse_hover_entered.connect(set_hovered_structure)
		structure.mouse_hover_exited.connect(set_hovered_structure)


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hovered_structure == null:
			return
		if hovered_structure.get_team() == team:
			if selected_source == null:
				selected_source = hovered_structure
			else:
				var request = UnitSendRequest.new(selected_source.structure_id, hovered_structure.structure_id, unit_send_mode, send_value)
				GameManager.try_send_units(request)
				selected_source = null
		elif hovered_structure.get_team() != team:
			if selected_source != null:
				var request = UnitSendRequest.new(selected_source.structure_id, hovered_structure.structure_id, unit_send_mode, send_value)
				GameManager.try_send_units(request)
				selected_source = null
