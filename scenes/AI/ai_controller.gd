extends Node
class_name AIController

@export var _team: int = 2
@onready var action_timer: Timer = $ActionTimer

@export_range(0.0, 1.0) var aggression := 0.6
@export_range(0.0, 1.0) var caution := 0.9
@export_range(0.0, 1.0) var expansionism := 0.5
@export_range(0.1, 1.0) var send_percentage := 0.5
@export_range(0.1, 1.0) var defensiveness := 0.5
@export var vulnerability_threshold := 10
@export var action_speed := 1.5


func _ready() -> void:
	action_timer.wait_time = action_speed
	if MultiplayerManager.is_team_human_controlled(_team):
		action_timer.stop()


func _get_my_structures() -> Array[Node]:
	var all_structures = get_tree().get_nodes_in_group("structures")
	return all_structures.filter(func(s): return s.get_team() == _team)


func _get_neutral_structures() -> Array[Node]:
	var all_structures = get_tree().get_nodes_in_group("structures")
	return all_structures.filter(func(s): return s.get_team() == 0)


func _get_enemy_structures() -> Array[Node]:
	var all_structures = get_tree().get_nodes_in_group("structures")
	return all_structures.filter(func(s): return s.get_team() != _team and s.get_team() != 0)


func _on_action_timer_timeout() -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return
	if MultiplayerManager.is_team_human_controlled(_team):
		return

	var my_structures := _get_my_structures()
	if my_structures.is_empty():
		return

	for source in my_structures:
		var target := _choose_target(source)
		if target:
			_maybe_attack(source, target)


func _choose_target(source: Structure) -> Structure:
	var neutral_structures := _get_neutral_structures()
	var enemy_structures := _get_enemy_structures()

	var candidates: Array = []

	if randf() < expansionism and not neutral_structures.is_empty():
		candidates = neutral_structures
	else:
		candidates = enemy_structures

	if randf() < defensiveness:
		var weak := _find_weak_friendly_structure()
		if weak and weak != source:
			if source.population > vulnerability_threshold:
				if source.global_position.distance_to(weak.global_position) < 500:
					return weak

	if candidates.is_empty():
		return null

	candidates.sort_custom(
		func(a, b):
			var score_a = a.population * 2 + source.global_position.distance_to(a.global_position)
			var score_b = b.population * 2 + source.global_position.distance_to(b.global_position)
			return score_a < score_b
	)

	return candidates[0]


func _maybe_attack(source: Structure, target: Structure) -> void:
	var source_pop := source.population
	var target_pop := target.population

	var advantage := float(source_pop) / maxf(1.0, target_pop)
	if advantage < caution:
		return

	if randf() > aggression:
		return

	var amount := int(source_pop * send_percentage)
	if amount > 5:
		var request := UnitSendRequest.new(source.structure_id, target.structure_id, Globals.UnitSendMode.PERCENT, send_percentage)
		source.send_units(request)


func _find_weak_friendly_structure() -> Structure:
	var my_structures := _get_my_structures()
	if my_structures.is_empty():
		return null

	my_structures.sort_custom(func(a, b): return a.population < b.population)

	var weakest: Structure = my_structures[0]
	if weakest.population < vulnerability_threshold:
		return weakest

	return null
