extends Node
# MultiplayerManager is keeps track of which team this peer controls, which teams belong to which peer, who is allowed to issue commands
# spawning units, syncing structure state, etc...


const DEFAULT_PORT := 7777
const MAX_PLAYERS := 6

signal connection_failed
signal peer_list_changed

var local_team: int = 1
var peer_teams: Dictionary = {} # peer_id -> team
var peer_factions: Dictionary = {} # peer_id -> faction_id
var human_teams: Array = []

var _structures_by_id: Dictionary = {} # structure_id -> Structure
var _units_by_id: Dictionary = {} # unit_id -> Unit
var _next_unit_id: int = 1


func _ready() -> void:
	multiplayer.multiplayer_peer = null
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_multiplayer() -> bool:
	return multiplayer.multiplayer_peer != null


func is_server_or_singleplayer() -> bool:
	return not is_multiplayer() or multiplayer.is_server()


func get_local_team() -> int:
	return local_team


func host_game(port: int = DEFAULT_PORT, team: int = 1) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		connection_failed.emit()
		return error

	multiplayer.multiplayer_peer = peer
	local_team = team
	peer_teams = {1: team}
	human_teams = [team]
	peer_list_changed.emit()
	return OK


func join_game(address: String, port: int = DEFAULT_PORT, team: int = 1) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		connection_failed.emit()
		return error

	multiplayer.multiplayer_peer = peer
	local_team = team
	return OK


func disconnect_from_game() -> void:
	if is_multiplayer():
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	peer_teams.clear()
	human_teams.clear()
	_structures_by_id.clear()
	_units_by_id.clear()
	_next_unit_id = 1 # resets the counter used to assign id-s to units


func start_game(map_path: String) -> void:
	if is_multiplayer():
		if not multiplayer.is_server():
			return
		start_game_rpc.rpc(map_path)
	else:
		human_teams = [get_local_team()]
		peer_teams = {1: get_local_team()}
		TransitionManager.change_scene(map_path)


func register_structures_from_tree(root: Node) -> void:
	_structures_by_id.clear()
	for node in root.get_tree().get_nodes_in_group("structures"):
		if node is Structure and node.structure_id > 0:
			_structures_by_id[node.structure_id] = node


func get_structure(structure_id: int) -> Structure:
	return _structures_by_id.get(structure_id)


func generate_unit_id() -> int:
	var id := _next_unit_id
	_next_unit_id += 1
	return id


func register_unit(unit: Unit, unit_id: int) -> void:
	_units_by_id[unit_id] = unit


func unregister_unit(unit_id: int) -> void:
	_units_by_id.erase(unit_id)


func request_send_units(request: UnitSendRequest) -> void:
	if is_multiplayer():
		if multiplayer.is_server():
			request.peer_id = multiplayer.get_unique_id()
			_handle_send_units_request(request)
		else:
			request_send_units_rpc.rpc_id(1, request.to_dict())
	else:
		if request.source_id and request.target_id:
			var source := get_structure(request.source_id)
			source.send_units(request)


func broadcast_spawn_unit(
	team: int,
	source_id: int,
	target_id: int,
	spawn_pos: Vector2,
	target_pos: Vector2,
	unit_id: int
) -> void:
	_spawn_unit_local(team, source_id, target_id, spawn_pos, target_pos, unit_id)
	if is_multiplayer() and multiplayer.is_server():
		spawn_unit_rpc.rpc(team, source_id, target_id, spawn_pos, target_pos, unit_id)


func broadcast_structure_state(structure_id: int, team: int, population: int) -> void:
	var structure := get_structure(structure_id)
	if structure:
		structure.apply_network_state(team, population)
	if is_multiplayer() and multiplayer.is_server():
		sync_structure_rpc.rpc(structure_id, team, population)


func broadcast_unit_destroyed(unit_id: int, effect_pos: Vector2) -> void:
	_destroy_unit_local(unit_id, effect_pos)
	if is_multiplayer() and multiplayer.is_server():
		destroy_unit_rpc.rpc(unit_id, effect_pos)


func is_team_human_controlled(team: int) -> bool:
	return human_teams.has(team)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		sync_teams_rpc.rpc(peer_teams)
		#_assign_faction_to_peer(faction_id, peer_id)
	peer_list_changed.emit()

