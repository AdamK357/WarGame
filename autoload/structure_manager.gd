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


func get_structure(structure_id: int) -> BaseStructure:
	return _structures_by_id.get(structure_id)

func register_structure(structure: BaseStructure, structure_id: int) -> void:
	_structures_by_id[structure_id] = structure
	structure_registered.emit(structure_id)

func unregister_structure(structure_id: int) -> void:
	_structures_by_id.erase(structure_id)
