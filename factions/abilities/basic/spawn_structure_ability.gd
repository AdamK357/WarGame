extends FactionAbility
class_name SpawnStructureAbility


@export var structure_path: String = "res://scenes/structures/basic_outpost_structure.gd"


func execute(fa_req: FactionAbilityRequest):
	var ss_req: StructureSpawnRequest = StructureSpawnRequest.new()
	ss_req.position = fa_req.mouse_pos
	ss_req.team = fa_req.team_id
	ss_req.structure_path = structure_path
	ss_req.structure_id = StructureManager.generate_structure_id()
	StructureManager.broadcast_spawn_structure(ss_req)
