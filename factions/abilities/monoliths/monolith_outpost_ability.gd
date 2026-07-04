extends FactionAbility
class_name MonolithOutpostAbility

var outpost_scene: PackedScene

func _init():
	outpost_scene = load("res://scenes/structures/outpost_structure.tscn")


func execute(_req: FactionAbilityRequest):
	var new_outpost: BaseStructure = outpost_scene.instantiate()
	new_outpost.structure_id = StructureManager.generate_structure_id()
	StructureManager.register_structure(new_outpost, new_outpost.structure_id)
	GameManager.structure_container.add_child(new_outpost)
	new_outpost.global_position = _req.mouse_pos
	new_outpost.set_team(_req.team_id)
