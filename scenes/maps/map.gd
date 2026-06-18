extends Node2D


func _ready():
	GameManager.unit_container = $UnitContainer
	GameManager.particle_container = $ParticleContainer
