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

#func _init(
		#_source_id: int,
		#_target_id: int,
		#_peer_id: int,
		#_team_id: int,
		#_unit_id: int,
		##_spawn_pos: Vector2,
		##_target_pos: Vector2,
		#_unit_send_mode: Globals.UnitSendMode,
		#_percent: float = -1.0,
		#_amount: int = -1
		#):
	#source_id = _source_id
	#target_id = _target_id
	#peer_id = _peer_id
	#team_id = _team_id
	#unit_id = _unit_id
	#
	#unit_send_mode = _unit_send_mode
	#percent = _percent
	#amount = _amount
	#
	##spawn_pos = _spawn_pos
	##target_pos = _target_pos
	#
#
#func to_dict() -> Dictionary:
	#return {
		#"source_id": source_id,
		#"target_id": target_id,
		#"peer_id": peer_id,
		#"team_id": team_id,
		#"unit_id": unit_id,
		#
		#"unit_send_mode": int(unit_send_mode),
		#"percent": percent,
		#"amount": amount,
		#
		#"spawn_pos": spawn_pos,
		#"target_pos": target_pos,
	#}
#
#static func from_dict(data: Dictionary) -> UnitSendRequest:
	#var req = UnitSendRequest.new(
		#data.get("source_id", -1), 
		#data.get("target_id", -1), 
		#data.get("peer_id", -1), 
		#data.get("team_id", -1), 
		#data.get("unit_id", -1), 
		#
		#data.get("unit_send_mode", Globals.UnitSendMode.PERCENT), 
		#data.get("percent", -1.0), 
		#data.get("amount", -1),
		#)
	#req.spawn_pos = data.get("spawn_pos", Vector2.ZERO)
	#req.target_pos = data.get("target_pos", Vector2.ZERO)
	#return req
