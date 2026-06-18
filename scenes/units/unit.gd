extends Node2D
class_name Unit

@export var speed: float = 120.0
@onready var unit_collision_particles = preload("res://scenes/units/unit_collision_particles.tscn")
@onready var sprite2d = $SpriteContainer/Sprite2D2
var faction
var target_structure
var target_position

func _ready():
	_update_texture()

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
	match faction:
		Globals.Faction.NEUTRAL:
			sprite2d.modulate = Color.GRAY
		Globals.Faction.PLAYER:
			sprite2d.modulate = Color.GREEN
		Globals.Faction.AI1:
			sprite2d.modulate = Color.YELLOW
		Globals.Faction.AI2:
			sprite2d.modulate = Color.RED

func hit_structure():
	if target_structure.faction == faction: # If same faction
		target_structure.population += 1
	else: # If different faction
		target_structure.population -= 1
		if target_structure.population <= 0:
			target_structure.set_faction(faction)
	queue_free()



func _on_area_2d_area_entered(area):
	var object = area.get_parent()
	if object is Unit and object.faction != faction:
		object.die()

func die():
	var effect = unit_collision_particles.instantiate()
	effect.global_position = global_position
	GameManager.particle_container.add_child(effect)
	queue_free()

func set_target_structure(target):
	target_structure = target
	
	var min_radius := 25.0
	var max_radius := 75.0
	var distance := randf_range(min_radius, max_radius)
	
	var offset := Vector2.from_angle(randf() * TAU) * distance
	
	target_position = target.global_position + offset
