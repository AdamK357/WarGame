extends Node
class_name FactionController


var team_id: int
var faction_data_instance: FactionData
var logic: FactionLogic
var state: Dictionary

# ability_index -> time remaining
var cooldowns := {}

func _ready():
	_init_cooldowns()
	logic = faction_data_instance.logic_module
	state = logic.init_state()


func _process(delta):
	_update_cooldowns(delta)
	_run_passive_effects(delta)


func _replicate_state():
	sync_state_rpc.rpc(state)

@rpc("authority", "reliable")
func sync_state_rpc(new_state):
	state = new_state


func _init_cooldowns():
	for i in faction_data_instance.ability_resources.size():
		var ability_script = faction_data_instance.ability_resources[i]
		cooldowns[i] = ability_script.cooldown
	print("cooldowns: " + str(cooldowns))


func _update_cooldowns(delta):
	for index in cooldowns.keys():
		if cooldowns[index] > 0.0:
			cooldowns[index] -= delta
			if cooldowns[index] < 0.0:
				cooldowns[index] = 0.0


func can_execute_ability(index: int) -> bool:
	if index - 1 < 0 or index - 1 >= faction_data_instance.ability_resources.size():
		return false

	return cooldowns[index - 1] <= 0.0


func execute_ability(req: FactionAbilityRequest):
	if not can_execute_ability(req.ability_index):
		return
	
	# instantiate the ability script
	var ability_script = faction_data_instance.ability_resources[req.ability_index - 1]
	ability_script.execute(req)

	# start cooldown
	cooldowns[req.ability_index] = ability_script.cooldown


func _run_passive_effects(delta):
	# optional: factions may override this via custom scripts
	if faction_data_instance.has_method("passive_effect"):
		faction_data_instance.passive_effect(team_id, delta)
