extends RefCounted
class_name UnitSendRequest

var source_id: int # Source structure
var target_id: int # Target structure
var unit_send_mode: Globals.UnitSendMode = Globals.UnitSendMode.PERCENT
var percent: float # Percent of units to send
var amount: float # Amount of units to send
var peer_id: int = -1  # optional, server fills this in

func _init(_source_id: int, _target_id: int, _unit_send_mode: Globals.UnitSendMode, _value: float):
	source_id = _source_id
	target_id = _target_id
	unit_send_mode = _unit_send_mode
	
	if _value != 0:
		if _unit_send_mode == Globals.UnitSendMode.PERCENT:
			percent = _value
			amount = -1
		else:
			percent = -1
			amount = _value

func to_dict() -> Dictionary:
	return {
		"source_id": source_id,
		"target_id": target_id,
		"unit_send_mode": unit_send_mode,
		"percent": percent,
		"amount": amount,
		"peer_id": peer_id
	}

static func from_dict(data: Dictionary) -> UnitSendRequest:
	var req = UnitSendRequest.new(data.source_id, data.target_id, data.unit_send_mode, 0)
	req.percent = data.percent
	req.amount = data.amount
	req.peer_id = data.peer_id
	return req
