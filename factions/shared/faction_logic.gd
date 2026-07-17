extends Resource
class_name FactionLogic


func init_state() -> Dictionary:
	return {}

func process_tick(_delta: float, _state: Dictionary) -> void:
	pass

func on_structure_captured(_structure, _state: Dictionary) -> void:
	pass

func on_unit_spawned(_unit, _state: Dictionary) -> void:
	pass

func on_ability_used(_ability_id: String, _state: Dictionary) -> void:
	pass
