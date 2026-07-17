extends Node

# Faction ID -> file path
var faction_paths := {
	1: "res://factions/data/monoliths.tres",
	2: "res://factions/data/twinkles.tres",
	3: "res://factions/data/prisms.tres",
	4: "res://factions/data/scryers.tres",
}

# team_id -> FactionController
var team_controllers: Dictionary[int, FactionController] = {}
# team_id -> Faction id
var team_faction_ids: Dictionary[int, int] = {}

# Called by MultiplayerManager when a team is assigned a faction
func register_team_faction(team_id: int, faction_data_id: int):
	# Store the team and corresponding faction data resource
	team_faction_ids[team_id] = faction_data_id

	# Create a new controller for the team
	var controller := FactionController.new()
	controller.team_id = team_id
	controller.faction_data_instance = create_duplicate_faction_data(faction_data_id)
	print("(FACTION MANAGER: register team) faction data name: " + controller.faction_data_instance.name)
	# Store the team and corresponding controller
	team_controllers[team_id] = controller
	# Add the controller to the scene tree
	add_child(controller)

	print("FactionController created for team %s" % team_id)


func update_team_factions(server_dict: Dictionary) -> void:
	# 1. Remove any local teams that no longer exist on the server.
	for team_id in team_faction_ids.keys().duplicate():
		if not server_dict.has(team_id):
			team_faction_ids.erase(team_id)
			delete_team_controller(team_id)

	# 2. Add or update teams based on server data.
	for team_id in server_dict.keys():
		var faction_id: int = server_dict[team_id]

		# If server explicitly sends null → remove team.
		if faction_id == null:
			team_faction_ids.erase(team_id)
			delete_team_controller(team_id)
			continue

		# If team does not exist locally → create it.
		if not team_faction_ids.has(team_id):
			register_team_faction(team_id, faction_id)
			continue

		# If faction changed → rebuild controller.
		if team_faction_ids[team_id] != faction_id:
			team_faction_ids[team_id] = faction_id
			delete_team_controller(team_id)
			register_team_faction(team_id, faction_id)


func get_team_faction_id(_team: int) -> int:
	if _team > team_faction_ids.size() or _team <= 0:
		return 0
	return team_faction_ids[_team]


## Returns the base FactionData resource using the faction_id
func get_base_faction_data(faction_id: int) -> FactionData:
	return load(faction_paths[faction_id])


## Returns the existing unique faction data resource from the faction_controller associated with the team_id
func get_team_faction_data(team_id: int) -> FactionData:
	return get_controller(team_id).faction_data_instance


## Returns a duplicated base FactionData resource using the faction_id. (Creates a unique FactionData resource instance for a team)
func create_duplicate_faction_data(faction_id: int) -> FactionData:
	return get_base_faction_data(faction_id).duplicate(true) # true = deep duplicate


## Returns the faction_controller associated with the team_id
func get_controller(team_id: int) -> FactionController:
	return team_controllers.get(team_id)



func delete_team_controller(_team_id: int) -> void:
	if team_controllers.has(_team_id):
		var old_controller := team_controllers[_team_id]
		old_controller.queue_free()
		team_controllers.erase(_team_id)
	
#func use_ability(request: FactionAbilityRequest):
	#var controller: FactionController = team_controllers.get(request.team_id)
	#if controller == null:
		#push_error("FactionController missing for team %s" % request.team_id)
		#return
#
	#controller.execute_ability(request)


# Called only by the server.
func handle_ability_request(req: FactionAbilityRequest):
	var controller := get_controller(req.team_id) # Get the existing faction controller associated with the request's team id
	if controller == null:
		return
	
	if not controller.can_execute_ability(req.ability_index):
		return
	
	controller.execute_ability(req) # Activate the ability on the server side.



@rpc("any_peer", "reliable")
func rpc_register_faction(_faction: int) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	register_team_faction(MultiplayerManager.get_peer_team(peer_id), _faction)
	rpc_sync_factions.rpc(FactionManager.team_faction_ids)

# RELOCATE
@rpc("authority", "reliable")
func rpc_sync_factions(_team_faction_ids: Dictionary) -> void:
	update_team_factions(_team_faction_ids)
