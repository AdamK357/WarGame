extends Node

# RELOCATE in progress
# Called by any peer
func request_ability(req: FactionAbilityRequest) -> void:
	if MultiplayerManager.is_multiplayer():
		if MultiplayerManager.is_server():
			_handle_ability_request(req) # if this peer is the server, handle the request
		else:
			rpc_request_ability.rpc_id(1, req.to_dict()) # if this peer is a client, send an rpc to the server so the server can handle the request.
	else:
		_handle_ability_request(req) # if singleplayer, handle the request
# RELOCATE
# RPC sent by client, function executed by server only.
@rpc("any_peer", "reliable")
func rpc_request_ability(dict: Dictionary):
	var req := BaseRequest.from_dict(dict, FactionAbilityRequest)
	_handle_ability_request(req)

# RELOCATE
func _handle_ability_request(req: FactionAbilityRequest):
	FactionManager.handle_ability_request(req)
