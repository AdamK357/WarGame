extends Node
# MultiplayerManager: authoritative networking layer.
# Handles: player requests → server validation → broadcast → local application.
# Also manages: team ownership, faction assignment, structure/unit registries.

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 6

signal connection_failed
signal peer_list_changed

var local_peer_id: int = 1
var local_team_id: int = 1
var local_faction_id: int = 1

var peer_teams: Dictionary = {}      # peer_id -> team
var human_teams: Array = []          # teams controlled by humans


# -------------------------------------------------------------------
# BASIC STATE
# -------------------------------------------------------------------

func _ready() -> void:
	multiplayer.multiplayer_peer = null
	if is_multiplayer():
		local_peer_id = multiplayer.get_unique_id()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_multiplayer() -> bool:
	return multiplayer.multiplayer_peer != null

func is_server() -> bool:
	return multiplayer.is_server()

func is_server_or_singleplayer() -> bool:
	return not is_multiplayer() or multiplayer.is_server()

func get_local_team_id() -> int:
	return local_team_id

func get_local_faction() -> int:
	return local_faction_id

func get_local_peer_id() -> int:
	return local_peer_id

func get_peer_team(id: int) -> int:
	return peer_teams[id]


# -------------------------------------------------------------------
# HOST / JOIN / DISCONNECT
# -------------------------------------------------------------------

func host_game(port := DEFAULT_PORT, team := 1, faction := 1) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		connection_failed.emit()
		return err

	multiplayer.multiplayer_peer = peer
	local_peer_id = multiplayer.get_unique_id()
	local_team_id = team
	local_faction_id = faction

	peer_teams = {1: team}
	human_teams = [team]

	FactionManager.register_team_faction(team, faction)
	peer_list_changed.emit()
	return OK


func join_game(address: String, port := DEFAULT_PORT, team := 1, faction := 1) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		connection_failed.emit()
		return err

	multiplayer.multiplayer_peer = peer
	local_peer_id = multiplayer.get_unique_id()
	local_team_id = team
	local_faction_id = faction
	return OK


func disconnect_from_game() -> void:
	if is_multiplayer():
		multiplayer.multiplayer_peer.close()

	multiplayer.multiplayer_peer = null
	peer_teams.clear()
	human_teams.clear()

	StructureManager._structures_by_id.clear()
	UnitManager._units_by_id.clear()
	UnitManager._next_unit_id = 1


# -------------------------------------------------------------------
# GAME START
# -------------------------------------------------------------------

func start_game(map_path: String) -> void:
	if is_multiplayer():
		if not is_server():
			return
		start_game_rpc.rpc(map_path)
	else:
		human_teams = [local_team_id]
		peer_teams = {1: local_team_id}
		FactionManager.register_team_faction(local_team_id, local_faction_id)
		TransitionManager.change_scene(map_path)


@rpc("authority", "reliable", "call_local")
func start_game_rpc(map_path: String) -> void:
	get_tree().change_scene_to_file(map_path)


# -------------------------------------------------------------------
# REQUEST PATTERN (CLIENT → SERVER → BROADCAST → APPLY)
# -------------------------------------------------------------------
# Every gameplay action follows this pattern:
#
# request_X()          # client → server
# rpc_request_X()      # server receives request
# _handle_X_request()  # server validates + executes
# broadcast_X()        # server → all peers
# rpc_X()              # peers apply result
# -------------------------------------------------------------------


# ---------------------------
# SEND UNITS
# ---------------------------

func request_send_units(req: UnitSendRequest) -> void:
	if is_multiplayer():
		if is_server():
			_handle_send_units_request(req)
		else:
			rpc_request_send_units.rpc_id(1, req.to_dict())
	else:
		var src := StructureManager.get_structure(req.source_id)
		if src:
			src.send_units(req)

# RPC sent by client, function executed by server only.
@rpc("any_peer", "reliable")
func rpc_request_send_units(dict: Dictionary) -> void:
	var req := BaseRequest.from_dict(dict, UnitSendRequest)
	req.peer_id = multiplayer.get_remote_sender_id()
	_handle_send_units_request(req)


func _handle_send_units_request(req: UnitSendRequest) -> void:
	if not peer_teams.has(req.peer_id):
		Globals.send_error("Unknown peer %d attempted to send units" % req.peer_id)
		return

	var src := StructureManager.get_structure(req.source_id)
	var tgt := StructureManager.get_structure(req.target_id)

	if src == null or tgt == null:
		Globals.send_error("Invalid structure ids: %d -> %d" % [req.source_id, req.target_id])
		return

	if src == tgt:
		return

	if src.get_team() != peer_teams[req.peer_id]:
		Globals.send_error("Peer %d does not own team %d" % [req.peer_id, src.get_team()])
		return

	src.send_units(req)


# ---------------------------
# SPAWN UNIT (broadcast only)
# ---------------------------

func broadcast_spawn_unit(req: UnitSendRequest) -> void:
	UnitManager._spawn_unit_local(req)
	if is_multiplayer() and is_server():
		rpc_spawn_unit.rpc(req.to_dict())


