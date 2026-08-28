class_name CameraFollow extends Camera3D

@export var min_distance: float = 4.0
@export var max_distance: float = 8.0
@export var height: float = 3.0
@export var sensitivity: float = 0.001

@export var target: Node3D = null
@export var pivot: Node3D = null

func _unhandled_input(event: InputEvent) -> void:
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event is InputEventMouseMotion:
		top_level = false
		pivot.rotate_y(-event.screen_relative.x * sensitivity)
		top_level = true

func _process(delta: float) -> void:
	
	if not target: return
	
	var from_target: Vector3 = global_position - target.global_position
	
	if from_target.length() < min_distance:
		from_target = from_target.normalized() * min_distance
	elif from_target.length() > max_distance:
		from_target = from_target.normalized() * max_distance
		
	from_target.y = height
	global_position = target.global_position + from_target
	
	var look_dir: Vector3 = global_position.direction_to(target.global_position).abs() - Vector3.UP
	if not look_dir.is_zero_approx():
		look_at_from_position(global_position, target.global_position, Vector3.UP)
