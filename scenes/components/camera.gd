extends Camera2D

const MOVE_SPEED := 1000.0
const ZOOM_SPEED := 0.1
const MIN_ZOOM := 0.25
const MAX_ZOOM := 2.5

var _dragging := false
var _last_mouse_pos := Vector2.ZERO


func _process(delta: float) -> void:
	_handle_keyboard_movement(delta)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _dragging:
		_handle_mouse_drag(event)


## Handle arrow keys and WASD for camera movement
func _handle_keyboard_movement(delta: float) -> void:
	var velocity := Vector2.ZERO

	if Input.is_action_pressed("right"):
		velocity.x += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("down"):
		velocity.y += 1
	if Input.is_action_pressed("up"):
		velocity.y -= 1

	if velocity != Vector2.ZERO and not _dragging:
		velocity = velocity.normalized()
		global_position += velocity * MOVE_SPEED * delta * (1 / zoom.x)


## Handle mouse button events (middle click drag start/stop, wheel zoom)
func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		_dragging = event.pressed
		if _dragging:
			_last_mouse_pos = event.position

	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_apply_zoom(-ZOOM_SPEED)
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_apply_zoom(ZOOM_SPEED)


## Handle middle-mouse drag movement, with zoom-aware scaling
func _handle_mouse_drag(event: InputEventMouseMotion) -> void:
	var delta := event.position - _last_mouse_pos
	global_position -= delta * (1 / zoom.x)
	_last_mouse_pos = event.position


## Apply zoom adjustment with clamping
func _apply_zoom(amount: float) -> void:
	var new_zoom := zoom + Vector2(amount, amount)
	zoom = new_zoom.clamp(Vector2(MIN_ZOOM, MIN_ZOOM), Vector2(MAX_ZOOM, MAX_ZOOM))
	
