class_name PlayerCamera extends Camera3D


@export var minimum_distance : float = 3.0
@export var maximum_distance : float = 6.0
@export var height : float = 3.0
@export var sensitivity : float = 50

@export var target : Node3D = null
@export var pivot : Node3D = null

var moving : bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not target:
		target = get_owner()
	if not pivot:
		pivot = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	moving = (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion)
	
	if moving:
		top_level = false
		pivot.rotate_y(-event.relative.x * deg_to_rad(sensitivity / 1000))
		top_level = true
	


func _process(delta: float) -> void:
	var from_target : Vector3 = global_position - target.global_position
	
	if from_target.length() < minimum_distance:
		from_target = from_target.normalized() * minimum_distance
	if from_target.length() > maximum_distance:
		from_target = from_target.normalized() * maximum_distance
	
	from_target.y = height
	global_position = target.global_position + from_target
	
	var look_direction : Vector3 = global_position.direction_to(target.global_position).abs() - Vector3.UP
	if not look_direction.is_zero_approx():
		look_at_from_position(global_position, target.global_position, Vector3.UP)
