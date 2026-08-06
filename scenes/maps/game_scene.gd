extends Node2D

@onready var ui_container: CanvasLayer = $UI

func _ready() -> void:
	GameManager.unit_container = $UnitContainer
	GameManager.particle_container = $ParticleContainer
	GameManager.structure_container = $StructureContainer
	StructureManager.register_structures_from_tree(self)
	
	if MultiplayerManager.is_team_human_controlled(MultiplayerManager.get_local_team_id()):
		var new_pc = PlayerController.new()
		var new_pm = load("res://scenes/ui/player_menu.tscn").instantiate()
		
		new_pc.team = MultiplayerManager.get_local_team_id()
		new_pc.player_menu = new_pm
		add_child(new_pc)
		
		new_pm.faction_ui = FactionManager.get_team_faction_data(MultiplayerManager.get_local_team_id()).faction_ui
		ui_container.add_child(new_pm)
	
	
	SignalBus.emit_signal("game_scene_ready")
