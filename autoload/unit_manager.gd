extends Node

var _units_by_id: Dictionary = {} # unit_id -> Unit
var _next_unit_id: int = 1

func generate_unit_id() -> int:
	var id := _next_unit_id
	_next_unit_id += 1
	return id


func register_unit(unit: Unit, unit_id: int) -> void:
	_units_by_id[unit_id] = unit


func unregister_unit(unit_id: int) -> void:
	_units_by_id.erase(unit_id)

func _spawn_unit_local(req: UnitSendRequest) -> void:
	if GameManager.unit_container == null:
		return
	
	var source := StructureManager.get_structure(req.source_id)
	var target := StructureManager.get_structure(req.target_id)
	if target == null:
		return

	var unit: Unit = load("res://scenes/units/unit.tscn").instantiate()
	unit.unit_id = req.unit_id
	unit.set_team(req.team_id)
	unit.global_position = req.spawn_pos
	unit.speed = req.unit_speed
	unit.source_structure = source
	unit.set_target_from_network(target, req.target_pos)
	GameManager.unit_container.add_child(unit)
	register_unit(unit, req.unit_id)


func _destroy_unit_local(unit_id: int, effect_pos: Vector2) -> void:
	var unit: Unit = _units_by_id.get(unit_id)
	if unit == null:
		return
	unit.die_at_position(effect_pos)

# Relocated VVVVV

func request_send_units(req: UnitSendRequest) -> void:
	if MultiplayerManager.is_multiplayer():
		if MultiplayerManager.is_server():
			_handle_send_units_request(req)
		else:
			rpc_request_send_units.rpc_id(1, req.to_dict())
	else:
		_handle_send_units_request(req)


# RPC sent by client, function executed by server only.
@rpc("any_peer", "reliable")
func rpc_request_send_units(dict: Dictionary) -> void:
	var req := BaseRequest.from_dict(dict, UnitSendRequest)
	req.peer_id = multiplayer.get_remote_sender_id()
	_handle_send_units_request(req)



func _handle_send_units_request(req: UnitSendRequest) -> void:
	if not MultiplayerManager.peer_teams.has(req.peer_id):
		Globals.send_error("Unknown peer %d attempted to send units" % req.peer_id)
		return

	var src := StructureManager.get_structure(req.source_id)
	var tgt := StructureManager.get_structure(req.target_id)

	if src == null or tgt == null:
		Globals.send_error("Invalid structure ids: %d -> %d" % [req.source_id, req.target_id])
		return

	if src == tgt:
		return

	if src.get_team() != MultiplayerManager.peer_teams[req.peer_id]:
		Globals.send_error("Peer %d does not own team %d" % [req.peer_id, src.get_team()])
		return

	src.send_units(req)




func broadcast_spawn_unit(req: UnitSendRequest) -> void:
	_spawn_unit_local(req)
	if MultiplayerManager.is_multiplayer() and MultiplayerManager.is_server():
		rpc_spawn_unit.rpc(req.to_dict())



@rpc("authority", "reliable")
func rpc_spawn_unit(dict: Dictionary) -> void:
	var req := BaseRequest.from_dict(dict, UnitSendRequest)
	_spawn_unit_local(req)


func broadcast_unit_destroyed(id: int, pos: Vector2) -> void:
	_destroy_unit_local(id, pos)
	if MultiplayerManager.is_multiplayer() and MultiplayerManager.is_server():
		rpc_destroy_unit.rpc(id, pos)


# RELOCATE
@rpc("authority", "reliable")
func rpc_destroy_unit(id: int, pos: Vector2) -> void:
	_destroy_unit_local(id, pos)
