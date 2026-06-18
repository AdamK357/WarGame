extends Camera2D

@export var move_speed: float = 1000.0
@export var edge_size: int = 20
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.25
@export var max_zoom: float = 2.5

var dragging := false
var last_mouse_pos := Vector2.ZERO

func _process(delta):
	var velocity := Vector2.ZERO

	# Keyboard movement
	if Input.is_action_pressed("right"):
		velocity.x += 1
	if Input.is_action_pressed("left"):
		velocity.x -= 1
	if Input.is_action_pressed("down"):
		velocity.y += 1
	if Input.is_action_pressed("up"):
		velocity.y -= 1

	# Mouse edge scrolling
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_size = get_viewport_rect().size

	if mouse_pos.x <= edge_size:
		velocity.x -= 1
	elif mouse_pos.x >= viewport_size.x - edge_size:
		velocity.x += 1

	if mouse_pos.y <= edge_size:
		velocity.y -= 1
	elif mouse_pos.y >= viewport_size.y - edge_size:
		velocity.y += 1

	# Apply movement
	if velocity != Vector2.ZERO and not dragging:
		velocity = velocity.normalized()
		global_position += velocity * move_speed * delta * (1/ zoom.x)

func _input(event):
	# Middle mouse drag start
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			if dragging:
				last_mouse_pos = event.position

		# Zoom with mouse wheel
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = (zoom - Vector2(zoom_speed, zoom_speed)).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = (zoom + Vector2(zoom_speed, zoom_speed)).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

	# Middle mouse dragging movement
	if event is InputEventMouseMotion and dragging:
		var delta = event.position - last_mouse_pos
		global_position -= delta * (1 / zoom.x)  # drag speed scales with zoom
		last_mouse_pos = event.position
	
