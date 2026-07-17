extends Node2D
class_name Unit

@export var speed: float = 120.0

@onready var unit_collision_particles = preload("res://scenes/units/unit_collision_particles.tscn")
@onready var sprite2d = $SpriteContainer/Sprite2D2

var unit_id: int = -1
var team: int
var source_structure: BaseStructure
var target_structure: BaseStructure
var target_position: Vector2


func _physics_process(delta: float) -> void:
	if target_structure == null:
		queue_free()
		return

	_move_toward_target(delta)


func _move_toward_target(delta: float) -> void:
	var dir := (target_position - global_position).normalized()
	global_position += dir * speed * delta


func _update_texture() -> void:
	if sprite2d == null:
		await ready
	
	sprite2d.modulate = Globals.get_team_color(team)
	
	var faction_id: int = FactionManager.get_team_faction_id(team)
	if faction_id == 0:
		return
	
	var texture: Texture2D = FactionManager.get_base_faction_data(faction_id).unit_texture
	if texture == null or texture == sprite2d.texture:
		return
	sprite2d.texture = texture


func set_team(_team: int) -> void:
	team = _team
	_update_texture()


func get_team() -> int:
	return team


func set_target_structure(target: BaseStructure) -> void:
	target_structure = target
	target_position = target.generate_arrival_position()


func set_target_from_network(target: BaseStructure, arrival_position: Vector2) -> void:
	target_structure = target
	target_position = arrival_position


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return

	var object = area.get_parent()
	if object is Unit and object.get_team() != team:
		_resolve_unit_collision(object)
	if object is BaseStructure:
		_resolve_structure_collision(object)


func _resolve_unit_collision(other: Unit) -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return
	
	if unit_id < other.unit_id:
		return
	die()
	other.die()


func _resolve_structure_collision(structure: BaseStructure) -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return
	
	if structure == null:
		queue_free()
		return
		
	if structure != source_structure:
		structure.apply_unit_hit(team)
		die()


func die() -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return
	
	UnitManager.broadcast_unit_destroyed(unit_id, global_position)

# Runs locally
func die_at_position(effect_pos: Vector2) -> void:
	var effect = unit_collision_particles.instantiate()
	effect.global_position = effect_pos
	if GameManager.particle_container:
		GameManager.particle_container.add_child(effect)
	_remove_self()

# Runs locally
func _remove_self() -> void:
	if unit_id >= 0:
		UnitManager.unregister_unit(unit_id)
	queue_free()
