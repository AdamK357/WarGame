extends Node2D
class_name BaseStructure

signal mouse_hover_entered(structure)
signal mouse_hover_exited

# Unit spawning constants
const SPAWN_MIN_RADIUS := 25.0
const SPAWN_MAX_RADIUS := 75.0
const SPAWN_ANGLE_RANGE := 0.35  # radians from target angle
const SPAWN_DELAY_MIN := 0.05
const SPAWN_DELAY_MAX := 0.2
const SPAWN_DELAY_SCALE := 0.001

@export var structure_id: int = 0
@export var team: int = 0

@onready var growth_timer: Timer = $GrowthTimer
@onready var population_label: Label = $PopulationLabel
@onready var selection_ring: Sprite2D = $SelectionRingSprite
@onready var sprite2d: Sprite2D = $SpriteContainer/Sprite2D
@onready var sprite_container: Node2D = $SpriteContainer
@onready var unit_scene: PackedScene = preload("res://scenes/units/unit.tscn")
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var population: int = 10:
	set(value):
		population = value
		_update_population_label()
## Set to -1 to disable
@export var max_population: int = -1
## Should the population increase over time
@export var can_grow: bool = true
## Amount of time between population growths (seconds)
@export var growth_time: float = 1
## Amount added to population per growth
@export var growth_amount: int = 1


func _ready() -> void:
	growth_timer.wait_time = growth_time
	_update_texture()
	_update_population_label()
	
	if not MultiplayerManager.is_server_or_singleplayer():
		return
	
	if team != 0 and can_grow:
		growth_timer.start()


func set_team(new_team: int) -> void:
	if MultiplayerManager.is_server_or_singleplayer():
		if team == 0 and can_grow and new_team != 0:
			growth_timer.start()
	
	team = new_team
	_update_texture()


func get_team() -> int:
	return team


## Will not work if structure is not added to scene yet.
func _update_texture() -> void:
	if sprite2d == null:
		return
	sprite2d.modulate = Globals.get_team_color(team)
	var faction_id: int = FactionManager.get_team_faction_id(team)
	if faction_id == 0:
		return
	
	if self is GrowthStructure:
		var texture: Texture2D = FactionManager.get_base_faction_data(faction_id).structure_texture
		if texture == null or texture == sprite2d.texture:
			return
		sprite2d.texture = texture


func _on_growth_timer_timeout() -> void:
	if not MultiplayerManager.is_server_or_singleplayer(): # if this instance of the game is a client, exit this function.
		return
	
	var new_population
	if max_population < 0:
		new_population = population + growth_amount
	else:
		new_population = clampi(population + growth_amount, 0, max_population)
	
	if new_population == population:
		return

	population = new_population # authoritative update to the population. population label is updated using apply_network_state() through broadcast_structure_state()
	StructureManager.broadcast_structure_state(structure_id, team, population)





func apply_network_state(_team: int, new_population: int) -> void: # this is a replication function who's job is to simply update the clients with the server's information/state. Singleplayer still uses this function just to update the visual state, but does not use it as an authoritative function.
	team = _team
	population = new_population
	_update_texture()
	_update_population_label()


func _update_population_label() -> void:
	if population_label != null:
		population_label.text = str(population)

func send_units(request: UnitSendRequest) -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return

	var amount_to_send := _calculate_send_amount(request)
	if amount_to_send <= 0:
		return
	
	population -= amount_to_send
	StructureManager.broadcast_structure_state(structure_id, team, population)

	# Stagger unit spawning for visual effect - delay increases with quantity
	var delay := clampf(SPAWN_DELAY_MAX - amount_to_send * SPAWN_DELAY_SCALE, SPAWN_DELAY_MIN, SPAWN_DELAY_MAX)
	for i in amount_to_send:
		request.unit_id = UnitManager.generate_unit_id()
		spawn_unit(request)
		await get_tree().create_timer(delay).timeout



# I updated this code, hopefully it is better, need testing
func _calculate_send_amount(request: UnitSendRequest) -> int:
	var result: int = 0

	if request.unit_send_mode == Globals.UnitSendMode.PERCENT:
		var p = request.percent
		# If you treat p as 0–100, convert to 0–1:
		if p > 1.0:
			p /= 100.0
		result = int(round(population * p))
	else:
		result = int(request.amount)

	# Clamp to valid range
	result = clampi(result, 0, population)
	return result


func spawn_unit(req: UnitSendRequest) -> void:
	if not MultiplayerManager.is_server_or_singleplayer():
		return
	
	var target: BaseStructure = StructureManager.get_structure(req.target_id)
	req.spawn_pos = _generate_spawn_position(target.global_position)
	req.target_pos = target.generate_arrival_position()
	
	UnitManager.broadcast_spawn_unit(req)


## Generate a spawn position biased toward the target direction
func _generate_spawn_position(target_pos: Vector2) -> Vector2:
	var distance := randf_range(SPAWN_MIN_RADIUS, SPAWN_MAX_RADIUS)
	var angle_to_target := get_angle_to(target_pos)
	var lower_angle := angle_to_target - SPAWN_ANGLE_RANGE
	var upper_angle := angle_to_target + SPAWN_ANGLE_RANGE
	var angle := randf_range(lower_angle, upper_angle)
	return global_position + (Vector2.from_angle(angle) * distance)


## Generate a random arrival position around this structure
func generate_arrival_position() -> Vector2:
	var distance := randf_range(SPAWN_MIN_RADIUS, SPAWN_MAX_RADIUS)
	var angle := randf() * TAU
	var offset := Vector2.from_angle(angle) * distance
	return global_position + offset


func apply_unit_hit(incoming_unit_team: int) -> void:
	if incoming_unit_team == team:
		population += 1
		anim_player.play("hit")
	else:
		population -= 1
		anim_player.play("hit")
		if population <= 0:
			structure_captured(team, incoming_unit_team)

	StructureManager.broadcast_structure_state(structure_id, team, population)


func structure_captured(current_team: int, new_team: int):
	GameManager.transfer_structure(current_team, new_team)
	set_team(new_team)


func _on_area_2d_mouse_entered():
	mouse_hover_entered.emit(self)
	# tween animation
	var tween = get_tree().create_tween()
	tween.tween_property(sprite_container, "scale", Vector2(1.05, 1.05), 0.05)


func _on_area_2d_mouse_exited():
	mouse_hover_exited.emit()
	# tween animation
	var tween = get_tree().create_tween()
	tween.tween_property(sprite_container, "scale", Vector2(1, 1), 0.05)


func set_selected(state: bool) -> void:
	var tween = get_tree().create_tween()
	if state:
		selection_ring.scale = Vector2(0, 0)
		selection_ring.show()
		tween.tween_property(selection_ring, "scale", Vector2(0.7, 0.7), 0.1)
	else:
		tween.tween_property(selection_ring, "scale", Vector2(0, 0), 0.1)
		await tween.finished
		selection_ring.hide()
