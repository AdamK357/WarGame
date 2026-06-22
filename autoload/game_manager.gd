extends Node2D

var selected_source_structure: Structure = null
var selected_target_structure: Structure = null

var unit_container: Node2D
var particle_container: Node2D
var structure_container: Node2D


var player_sending_percentage: bool = true
var player_percent_to_send: float = 0.5
var player_amount_to_send: float


func select_source_structure(structure: Structure) -> void:
	selected_source_structure = structure
	Globals.send_note("Selected source structure: " + str(selected_source_structure.structure_id))


func select_target_structure(structure: Structure) -> void:
	selected_target_structure = structure
	Globals.send_note("Selected target structure: " + str(selected_target_structure.structure_id))


func try_send_units() -> void:
	if not selected_source_structure or not selected_target_structure:
		Globals.send_error("source structure or target structure not selected")
		return

	if selected_source_structure == selected_target_structure:
		Globals.send_error("source and target structure are the same")
		return

	MultiplayerManager.request_send_units(
		selected_source_structure.structure_id,
		selected_target_structure.structure_id,
		player_sending_percentage,
		player_percent_to_send if player_sending_percentage else player_amount_to_send
	)

	selected_source_structure = null
	selected_target_structure = null
