extends Resource
class_name FactionAbility


var ability_name: String
var cooldown: float = 0
var icon

func execute(_req: FactionAbilityRequest):
	# Overridden in subclasses
	pass
