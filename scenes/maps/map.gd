extends Node2D


func _ready() -> void:
	GameManager.unit_container = $UnitContainer
	GameManager.particle_container = $ParticleContainer
	GameManager.structure_container = $StructureContainer
	MultiplayerManager.register_structures_from_tree(self)
	
	if MultiplayerManager.is_team_human_controlled(MultiplayerManager.get_local_team()):
		var pc = PlayerController.new()
		pc.team = MultiplayerManager.get_local_team()
		add_child(pc)
