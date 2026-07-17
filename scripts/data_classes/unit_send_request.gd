extends BaseRequest
class_name UnitSendRequest

var source_id: int # Source structure
var target_id: int # Target structure
var peer_id: int = -1 # optional, server fills this in
var team_id: int = -1 # optional, server fills this in
var unit_id: int = -1 # optional, server fills this in

var unit_send_mode: int = Globals.UnitSendMode.PERCENT
var percent: float # Percent of units to send
var amount: float # Amount of units to send

var unit_speed: float = 100.0

var spawn_pos: Vector2
var target_pos: Vector2

func initialize(
		_source_id: int,
		_target_id: int,
		_peer_id: int,
		_team_id: int,
		_unit_id: int,
		#_spawn_pos: Vector2,
		#_target_pos: Vector2,
		_unit_send_mode: Globals.UnitSendMode,
		_percent: float = -1.0,
		_amount: int = -1
		) -> void:
	source_id = _source_id
	target_id = _target_id
	peer_id = _peer_id
	team_id = _team_id
	unit_id = _unit_id
	
	unit_send_mode = _unit_send_mode
	percent = _percent
	amount = _amount
