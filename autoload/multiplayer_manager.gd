extends Node

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

func get_local_faction_id() -> int:
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
		SceneManager.change_scene(map_path)


@rpc("authority", "reliable", "call_local")
func start_game_rpc(map_path: String) -> void:
	get_tree().change_scene_to_file(map_path)


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
	FactionManager.rpc_register_faction.rpc_id(1, local_faction_id)


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
