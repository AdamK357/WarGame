extends Node
class_name AIController

@export var faction: Globals.Faction = Globals.Faction.AI1
@onready var action_timer: Timer = $ActionTimer

# Personality Parameters
@export_range(0.0, 1.0) var aggression := 0.6 ## Desire to actually attack if strong enough to do so
@export_range(0.0, 1.0) var caution := 0.9 ## How strong we want to be before attacking
@export_range(0.0, 1.0) var expansionism := 0.5 ## Desire to attack neutrals rather than other factions
@export_range(0.1, 1.0) var send_percentage := 0.5 ## Percentage of population sent from structure
@export_range(0.1, 1.0) var defensiveness := 0.5 ## Chance to support own structures that have a population beneath the vulnerability_threshold.
@export var vulnerability_threshold := 10 ## Lowest population before sending units to support
@export var action_speed := 1.5 ## Amount of time between actions


func _ready() -> void:
	action_timer.wait_time = action_speed


func _get_my_structures() -> Array[Node]:
	var all_structures = get_tree().get_nodes_in_group("Structures")
	return all_structures.filter(func(s): return s.faction == faction)

func _get_neutral_structures() -> Array[Node]:
	var all_structures = get_tree().get_nodes_in_group("Structures")
	return all_structures.filter(func(s): return s.faction == Globals.Faction.NEUTRAL)

func _get_enemy_structures() -> Array[Node]:
	var all_structures = get_tree().get_nodes_in_group("Structures")
	return all_structures.filter(func(s): return s.faction != faction and s.faction != Globals.Faction.NEUTRAL)




func _on_action_timer_timeout():
	var my_structures = _get_my_structures()
	
	if my_structures.is_empty():
		return
	
	for source in my_structures:
		var target = _choose_target(source)
		if target:
			_maybe_attack(source, target)



# Attack enemy or neutral structure, support own structure, 
# When to attack: enemy structure has low population, 
# when to support: own structure has low population, own structure is targeted by player

func _choose_target(source: Structure) -> Structure:
	var neutral_structures = _get_neutral_structures()
	var enemy_structures = _get_enemy_structures()
	
	var candidates: Array = []
	
	# Expansionist AIs prefer neutrals
	if randf() < expansionism and not neutral_structures.is_empty():
		candidates = neutral_structures
	else:
		candidates = enemy_structures
	
	# Defensive AIs are more likely to send reinforcements to a structure beneath the vulnerability_threshold.
	if randf() < defensiveness:
		var weak = _find_weak_friendly_structure()
		if weak and weak != source:
			if source.population > vulnerability_threshold:
				if source.global_position.distance_to(weak.global_position) < 500:
					return weak
	
	
	if candidates.is_empty():
		return null
	
	# Sort by (population + distance) weighting
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
	
	# Require a minimum advantage
	var advantage = float(source_pop) / max(1.0, target_pop)
	if advantage < caution:
		return
	
	# Aggression: chance to attack if strong enough
	if randf() > aggression:
		return
	
	# Send units
	var amount := int(source_pop * send_percentage)
	if amount > 5:
		source.send_units(target)

func _find_weak_friendly_structure() -> Structure:
	var my_structures = _get_my_structures()
	if my_structures.is_empty():
		return null

	# Find the lowest population structure
	my_structures.sort_custom(
		func(a, b): return a.population < b.population
	)

	var weakest = my_structures[0]

	# Only consider it weak if it's below some threshold
	if weakest.population < vulnerability_threshold:
		return weakest

	return null