@rpc("authority", "reliable")
func rpc_spawn_unit(dict: Dictionary) -> void:
	var req := BaseRequest.from_dict(dict, UnitSendRequest)
	UnitManager._spawn_unit_local(req)

# ---------------------------
# SPAWN STRUCTURE (broadcast only)
# ---------------------------

func broadcast_spawn_structure(req: StructureSpawnRequest) -> void:
	StructureManager._spawn_structure_local(req)
	if is_multiplayer() and is_server():
		rpc_spawn_structure.rpc(req.to_dict())


@rpc("authority", "reliable")
func rpc_spawn_structure(dict: Dictionary) -> void:
	var req := BaseRequest.from_dict(dict, StructureSpawnRequest)
	StructureManager._spawn_structure_local(req)


# ---------------------------
# ABILITY REQUEST
# ---------------------------

# Called by any peer
func request_ability(req: FactionAbilityRequest) -> void:
	if is_multiplayer():
		if is_server():
			_handle_ability_request(req) # if this peer is the server, handle the request
		else:
			rpc_request_ability.rpc_id(1, req.to_dict()) # if this peer is a client, send an rpc to the server so the server can handle the request.
	else:
		_handle_ability_request(req) # if singleplayer, handle the request

# RPC sent by client, function executed by server only.
@rpc("any_peer", "reliable")
func rpc_request_ability(dict: Dictionary):
	var req := BaseRequest.from_dict(dict, FactionAbilityRequest)
	_handle_ability_request(req)


func _handle_ability_request(req: FactionAbilityRequest):
	FactionManager.handle_ability_request(req)

# ---------------------------
# ABILITY EXECUTION (broadcast only)
# ---------------------------


@rpc("authority", "call_remote")
func rpc_execute_ability(data: Dictionary):
	var req := BaseRequest.from_dict(data, FactionAbilityRequest)
	var controller := FactionManager.get_controller(req.team_id)
	controller.execute_ability(req) # Activate the ability on the client side.


# ---------------------------
# STRUCTURE STATE SYNC
# ---------------------------

func broadcast_structure_state(id: int, team: int, pop: int) -> void:
	var s := StructureManager.get_structure(id)
	if s:
		s.apply_network_state(team, pop)

	if is_multiplayer() and is_server():
		rpc_sync_structure.rpc(id, team, pop)


@rpc("authority", "reliable")
func rpc_sync_structure(id: int, team: int, pop: int) -> void:
	var s := StructureManager.get_structure(id)
	if s:
		s.apply_network_state(team, pop)


# ---------------------------
# UNIT DESTROY
# ---------------------------

func broadcast_unit_destroyed(id: int, pos: Vector2) -> void:
	UnitManager._destroy_unit_local(id, pos)
	if is_multiplayer() and is_server():
		rpc_destroy_unit.rpc(id, pos)


@rpc("authority", "reliable")
func rpc_destroy_unit(id: int, pos: Vector2) -> void:
	UnitManager._destroy_unit_local(id, pos)


# -------------------------------------------------------------------
# TEAM / FACTION SYNC
# -------------------------------------------------------------------

func is_team_human_controlled(team: int) -> bool:
	return human_teams.has(team)


func _on_peer_connected(_peer_id: int) -> void:
	if is_server():
		rpc_sync_teams.rpc(peer_teams)
	peer_list_changed.emit()


func _on_peer_disconnected(peer_id: int) -> void:
	peer_teams.erase(peer_id)
	human_teams = peer_teams.values()
	peer_list_changed.emit()


func _on_connected_to_server() -> void:
	rpc_register_team.rpc_id(1, local_team_id)
	rpc_register_faction.rpc_id(1, local_faction_id)


func _on_connection_failed() -> void:
	disconnect_from_game()
	connection_failed.emit()


func _on_server_disconnected() -> void:
	disconnect_from_game()
	connection_failed.emit()


# RPC sent by client, function executed by server only.
@rpc("any_peer", "reliable")
func rpc_register_team(team: int) -> void:
	var peer_id := multiplayer.get_remote_sender_id()

	if peer_teams.values().has(team):
		Globals.send_error("Team %d already taken" % team)
		return

	peer_teams[peer_id] = team
	human_teams = peer_teams.values()

	rpc_sync_teams.rpc(peer_teams)
	peer_list_changed.emit()


@rpc("authority", "reliable", "call_local")
func rpc_sync_teams(teams: Dictionary) -> void:
	peer_teams = teams
	human_teams = peer_teams.values()

	var my_id := multiplayer.get_unique_id()
	if peer_teams.has(my_id):
		local_team_id = get_peer_team(my_id)

	peer_list_changed.emit()


# ---------------------------
# FACTION ASSIGNMENT
# ---------------------------

@rpc("any_peer", "reliable")
func rpc_register_faction(_faction: int) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	FactionManager.register_team_faction(get_peer_team(peer_id), _faction)
	rpc_sync_factions.rpc(FactionManager.team_factions)

@rpc("authority", "reliable")
func rpc_sync_factions(team_factions: Dictionary) -> void:
	FactionManager.update_team_factions(team_factions)
