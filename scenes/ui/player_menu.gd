extends Control
class_name PlayerMenu

signal ability_pressed(id: int)


@onready var faction_ui_tab: Control = $TabContainer/Faction
var faction_ui
@onready var amount_text_edit = $TabContainer/StructureMenu/MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/AmountTextEdit

func _ready():
	faction_ui_tab.add_child(faction_ui)
	faction_ui.connect("ability_pressed", handle_ability_pressed)

func update_structure_ui(_structure_data_res: StructureData):
	print("updating the structure UI")



func handle_ability_pressed(id: int):
	ability_pressed.emit(id)


## Sets the percentage of units to send (0.0 to 1.0)
func _on_percent_button_pressed(percentage: float) -> void:
	PlayerController.instance.send_value = clampf(percentage, 0.0, 1.0)
	PlayerController.instance.unit_send_mode = Globals.UnitSendMode.PERCENT


## Connected to all 4 percent buttons (with custom parameters)
func _on_percent_button_1_pressed() -> void:
	_on_percent_button_pressed(0.25)


func _on_percent_button_2_pressed() -> void:
	_on_percent_button_pressed(0.5)


func _on_percent_button_3_pressed() -> void:
	_on_percent_button_pressed(0.75)


func _on_percent_button_4_pressed() -> void:
	_on_percent_button_pressed(1.0)


## Switches to absolute amount mode with custom unit count from text input
func _on_amount_text_edit_text_set() -> void:
	if not amount_text_edit.text.is_valid_int():
		Globals.send_error("Unit amount not valid.")
		return
	PlayerController.instance.unit_send_mode = Globals.UnitSendMode.AMOUNT
	PlayerController.instance.send_value = int(amount_text_edit.text)
