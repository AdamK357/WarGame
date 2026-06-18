extends Node2D

var selected_source_structure: Structure = null
var selected_target_structure: Structure = null

var unit_container: Node2D
var particle_container: Node2D

func select_source_structure(structure: Structure) -> void:
	selected_source_structure = structure
	Globals.send_note("Selected source structure: " + str(selected_source_structure))

func select_target_structure(structure: Structure) -> void:
	selected_target_structure = structure
	Globals.send_note("Selected target structure: " + str(selected_target_structure))

func try_send_units():
	Globals.send_note("Attempting to send units from source to target")
	if !selected_source_structure or !selected_target_structure:
		Globals.send_error("source structure or target structure not selected")
		return
		
	if selected_source_structure == selected_target_structure:
		Globals.send_error("source and target structure are the same")
		return
	
	selected_source_structure.send_units(selected_target_structure)
	selected_source_structure = null
	selected_target_structure = null

func _process(_delta):
	if Input.is_action_just_pressed("spacebar"):
		try_send_units()
