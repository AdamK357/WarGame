extends Control

@onready var amount_text_edit = $CanvasLayer/Control/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/AmountTextEdit


## Sets the percentage of units to send (0.0 to 1.0)
func _on_percent_button_pressed(percentage: float) -> void:
	GameManager.player_percent_to_send = clampf(percentage, 0.0, 1.0)
	GameManager.player_sending_percentage = true


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
	GameManager.player_sending_percentage = false
	GameManager.player_amount_to_send = int(amount_text_edit.text)
