class_name FollowCamera extends Camera3D

@export var minimun_distance : float = 4.0
@export var maximum_distance : float = 8.0
@export var height : float = 3.0
@export var sensitivity : float = 0.001

@export var target : Node3D = null
@export var pivot : Node3D = null


func _unhandled_input(event: InputEvent) -> void:
	
	if not pivot : return
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_key_pressed(KEY_ESCAPE) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var moving : bool = event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	
	if moving:
		top_level = false
		pivot.rotate_y(-event.relative.x * sensitivity)
		top_level = true


func _process(delta: float) -> void:
	var from_direction : Vector3 = global_position - target.global_position
	
	
	if from_direction.length() < minimun_distance:
		from_direction = from_direction.normalized() * minimun_distance
	elif from_direction.length() > maximum_distance:
		from_direction = from_direction.normalized() * maximum_distance
	
	from_direction.y = height
	global_position = target.global_position + from_direction
	
	var look_direction : Vector3 = global_position.direction_to(target.global_position).abs() - Vector3.UP
	if not look_direction.is_zero_approx():
		look_at_from_position(global_position, target.global_position, Vector3.UP)
