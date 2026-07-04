extends Node

var _units_by_id: Dictionary = {} # unit_id -> Unit
var _next_unit_id: int = 1

func generate_unit_id() -> int:
	var id := _next_unit_id
	_next_unit_id += 1
	return id


func register_unit(unit: Unit, unit_id: int) -> void:
	_units_by_id[unit_id] = unit


func unregister_unit(unit_id: int) -> void:
	_units_by_id.erase(unit_id)

func _spawn_unit_local(req: UnitSendRequest) -> void:
	if GameManager.unit_container == null:
		return

	var target := StructureManager.get_structure(req.target_id)
	if target == null:
		return

	var unit: Unit = load("res://scenes/units/unit.tscn").instantiate()
	unit.unit_id = req.unit_id
	unit.set_team(req.team_id)
	unit.global_position = req.spawn_pos
	unit.set_target_from_network(target, req.target_pos)
	GameManager.unit_container.add_child(unit)
	register_unit(unit, req.unit_id)


func _destroy_unit_local(unit_id: int, effect_pos: Vector2) -> void:
	var unit: Unit = _units_by_id.get(unit_id)
	if unit == null:
		return
	unit.die_at_position(effect_pos)
