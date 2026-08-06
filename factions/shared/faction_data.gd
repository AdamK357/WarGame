extends Resource
class_name FactionData

@export var id: int
@export var name: String

@export var unit_texture: Texture2D
@export var structure_texture: Texture2D

@export var base_unit_speed: float = 100
@export var growth_rate_multiplier: float = 1.0
@export var unit_speed_multiplier: float = 1.0
@export var ability_resources: Array[Resource]
@export var passive_resources: Array[Resource]
@export var logic_module: FactionLogic
@export var faction_ui: Resource
