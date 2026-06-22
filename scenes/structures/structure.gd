extends Node2D
class_name Structure

# Unit spawning constants
const SPAWN_MIN_RADIUS := 25.0
const SPAWN_MAX_RADIUS := 75.0
const SPAWN_ANGLE_RANGE := 0.35  # radians from target angle
const SPAWN_DELAY_MIN := 0.05
const SPAWN_DELAY_MAX := 0.2
const SPAWN_DELAY_SCALE := 0.001

@export var structure_id: int = 0
@export var _team: int = 0

@onready var growth_timer: Timer = $GrowthTimer
@onready var population_label: Label = $PopulationLabel
@onready var sprite2d: Sprite2D = $SpriteContainer/Sprite2D
@onready var unit_scene: PackedScene = preload("res://scenes/units/unit.tscn")
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var population: int = 10:
	set(value):
		population = value
		_update_population_label()
var max_population: int = 100
var growth_rate: float = 1
var growth_amount: int = 1


func _ready() -> void:
	growth_timer.wait_time = growth_rate
	_update_texture()
	_update_population_label()
	if _team != 0 and MultiplayerManager.is_server_or_singleplayer():
		growth_timer.start()


func _update_texture() -> void:
	sprite2d.modulate = Globals.get_team_color(_team)


func _on_growth_timer_timeout() -> void:
	if not MultiplayerManager.is_server_or_singleplayer(): # if this instance of the game is a client, exit this function.
		return

	var new_population := clampi(population + growth_amount, 0, max_population)
	if new_population == population:
		return

	population = new_population # authoritative update to the population. population label is updated using apply_network_state() through broadcast_structure_state()
	MultiplayerManager.broadcast_structure_state(structure_id, _team, population)


func set_team(team: int) -> void:
	if _team == 0 and team != 0 and MultiplayerManager.is_server_or_singleplayer():
		growth_timer.start()

	_team = team
	_update_texture()


func get_team() -> int:
	return _team


func apply_network_state(team: int, new_population: int) -> void: # this is a replication function who's job is to simply update the clients with the server's information/state. Singleplayer still uses this function just to update the visual state, but does not use it as an authoritative function.
	_team = team
	population = new_population
	_update_texture()
	_update_population_label()


func _update_population_label() -> void:
	population_label.text = str(population)


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_LEFT and _team == MultiplayerManager.get_local_team():
		PlayerController.instance.select_source(self)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		PlayerController.instance.select_target(self)


func send_units(
	target_structure: Structure,
	use_percent: bool = GameManager.player_sending_percentage,
	value: float = -1.0
) -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return

	var amount_to_send := _calculate_send_amount(use_percent, value)
	if amount_to_send <= 0:
		return

	population -= amount_to_send
	MultiplayerManager.broadcast_structure_state(structure_id, _team, population)

	# Stagger unit spawning for visual effect - delay increases with quantity
	var delay := clampf(SPAWN_DELAY_MAX - amount_to_send * SPAWN_DELAY_SCALE, SPAWN_DELAY_MIN, SPAWN_DELAY_MAX)
	for i in amount_to_send:
		spawn_unit(target_structure)
		await get_tree().create_timer(delay).timeout


func _calculate_send_amount(use_percent: bool, value: float) -> int:
	if use_percent:
		var percent := value if value >= 0.0 else GameManager.player_percent_to_send
		return int(population * percent)
	return int(value if value >= 0.0 else GameManager.player_amount_to_send)


func spawn_unit(target_structure: Structure) -> void:
	var spawn_offset := _generate_spawn_offset(target_structure.global_position)
	var spawn_pos := global_position + spawn_offset
	var target_pos := target_structure.generate_arrival_position()

	var unit_id := MultiplayerManager.generate_unit_id()
	MultiplayerManager.broadcast_spawn_unit(
		_team,
		structure_id,
		target_structure.structure_id,
		spawn_pos,
		target_pos,
		unit_id
	)


## Generate a spawn offset biased toward the target direction
func _generate_spawn_offset(target_pos: Vector2) -> Vector2:
	var distance := randf_range(SPAWN_MIN_RADIUS, SPAWN_MAX_RADIUS)
	var angle_to_target := get_angle_to(target_pos)
	var lower_angle := angle_to_target - SPAWN_ANGLE_RANGE
	var upper_angle := angle_to_target + SPAWN_ANGLE_RANGE
	var angle := randf_range(lower_angle, upper_angle)
	return Vector2.from_angle(angle) * distance


## Generate a random arrival position around this structure
func generate_arrival_position() -> Vector2:
	var distance := randf_range(SPAWN_MIN_RADIUS, SPAWN_MAX_RADIUS)
	var angle := randf() * TAU
	var offset := Vector2.from_angle(angle) * distance
	return global_position + offset


func apply_unit_hit(attacker_team: int) -> void:
	if attacker_team == _team:
		population += 1
	else:
		population -= 1
		anim_player.play("hit")
		if population <= 0:
			set_team(attacker_team)

	MultiplayerManager.broadcast_structure_state(structure_id, _team, population)


func _on_area_2d_body_entered(body) -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return
	if body is Unit and self != body.target_structure:
		body.die()
