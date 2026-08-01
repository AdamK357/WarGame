extends Node

signal structure_registered(structure_id: int)

var _structures_by_id: Dictionary = {} # structure_id -> BaseStructure
var _next_structure_id: int = 1


func generate_structure_id() -> int:
	var id := _next_structure_id
	_next_structure_id += 1
	return id


func register_structures_from_tree(root: Node) -> void:
	_structures_by_id.clear()
	for node in root.get_tree().get_nodes_in_group("structures"):
		if node is BaseStructure and node.structure_id >= 0:
			node.structure_id = generate_structure_id()
			register_structure(node, node.structure_id)


## Returns the structure corresponding to the id
func get_structure(structure_id: int) -> BaseStructure:
	return _structures_by_id.get(structure_id)


func register_structure(structure: BaseStructure, structure_id: int) -> void:
	_structures_by_id[structure_id] = structure
	GameManager.register_structure_to_team(structure.get_team())
	structure_registered.emit(structure_id)


func unregister_structure(structure_id: int) -> void:
	GameManager.remove_structure_from_team(get_structure(structure_id).get_team())
	_structures_by_id.erase(structure_id)
	


func _spawn_structure_local(_req: StructureSpawnRequest) -> void:
	if GameManager.structure_container == null:
		return
	var new_structure: BaseStructure = load(_req.structure_path).instantiate()
	
	new_structure.set_team(_req.team)
	new_structure.global_position = _req.position
	new_structure.structure_id = _req.structure_id
	GameManager.structure_container.add_child(new_structure)
	
	register_structure(new_structure, _req.structure_id)
	

# Relocated VVVVVVV

func broadcast_spawn_structure(req: StructureSpawnRequest) -> void:
	_spawn_structure_local(req)
	if MultiplayerManager.is_multiplayer() and MultiplayerManager.is_server():
		rpc_spawn_structure.rpc(req.to_dict())


@rpc("authority", "reliable")
func rpc_spawn_structure(dict: Dictionary) -> void:
	var req := BaseRequest.from_dict(dict, StructureSpawnRequest)
	_spawn_structure_local(req)


func broadcast_structure_state(id: int, team: int, pop: int) -> void:
	var s := get_structure(id)
	if s:
		s.apply_network_state(team, pop)

	if MultiplayerManager.is_multiplayer() and MultiplayerManager.is_server():
		rpc_sync_structure.rpc(id, team, pop)

# RELOCATE
@rpc("authority", "reliable")
func rpc_sync_structure(id: int, team: int, pop: int) -> void:
	var s := get_structure(id)
	if s:
		s.apply_network_state(team, pop)
