extends Node
class_name PlayerController

var team: int
static var instance

func _ready():
	instance = self


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("spacebar"):
		GameManager.try_send_units()


func select_source(structure):
	GameManager.select_source_structure(structure)

func select_target(structure):
	GameManager.select_target_structure(structure)
