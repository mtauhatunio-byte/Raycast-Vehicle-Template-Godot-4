class_name EditorCameraController extends Camera3D

@export_subgroup("Settings")
@export var mouse_sensitivity: float = 0.25
@export var base_speed: float = 10.0
@export var velocity_multiplier: float = 2.0

@export_subgroup("Modifiers")
@export var fast_modifier: float = 2.5
@export var slow_modifier: float = 0.3

var _rotation: Vector3 = Vector3.ZERO

func _ready() -> void:
	_rotation = rotation

func _input(event: InputEvent) -> void:
	# Right-click triggers freelook rotation
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		# Capture mouse to prevent it from flying off-screen during pan
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
		# Modify internal tracking rotations based on relative mouse movement
		_rotation.y -= deg_to_rad(event.relative.x * mouse_sensitivity)
		_rotation.x -= deg_to_rad(event.relative.y * mouse_sensitivity)
		_rotation.x = clamp(_rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0)) # Prevent flipping over
		
		rotation = _rotation
	
	# Release mouse mode when letting go of right-click
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Scroll wheel changes base movement speed dynamically
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			base_speed += velocity_multiplier
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			base_speed = max(0.5, base_speed - velocity_multiplier)

func _process(delta: float) -> void:
	_update_movement(delta)

func _update_movement(delta: float) -> void:
	# Only allow keyboard movement while holding Right-Click (like Godot Editor)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return

	var direction := Vector3.ZERO
	
	# Local spatial calculations relative to where camera is looking
	if Input.is_key_pressed(KEY_W): direction -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S): direction += global_transform.basis.z
	if Input.is_key_pressed(KEY_A): direction -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D): direction += global_transform.basis.x
	if Input.is_key_pressed(KEY_E): direction += global_transform.basis.y # Up
	if Input.is_key_pressed(KEY_Q): direction -= global_transform.basis.y # Down
	
	direction = direction.normalized()
	
	# Handle speed modifiers (Shift = Fast, Alt = Slow)
	var current_speed : float = base_speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= fast_modifier
	elif Input.is_key_pressed(KEY_ALT):
		current_speed *= slow_modifier
		
	# Move the camera
	global_translate(direction * current_speed * delta)
