extends Control

# var name: [value, label reference]
var displayed_data: Dictionary = {}
@onready var label_container: VBoxContainer = $CanvasLayer/PanelContainer/VBoxContainer


func _add_variable(_name: String, value) -> void:
	displayed_data[_name] = [value, _create_label(_name)]
	_update_label_text(_name)


func set_val(_name: String, value) -> void:
	if not displayed_data.has(_name):
		_add_variable(_name, value)
	else:
		displayed_data[_name][0] = value
		_update_label_text(_name)


func _update_label_text(_name: String) -> void:
	displayed_data[_name][1].text = _name + ": " + str(displayed_data[_name][0])


func _create_label(_name: String) -> Label:
	var new_label = Label.new()
	label_container.add_child(new_label)
	return new_label
