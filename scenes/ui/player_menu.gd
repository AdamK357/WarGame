extends Control
class_name PlayerMenu

signal ability_pressed(id: int)
@export var faction_ui: Control


func _ready():
	faction_ui.connect("ability_pressed", handle_ability_pressed)

func handle_ability_pressed(id: int):
	ability_pressed.emit(id)
