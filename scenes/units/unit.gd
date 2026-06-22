extends Node2D
class_name Unit

@export var speed: float = 120.0

@onready var unit_collision_particles = preload("res://scenes/units/unit_collision_particles.tscn")
@onready var sprite2d = $SpriteContainer/Sprite2D2

var unit_id: int = -1
var _team: int
var target_structure: Structure
var target_position: Vector2


func _physics_process(delta: float) -> void:
	if target_structure == null:
		queue_free()
		return

	_move_toward_target(delta)

	if not MultiplayerManager.is_server_or_singleplayer():
		return

	if global_position.distance_to(target_position) < 10:
		hit_structure()


func _move_toward_target(delta: float) -> void:
	var dir := (target_position - global_position).normalized()
	global_position += dir * speed * delta


func _update_texture() -> void:
	if sprite2d == null:
		await ready
	sprite2d.modulate = Globals.get_team_color(_team)


func hit_structure() -> void:
	if target_structure == null:
		queue_free()
		return

	target_structure.apply_unit_hit(_team)

	if MultiplayerManager.is_server_or_singleplayer():
		MultiplayerManager.broadcast_unit_destroyed(unit_id, global_position)


func set_team(team: int) -> void:
	_team = team
	_update_texture()


func get_team() -> int:
	return _team


func set_target_structure(target: Structure) -> void:
	target_structure = target
	target_position = target.generate_arrival_position()


func set_target_from_network(target: Structure, arrival_position: Vector2) -> void:
	target_structure = target
	target_position = arrival_position


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return

	var object = area.get_parent()
	if object is Unit and object.get_team() != _team:
		_resolve_unit_collision(object)


func _resolve_unit_collision(other: Unit) -> void:
	if unit_id < other.unit_id:
		return

	die()
	other.die()


func die() -> void:
	if MultiplayerManager.is_server_or_singleplayer():
		MultiplayerManager.broadcast_unit_destroyed(unit_id, global_position)


func die_at_position(effect_pos: Vector2) -> void:
	var effect = unit_collision_particles.instantiate()
	effect.global_position = effect_pos
	if GameManager.particle_container:
		GameManager.particle_container.add_child(effect)
	_remove_self()


func _remove_self() -> void:
	if unit_id >= 0:
		MultiplayerManager.unregister_unit(unit_id)
	queue_free()
