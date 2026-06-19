extends Control

@onready var amount_text_edit = $CanvasLayer/Control/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/AmountTextEdit

func _on_percent_button_1_pressed():
	GameManager.player_percent_to_send = 0.25
	GameManager.player_sending_percentage = true

func _on_percent_button_2_pressed():
	GameManager.player_percent_to_send = 0.5
	GameManager.player_sending_percentage = true


func _on_percent_button_3_pressed():
	GameManager.player_percent_to_send = 0.75
	GameManager.player_sending_percentage = true


func _on_percent_button_4_pressed():
	GameManager.player_percent_to_send = 1
	GameManager.player_sending_percentage = true


func _on_amount_text_edit_text_set():
	if !(amount_text_edit.text is int):
		Globals.send_error("Unit amount not valid.")
		return
	GameManager.player_sending_percentage = false
	GameManager.player_amount_to_send = int(amount_text_edit.text)
