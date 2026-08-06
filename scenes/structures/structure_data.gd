extends Resource
class_name StructureData

## The current population
@export var population: int = 10
## Set to -1 to disable
@export var max_population: int = -1
## Should the population increase over time
@export var can_grow: bool = true
## Amount of time between population growths (seconds)
@export var growth_time: float = 1
## Amount added to population per growth
@export var growth_amount: int = 1
