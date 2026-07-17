extends Control

signal ability_pressed(id: int)


func _on_ability_button_1_pressed():
	ability_pressed.emit(1)


func _on_ability_button_2_pressed():
	ability_pressed.emit(2)


func _on_ability_button_3_pressed():
	ability_pressed.emit(3)


func _on_ability_button_4_pressed():
	ability_pressed.emit(4)
