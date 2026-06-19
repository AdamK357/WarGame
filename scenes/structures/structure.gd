extends Node2D
class_name Structure

@onready var growth_timer: Timer = $GrowthTimer
@onready var population_label: Label = $PopulationLabel
@onready var sprite2d: Sprite2D = $SpriteContainer/Sprite2D
@onready var unit_scene: PackedScene = preload("res://scenes/units/unit.tscn")
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var _team: int = 0


var population: int = 10:
	set(value):
		population = value
		_update_population_label()
var max_population: int = 100
var growth_rate: float = 1 # time between population growths
var growth_amount: int = 1 # amount population increases with each growth


func _ready():
	growth_timer.wait_time = growth_rate
	_update_texture()
	_update_population_label()
	if _team != 0:
		growth_timer.start()

func _update_texture() -> void:
	sprite2d.modulate = Globals.get_team_color(_team)

func _on_growth_timer_timeout() -> void:
	population = clamp(population + growth_amount, 0, max_population)
	_update_population_label()

func set_team(team: int) -> void:
	# enable growth if the structure is no longer neutral
	if _team == 0 and team != 0:
		growth_timer.start()
	
	_team = team
	_update_texture()

func get_team() -> int:
	return _team

func _update_population_label() -> void:
	population_label.text = str(population)


func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and _team == 1:
			GameManager.select_source_structure(self)
		if event.button_index == MOUSE_BUTTON_RIGHT:
			GameManager.select_target_structure(self)

func send_units(target_structure) -> void:
	var amount_to_send
	if GameManager.player_sending_percentage == true:
		amount_to_send = int(population * GameManager.player_percent_to_send)
	else:
		amount_to_send = GameManager.player_amount_to_send
	if amount_to_send <= 0:
		return
	
	population -= amount_to_send
	
	var delay: float = clamp(0.2 - amount_to_send * 0.001, 0.05, 0.2) # delay between spawns decreases with greater number of total spawns
	
	for i in amount_to_send:
		spawn_unit(target_structure)
		await get_tree().create_timer(delay).timeout # delay between spawns

func spawn_unit(target_structure) -> void:
	var unit = unit_scene.instantiate()
	unit.set_team(_team)
	
	# Random spawn radius
	var min_radius := 25.0
	var max_radius := 75.0
	var distance := randf_range(min_radius, max_radius)
	
	# Directional spawn cone
	var angle_range := 0.35 # radians
	var lower_angle = get_angle_to(target_structure.global_position) - angle_range
	var upper_angle = get_angle_to(target_structure.global_position) + angle_range
	var angle = randf_range(lower_angle, upper_angle)
	
	var offset := Vector2.from_angle(angle) * distance
	
	unit.global_position = global_position + offset
	unit.set_target_structure(target_structure)
	GameManager.unit_container.add_child(unit)

func _on_area_2d_body_entered(body):
	if body is Unit and self != body.target_structure:
		body.die()
		print("kill unit")