func _assign_faction_to_peer(faction_id: int, peer_id: int) -> void:
	peer_factions[peer_id] = faction_id
	_broadcast_faction_assignment(peer_id, faction_id)

@rpc("authority", "call_local", "reliable")
func _broadcast_faction_assignment(peer_id: int, faction: int):
	peer_factions[peer_id] = faction
	

func _on_peer_disconnected(peer_id: int) -> void:
	peer_teams.erase(peer_id)
	human_teams = peer_teams.values()
	peer_list_changed.emit()


func _on_connected_to_server() -> void:
	register_team_rpc.rpc_id(1, local_team)


func _on_connection_failed() -> void:
	disconnect_from_game()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	disconnect_from_game()
	connection_failed.emit()


@rpc("any_peer", "reliable")
func register_team_rpc(team: int) -> void:
	if not multiplayer.is_server():
		return

	var peer_id := multiplayer.get_remote_sender_id()
	if peer_teams.values().has(team):
		Globals.send_error("Team %d already taken by another player" % team)
		return

	peer_teams[peer_id] = team
	human_teams = peer_teams.values()
	sync_teams_rpc.rpc(peer_teams)
	peer_list_changed.emit()


@rpc("authority", "reliable", "call_local")
func sync_teams_rpc(teams: Dictionary) -> void:
	peer_teams = teams
	human_teams = peer_teams.values()
	var my_id := multiplayer.get_unique_id()
	if peer_teams.has(my_id):
		local_team = peer_teams[my_id]
	peer_list_changed.emit()


@rpc("authority", "reliable", "call_local")
func start_game_rpc(map_path: String) -> void:
	get_tree().change_scene_to_file(map_path)


@rpc("any_peer", "reliable")
func request_send_units_rpc(request_dict: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	
	var request = UnitSendRequest.from_dict(request_dict)
	request.peer_id = multiplayer.get_remote_sender_id()
	
	_handle_send_units_request(request)


@rpc("authority", "reliable")
func spawn_unit_rpc(
	team: int,
	source_id: int,
	target_id: int,
	spawn_pos: Vector2,
	target_pos: Vector2,
	unit_id: int
) -> void:
	_spawn_unit_local(team, source_id, target_id, spawn_pos, target_pos, unit_id)


@rpc("authority", "reliable")
func sync_structure_rpc(structure_id: int, team: int, population: int) -> void:
	var structure := get_structure(structure_id)
	if structure:
		structure.apply_network_state(team, population)


@rpc("authority", "reliable")
func destroy_unit_rpc(unit_id: int, effect_pos: Vector2) -> void:
	_destroy_unit_local(unit_id, effect_pos)


func _handle_send_units_request(request: UnitSendRequest) -> void:
	if not peer_teams.has(request.peer_id):
		Globals.send_error("Unknown peer %d attempted to send units" % request.peer_id)
		return

	var source := get_structure(request.source_id)
	var target := get_structure(request.target_id)
	if source == null or target == null:
		Globals.send_error("Invalid structure ids: %d -> %d" % [request.source_id, request.target_id])
		return

	if source == target:
		return

	if source.get_team() != peer_teams[request.peer_id]:
		Globals.send_error("Peer %d does not own team %d" % [request.peer_id, source.get_team()])
		return

	source.send_units(request)


func _spawn_unit_local(
	team: int,
	source_id: int,
	target_id: int,
	spawn_pos: Vector2,
	target_pos: Vector2,
	unit_id: int
) -> void:
	if GameManager.unit_container == null:
		return

	var target := get_structure(target_id)
	if target == null:
		return

	var unit: Unit = preload("res://scenes/units/unit.tscn").instantiate()
	unit.unit_id = unit_id
	unit.set_team(team)
	unit.global_position = spawn_pos
	unit.set_target_from_network(target, target_pos)
	GameManager.unit_container.add_child(unit)
	register_unit(unit, unit_id)


func _destroy_unit_local(unit_id: int, effect_pos: Vector2) -> void:
	var unit: Unit = _units_by_id.get(unit_id)
	if unit == null:
		return
	unit.die_at_position(effect_pos)
