extends Node2D

var unit_container: Node2D
var particle_container: Node2D
var structure_container: Node2D
var player_controller: PlayerController

func try_send_units(request: UnitSendRequest) -> void:
	if not request.source_id or not request.target_id:
		Globals.send_error("source structure or target structure not selected")
		return

	if request.source_id == request.target_id:
		Globals.send_error("source and target structure are the same")
		return

	MultiplayerManager.request_send_units(request)
