extends FactionLogic
class_name MonolithLogic

func init_state() -> Dictionary:
	return {
		"monolith_points": 0,
		"walls_built": 0,
		"turrets": []
	}

func on_structure_captured(structure, state):
	if structure.is_monolith:
		state["monolith_points"] += 1

func process_tick(delta, state):
	# Example passive effect
	if state["monolith_points"] > 10:
		# unlock something, trigger something, etc
		pass
