extends Control

const MAP_PATH := "res://scenes/maps/map.tscn"
const DEFAULT_PORT := 60865

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var host_button: Button = $CenterContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/JoinButton
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var address_edit: LineEdit = $CenterContainer/VBoxContainer/AddressEdit
@onready var team_edit: LineEdit = $CenterContainer/VBoxContainer/TeamEdit


func _ready() -> void:
	MultiplayerManager.peer_list_changed.connect(_refresh_status)
	MultiplayerManager.connection_failed.connect(_on_connection_failed)
	_refresh_status()


func _get_team_from_input() -> int:
	if team_edit.text.is_valid_int():
		var team := int(team_edit.text)
		if team > 0:
			return team
	return 1


func _on_host_button_pressed() -> void:
	var error := MultiplayerManager.host_game(DEFAULT_PORT, _get_team_from_input())
	if error != OK:
		_set_status("Failed to host on port %d" % DEFAULT_PORT)
		return
	_set_status("Hosting on port %d as team %d" % [DEFAULT_PORT, MultiplayerManager.local_team])


func _on_join_button_pressed() -> void:
	var address := address_edit.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"

	var error := MultiplayerManager.join_game(address, DEFAULT_PORT, _get_team_from_input())
	if error != OK:
		_set_status("Failed to connect to %s:%d" % [address, DEFAULT_PORT])
		return
	_set_status("Connecting to %s:%d..." % [address, DEFAULT_PORT])


func _on_start_button_pressed() -> void:
	if MultiplayerManager.is_multiplayer() and not multiplayer.is_server():
		_set_status("Only the host can start the game")
		return

	MultiplayerManager.local_team = _get_team_from_input()
	if MultiplayerManager.is_multiplayer():
		MultiplayerManager.peer_teams[1] = MultiplayerManager.local_team
		MultiplayerManager.human_teams = MultiplayerManager.peer_teams.values()

	MultiplayerManager.start_game(MAP_PATH)


func _on_connection_failed() -> void:
	_set_status("Connection failed")


func _refresh_status() -> void:
	if not MultiplayerManager.is_multiplayer():
		_set_status("Single player — pick a team and press Start Game")
		return

	if multiplayer.is_server():
		var player_count := multiplayer.get_peers().size() + 1
		_set_status("Hosting — %d player(s), team %d" % [player_count, MultiplayerManager.local_team])
	else:
		_set_status("Connected — team %d" % MultiplayerManager.local_team)


func _set_status(message: String) -> void:
	status_label.text = message
