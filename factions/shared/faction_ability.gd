extends Resource
class_name FactionAbility


@export var ability_name: String
@export var activation_type: Globals.ActivationType = Globals.ActivationType.INSTANT
@export var cooldown: float = 0
var icon

func execute(_req: FactionAbilityRequest):
	# Overridden in subclasses
	pass
