extends Node2D
class_name Unit

@export var speed: float = 120.0
@onready var unit_collision_particles = preload("res://scenes/units/unit_collision_particles.tscn")
@onready var sprite2d = $SpriteContainer/Sprite2D2
var _team: int
var target_structure
var target_position

func _physics_process(delta):
	if target_structure == null:
		queue_free()
		return
	# Move towards target structure
	var dir = (target_position - global_position).normalized()
	global_position += dir * speed * delta
	
	# Check if reached structure
	if global_position.distance_to(target_position) < 10:
		hit_structure()

func _update_texture() -> void:
	if sprite2d == null:
		await ready
	sprite2d.modulate = Globals.get_team_color(_team)

func hit_structure():
	if target_structure.get_team() == _team: # If same faction
		target_structure.population += 1
	else: # If different faction
		target_structure.population -= 1
		target_structure.anim_player.play("hit")
		if target_structure.population <= 0:
			target_structure.set_team(_team)
	queue_free()

func set_team(team: int) -> void:
	_team = team
	_update_texture()


func get_team() -> int:
	return _team


func _on_area_2d_area_entered(area):
	var object = area.get_parent()
	if object is Unit and object.get_team() != _team:
		object.die()

func die():
	var effect = unit_collision_particles.instantiate()
	effect.global_position = global_position
	GameManager.particle_container.add_child(effect)
	queue_free()

func set_target_structure(target: Structure) -> void:
	target_structure = target
	target_position = generate_target_position(target)

func generate_target_position(target: Structure) -> Vector2:
	var min_radius := 25.0
	var max_radius := 75.0
	var distance := randf_range(min_radius, max_radius)
	
	var offset := Vector2.from_angle(randf() * TAU) * distance
	
	return target.global_position + offset
